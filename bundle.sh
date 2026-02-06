#!/bin/bash
set -e

APP="VirtualScreen.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

swift build

rm -rf "$APP"
mkdir -p "$MACOS"
cp .build/debug/VirtualScreen "$MACOS/VirtualScreen"
cp Sources/VirtualScreen/Info.plist "$CONTENTS/Info.plist"

echo "Built $APP — run with: open VirtualScreen.app"
