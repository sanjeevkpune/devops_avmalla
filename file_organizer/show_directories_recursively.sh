#!/bin/bash

# Usage: ./show_directories_recursively.sh [directory1] [directory2] ...

show_tree() {
    local dir="$1"
    echo "$dir"
    find "$dir" -print | sed -e "s;[^/]*/;|____;g;s;____|; |;g"
}

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [directory1] [directory2] ..."
    exit 1
fi

for dir in "$@"; do
    if [ -d "$dir" ]; then
        show_tree "$dir"
        echo
    else
        echo "Directory not found: $dir"
    fi
done