#!/usr/bin/env bash
# Generate an Android upload keystore for Play Store release builds.
# Run from project root:
#   ./scripts/generate_upload_keystore.sh
#
# Back up android/upload-keystore.jks and the passwords printed below.
# If you lose the upload key, you cannot publish updates to the same app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPS="$ANDROID_DIR/key.properties"
ALIAS="${KEY_ALIAS:-upload}"
VALIDITY_DAYS="${KEY_VALIDITY_DAYS:-10000}"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists: $KEYSTORE"
  echo "Delete it first if you need a new one."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a JDK (e.g. brew install openjdk@17)."
  exit 1
fi

STORE_PASS="${STORE_PASSWORD:-$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)}"
KEY_PASS="${KEY_PASSWORD:-$STORE_PASS}"

ORG="${KEY_ORG:-Briktap Inc}"
CN="${KEY_CN:-Toofty}"

echo "==> Generating upload keystore"
keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY_DAYS" \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=$CN, OU=Mobile, O=$ORG, L=NA, ST=NA, C=US"

cat > "$KEY_PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=../upload-keystore.jks
EOF

chmod 600 "$KEY_PROPS" "$KEYSTORE"

echo ""
echo "Created:"
echo "  Keystore:     $KEYSTORE"
echo "  Properties:   $KEY_PROPS"
echo ""
echo "SAVE THESE PASSWORDS OFFLINE (password manager or secure vault):"
echo "  storePassword: $STORE_PASS"
echo "  keyPassword:   $KEY_PASS"
echo "  keyAlias:      $ALIAS"
echo ""
echo "Next:"
echo "  1. Back up upload-keystore.jks to a secure location"
echo "  2. ./scripts/register_release_sha_firebase.sh"
echo "  3. ./scripts/build_playstore_aab.sh"
