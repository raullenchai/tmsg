import SwiftUI

struct SessionRowView: View {
    let session: TerminalSession
    let isSelected: Bool
    let isHovered: Bool
    var isRenaming: Bool = false
    @Binding var renameText: String
    var onRenameCommit: () -> Void = {}
    var onRenameCancel: () -> Void = {}
    @FocusState private var renameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            avatar
            info
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isSelected ? Theme.selectedBg : (isHovered ? Theme.hoverBg : .clear))
        .onChange(of: isRenaming) { _, renaming in
            if renaming { renameFieldFocused = true }
        }
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Theme.avatarGradient(for: session.connection))
                .frame(width: 49, height: 49)
                .overlay {
                    Image(systemName: session.connection.isLocal ? "terminal" : "network")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

            if session.isAlive {
                Circle()
                    .fill(Theme.accentLight)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Theme.sidebarBg, lineWidth: 2.5))
                    .offset(x: 1, y: 1)
            }
        }
    }

    // MARK: - Info

    private var info: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if session.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                        .rotationEffect(.degrees(45))
                }

                if isRenaming {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.textPrimary)
                        .focused($renameFieldFocused)
                        .onSubmit { onRenameCommit() }
                        .onExitCommand { onRenameCancel() }
                } else {
                    Text(session.name)
                        .font(.system(size: 16, weight: session.hasUnread ? .semibold : .regular))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                Text(timeLabel)
                    .font(.system(size: 12))
                    .foregroundColor(session.hasUnread ? Theme.unreadBadge : Theme.textMuted)
            }

            HStack(spacing: 0) {
                previewText
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                if session.unreadCount > 0 {
                    Text(session.unreadCount > 99 ? "99+" : "\(session.unreadCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.unreadBadge)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var previewText: Text {
        if !session.lastOutput.isEmpty {
            let line = session.lastOutput.components(separatedBy: .newlines)
                .last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
            return Text(line)
        }
        return Text(session.connection.displayLabel)
    }

    private var timeLabel: String {
        let diff = Date().timeIntervalSince(session.lastActiveAt)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return "\(Int(diff / 86400))d"
    }
}
