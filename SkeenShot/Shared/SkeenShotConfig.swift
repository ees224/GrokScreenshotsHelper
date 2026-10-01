import Foundation

struct SkeenShotConfig {
    var screenshotsDir: String
    var maxDimension: Int
    var sessionFallback: String
    var notifyOnSave: Bool
    var copyPathToClipboard: Bool

    static let defaults = SkeenShotConfig(
        screenshotsDir: "~/GrokScreenshots",
        maxDimension: 4096,
        sessionFallback: "active_sessions",
        notifyOnSave: true,
        copyPathToClipboard: true
    )

    static func load() -> SkeenShotConfig {
        loadTOMLConfig() ?? defaults
    }

    var expandedScreenshotsDir: String {
        NSString(string: screenshotsDir).expandingTildeInPath
    }

    var contextFilePath: String {
        (expandedScreenshotsDir as NSString).appendingPathComponent(".context.json")
    }

    var inboxFilePath: String {
        (expandedScreenshotsDir as NSString).appendingPathComponent("inbox.jsonl")
    }

    private static func loadTOMLConfig() -> SkeenShotConfig? {
        let path = NSString(string: defaults.expandedScreenshotsDir).appendingPathComponent("config.toml")
        guard FileManager.default.fileExists(atPath: path),
              let text = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        return parseSimpleTOML(text)
    }

    private static func parseSimpleTOML(_ text: String) -> SkeenShotConfig? {
        var config = defaults
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            switch key {
            case "screenshots_dir": config.screenshotsDir = value
            case "max_dimension": config.maxDimension = Int(value) ?? config.maxDimension
            case "session_fallback": config.sessionFallback = value
            case "notify_on_save": config.notifyOnSave = value == "true"
            case "copy_path_to_clipboard": config.copyPathToClipboard = value == "true"
            default: break
            }
        }
        return config
    }
}
