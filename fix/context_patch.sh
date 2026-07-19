#!/bin/bash
SYS_FILE="base_img/config/system_file_contexts"
EXT_FILE="base_img/config/system_ext_file_contexts"
VENDOR_FILE="stock/config/vendor_file_contexts"

add_line() {
    local file="$1"
    local line="$2"
    if ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        echo "Added: $file : $line"
    else
        echo "Skipped: $file : $line"
    fi
}

# com.qualcomm.location.apk (system_ext/priv-app)
add_line "$EXT_FILE" '/system_ext/priv-app/com\.qualcomm\.location(/.*)?    u:object_r:system_file:s0'

# fix/setup/apex/com.android.* (system/system/apex)
add_line "$SYS_FILE" '/system/system/apex(/.*)?    u:object_r:system_file:s0'

# my_ partitions
add_line "$SYS_FILE" '/system/my_bigball(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_carrier(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_company(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_engineering(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_heytap(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_manifest(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_preload(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_product(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_region(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_reserve(/.*)?    u:object_r:system_file:s0'
add_line "$SYS_FILE" '/system/my_stock(/.*)?    u:object_r:system_file:s0'

# VNDK apex
add_line "$EXT_FILE" '/system_ext/apex/com\.android\.vndk\.v30\.apex    u:object_r:system_file:s0'

# BPF
add_line "$SYS_FILE" '/system/system/etc/bpf(/.*)?    u:object_r:system_file:s0'

# power_delay fix stock/vendor/*
add_line "$VENDOR_FILE" '/vendor(/.*)?    u:object_r:vendor_file:s0'
