#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Starting backends..."
docker compose -f "$ROOT/docker-compose.yml" up -d postgres backend
docker compose -f "$ROOT/docker-compose.new.yml" up -d backend_new

echo "Building deprecated Flutter web app..."
"$ROOT/Frontend_Deprecated/scripts/build_web.sh"

echo "Building new Flutter web app..."
"$ROOT/Frontend/scripts/build_web.sh"

echo "Starting frontends..."
docker compose -f "$ROOT/docker-compose.yml" up -d frontend
docker compose -f "$ROOT/docker-compose.new.yml" up -d frontend_new

echo "All services started."
echo "Deprecated UI: http://localhost"
echo "New UI:        http://localhost:${FRONTEND_NEW_PORT:-8082}"
