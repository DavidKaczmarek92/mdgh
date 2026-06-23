---
name: mdgh-review
description: Guidelines for reviewing mdgh scripts (bash, gh CLI, markdown parsing)
---

# mdgh-review Skill

Use this skill when reviewing changes to the `mdgh` project or when asked to conduct a general code review of the repository.

## Review Principles

1. **Bash Best Practices**:
   - Ensure `set -euo pipefail` is used.
   - Check for proper quoting of variables (e.g., `"$VAR"` instead of `$VAR`).
   - Verify error handling (checking exit codes, using `trap` for cleanup).
   - Prefer `[[ ... ]]` over `[ ... ]`.

2. **GitHub CLI (`gh`) Usage**:
   - Verify that `gh issue create` commands use the correct flags.
   - Ensure labels and repositories are handled correctly.

3. **Portability**:
   - The scripts should run on both Linux and macOS. Avoid GNU-specific flags in `grep`, `sed`, etc., unless alternatives are provided.

4. **Markdown Parsing Logic**:
   - The core logic in `md-to-issues.sh` relies on `sed` and `grep` to parse headings. Ensure changes don't break the regex that identifies tasks.

## Checklist

- [ ] Does the script handle missing dependencies?
- [ ] Are temporary files cleaned up properly?
- [ ] Is the help message (`--help`) up to date?
- [ ] Does the `update.sh` script handle failed downloads gracefully?
- [ ] Is the `REPO_URL` placeholder mentioned if it hasn't been updated?
- [ ] Have the tests been run and do they pass (`./tests/run-tests.sh`)?
