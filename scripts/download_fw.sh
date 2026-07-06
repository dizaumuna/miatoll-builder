#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

require_var SOURCE_FIRMWARE_URL

log_step "Downloading source firmware"

mkdir -p "$TEMP_DIR"

if ! command -v aria2c &>/dev/null; then
    log_sub "Installing aria2"
    sudo apt-get update -y
    sudo apt-get install -y aria2
fi

log_sub "Downloading $SOURCE_FIRMWARE_URL"

aria2c -x 16 -s 16 -k 1M \
    --dir="$TEMP_DIR" \
    --out="source_firmware.zip" \
    "$SOURCE_FIRMWARE_URL"

if [ ! -f "$TEMP_DIR/source_firmware.zip" ]; then
    log_error "Failed to download source firmware"
    exit 1
fi
