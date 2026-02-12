#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common_functions.sh"

[[ $# -lt 1 ]] && error "Working directory not specified"
WORK_DIR="$1"

[[ ! -d "$WORK_DIR" ]] && error "Directory not found: $WORK_DIR"
cd "$WORK_DIR"

log "Updating packages..."
sudo apt update -y &>xerr || xerror "Failed to update packages"
sudo apt upgrade -y &>xerr || xerror "Failed to upgrade packages"

log "Installing required packages..."
sudo apt install -y 
cpio 
aria2 
git 
python3 
python3-pip 
neofetch 
tar 
gzip 
gh 
&>xerr || xerror "Failed to install required packages"

log "Cloning DumprX..."
if [[ ! -d DumprX ]]; then
git clone https://github.com/DumprX/DumprX &>xerr || xerror "Failed to clone DumprX"
fi

pushd DumprX >/dev/null
chmod +x *.sh
bash setup.sh &>xerr || xerror "DumprX setup failed"
popd >/dev/null

log "Installing Python tools..."
pip3 install --upgrade pip &>xerr || xerror "Failed to upgrade pip"
pip3 install aospdtgen twrpdtgen &>xerr || xerror "Failed to install dtgen tools"

log "Cloning extract utils..."
mkdir -p android/{tools,prebuilts}

git clone --depth=1 
https://github.com/LineageOS/android_tools_extract-utils 
-b lineage-22.2 android/tools/extract-utils &>xerr 
|| xerror "Failed to clone extract-utils"

git clone --depth=1 
https://github.com/LineageOS/android_prebuilts_extract-tools 
-b lineage-22.2 android/prebuilts/extract-tools &>xerr 
|| xerror "Failed to clone extract-tools"

log "Setup completed successfully."
