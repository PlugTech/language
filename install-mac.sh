#!/bin/bash
# Build the Mac (Catalyst) app and install it to /Applications — no Xcode UI needed.
set -e
cd "$(dirname "$0")"

export PATH="/opt/homebrew/bin:$PATH"
echo "▸ Generating project…"
xcodegen generate >/dev/null

echo "▸ Building (Release, Mac Catalyst)…"
xcodebuild -project Rus.xcodeproj -scheme Rus -configuration Release \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath build/cat-rel \
  CODE_SIGNING_ALLOWED=NO build >/dev/null

APP="build/cat-rel/Build/Products/Release-maccatalyst/Rus.app"
echo "▸ Signing & installing to /Applications…"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1
rm -rf /Applications/Rus.app
cp -R "$APP" /Applications/Rus.app
xattr -dr com.apple.quarantine /Applications/Rus.app 2>/dev/null || true

echo "✓ Installed /Applications/Rus.app"
open /Applications/Rus.app
