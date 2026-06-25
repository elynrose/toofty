#!/usr/bin/env bash
# Build Toofty for iOS (simulator or device).
# Run from project root:
#   ./scripts/build_ios.sh              # debug simulator build
#   ./scripts/build_ios.sh --release    # release (requires signing for device)
#   ./scripts/build_ios.sh --ipa        # App Store .ipa (requires signing)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

MODE="debug"
for arg in "$@"; do
  case "$arg" in
    --release) MODE="release" ;;
    --ipa) MODE="ipa" ;;
  esac
done

if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "==> Xcode developer dir not set. Run once (requires password):"
  echo "    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  echo "    sudo xcodebuild -runFirstLaunch"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "==> CocoaPods not found. Install with: brew install cocoapods"
  exit 1
fi

echo "==> Flutter pub get"
flutter pub get

echo "==> Installing iOS pods"
cd ios
pod install
cd "$ROOT"

case "$MODE" in
  debug)
    echo "==> Building iOS debug (simulator)"
    flutter build ios --simulator --debug
    echo ""
    echo "Run on simulator:"
    echo "  open -a Simulator && flutter run -d ios"
    ;;
  release)
    echo "==> Building iOS release (no codesign — open Xcode to sign for device)"
    flutter build ios --release --no-codesign
    echo ""
    echo "Open ios/Runner.xcworkspace in Xcode → Signing & Capabilities → select your Team."
    ;;
  ipa)
    echo "==> Building App Store IPA (requires Apple Developer signing in Xcode)"
    flutter build ipa --release
    echo ""
    echo "Upload with Transporter or Xcode Organizer:"
    ls -lh build/ios/ipa/*.ipa 2>/dev/null || true
    ;;
esac
