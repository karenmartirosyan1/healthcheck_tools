# Description

This repository contains a bash script for monitoring URL availability and performing diagnostics when failures occur. The script checks both HTTP response codes and specific content in the response body, providing detailed diagnostics when issues are detected.

## Features

- Verifies endpoint availability with HTTP status code 200 check
- Confirms response body contains expected keyword (default: "Success")
- Automatically runs diagnostics on failure
- Detailed logging with timestamps
- Customizable log file location
- Command-line options for all parameters
- Pre-flight dependency checks
- Clear error reporting with specific exit codes

## Prerequisites

The script requires the following tools:
- [curl](https://linux.die.net/man/1/curl) - Command line tool for transferring data with URLs
- [ping](https://linux.die.net/man/8/ping) - Network utility to test reachability of hosts
- [traceroute](https://linux.die.net/man/8/traceroute) - Network diagnostic tool for displaying the route to a destination
- [nslookup](https://linux.die.net/man/1/nslookup) - Tool to query DNS servers for domain name or IP mapping

## Installation

### Clone the Repository

```bash
git clone https://github.com/yourusername/url-health-check.git
cd url-health-check
```

### Make the Script Executable

```bash
chmod +x health_check.sh
```

## Usage

### Basic Usage

```bash
./health_check.sh -e https://example.com/health
```
**Note:** Writing to `/var/log/` typically requires root privileges. You may need to run the script with `sudo` or specify an alternative log location.

### Full Options

```bash
./health_check.sh -e <endpoint_url> [-s <desired_status>] [-l <log_file_path>] [-f <log_file_name>] [-h]
```

### Command Line Options

| Option | Long Option | Description | Default |
|--------|-------------|-------------|---------|
| `-e` | `--endpoint` | URL to check (required) | - |
| `-s` | `--status` | Desired string in response body | "Success" |
| `-l` | `--logpath` | Directory to store the log file | /var/log/ |
| `-f` | `--logfile` | Log file name | diagnostics.log |
| `-h` | `--help` | Display help message | - |

### Examples

Check a specific endpoint:
```bash
./health_check.sh -e https://myservice.example.com/health.html
```

Check with custom success keyword:
```bash
./health_check.sh -e https://myservice.example.com/health.html -s "Healthy"
```

Use custom log location:
```bash
./health_check.sh -e https://myservice.example.com/health.html -l /tmp/ -f my_service_health.log
```

## Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success - endpoint is available and contains the expected keyword |
| 1 | General script error or service check failure |
| 10 | Required tools are missing |
| 11 | Could not create log directory |
| 12 | Could not create log file |

## Log File

The script creates a detailed log file with timestamps for all operations and diagnostic information. By default, logs are written to `/var/log/diagnostics.log`.
