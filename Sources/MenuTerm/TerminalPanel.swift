import AppKit

/// Fenster, das Tastatureingaben annehmen darf (nötig für ein Terminal).
final class TerminalPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
