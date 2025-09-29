#!/bin/bash

# Usage: ./disk_usage_reporter.sh /path/to/directory

TARGET_DIR="${1:-.}"

du -sh "$TARGET_DIR"/* 2>/dev/null | sort -hr