#!/usr/bin/env bash
set -euo pipefail

# Build Flutter web assets and note where demo-mode.js is sourced from.
# Usage: ./Frontend_Deprecated/scripts/build_and_deploy_demo.sh [--upload user@host:/path/to/site]

HERE="$(cd "$(dirname "$0")/.." && pwd)"
echo "Working from $HERE"

echo "Running: ./scripts/build_web.sh"
cd "$HERE"
./scripts/build_web.sh

echo "Built web to $HERE/build/web"
echo "Reminder: ensure v1/web/demo-mode.js contains the desired demo-mode host detection (it will be copied into the build)."

if [ "$#" -gt 0 ]; then
  echo "Deploying build to: $1"
  rsync -av --delete "$HERE/build/web/" "$1"
  echo "Deployed. Remember to invalidate CDN caches if used."
fi

echo "Done. If clients are showing stale demo data, ask users to run `window.demoMode.clearDemoCache()` or visit /__demo_api/clear_demo_cache in their browser." 
