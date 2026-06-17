import Foundation

struct SkeenShotConfig: Codable {
    var screenshotsDir: String
    var analyzeMode: String
    var maxDimension: Int
    var sessionFallback: String
    var archiveAfterDays: Int
    var notifyOnSave: Bool
    var copyPathToClipboard: Bool

    static let defaults = SkeenShotConfig(
        screenshotsDir: "~/GrokScreenshots",
        analyzeMode: "queue",
        maxDimension: 4096,
        sessionFallback: "active_sessions",
        archiveAfterDays: 30,
        notifyOnSave: true,
        copyPathToClipboard: true
    )

    static func load() -> SkeenShotConfig {
        var config = defaults
        if let json = loadJSONConfig() {
            config.merge(json)
        }
        if let toml = loadTOMLConfig() {
            config.merge(toml)
        }
        return config
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

    var folderConfigPath: String {
        (expandedScreenshotsDir as NSString).appendingPathComponent("config.toml")
    }

    private static var appSupportConfigPath: String {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SkeenShot/config.json").path
    }

    private static func loadJSONConfig() -> SkeenShotConfig? {
        let path = appSupportConfigPath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path) else { return nil }
        return try? JSONDecoder().decode(SkeenShotConfig.self, from: data)
    }

    private static func loadTOMLConfig() -> SkeenShotConfig? {
        let path = NSString(string: defaults.expandedScreenshotsDir).appendingPathComponent("config.toml")
        guard FileManager.default.fileExists(atPath: path),
              let text = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        return parseSimpleTOML(text)
    }

    private mutating func merge(_ other: SkeenShotConfig) {
        screenshotsDir = other.screenshotsDir
        analyzeMode = other.analyzeMode
        maxDimension = other.maxDimension
        sessionFallback = other.sessionFallback
        archiveAfterDays = other.archiveAfterDays
        notifyOnSave = other.notifyOnSave
        copyPathToClipboard = other.copyPathToClipboard
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
            case "analyze_mode": config.analyzeMode = value
            case "max_dimension": config.maxDimension = Int(value) ?? config.maxDimension
            case "session_fallback": config.sessionFallback = value
            case "archive_after_days": config.archiveAfterDays = Int(value) ?? config.archiveAfterDays
            case "notify_on_save": config.notifyOnSave = value == "true"
            case "copy_path_to_clipboard": config.copyPathToClipboard = value == "true"
            default: break
            }
        }
        return config
    }

    enum CodingKeys: String, CodingKey {
        case screenshotsDir = "screenshots_dir"
        case analyzeMode = "analyze_mode"
        case maxDimension = "max_dimension"
        case sessionFallback = "session_fallback"
        case archiveAfterDays = "archive_after_days"
        case notifyOnSave = "notify_on_save"
        case copyPathToClipboard = "copy_path_to_clipboard"
    }
}