import AppKit

protocol SelectionOverlayDelegate: AnyObject {
    func selectionDidComplete(rect: CGRect, screen: NSScreen)
    func selectionDidCancel()
}

final class SelectionOverlayView: NSView {
    weak var delegate: SelectionOverlayDelegate?

    private var dragOrigin: CGPoint = .zero
    private var currentRect: CGRect = .zero
    private var isDragging = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragOrigin = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        isDragging = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let current = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(dragOrigin.x, current.x),
            y: min(dragOrigin.y, current.y),
            width: abs(current.x - dragOrigin.x),
            height: abs(current.y - dragOrigin.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        guard currentRect.width > 10, currentRect.height > 10,
              let screen = window?.screen else {
            delegate?.selectionDidCancel()
            return
        }

        let screenRect = convertToScreenCoordinates(currentRect, in: screen)
        delegate?.selectionDidComplete(rect: screenRect, screen: screen)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            delegate?.selectionDidCancel()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        guard currentRect.width > 0, currentRect.height > 0 else { return }

        NSColor.clear.setFill()
        currentRect.fill(using: .copy)

        let border = NSBezierPath(rect: currentRect)
        NSColor.white.setStroke()
        border.lineWidth = 2
        border.stroke()

        let sizeText = "\(Int(currentRect.width)) × \(Int(currentRect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium),
        ]
        let textSize = sizeText.size(withAttributes: attrs)
        let textPoint = CGPoint(
            x: currentRect.midX - textSize.width / 2,
            y: currentRect.maxY + 8
        )
        sizeText.draw(at: textPoint, withAttributes: attrs)
    }

    private func convertToScreenCoordinates(_ rect: CGRect, in screen: NSScreen) -> CGRect {
        guard let window = self.window else { return rect }
        let windowRect = convert(rect, to: nil)
        let screenRect = window.convertToScreen(windowRect)
        return CGRect(
            x: screenRect.origin.x - screen.frame.origin.x,
            y: screenRect.origin.y - screen.frame.origin.y,
            width: screenRect.width,
            height: screenRect.height
        )
    }
}
