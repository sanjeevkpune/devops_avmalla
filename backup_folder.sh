#!/bin/bash
# backup_folder.sh
# Usage: ./backup_folder.sh /path/to/folder
if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/folder"
    exit 1
fi
SOURCE_DIR="$1"
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Directory '$SOURCE_DIR' does not exist."
    exit 2
fi
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="$(basename "$SOURCE_DIR")_backup_$TIMESTAMP.tar.gz"
tar -czf "$ARCHIVE_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
echo "Backup created: $ARCHIVE_NAME"