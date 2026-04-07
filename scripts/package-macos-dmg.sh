#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="OpenWithGUI"
BUILD_CONFIGURATION="debug"
SHOULD_OPEN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release)
            BUILD_CONFIGURATION="release"
            shift
            ;;
        --open)
            SHOULD_OPEN=1
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: ./scripts/package-macos-dmg.sh [--release] [--open]" >&2
            exit 1
            ;;
    esac
done

cd "$ROOT_DIR"

echo "Packaging app bundle for DMG ($BUILD_CONFIGURATION)..."
APP_ARGS=()
if [[ "$BUILD_CONFIGURATION" == "release" ]]; then
    APP_ARGS+=(--release)
fi
./scripts/package-macos-app.sh "${APP_ARGS[@]}"

APP_BUNDLE_DIR="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"
STAGING_DIR="$ROOT_DIR/dist/.dmg-staging"

if [[ ! -d "$APP_BUNDLE_DIR" ]]; then
    echo "App bundle not found at: $APP_BUNDLE_DIR" >&2
    exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "Packaged DMG:"
echo "  $DMG_PATH"

if [[ "$SHOULD_OPEN" -eq 1 ]]; then
    echo "Opening DMG..."
    open "$DMG_PATH"
fi
