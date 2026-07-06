#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

ZIP_PATH="$TEMP_DIR/source_firmware.zip"

if [ ! -f "$ZIP_PATH" ]; then
    log_error "Zip not found: $ZIP_PATH"
    exit 1
fi

log_step "Extracting payload.bin"

if ! command -v unzip &>/dev/null; then
    log_sub "Installing unzip"
    sudo apt-get update -y
    sudo apt-get install -y unzip
fi

log_sub "Unzipping payload.bin"
unzip -o "$ZIP_PATH" payload.bin -d "$TEMP_DIR"

if [ ! -f "$TEMP_DIR/payload.bin" ]; then
    log_error "Failed to extract payload.bin"
    exit 1
fi

log_sub "Removing zip"
rm -f "$ZIP_PATH"
