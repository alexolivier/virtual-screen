import AppKit

final class OutputWindow: NSWindow {
    let frameRenderer: FrameRenderer

    init(regionSize: CGSize) {
        let windowSize = OutputWindow.fitSize(for: regionSize)
        frameRenderer = FrameRenderer(frame: CGRect(origin: .zero, size: windowSize))

        super.init(
            contentRect: CGRect(origin: CGPoint(x: 100, y: 100), size: windowSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "Virtual Screen"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        contentView = frameRenderer
        isReleasedWhenClosed = false
        isMovableByWindowBackground = true
        minSize = CGSize(width: 320, height: 240)
    }

    private static func fitSize(for regionSize: CGSize) -> CGSize {
        let maxWidth: CGFloat = 1280
        let maxHeight: CGFloat = 800
        let scale = min(maxWidth / regionSize.width, maxHeight / regionSize.height, 1.0)
        return CGSize(
            width: max(regionSize.width * scale, 320),
            height: max(regionSize.height * scale, 240)
        )
    }
}
