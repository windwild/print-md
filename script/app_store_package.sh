#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PrintMD"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_STORE_DIR="$DIST_DIR/app-store"
ENTITLEMENTS="$ROOT_DIR/Config/MacAppStore.entitlements"

VERSION="${1:-${APP_VERSION:-}}"
APP_STORE_SIGN_IDENTITY="${APP_STORE_SIGN_IDENTITY:-}"
INSTALLER_SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-}"
CODESIGN_TIMESTAMP="${CODESIGN_TIMESTAMP:-0}"

usage() {
  cat >&2 <<USAGE
usage:
  APP_STORE_SIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)" \\
  INSTALLER_SIGN_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)" \\
  PROVISIONING_PROFILE="/path/to/Mac_App_Store.provisionprofile" \\
  $0 VERSION

notes:
  APP_STORE_SIGN_IDENTITY may also be a legacy "3rd Party Mac Developer Application: ..." identity.
  The provisioning profile must be a Mac App Store profile for com.wwgao.printmd.
USAGE
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

if [ -z "$VERSION" ]; then
  usage
  exit 2
fi

if [ -z "$APP_STORE_SIGN_IDENTITY" ]; then
  echo "APP_STORE_SIGN_IDENTITY is required." >&2
  usage
  exit 2
fi

if [ -z "$INSTALLER_SIGN_IDENTITY" ]; then
  echo "INSTALLER_SIGN_IDENTITY is required." >&2
  usage
  exit 2
fi

if [ -z "$PROVISIONING_PROFILE" ] || [ ! -f "$PROVISIONING_PROFILE" ]; then
  echo "PROVISIONING_PROFILE must point to a downloaded Mac App Store provisioning profile." >&2
  usage
  exit 2
fi

require_command codesign
require_command ditto
require_command productbuild
require_command pkgutil

cd "$ROOT_DIR"

rm -rf "$APP_STORE_DIR"
mkdir -p "$APP_STORE_DIR"

APP_VERSION="$VERSION" BUILD_CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" --bundle

cp "$PROVISIONING_PROFILE" "$APP_CONTENTS/embedded.provisionprofile"

codesign_args=(--force --deep --options runtime)
if [ "$CODESIGN_TIMESTAMP" = "1" ]; then
  codesign_args+=(--timestamp)
fi

codesign "${codesign_args[@]}" \
  --entitlements "$ENTITLEMENTS" \
  --sign "$APP_STORE_SIGN_IDENTITY" \
  "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

PKG_PATH="$APP_STORE_DIR/$APP_NAME-v$VERSION-mac-app-store.pkg"

productbuild \
  --component "$APP_BUNDLE" /Applications \
  --product "$INFO_PLIST" \
  --sign "$INSTALLER_SIGN_IDENTITY" \
  "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH"

echo "$PKG_PATH"
