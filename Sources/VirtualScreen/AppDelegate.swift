import AppKit
import ScreenCaptureKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controlPanel: ControlPanelWindow!
    private var captureEngine = CaptureEngine()
    private var outputWindow: OutputWindow?
    private var overlayWindow: SelectionOverlayWindow?
    private var overlayView: SelectionOverlayView?
    private var regionFrameWindow: RegionFrameWindow?

    private var selectedRegion: CGRect?
    private var selectedScreen: NSScreen?
    private var fps = 30

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        controlPanel = ControlPanelWindow(delegate: self)
        controlPanel.window.makeKeyAndOrderFront(nil)
        controlPanel.window.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showOverlay() {
        guard let screen = NSScreen.main else { return }

        let overlay = SelectionOverlayWindow(screen: screen)
        let view = SelectionOverlayView(frame: screen.frame)
        view.delegate = self
        overlay.contentView = view
        overlay.makeKeyAndOrderFront(nil)

        self.overlayWindow = overlay
        self.overlayView = view
    }

    private func dismissOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        overlayView = nil
    }

    private func startCapture() {
        guard let region = selectedRegion, let screen = selectedScreen else { return }

        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            controlPanel.state.errorMessage = "Could not identify display"
            return
        }

        let scaleFactor = screen.backingScaleFactor
        let screenHeight = screen.frame.height

        outputWindow?.close()
        let output = OutputWindow(regionSize: region.size)
        output.makeKeyAndOrderFront(nil)
        self.outputWindow = output

        regionFrameWindow?.close()
        let frame = RegionFrameWindow(region: region)
        frame.orderFront(nil)
        self.regionFrameWindow = frame

        captureEngine.receiver = output.frameRenderer

        var excludeIDs: [CGWindowID] = []
        let outputNum = output.windowNumber
        if outputNum > 0 {
            excludeIDs.append(CGWindowID(outputNum))
        }
        let controlNum = controlPanel.window.windowNumber
        if controlNum > 0 {
            excludeIDs.append(CGWindowID(controlNum))
        }
        let frameNum = frame.windowNumber
        if frameNum > 0 {
            excludeIDs.append(CGWindowID(frameNum))
        }

        Task {
            do {
                let hasPermission = await PermissionManager.ensurePermission()
                guard hasPermission else {
                    await MainActor.run {
                        controlPanel.state.errorMessage = "Screen recording permission denied. Grant access in System Settings > Privacy > Screen Recording."
                    }
                    return
                }

                try await captureEngine.startCapture(
                    regionInAppKit: region,
                    screenHeight: screenHeight,
                    displayID: displayID,
                    scaleFactor: scaleFactor,
                    excludeWindowIDs: excludeIDs,
                    fps: fps
                )
                await MainActor.run {
                    controlPanel.state.isCapturing = true
                    controlPanel.state.errorMessage = nil
                    controlPanel.updateView()
                }
            } catch {
                await MainActor.run {
                    controlPanel.state.errorMessage = error.localizedDescription
                    controlPanel.updateView()
                }
            }
        }
    }

    private func stopCapture() {
        regionFrameWindow?.close()
        regionFrameWindow = nil
        Task {
            try? await captureEngine.stopCapture()
            await MainActor.run {
                controlPanel.state.isCapturing = false
                controlPanel.updateView()
            }
        }
    }
}

extension AppDelegate: SelectionOverlayDelegate {
    func selectionDidComplete(rect: CGRect, screen: NSScreen) {
        dismissOverlay()
        selectedRegion = rect
        selectedScreen = screen
        controlPanel.state.selectedRegion = rect
        controlPanel.updateView()
    }

    func selectionDidCancel() {
        dismissOverlay()
    }
}

extension AppDelegate: ControlPanelDelegate {
    func controlPanelDidRequestSelectRegion() {
        showOverlay()
    }

    func controlPanelDidRequestStartCapture() {
        startCapture()
    }

    func controlPanelDidRequestStopCapture() {
        stopCapture()
    }

    func controlPanelDidChangeFPS(_ fps: Int) {
        self.fps = fps
        controlPanel.state.fps = fps
        if captureEngine.isRunning, let region = selectedRegion, let screen = selectedScreen {
            Task {
                try? await captureEngine.updateRegion(
                    regionInAppKit: region,
                    screenHeight: screen.frame.height,
                    scaleFactor: screen.backingScaleFactor,
                    fps: fps
                )
            }
        }
    }
}
