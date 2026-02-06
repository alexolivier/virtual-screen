import AppKit

final class RegionFrameWindow: NSWindow {
    fileprivate static let borderWidth: CGFloat = 3
    var onRegionMoved: ((CGRect) -> Void)?
    private var handleWindow: DragHandleWindow?

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

        let handle = DragHandleWindow(parentFrame: frame)
        addChildWindow(handle, ordered: .above)
        handle.orderFront(nil)
        self.handleWindow = handle
    }

    func updateRegion(_ region: CGRect) {
        let inset = -Self.borderWidth
        let frame = region.insetBy(dx: inset, dy: inset)
        setFrame(frame, display: true)
        handleWindow?.repositionForParentFrame(frame)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func close() {
        handleWindow?.close()
        handleWindow = nil
        super.close()
    }
}

private final class DragHandleWindow: NSWindow {
    private static let handleSize = CGSize(width: 60, height: 14)

    convenience init(parentFrame: NSRect) {
        let handleFrame = Self.frameForParent(parentFrame)
        self.init(
            contentRect: handleFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        isOpaque = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        ignoresMouseEvents = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = DragHandleView(frame: NSRect(origin: .zero, size: handleFrame.size))
        contentView = view
    }

    static func frameForParent(_ parentFrame: NSRect) -> NSRect {
        let w = handleSize.width
        let h = handleSize.height
        let x = parentFrame.origin.x + (parentFrame.width - w) / 2
        let y = parentFrame.maxY - RegionFrameWindow.borderWidth - h
        return NSRect(x: x, y: y, width: w, height: h)
    }

    func repositionForParentFrame(_ parentFrame: NSRect) {
        setFrame(Self.frameForParent(parentFrame), display: true)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class DragHandleView: NSView {
    private var initialMouseLocation: NSPoint?
    private var initialParentOrigin: NSPoint?

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func draw(_ dirtyRect: NSRect) {
        let radius = bounds.height / 2
        let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        NSColor.green.withAlphaComponent(0.85).setFill()
        path.fill()

        NSColor.white.withAlphaComponent(0.5).setStroke()
        let lineSpacing: CGFloat = 4
        let lineWidth: CGFloat = 16
        let cx = bounds.midX
        let cy = bounds.midY
        for offset: CGFloat in [-lineSpacing, 0, lineSpacing] {
            let line = NSBezierPath()
            line.move(to: NSPoint(x: cx - lineWidth / 2, y: cy + offset))
            line.line(to: NSPoint(x: cx + lineWidth / 2, y: cy + offset))
            line.lineWidth = 1
            line.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialParentOrigin = window?.parent?.frame.origin
        NSCursor.closedHand.push()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialMouse = initialMouseLocation,
              let initialOrigin = initialParentOrigin,
              let parent = window?.parent else { return }
        let current = NSEvent.mouseLocation
        parent.setFrameOrigin(NSPoint(
            x: initialOrigin.x + current.x - initialMouse.x,
            y: initialOrigin.y + current.y - initialMouse.y
        ))
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.pop()
        initialMouseLocation = nil
        initialParentOrigin = nil
        guard let parent = window?.parent as? RegionFrameWindow else { return }
        let bw = RegionFrameWindow.borderWidth
        let region = parent.frame.insetBy(dx: bw, dy: bw)
        parent.onRegionMoved?(region)
    }
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
