#!/usr/bin/env bash
# One-shot Play Store prep: keystore (if needed), SHA hints, release AAB.
# Run from project root:
#   ./scripts/playstore_prepare.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Toofty Play Store preparation"
echo ""

if [[ ! -f "$ROOT/android/upload-keystore.jks" ]]; then
  "$ROOT/scripts/generate_upload_keystore.sh"
else
  echo "Upload keystore already present."
fi

echo ""
"$ROOT/scripts/register_release_sha_firebase.sh"

echo ""
read -r -p "Have you added the SHA fingerprints in Firebase and updated google-services.json? [y/N] " answered
if [[ ! "$answered" =~ ^[Yy]$ ]]; then
  echo "Complete Firebase SHA registration, then run:"
  echo "  ./scripts/build_playstore_aab.sh"
  exit 0
fi

echo ""
"$ROOT/scripts/build_playstore_aab.sh"

echo ""
echo "==> Play Console checklist"
echo "  • Create app: https://play.google.com/console"
echo "  • Upload: build/app/outputs/bundle/release/app-release.aab"
echo "  • Store listing: name, short/full description, screenshots, feature graphic"
echo "  • Privacy policy URL (required — app uses Firebase Auth + Firestore)"
echo "  • Data safety form: email, account info, app activity"
echo "  • Content rating questionnaire"
echo "  • Target audience / Families policy if for children"
echo "  • After first upload: add Play App Signing SHA to Firebase (see register_release_sha_firebase.sh)"
