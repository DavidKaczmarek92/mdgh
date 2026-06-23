#!/usr/bin/env bash
#
# tests/run-tests.sh — Test suite for mdgh.
#
set -euo pipefail

SCRIPT="./md-to-issues.sh"
SAMPLES="tests/samples"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

passed=0
failed=0

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}✓${NC} $message"
    passed=$((passed + 1))
  else
    echo -e "  ${RED}✗${NC} $message"
    echo "    Expected to find: $needle"
    failed=$((failed + 1))
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}✓${NC} $message"
    passed=$((passed + 1))
  else
    echo -e "  ${RED}✗${NC} $message"
    echo "    Expected NOT to find: $needle"
    failed=$((failed + 1))
  fi
}

echo "→ Running tests for $SCRIPT..."

# Test 1: Help message
echo "Test 1: Help message"
output=$($SCRIPT --help)
assert_contains "$output" "USAGE" "Help message contains USAGE"
assert_contains "$output" "EXPECTED MARKDOWN FORMAT" "Help message contains format info"

# Test 2: Dry run - Basic parsing
echo "Test 2: Basic parsing (Dry Run)"
output=$($SCRIPT "$SAMPLES/valid-tasks.md" --dry-run)
assert_contains "$output" "Found 3 task(s)" "Found correct number of tasks"
assert_contains "$output" "title: Add login button" "Task 1 title parsed"
assert_contains "$output" "title: Setup database schema" "Task 2 title parsed"
assert_contains "$output" "title: Write documentation" "Task 3 title parsed"
assert_contains "$output" "**Files:** \`src/components/Login.tsx\`" "Metadata 'Files' parsed"
assert_contains "$output" "**Depends on:** Backend API" "Metadata 'Depends on' parsed"
assert_contains "$output" "label: ui" "Default label (lowercased tag) works"

# Test 3: Label mapping
echo "Test 3: Label mapping"
output=$($SCRIPT "$SAMPLES/valid-tasks.md" --dry-run --label-map "$SAMPLES/label-map.json")
assert_contains "$output" "label: frontend" "Label UI mapped to frontend"
assert_contains "$output" "label: backend" "Label DATA mapped to backend"
assert_contains "$output" "label: (none)" "Tag DOC (not in map) has no label"

# Test 4: Prefix tag
echo "Test 4: Prefix tag flag"
output=$($SCRIPT "$SAMPLES/valid-tasks.md" --dry-run --prefix-tag)
assert_contains "$output" "title: [UI] Add login button" "Title prefixed with tag"

# Test 5: Code block handling
echo "Test 5: Code block handling"
output=$($SCRIPT "$SAMPLES/valid-tasks.md" --dry-run)
assert_contains "$output" 'CREATE TABLE users' "Code block content preserved"

# Test 6: Error handling - Missing file
echo "Test 6: Error handling (Missing file)"
if $SCRIPT "non-existent.md" 2>&1 | grep -q "File not found" || [ $? -eq 1 ]; then
  # We expect the script to fail, so we check if it printed the right error
  # and that grep found it. The || [ $? -eq 1 ] is because grep -q 
  # returns 0 on match.
  # Actually, let's just do it simpler:
  err_output=$($SCRIPT "non-existent.md" 2>&1 || true)
  if echo "$err_output" | grep -q "File not found"; then
    echo -e "  ${GREEN}✓${NC} Handles missing file correctly"
    passed=$((passed + 1))
  else
    echo -e "  ${RED}✗${NC} Fails to handle missing file"
    failed=$((failed + 1))
  fi
else
  echo -e "  ${RED}✗${NC} Unexpected failure in test logic"
  failed=$((failed + 1))
fi

echo ""
echo "------------------------------------------------"
echo -e "Tests completed: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
echo "------------------------------------------------"

if [ $failed -gt 0 ]; then
  exit 1
fi
