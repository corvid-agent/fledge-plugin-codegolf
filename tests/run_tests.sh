#!/usr/bin/env bash
# Test suite for fledge-plugin-codegolf
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEGOLF="$REPO_DIR/bin/codegolf"

export FLEDGE_PLUGIN_DIR="$REPO_DIR"

passed=0
failed=0
total=0

fail() {
    failed=$((failed + 1))
    total=$((total + 1))
    echo "  FAIL: $1"
}

pass() {
    passed=$((passed + 1))
    total=$((total + 1))
    echo "  PASS: $1"
}

# ── Test: help output ───────────────────────────────────────────────
echo "=== help output ==="
help_out=$("$CODEGOLF" help 2>&1)
if echo "$help_out" | grep -q "fledge golf"; then
    pass "help mentions 'fledge golf'"
else
    fail "help should mention 'fledge golf'"
fi
if echo "$help_out" | grep -q "submit"; then
    pass "help mentions submit command"
else
    fail "help should mention submit command"
fi

# ── Test: list output ───────────────────────────────────────────────
echo ""
echo "=== list command ==="
list_out=$("$CODEGOLF" list 2>&1)
for id in fizzbuzz reverse prime fibonacci caesar; do
    if echo "$list_out" | grep -qi "$id"; then
        pass "list includes $id"
    else
        fail "list should include $id"
    fi
done

# ── Test: challenge display ─────────────────────────────────────────
echo ""
echo "=== challenge display ==="
challenge_out=$("$CODEGOLF" challenge fizzbuzz 2>&1)
if echo "$challenge_out" | grep -q "FizzBuzz"; then
    pass "challenge fizzbuzz shows title"
else
    fail "challenge fizzbuzz should show title"
fi
if echo "$challenge_out" | grep -q "easy"; then
    pass "challenge fizzbuzz shows difficulty"
else
    fail "challenge fizzbuzz should show difficulty"
fi

# ── Test: unknown challenge ─────────────────────────────────────────
echo ""
echo "=== error handling ==="
err_out=$("$CODEGOLF" challenge nonexistent 2>&1 || true)
if echo "$err_out" | grep -qi "not found"; then
    pass "nonexistent challenge handled"
else
    fail "nonexistent challenge should say not found"
fi

# ── Test: unknown command ───────────────────────────────────────────
err_out=$("$CODEGOLF" badcommand 2>&1 || true)
if echo "$err_out" | grep -qi "unknown"; then
    pass "unknown command reports error"
else
    fail "unknown command should report error"
fi

# ── Test: verify with correct solution ──────────────────────────────
echo ""
echo "=== verify command ==="
tmpfile=$(mktemp /tmp/golf_test_XXXXXX.py)
cat > "$tmpfile" <<'PYEOF'
s=input()
print(s[::-1])
PYEOF
verify_out=$("$CODEGOLF" verify reverse "$tmpfile" 2>&1)
if echo "$verify_out" | grep -q "3/3 passed"; then
    pass "verify reverse with correct solution"
else
    fail "verify reverse should pass 3/3 ($verify_out)"
fi
rm -f "$tmpfile"

# ── Test: verify with wrong solution ────────────────────────────────
tmpfile=$(mktemp /tmp/golf_test_XXXXXX.py)
cat > "$tmpfile" <<'PYEOF'
print("wrong")
PYEOF
if "$CODEGOLF" verify reverse "$tmpfile" 2>&1; then
    fail "verify with wrong solution should fail"
else
    pass "verify rejects wrong solution"
fi
rm -f "$tmpfile"

# ── Test: verify missing file ──────────────────────────────────────
err_out=$("$CODEGOLF" verify fizzbuzz /tmp/nonexistent_file_xyz 2>&1 || true)
if echo "$err_out" | grep -qi "not found"; then
    pass "verify handles missing file"
else
    fail "verify should report missing file"
fi

# ── Test: leaderboard ──────────────────────────────────────────────
echo ""
echo "=== leaderboard ==="
if command -v jq &>/dev/null; then
    lb_out=$("$CODEGOLF" leaderboard 2>&1)
    if echo "$lb_out" | grep -qi "leaderboard"; then
        pass "leaderboard displays"
    else
        fail "leaderboard should display header"
    fi

    lb_fizz=$("$CODEGOLF" leaderboard fizzbuzz 2>&1)
    if echo "$lb_fizz" | grep -qi "fizzbuzz"; then
        pass "per-challenge leaderboard displays"
    else
        fail "per-challenge leaderboard should show challenge name"
    fi
else
    echo "  SKIP: jq not installed, skipping leaderboard tests"
fi

# ── Test: submit and score tracking ─────────────────────────────────
echo ""
echo "=== submit command ==="
if command -v jq &>/dev/null; then
    # Use a temp scores file to avoid mutating the repo
    backup_scores="$REPO_DIR/.scores.json.bak"
    cp "$REPO_DIR/.scores.json" "$backup_scores"

    tmpfile=$(mktemp /tmp/golf_test_XXXXXX.py)
    cat > "$tmpfile" <<'PYEOF'
s=input()
print(s[::-1])
PYEOF
    export FLEDGE_GOLF_PLAYER="test-runner"
    submit_out=$("$CODEGOLF" submit reverse "$tmpfile" 2>&1)
    if echo "$submit_out" | grep -q "Submitted"; then
        pass "submit accepts correct solution"
    else
        fail "submit should accept correct solution ($submit_out)"
    fi
    if echo "$submit_out" | grep -q "bytes"; then
        pass "submit reports byte count"
    else
        fail "submit should report byte count"
    fi
    unset FLEDGE_GOLF_PLAYER
    rm -f "$tmpfile"

    # Restore scores
    mv "$backup_scores" "$REPO_DIR/.scores.json"
else
    echo "  SKIP: jq not installed, skipping submit tests"
fi

# ── Test: plugin.toml validity ──────────────────────────────────────
echo ""
echo "=== plugin.toml ==="
if grep -q '^name = "codegolf"' "$REPO_DIR/plugin.toml"; then
    pass "plugin.toml has correct name"
else
    fail "plugin.toml should have name = codegolf"
fi
if grep -q 'binary = "bin/codegolf"' "$REPO_DIR/plugin.toml"; then
    pass "plugin.toml references bin/codegolf"
else
    fail "plugin.toml should reference bin/codegolf"
fi

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "=============================="
echo "Results: $passed/$total passed, $failed failed"
echo "=============================="

[[ $failed -eq 0 ]]
