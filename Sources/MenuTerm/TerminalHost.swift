import AppKit
import SwiftTerm

/// Hält die Terminal-Ansicht und die darin laufende Login-Shell.
@MainActor
final class TerminalHost: NSObject, LocalProcessTerminalViewDelegate {
    static let backgroundColor = NSColor(calibratedRed: 0.09, green: 0.09, blue: 0.11, alpha: 1)
    static let foregroundColor = NSColor(calibratedRed: 0.86, green: 0.87, blue: 0.90, alpha: 1)

    let view: LocalProcessTerminalView
    let startedAt = Date()
    var onTitleChange: ((String) -> Void)?
    var onExit: (() -> Void)?

    init(fontSize: CGFloat) {
        view = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 900, height: 420))
        super.init()
        view.processDelegate = self
        view.autoresizingMask = [.width, .height]
        view.nativeBackgroundColor = Self.backgroundColor
        view.nativeForegroundColor = Self.foregroundColor
        view.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        startShell()
    }

    func setFontSize(_ size: CGFloat) {
        view.font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private func startShell() {
        let shell = Self.loginShell()
        view.startProcess(
            executable: shell,
            args: ["-l"],
            environment: Self.makeEnvironment(shell: shell),
            execName: nil,
            currentDirectory: NSHomeDirectory()
        )
    }

    private static func loginShell() -> String {
        if let pw = getpwuid(getuid()), let sh = pw.pointee.pw_shell {
            let path = String(cString: sh)
            if !path.isEmpty { return path }
        }
        return "/bin/zsh"
    }

    private static func makeEnvironment(shell: String) -> [String] {
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color", trueColor: true)

        // Sprache des Systems statt fest "en_US"
        env.removeAll { $0.hasPrefix("LANG=") }
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let region = Locale.current.region?.identifier ?? "US"
        env.append("LANG=\(language)_\(region).UTF-8")

        env.append("SHELL=\(shell)")
        env.append("TERM_PROGRAM=MenuTerm")
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env.append("PATH=\(path)")
        return env
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        onTitleChange?(title)
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        onExit?()
    }
}
