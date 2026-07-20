# Ralph — autonomous task loop

`run.sh` drives a CLI agent through Ralph's prompt loop for a single ticket.
It assembles a prompt from `issues/<ticket-id>/*.md`, recent commits, and the
workflow files in this directory, then pipes it into the agent in
non-interactive mode. The loop continues until the agent emits
`<promise>NO MORE TASKS</promise>` or you pass `--once`.

## Prerequisites

1. **Install a supported agent CLI**
   - Cursor: [`cursor-agent`](https://cursor.com/cli) (default)
   - OpenCode: [`opencode`](https://opencode.ai)

2. **Install the shared skills for that agent**
   ```bash
   ./scripts/install/install-cursor.sh --global
   # or
   ./scripts/install/install-opencode.sh --global
   ```
   See `scripts/install/README.md` for project-local installs and selectors.

3. **Seed `issues/<ticket-id>/`**
   Use the `breakdown` skill (or write them by hand) so `issues/<ticket-id>/`
   contains the tracer-bullet tasks you want Ralph to work through.
   Expected format: `issues/<ticket-id>/NNN-short-title.md`.

4. **Be on a feature branch** in the target repo. `run.sh` refuses to run on `main` or `master`.

> **Tip:** You can keep the skill repo and Ralph in one place (e.g. `~/IdeaProjects/skill`) and use `--repo-root` to drive work in any other git worktree without copying files.

## Usage

```bash
# Required: specify the ticket directory under issues/
./scripts/ralph/run.sh --ticket-id PROJ-12312
./scripts/ralph/run.sh --ticket-id PROJ-12312 --agent opencode
./scripts/ralph/run.sh --ticket-id PROJ-12312 --once
./scripts/ralph/run.sh --ticket-id PROJ-12312 --echo
./scripts/ralph/run.sh --help

# Target a different repo (e.g. a git worktree)
./scripts/ralph/run.sh --repo-root ~/Codebase/provisioning-service --ticket-id PROJ-12312 --agent opencode
```

### Flags

| Flag | Effect |
| --- | --- |
| `--ticket-id <id>` | **Required.** The ticket directory under `issues/` to work on. |
| `--repo-root <path>` | Path to the target git repository. Defaults to the skill repo itself. |
| `--agent cursor\|opencode` | Pick which CLI to drive. Default: `cursor`. |
| `--once` | Run a single iteration and exit. Good for testing prompt changes. |
| `--echo` | Print the assembled prompt to stdout and exit. No agent invoked, no branch check, no ticket validation. Useful for debugging prompts. |
| `-h`, `--help` | Show inline help. |

## How it works

Each iteration:

1. Assembles the prompt from:
   - last 5 git commits
   - all `issues/<ticket-id>/*.md` (skips `done/` subdirectory)
   - `prompt.md`, `feedback-loops.md`, `git-commit.md` in this directory
2. Invokes the chosen agent in non-interactive auto-apply mode:
   - Cursor: `cursor-agent -p --force "$PROMPT"`
   - OpenCode: `opencode run "$PROMPT"`
3. Tees agent output to `scripts/ralph/logs/<timestamp>-iter-<N>.log`.
4. If the log contains `<promise>NO MORE TASKS</promise>`, the loop exits.
5. Otherwise the next iteration starts immediately (or stops if `--once`).

Stop the loop at any time with **Ctrl-C**.

## Logs

Per-iteration output is written to `scripts/ralph/logs/`. The directory is
created on first run and is covered by the repo's `*.log` gitignore rule.

## Caveat: `/tdd` in cursor-agent

The `/tdd` slash-command routing that works in the Cursor IDE chat is **not
guaranteed** in `cursor-agent`'s headless mode. To stay portable, `prompt.md`
references the TDD skill by path (`dotskill/workflow/tdd/SKILL.md`) so the
agent reads it explicitly regardless of slash-command support. OpenCode loads
skills from `~/.config/opencode/skills` automatically and honours `/tdd`.

## Customizing the loop

- Edit `prompt.md` to change task selection, exploration rules, or completion
  criteria.
- Edit `feedback-loops.md` for the build/test/lint commands Ralph runs before
  committing.
- Edit `git-commit.md` for commit message conventions.
