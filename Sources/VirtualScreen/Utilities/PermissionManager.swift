import ScreenCaptureKit
import CoreGraphics

enum PermissionManager {
    static var hasScreenCapturePermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestScreenCapturePermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func ensurePermission() async -> Bool {
        if hasScreenCapturePermission { return true }
        return requestScreenCapturePermission()
    }
}
