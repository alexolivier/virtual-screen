# VirtualScreen

A macOS utility that captures a region of your screen and mirrors it in a separate window.

## Why

Sharing an ultrawide monitor on a video call looks terrible. The content gets squashed into a tiny strip because Zoom, Google Meet, and others fit the entire display into a 16:9 video frame. There's no built-in way to share just a region of your screen — only full screens or specific windows.

VirtualScreen fixes this. Select a 16:9 (or any) rectangle on your ultrawide, and it mirrors that region into a standalone window you can share instead. Your audience sees a crisp, full-size view of exactly what you want to show.

## How it works

1. Click **Select Region** and drag to define a capture area. A green border marks the active region.
2. Click **Start Capture**. A new window appears showing the captured content in real-time.
3. In your video call, share the VirtualScreen output window.
4. Optionally, move the output window to a separate macOS Space so it stays out of your way while still being shared.

The output window, control panel, and region border are all excluded from the capture using ScreenCaptureKit's window filtering, so they never appear in the mirrored output.

## Requirements

- macOS 14+
- Swift 5.9+
- Screen Recording permission (prompted on first run)

## Build & Run

```sh
# Build and run directly
swift build && .build/debug/VirtualScreen

# Or bundle as a .app
./bundle.sh
open VirtualScreen.app
```

## FPS

The control panel has a 15 / 30 / 60 FPS toggle. Higher frame rates use more CPU. 30 is the default and works well for most screen sharing scenarios.
