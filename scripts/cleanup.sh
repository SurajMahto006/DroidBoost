#!/usr/bin/env bash
# ==============================================================================
# DroidBoost - Android TV Performance Optimizer & Bloatware Remover (Bash)
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}==========================================================${NC}"
echo -e "${YELLOW}   🚀 DROIDBOOST - Android TV Cleanup & Speed Optimizer   ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo -e " No root needed | No apps deleted | 100% reversible\n"

# 1. Locate ADB
ADB_BIN=$(which adb 2>/dev/null || true)
if [ -z "$ADB_BIN" ]; then
    echo -e "${RED}[!] 'adb' command not found in PATH.${NC}"
    echo -e "Please install android-platform-tools or specify ADB path."
    read -rp "Path to adb executable: " ADB_BIN
    if [ ! -x "$ADB_BIN" ]; then
        echo -e "${RED}[-] Invalid ADB executable path.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}[+] Using ADB: $ADB_BIN${NC}"

# 2. TV IP
TV_IP="$1"
if [ -z "$TV_IP" ]; then
    read -rp "Enter TV IP address (e.g. 192.168.0.107): " TV_IP
fi

if [[ "$TV_IP" != *:* ]]; then
    TV_TARGET="${TV_IP}:5555"
else
    TV_TARGET="$TV_IP"
fi

# 3. Connect
echo -e "\n${CYAN}[*] Connecting to $TV_TARGET...${NC}"
"$ADB_BIN" connect "$TV_TARGET" >/dev/null 2>&1
sleep 1

DEVICES_OUT=$("$ADB_BIN" devices)
if echo "$DEVICES_OUT" | grep -q "$TV_TARGET.*unauthorized"; then
    echo -e "${YELLOW}[!] Device unauthorized. Please accept the prompt on your TV screen!${NC}"
    read -rp "Press Enter once accepted..."
    "$ADB_BIN" connect "$TV_TARGET" >/dev/null 2>&1
fi

if ! "$ADB_BIN" devices | grep -q "$TV_TARGET.*device"; then
    echo -e "${RED}[-] Could not connect to $TV_TARGET. Check Wi-Fi and USB debugging.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Connected to TV!${NC}"

# 4. Bloatware list
SAFE_PACKAGES=(
    "com.amazon.amazonvideo.livingroom"
    "com.google.android.tvrecommendations"
    "com.google.android.backdrop"
    "com.google.android.tungsten.setupwraith"
    "com.google.android.feedback"
    "com.google.android.syncadapters.calendar"
    "com.android.providers.calendar"
    "com.android.providers.contacts"
    "com.android.printspooler"
    "com.android.deskclock"
    "com.android.soundpicker"
    "fusion.android.tv.demo"
    "com.google.android.marvin.talkback"
    "com.google.android.youtube.tvmusic"
    "com.google.android.play.games"
    "com.google.android.videos"
    "tv.anoki.acr.controller"
    "com.haier.apps.evoSmart"
    "com.haierubic.usmartdevice"
    "com.haier.apps.shahid"
    "com.haier.apps"
)

PROTECTED_PACKAGES=(
    "android"
    "com.android.systemui"
    "com.android.tv.settings"
    "com.google.android.gms"
    "com.android.vending"
    "com.android.bluetooth"
    "com.google.android.inputmethod.latin"
    "com.mediatek.tvinput"
)

# 5. Scan installed packages
echo -e "\n${CYAN}[*] Scanning installed packages...${NC}"
INSTALLED_PKGS=$("$ADB_BIN" -s "$TV_TARGET" shell "pm list packages" | sed 's/^package://' | tr -d '\r')

TO_DISABLE=()
for pkg in "${SAFE_PACKAGES[@]}"; do
    if echo "$INSTALLED_PKGS" | grep -qx "$pkg"; then
        TO_DISABLE+=("$pkg")
    fi
done

echo -e "${GREEN}[+] Found ${#TO_DISABLE[@]} candidate bloatware packages installed.${NC}"
for pkg in "${TO_DISABLE[@]}"; do
    echo "  - $pkg"
done

if [ ${#TO_DISABLE[@]} -gt 0 ]; then
    read -rp "Disable these packages now? (y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy] ]]; then
        echo -e "\n${CYAN}[*] Disabling bloatware...${NC}"
        for pkg in "${TO_DISABLE[@]}"; do
            echo -n "  Disabling $pkg... "
            "$ADB_BIN" -s "$TV_TARGET" shell "pm disable-user --user 0 $pkg" >/dev/null 2>&1 || true
            "$ADB_BIN" -s "$TV_TARGET" shell "echo $pkg >> /data/local/tmp/droidboost-disabled.txt" 2>/dev/null || true
            echo -e "${GREEN}[OK]${NC}"
        done
    fi
fi

# 6. Performance tweaks
echo -e "\n${CYAN}[*] Applying performance tweaks...${NC}"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global window_animation_scale 0"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global transition_animation_scale 0"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global animator_duration_scale 0"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put secure screensaver_enabled 0"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put system screen_off_timeout 300000"
echo -e "${GREEN}[+] Tweaks applied!${NC}"

# 7. Reboot
read -rp "Reboot TV now? (y/n): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy] ]]; then
    echo -e "${YELLOW}[*] Rebooting TV...${NC}"
    "$ADB_BIN" -s "$TV_TARGET" reboot
fi

echo -e "\n${GREEN}[+] DroidBoost cleanup complete!${NC}\n"
