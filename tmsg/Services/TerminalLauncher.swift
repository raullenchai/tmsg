import AppKit

/// Launches sessions in the user's preferred terminal app (iTerm2 > Terminal.app)
enum TerminalLauncher {

    enum TerminalApp: String {
        case iterm2 = "iTerm2"
        case terminal = "Terminal"
    }

    /// Detect which terminal is available, prefer iTerm2
    static var preferred: TerminalApp {
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") != nil {
            return .iterm2
        }
        return .terminal
    }

    /// Open a session in the user's preferred terminal
    static func open(session: TerminalSession) {
        let cmd = shellCommand(for: session)
        switch preferred {
        case .iterm2:
            openInITerm2(command: cmd, title: session.name)
        case .terminal:
            openInTerminalApp(command: cmd, title: session.name)
        }
    }

    /// Bring an existing session's terminal tab to front
    static func focus(session: TerminalSession) {
        // Just activate the terminal app — iTerm2/Terminal will show the last used tab
        let bundleId = preferred == .iterm2 ? "com.googlecode.iterm2" : "com.apple.Terminal"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    // MARK: - Private

    private static func shellCommand(for session: TerminalSession) -> String {
        let tmuxName = session.tmuxSessionName
        let tmuxCmd = "command -v tmux >/dev/null && tmux new-session -A -s \(tmuxName) || exec zsh"

        switch session.connection {
        case .local:
            return tmuxCmd
        case .remote(let host, let user, let port):
            var ssh = "ssh -t"
            if port != 22 { ssh += " -p \(port)" }
            ssh += " -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
            ssh += " \(user)@\(host)"
            ssh += " '\(tmuxCmd)'"
            return ssh
        }
    }

    private static func openInITerm2(command: String, title: String) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let titleEscaped = title.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "iTerm2"
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if
            tell current window
                create tab with default profile
                tell current session
                    write text "\(escaped)"
                    set name to "\(titleEscaped)"
                end tell
            end tell
        end tell
        """

        runAppleScript(script)
    }

    private static func openInTerminalApp(command: String, title: String) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """

        runAppleScript(script)
    }

    private static func runAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error { print("AppleScript error: \(error)") }
        }
    }
}
