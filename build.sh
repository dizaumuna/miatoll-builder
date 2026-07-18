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

# -- input handling
# Usage:
#   ./build.sh                 -> downloads $BASE_FW, unpacks it (default CI behavior)
#   ./build.sh path/to/fw.zip  -> skips download, unzips local zip, then unpacks
#   ./build.sh path/to/payload.bin -> skips download AND unzip, unpacks directly
LOCAL_INPUT="${1:-}"

sudo mv binaries/* /usr/local/bin

mkdir -p base_images

if [ -n "$LOCAL_INPUT" ]; then
    if [ ! -f "$LOCAL_INPUT" ]; then
        error "Given local firmware path not found: $LOCAL_INPUT"
        exit 1
    fi

    case "$LOCAL_INPUT" in
        *.bin)
            log "Local payload.bin given ($LOCAL_INPUT), skipping download and unzip."
            cp "$LOCAL_INPUT" base_images/payload.bin
            ;;
        *.zip)
            log "Local firmware zip given ($LOCAL_INPUT), skipping download."
            log_proc "Unzipping target firmware."
            unzip -o "$LOCAL_INPUT" payload.bin -d base_images/
            ;;
        *)
            error "Unrecognized local input, expected .zip or .bin: $LOCAL_INPUT"
            exit 1
            ;;
    esac
else
    log "Downloading given target firmware using aria2c."
    aria2c -x8 -s8 "$BASE_FW" -o base.zip
    log_proc "Unzipping target firmware."
    unzip base.zip payload.bin -d base_images/
    rm -f base.zip
fi

# run pdg
log "Extracting images from bin file."
payload-dumper-go -o base base_images/payload.bin > /dev/null

log_proc "Cleaning up before continuining."
rm -rf base_images

mkdir temp
mv base/my_*.img temp/ && mv base/system.img temp/ && mv base/system_ext.img temp/ && mv base/product.img temp/
rm -rf base/*
mv temp/* base/ && rm -rf temp
log "Extracting OnePlus partitions [erofs]"
extract.erofs -x -i base/my_bigball.img -o base_img/
extract.erofs -x -i base/my_carrier.img -o base_img/
extract.erofs -x -i base/my_engineering.img -o base_img/
extract.erofs -x -i base/my_heytap.img -o base_img/
extract.erofs -x -i base/my_manifest.img -o base_img/
extract.erofs -x -i base/my_product.img -o base_img/
extract.erofs -x -i base/my_region.img -o base_img/
extract.erofs -x -i base/my_stock.img -o base_img/
extract.erofs -x -i base/system.img -o base_img/
extract.erofs -x -i base/product.img -o base_img/
extract.erofs -x -i base/system_ext.img -o base_img/

# the output will be like:
# base_img/system/
# base_img/config/system_fs_config and other configs

log_proc "Cleaning up before continuining."
rm -rf base/*

log "Replacing prop ro.product.first_api_level=34 with #ro.product.first_api_level=30."
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

log_proc "Replacing prop ro.product.oplus.cpuinfo with Snapdragon 720G."
echo "ro.product.oplus.cpuinfo=Snapdragon 720G" >> base_img/my_manifest/build.prop

log_proc "Replacing prop ro.sf.lcd_density with 480."
FILE="base_img/my_manifest/build.prop"

if grep -q '^ro\.sf\.lcd_density=' "$FILE"; then
    sed -i 's/^ro\.sf\.lcd_density=.*/ro.sf.lcd_density=480/' "$FILE"
else
    echo 'ro.sf.lcd_density=480' >> "$FILE"
fi
log_proc "Replacing prop ro.product.name and model with ATOLL-AB."
sed -i 's/^ro\.product\.name=.*/ro.product.name=ATOLL-AB/' base_img/my_manifest/build.prop
sed -i 's/^ro\.product\.model=.*/ro.product.model=ATOLL-AB/' base_img/my_manifest/build.prop

log_proc "Replacing prop ro.vendor.oplus.market.name and enname with Redmi Note 9 Pro."
sed -i 's/^ro\.vendor\.oplus\.market\.name=.*/ro.vendor.oplus.market.name=Redmi Note 9 Pro/' base_img/my_manifest/build.prop
sed -i 's/^ro\.vendor\.oplus\.market\.enname=.*/ro.vendor.oplus.market.enname=Redmi Note 9 Pro/' base_img/my_manifest/build.prop

log_proc "Replacing ro.oplus.density.fhd_default and qhd_default with 1080,2400."
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
git clone --depth=1 https://github.com/dizaumuna/vendor.git stock -b COLOROS

SYSTEM_FS_CONFIG="$CONFIG_DIR/system_fs_config"
SYSTEM_FILE_CONTEXTS="$CONFIG_DIR/system_file_contexts"
SYSTEM_EXT_FS_CONFIG="$CONFIG_DIR/system_ext_fs_config"
SYSTEM_EXT_FILE_CONTEXTS="$CONFIG_DIR/system_ext_file_contexts"
VENDOR_FS_CONFIG="stock/config/vendor_fs_config"
VENDOR_FILE_CONTEXTS="stock/config/vendor_file_contexts"

log "Processing ColorOS setup fix by NezukoTM."
cp -a fix/setup/com.qualcomm.location.apk base_img/system_ext/priv-app/com.qualcomm.location/
log_proc "Moved file: com.qualcomm.location.apk to system_ext/priv-app/com.qualcomm.location"

cp -a fix/setup/apex/com.android.* base_img/system/system/apex/
log_proc "Moved file: fix/setup/apex/com.android.* to system/apex"

log "Processing VNDK patch."
cp -a fix/apex/com.android.vndk.v30.apex base_img/system_ext/apex/
log_proc "Moved file: com.android.vndk.v30.apex to system_ext/apex"
rm -rf base_img/system_ext/apex/com.android.vndk.v34.apex
log_proc "Deleted useless file: com.android.vndk.v34.apex"

log "Processing YouTube patch."
rm -rf base_img/system_ext/lib64/libavenhancements.so
rm -rf base_img/system_ext/lib/libavenhancements.so
rm -rf base_img/system_ext/lib64/liboplusstagefright.so 
rm -rf base_img/system_ext/lib/liboplusstagefright.so 

log "Processing BPF patch by NezukoTM."
cp -a fix/bpf/* base_img/system/system/etc/bpf/
log_proc "Moved file ipv6_offload.o to system/etc/bpf"
log_proc "Moved file oplus-netd.o to system/etc/bpf"

log "Processing power button delay fix by getthefckoutofheree."
cp -a fix/power_delay/* stock/vendor/

log "Debloating system."
rm -rf base_img/my_stock/app/AIMemory
rm -rf base_img/my_stock/app/AIUnit
rm -rf base_img/my_stock/app/AIWidgets
rm -rf base_img/my_stock/app/AIWriter
rm -rf base_img/my_stock/app/BeaconLink
rm -rf base_img/my_stock/app/Browser
rm -rf base_img/my_stock/app/CarLink
rm -rf base_img/my_stock/app/ChildrenSpace
rm -rf base_img/my_stock/app/DigitalKeyFramework
rm -rf base_img/my_stock/app/DigitalWellBeing
rm -rf base_img/my_stock/app/Instant
rm -rf base_img/my_stock/app/InstantService
rm -rf base_img/my_stock/app/OplusOperationManual
rm -rf base_img/my_stock/app/OplusSecurityKeyboard
rm -rf base_img/my_stock/app/OWork
rm -rf base_img/my_stock/app/Pictorial
rm -rf base_img/my_stock/app/RomUpdate
rm -rf base_img/my_stock/app/SceneMode
rm -rf base_img/my_stock/app/SecurePay
rm -rf base_img/my_stock/app/SecurityGuard
rm -rf base_img/my_stock/app/ShareScreen
rm -rf base_img/my_stock/app/ViewTalk
rm -rf base_img/my_stock/app/TasWallet

rm -rf base_img/my_stock/del-app/BackupAndRestore
rm -rf base_img/my_stock/del-app/BrowserVideo
rm -rf base_img/my_stock/del-app/Calculator2
rm -rf base_img/my_stock/del-app/Calendar
rm -rf base_img/my_stock/del-app/FamilyGuard
rm -rf base_img/my_stock/del-app/FinShellWallet
rm -rf base_img/my_stock/del-app/Gamecenter
rm -rf base_img/my_stock/del-app/Health
rm -rf base_img/my_stock/del-app/KeKeThemeSpace
rm -rf base_img/my_stock/del-app/KeKeUserCenterMember
rm -rf base_img/my_stock/del-app/Melody
rm -rf base_img/my_stock/del-app/Music
rm -rf base_img/my_stock/del-app/NewSoundRecorder
rm -rf base_img/my_stock/del-app/OPBreathMode
rm -rf base_img/my_stock/del-app/OPCommunity
rm -rf base_img/my_stock/del-app/OplusDocumentsReader
rm -rf base_img/my_stock/del-app/OplusEmail
rm -rf base_img/my_stock/del-app/OplusQuickGame
rm -rf base_img/my_stock/del-app/OppoCompass2
rm -rf base_img/my_stock/del-app/OppoNote2
rm -rf base_img/my_stock/del-app/OPPOStore
rm -rf base_img/my_stock/del-app/OppoTranslation
rm -rf base_img/my_stock/del-app/OppoWeather2
rm -rf base_img/my_stock/del-app/RiderMode
rm -rf base_img/my_stock/del-app/Shortcuts
rm -rf base_img/my_stock/del-app/SoftsimRedteaRoaming
rm -rf base_img/my_stock/del-app/Tips
rm -rf base_img/my_stock/del-app/UPTsmService

rm -rf base_img/my_stock/priv-app/BlackListApp
rm -rf base_img/my_stock/priv-app/DCS
rm -rf base_img/my_stock/priv-app/Cota
rm -rf base_img/my_stock/priv-app/HeyCast
rm -rf base_img/my_stock/priv-app/HeyTapSpeechAssist
rm -rf base_img/my_stock/priv-app/KeKeMarket
rm -rf base_img/my_stock/priv-app/KeKeOplusThemeStore-CN
rm -rf base_img/my_stock/priv-app/LinktoWindows
rm -rf base_img/my_stock/priv-app/Metis
rm -rf base_img/my_stock/priv-app/MyDevices
rm -rf base_img/my_stock/priv-app/OplusGames
rm -rf base_img/my_stock/priv-app/OplusScreenRecorder
rm -rf base_img/my_stock/priv-app/OPSynergy
rm -rf base_img/my_stock/priv-app/OShare
rm -rf base_img/my_stock/priv-app/PhoneManager
rm -rf base_img/my_stock/priv-app/SceneService
rm -rf base_img/my_stock/priv-app/SOSHelper
rm -rf base_img/my_stock/priv-app/UMS
rm -rf base_img/my_stock/priv-app/VideoGallery
rm -rf base_img/my_stock/priv-app/GlobalSearch
rm -rf base_img/my_stock/priv-app/OCar

rm -rf base_img/my_product/app/AONService
rm -rf base_img/my_product/app/OplusCamera
# TODO: Add LatinImeGoogle and delete BaiduInput_U_Product
rm -rf base_img/my_product/app/talkback
rm -rf base_img/my_product/del-app/*
rm -rf base_img/my_product/priv-app/RemoteControl
while IFS= read -r -d '' oat_dir; do
    log_proc "Deleted ${oat_dir#./}"
    rm -rf "$oat_dir"
done < <(find . -type d -name "oat" -print0)

log_proc "Merging my_ partitions to system."
mv base_img/my_* base_img/system/

log "Fetching fspatch.py by affggh"
curl -# -L -o fspatch.py "https://raw.githubusercontent.com/affggh/fspatch/refs/heads/main/fspatch.py"
log_proc "Patching fs_configs"
python fspatch.py base_img/system base_img/config/system_fs_config
python fspatch.py base_img/system_ext base_img/config/system_ext_fs_config
python fspatch.py base_img/product base_img/config/product_fs_config
python fspatch.py stock/vendor stock/config/vendor_fs_config
log_proc "Patching file_contexts"
mv fix/context_patch.sh . && chmod a+x context_patch.sh && ./context_patch.sh

mkdir -p "$OUT_DIR"

log "Building OS images"

# Per-partition padding %. Small partitions (product) need proportionally
# more headroom since ext4 metadata overhead (dir blocks, extent trees,
# reserved GDT blocks) doesn't scale down linearly with raw data size.
declare -A PADDING_PERCENT=(
    [system]=4
    [system_ext]=4
    [product]=15
    [vendor]=4
)

for partition in "${PARTITIONS[@]}"; do
    if [ "$partition" = "vendor" ]; then
        # vendor lives under stock/, not base_img/ — separate tree with its own configs
        SRC_DIR="$SCRIPT_DIR/stock/vendor"
        FS_CONFIG="$SCRIPT_DIR/stock/config/vendor_fs_config"
        FILE_CONTEXTS="$SCRIPT_DIR/stock/config/vendor_file_contexts"
    else
        SRC_DIR="$BASE_DIR/$partition"
        FS_CONFIG="$CONFIG_DIR/${partition}_fs_config"
        FILE_CONTEXTS="$CONFIG_DIR/${partition}_file_contexts"
    fi

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

    PCT="${PADDING_PERCENT[$partition]:-4}"
    RAW_SIZE=$(du -sb "$SRC_DIR" | cut -f1)
    PADDED_SIZE=$(( RAW_SIZE + RAW_SIZE * PCT / 100 ))   # per-partition padding
    BLOCK_SIZE=4096
    IMG_SIZE=$(( ( (PADDED_SIZE + BLOCK_SIZE - 1) / BLOCK_SIZE ) * BLOCK_SIZE ))
    IMG_BLOCKS=$(( IMG_SIZE / BLOCK_SIZE ))

    # Inode estimate: one per file/dir/symlink found, plus 10% headroom.
    NUM_ENTRIES=$(find "$SRC_DIR" | wc -l)
    NUM_INODES=$(( NUM_ENTRIES + NUM_ENTRIES / 10 + 32 ))

    log_proc "mke2fs: $IMG_BLOCKS blocks, $NUM_INODES inodes"
    mke2fs -O ^has_journal -L "$partition" -I 256 -M "/$partition" \
        -m 0 -t ext4 -b "$BLOCK_SIZE" \
        -N "$NUM_INODES" \
        "$OUT_DIR/${partition}.img" "$IMG_BLOCKS"

    log_proc "e2fsdroid: populating image"
    e2fsdroid -e -T 0 \
        -S "$FILE_CONTEXTS" \
        -C "$FS_CONFIG" \
        -a "/$partition" \
        -f "$SRC_DIR" \
        "$OUT_DIR/${partition}.img"

    log "$partition.img's build is finished: $OUT_DIR/${partition}.img ($(du -h "$OUT_DIR/${partition}.img" | cut -f1))"
done
