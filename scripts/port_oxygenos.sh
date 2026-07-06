#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

log_step "Porting OxygenOS"

cd "$SOURCE_DIR"

for dir in my_*/; do
    name="$(basename "$dir")"
    log_sub "Moving $name into system"
    mv "$name" system/
    echo "import /$name/build.prop" >> system/build.prop
done

log_sub "Commenting ro.product.first_api_level"
sed -i "s/^ro.product.first_api_level/#ro.product.first_api_level/" system/my_manifest/build.prop

log_sub "Copying group and passwd to target vendor"
cp "$SOURCE_DIR/vendor/etc/group" "$TARGET_DIR/vendor/etc/group"
cp "$SOURCE_DIR/vendor/etc/passwd" "$TARGET_DIR/vendor/etc/passwd"

log_sub "Copying com.android.vndk.v30.apex"
mkdir -p "$SOURCE_DIR/system_ext/apex"
cp "$PATCHES_DIR/apex/com.android.vndk.v30.apex" "$SOURCE_DIR/system_ext/apex/com.android.vndk.v30.apex"
