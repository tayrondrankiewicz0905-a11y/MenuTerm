# MenuTerm

Ein normales Terminal (Login-Shell, Farben, Kopieren/Einsetzen, `vim`, `htop` …), das oben am Bildschirm
aufklappt – per Menüleisten-Symbol, Dock-Symbol **oder globalem Tastenkürzel**.
Basiert auf [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm).

## Bauen (einmalig)

Voraussetzung: Xcode oder die Command Line Tools (`xcode-select --install`), Internet für den ersten Build.

```
cd MenuTerm
./build.sh
cp -R build/MenuTerm.app /Applications/
open /Applications/MenuTerm.app
```

Ein selbst gebautes Programm wird von Gatekeeper nicht blockiert.

### Als DMG-Datei

```
./make-dmg.sh
```

erzeugt `build/MenuTerm.dmg` (mit Verknüpfung zu „Programme“ zum Hineinziehen). Baut die App bei Bedarf selbst.
Kopierst du die DMG auf einen anderen Mac, blockiert Gatekeeper sie, weil sie nicht notarisiert ist:
Rechtsklick auf die App → „Öffnen“, oder im Terminal `xattr -cr /Applications/MenuTerm.app`.

## Bedienung

| Aktion | So geht's |
| --- | --- |
| Terminal ein-/ausblenden | Tastenkürzel **⌃⌥ Leertaste**, Klick aufs Menüleisten-Symbol oder aufs Dock-Symbol |
| Einstellungen | Rechtsklick aufs Menüleisten-Symbol oder App-Menü „MenuTerm“ |
| Schrift größer/kleiner | ⌘ + / ⌘ − / ⌘ 0 |
| Fenster ausblenden | ⌘ W (die Shell läuft weiter) |
| Shell beenden | `exit` – beim nächsten Öffnen startet eine frische Shell |

Einstellbar: Beim Wegklicken ausblenden, Immer im Vordergrund, Im Dock anzeigen, Tastenkürzel (3 Vorschläge).

## Falls das Menüleisten-Symbol fehlt

Das Terminal ist trotzdem erreichbar: Tastenkürzel oder Dock-Symbol benutzen. Deshalb ist „Im Dock anzeigen“
standardmäßig an.

## Anpassen

- Farben und Schrift: `Sources/MenuTerm/TerminalHost.swift`
- Fenstergröße: `Sources/MenuTerm/AppDelegate.swift` (`buildPanel`)
- Weitere Tastenkürzel: `Sources/MenuTerm/HotKey.swift` (`HotKeyPresets`)

## Ohne eigenen Mac bauen lassen (GitHub Actions)

Die App kann nur auf einem Mac kompiliert werden. Du musst dafür aber nicht an deinem Mac sitzen:
GitHub stellt kostenlos einen Mac in der Cloud bereit, der das Projekt baut und dir die fertige DMG zum Download gibt.
Das geht von jedem Computer aus im Browser.

1. Konto auf [github.com](https://github.com/signup) anlegen und ein neues Repository erstellen (z. B. `MenuTerm`, „Private“ ist okay).
2. Diese ZIP entpacken. Im Repository **Add file → Upload files** wählen und den **Inhalt** des Ordners `MenuTerm`
   hineinziehen (auch den versteckten Ordner `.github`) → **Commit changes**.
3. Reiter **Actions** öffnen. Der Lauf „MenuTerm bauen“ startet automatisch (sonst: Workflow auswählen → **Run workflow**).
   Er dauert einige Minuten.
4. Ist der Lauf grün: Lauf anklicken → unten unter **Artifacts** „MenuTerm-dmg“ herunterladen → entpacken → `MenuTerm.dmg`.
5. Auf dem Mac die DMG öffnen und die App nach „Programme“ ziehen. Weil die App nicht notarisiert ist, im Terminal einmal:
   `xattr -dr com.apple.quarantine /Applications/MenuTerm.app` und danach normal öffnen.

Fehlt der Lauf im Reiter „Actions“, wurde `.github` nicht mit hochgeladen: **Add file → Create new file**, als Namen
`.github/workflows/build.yml` eintippen und den Inhalt aus `Support/build-workflow.yml` einfügen.
Ist der Lauf rot, den fehlgeschlagenen Schritt aufklappen und die Fehlermeldung kopieren.
