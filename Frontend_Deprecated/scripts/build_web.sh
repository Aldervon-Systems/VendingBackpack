#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

echo "Building Flutter web assets in $HERE"
flutter build web --release

if [ ! -f "$HERE/build/web/flutter_bootstrap.js" ]; then
  echo "ERROR: Flutter build did not produce flutter_bootstrap.js."
  echo "Make sure you are using a Flutter SDK that satisfies pubspec.yaml."
  exit 1
fi

echo "Flutter web build complete: $HERE/build/web"
