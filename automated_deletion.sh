#!/bin/bash

###############################################################################
# automated_deletion.sh
#
# Description:
#   This script automatically deletes files older than 30 days from a specified
#   directory and logs all deletions to a log file.
#
# Usage:
#   1. Set TARGET_DIR to the directory you want to clean.
#   2. Set LOG_FILE to the desired log file path.
#   3. Run the script: ./automated_deletion.sh
#
# Notes:
#   - Only files (not directories) older than 30 days are deleted.
#   - Each deleted file is logged.
#   - The script appends a completion timestamp to the log file.
###############################################################################

# Directory to clean (update this path before running)
TARGET_DIR="/path/to/your/directory"

# Log file location (update this path before running)
LOG_FILE="/path/to/your/deletion.log"

# Find and delete files older than 30 days, logging each deletion.
# -type f      : Only files
# -mtime +30   : Modified more than 30 days ago
# -print       : Print the file name before deletion (for logging)
# -exec rm -f {} \; : Delete the file
# Output and errors are appended to the log file.
find "$TARGET_DIR" -type f -mtime +30 -print -exec rm -f {} \; >> "$LOG_FILE" 2>&1

# Log completion timestamp
echo "Deletion completed on $(date)" >> "$LOG_FILE"