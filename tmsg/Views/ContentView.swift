import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 360)

            Rectangle().fill(Theme.divider).frame(width: 1)

            // Keep ALL terminal views alive, show/hide based on selection.
            // This preserves scrollback and terminal state when switching.
            ZStack {
                ForEach(sessionManager.sessions.filter { !$0.isArchived }) { session in
                    let isVisible = session.id == sessionManager.selectedSessionId
                    TerminalContainerView(session: session)
                        .opacity(isVisible ? 1 : 0)
                        .allowsHitTesting(isVisible)
                }

                if sessionManager.selectedSession == nil {
                    emptyState
                }
            }
        }
        .background(Theme.chatBg)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $sessionManager.showNewLocalSheet) {
            NewLocalSessionSheet()
        }
        .sheet(isPresented: $sessionManager.showNewRemoteSheet) {
            NewRemoteSessionSheet()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56, weight: .thin))
                .foregroundColor(Theme.textMuted)
            Text("tmsg")
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("Select a chat or start a new one")
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
            HStack(spacing: 12) {
                Button { sessionManager.showNewLocalSheet = true } label: {
                    Label("New Chat", systemImage: "terminal")
                }
                Button { sessionManager.showNewRemoteSheet = true } label: {
                    Label("Remote", systemImage: "network")
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.chatBg)
    }
}
