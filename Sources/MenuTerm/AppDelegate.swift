import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private let settings = Settings()
    private var statusItem: NSStatusItem?
    private var panel: TerminalPanel!
    private var host: TerminalHost!
    private var hotKey: HotKey?
    private var restartPending = false

    // MARK: - Start

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(settings.showInDock ? .regular : .accessory)
        buildMainMenu()
        buildPanel()
        setupStatusItem()
        registerHotKey(announceFailure: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appResignedActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Beim ersten Start gleich zeigen, damit man sofort sieht, dass es läuft.
        showPanel()
    }

    /// Klick aufs Dock-Symbol oder erneutes Öffnen der App aus dem Finder.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return true
    }

    // MARK: - Fenster

    private func buildPanel() {
        let rect = NSRect(x: 0, y: 0, width: 900, height: 420)
        let p = TerminalPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        p.title = "MenuTerm"
        p.isReleasedWhenClosed = false
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        p.appearance = NSAppearance(named: .darkAqua)
        p.backgroundColor = TerminalHost.backgroundColor
        p.level = settings.alwaysOnTop ? .floating : .normal
        p.setFrameAutosaveName("MenuTermPanel")
        panel = p
        installHost()
    }

    private func installHost() {
        let h = TerminalHost(fontSize: CGFloat(settings.fontSize))
        h.onTitleChange = { [weak self] title in
            self?.panel.title = title.isEmpty ? "MenuTerm" : title
        }
        h.onExit = { [weak self] in
            self?.shellExited()
        }
        host = h
        panel.contentView = h.view
    }

    /// Wenn die Shell beendet wird (z. B. mit `exit`): Fenster zu, beim nächsten Öffnen neue Shell.
    private func shellExited() {
        panel.orderOut(nil)
        // Beendet sich die Shell schon nach kurzer Zeit wieder, nicht sofort neu starten
        // (sonst Endlosschleife), sondern erst beim nächsten Öffnen.
        if Date().timeIntervalSince(host.startedAt) < 2 {
            restartPending = true
        } else {
            installHost()
        }
    }

    private func positionPanel() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        var frame = panel.frame
        frame.size.width = min(frame.width, visible.width)
        frame.size.height = min(frame.height, visible.height)
        frame.origin.x = visible.midX - frame.width / 2
        frame.origin.y = visible.maxY - frame.height
        panel.setFrame(frame, display: true)
    }

    private func showPanel() {
        if restartPending {
            restartPending = false
            installHost()
        }
        if !panel.isVisible { positionPanel() }
        panel.level = settings.alwaysOnTop ? .floating : .normal
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(host.view)
    }

    private func hidePanel() {
        panel.orderOut(nil)
    }

    @objc private func togglePanel() {
        if panel.isVisible && NSApp.isActive {
            hidePanel()
        } else {
            showPanel()
        }
    }

    @objc private func hideTerminal() {
        hidePanel()
    }

    @objc private func appResignedActive() {
        guard settings.hideOnClickAway, panel.isVisible else { return }
        hidePanel()
    }

    // MARK: - Menüleisten-Symbol

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            if let image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "MenuTerm") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = ">_"
            }
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.control) ?? false)
        if wantsMenu {
            statusItem?.menu = makeSettingsMenu()
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePanel()
        }
    }

    // MARK: - Menüs

    private func menuItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func makeSettingsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem("Terminal ein-/ausblenden", #selector(togglePanel)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Beim Wegklicken ausblenden", #selector(toggleHideOnClickAway)))
        menu.addItem(menuItem("Immer im Vordergrund", #selector(toggleAlwaysOnTop)))
        menu.addItem(menuItem("Im Dock anzeigen", #selector(toggleShowInDock)))

        let hotKeyItem = NSMenuItem(title: "Tastenkürzel", action: nil, keyEquivalent: "")
        let hotKeyMenu = NSMenu()
        for (index, preset) in HotKeyPresets.all.enumerated() {
            let item = menuItem(preset.title, #selector(selectHotKeyPreset(_:)))
            item.tag = index
            hotKeyMenu.addItem(item)
        }
        hotKeyItem.submenu = hotKeyMenu
        menu.addItem(hotKeyItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "MenuTerm beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        // App-Menü
        let appItem = NSMenuItem()
        let appMenu = makeSettingsMenu()
        appMenu.insertItem(
            NSMenuItem(title: "Über MenuTerm", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
            at: 0
        )
        appMenu.insertItem(.separator(), at: 1)
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        // Bearbeiten
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Bearbeiten")
        editMenu.addItem(withTitle: "Kopieren", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Einsetzen", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Alles auswählen", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        // Darstellung
        let viewItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Darstellung")
        viewMenu.addItem(menuItem("Schrift größer", #selector(fontBigger), key: "+"))
        viewMenu.addItem(menuItem("Schrift kleiner", #selector(fontSmaller), key: "-"))
        viewMenu.addItem(menuItem("Standardgröße", #selector(fontReset), key: "0"))
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        // Fenster
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Fenster")
        windowMenu.addItem(menuItem("Terminal ausblenden", #selector(hideTerminal), key: "w"))
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)

        NSApp.mainMenu = mainMenu
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(toggleHideOnClickAway):
            menuItem.state = settings.hideOnClickAway ? .on : .off
        case #selector(toggleAlwaysOnTop):
            menuItem.state = settings.alwaysOnTop ? .on : .off
        case #selector(toggleShowInDock):
            menuItem.state = settings.showInDock ? .on : .off
        case #selector(selectHotKeyPreset(_:)):
            menuItem.state = (menuItem.tag == settings.hotKeyPreset) ? .on : .off
        default:
            break
        }
        return true
    }

    // MARK: - Einstellungen

    @objc private func toggleHideOnClickAway() {
        settings.hideOnClickAway.toggle()
    }

    @objc private func toggleAlwaysOnTop() {
        settings.alwaysOnTop.toggle()
        panel.level = settings.alwaysOnTop ? .floating : .normal
    }

    @objc private func toggleShowInDock() {
        settings.showInDock.toggle()
        NSApp.setActivationPolicy(settings.showInDock ? .regular : .accessory)
        showPanel()
    }

    @objc private func selectHotKeyPreset(_ sender: NSMenuItem) {
        let previous = settings.hotKeyPreset
        settings.hotKeyPreset = sender.tag
        if !registerHotKey(announceFailure: true) {
            settings.hotKeyPreset = previous
            registerHotKey(announceFailure: false)
        }
    }

    @objc private func fontBigger() { changeFont(by: 1) }
    @objc private func fontSmaller() { changeFont(by: -1) }
    @objc private func fontReset() {
        settings.fontSize = 13
        host.setFontSize(13)
    }

    private func changeFont(by delta: Double) {
        settings.fontSize = min(40, max(8, settings.fontSize + delta))
        host.setFontSize(CGFloat(settings.fontSize))
    }

    // MARK: - Globales Tastenkürzel

    @discardableResult
    private func registerHotKey(announceFailure: Bool) -> Bool {
        hotKey = nil  // altes Kürzel freigeben

        let index = min(max(settings.hotKeyPreset, 0), HotKeyPresets.all.count - 1)
        let preset = HotKeyPresets.all[index]
        let newHotKey = HotKey(
            keyCode: UInt32(preset.keyCode),
            modifiers: UInt32(preset.modifiers)
        ) { [weak self] in
            self?.togglePanel()
        }

        guard let newHotKey else {
            if announceFailure {
                let alert = NSAlert()
                alert.messageText = "Tastenkürzel nicht verfügbar"
                alert.informativeText = "Dieses Tastenkürzel ist schon belegt. Bitte wähle ein anderes im Menü unter „Tastenkürzel“."
                alert.runModal()
            }
            return false
        }
        hotKey = newHotKey
        return true
    }
}
