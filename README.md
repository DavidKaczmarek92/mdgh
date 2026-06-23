# mdgh

`mdgh` is a collection of Bash scripts designed to convert a structured Markdown file into GitHub issues using the `gh` CLI. It's lightweight, has minimal dependencies, and works on macOS and Linux.

## Quick Start

If you just want to get started quickly, download the latest release and run the installer:

1. Go to the [Latest Release](https://github.com/DavidKaczmarek92/mdgh/releases/latest) page.
2. Download `md-to-issues.sh`, `install.sh`, `update.sh`, and `uninstall.sh`.
3. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## Dependencies

- **GitHub CLI (`gh`)**: Must be installed and authenticated (`gh auth login`).
- **Bash**: Versions 4+ are recommended.

## Installation

### Manual Download & Install

You can install `mdgh` by downloading the scripts from the repository and running the installation script.

```bash
# 1. Download scripts
curl -LO https://raw.githubusercontent.com/DavidKaczmarek92/mdgh/main/md-to-issues.sh
curl -LO https://raw.githubusercontent.com/DavidKaczmarek92/mdgh/main/install.sh
curl -LO https://raw.githubusercontent.com/DavidKaczmarek92/mdgh/main/update.sh
curl -LO https://raw.githubusercontent.com/DavidKaczmarek92/mdgh/main/uninstall.sh

# 2. Run the installer
chmod +x install.sh
./install.sh
```

The installer will copy the scripts to your PATH as:
- `mdgh`: The core tool.
- `mdgh-update`: Utility to update `mdgh` from the repository.
- `mdgh-uninstall`: Utility to remove `mdgh` from your system.

## Usage

Create GitHub issues from a Markdown file:

```bash
mdgh TASKS.md --repo owner/repo --label-map labels.json
```

### Options

- `MD_FILE`: The first argument is the path to your Markdown file.
- `--repo owner/repo`: Target GitHub repository. Optional if run inside a git repo.
- `--label-map labels.json`: Path to a JSON file mapping tags to GitHub labels.
- `--dry-run`: Preview what issues would be created without actually creating them.
- `--validate`: Check the Markdown file for formatting errors without creating issues.
- `--prefix-tag`: Prepend the tag to the issue title (e.g., `[UI] Title`).
- `--version`: Show the current version of `mdgh`.
- `-h, --help`: Show help message.

### Markdown Format

Tasks must start with a level-3 heading containing a tag:

```markdown
### [TAG] Task title here
**Files:** `path/to/file.tsx`
**Depends on:** Some other task title

Free text description here.

**Acceptance criteria:**
- [ ] First criterion
- [ ] Second criterion
```

## Updating & Uninstalling

To check for updates and install the latest version:
```bash
mdgh-update
```

To remove all `mdgh` scripts from your system:
```bash
mdgh-uninstall
```

## Maintainers

To publish a new release:
1. Update the `VERSION` file (e.g., `1.1.0`).
2. Sync the version to all scripts (search for `VERSION="X.Y.Z"`).
3. Run the release script:
   ```bash
   ./release.sh
   ```
This script will verify version consistency, create a git tag, push it to origin, and create a GitHub release with the scripts as assets.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
