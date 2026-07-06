#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Porting HyperOS"

cd "$SOURCE_DIR"

log_sub "Appending mi_ext build.prop into product build.prop"
cat mi_ext/etc/build.prop >> product/etc/build.prop

for dir in app overlay priv-app framework; do
    if [ -d "mi_ext/product/$dir" ]; then
        log_sub "Copying mi_ext/product/$dir into product"
        mkdir -p "product/$dir"
        cp -a "mi_ext/product/$dir/." "product/$dir/"
    fi
done

log_sub "Copying device_features patches"
mkdir -p product/etc/device_features
cp -a "$PATCHES_DIR/device_features/." product/etc/device_features/

log_sub "Copying displayconfig patches"
mkdir -p product/etc/displayconfig
cp -a "$PATCHES_DIR/displayconfig/." product/etc/displayconfig/

log_sub "Copying overlay patches"
mkdir -p product/overlay
cp -a "$PATCHES_DIR/overlay/." product/overlay/
