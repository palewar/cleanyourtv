#!/bin/bash
# Put the photo wallpapers back on the TV: the same steps as tools/theme.sh, with the native adb (macOS Local Network
# privacy blocks the Python ADB client that theme.sh uses). Restarts Home and puts the key helpers back on.
# Usage: TV_HOST=192.168.1.20 themes/panasonic-mx660/push-theme.sh [--config] [theme folder, default themes/panasonic-mx660]
#   --config  send only config.json and restart Home; the wallpapers already on the TV stay as they are
set -euo pipefail
cd "$(dirname "$0")/../.."
CONFIG_ONLY=
if [ "${1:-}" = "--config" ]; then CONFIG_ONLY=1; shift; fi
THEME=${1:-themes/panasonic-mx660}
T=${TV_HOST:?set TV_HOST, e.g. TV_HOST=192.168.1.20}; T=${T%%:*}:5555
PKG=com.gathin.tvhome
DIR=/sdcard/Android/data/$PKG/files
URI=content://$PKG.theme
TMP=/data/local/tmp/cyt-theme
adb connect "$T" >/dev/null
put() { local stage="$TMP-${1//\//-}"
        adb -s "$T" push "$2" "$stage" >/dev/null
        adb -s "$T" shell "rm -f $DIR/$1 2>/dev/null; content write --uri $URI/$1 < $stage || cp $stage $DIR/$1; rm -f $stage"; }
put config.json "$THEME/config.json"
if [ -z "$CONFIG_ONLY" ]; then
  adb -s "$T" shell "rm -f $DIR/wallpaper.jpg 2>/dev/null; content delete --uri $URI/wallpaper.jpg 2>/dev/null; mkdir -p $DIR/wallpapers 2>/dev/null; rm -f $DIR/wallpapers/* 2>/dev/null; content delete --uri $URI/wallpapers 2>/dev/null; true"
  for f in "$THEME"/wallpapers/*.jpg; do put "wallpapers/$(basename "$f")" "$f"; done
fi
REV=$(uuidgen | tr -d -)
adb -s "$T" shell "printf '%s' '$REV' > $TMP-theme_revision; rm -f $DIR/theme_revision; content write --uri $URI/theme_revision < $TMP-theme_revision; rm -f $TMP-theme_revision"
adb -s "$T" shell 's=$(settings get secure enabled_accessibility_services); am force-stop com.gathin.tvhome; settings put secure enabled_accessibility_services ""; settings put secure enabled_accessibility_services "$s"; settings put secure accessibility_enabled 1; am start -n com.gathin.tvhome/.MainActivity >/dev/null'
if [ -n "$CONFIG_ONLY" ]; then echo "config.json of $(basename "$THEME") is on the TV (wallpapers left as they were)."; else echo "Theme $(basename "$THEME") is on the TV."; fi
