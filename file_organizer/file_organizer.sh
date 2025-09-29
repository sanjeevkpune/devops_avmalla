#!/bin/bash
# file_organizer.sh
# Scans a directory and organizes files into folders based on their extensions.
# Usage: ./file_organizer.sh /path/to/directory

########################################
# Function: print_usage
# Prints usage information.
########################################
print_usage() {
    echo "Usage: $0 /path/to/directory"
}

########################################
# Function: get_folder_name
# Maps file extensions to folder names.
# Arguments:
#   $1 - file extension (e.g., jpg)
# Returns:
#   Folder name (e.g., Images)
########################################
get_folder_name() {
    local ext="${1,,}" # convert to lowercase
    case "$ext" in
        jpg|jpeg|png|gif|bmp|tiff) echo "Images" ;;
        pdf|doc|docx|txt|xls|xlsx|ppt|pptx) echo "Documents" ;;
        mp3|wav|flac|aac) echo "Audio" ;;
        mp4|mkv|avi|mov|wmv) echo "Videos" ;;
        zip|tar|gz|rar|7z) echo "Archives" ;;
        exe|sh|bat|py|js|rb|pl|php|c|cpp|java) echo "Scripts" ;;
        *) echo "Others" ;;
    esac
}

########################################
# Function: organize_files
# Organizes files in the given directory.
# Arguments:
#   $1 - target directory
########################################
organize_files() {
    local target_dir="$1"
    local script_name="$(basename "$0")"
    shopt -s nullglob
    for file in "$target_dir"/*; do
        if [ -f "$file" ]; then
            # Skip moving the script itself if running from its own directory
            if [[ "$target_dir" == "$(dirname "$0")" && "$(basename "$file")" == "$script_name" ]]; then
                continue
            fi
            ext="${file##*.}"
            folder=$(get_folder_name "$ext")
            dest="$target_dir/$folder"
            mkdir -p "$dest"
            mv "$file" "$dest/"
            echo "Moved: $(basename "$file") -> $folder/"
        fi
    done
    shopt -u nullglob
}

########################################
# Main Script Execution
########################################
if [ $# -ne 1 ]; then
    print_usage
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Error: Directory '$1' does not exist."
    exit 2
fi

organize_files "$1"