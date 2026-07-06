#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Building super.img"

PARTITIONS=(system system_ext product vendor)
SUPER_SIZE=$((8*1024*1024*1024))

PARTITION_ARGS=()
IMAGE_ARGS=()

for partition in "${PARTITIONS[@]}"; do
    IMG_PATH="$OUT_DIR/${partition}.img"

    if [ ! -f "$IMG_PATH" ]; then
        log_error "Missing image: $IMG_PATH"
        exit 1
    fi

    IMG_SIZE=$(stat -c%s "$IMG_PATH")

    log_sub "Adding $partition ($IMG_SIZE bytes)"

    PARTITION_ARGS+=(--partition "${partition}:readonly:${IMG_SIZE}:qti_dynamic_partitions")
    IMAGE_ARGS+=(--image "${partition}=${IMG_PATH}")
done

log_sub "Running lpmake"

lpmake \
    --metadata-size 65536 \
    --metadata-slots 2 \
    --device "super:${SUPER_SIZE}" \
    --group "qti_dynamic_partitions:${SUPER_SIZE}" \
    "${PARTITION_ARGS[@]}" \
    "${IMAGE_ARGS[@]}" \
    --output "$OUT_DIR/super.img"
