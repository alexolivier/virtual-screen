#!/bin/bash
set -e

APP="VirtualScreen.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

swift build

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp .build/debug/VirtualScreen "$MACOS/VirtualScreen"
cp Sources/VirtualScreen/Info.plist "$CONTENTS/Info.plist"
cp Resources/AppIcon.icns "$RESOURCES/AppIcon.icns"

echo "Built $APP — run with: open VirtualScreen.app"
