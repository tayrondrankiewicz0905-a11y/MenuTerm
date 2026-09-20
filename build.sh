#!/bin/bash
# Baut MenuTerm.app aus dem Swift-Package (ohne Xcode-Projekt).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/MenuTerm.app"

echo "→ Kompiliere (beim ersten Mal wird SwiftTerm von GitHub geladen) …"
swift build -c release || swift build -c release --disable-sandbox
BIN="$(swift build -c release --show-bin-path)"

echo "→ Erstelle App-Bundle …"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/MenuTerm" "$APP/Contents/MacOS/MenuTerm"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ressourcen-Bündel der Abhängigkeiten (falls vorhanden) mitkopieren
for bundle in "$BIN"/*.bundle; do
    if [ -e "$bundle" ]; then
        cp -R "$bundle" "$APP/Contents/Resources/"
    fi
done

echo "→ Signiere lokal (ad hoc) …"
if ! codesign --force --deep --sign - "$APP"; then
    echo "Warnung: Signieren fehlgeschlagen – die App startet auf Apple Silicon trotzdem (Binary ist vom Linker signiert)."
fi

echo
echo "✓ Fertig: $(pwd)/$APP"
echo "  Installieren:  cp -R \"$APP\" /Applications/ && open /Applications/MenuTerm.app"
