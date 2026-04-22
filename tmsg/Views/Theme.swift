import SwiftUI
import AppKit

/// WhatsApp Desktop dark mode color system
enum Theme {
    // Backgrounds
    static let sidebarBg = Color(hex: 0x111B21)
    static let chatBg = Color(hex: 0x0B141A)
    static let headerBg = Color(hex: 0x1F2C34)
    static let hoverBg = Color(hex: 0x202C33)
    static let selectedBg = Color(hex: 0x2A3942)
    static let searchBg = Color(hex: 0x202C33)

    // Text
    static let textPrimary = Color(hex: 0xE9EDEF)
    static let textSecondary = Color(hex: 0x8696A0)
    static let textMuted = Color(hex: 0x667781)

    // Accent
    static let accent = Color(hex: 0x00A884)
    static let accentLight = Color(hex: 0x25D366)
    static let unreadBadge = Color(hex: 0x25D366)

    // Divider
    static let divider = Color(hex: 0x2A3942)

    // Terminal — use same hex as chatBg for seamless blending
    static let terminalBg = NSColor(srgbRed: 0.043, green: 0.078, blue: 0.102, alpha: 1.0)
    static let terminalFg = NSColor(srgbRed: 0.91, green: 0.93, blue: 0.94, alpha: 1.0)

    // Shared avatar gradients
    static func avatarGradient(for connection: ConnectionType) -> LinearGradient {
        let colors: [Color] = switch connection {
        case .local: [Color(hex: 0x00A884), Color(hex: 0x06CF9C)]
        case .remote: [Color(hex: 0xF57C00), Color(hex: 0xFFB74D)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
