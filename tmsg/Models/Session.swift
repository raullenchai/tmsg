import Foundation

struct TerminalSession: Identifiable, Hashable {
    let id: UUID
    var name: String
    var connection: ConnectionType
    var tmuxSessionName: String
    var lastOutput: String
    var unreadCount: Int
    var isAlive: Bool
    var isPinned: Bool
    var isArchived: Bool
    var createdAt: Date
    var lastActiveAt: Date

    var hasUnread: Bool { unreadCount > 0 }

    init(
        name: String,
        connection: ConnectionType,
        tmuxSessionName: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.connection = connection
        let raw = tmuxSessionName ?? "msg-\(UUID().uuidString.prefix(8))"
        self.tmuxSessionName = raw.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        self.lastOutput = ""
        self.unreadCount = 0
        self.isAlive = false
        self.isPinned = false
        self.isArchived = false
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}

// MARK: - Codable (backward-compatible with old JSON)

extension TerminalSession: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, connection, tmuxSessionName, lastOutput
        case unreadCount, isAlive, isPinned, isArchived, createdAt, lastActiveAt
        case hasUnread // legacy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        connection = try c.decode(ConnectionType.self, forKey: .connection)
        tmuxSessionName = try c.decode(String.self, forKey: .tmuxSessionName)
        lastOutput = try c.decodeIfPresent(String.self, forKey: .lastOutput) ?? ""
        unreadCount = try c.decodeIfPresent(Int.self, forKey: .unreadCount)
            ?? (try c.decodeIfPresent(Bool.self, forKey: .hasUnread) == true ? 1 : 0)
        isAlive = try c.decodeIfPresent(Bool.self, forKey: .isAlive) ?? false
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastActiveAt = try c.decodeIfPresent(Date.self, forKey: .lastActiveAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(connection, forKey: .connection)
        try c.encode(tmuxSessionName, forKey: .tmuxSessionName)
        try c.encode(lastOutput, forKey: .lastOutput)
        try c.encode(unreadCount, forKey: .unreadCount)
        try c.encode(isAlive, forKey: .isAlive)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(isArchived, forKey: .isArchived)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(lastActiveAt, forKey: .lastActiveAt)
    }
}

enum ConnectionType: Codable, Hashable {
    case local
    case remote(host: String, user: String, port: Int)

    var displayLabel: String {
        switch self {
        case .local:
            return "local"
        case .remote(let host, let user, let port):
            let portStr = port == 22 ? "" : ":\(port)"
            return "\(user)@\(host)\(portStr)"
        }
    }

    /// Equality ignoring associated values (for gradient selection etc.)
    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }
}
