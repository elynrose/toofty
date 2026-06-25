#!/usr/bin/env bash
# Print release certificate fingerprints and open Firebase SHA registration.
# Google Sign-In requires SHA-1/SHA-256 for both upload and Play App Signing keys.
#
# Run from project root:
#   ./scripts/register_release_sha_firebase.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPS="$ANDROID_DIR/key.properties"
PROJECT_ID="${FIREBASE_PROJECT_ID:-todoos-briktap}"
PACKAGE="com.todoos.todoos"

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Keystore not found. Run: ./scripts/generate_upload_keystore.sh"
  exit 1
fi

if [[ -f "$KEY_PROPS" ]]; then
  storePassword="$(grep '^storePassword=' "$KEY_PROPS" | cut -d= -f2-)"
  keyAlias="$(grep '^keyAlias=' "$KEY_PROPS" | cut -d= -f2-)"
else
  echo "key.properties not found."
  exit 1
fi

echo "==> Upload keystore certificate fingerprints"
echo "    Add these in Firebase Console > Project settings > Your apps > Android"
echo "    Package: $PACKAGE"
echo ""

keytool -list -v \
  -keystore "$KEYSTORE" \
  -alias "${keyAlias:-upload}" \
  -storepass "${storePassword:?missing storePassword in key.properties}" 2>/dev/null | awk '
    /Alias name:/ { alias=$0; print alias }
    /SHA1:/ { print "  SHA-1:   " $2 }
    /SHA256:/ { print "  SHA-256: " $2 }
  '

echo ""
echo "Firebase Console (add both SHA-1 and SHA-256):"
echo "  https://console.firebase.google.com/project/${PROJECT_ID}/settings/general/android:${PACKAGE}"
echo ""
echo "After your first Play Store upload, also add the Play App Signing certificate"
echo "from Play Console > Release > Setup > App signing > App signing key certificate."
echo ""
echo "Then re-download google-services.json and replace:"
echo "  android/app/google-services.json"
echo ""

if command -v firebase >/dev/null 2>&1; then
  APP_ID="${FIREBASE_ANDROID_APP_ID:-1:550197968686:android:3b714c5c8cd8a26d7484bf}"
  SHA1="$(keytool -list -v -keystore "$KEYSTORE" -alias "${keyAlias:-upload}" -storepass "${storePassword}" 2>/dev/null | awk '/SHA1:/ {print $2; exit}')"
  SHA256="$(keytool -list -v -keystore "$KEYSTORE" -alias "${keyAlias:-upload}" -storepass "${storePassword}" 2>/dev/null | awk '/SHA256:/ {print $2; exit}')"

  if [[ -n "$SHA1" && -n "$SHA256" ]]; then
    echo "==> Registering SHA fingerprints via Firebase CLI (skips if already added)"
    firebase apps:android:sha:create "$APP_ID" "$SHA1" --project "$PROJECT_ID" 2>/dev/null || true
    firebase apps:android:sha:create "$APP_ID" "$SHA256" --project "$PROJECT_ID" 2>/dev/null || true
  fi
fi
