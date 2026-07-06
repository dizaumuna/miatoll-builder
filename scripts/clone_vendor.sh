#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../buildenv.sh"

require_var VENDOR_PAT
require_var IS_HYPEROS
require_var IS_OXYGENOS

log_step "Cloning target vendor"

if [ "$IS_HYPEROS" = "true" ]; then
    BRANCH="HYPEROS"
elif [ "$IS_OXYGENOS" = "true" ]; then
    BRANCH="OXYGENOS"
else
    log_error "Both IS_HYPEROS and IS_OXYGENOS are false"
    exit 1
fi

mkdir -p "$TARGET_DIR"

log_sub "Cloning miatoll_vendor ($BRANCH)"
git clone --depth=1 --branch "$BRANCH" \
    "https://x-access-token:${VENDOR_PAT}@github.com/dizaumuna/miatoll_vendor.git" \
    "$TARGET_DIR/vendor"
