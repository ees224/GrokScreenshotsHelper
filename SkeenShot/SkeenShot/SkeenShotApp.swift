import SwiftUI
import UserNotifications

@main
struct SkeenShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("SkeenShot", systemImage: "camera.viewfinder") {
            Button("Open Canvas") {
                appDelegate.showCanvas()
            }
            Button("Open Folder") {
                let dir = SkeenShotConfig.load().expandedScreenshotsDir
                NSWorkspace.shared.open(URL(fileURLWithPath: dir))
            }
            Button("Copy Last Path") {
                if let path = SkeenShotSaver.lastSavedPath {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                }
            }
            .disabled(SkeenShotSaver.lastSavedPath == nil)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

final class AppState: ObservableObject {
    @Published var previewImage: NSImage?
    @Published var note = ""
    @Published var statusMessage = "Paste, drop, or submit a screenshot."
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var canvasWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        DispatchQueue.main.async {
            self.showCanvas()
        }
    }

    func showCanvas() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let canvasWindow {
            canvasWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: CanvasView().environmentObject(appState)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SkeenShot Canvas"
        window.contentViewController = hosting
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        canvasWindow = window
    }
}