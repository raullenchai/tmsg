import Foundation

extension String {
    /// Strip ANSI escape sequences (colors, cursor movement, etc.)
    func strippingANSI() -> String {
        guard let regex = try? NSRegularExpression(pattern: "\u{1B}\\[[0-9;]*[a-zA-Z]") else {
            return self
        }
        return regex.stringByReplacingMatches(in: self, range: NSRange(startIndex..., in: self), withTemplate: "")
    }
}
