# panasonic-mx660 (personal)

My Panasonic TH-65MX660DX 65" (MOKA `R4_GTV`, Realtek `rtd2851m`, 2 GB, Google TV 14, build `UKR1.250803`).
Everything this TV needs from the repo lives here, so the launcher builds from plain upstream and this folder
goes on top. Personal only: not for an upstream PR.

| File | What |
|---|---|
| `config.json` | Launcher settings and the wallpaper rotation (see below) |
| `wallpapers/1.jpg`…`6.jpg` | My photos, rotating on Home |
| `debloat.txt` | The ~55 packages disabled on this TV; `[boot]` marks the ones the firmware re-enables at every cold boot |
| `push-theme.sh` | Pushes this theme with the native `adb`: config only, photo sync, or everything (see below) |

## Update and push

```bash
git pull upstream main && git push origin main
adb connect 192.168.1.20:5555
TV_ADB_BINARY=adb TV_HOST=192.168.1.20:5555 STOCK_LAUNCHER=none HOME_KEY_SERVICE=1 RESTORE_KEY_SERVICES=1 launcher/build-and-install.sh
TV_ADB_BINARY=adb TV_HOST=192.168.1.20:5555 tools/theme.sh themes/panasonic-mx660
```

`TV_ADB_BINARY=adb` makes the repo's tools use the native `adb`, because macOS Local Network privacy blocks
their Python ADB client on this Mac (`tools/native-adb.md`).

For day-to-day changes use this folder's own `push-theme.sh` instead of `tools/theme.sh`, which empties the TV's
`wallpapers/` and re-sends every photo each time:

```bash
TV_HOST=192.168.1.20 themes/panasonic-mx660/push-theme.sh            # config.json + photo sync
TV_HOST=192.168.1.20 themes/panasonic-mx660/push-theme.sh --config   # config.json only
TV_HOST=192.168.1.20 themes/panasonic-mx660/push-theme.sh --full     # everything again, like theme.sh
```

The sync compares `wallpapers/` here with the TV's by name and size: it sends only new or changed photos and
deletes from the TV the ones removed here. So to add or drop a photo, change `wallpapers/` and run the first line.

`RESTORE_KEY_SERVICES=1` matters: without it the install takes back WRITE_SECURE_SETTINGS and
`restore_key_services` does nothing.

`tools/theme.sh` (and `--full`) empty the TV's `wallpapers/` folder and replace its `config.json`, so never push
another theme folder that has no pictures, or yours are gone from the TV.

## What it sets

- Dock: Netflix, Prime Video, YouTube, Hotstar, Apple TV, Airtel Xstream, Spotify; 7 columns.
- Hidden: Live TV (`com.realtek.tv`, the Inputs menu covers it) and the firmware apps that come back at every
  boot (AudioLink, FastCast, Meeting Mode, Play Games, Play Movies, System Upgrade, TV Manager, World Clock).
- Home key: launcherx stays enabled (the firmware needs it and setupwraith); `HomeKeyService` sends it back
  here via `stock_home_redirect`, and `restore_key_services` turns the helper back on after a force stop.
- Remote's Settings (gear) button, keycode 83, opens TV Settings.
- Home at every power-on, also when the TV was switched off on an HDMI input.
- Cinematic shelf with the app art off (`cinematic_art: 0`, scrim 50), no app-colour glow, no app name above
  the dock (`dock_title: false`, which also hides the shelf's "Last opened" line and dots).
- Wi-Fi, Inputs and Settings as round icon buttons (`icon_only_buttons`, `icon_only_inputs`).
- No "Good evening" greeting above the clock (`show_greeting: false`); the day and date stay beside the clock.
- Wallpapers: the six photos, shuffled every 30 minutes, dimmed 30%, decoded in 32-bit colour.

## Debloat

```bash
TV_ADB_BINARY=adb TV_HOST=192.168.1.20:5555 tools/disable.sh themes/panasonic-mx660/debloat.txt
TV_ADB_BINARY=adb TV_HOST=192.168.1.20:5555 tools/venv/bin/python -I tools/check.py themes/panasonic-mx660/debloat.txt com.google.android.apps.tv.launcherx
```

The second line, after a firmware update, shows what came back; add `--fix` to disable it again.

Never disable `launcherx` or `setupwraith` on this TV. If setupwraith ever has to be re-enabled, enable launcherx
first (#3578).
