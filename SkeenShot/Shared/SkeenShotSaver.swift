import AppKit
import UserNotifications

struct InboxEntry: Codable {
    let path: String
    let timestamp: String
    let sessionId: String?
    let source: String
    let status: String
}

struct SaveResult {
    let imagePath: String
    let sidecarPath: String
}

enum SkeenShotSaver {
    static var lastSavedPath: String?

    @discardableResult
    static func save(image: NSImage, source: String, note: String? = nil, config: SkeenShotConfig = .load()) -> SaveResult? {
        let context = SessionContext.current(config: config)
        let dir = config.expandedScreenshotsDir
        ensureDirectories(at: dir)

        let timestamp = Self.filenameTimestamp()
        let baseName = "skeenshot_\(context.sessionShort)_\(timestamp)"
        let imagePath = (dir as NSString).appendingPathComponent("\(baseName).png")
        let sidecarPath = (dir as NSString).appendingPathComponent("\(baseName).json")

        guard let resized = resize(image: image, maxDimension: config.maxDimension),
              let tiff = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try png.write(to: URL(fileURLWithPath: imagePath))
        } catch {
            return nil
        }

        let sidecar: [String: Any] = [
            "session_id": context.sessionId as Any,
            "cwd": context.cwd as Any,
            "workspace_root": context.workspaceRoot as Any,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "note": note as Any,
            "source": source,
            "original_size": ["width": image.size.width, "height": image.size.height],
            "saved_size": ["width": resized.size.width, "height": resized.size.height],
            "saved_path": imagePath
        ]

        if let data = try? JSONSerialization.data(withJSONObject: sidecar, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: sidecarPath))
        }

        appendInbox(imagePath: imagePath, sessionId: context.sessionId, source: source, config: config)

        lastSavedPath = imagePath

        if config.copyPathToClipboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(imagePath, forType: .string)
        }

        if config.notifyOnSave {
            postNotification(title: "SkeenShot saved", body: (imagePath as NSString).lastPathComponent)
        }

        return SaveResult(imagePath: imagePath, sidecarPath: sidecarPath)
    }

    static func imageFromPasteboard(_ pasteboard: NSPasteboard) -> NSImage? {
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let first = images.first {
            return first
        }
        if let data = pasteboard.data(forType: .png), let image = NSImage(data: data) {
            return image
        }
        if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data) {
            return image
        }
        return nil
    }

    private static func ensureDirectories(at dir: String) {
        let fm = FileManager.default
        for sub in ["", "inbox", "processed", "archive"] {
            let path = sub.isEmpty ? dir : (dir as NSString).appendingPathComponent(sub)
            try? fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    private static func filenameTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private static func resize(image: NSImage, maxDimension: Int) -> NSImage? {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > CGFloat(maxDimension) else { return image }

        let scale = CGFloat(maxDimension) / maxSide
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    private static func appendInbox(imagePath: String, sessionId: String?, source: String, config: SkeenShotConfig) {
        let entry = InboxEntry(
            path: imagePath,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            sessionId: sessionId,
            source: source,
            status: "pending"
        )
        guard let data = try? JSONEncoder().encode(entry),
              let line = String(data: data, encoding: .utf8) else { return }
        let inboxPath = config.inboxFilePath
        if !FileManager.default.fileExists(atPath: inboxPath) {
            FileManager.default.createFile(atPath: inboxPath, contents: nil)
        }
        if let handle = FileHandle(forWritingAtPath: inboxPath) {
            handle.seekToEndOfFile()
            if let bytes = (line + "\n").data(using: .utf8) {
                handle.write(bytes)
            }
            try? handle.close()
        }
    }

    private static func postNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
}