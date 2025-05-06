#!/bin/bash

set -eu
set -o pipefail

# Exit codes:
# 0 - Success
# 1 - General script error
# 10 - Required tools are missing
# 11 - Could not create log directory
# 12 - Could not create log file

# Default configuration
ENDPOINT="https://sre-test-assignment.innervate.tech/health.html"
DESIRED_STATUS="Success"
LOG_FILE_PATH="/var/log/"
LOG_FILE_NAME="diagnostics.log"
LOG_FILE=""

# Usage function
usage() {
    cat <<EOF
Usage: $0 -e <endpoint_url> [-s <desired_status>] [-l <log_file_path>] [-f <log_file_name>] [-h]

Options:
  -e, --endpoint     URL to check (required)
  -s, --status       Desired string in response body (default: "Success")
  -l, --logpath      Directory to store the log file (default: /var/log/)
  -f, --logfile      Log file name (default: diagnostics.log)
  -h, --help         Display this help message

Example:
  $0 -e https://example.com/health -s Success -l /var/log/ -f diagnostics.log
EOF
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--endpoint)
            ENDPOINT="$2"
            shift 2
            ;;
        -s|--status)
            DESIRED_STATUS="$2"
            shift 2
            ;;
        -l|--logpath)
            LOG_FILE_PATH="$2"
            shift 2
            ;;
        -f|--logfile)
            LOG_FILE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required argument
if [[ -z "$ENDPOINT" ]]; then
    echo "ERROR: Endpoint URL is required."
    usage
fi

# Construct full log file path
LOG_FILE="${LOG_FILE_PATH%/}/$LOG_FILE_NAME"

# Function to log messages with timestamps
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check required tools
check_required_tools() {
    local missing_tools=()
    local required_tools=("curl" "ping" "traceroute" "nslookup")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "ERROR: The following required tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo "Please install them and try again."
        exit 10
    fi
}

# Function to perform diagnostics
perform_diagnostics() {
    local reason="$1"
    local domain=$(echo "$ENDPOINT" | sed -E 's|https?://([^/]+).*|\1|')

    log "ERROR: Service check failed - $reason"
    log "INFO: Starting diagnostics"

    log "INFO: DNS lookup results:"
    nslookup "$domain" 2>&1 | while read -r line; do log "  $line"; done

    log "INFO: Ping test results:"
    ping -c 4 "$domain" 2>&1 | while read -r line; do log "  $line"; done

    log "INFO: Traceroute results:"
    traceroute -m 15 "$domain" 2>&1 | while read -r line; do log "  $line"; done

    log "INFO: HTTP headers check:"
    curl -I "$ENDPOINT" 2>&1 | while read -r line; do log "  $line"; done

    log "INFO: Diagnostics completed!"

    exit 1
}

check_endpoint() {
    # Attempt to contact the endpoint
    response=$(curl -s --max-time 10 -w "\nHTTP_STATUS:%{http_code}" "$ENDPOINT" || true)

    # Ensure response is not empty
    if [[ -z "$response" ]]; then
        perform_diagnostics "No response from server (curl failed or returned empty)"
    fi

    # Extract status code and clean it
    status_code=$(echo "$response" | grep "HTTP_STATUS:" | cut -d':' -f2 | tr -d '\r')

    # Extract body (everything before the last line)
    body=$(echo "$response" | sed '$d')

    # Case handling based on HTTP status code
    case "$status_code" in
        000)
            echo "ERROR: Service check failed. See $LOG_FILE for diagnostic details."
            perform_diagnostics "Could not connect to endpoint — possible DNS issue or invalid URL"
            ;;
        ''|*[!0-9]*)
            echo "ERROR: Service check failed. See $LOG_FILE for diagnostic details."
            perform_diagnostics "Invalid or missing HTTP status code from endpoint"
            ;;
        200)
            if ! echo "$body" | grep -iq "$DESIRED_STATUS"; then
                echo "ERROR: Service check failed. See $LOG_FILE for diagnostic details."
                perform_diagnostics "Keyword '$DESIRED_STATUS' not found in response body."
                
            fi
            echo "SUCCESS"
            exit 0
            ;;
        *)
            perform_diagnostics "HTTP status code is $status_code, expected 200"
            ;;
    esac
}

# Ensure log directory and file are set up
if [ ! -f "$LOG_FILE" ]; then
    LOG_DIR=$(dirname "$LOG_FILE")
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" || {
            echo "ERROR: Could not create log directory: $LOG_DIR"
            exit 11
        }
    fi

    touch "$LOG_FILE" || {
        echo "ERROR: Could not create log file: $LOG_FILE"
        exit 12
    }

    echo "INFO: The log file created."
else
    > "$LOG_FILE"
    echo "INFO: The log file exists, clearing."
fi

# Run checks
check_required_tools
check_endpoint
