#!/bin/bash

# Thanks:
# MIO kitchen owner, contributors
# Antigravity & IDE
# Claude, Gemini

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/base_img"
CONFIG_DIR="$BASE_DIR/config"
OUT_DIR="$SCRIPT_DIR/out"
set -euo pipefail
PARTITIONS=(system system_ext product vendor)

# -- helpers
log () {
    echo " - $1"
}

log_proc () {
    echo "   - $1"
}

error () {
    echo "  ! $1"
}

warn () {
    echo "  ! $1"
}
sudo mv binaries/* /usr/local/bin

log "Downloading given target firmware using aria2c."
aria2c -x8 -s8 "https://gauss-compotaauto-c-cn.allawnfs.com/remove-e4ef5e6e9cb7c89e7d1c1c779fd171c1/g-10eab6008d5642cf42abd2aa41f847cb/component-ota/26/04/10/70b2e0b5874d4b06aa56e4a51bb3eba7.zip?sign=f2d2b2f2f3556b687c310df7be058e3a&t=6a5a24be&AWSAccessKeyId=ayjy7KyLVHvDqDax6_KqJgtBeORTJARg9MSGiL66&Expires=1784294102&Signature=hNlcrqzUzXmUQ9LVXx5NyVYual8%3D" -o base.zip
log_proc "Unzipping target firmware."
unzip base.zip payload.bin -d base_images/

# run pdg
log "Extracting images from bin file."
payload-dumper-go -o base base_images/payload.bin > /dev/null

log_proc "Cleaning up before continuining."
rm -rf base_images base.zip

mkdir temp
mv base/my_*.img temp/ && mv base/system.img temp/ && mv base/system_ext.img temp/
rm -rf base/*
mv temp/* base/ && rm -rf temp
log "Extracting OnePlus partitions [erofs]"
extract.erofs -x -i base/my_bigball.img -s -o base_img/
extract.erofs -x -i base/my_carrier.img -s -o base_img/
extract.erofs -x -i base/my_engineering.img -s -o base_img/
extract.erofs -x -i base/my_heytap.img -s -o base_img/
extract.erofs -x -i base/my_manifest.img -s -o base_img/
extract.erofs -x -i base/my_product.img -s -o base_img/
extract.erofs -x -i base/my_region.img -s -o base_img/
extract.erofs -x -i base/my_stock.img -s -o base_img/
extract.erofs -x -i base/system.img -s -o base_img/
extract.erofs -x -i base/system_ext.img -s -o base_img/

# the output will be like:
# base_img/system/
# base_img/config/system_fs_config and other configs

log_proc "Cleaning up before continuining."
rm -rf base/*

log "Fixing OnePlus identity."
sed -i '/^ro\.product\.first_api_level/s/^/#/' base_img/my_manifest/build.prop
sed -i '/^ro\.build\.version\.oplusrom\.display=/ s/$/ || by diza/' base_img/my_manifest/build.prop

log "Fixing partitions."
echo "import /my_bigball/build.prop" >> base_img/system/system/build.prop
echo "import /my_carrier/build.prop" >> base_img/system/system/build.prop
echo "import /my_engineering/build.prop" >> base_img/system/system/build.prop
echo "import /my_heytap/build.prop" >> base_img/system/system/build.prop
echo "import /my_manifest/build.prop" >> base_img/system/system/build.prop
echo "import /my_product/build.prop" >> base_img/system/system/build.prop
echo "import /my_region/build.prop" >> base_img/system/system/build.prop
echo "import /my_stock/build.prop" >> base_img/system/system/build.prop

log_proc "Fixing CPU info."
echo "ro.product.oplus.cpuinfo=Snapdragon 720G" >> base_img/my_manifest/build.prop

log_proc "Fixing DPI for miatoll."
FILE="base_img/my_manifest/build.prop"

if grep -q '^ro\.sf\.lcd_density=' "$FILE"; then
    sed -i 's/^ro\.sf\.lcd_density=.*/ro.sf.lcd_density=480/' "$FILE"
else
    echo 'ro.sf.lcd_density=480' >> "$FILE"
fi
log_proc "Fixing model name."
sed -i 's/^ro\.product\.name=.*/ro.product.name=ATOLL-AB/' base_img/my_manifest/build.prop
sed -i 's/^ro\.product\.model=.*/ro.product.model=ATOLL-AB/' base_img/my_manifest/build.prop

log_proc "Fixing market name."
sed -i 's/^ro\.vendor\.oplus\.market\.name=.*/ro.vendor.oplus.market.name=Redmi Note 9 Pro/' base_img/my_manifest/build.prop
sed -i 's/^ro\.vendor\.oplus\.market\.enname=.*/ro.vendor.oplus.market.enname=Redmi Note 9 Pro/' base_img/my_manifest/build.prop

log_proc "Fixing sharp image resolution."
grep -q '^ro\.oplus\.density\.fhd_default=' base_img/my_manifest/build.prop \
&& sed -i 's/^ro\.oplus\.density\.fhd_default=.*/ro.oplus.density.fhd_default=480/' base_img/my_manifest/build.prop \
|| echo 'ro.oplus.density.fhd_default=480' >> base_img/my_manifest/build.prop

grep -q '^ro\.oplus\.density\.qhd_default=' base_img/my_manifest/build.prop \
&& sed -i 's/^ro\.oplus\.density\.qhd_default=.*/ro.oplus.density.qhd_default=480/' base_img/my_manifest/build.prop \
|| echo 'ro.oplus.density.qhd_default=480' >> base_img/my_manifest/build.prop

grep -q '^ro\.oplus\.resolution\.low=' base_img/my_manifest/build.prop \
&& sed -i 's/^ro\.oplus\.resolution\.low=.*/ro.oplus.resolution.low=1080,2400/' base_img/my_manifest/build.prop \
|| echo 'ro.oplus.resolution.low=1080,2400' >> base_img/my_manifest/build.prop

grep -q '^ro\.oplus\.resolution\.high=' base_img/my_manifest/build.prop \
&& sed -i 's/^ro\.oplus\.resolution\.high=.*/ro.oplus.resolution.high=1080,2400/' base_img/my_manifest/build.prop \
|| echo 'ro.oplus.resolution.high=1080,2400' >> base_img/my_manifest/build.prop

log "Disabling liquid glass in system."
echo "persist.sys.feature.hdr_vision_app=1" >> base_img/my_manifest/build.prop
echo "persist.sys.feature.colormanager.v1.plus=1" >> base_img/my_manifest/build.prop
echo "persist.sys.renderengine.maxLuminance=500" >> base_img/my_manifest/build.prop
echo "ro.surface_flinger.media_panel_bg_blur=1" >> base_img/my_manifest/build.prop
echo "ro.oplus.animationlevel=1" >> base_img/my_manifest/build.prop
echo "ro.oplus.gaussianlevel=1" >> base_img/my_manifest/build.prop
echo "ro.launcher.blur.appLaunch=0" >> base_img/my_manifest/build.prop
echo "vendor.display.enable_rounded_corner=1" >> base_img/my_manifest/build.prop
echo "ro.oplus.display.disable.volume_blur=1" >> base_img/my_manifest/build.prop
echo "disable_window_blurs=1" >> base_img/my_manifest/build.prop
echo "persist.sys.oplus.anim_level=3" >> base_img/my_manifest/build.prop
echo "persist.sys.wallpaperanimation.enable=true" >> base_img/my_manifest/build.prop
echo "ro.sf.blurs_are_caro=1" >> base_img/my_manifest/build.prop
echo "ro.sf.blurs_are_expensive=0" >> base_img/my_manifest/build.prop
echo "oplus_customize_settings_zoom_wallpaper_enable=1" >> base_img/my_manifest/build.prop

log "Cloning public miatoll vendor, branch ColorOS."
git clone --depth=1 https://github.com/dizaumuna/vendor.git -d stock -b COLOROS

log "Processing ColorOS setup fix by NezukoTM."
mv fix/setup/com.qualcomm.location.apk base_img/system_ext/priv-app/com.qualcomm.location/
log_proc "Moved file: com.qualcomm.location.apk to system_ext/priv-app/com.qualcomm.location"
mv fix/setup/apex/com.android.* base_img/system/system/apex/
log_proc "Moved file: fix/setup/apex/com.android.* to system/apex"

log "Processing VNDK patch."
mv fix/apex/com.android.vndk.v30.apex base_img/system_ext/apex/
log_proc "Moved file: com.android.vndk.v30.apex to system_ext/apex"
rm -rf base_img/system_ext/apex/com.android.vndk.v34.apex
log_proc "Deleted useless file: com.android.vndk.v34.apex"

log "Processing YouTube patch."
rm -rf base_img/system_ext/lib64/libavenhancements.so
rm -rf base_img/system_ext/lib/libavenhancements.so
rm -rf base_img/system_ext/lib64/liboplusstagefright.so 
rm -rf base_img/system_ext/lib/liboplusstagefright.so 

log "Processing BPF patch by NezukoTM."
mv fix/bpf/* base_img/system/system/etc/bpf/
log_proc "Moved file ipv6_offload.o to system/etc/bpf"
log_proc "Moved file oplus-netd.o to system/etc/bpf"

log "Processing power button delay fix by getthefckoutofheree."
mv fix/power_delay/* stock/vendor/

mkdir -p "$OUT_DIR"

log "Building OS images"

for partition in "${PARTITIONS[@]}"; do
    SRC_DIR="$BASE_DIR/$partition"
    FS_CONFIG="$CONFIG_DIR/${partition}_fs_config"
    FILE_CONTEXTS="$CONFIG_DIR/${partition}_file_contexts"

    if [ ! -d "$SRC_DIR" ]; then
        error "Folder didnt exists: $SRC_DIR"
        exit 1
    fi
    if [ ! -f "$FS_CONFIG" ]; then
        error "fs_config not found: $FS_CONFIG"
        exit 1
    fi
    if [ ! -f "$FILE_CONTEXTS" ]; then
        error "file_contexts not found: $FILE_CONTEXTS"
        exit 1
    fi

    log_proc "Building $partition.img"

    RAW_SIZE=$(du -sb "$SRC_DIR" | cut -f1)
    PADDED_SIZE=$(( RAW_SIZE + RAW_SIZE * 3 / 100 ))   # %3 padding
    BLOCK_SIZE=4096
    IMG_SIZE=$(( ( (PADDED_SIZE + BLOCK_SIZE - 1) / BLOCK_SIZE ) * BLOCK_SIZE ))

    make_ext4fs \
        -T 0 \
        -S "$FILE_CONTEXTS" \
        -C "$FS_CONFIG" \
        -L "$partition" \
        -l "$IMG_SIZE" \
        -a "$partition" \
        "$OUT_DIR/${partition}.img" \
        "$SRC_DIR"

    log "$partition.img's build is finished: $OUT_DIR/${partition}.img ($(du -h "$OUT_DIR/${partition}.img" | cut -f1))"
done
