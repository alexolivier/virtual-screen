import AppKit
import IOSurface

final class FrameRenderer: NSView, CaptureOutputReceiver {
    private var displayLayer: CALayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        guard let layer else { return }
        layer.contentsGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
    }

    func didCaptureFrame(_ surface: IOSurfaceRef) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let layer = self.layer else { return }
            layer.contents = surface
            layer.setNeedsDisplay()
        }
    }
}
