#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"
AUDIT_ROOT="$ROOT_DIR/.codex/security-audits"
STATE_DIR="$AUDIT_ROOT/state"

RUN_KEY="${RUN_KEY:-$(date -u +%Y-%m-%d-%H)}"
MONTH_KEY="${RUN_KEY:0:7}"
WEEK_KEY="${WEEK_KEY:-week-$(date -u +%V)}"
RUN_PATH="$AUDIT_ROOT/$MONTH_KEY/$WEEK_KEY/$RUN_KEY"

mkdir -p "$STATE_DIR" "$AUDIT_ROOT/audit-scratch"
mkdir -p "$AUDIT_ROOT/$MONTH_KEY/$WEEK_KEY/$RUN_KEY"

if [[ ! -f "$AUDIT_ROOT/$MONTH_KEY/README.md" ]]; then
  cat > "$AUDIT_ROOT/$MONTH_KEY/README.md" <<EOF
# $MONTH_KEY

This folder holds the audit runs for $MONTH_KEY.
EOF
fi

if [[ ! -f "$AUDIT_ROOT/$MONTH_KEY/$WEEK_KEY/README.md" ]]; then
  cat > "$AUDIT_ROOT/$MONTH_KEY/$WEEK_KEY/README.md" <<EOF
# $WEEK_KEY

This folder holds the audit runs for $WEEK_KEY.
EOF
fi

if [[ ! -f "$RUN_PATH/README.md" ]]; then
  cat > "$RUN_PATH/README.md" <<EOF
# $RUN_KEY Run

This folder holds one additive security audit chain for $RUN_KEY.
EOF
fi

for file in \
  "$AUDIT_ROOT/README.md" \
  "$AUDIT_ROOT/constraints.md" \
  "$AUDIT_ROOT/audit-rubric.md" \
  "$AUDIT_ROOT/audit-prompt.md" \
  "$STATE_DIR/README.md" \
  "$AUDIT_ROOT/$MONTH_KEY/README.md" \
  "$AUDIT_ROOT/$MONTH_KEY/$WEEK_KEY/README.md" \
  "$RUN_PATH/README.md"
do
  test -f "$file"
done

LOCK_FILE="$STATE_DIR/run.lock"
ACTIVE_FILE="$STATE_DIR/active-run.md"
LAST_FILE="$STATE_DIR/last-completed-run.md"

now_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
expires_ts="$(date -u -d '+12 minutes' +%Y-%m-%dT%H:%M:%SZ)"

cat > "$LOCK_FILE" <<EOF
run_key: $RUN_KEY
owner: security-audits-workflow
created_at: $now_ts
expires_at: $expires_ts
status: active
EOF

cat > "$ACTIVE_FILE" <<EOF
run_key: $RUN_KEY
month: $MONTH_KEY
week: $WEEK_KEY
run_path: $RUN_PATH
current_pass: 00-baseline
lock_ref: $LOCK_FILE
status: active
EOF

create_pass_file() {
  local target="$1"
  local title="$2"
  if [[ ! -f "$target" ]]; then
    cat > "$target" <<EOF
# $title

Pending audit content.
EOF
  fi
}

create_pass_file "$RUN_PATH/00-baseline.md" "Baseline"
create_pass_file "$RUN_PATH/02-expand.md" "Expansion"
create_pass_file "$RUN_PATH/04-delta.md" "Delta"
create_pass_file "$RUN_PATH/06-final.md" "Final"

cat > "$ACTIVE_FILE" <<EOF
run_key: $RUN_KEY
month: $MONTH_KEY
week: $WEEK_KEY
run_path: $RUN_PATH
current_pass: bootstrap
lock_ref: $LOCK_FILE
status: active
EOF

if [[ ! -f "$LAST_FILE" ]]; then
  cat > "$LAST_FILE" <<EOF
run_key: none
final_pass: none
final_path: none
completed_at: none
status: none
EOF
fi

echo "Security audit workspace bootstrapped for $RUN_KEY"
