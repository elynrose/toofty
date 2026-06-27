#!/usr/bin/env bash
# Deploy Toofty marketing site to Firebase Hosting.
#   chmod +x scripts/deploy_hosting.sh && ./scripts/deploy_hosting.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "Install Firebase CLI: npm install -g firebase-tools"
  exit 1
fi

echo "==> Deploying hosting/ to Firebase (todoos-briktap)"
firebase deploy --only hosting --project todoos-briktap

echo ""
echo "Live URLs:"
echo "  Home:      https://todoos-briktap.web.app/"
echo "  Support:   https://todoos-briktap.web.app/support.html"
echo "  Privacy:   https://todoos-briktap.web.app/privacy.html"
echo "  Copyright: https://todoos-briktap.web.app/copyright.html"
