#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Downloading tools"

mkdir -p "$TEMP_DIR"

log_sub "Downloading payload-dumper-go"
PD_URL="https://github.com/ssut/payload-dumper-go/releases/download/1.3.0/payload-dumper-go_1.3.0_linux_amd64.tar.gz"
PD_TAR="$TEMP_DIR/payload-dumper-go.tar.gz"
PD_EXTRACT_DIR="$TEMP_DIR/payload-dumper-go"

mkdir -p "$PD_EXTRACT_DIR"
wget -q -O "$PD_TAR" "$PD_URL"
tar -xzf "$PD_TAR" -C "$PD_EXTRACT_DIR"

PD_BIN="$(find "$PD_EXTRACT_DIR" -type f -name "payload-dumper-go")"

if [ -z "$PD_BIN" ]; then
    log_error "payload-dumper-go binary not found in archive"
    exit 1
fi

chmod +x "$PD_BIN"
sudo mv "$PD_BIN" /usr/local/bin/payload-dumper-go
rm -rf "$PD_TAR" "$PD_EXTRACT_DIR"

log_sub "Downloading extract.erofs"
EROFS_URL="https://raw.githubusercontent.com/ColdWindScholar/MIO-KITCHEN-SOURCE/refs/heads/main/bin/Linux/x86_64/extract.erofs"

wget -q -O "$TEMP_DIR/extract.erofs" "$EROFS_URL"
chmod +x "$TEMP_DIR/extract.erofs"
sudo mv "$TEMP_DIR/extract.erofs" /usr/local/bin/extract.erofs

log_sub "Downloading make_ext4fs"
MAKE_EXT4FS_URL="https://raw.githubusercontent.com/ColdWindScholar/MIO-KITCHEN-SOURCE/refs/heads/main/bin/Linux/x86_64/make_ext4fs"

wget -q -O "$TEMP_DIR/make_ext4fs" "$MAKE_EXT4FS_URL"
chmod +x "$TEMP_DIR/make_ext4fs"
sudo mv "$TEMP_DIR/make_ext4fs" /usr/local/bin/make_ext4fs

log_sub "Downloading lpmake"
LPMAKE_URL="https://raw.githubusercontent.com/ColdWindScholar/MIO-KITCHEN-SOURCE/refs/heads/main/bin/Linux/x86_64/lpmake"

wget -q -O "$TEMP_DIR/lpmake" "$LPMAKE_URL"
chmod +x "$TEMP_DIR/lpmake"
sudo mv "$TEMP_DIR/lpmake" /usr/local/bin/lpmake
