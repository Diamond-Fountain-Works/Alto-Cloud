#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Diamond Transfer"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_DIR="$ROOT_DIR/dist/dmg"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME"

cd "$ROOT_DIR"

"$ROOT_DIR/script/build_and_run.sh" --verify

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$DMG_PATH"
