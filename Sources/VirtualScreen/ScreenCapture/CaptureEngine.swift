import ScreenCaptureKit
import AppKit

final class CaptureEngine {
    private var stream: SCStream?
    private let outputHandler = CaptureOutputHandler()
    private var display: SCDisplay?
    private var filter: SCContentFilter?

    weak var receiver: CaptureOutputReceiver? {
        didSet { outputHandler.receiver = receiver }
    }

    func startCapture(
        regionInAppKit: CGRect,
        screenHeight: CGFloat,
        displayID: CGDirectDisplayID,
        scaleFactor: CGFloat,
        excludeWindowIDs: [CGWindowID],
        fps: Int = 30
    ) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        guard let scDisplay = DisplayInfo.findSCDisplay(for: displayID, in: content) else {
            throw CaptureError.displayNotFound
        }
        self.display = scDisplay

        let excludeWindows = content.windows.filter { excludeWindowIDs.contains($0.windowID) }
        let filter = SCContentFilter(display: scDisplay, excludingWindows: excludeWindows)
        self.filter = filter

        let sourceRect = DisplayInfo.appKitToSCK(regionInAppKit, screenHeight: screenHeight)
        let pixelSize = DisplayInfo.pixelSize(for: regionInAppKit.size, scaleFactor: scaleFactor)

        let config = SCStreamConfiguration()
        config.sourceRect = sourceRect
        config.width = pixelSize.width
        config.height = pixelSize.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.queueDepth = 3

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(outputHandler, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try await stream.startCapture()
        self.stream = stream
    }

    func updateRegion(
        regionInAppKit: CGRect,
        screenHeight: CGFloat,
        scaleFactor: CGFloat,
        fps: Int = 30
    ) async throws {
        guard let stream else { throw CaptureError.notRunning }

        let sourceRect = DisplayInfo.appKitToSCK(regionInAppKit, screenHeight: screenHeight)
        let pixelSize = DisplayInfo.pixelSize(for: regionInAppKit.size, scaleFactor: scaleFactor)

        let config = SCStreamConfiguration()
        config.sourceRect = sourceRect
        config.width = pixelSize.width
        config.height = pixelSize.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.queueDepth = 3

        try await stream.updateConfiguration(config)
    }

    func stopCapture() async throws {
        guard let stream else { return }
        try await stream.stopCapture()
        self.stream = nil
        self.filter = nil
    }

    var isRunning: Bool { stream != nil }
}

enum CaptureError: Error, LocalizedError {
    case displayNotFound
    case notRunning

    var errorDescription: String? {
        switch self {
        case .displayNotFound: "Could not find the target display"
        case .notRunning: "Capture is not running"
        }
    }
}
