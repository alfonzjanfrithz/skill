# Install scripts

Simple install entrypoints for each supported tool:

- `install-cursor.sh`
- `install-claude.sh`
- `install-opencode.sh`
- `install-copilot.sh`
- `install-github-copilot.sh` (alias of `install-copilot.sh`)

Each script supports exactly one of these modes:

```bash
./scripts/install/install-cursor.sh --global
./scripts/install/install-cursor.sh --project-location /path/to/project
```

## Behavior

- `--global` installs into the tool's global folder.
- `--project-location <path>` installs into a project-local folder.
- Missing folders are created automatically.
- Re-running a script replaces each installed skill folder with the current version from `dotskill/`.

## Default destinations

| Tool | Global | Project-local |
| --- | --- | --- |
| Cursor | `~/.cursor/rules` | `.cursor/rules` |
| Claude | `~/.claude/skills` | `.claude/skills` |
| OpenCode | `~/.config/opencode/skills` | `.opencode/skills` |
| GitHub Copilot | `~/.config/github-copilot/skills` | `.github/copilot/skills` |

## Optional overrides

If you want different destinations, set environment variables before running a script:

- Cursor: `CURSOR_GLOBAL_DIR`, `CURSOR_PROJECT_SUBDIR`
- Claude: `CLAUDE_GLOBAL_DIR`, `CLAUDE_PROJECT_SUBDIR`
- OpenCode: `OPENCODE_GLOBAL_DIR`, `OPENCODE_PROJECT_SUBDIR`
- Copilot: `COPILOT_GLOBAL_DIR`, `COPILOT_PROJECT_SUBDIR`

