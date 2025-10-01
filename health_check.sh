#!/usr/bin/env bash

set -e -u -o pipefail # Exit on error and undefined variable, fail on pipe errors

LOGFILE="health_check.log" # Define the log file name

# Create the functions for usage
usage() {
  echo "Usage: $0 <server_ip_or_hostname> [port]" >&2
  exit 2
}

ts() { date '+%Y-%m-%d %H:%M:%S %z'; } # Timestamp function
log() { printf '[%s] %s\n' "$(ts)" "$1" >> "$LOGFILE"; } # Logging function

# --- Args / validation ---
[[ $# -lt 1 ]] && usage # Require at least one argument
SERVER="$1" # First argument is server
PORT="${2:-80}" # Second argument is port, default to 80

# Basic port validation
# Port must be a number between 1 and 65535
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then 
  echo "Invalid port: $PORT" >&2
  exit 2 # Exit with error code 2 for invalid usage
fi

for cmd in ping curl df awk date; do # Check for required commands
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 2; } # Exit if command not found
done

# --- Ping Test ---
log "Ping Test: Pinging ${SERVER}" # Log the ping attempt
# Ping the server with 3 packets and 3 seconds timeout
if ping -c 3 -W 3 "$SERVER" >/dev/null 2>&1; then 
  echo "Server is reachable."
  log "Ping Test: SUCCESS"
else
  log "Ping Test: FAILED - Server unreachable"
  echo "Server unreachable" >&2
  exit 1
fi

# --- HTTP/S Check (via curl) ---
SCHEME="http" # Default scheme
[[ "$PORT" = "443" ]] && SCHEME="https" # Use https if port is 443
URL="${SCHEME}://${SERVER}:${PORT}/" # Construct the URL

log "HTTP/S Check: Checking ${URL}" # Log the HTTP/S check attempt
# Use curl to check the HTTP status code with a 5 second timeout
HTTP_CODE="$(curl -ksS -m 5 -o /dev/null -w '%{http_code}' -I "$URL")"
CURL_EXIT=$?

# Check for successful HTTP codes (2xx or 3xx)
if [[ $CURL_EXIT -eq 0 && "$HTTP_CODE" =~ ^(2|3)[0-9]{2}$ ]]; then 
  echo "Web service on port ${PORT} is UP."
  log "HTTP/S Check: UP (HTTP ${HTTP_CODE})"
else
  echo "Web service on port ${PORT} is DOWN."
  if [[ $CURL_EXIT -ne 0 ]]; then
    log "HTTP/S Check: DOWN (curl exit ${CURL_EXIT})"
  else
    log "HTTP/S Check: DOWN (HTTP ${HTTP_CODE})"
  fi
fi

# --- Disk Usage (/) ---
read -r Percentage Used Total <<<"$(df -hP / | awk 'NR==2{print $5, $3, $2}')" # Get disk usage for root filesystem
echo "Disk usage on / is ${PERCENT}." # Display disk usage
log "Disk Usage: / ${PERCENT} used (${USED}/${TOTAL})" # Log disk usage

echo "Results logged to ${LOGFILE}"
exit 0
