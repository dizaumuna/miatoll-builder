#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

TEMP_DIR="$ROOT_DIR/temp"
SOURCE_DIR="$ROOT_DIR/source"
TARGET_DIR="$ROOT_DIR/target"
MODS_DIR="$ROOT_DIR/mods"
PATCHES_DIR="$ROOT_DIR/patches"
OUT_DIR="$ROOT_DIR/out"

export ROOT_DIR TEMP_DIR SOURCE_DIR TARGET_DIR MODS_DIR PATCHES_DIR OUT_DIR

SOURCE_FIRMWARE_URL="${SOURCE_FIRMWARE_URL:-}"
IS_HYPEROS="${IS_HYPEROS:-false}"
IS_OXYGENOS="${IS_OXYGENOS:-false}"

export SOURCE_FIRMWARE_URL IS_HYPEROS IS_OXYGENOS

C_RESET='\033[0m'
C_BLUE='\033[1;34m'
C_RED='\033[1;31m'

log_step()  { echo -e "\n${C_BLUE}$*${C_RESET}"; }
log_sub()   { echo -e "  * $*"; }
log_error() { echo -e "${C_RED}$*${C_RESET}" >&2; }

require_var() {
    local var_name="$1"
    if [ -z "${!var_name:-}" ]; then
        log_error "Missing required variable: $var_name"
        exit 1
    fi
}
