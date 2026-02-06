import AppKit
import ScreenCaptureKit

struct DisplayInfo {
    let displayID: CGDirectDisplayID
    let frame: CGRect
    let scaleFactor: CGFloat

    static func allDisplays() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return nil
            }
            return DisplayInfo(
                displayID: displayID,
                frame: screen.frame,
                scaleFactor: screen.backingScaleFactor
            )
        }
    }

    static func mainDisplay() -> DisplayInfo? {
        allDisplays().first
    }

    /// Convert AppKit rect (bottom-left origin) to ScreenCaptureKit rect (top-left origin)
    static func appKitToSCK(_ rect: CGRect, screenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Find the SCDisplay matching a CGDirectDisplayID
    static func findSCDisplay(for displayID: CGDirectDisplayID, in content: SCShareableContent) -> SCDisplay? {
        content.displays.first { $0.displayID == displayID }
    }

    /// Pixel dimensions for a region in points, accounting for Retina
    static func pixelSize(for pointSize: CGSize, scaleFactor: CGFloat) -> (width: Int, height: Int) {
        (
            width: Int(pointSize.width * scaleFactor),
            height: Int(pointSize.height * scaleFactor)
        )
    }
}
