# panasonic-mx660 (personal)

Launcher settings for my Panasonic TH-65MX660DX (MOKA `R4_GTV`, Realtek `rtd2851m`, Google TV 14,
build `UKR1.250803`). It replaces the `my-tv` branch's edits to `launcher/.../values/config.xml`, so the
launcher can be built from plain upstream and these settings pushed on top.

Not meant for an upstream PR: the dock is my apps, and there is no screenshot or README row.

## Apply

```bash
git checkout main && git pull upstream main
STOCK_LAUNCHER=none HOME_KEY_SERVICE=1 RESTORE_KEY_SERVICES=1 launcher/build-and-install.sh
TV_HOST=192.168.1.24 tools/theme.sh themes/panasonic-mx660
```

`RESTORE_KEY_SERVICES=1` matters: without it the install takes back WRITE_SECURE_SETTINGS and
`restore_key_services` does nothing.

## What it sets

- Dock: Netflix, Prime Video, YouTube, Hotstar, Apple TV, Airtel Xstream, Spotify; 7 columns.
- Hidden: Live TV (`com.realtek.tv`, the Inputs menu covers it) and the firmware apps that come back at every
  boot (AudioLink, FastCast, Meeting Mode, Play Games, Play Movies, System Upgrade, TV Manager, World Clock).
- Home key: launcherx stays enabled (the firmware needs it and setupwraith); `HomeKeyService` sends it back
  here via `stock_home_redirect`, and `restore_key_services` turns the helper back on after a force stop.
- Remote's Settings (gear) button, keycode 83, opens TV Settings.
- Home at every power-on, also when the TV was switched off on an HDMI input.
- Cinematic shelf, 32-bit wallpaper decoding (the set has 2 GB).

Never disable `launcherx` or `setupwraith` on this TV; if setupwraith ever has to be re-enabled, enable
launcherx first (#3578).
