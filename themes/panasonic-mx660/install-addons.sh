#!/usr/bin/env bash
# Installs Sachin's cleanyourtv add-ons on the Panasonic MX660.
# Run from the repo root:  themes/panasonic-mx660/install-addons.sh
# Uses native adb (macOS Local Network privacy blocks the repo's Python ADB client on this Mac).
set -euo pipefail
cd "$(dirname "$0")/../.."
export TV_HOST="${TV_HOST:-192.168.1.20}"
export TV_ADB_BINARY="${TV_ADB_BINARY:-adb}"
PY=tools/venv/bin/python

# Pick an Apple Silicon JDK 17+ (the old Intel JDK 11 in /Library/Java can't run on this M1).
pick_java() {
  for h in "${JAVA_HOME:-}" \
           "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
           "$(/usr/libexec/java_home -v 17 -a arm64 2>/dev/null || true)" \
           "$(/usr/libexec/java_home -v 21 -a arm64 2>/dev/null || true)" \
           /opt/homebrew/opt/openjdk@17 /opt/homebrew/opt/openjdk@21 /opt/homebrew/opt/openjdk; do
    [ -n "$h" ] && [ -x "$h/bin/java" ] || continue
    v=$("$h/bin/java" -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/') || continue
    [ "${v:-0}" -ge 17 ] 2>/dev/null && { export JAVA_HOME="$h"; export PATH="$h/bin:$PATH"; return 0; }
  done
  echo "No Apple Silicon Java 17+ found. Install one with:  brew install openjdk@17" >&2
  exit 1
}
pick_java
echo "Using Java: $JAVA_HOME"

# Find the Android SDK (the add-ons need platform 34 and build-tools 34.0.0).
pick_sdk() {
  local from_launcher=""
  [ -f launcher/local.properties ] && from_launcher=$(sed -n 's/^sdk\.dir=//p' launcher/local.properties | head -1)
  for d in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$from_launcher" \
           "$HOME/Library/Android/sdk" /opt/homebrew/share/android-commandlinetools /opt/homebrew/share/android-sdk; do
    [ -n "$d" ] && [ -d "$d/platforms" ] || continue
    export ANDROID_HOME="$d" ANDROID_SDK_ROOT="$d"; return 0
  done
  cat >&2 <<'MSG'
No Android SDK found. Install one with:
  brew install --cask android-commandlinetools
  yes | sdkmanager --sdk_root=/opt/homebrew/share/android-commandlinetools "platforms;android-34" "build-tools;34.0.0" "platform-tools"
then run this script again.
MSG
  exit 1
}
pick_sdk
echo "Using Android SDK: $ANDROID_HOME"

adb connect "$TV_HOST:5555"

# Add-ons with their own installer (build, install, grant permissions, open)
for a in quiet-hours brightness headphones bluetooth-connect; do
  echo "=== $a"; addons/$a/install.sh
done
echo "=== sleep-timer"; addons/sleep-timer/build-and-install.sh

# Add-ons built and pushed by hand
for a in world-clock weather; do
  echo "=== $a"
  (cd addons/$a && ./gradlew --no-daemon assembleRelease)
  "$PY" -I tools/tv.py --push addons/$a/app/build/outputs/apk/release/app-release.apk /data/local/tmp/addon.apk
  "$PY" -I tools/tv.py 'pm install -r /data/local/tmp/addon.apk; rm -f /data/local/tmp/addon.apk'
done

echo "Done. Press Home on the TV and answer 'Show card' for each add-on."
