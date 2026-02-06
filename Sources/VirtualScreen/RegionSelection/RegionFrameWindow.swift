import AppKit

final class RegionFrameWindow: NSWindow {
    fileprivate static let borderWidth: CGFloat = 3

    convenience init(region: CGRect) {
        let inset = -Self.borderWidth
        let frame = region.insetBy(dx: inset, dy: inset)

        self.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        self.setFrame(frame, display: true)
        level = .screenSaver
        isOpaque = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let borderView = RegionFrameView(frame: NSRect(origin: .zero, size: frame.size))
        contentView = borderView
    }

    func updateRegion(_ region: CGRect) {
        let inset = -Self.borderWidth
        let frame = region.insetBy(dx: inset, dy: inset)
        setFrame(frame, display: true)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class RegionFrameView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.green.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(
            dx: RegionFrameWindow.borderWidth / 2,
            dy: RegionFrameWindow.borderWidth / 2
        ))
        path.lineWidth = RegionFrameWindow.borderWidth
        path.stroke()
    }
}
