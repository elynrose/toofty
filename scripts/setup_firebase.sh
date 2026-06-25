#!/usr/bin/env bash
# Interactive Firebase setup for todoos — run from project root:
#   chmod +x scripts/setup_firebase.sh && ./scripts/setup_firebase.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-todoos-briktap}"
DISPLAY_NAME="${FIREBASE_DISPLAY_NAME:-todoos}"

echo "==> todoos Firebase setup"
echo "    Project ID:   $PROJECT_ID"
echo "    Display name: $DISPLAY_NAME"
echo ""

if ! command -v firebase >/dev/null 2>&1; then
  echo "Installing Firebase CLI..."
  npm install -g firebase-tools
fi

if ! firebase login:list 2>/dev/null | grep -q '@'; then
  echo "==> Sign in to Firebase (browser will open)"
  firebase login
fi

echo "==> Creating Firebase project (skips if it already exists)"
if firebase projects:list --json 2>/dev/null | grep -q "\"projectId\": \"$PROJECT_ID\""; then
  echo "    Project $PROJECT_ID already exists."
else
  firebase projects:create "$PROJECT_ID" --display-name "$DISPLAY_NAME"
fi

echo "==> Linking this directory to Firebase"
cat > .firebaserc <<EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

if [[ ! -f firebase.json ]]; then
  cat > firebase.json <<'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
EOF
fi

echo "==> Enabling Authentication"
echo "    Open Firebase Console and enable these sign-in providers:"
echo "    • Email/Password"
echo "    • Google"
echo "    https://console.firebase.google.com/project/${PROJECT_ID}/authentication/providers"
echo ""

if ! command -v flutterfire >/dev/null 2>&1; then
  echo "==> Installing FlutterFire CLI"
  dart pub global activate flutterfire_cli
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi

echo "==> Configuring Flutter app (android, ios, web)"
flutterfire configure \
  --project="$PROJECT_ID" \
  --platforms=android,ios,web \
  --android-package-name=com.todoos.todoos \
  --ios-bundle-id=com.briktap.toofty \
  --yes

echo ""
echo "==> Fetching dependencies"
flutter pub get

echo ""
echo "Done! Firebase project: $PROJECT_ID"
echo "Run the app: flutter run"
