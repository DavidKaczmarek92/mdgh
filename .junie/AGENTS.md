# Project Guidelines for mdgh

## Overview
`mdgh` is a collection of Bash scripts designed to convert a structured Markdown file into GitHub issues using the `gh` CLI.

## Key Scripts
- `md-to-issues.sh`: The core logic that parses Markdown and creates issues.
- `install.sh`: Installs `mdgh` to the user's PATH.
- `update.sh`: Updates the local installation from the GitHub repository.
- `uninstall.sh`: Removes the `mdgh` binary from the system.
- `tests/run-tests.sh`: Runs the automated test suite.

## Dependencies
- `gh` (GitHub CLI): Must be installed and authenticated (`gh auth login`).
- `bash`: The scripts are written for Bash and use standard GNU/macOS utilities like `grep`, `curl`, `wget`.

## Coding Standards
- Scripts should be POSIX-compliant where possible, but Bash 4+ features are acceptable as long as they work on macOS and common Linux distros.
- Use kebab-case for filenames.
- Always include `set -euo pipefail` at the top of scripts.

## Markdown Format
Tasks in the Markdown file must follow this structure:
```markdown
### [TAG] Title
Description and details here.
```
The script expects level-3 headings starting with a tag in brackets.

## CI/CD
- **GitHub Actions**: Automated tests run on every push to the `main` branch and on all pull requests.
- **Environments**: Tests are executed on both `ubuntu-latest` and `macos-latest` to ensure cross-platform compatibility.
- **Linting**: ShellCheck is used on Linux runners to ensure Bash best practices.

## Important TODOs
- **Update REPO_URL**: The `REPO_URL` in `update.sh` currently contains a placeholder `<your-username>`. This must be updated to the actual repository URL once the project is pushed to GitHub.

## Junie Specifics
- When reviewing or editing scripts, ensure that the `gh` CLI commands are correct and that the script handles edge cases like missing files or failed downloads.
- Prefer minimal changes and avoid adding heavy dependencies.
