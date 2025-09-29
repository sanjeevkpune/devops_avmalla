#!/bin/bash

###############################################################################
# log_analyzer.sh
#
# Description:
#   Parses a CSV web server log file and counts requests per IP address.
#   Assumes the log file is named 'E-commerce_Website_Logs.csv' and is located
#   in the current working directory. The IP address is expected to be in the
#   4th column of the CSV file.
#
# Usage:
#   ./log_analyzer.sh
#
# Output:
#   Prints a sorted list of IP addresses and the number of requests from each,
#   in descending order of request count.
###############################################################################

# Path to the log file (update if needed)
LOG_FILE="$(pwd)/E-commerce_Website_Logs.csv"

########################################
# Function: check_log_file
# Checks if the log file exists in the current directory.
# Exits with error if not found.
########################################
check_log_file() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Log file '$LOG_FILE' not found in current directory."
        exit 1
    fi
}

########################################
# Function: count_requests_per_ip
# Extracts IP addresses from the 4th column of the CSV,
# counts occurrences, and sorts them in descending order.
# Skips the header row.
########################################
count_requests_per_ip() {
    # -F','      : Set field separator to comma
    # NR>1       : Skip header row
    # print $4   : Print the 4th column (IP address)
    # sort       : Sort IPs
    # uniq -c    : Count occurrences of each IP
    # sort -nr   : Sort counts numerically, descending
    awk -F',' 'NR>1 {print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr
}

########################################
# Main script execution
########################################
main() {
    check_log_file
    echo "Requests per IP address:"
    count_requests_per_ip
}

main