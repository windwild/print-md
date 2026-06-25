#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PrintMD"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
RELEASE_DIR="$DIST_DIR/release"

VERSION="${1:-${APP_VERSION:-}}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"
ALLOW_NON_DEVELOPER_ID="${ALLOW_NON_DEVELOPER_ID:-0}"

usage() {
  cat >&2 <<USAGE
usage: SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE="profile" $0 VERSION

examples:
  SIGN_IDENTITY="Developer ID Application: Jiayang Gao (TEAMID)" NOTARY_PROFILE="printmd-notary" $0 0.1.0
  SIGN_IDENTITY="Developer ID Application: Jiayang Gao (TEAMID)" SKIP_NOTARIZATION=1 $0 0.1.0
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

if [ -z "$SIGN_IDENTITY" ]; then
  echo "SIGN_IDENTITY is required for a public macOS release." >&2
  usage
  exit 2
fi

if [[ "$SIGN_IDENTITY" != Developer\ ID\ Application:* && "$ALLOW_NON_DEVELOPER_ID" != "1" ]]; then
  echo "SIGN_IDENTITY must be a Developer ID Application certificate for public distribution." >&2
  echo "Set ALLOW_NON_DEVELOPER_ID=1 only for local signing tests." >&2
  exit 2
fi

if [ "$SKIP_NOTARIZATION" != "1" ] && [ -z "$NOTARY_PROFILE" ]; then
  echo "NOTARY_PROFILE is required unless SKIP_NOTARIZATION=1." >&2
  usage
  exit 2
fi

require_command codesign
require_command ditto
require_command xcrun

cd "$ROOT_DIR"

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

APP_VERSION="$VERSION" BUILD_CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" --bundle

codesign --force --deep --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" \
  "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

NOTARY_ZIP="$RELEASE_DIR/$APP_NAME-v$VERSION-notary.zip"
FINAL_ZIP="$RELEASE_DIR/$APP_NAME-v$VERSION-macos.zip"

ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"

if [ "$SKIP_NOTARIZATION" != "1" ]; then
  xcrun notarytool submit "$NOTARY_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  spctl -a -vv -t exec "$APP_BUNDLE"
else
  echo "Skipping notarization. The final zip is not suitable for broad public distribution." >&2
fi

ditto -c -k --keepParent "$APP_BUNDLE" "$FINAL_ZIP"

echo "$FINAL_ZIP"
