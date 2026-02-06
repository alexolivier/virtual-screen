import AppKit
import ScreenCaptureKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var captureEngine = CaptureEngine()
    private var outputWindow: OutputWindow?
    private var overlayWindow: SelectionOverlayWindow?
    private var overlayView: SelectionOverlayView?
    private var regionFrameWindow: RegionFrameWindow?

    private var selectedRegion: CGRect?
    private var selectedScreen: NSScreen?
    private var fps = 30
    private var isCapturing = false
    private var errorMessage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "VirtualScreen")
        }

        rebuildMenu()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if let region = selectedRegion {
            let label = NSMenuItem(title: "\(Int(region.width)) × \(Int(region.height)) at (\(Int(region.origin.x)), \(Int(region.origin.y)))", action: nil, keyEquivalent: "")
            label.isEnabled = false
            menu.addItem(label)
            menu.addItem(.separator())
        }

        let selectRegion = NSMenuItem(title: "Select Region", action: #selector(selectRegionClicked), keyEquivalent: "")
        selectRegion.target = self
        selectRegion.isEnabled = !isCapturing
        menu.addItem(selectRegion)

        menu.addItem(.separator())

        if isCapturing {
            let stop = NSMenuItem(title: "Stop Capture", action: #selector(stopCaptureClicked), keyEquivalent: "")
            stop.target = self
            menu.addItem(stop)
        } else {
            let start = NSMenuItem(title: "Start Capture", action: #selector(startCaptureClicked), keyEquivalent: "")
            start.target = self
            start.isEnabled = selectedRegion != nil
            menu.addItem(start)
        }

        menu.addItem(.separator())

        let fpsItem = NSMenuItem(title: "FPS", action: nil, keyEquivalent: "")
        let fpsSubmenu = NSMenu()
        for rate in [15, 30, 60] {
            let item = NSMenuItem(title: "\(rate)", action: #selector(fpsSelected(_:)), keyEquivalent: "")
            item.target = self
            item.tag = rate
            item.state = fps == rate ? .on : .off
            fpsSubmenu.addItem(item)
        }
        fpsItem.submenu = fpsSubmenu
        menu.addItem(fpsItem)

        if let error = errorMessage {
            menu.addItem(.separator())
            let errorItem = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit VirtualScreen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func selectRegionClicked() {
        showOverlay()
    }

    @objc private func startCaptureClicked() {
        startCapture()
    }

    @objc private func stopCaptureClicked() {
        stopCapture()
    }

    @objc private func fpsSelected(_ sender: NSMenuItem) {
        let newFPS = sender.tag
        self.fps = newFPS
        rebuildMenu()
        if captureEngine.isRunning, let region = selectedRegion, let screen = selectedScreen {
            Task {
                try? await captureEngine.updateRegion(
                    regionInAppKit: region,
                    screenHeight: screen.frame.height,
                    scaleFactor: screen.backingScaleFactor,
                    fps: newFPS
                )
            }
        }
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
            errorMessage = "Could not identify display"
            rebuildMenu()
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
        let frameNum = frame.windowNumber
        if frameNum > 0 {
            excludeIDs.append(CGWindowID(frameNum))
        }

        Task {
            do {
                let hasPermission = await PermissionManager.ensurePermission()
                guard hasPermission else {
                    await MainActor.run {
                        self.errorMessage = "Screen recording permission denied. Grant access in System Settings > Privacy > Screen Recording."
                        self.rebuildMenu()
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
                    self.isCapturing = true
                    self.errorMessage = nil
                    self.rebuildMenu()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.rebuildMenu()
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
                self.isCapturing = false
                self.rebuildMenu()
            }
        }
    }
}

extension AppDelegate: SelectionOverlayDelegate {
    func selectionDidComplete(rect: CGRect, screen: NSScreen) {
        dismissOverlay()
        selectedRegion = rect
        selectedScreen = screen
        startCapture()
    }

    func selectionDidCancel() {
        dismissOverlay()
    }
}
