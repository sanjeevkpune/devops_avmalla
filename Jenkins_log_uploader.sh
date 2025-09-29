#!/bin/bash

###############################################################################
# Jenkins Log Uploader Script
# Description: Uploads all Jenkins build logs to a specified AWS S3 bucket,
#              preserving the job/build directory structure.
# Author:      [Your Name]
# Date:        [Date]
###############################################################################

set -euo pipefail  # Enable strict error handling

#---------------------------#
# Configuration Parameters  #
#---------------------------#
JENKINS_HOME="/var/lib/jenkins"                       # Jenkins home directory
S3_BUCKET="s3://your-s3-bucket-name/jenkins-logs"      # Target S3 bucket path
MULTIPART_THRESHOLD=$((50 * 1024 * 1024))              # 50MB threshold for multipart upload

#---------------------------#
# Function Definitions      #
#---------------------------#

# Function: log_error
# Description: Logs error messages to stderr.
log_error() {
    echo "Error: $1" >&2
}

# Function: upload_log_file
# Description: Uploads a single log file to S3, using multipart if large.
upload_log_file() {
    local LOGFILE="$1"
    local S3_PATH="$2"

    if [ ! -r "$LOGFILE" ]; then
        log_error "Cannot read log file: $LOGFILE"
        return 1
    fi

    local FILE_SIZE
    FILE_SIZE=$(stat -c%s "$LOGFILE" 2>/dev/null || stat -f%z "$LOGFILE" 2>/dev/null)
    if [ -z "$FILE_SIZE" ]; then
        log_error "Unable to determine file size for: $LOGFILE"
        return 1
    fi

    # Use multipart upload for large files
    if [ "$FILE_SIZE" -ge "$MULTIPART_THRESHOLD" ]; then
        if aws s3 cp "$LOGFILE" "$S3_PATH" --expected-size "$FILE_SIZE"; then
            echo "Multipart uploaded: $LOGFILE -> $S3_PATH"
        else
            log_error "Multipart upload failed: $LOGFILE"
            return 1
        fi
    else
        if aws s3 cp "$LOGFILE" "$S3_PATH"; then
            echo "Uploaded: $LOGFILE -> $S3_PATH"
        else
            log_error "Upload failed: $LOGFILE"
            return 1
        fi
    fi
    return 0
}

# Function: upload_logs
# Description: Finds and uploads Jenkins build logs to S3.
upload_logs() {
    local LOGFILES
    LOGFILES=$(find "$JENKINS_HOME/jobs" -type f -name "log" 2>/dev/null)
    if [ -z "$LOGFILES" ]; then
        log_error "No Jenkins build logs found."
        return 1
    fi

    while IFS= read -r LOGFILE; do
        # Compute relative path to preserve job/build structure in S3
        REL_PATH="${LOGFILE#$JENKINS_HOME/}"
        S3_PATH="$S3_BUCKET/$REL_PATH"

        upload_log_file "$LOGFILE" "$S3_PATH"
    done <<< "$LOGFILES"
}

#---------------------------#
# Main Script Execution     #
#---------------------------#

# Check if AWS CLI is installed
if ! command -v aws &>/dev/null; then
    log_error "AWS CLI is not installed. Please install it and configure credentials."
    exit 1
fi

# Check if Jenkins jobs directory exists
if [ ! -d "$JENKINS_HOME/jobs" ]; then
    log_error "Jenkins jobs directory not found at $JENKINS_HOME/jobs"
    exit 1
fi

# Start log upload process
if ! upload_logs; then
    log_error "Log upload process encountered errors."
    exit 1
fi

exit 0