#!/usr/bin/env bash
set -euo pipefail

base=${1:-http://localhost}

echo "Checking demo server at $base"
echo "GET /__demo_api/_db"
curl -fsS "$base/__demo_api/_db" | jq '.'

echo "GET /__demo_api/inventory"
curl -fsS "$base/__demo_api/inventory" | jq '.'

echo "POST /__demo_api/inventory/fill (add)"
curl -fsS -X POST "$base/__demo_api/inventory/fill" -H 'Content-Type: application/json' -d '{"id":999,"sku":"TEST","name":"Test Item","add":3}' | jq '.'

echo "GET /__demo_api/inventory (after add)"
curl -fsS "$base/__demo_api/inventory" | jq '. | map(select(.id==999))'

echo "All checks passed"
