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
assert_contains "$output" "labels: UI" "Labels (case-preserved tag) works"

# Test 3: Multiple labels
echo "Test 3: Multiple labels"
output=$($SCRIPT "$SAMPLES/multiple-labels.md" --dry-run)
assert_contains "$output" "labels: UI, FE" "Multiple labels parsed correctly"

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
err_output=$($SCRIPT "non-existent.md" 2>&1 || true)
if echo "$err_output" | grep -q "File not found"; then
  echo -e "  ${GREEN}✓${NC} Handles missing file correctly"
  passed=$((passed + 1))
else
  echo -e "  ${RED}✗${NC} Fails to handle missing file"
  failed=$((failed + 1))
fi

# Test 7: Validation - Valid file
echo "Test 7: Validation (Valid file)"
if output=$($SCRIPT "$SAMPLES/valid-tasks.md" --validate 2>&1); then
  echo -e "  ${GREEN}✓${NC} Validation passes for valid file"
  passed=$((passed + 1))
else
  echo -e "  ${RED}✗${NC} Validation failed for valid file"
  echo "$output"
  failed=$((failed + 1))
fi

# Test 8: Validation - Invalid file
echo "Test 8: Validation (Invalid file)"
if output=$($SCRIPT "$SAMPLES/invalid-tasks.md" --validate 2>&1); then
  echo -e "  ${RED}✗${NC} Validation unexpectedly passed for invalid file"
  failed=$((failed + 1))
else
  echo -e "  ${GREEN}✓${NC} Validation correctly failed for invalid file"
  assert_contains "$output" "Line 5: ✗ Wrong heading level" "Detected Level 2 heading"
  assert_contains "$output" "Line 8: ✗ Missing tag" "Detected missing tag"
  assert_contains "$output" "Line 11: ✗ Empty tag" "Detected empty tag"
  assert_contains "$output" "Line 14: ✗ Invalid characters in tag" "Detected invalid tag characters"
  assert_contains "$output" "Line 17: ✗ Wrong heading level" "Detected Level 4 heading"
  assert_contains "$output" "Line 23: ✗ Wrong heading level" "Detected another Level 2 heading"
  assert_contains "$output" "Validation failed: Found 6 error(s)" "Reported correct number of errors"
  passed=$((passed + 1))
fi

echo ""
echo "------------------------------------------------"
echo -e "Tests completed: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"
echo "------------------------------------------------"

if [ $failed -gt 0 ]; then
  exit 1
fi
