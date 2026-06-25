#!/bin/sh
# Ensures Xcode SDK tools are available to Flutter native asset hooks during builds.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export PATH="${SRCROOT}:${PATH}:/usr/bin:/bin:/usr/sbin:/sbin"

exec /bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"
