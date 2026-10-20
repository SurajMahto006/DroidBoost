#!/usr/bin/env bash
# ==============================================================================
# DroidBoost - Undo Script (Bash)
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${CYAN}==========================================================${NC}"
echo -e "${YELLOW}               DROIDBOOST - UNDO / RESTORE                ${NC}"
echo -e "${CYAN}==========================================================${NC}\n"

ADB_BIN=$(which adb 2>/dev/null || true)
if [ -z "$ADB_BIN" ]; then
    read -rp "Path to adb executable: " ADB_BIN
fi

TV_IP="$1"
if [ -z "$TV_IP" ]; then
    read -rp "Enter TV IP address: " TV_IP
fi

if [[ "$TV_IP" != *:* ]]; then
    TV_TARGET="${TV_IP}:5555"
else
    TV_TARGET="$TV_IP"
fi

echo -e "${CYAN}[*] Connecting to $TV_TARGET...${NC}"
"$ADB_BIN" connect "$TV_TARGET" >/dev/null 2>&1
sleep 1

# Re-enable packages
echo -e "\n${CYAN}[*] Reading disabled packages from TV...${NC}"
DISABLED_LIST=$("$ADB_BIN" -s "$TV_TARGET" shell "cat /data/local/tmp/droidboost-disabled.txt 2>/dev/null" | tr -d '\r' || true)

# Default bloatware list fallback
KNOWN_PACKAGES=(
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
    "com.google.android.tvlauncher"
)

ALL_TO_ENABLE=()
for p in $DISABLED_LIST; do
    ALL_TO_ENABLE+=("$p")
done
for p in "${KNOWN_PACKAGES[@]}"; do
    ALL_TO_ENABLE+=("$p")
done

# Unique packages
UNIQUE_PKGS=($(printf "%s\n" "${ALL_TO_ENABLE[@]}" | sort -u))

echo -e "${CYAN}[*] Re-enabling packages...${NC}"
for pkg in "${UNIQUE_PKGS[@]}"; do
    "$ADB_BIN" -s "$TV_TARGET" shell "pm enable $pkg" >/dev/null 2>&1 && echo -e "  Re-enabled: ${GREEN}$pkg${NC}" || true
done

# Restore animation scales & screensaver
echo -e "\n${CYAN}[*] Restoring animation scales and screensaver...${NC}"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global window_animation_scale 1"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global transition_animation_scale 1"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put global animator_duration_scale 1"
"$ADB_BIN" -s "$TV_TARGET" shell "settings put secure screensaver_enabled 1"

"$ADB_BIN" -s "$TV_TARGET" shell "rm -f /data/local/tmp/droidboost-disabled.txt" 2>/dev/null || true

read -rp "Reboot TV now? (y/n): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy] ]]; then
    "$ADB_BIN" -s "$TV_TARGET" reboot
fi

echo -e "\n${GREEN}[+] All apps and settings restored!${NC}\n"
