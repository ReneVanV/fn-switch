# Fn Switch

A tiny macOS menu bar app that toggles **"Use F1, F2, etc. keys as standard function keys"** with one click, so you don't have to dig through System Settings → Keyboard every time.

Handy if you switch between an external mechanical keyboard (where you want real F1–F12) and your Mac's built-in keys (where you want brightness and volume).

<p>
  <img src="icons/fn-on.png" width="36" alt="On"> &nbsp;
  <img src="icons/fn-off.png" width="36" alt="Off"> &nbsp;
  <img src="icons/fn-pressed.png" width="36" alt="Pressed">
</p>

| Icon | Meaning |
|------|---------|
| 🟢 Green | F1, F2… work as **standard function keys** (hold fn for brightness/media) |
| 🔴 Red | F-keys control **brightness, volume and media** (hold fn for F1, F2…) |
| 🟠 Orange | Shown while you press the button, like a real key going down |

## Usage

- **Left-click** the icon: switch between the two modes.
- **Right-click** (or ctrl-click): menu with the setting, **Open at Login** and **Quit**.

The change takes effect immediately and is the same setting as in System Settings, so the two always agree.

## Install

1. Download `Fn-Switch.zip` from the [Releases](../../releases) page and unzip it.
2. Move **Fn Switch.app** to your Applications folder.
3. Open it. Because the app is not notarized by Apple, macOS will block it the first time:
   open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
   (Or in Terminal: `xattr -dr com.apple.quarantine "/Applications/Fn Switch.app"`)
4. Right-click the icon and choose **Open at Login** if you want it to start automatically.

Requires macOS 13 Ventura or later. Runs on Apple Silicon and Intel Macs.

## Build from source

You only need the Xcode Command Line Tools (`xcode-select --install`), not Xcode itself.

```sh
./build.sh               # builds, creates dist/Fn-Switch.zip and installs to ~/Applications
./build.sh --no-install  # only build and zip
```

The whole app is one file, [`FnSwitch.swift`](FnSwitch.swift). Custom icons go in `icons/` (`fn-on.png`, `fn-off.png`, `fn-pressed.png`, 18×18 pt); without them the app falls back to text.

## How it works

It sets the `HIDFKeyMode` parameter of the keyboard driver through IOKit (the same thing System Settings does) and saves `com.apple.keyboard.fnState` so the setting survives a restart and shows up correctly in System Settings.

## License

[MIT](LICENSE)
