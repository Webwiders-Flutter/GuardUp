#!/usr/bin/env bash
# Regenerates the web favicon + PWA icons from assets/images/app_logo_mark.png.
# Uses macOS `sips` (no extra installs). Run from the guardup_admin folder:
#   bash tool/generate_web_icons.sh
set -euo pipefail

SRC="assets/images/app_logo_mark.png"   # square shield mark, transparent background
BG="12141C"                              # matches manifest background_color
OUT="web"
TMP="$(mktemp -d)"

# Transparent icons: favicon + standard PWA icons.
sips -z 32 32   "$SRC" --out "$OUT/favicon.png"          >/dev/null
sips -z 192 192 "$SRC" --out "$OUT/icons/icon-192.png"   >/dev/null
sips -z 512 512 "$SRC" --out "$OUT/icons/icon-512.png"   >/dev/null

# Padded icons on a solid background (maskable icons need a ~20% safe zone,
# iOS fills transparency with black, so give it the brand background).
padded() { # size inner out
  sips -z "$2" "$2" "$SRC" --out "$TMP/inner.png" >/dev/null
  sips -p "$1" "$1" --padColor "$BG" "$TMP/inner.png" --out "$3" >/dev/null 2>&1
}
padded 192 144 "$OUT/icons/icon-192-maskable.png"
padded 512 384 "$OUT/icons/icon-512-maskable.png"
padded 180 144 "$OUT/icons/apple-touch-icon.png"

rm -rf "$TMP"
echo "Web icons regenerated from $SRC"
