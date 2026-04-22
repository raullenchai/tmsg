import SwiftUI
import AppKit
import SwiftTerm

/// Container that ensures the terminal grabs keyboard focus on click.
class FocusableTerminalView: NSView {
    let terminalView: LocalProcessTerminalView

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)
        addSubview(terminalView)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(terminalView)
        super.mouseDown(with: event)
    }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        window?.makeFirstResponder(terminalView)
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Auto-focus when added to a window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, let window = self.window else { return }
            window.makeFirstResponder(self.terminalView)
        }
    }
}

/// Wraps SwiftTerm's LocalProcessTerminalView in SwiftUI.
struct SwiftTermView: NSViewRepresentable {
    let session: TerminalSession
    @Binding var isConnected: Bool
    var onOutput: (String) -> Void
    var onAliveChanged: (Bool) -> Void

    func makeNSView(context: Context) -> FocusableTerminalView {
        let termView = LocalProcessTerminalView(frame: .zero)

        termView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        termView.nativeBackgroundColor = Theme.terminalBg
        termView.nativeForegroundColor = Theme.terminalFg

        let delegate = TerminalDelegate(
            onOutput: onOutput,
            onProcessExited: {
                Task { @MainActor in
                    isConnected = false
                    onAliveChanged(false)
                }
            }
        )
        context.coordinator.delegate = delegate
        termView.processDelegate = delegate

        let (executable, args) = shellCommand(for: session)

        var envArray = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        envArray.removeAll { $0.hasPrefix("TERM=") }
        envArray.append("TERM=xterm-256color")

        termView.startProcess(
            executable: executable,
            args: args,
            environment: envArray,
            execName: nil
        )

        Task { @MainActor in
            isConnected = true
            onAliveChanged(true)
        }

        return FocusableTerminalView(terminalView: termView)
    }

    func updateNSView(_ nsView: FocusableTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var delegate: TerminalDelegate?
    }

    // MARK: - Shell command construction

    private func shellCommand(for session: TerminalSession) -> (String, [String]) {
        let tmuxName = session.tmuxSessionName
        let tmuxCmd = "command -v tmux >/dev/null && tmux new-session -A -s \(tmuxName) || exec zsh"

        switch session.connection {
        case .local:
            return ("/bin/zsh", ["-l", "-c", tmuxCmd])

        case .remote(let host, let user, let port):
            var args = ["-t"]
            if port != 22 {
                args.append(contentsOf: ["-p", "\(port)"])
            }
            args.append(contentsOf: [
                "-o", "ServerAliveInterval=30",
                "-o", "ServerAliveCountMax=3",
                "\(user)@\(host)",
                tmuxCmd
            ])
            return ("/usr/bin/ssh", args)
        }
    }
}

// MARK: - Terminal Delegate

@MainActor
class TerminalDelegate: NSObject, LocalProcessTerminalViewDelegate {
    let onOutput: (String) -> Void
    let onProcessExited: () -> Void
    private var outputBuffer = ""
    private var bufferTimer: Timer?

    init(onOutput: @escaping (String) -> Void, onProcessExited: @escaping () -> Void) {
        self.onOutput = onOutput
        self.onProcessExited = onProcessExited
    }

    nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
        Task { @MainActor in self.onProcessExited() }
    }

    nonisolated func dataReceived(slice: ArraySlice<UInt8>) {
        guard let str = String(bytes: slice, encoding: .utf8) else { return }
        Task { @MainActor in
            self.outputBuffer += str
            self.bufferTimer?.invalidate()
            self.bufferTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self else { return }
                MainActor.assumeIsolated {
                    let output = self.outputBuffer
                    self.outputBuffer = ""
                    self.onOutput(output)
                }
            }
        }
    }
}
