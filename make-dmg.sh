#!/bin/bash
# Baut (falls nötig) MenuTerm.app und packt sie in eine DMG mit Verknüpfung zu "Programme".
# Läuft nur auf einem Mac (braucht hdiutil).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/MenuTerm.app"
DMG="build/MenuTerm.dmg"

if [ ! -d "$APP" ]; then
    bash ./build.sh
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
# hdiutil scheitert auf Build-Servern manchmal mit "Resource busy" – deshalb bis zu 3 Versuche
for attempt in 1 2 3; do
    if hdiutil create -volname "MenuTerm" -srcfolder "$STAGE" -ov -format UDZO "$DMG"; then
        break
    fi
    if [ "$attempt" = "3" ]; then
        echo "hdiutil ist dreimal fehlgeschlagen."
        exit 1
    fi
    echo "Neuer Versuch …"
    sleep 5
done

echo
echo "✓ Fertig: $(pwd)/$DMG"
