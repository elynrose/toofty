#!/usr/bin/env bash
# Build a signed Android App Bundle (.aab) for Google Play upload.
# Run from project root:
#   ./scripts/build_playstore_aab.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEYSTORE="$ROOT/android/upload-keystore.jks"
KEY_PROPS="$ROOT/android/key.properties"

if [[ ! -f "$KEYSTORE" || ! -f "$KEY_PROPS" ]]; then
  echo "Missing release signing files."
  echo "Run: ./scripts/generate_upload_keystore.sh"
  exit 1
fi

echo "==> Flutter clean (optional cache reset skipped)"
echo "==> Building release app bundle"
flutter pub get
flutter build appbundle --release

AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
MAPPING="$ROOT/build/app/outputs/mapping/release/mapping.txt"
if [[ -f "$AAB" ]]; then
  echo ""
  echo "Success. Upload this file to Google Play Console:"
  echo "  $AAB"
  ls -lh "$AAB"
  if [[ -f "$MAPPING" ]]; then
    echo ""
    echo "Upload this deobfuscation (mapping) file with the same release:"
    echo "  $MAPPING"
    echo "  Play Console → App bundle explorer → your version → Downloads → Upload mapping file"
  fi
else
  echo "Build finished but AAB not found at expected path."
  exit 1
fi
