#!/bin/bash

# Directory containing the log files
LOG_DIR="/opt/nginx-proxy-manager/data/logs"

# Function to parse a single log file
parse_log_file() {
  local log_file=$1
  echo "Parsing log file: $log_file"

  # Read and parse each line in the log file
  while IFS= read -r line; do
    # Extract components using awk and regular expressions
    local timestamp=$(echo "$line" | awk -F'[][]' '{print $2}')
    local status=$(echo "$line" | awk '{print $4}')
    local method=$(echo "$line" | awk '{print $7}')
    local url=$(echo "$line" | awk '{print $9 $10}')
    local client_ip=$(echo "$line" | grep -oP '(?<=\[Client )[^]]+')

    # Display the extracted information
    echo "Timestamp: $timestamp, Status: $status, Method: $method, Client IP: $client_ip, URL: $url"
  done < "$log_file"
}

# Parse each proxy-host access log file
for log_file in "$LOG_DIR"/proxy-host-*access.log; do
  parse_log_file "$log_file"
done
