#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

require_var IS_HYPEROS
require_var IS_OXYGENOS

log_step "Dumping images from payload.bin"

mkdir -p "$SOURCE_DIR"

if [ "$IS_OXYGENOS" = "true" ]; then
    PARTITIONS=(my_bigball my_carrier my_company my_engineering my_heytap my_manifest my_product my_region my_stock system system_ext product vendor)
    log_sub "Using OxygenOS partition list"
elif [ "$IS_HYPEROS" = "true" ]; then
    PARTITIONS=(system system_ext product)
    log_sub "Using HyperOS partition list"
else
    log_error "Both IS_HYPEROS and IS_OXYGENOS are false"
    exit 1
fi

PARTITION_LIST="$(IFS=,; echo "${PARTITIONS[*]}")"

log_sub "Partitions: $PARTITION_LIST"

payload-dumper-go \
    -o "$SOURCE_DIR" \
    -partitions "$PARTITION_LIST" \
    "$TEMP_DIR/payload.bin"
