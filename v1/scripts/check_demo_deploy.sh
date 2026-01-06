#!/usr/bin/env bash
set -euo pipefail

HOST=${1:-http://127.0.0.1:8000}
echo "Checking demo endpoints on $HOST"

curl -sS "$HOST/__demo_api/_db" | jq '{employees: .employees | length, routes: .routes | length}' || echo "failed to fetch _db"

curl -sS "$HOST/__demo_api/employee_routes" | jq '[.[] | {employee_id: .employee_id, stops: (.stops|length)}]' || echo "failed to fetch employee_routes"

echo "If you see 5 employees and 5 routes, the server is returning demo data." 
