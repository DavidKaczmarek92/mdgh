#!/usr/bin/env bash
#
# md-to-issues.sh — Create GitHub issues from a structured Markdown task file.
#
# Works on ANY repo. Point it at a markdown file following the expected
# format (see below) and an optional label map, and it creates one
# GitHub issue per task section using the gh CLI.
#
# ──────────────────────────────────────────────────────────────────
# EXPECTED MARKDOWN FORMAT
# ──────────────────────────────────────────────────────────────────
#
#   ### [TAG] Task title here
#   **Agent:** anything, ignored
#   **Files:** `path/to/file.tsx`
#   **Depends on:** Some other task title, or "nothing"
#
#   Free text description (optional, can span multiple lines).
#
#   **Acceptance criteria:**
#   - [ ] First criterion
#   - [ ] Second criterion
#
#   ---
#
#   ### [TAG] Another task
#   ...
#
# Rules the parser relies on:
#   - Each task starts with a level-3 heading: "### [TAG] Title"
#   - Any other markdown heading (# ## ###...) ends the current task body
#     — so trailing sections like "## Dependency map" are never swallowed
#   - Fenced code blocks (```) are tracked so "---" or "#" inside one
#     (e.g. an ascii diagram) doesn't get misread as a task boundary
#   - Everything else in the body is copied verbatim into the issue
#
# ──────────────────────────────────────────────────────────────────
# USAGE
# ──────────────────────────────────────────────────────────────────
#
#   chmod +x md-to-issues.sh
#
#   # Dry run first (recommended) — prints what would be created
#   ./md-to-issues.sh TASKS.md --dry-run
#
#   # Validation
#   ./md-to-issues.sh TASKS.md --validate
#
#   # For real
#   ./md-to-issues.sh TASKS.md --repo owner/repo
#
#   # Run from inside the target repo — --repo can be omitted
#   cd ~/code/devlog && /path/to/md-to-issues.sh TASKS.md
#
# Multiple labels can be specified in the brackets, separated by commas:
#   ### [UI, FE] Task title
#
# The tag is used directly as the label, preserving case (e.g. [UI] -> "UI").
#
# Requires: gh CLI installed and authenticated (gh auth login).
#
set -euo pipefail

VERSION="1.0.0"

# ─────────────────────────────────────────────────────────────
# Arg parsing
# ─────────────────────────────────────────────────────────────

validate_tasks() {
  local file="$1"
  local errors=0
  local line_num=0
  local in_code=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    trimmed="${line#"${line%%[![:space:]]*}"}"

    # Track fenced code blocks.
    if [[ "$trimmed" == '```'* ]]; then
      if $in_code; then in_code=false; else in_code=true; fi
      continue
    fi
    $in_code && continue

    # 1. Catch headings with tags that are NOT level 3
    if [[ "$line" =~ ^(#|##|####+)[[:space:]]+\[.*\].*$ ]]; then
      echo "Line $line_num: ✗ Wrong heading level. Tasks must be Level 3 (###)." >&2
      errors=$((errors + 1))
    fi

    # 2. Check Level 3 headings
    if [[ "$line" =~ ^###[[:space:]]+(.*)$ ]]; then
      local content="${BASH_REMATCH[1]}"
      
      # If it has a tag, check its format
      if [[ "$content" =~ ^\[(.*)\] ]]; then
        local tag="${BASH_REMATCH[1]}"
        local tag_re='^[A-Za-z0-9_, -]+$'
        if [[ -z "$tag" ]]; then
          echo "Line $line_num: ✗ Empty tag in Level 3 heading." >&2
          errors=$((errors + 1))
        elif [[ ! "$tag" =~ $tag_re ]]; then
          echo "Line $line_num: ✗ Invalid characters in tag: [$tag]. Use only A-Z, 0-9, _, -, comma, and space." >&2
          errors=$((errors + 1))
        fi
      else
        # No tag at all
        echo "Line $line_num: ✗ Missing tag in Level 3 heading (expected '### [TAG] Title')." >&2
        errors=$((errors + 1))
      fi
    fi
  done < "$file"

  if [[ $errors -gt 0 ]]; then
    echo "Validation failed: Found $errors error(s)." >&2
    return 1
  fi
  echo "✓ Validation passed!"
  return 0
}

MD_FILE=""
REPO=""
DRY_RUN=false
VALIDATE_ONLY=false
PREFIX_TAG=false

usage() {
  grep '^#' "$0" | sed -e 's/^#//' -e 's/^! //'
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  --version)
    echo "mdgh v$VERSION"
    exit 0
    ;;
esac

MD_FILE="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --validate)
      VALIDATE_ONLY=true
      shift
      ;;
    --prefix-tag)
      PREFIX_TAG=true
      shift
      ;;
    --version)
      echo "mdgh v$VERSION"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "✗ Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$MD_FILE" ]]; then
  echo "✗ File not found: $MD_FILE"
  exit 1
fi

if ! $DRY_RUN && ! $VALIDATE_ONLY && ! command -v gh >/dev/null 2>&1; then
  echo "✗ gh CLI not found. Install it first: https://cli.github.com"
  exit 1
fi

if $VALIDATE_ONLY; then
  validate_tasks "$MD_FILE"
  exit $?
fi

REPO_FLAG=()
if [[ -n "$REPO" ]]; then
  REPO_FLAG=(--repo "$REPO")
fi

# ─────────────────────────────────────────────────────────────
# Label resolution
#
# Returns the tag as-is, preserving case.
# ─────────────────────────────────────────────────────────────

resolve_label() {
  echo "$1"
}

# ─────────────────────────────────────────────────────────────
# Markdown parser
#
# Reads the file line by line, tracking:
#   - whether we're inside a fenced code block (``` ... ```)
#   - the current task being accumulated
# Emits one task per call to flush_task, as TSV-ish records written
# to temp files (one file per task) to avoid shell quoting headaches
# with multi-line bodies.
# ─────────────────────────────────────────────────────────────

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

task_index=0
in_code_block=false
current_tag=""
current_title=""
current_files=""
current_depends=""
body_file=""
have_task=false

flush_task() {
  if $have_task; then
    task_index=$((task_index + 1))
    {
      echo "TAG:${current_tag}"
      echo "TITLE:${current_title}"
      echo "FILES:${current_files}"
      echo "DEPENDS:${current_depends}"
      echo "---BODY---"
      cat "$body_file"
    } > "${WORKDIR}/task_${task_index}.txt"
  fi
  have_task=false
  current_tag=""
  current_title=""
  current_files=""
  current_depends=""
}

while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"  # ltrim

  # Track fenced code blocks first.
  if [[ "$trimmed" == '```'* ]]; then
    if $in_code_block; then
      in_code_block=false
    else
      in_code_block=true
    fi
    if $have_task; then
      echo "$line" >> "$body_file"
    fi
    continue
  fi

  if $in_code_block; then
    if $have_task; then
      echo "$line" >> "$body_file"
    fi
    continue
  fi

  # New task heading: "### [TAG] Title"
  task_re='^###[[:space:]]+\[([A-Za-z0-9_, -]+)\][[:space:]]+(.+)$'
  if [[ "$line" =~ $task_re ]]; then
    flush_task
    current_tag="${BASH_REMATCH[1]}"
    current_title="${BASH_REMATCH[2]%% }"
    current_title="${current_title%"${current_title##*[![:space:]]}"}"  # rtrim
    body_file="${WORKDIR}/body_pending.txt"
    : > "$body_file"
    have_task=true
    continue
  fi

  # Any other markdown heading ends the current task's body.
  if [[ "$trimmed" == '#'* ]]; then
    flush_task
    continue
  fi

  if ! $have_task; then
    continue
  fi

  # Metadata lines.
  if [[ "$line" =~ ^\*\*Files:\*\*[[:space:]]*(.*)$ ]]; then
    current_files="${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^\*\*Depends\ on:\*\*[[:space:]]*(.*)$ ]]; then
    current_depends="${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^\*\*Agent:\*\*[[:space:]]*(.*)$ ]]; then
    # Parsed but currently unused — kept for future use (e.g. assignee mapping).
    continue
  fi

  # A bare "---" is a section/task divider, not body content.
  if [[ "$trimmed" == "---" ]]; then
    continue
  fi

  echo "$line" >> "$body_file"
done < "$MD_FILE"

flush_task

if [[ "$task_index" -eq 0 ]]; then
  echo "No tasks found. Check that your file uses '### [TAG] Title' headings."
  exit 1
fi

echo "Found ${task_index} task(s) in $(basename "$MD_FILE")"
if $DRY_RUN; then
  echo "Running in DRY RUN mode — no issues will be created."
fi
echo ""

# ─────────────────────────────────────────────────────────────
# Create issues
# ─────────────────────────────────────────────────────────────

for i in $(seq 1 "$task_index"); do
  task_file="${WORKDIR}/task_${i}.txt"

  tag=$(sed -n '1p' "$task_file" | sed 's/^TAG://')
  title=$(sed -n '2p' "$task_file" | sed 's/^TITLE://')
  files=$(sed -n '3p' "$task_file" | sed 's/^FILES://')
  depends=$(sed -n '4p' "$task_file" | sed 's/^DEPENDS://')
  body_raw=$(sed -n '/^---BODY---$/,$p' "$task_file" | tail -n +2)

  if $PREFIX_TAG; then
    title="[${tag}] ${title}"
  fi

  # Assemble final body: Files / Depends on (if present) + blank line + free text.
  body=""
  if [[ -n "$files" ]]; then
    body+="**Files:** ${files}"$'\n'
  fi
  if [[ -n "$depends" ]]; then
    body+="**Depends on:** ${depends}"$'\n'
  fi
  if [[ -n "$body" ]]; then
    body+=$'\n'
  fi
  body+="$body_raw"
  # Trim trailing whitespace/newlines and collapse the blank line that
  # can appear right after metadata into a single separator.
  body=$(printf '%s' "$body" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
  body=$(printf '%s' "$body" | awk 'BEGIN{blank=0} /^$/{blank++; if(blank>1) next} !/^$/{blank=0} {print}')

  label=$(resolve_label "$tag")

  if $DRY_RUN; then
    echo "────────────────────────────────────────────────────────"
    echo "[DRY RUN] would create issue:"
    echo "  title: $title"
    echo "  labels: ${label:-(none)}"
    echo "  body:"
    printf '    %s\n' "${body//$'\n'/$'\n'    }"
  else
    label_args=()
    if [[ -n "$label" ]]; then
      # Split by comma and trim each label
      IFS=',' read -ra ADDR <<< "$label"
      for l in "${ADDR[@]}"; do
        # trim whitespace
        l="${l#"${l%%[![:space:]]*}"}"
        l="${l%"${l##*[![:space:]]}"}"
        if [[ -n "$l" ]]; then
          label_args+=(--label "$l")
        fi
      done
    fi

    if output=$(gh issue create --title "$title" --body "$body" "${label_args[@]}" "${REPO_FLAG[@]}" 2>&1); then
      echo "✓ Created: $title  →  $output"
    else
      echo "✗ Failed: $title"
      echo "  $output"
    fi
  fi
done

echo ""
if $DRY_RUN; then
  echo "Dry run complete. Re-run without --dry-run to actually create these ${task_index} issues."
else
  echo "Done. Processed ${task_index} task(s)."
fi