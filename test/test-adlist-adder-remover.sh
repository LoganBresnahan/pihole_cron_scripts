#!/bin/sh
# Mock test harness for pihole-adlist-adder-remover.
#
# Builds a throwaway sqlite DB matching the columns the script touches,
# serves a fake firebog list via file://, runs the script against both,
# and asserts state across insert / rerun / disable / re-enable /
# injection-shaped URL / fetch-failure scenarios.
#
# Run: sh test/test-adlist-adder-remover.sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
SCRIPT_SRC="${REPO_DIR}/pihole-adlist-adder-remover"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

DB="${WORK_DIR}/gravity.db"
LIST_FILE="${WORK_DIR}/firebog.txt"
SCRIPT="${WORK_DIR}/script-under-test.sh"

# Minimal pihole v5 adlist schema (only columns the script touches).
sqlite3 "$DB" <<'SQL'
CREATE TABLE adlist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  address TEXT UNIQUE NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT 1,
  comment TEXT
);
INSERT INTO adlist (address, comment) VALUES ('https://manual.example/list', 'manually added');
INSERT INTO adlist (address, enabled, comment)
  VALUES ('https://stale.example/list', 1, 'placeholder');
SQL

# Build script copy with paths swapped for test.
sed \
  -e "s|/etc/pihole/gravity.db|${DB}|" \
  -e "s|https://v.firebog.net/hosts/lists.php?type=tick|file://${LIST_FILE}|" \
  "$SCRIPT_SRC" > "$SCRIPT"
chmod +x "$SCRIPT"

# Patch seeded stale row to use the rewritten ADLISTS_HOST so it counts as migrated.
sqlite3 "$DB" \
  "UPDATE adlist SET comment = 'Migrated from file://${LIST_FILE}' WHERE address = 'https://stale.example/list';"

dump_state() {
  echo "--- DB state: $1 ---"
  sqlite3 -header -column "$DB" "SELECT address, enabled, comment FROM adlist ORDER BY id;"
}

assert_row() {
  addr="$1"; want_enabled="$2"; label="$3"
  got=$(sqlite3 "$DB" "SELECT enabled FROM adlist WHERE address = '${addr}';")
  if [ "$got" = "$want_enabled" ]; then
    echo "PASS: ${label} (${addr} enabled=${got})"
  else
    echo "FAIL: ${label} (${addr} want=${want_enabled} got=${got:-MISSING})"
    exit 1
  fi
}

assert_count() {
  want="$1"; label="$2"
  got=$(sqlite3 "$DB" "SELECT COUNT(*) FROM adlist;")
  if [ "$got" = "$want" ]; then
    echo "PASS: ${label} (count=${got})"
  else
    echo "FAIL: ${label} (want=${want} got=${got})"
    exit 1
  fi
}

# -------- Scenario 1: fresh insert --------
cat > "$LIST_FILE" <<'EOF'
https://example.com/list-a.txt
https://example.com/list-b.txt
https://example.com/list-c.txt
EOF

echo
echo "=== Scenario 1: insert three new adlists ==="
"$SCRIPT"
dump_state "after scenario 1"
assert_count 5 "manual + stale + 3 inserted"
assert_row "https://example.com/list-a.txt" "1" "list-a inserted enabled"
assert_row "https://example.com/list-b.txt" "1" "list-b inserted enabled"
assert_row "https://example.com/list-c.txt" "1" "list-c inserted enabled"
assert_row "https://manual.example/list" "1" "manual entry untouched"
assert_row "https://stale.example/list" "0" "stale entry disabled"

# -------- Scenario 2: idempotent rerun --------
echo
echo "=== Scenario 2: rerun with same upstream list ==="
"$SCRIPT"
assert_count 5 "no duplicates inserted"
assert_row "https://example.com/list-a.txt" "1" "list-a still enabled"

# -------- Scenario 3: list-b removed upstream --------
cat > "$LIST_FILE" <<'EOF'
https://example.com/list-a.txt
https://example.com/list-c.txt
EOF

echo
echo "=== Scenario 3: list-b dropped upstream ==="
"$SCRIPT"
assert_row "https://example.com/list-b.txt" "0" "list-b disabled when missing"
assert_row "https://example.com/list-a.txt" "1" "list-a still enabled"
assert_row "https://example.com/list-c.txt" "1" "list-c still enabled"

# -------- Scenario 4: list-b returns --------
cat > "$LIST_FILE" <<'EOF'
https://example.com/list-a.txt
https://example.com/list-b.txt
https://example.com/list-c.txt
EOF

echo
echo "=== Scenario 4: list-b returns upstream ==="
"$SCRIPT"
assert_row "https://example.com/list-b.txt" "1" "list-b re-enabled"

# -------- Scenario 5: SQL-injection-shaped URL --------
cat > "$LIST_FILE" <<'EOF'
https://example.com/weird'); DROP TABLE adlist;--/x.txt
EOF

echo
echo "=== Scenario 5: malicious URL safely handled ==="
"$SCRIPT"
assert_count 6 "adlist table still present (no DROP), malicious row inserted as data"
weird_count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM adlist WHERE address LIKE '%DROP TABLE%';")
[ "$weird_count" = "1" ] && echo "PASS: malicious URL stored verbatim, not executed" || { echo "FAIL: malicious URL not stored"; exit 1; }

# -------- Scenario 6: upstream fetch fails --------
rm -f "$LIST_FILE"
echo
echo "=== Scenario 6: upstream unreachable ==="
if "$SCRIPT"; then
  echo "FAIL: script should exit non-zero when fetch fails"
  exit 1
else
  echo "PASS: script exited non-zero on fetch failure"
fi

echo
echo "All scenarios passed."
