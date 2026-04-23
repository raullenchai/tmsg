import SwiftUI

struct TerminalContainerView: View {
    let session: TerminalSession
    @EnvironmentObject var sessionManager: SessionManager
    @State private var launched = false

    var body: some View {
        VStack(spacing: 0) {
            header
            sessionDetail
        }
        .background(Theme.chatBg)
        .onAppear {
            if !launched {
                TerminalLauncher.open(session: session)
                launched = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.avatarGradient(for: session.connection))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: session.connection.isLocal ? "terminal" : "network")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(statusLine)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            Button {
                TerminalLauncher.open(session: session)
                launched = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12))
                    Text("Open in \(TerminalLauncher.preferred.rawValue)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.headerBg)
    }

    // MARK: - Detail

    private var sessionDetail: some View {
        VStack(spacing: 24) {
            Spacer()

            Circle()
                .fill(Theme.avatarGradient(for: session.connection))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: session.connection.isLocal ? "terminal" : "network")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

            VStack(spacing: 6) {
                Text(session.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(connectionLabel)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                Text("tmux: \(session.tmuxSessionName)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }

            HStack(spacing: 16) {
                actionButton("New Tab", icon: "arrow.up.forward.app") {
                    TerminalLauncher.open(session: session)
                }
                actionButton("Focus", icon: "macwindow") {
                    TerminalLauncher.focus(session: session)
                }
            }

            Spacer()
        }
    }

    private func actionButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(Theme.headerBg)
                    .clipShape(Circle())
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(Theme.accent)
        }
        .buttonStyle(.plain)
    }

    private var statusLine: String {
        switch session.connection {
        case .local:
            return "local · \(TerminalLauncher.preferred.rawValue)"
        case .remote(let host, let user, _):
            return "\(user)@\(host) · \(TerminalLauncher.preferred.rawValue)"
        }
    }

    private var connectionLabel: String {
        session.connection.displayLabel
    }
}
