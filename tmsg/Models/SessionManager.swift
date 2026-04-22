import Foundation
import SwiftUI
import UserNotifications

@MainActor
class SessionManager: ObservableObject {
    @Published var sessions: [TerminalSession] = []
    @Published var selectedSessionId: UUID?
    @Published var showNewLocalSheet = false
    @Published var showNewRemoteSheet = false
    @Published var showGlobalSearch = false

    private let storageURL: URL
    private var saveTask: Task<Void, Never>?
    private let selectedIdKey = "selectedSessionId"

    // MARK: - Computed

    var selectedSession: TerminalSession? {
        guard let id = selectedSessionId else { return nil }
        return sessions.first { $0.id == id }
    }

    /// Sessions sorted like a messenger: pinned first, then by most recent activity
    var sortedSessions: [TerminalSession] {
        let active = sessions.filter { !$0.isArchived }
        let pinned = active.filter(\.isPinned).sorted { $0.lastActiveAt > $1.lastActiveAt }
        let unpinned = active.filter { !$0.isPinned }.sorted { $0.lastActiveAt > $1.lastActiveAt }
        return pinned + unpinned
    }

    var archivedSessions: [TerminalSession] {
        sessions.filter(\.isArchived).sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    // MARK: - Init

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("tmsg", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.storageURL = appDir.appendingPathComponent("sessions.json")

        loadSessions()

        if sessions.isEmpty {
            createLocalSession(name: "Default")
        } else {
            if let saved = UserDefaults.standard.string(forKey: selectedIdKey),
               let uuid = UUID(uuidString: saved),
               sessions.contains(where: { $0.id == uuid }) {
                selectedSessionId = uuid
            } else {
                selectedSessionId = sessions.first?.id
            }
        }

        // Request notification permission (only works in .app bundle)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    // MARK: - Session CRUD

    func createLocalSession(name: String? = nil) {
        let n = name ?? "Local \(sessions.filter { $0.connection.isLocal }.count + 1)"
        let session = TerminalSession(name: n, connection: .local)
        sessions.append(session)
        selectedSessionId = session.id
        saveSessions()
    }

    func createRemoteSession(name: String, host: String, user: String, port: Int = 22, tmuxSession: String? = nil) {
        let session = TerminalSession(
            name: name,
            connection: .remote(host: host, user: user, port: port),
            tmuxSessionName: tmuxSession
        )
        sessions.append(session)
        selectedSessionId = session.id
        saveSessions()
    }

    func deleteSession(_ session: TerminalSession) {
        sessions.removeAll { $0.id == session.id }
        if selectedSessionId == session.id {
            selectedSessionId = sortedSessions.first?.id
        }
        saveSessions()
    }

    func renameSession(_ id: UUID, to newName: String) {
        guard !newName.isEmpty, let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].name = newName
        saveSessions()
    }

    // MARK: - Pin / Archive

    func togglePin(_ id: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].isPinned.toggle()
        saveSessions()
    }

    func toggleArchive(_ id: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].isArchived.toggle()
        if sessions[idx].isArchived && selectedSessionId == id {
            selectedSessionId = sortedSessions.first?.id
        }
        saveSessions()
    }

    // MARK: - Selection

    func selectSession(atIndex index: Int) {
        let sorted = sortedSessions
        guard index >= 0 && index < sorted.count else { return }
        selectedSessionId = sorted[index].id
        markAsRead(sorted[index].id)
    }

    func markAsRead(_ sessionId: UUID) {
        if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[idx].unreadCount = 0
            // WhatsApp behavior: reading a chat does NOT change its sort position.
            // Only new output (in updateLastOutput) moves a session up.
            saveSessions()
        }
        UserDefaults.standard.set(sessionId.uuidString, forKey: selectedIdKey)
    }

    // MARK: - Output Tracking

    func updateLastOutput(_ sessionId: UUID, output: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let clean = output.strippingANSI()
        sessions[idx].lastOutput = String(clean.suffix(200))
        sessions[idx].lastActiveAt = Date()

        if sessions[idx].id != selectedSessionId {
            let newLines = max(1, clean.components(separatedBy: .newlines).count)
            sessions[idx].unreadCount = min(sessions[idx].unreadCount + newLines, 999)
            checkKeywordNotification(session: sessions[idx], output: clean)
        }
        debouncedSave()
    }

    func updateAliveStatus(_ sessionId: UUID, isAlive: Bool) {
        if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[idx].isAlive = isAlive
        }
    }

    // MARK: - Keyword Notifications

    private let keywords = ["error", "fail", "success", "done", "complete",
                            "BUILD SUCCEEDED", "BUILD FAILED", "SIGTERM", "fatal"]

    private func checkKeywordNotification(session: TerminalSession, output: String) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        for keyword in keywords {
            if output.localizedCaseInsensitiveContains(keyword) {
                let line = output.components(separatedBy: .newlines)
                    .first(where: { $0.localizedCaseInsensitiveContains(keyword) }) ?? output.prefix(100).description
                let content = UNMutableNotificationContent()
                content.title = session.name
                content.body = String(line.prefix(120))
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                break
            }
        }
    }

    // MARK: - Persistence

    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            saveSessions()
        }
    }

    private func saveSessions() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(sessions) {
            try? data.write(to: storageURL)
        }
    }

    private func loadSessions() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([TerminalSession].self, from: data) {
            self.sessions = loaded
            for i in sessions.indices {
                sessions[i].isAlive = false
            }
        }
    }
}
