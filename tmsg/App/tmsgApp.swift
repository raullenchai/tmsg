import SwiftUI
import AppKit

/// Ensure bare binary (non-.app bundle) registers as a foreground app
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct tmsgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    sessionManager.showNewLocalSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("New Remote Chat...") {
                    sessionManager.showNewRemoteSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Quick New Chat") {
                    sessionManager.createLocalSession()
                }
                .keyboardShortcut("t", modifiers: [.command])
            }

            CommandMenu("Sessions") {
                ForEach(0..<9, id: \.self) { i in
                    Button("Session \(i + 1)") {
                        sessionManager.selectSession(atIndex: i)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: .command)
                }
            }
        }
    }
}
