#!/bin/bash
# Push this theme to the TV with the native adb (macOS Local Network privacy blocks the Python ADB client that
# tools/theme.sh uses), then restart Home and put the key helpers back on.
#
# Usage: TV_HOST=192.168.1.20 themes/panasonic-mx660/push-theme.sh [--config | --full] [theme folder]
#   (default)  config.json, then sync the photos: send only new or changed ones (by name and size) and delete
#              the ones no longer in wallpapers/ here
#   --config   config.json only; the photos on the TV stay as they are
#   --full     config.json, then empty the TV's wallpapers/ and send every photo again (as tools/theme.sh does)
# The theme folder defaults to themes/panasonic-mx660. TV_HOST may carry :5555 or not.
set -euo pipefail
cd "$(dirname "$0")/../.."
MODE=sync
case "${1:-}" in
  --config) MODE=config; shift ;;
  --full) MODE=full; shift ;;
  -*) echo "unknown option $1 (use --config or --full)" >&2; exit 2 ;;
esac
THEME=${1:-themes/panasonic-mx660}
T=${TV_HOST:?set TV_HOST, e.g. TV_HOST=192.168.1.20}; T=${T%%:*}:5555
PKG=com.gathin.tvhome
DIR=/sdcard/Android/data/$PKG/files
URI=content://$PKG.theme
TMP=/data/local/tmp/cyt-theme
[ -f "$THEME/config.json" ] || { echo "$THEME/config.json not found" >&2; exit 2; }
adb connect "$T" >/dev/null
sh_tv() { adb -s "$T" shell "$1"; }
put() { local stage="$TMP-${1//\//-}"
        adb -s "$T" push "$2" "$stage" >/dev/null
        sh_tv "rm -f $DIR/$1 2>/dev/null; content write --uri $URI/$1 < $stage || cp $stage $DIR/$1; rm -f $stage"; }
del() { sh_tv "rm -f $DIR/$1 2>/dev/null; content delete --uri $URI/$1 >/dev/null 2>&1; true"; }
is_photo() { case "$1" in *.[jJ][pP][gG]|*.[jJ][pP][eE][gG]|*.[pP][nN][gG]|*.[wW][eE][bB][pP]) return 0 ;; esac; return 1; }

put config.json "$THEME/config.json"
echo "config.json sent"

if [ "$MODE" = full ]; then
  sh_tv "rm -f $DIR/wallpaper.jpg 2>/dev/null; content delete --uri $URI/wallpaper.jpg 2>/dev/null; mkdir -p $DIR/wallpapers 2>/dev/null; rm -f $DIR/wallpapers/* 2>/dev/null; content delete --uri $URI/wallpapers 2>/dev/null; true"
  for f in "$THEME"/wallpapers/*; do is_photo "$f" && { put "wallpapers/$(basename "$f")" "$f"; echo "sent $(basename "$f")"; }; done
elif [ "$MODE" = sync ]; then
  # name<TAB>size of every picture on the TV
  REMOTE=$(sh_tv "cd $DIR/wallpapers 2>/dev/null && for f in *; do [ -f \"\$f\" ] && printf '%s\t%s\n' \"\$f\" \"\$(wc -c < \"\$f\")\"; done" | tr -d '\r')
  remote_size() { printf '%s\n' "$REMOTE" | awk -F'\t' -v n="$1" '$1==n {gsub(/ /,"",$2); print $2}'; }
  sent=0; removed=0
  for f in "$THEME"/wallpapers/*; do
    [ -f "$f" ] && is_photo "$f" || continue
    n=$(basename "$f"); s=$(wc -c < "$f" | tr -d ' ')
    if [ "$(remote_size "$n")" != "$s" ]; then put "wallpapers/$n" "$f"; echo "sent $n"; sent=$((sent+1)); fi
  done
  while IFS=$'\t' read -r n s; do
    [ -n "$n" ] && is_photo "$n" || continue
    if [ ! -f "$THEME/wallpapers/$n" ]; then del "wallpapers/$n"; echo "removed $n from the TV"; removed=$((removed+1)); fi
  done <<< "$REMOTE"
  echo "photos: $sent sent, $removed removed, the rest already on the TV"
fi

REV=$(uuidgen | tr -d -)
sh_tv "printf '%s' '$REV' > $TMP-theme_revision; rm -f $DIR/theme_revision; content write --uri $URI/theme_revision < $TMP-theme_revision; rm -f $TMP-theme_revision"
sh_tv 's=$(settings get secure enabled_accessibility_services); am force-stop com.gathin.tvhome; settings put secure enabled_accessibility_services ""; settings put secure enabled_accessibility_services "$s"; settings put secure accessibility_enabled 1; am start -n com.gathin.tvhome/.MainActivity >/dev/null'
echo "Home restarted with $(basename "$THEME")."
