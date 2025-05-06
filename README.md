# Description

This repository contains a bash script for monitoring URL availability and performing diagnostics when failures occur. The script checks both HTTP response codes and specific content in the response body, providing detailed diagnostics when issues are detected.

## Features

- Verifies endpoint availability with HTTP status code 200 check
- Confirms response body contains expected keyword (default: "Success")
- Automatically runs comprehensive diagnostics on failure:
  - **nslookup**: Verifies the domain name can be resolved to an IP address, helping identify DNS configuration issues or outages
  - **ping**: Confirms basic network connectivity to the target host, showing packet loss and latency issues
  - **traceroute**: Maps the full network path to the target, revealing routing problems or bottlenecks
  - **curl**: Examines the server's response headers to identify server-side issues, redirects, or content delivery problems
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
git clone git@github.com:karenmartirosyan1/healthcheck_tools.git
cd healthcheck_tools
```

### Make the Script Executable

```bash
chmod +x check_endpoint.sh
```

## Usage

### Basic Usage

```bash
./check_endpoint.sh -e https://example.com/health
```
**Note:** Writing to `/var/log/` typically requires root privileges. You may need to run the script with `sudo` or specify an alternative log location.

### Full Options

```bash
./check_endpoint.sh -e <endpoint_url> [-s <desired_status>] [-l <log_file_path>] [-f <log_file_name>] [-h]
```

### Command Line Options

| Option | Long Option | Description | Default |
|--------|-------------|-------------|---------|
| `-e` | `--endpoint` | URL to check | https://sre-test-assignment.innervate.tech/health.html |
| `-s` | `--status` | Desired string in response body | "Success" |
| `-l` | `--logpath` | Directory to store the log file | /var/log/ |
| `-f` | `--logfile` | Log file name | diagnostics.log |
| `-h` | `--help` | Display help message | - |

### Examples

Check a specific endpoint:
```bash
./check_endpoint.sh -e https://myservice.example.com/health.html
```

Check with custom success keyword:
```bash
./check_endpoint.sh -e https://myservice.example.com/health.html -s "Healthy"
```

Use custom log location:
```bash
./check_endpoint.sh -e https://myservice.example.com/health.html -l /tmp/ -f my_service_health.log
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
