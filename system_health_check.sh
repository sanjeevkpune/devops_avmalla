#!/bin/bash
# system_health_check.sh
# Checks CPU load, memory usage, and disk space, then sends an alert if thresholds are exceeded.

# Thresholds (customize as needed)
CPU_THRESHOLD=80      # in percent
MEM_THRESHOLD=80      # in percent
DISK_THRESHOLD=90     # in percent
ALERT_EMAIL="admin@example.com"

# Function to send alert
send_alert() {
    local message="$1"
    echo "$message" | mail -s "System Health Alert on $(hostname)" "$ALERT_EMAIL"
}

# Check CPU Load (average over 1 minute)
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
CPU_LOAD_INT=${CPU_LOAD%.*}
if [ "$CPU_LOAD_INT" -ge "$CPU_THRESHOLD" ]; then
    send_alert "CPU load is high: ${CPU_LOAD}% (Threshold: ${CPU_THRESHOLD}%)"
fi

# Check Memory Usage
MEM_TOTAL=$(free | awk '/Mem:/ {print $2}')
MEM_USED=$(free | awk '/Mem:/ {print $3}')
MEM_USAGE=$((MEM_USED * 100 / MEM_TOTAL))
if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
    send_alert "Memory usage is high: ${MEM_USAGE}% (Threshold: ${MEM_THRESHOLD}%)"
fi

# Check Disk Usage (root partition)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    send_alert "Disk usage is high: ${DISK_USAGE}% (Threshold: ${DISK_THRESHOLD}%)"
fi

# End of script