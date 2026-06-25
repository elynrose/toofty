#!/usr/bin/env bash
# Build and prepare Toofty for App Store submission.
# Run from project root:
#   ./scripts/appstore_prepare.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "==> Toofty App Store preparation"
echo ""

# Check for Distribution cert (required for App Store upload)
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
  echo "⚠  No 'Apple Distribution' certificate found."
  echo "   You need the paid Apple Developer Program (\$99/year)."
  echo ""
  echo "   In Xcode: ios/Runner.xcworkspace → Runner target → Signing & Capabilities"
  echo "   • Select your Team (Briktap / Eliezer Ayertey)"
  echo "   • Check 'Automatically manage signing'"
  echo "   • For Archive: Product → Archive (uses Distribution profile)"
  echo ""
  echo "   Xcode will create Apple Distribution cert + App Store profile on first archive."
  echo ""
fi

echo "==> Building App Store IPA"
"$ROOT/scripts/build_ios.sh" --ipa

IPA=$(ls "$ROOT"/build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [[ -z "$IPA" ]]; then
  echo "IPA not found after build."
  exit 1
fi

echo ""
echo "==> IPA ready: $IPA"
ls -lh "$IPA"
echo ""
echo "==> App Store Connect checklist"
echo "  1. Create app: https://appstoreconnect.apple.com/apps"
echo "     • Name: Toofty"
echo "     • Bundle ID: com.briktap.toofty (register at developer.apple.com if needed)"
echo "     • SKU: toofty-ios (any unique string)"
echo ""
echo "  2. Upload build (Transporter or Xcode Organizer)"
echo "     • Drag $IPA into Transporter app"
echo "     • Or: open ios/Runner.xcworkspace → Product → Archive → Distribute App"
echo ""
echo "  3. App Information"
echo "     • Privacy Policy URL: https://todoos-briktap.web.app/delete-account.html"
echo "       (create a dedicated privacy page if Apple requires separate policy URL)"
echo "     • Account deletion URL: https://todoos-briktap.web.app/delete-account.html"
echo "     • Category: Health & Fitness or Lifestyle"
echo "     • Age Rating: complete questionnaire (likely 4+ with parental features)"
echo ""
echo "  4. Version 1.0.0 metadata"
echo "     • Screenshots: iPhone 6.7\", 6.5\", iPad 12.9\" (required for iPad app)"
echo "     • Description: see README App Store section"
echo "     • Keywords: brushing, kids, rewards, teeth, family"
echo ""
echo "  5. App Privacy (nutrition labels)"
echo "     • Collects: Email, User ID, Product Interaction"
echo "     • Linked to identity: Yes (Firebase Auth)"
echo "     • Used for: App functionality, account management"
echo ""
echo "  6. Submit for Review"

TRANSPORTER=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.TransporterApp'" 2>/dev/null | head -1)
if [[ -n "$TRANSPORTER" ]]; then
  echo ""
  read -r -p "Open Transporter to upload the IPA? [y/N] " open_tx
  if [[ "$open_tx" =~ ^[Yy]$ ]]; then
    open -a Transporter "$IPA"
  fi
fi

read -r -p "Open App Store Connect in browser? [y/N] " open_asc
if [[ "$open_asc" =~ ^[Yy]$ ]]; then
  open "https://appstoreconnect.apple.com/apps"
fi
