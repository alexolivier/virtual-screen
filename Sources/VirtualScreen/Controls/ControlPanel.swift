import SwiftUI
import AppKit

protocol ControlPanelDelegate: AnyObject {
    func controlPanelDidRequestSelectRegion()
    func controlPanelDidRequestStartCapture()
    func controlPanelDidRequestStopCapture()
    func controlPanelDidChangeFPS(_ fps: Int)
}

struct ControlPanelView: View {
    @ObservedObject var state: ControlPanelState
    var onSelectRegion: () -> Void = {}
    var onStartCapture: () -> Void = {}
    var onStopCapture: () -> Void = {}
    var onFPSChange: (Int) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 16) {
            if let region = state.selectedRegion {
                Text("Region: \(Int(region.width)) × \(Int(region.height)) at (\(Int(region.origin.x)), \(Int(region.origin.y)))")
                    .font(.system(.body, design: .monospaced))
            } else {
                Text("No region selected")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button("Select Region") {
                    onSelectRegion()
                }
                .disabled(state.isCapturing)

                if state.isCapturing {
                    Button("Stop") {
                        onStopCapture()
                    }
                    .tint(.red)
                } else {
                    Button("Start Capture") {
                        onStartCapture()
                    }
                    .disabled(state.selectedRegion == nil)
                }
            }

            HStack {
                Text("FPS:")
                Picker("", selection: Binding(
                    get: { state.fps },
                    set: { onFPSChange($0) }
                )) {
                    Text("15").tag(15)
                    Text("30").tag(30)
                    Text("60").tag(60)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if let error = state.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(20)
        .frame(minWidth: 350)
    }
}

final class ControlPanelState: ObservableObject {
    @Published var selectedRegion: CGRect?
    @Published var isCapturing = false
    @Published var fps = 30
    @Published var errorMessage: String?
}

final class ControlPanelWindow {
    let window: NSWindow
    let state: ControlPanelState
    private weak var delegate: ControlPanelDelegate?

    init(delegate: ControlPanelDelegate) {
        self.delegate = delegate
        self.state = ControlPanelState()

        let view = ControlPanelView(
            state: state,
            onSelectRegion: { [weak delegate] in delegate?.controlPanelDidRequestSelectRegion() },
            onStartCapture: { [weak delegate] in delegate?.controlPanelDidRequestStartCapture() },
            onStopCapture: { [weak delegate] in delegate?.controlPanelDidRequestStopCapture() },
            onFPSChange: { [weak delegate] fps in delegate?.controlPanelDidChangeFPS(fps) }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 380, height: 160))

        let window = NSWindow(
            contentRect: CGRect(x: 200, y: 200, width: 380, height: 160),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "VirtualScreen Controls"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        self.window = window
    }

    func updateView() {
        guard let delegate else { return }
        let view = ControlPanelView(
            state: state,
            onSelectRegion: { [weak delegate] in delegate?.controlPanelDidRequestSelectRegion() },
            onStartCapture: { [weak delegate] in delegate?.controlPanelDidRequestStartCapture() },
            onStopCapture: { [weak delegate] in delegate?.controlPanelDidRequestStopCapture() },
            onFPSChange: { [weak delegate] fps in delegate?.controlPanelDidChangeFPS(fps) }
        )
        (window.contentView as? NSHostingView<ControlPanelView>)?.rootView = view
    }
}
