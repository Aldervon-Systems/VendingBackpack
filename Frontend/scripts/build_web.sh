#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUTPUT_DIR="$ROOT/deploy/frontend"

cd "$HERE"

if [ ! -d "$HERE/web" ]; then
  echo "Web platform not found. Running flutter create --platforms=web ."
  flutter create --platforms=web .
fi

echo "Building Flutter web assets in $HERE"
flutter build web --release

if [ ! -f "$HERE/build/web/flutter_bootstrap.js" ]; then
  echo "ERROR: Flutter build did not produce flutter_bootstrap.js."
  echo "Make sure you are using a Flutter SDK that satisfies pubspec.yaml."
  exit 1
fi

case "$OUTPUT_DIR" in
  */deploy/frontend) ;;
  *)
    echo "ERROR: refusing to overwrite unexpected output dir: $OUTPUT_DIR"
    exit 1
    ;;
esac

mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*
cp -R "$HERE/build/web/." "$OUTPUT_DIR"

echo "Copied web build to $OUTPUT_DIR"
