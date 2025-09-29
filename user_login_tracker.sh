#!/bin/bash
###############################################################################
# user_login_tracker.sh
#
# Description:
#   Monitors and logs user login events using 'who' and 'last' commands.
#   Logs are stored in /var/log/user_login_tracker.log (customizable).
#
# Usage:
#   ./user_login_tracker.sh [--mode who|last] [--logfile /path/to/logfile]
#
# Author: GitHub Copilot
# Date: 2024-06
###############################################################################

# Default log file location
LOGFILE="user_login_tracker.log"
MODE="who"

# Print usage information
usage() {
    echo "Usage: $0 [--mode who|last] [--logfile /path/to/logfile]"
    echo "  --mode     : Use 'who' (current logins) or 'last' (recent logins). Default: who"
    echo "  --logfile  : Specify log file location. Default: /var/log/user_login_tracker.log"
    exit 1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                MODE="$2"
                shift 2
                ;;
            --logfile)
                LOGFILE="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Ensure log file is writable
init_logfile() {
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE" 2>/dev/null
    fi
    if [ ! -w "$LOGFILE" ]; then
        echo "Error: Cannot write to log file $LOGFILE"
        exit 2
    fi
}

# Log message with timestamp
log_msg() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOGFILE"
}

# Monitor current logins using 'who'
monitor_who() {
    log_msg "=== Current user logins (who) ==="
    who | while read line; do
        log_msg "$line"
    done
}

# Monitor recent logins using 'last'
monitor_last() {
    log_msg "=== Recent user logins (last) ==="
    last | while read line; do
        log_msg "$line"
    done
}

# Main function
main() {
    parse_args "$@"
    init_logfile

    case "$MODE" in
        who)
            monitor_who
            ;;
        last)
            monitor_last
            ;;
        *)
            echo "Invalid mode: $MODE"
            usage
            ;;
    esac
}

main "$@"