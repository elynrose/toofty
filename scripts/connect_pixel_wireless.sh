#!/usr/bin/env bash
# Pair and connect to a Pixel over wireless debugging.
#
# On your Pixel:
#   Settings → Developer options → Wireless debugging → ON
#   Tap "Pair device with pairing code"
#
# Usage:
#   ./scripts/connect_pixel_wireless.sh 192.168.1.50:37123 123456
#   ./scripts/connect_pixel_wireless.sh 192.168.1.50:37123 123456 192.168.1.50:5555
set -euo pipefail

ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
PAIR_ADDR="${1:?Usage: $0 <pair-ip:port> <6-digit-code> [connect-ip:port]}"
PAIR_CODE="${2:?Missing pairing code}"
CONNECT_ADDR="${3:-}"

if [[ ! -x "$ADB" ]]; then
  echo "adb not found at $ADB"
  exit 1
fi

echo "==> Pairing with $PAIR_ADDR"
printf '%s\n' "$PAIR_CODE" | "$ADB" pair "$PAIR_ADDR"

if [[ -n "$CONNECT_ADDR" ]]; then
  echo "==> Connecting to $CONNECT_ADDR"
  "$ADB" connect "$CONNECT_ADDR"
else
  echo "==> Discovering connect endpoint via mDNS..."
  sleep 2
  "$ADB" mdns services || true
  echo ""
  echo "If no device appears, open Wireless debugging on your phone"
  echo "and note the IP address & port under the main screen (not pairing)."
  echo "Then run: $ADB connect <ip:port>"
fi

echo ""
"$ADB" devices -l
