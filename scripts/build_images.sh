#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Building ext4 images"

mkdir -p "$OUT_DIR"

PARTITIONS=(system system_ext product vendor)

for partition in "${PARTITIONS[@]}"; do
    if [ "$partition" = "vendor" ]; then
        SRC_DIR="$TARGET_DIR/vendor"
        CONFIG_DIR="$TARGET_DIR/config"
    else
        SRC_DIR="$SOURCE_DIR/$partition"
        CONFIG_DIR="$SOURCE_DIR/config"
    fi

    FS_CONFIG="$CONFIG_DIR/${partition}_fs_config"
    FILE_CONTEXTS="$CONFIG_DIR/${partition}_file_contexts"

    if [ ! -d "$SRC_DIR" ]; then
        log_error "Missing directory: $SRC_DIR"
        exit 1
    fi

    if [ ! -f "$FS_CONFIG" ] || [ ! -f "$FILE_CONTEXTS" ]; then
        log_error "Missing fs_config or file_contexts for $partition"
        exit 1
    fi

    log_sub "Building $partition.img"

    RAW_SIZE=$(du -sb "$SRC_DIR" | cut -f1)
    PADDED_SIZE=$(( RAW_SIZE + RAW_SIZE * 3 / 100 ))
    BLOCK_SIZE=4096
    IMG_SIZE=$(( ( (PADDED_SIZE + BLOCK_SIZE - 1) / BLOCK_SIZE ) * BLOCK_SIZE ))

    make_ext4fs -T 0 -S "$FILE_CONTEXTS" -C "$FS_CONFIG" -L "$partition" -l "$IMG_SIZE" -a "$partition" "$OUT_DIR/${partition}.img" "$SRC_DIR"
done
