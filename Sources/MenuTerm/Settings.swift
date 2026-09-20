import Foundation

/// Einfache Einstellungen, gespeichert in UserDefaults.
final class Settings {
    private let defaults = UserDefaults.standard

    init() {
        defaults.register(defaults: [
            "showInDock": true,        // Dock-Symbol anzeigen (Fallback, falls die Menüleiste voll ist)
            "hideOnClickAway": true,   // Fenster ausblenden, wenn man woanders hinklickt
            "alwaysOnTop": true,       // Fenster vor allen anderen halten
            "fontSize": 13.0,
            "hotKeyPreset": 0,
        ])
    }

    var showInDock: Bool {
        get { defaults.bool(forKey: "showInDock") }
        set { defaults.set(newValue, forKey: "showInDock") }
    }

    var hideOnClickAway: Bool {
        get { defaults.bool(forKey: "hideOnClickAway") }
        set { defaults.set(newValue, forKey: "hideOnClickAway") }
    }

    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: "alwaysOnTop") }
        set { defaults.set(newValue, forKey: "alwaysOnTop") }
    }

    var fontSize: Double {
        get { defaults.double(forKey: "fontSize") }
        set { defaults.set(newValue, forKey: "fontSize") }
    }

    var hotKeyPreset: Int {
        get { defaults.integer(forKey: "hotKeyPreset") }
        set { defaults.set(newValue, forKey: "hotKeyPreset") }
    }
}
