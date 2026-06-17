import Foundation
import CryptoKit

struct SessionContext: Codable {
    let sessionId: String?
    let cwd: String?
    let workspaceRoot: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cwd
        case workspaceRoot = "workspace_root"
        case updatedAt = "updated_at"
    }

    var sessionShort: String {
        if let id = sessionId, !id.isEmpty {
            return String(id.prefix(8))
        }
        if let cwd = cwd, !cwd.isEmpty {
            return Self.hashShort(cwd)
        }
        return "unknown"
    }

    static func current(config: SkeenShotConfig = .load()) -> SessionContext {
        if let fromFile = loadContextFile(path: config.contextFilePath) {
            return fromFile
        }
        if config.sessionFallback == "active_sessions",
           let fromActive = loadActiveSessions() {
            return fromActive
        }
        return SessionContext(
            sessionId: nil,
            cwd: FileManager.default.currentDirectoryPath,
            workspaceRoot: FileManager.default.homeDirectoryForCurrentUser.path,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private static func loadContextFile(path: String) -> SessionContext? {
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path) else { return nil }
        return try? JSONDecoder().decode(SessionContext.self, from: data)
    }

    private static func loadActiveSessions() -> SessionContext? {
        let path = NSString(string: "~/.grok/active_sessions.json").expandingTildeInPath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let latest = json.last else { return nil }

        let sessionId = latest["session_id"] as? String
        let cwd = latest["cwd"] as? String
        return SessionContext(
            sessionId: sessionId,
            cwd: cwd,
            workspaceRoot: cwd,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    static func hashShort(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.prefix(4).map { String(format: "%02x", $0) }.joined()
    }
}