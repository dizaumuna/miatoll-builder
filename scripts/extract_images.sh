#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Extracting source images"

cd "$SOURCE_DIR"

IMG_FILES=(*.img)

if [ ! -e "${IMG_FILES[0]}" ]; then
    log_error "No .img files found in source/"
    exit 1
fi

for img in "${IMG_FILES[@]}"; do
    log_sub "Extracting $img"
    extract.erofs -i "$img" -x -s -o .
done
