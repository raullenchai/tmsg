import SwiftUI

// MARK: - New Local Chat

struct NewLocalSessionSheet: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Avatar preview
            Circle()
                .fill(Theme.avatarGradient(for: .local))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "terminal")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 20)

            Text("New Chat")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            // Name input
            TextField("Give this chat a name...", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(12)
                .background(Theme.searchBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)
                .focused($focused)
                .onSubmit {
                    sessionManager.createLocalSession(name: name.isEmpty ? nil : name)
                    dismiss()
                }

            Text("A local terminal session with tmux persistence.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Start Chat") {
                    sessionManager.createLocalSession(name: name.isEmpty ? nil : name)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x00A884))
            }
            .padding(20)
        }
        .frame(width: 360, height: 320)
        .background(Theme.sidebarBg)
        .onAppear { focused = true }
    }
}

// MARK: - New Remote Chat

struct NewRemoteSessionSheet: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var host = ""
    @State private var user = ""
    @State private var port = "22"
    @State private var tmuxSession = ""
    @FocusState private var focusedField: Field?

    enum Field { case name, host, user, port, tmux }

    private var isValid: Bool {
        !host.isEmpty && !user.isEmpty && (Int(port) != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Circle()
                    .fill(Theme.avatarGradient(for: .remote(host: "", user: "", port: 22)))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "network")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 20)

                Text("New Remote Chat")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.bottom, 16)

            // Form
            VStack(spacing: 12) {
                formField("Chat Name", text: $name, prompt: "e.g. Production Agent", field: .name)
                formField("Host", text: $host, prompt: "192.168.1.100", field: .host)
                HStack(spacing: 10) {
                    formField("User", text: $user, prompt: "root", field: .user)
                    formField("Port", text: $port, prompt: "22", field: .port)
                        .frame(width: 80)
                }
                formField("tmux Session", text: $tmuxSession, prompt: "auto-generated if empty", field: .tmux)
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.horizontal, 24)

            if !host.isEmpty && !user.isEmpty && Int(port) == nil {
                Text("Port must be a number")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Start Chat") {
                    let displayName = name.isEmpty ? "\(user)@\(host)" : name
                    let tmux = tmuxSession.isEmpty ? nil : tmuxSession
                    sessionManager.createRemoteSession(
                        name: displayName,
                        host: host,
                        user: user,
                        port: Int(port) ?? 22,
                        tmuxSession: tmux
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x00A884))
                .disabled(!isValid)
            }
            .padding(20)
        }
        .frame(width: 400, height: 460)
        .background(Theme.sidebarBg)
        .onAppear { focusedField = .name }
    }

    private func formField(_ label: String, text: Binding<String>, prompt: String, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .padding(10)
                .background(Theme.searchBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($focusedField, equals: field)
        }
    }
}
