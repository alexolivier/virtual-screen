# VirtualScreen

A macOS menu bar utility that captures a region of your screen and mirrors it in a separate window.

## Why

Sharing an ultrawide monitor on a video call looks terrible. The content gets squashed into a tiny strip because Zoom, Google Meet, and others fit the entire display into a 16:9 video frame. There's no built-in way to share just a region of your screen — only full screens or specific windows.

VirtualScreen fixes this. Select a 16:9 (or any) rectangle on your ultrawide, and it mirrors that region into a standalone window you can share instead. Your audience sees a crisp, full-size view of exactly what you want to show.

## Install

Download the latest **VirtualScreen.dmg** from [Releases](../../releases/latest), open it, and drag VirtualScreen to Applications.

On first launch, macOS may block the app because it's not notarized. Right-click the app and select **Open** to bypass. If you see "damaged and can't be opened", run:

```sh
xattr -cr /Applications/VirtualScreen.app
```

## Usage

1. Click the **rectangle icon** in the menu bar
2. Use **Select Region** to drag a capture area, or pick a preset from **Region Size** (720p, 1080p, 4K)
3. A green border marks the active region — drag the handle at the top to reposition it
4. The output window appears with the mirrored content. Share this window in your video call.
5. Use **FPS** to switch between 15 / 30 / 60 fps. 30 is the default.

The output window, region border, and drag handle are all excluded from the capture, so they never appear in the mirrored output.

## Requirements

- macOS 14+
- Screen Recording permission (prompted on first run)

## Build from source

```sh
# Run directly
swift build && .build/debug/VirtualScreen

# Or bundle as a .app
./bundle.sh
open VirtualScreen.app
```
