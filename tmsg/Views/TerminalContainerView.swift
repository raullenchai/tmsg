import SwiftUI

struct TerminalContainerView: View {
    let session: TerminalSession
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isConnected = false

    var body: some View {
        VStack(spacing: 0) {
            // WhatsApp-style chat header
            HStack(spacing: 12) {
                // Same avatar style as sidebar
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
                        .truncationMode(.tail)
                    Text(statusLine)
                        .font(.system(size: 13))
                        .foregroundColor(isConnected ? Theme.accent : Theme.textMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.headerBg)

            // Terminal
            SwiftTermView(
                session: session,
                isConnected: $isConnected,
                onOutput: { output in
                    sessionManager.updateLastOutput(session.id, output: output)
                },
                onAliveChanged: { alive in
                    sessionManager.updateAliveStatus(session.id, isAlive: alive)
                }
            )
        }
        .background(Theme.chatBg)
    }

    private var statusLine: String {
        if isConnected {
            switch session.connection {
            case .local:
                return "online · \(session.tmuxSessionName)"
            case .remote(let host, let user, let port):
                let portStr = port == 22 ? "" : ":\(port)"
                return "online · \(user)@\(host)\(portStr)"
            }
        }
        return "connecting..."
    }
}
