import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var searchText = ""
    @State private var hoveredId: UUID?
    @State private var renamingId: UUID?
    @State private var renameText = ""
    @State private var tick = false

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var filteredSessions: [TerminalSession] {
        let list = sessionManager.sortedSessions
        if searchText.isEmpty { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.connection.displayLabel.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Rectangle().fill(Theme.divider).frame(height: 1)
            sessionList
        }
        .background(Theme.sidebarBg)
        .onReceive(refreshTimer) { _ in tick.toggle() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Text("Chats")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            headerButton("network", tip: "New Remote Chat (Cmd+Shift+N)") {
                sessionManager.showNewRemoteSheet = true
            }
            headerButton("square.and.pencil", tip: "New Chat (Cmd+N)") {
                sessionManager.showNewLocalSheet = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.headerBg)
    }

    @State private var hoveredButton: String?

    private func headerButton(_ icon: String, tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(hoveredButton == icon ? Theme.hoverBg : .clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { h in hoveredButton = h ? icon : nil }
        .help(tip)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(Theme.textMuted)
            TextField("Search by name or host...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.searchBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.sidebarBg)
    }

    // MARK: - List

    @State private var showArchived = false

    private var sessionList: some View {
        ScrollView {
            let _ = tick
            LazyVStack(spacing: 0) {
                if filteredSessions.isEmpty && !searchText.isEmpty {
                    Text("No sessions found")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textMuted)
                        .padding(.top, 40)
                } else {
                    ForEach(filteredSessions) { session in
                        sessionRow(session)
                    }
                }

                // Archived toggle
                let archived = sessionManager.archivedSessions
                if !archived.isEmpty && searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showArchived.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "archivebox")
                                .font(.system(size: 13))
                            Text("Archived (\(archived.count))")
                                .font(.system(size: 13))
                            Spacer()
                            Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if showArchived {
                        ForEach(archived) { session in
                            sessionRow(session)
                                .opacity(0.7)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: TerminalSession) -> some View {
        SessionRowView(
            session: session,
            isSelected: session.id == sessionManager.selectedSessionId,
            isHovered: session.id == hoveredId,
            isRenaming: renamingId == session.id,
            renameText: $renameText,
            onRenameCommit: {
                sessionManager.renameSession(session.id, to: renameText)
                renamingId = nil
            },
            onRenameCancel: { renamingId = nil }
        )
        .onTapGesture(count: 2) {
            renamingId = session.id
            renameText = session.name
        }
        .onTapGesture(count: 1) {
            sessionManager.selectedSessionId = session.id
            sessionManager.markAsRead(session.id)
        }
        .onHover { h in hoveredId = h ? session.id : nil }
        .contextMenu {
            Button(session.isPinned ? "Unpin" : "Pin") {
                sessionManager.togglePin(session.id)
            }
            Button("Rename...") {
                renamingId = session.id
                renameText = session.name
            }
            Divider()
            Button(session.isArchived ? "Unarchive" : "Archive") {
                sessionManager.toggleArchive(session.id)
            }
            Button("Delete", role: .destructive) {
                sessionManager.deleteSession(session)
            }
        }
    }
}
