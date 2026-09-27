#!/bin/zsh
# Builds "Fn Switch.app" (Apple Silicon + Intel), zips it into dist/ and installs it into ~/Applications.
set -e
cd "$(dirname "$0")"

APP="Fn Switch.app"
MIN_MACOS=13.0
rm -rf "$APP" dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" dist

for f in icons/*.png(N); do cp "$f" "$APP/Contents/Resources/"; done

# Universal binary: compile for both architectures, then merge.
# (IOHIDGetParameter/SetParameter are deprecated but still the only public API for this; hide those warnings.)
for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos$MIN_MACOS FnSwitch.swift -o dist/FnSwitch-$arch \
    2> >(grep -v -e deprecated -e '^\s*[0-9]* |' -e '^\s*|' -e '^$' >&2)
done
lipo -create dist/FnSwitch-arm64 dist/FnSwitch-x86_64 -output "$APP/Contents/MacOS/FnSwitch"
rm dist/FnSwitch-*

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Fn Switch</string>
    <key>CFBundleIdentifier</key><string>local.fnswitch</string>
    <key>CFBundleExecutable</key><string>FnSwitch</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"

# Zip for a GitHub release (ditto keeps the app bundle intact).
ditto -c -k --keepParent "$APP" "dist/Fn-Switch.zip"
echo "Created dist/Fn-Switch.zip"

if [[ "$1" != "--no-install" ]]; then
  mkdir -p ~/Applications
  rm -rf ~/Applications/"$APP"
  cp -R "$APP" ~/Applications/
  echo "Installed to ~/Applications/$APP"
fi
