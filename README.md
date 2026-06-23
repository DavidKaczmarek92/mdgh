# mdgh

`mdgh` is a CLI tool that creates GitHub issues from a structured Markdown file.

## Installation

```bash
chmod +x install.sh
./install.sh
```

## Uninstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Usage

```bash
mdgh TASKS.md --repo owner/repo --label-map labels.json
```

See `mdgh --help` for more options.

## Development & Testing

To run the test suite:

```bash
./tests/run-tests.sh
```

## Markdown Format

Each task starts with a level-3 heading: `### [TAG] Title`.

```markdown
### [UI] Add login button
**Files:** `src/components/Login.tsx`
**Depends on:** Backend API

Please add a login button that triggers the auth flow.

**Acceptance criteria:**
- [ ] Button is visible
- [ ] Clicking shows the modal
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
