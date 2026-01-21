#!/usr/bin/env bash
set -euo pipefail

# Normalize line endings and make script runnable in bash on Windows
# (removes stray CR characters that cause 'command not found' errors)
if command -v sed >/dev/null 2>&1; then
  sed -i 's/\r$//' "$0" >/dev/null 2>&1 || true
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Starting backends..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: 'docker' not found in PATH. Install Docker Desktop or run this script in an environment with Docker (e.g., WSL with Docker, or Git Bash with Docker in PATH)." >&2
  exit 127
fi

docker compose -f "$ROOT/docker-compose-deprecated.yml" up -d postgres backend
docker compose -f "$ROOT/docker-compose.yml" up -d backend_new

echo "Building deprecated Flutter web app..."
"$ROOT/Frontend_Deprecated/scripts/build_web.sh"

echo "Building new Flutter web app..."
"$ROOT/Frontend/scripts/build_web.sh"

echo "Starting frontends..."
docker compose -f "$ROOT/docker-compose-deprecated.yml" up -d frontend
docker compose -f "$ROOT/docker-compose.yml" up -d frontend_new

echo "All services started."
echo "Deprecated UI: http://localhost"
echo "New UI:        http://localhost:${FRONTEND_NEW_PORT:-8082}"
