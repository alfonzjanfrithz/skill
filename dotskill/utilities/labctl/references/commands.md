# labctl command reference

> **Cache, not spec.** Generated from `labctl <command> --help` (labctl 0.1.61, 2026-02).
> The installed CLI is authoritative — always re-check with `labctl <command> --help`.
> Regenerate this file from live help output when the self-check reports drift.

Global flags (available on every command):

- `--endpoint <url>` — iximiuz Labs API endpoint URL
- `-l, --log-level <debug|info|warn|error|fatal>` — log level (default `info`)
- `-h, --help` — help for the command

---

## auth — session identity

| Command | Purpose |
|---------|---------|
| `labctl auth login` | Log in (prompts to open a browser page with a one-time-use URL). |
| `labctl auth logout` | Log out; deletes the current CLI session. |
| `labctl auth whoami` | Print the current user info. |

## playground (aliases: `p`, `playgrounds`) — environments

| Command | Purpose |
|---------|---------|
| `catalog` (`cat`) | List playgrounds from the catalog. `-f/--filter my-custom\|recent\|popular\|community` (default: official only); `-q` names only. |
| `start <name>` | Start a session. See flags below. |
| `list` | List recent playground sessions. |
| `machines <id>` | List machines of a session. |
| `tasks <id>` | List tasks of a session. |
| `manifest <id>` | View a session's manifest. |
| `stop <id>` | Stop a running session, preserving state. |
| `restart <id>` | Restart a stopped session, resuming state. |
| `persist <id>` | Make an active session persistent. |
| `destroy <id>` | **Destructive.** Delete a session and all its data. |
| `create` | Create a new playground from a base + manifest file. |
| `update` | Update an authored playground from a manifest file. |
| `remove` | **Destructive.** Remove a playground you authored. |

`playground start` flags:

- `-f, --file <path>` — manifest file (machines, tabs, custom init tasks, etc.)
- `-o, --open` — open the playground page in a browser
- `--ssh` — SSH in immediately after start
- `-m, --machine <name>` — target machine for `--ssh` (default: first machine)
- `-u, --user <name>` — SSH user (default: machine's default login user)
- `--ide <code|cursor|windsurf>` — open in the named local IDE
- `-i, --init-condition <k=v>` — set init conditions (repeatable)
- `--with-port-forwards` — auto-forward ports from the playground config
- `-q, --quiet` — print only the playground's ID
- `--skip-wait-init` — don't wait for initialization (debugging)
- `--as-free-tier-user` — run as a free-tier user (test tier behavior)
- `--safety-disclaimer-consent` — acknowledge the safety disclaimer
- `--forward-agent` — **INSECURE**: forward the SSH agent to the VM

## ssh / ssh-proxy — remote access

`labctl ssh [flags] <playground-id>`

- `-m, --machine <name>` — target machine (default: first)
- `-u, --user <name>` — SSH user (default: machine default)
- `--forward-agent` — **INSECURE** SSH agent forwarding
- Run a command remotely: `labctl ssh <id> -- <cmd ...>` (e.g. `-- ls -la /`)

`labctl ssh-proxy` — start an SSH proxy to the playground's machine.

## cp — copy files

```
labctl cp [flags] <playground-id>:<src> <dst>
labctl cp [flags] <src> <playground-id>:<dst>
```

- `-r, --recursive` — copy directories
- `-m, --machine <name>` — target machine
- `-u, --user <name>` — SSH user

## port-forward — tunnels

`labctl port-forward <playground> [-m machine] -L [LOCAL:]REMOTE [-L ...] | --list | --restore | --remove <index>`

"local" = labctl side, "remote" = playground side (like SSH `-L`/`-R`).

- `-L, --local <[[LHOST:]LPORT:][RHOST:]RPORT>` — local forwarding (repeatable)
- `-R, --remote <[RHOST:]RPORT:LHOST:LPORT>` — remote forwarding (repeatable)
- `--list` — list "should be forwarded" ports (config + past attempts)
- `--restore` — forward all saved "should be forwarded" ports
- `--remove <index>` — remove a saved port by 0-based index
- `-m, --machine <name>` — target machine
- `-q, --quiet` — suppress verbose output

Using `-L`/`-R` auto-saves the forward to the playground config for later `--restore`.

## expose (aliases: `e`, `ex`) — publish services

| Command | Purpose |
|---------|---------|
| `port` | Expose an HTTP(s) service running in the playground. (`--open`, `--public`) |
| `shell` | Expose a web terminal session with a handy URL. (`--public`) |
| `list` | List all exposed ports and web terminals. |
| `remove` | Un-expose a port or shell by ID. |

`--public` makes the URL reachable by anyone with the link — confirm intent, remove when done.

## challenge (aliases: `ch`, `challenges`)

| Command | Purpose |
|---------|---------|
| `catalog` | List challenges (filter by category and/or status). |
| `start <name>` | Solve a challenge from the terminal. |
| `list` | List running challenge attempts. |
| `stop` | Stop the current solution attempt. |

## tutorial (aliases: `tut`, `tutorials`)

| Command | Purpose |
|---------|---------|
| `catalog` | List tutorials (filter by category and/or status). |
| `start <name>` | Follow a tutorial from the terminal. |
| `stop` | Stop the current tutorial session. |

## course (alias: `courses`)

| Command | Purpose |
|---------|---------|
| `start` | Start a course lesson. |
| `stop` | Stop a running course lesson. |

## content (aliases: `c`, `contents`) — authoring

| Command | Purpose |
|---------|---------|
| `create <challenge\|tutorial\|skill-path\|course\|training> <name>` | Create new content (author-only). `-d/--dir` local dir (default `$CWD/<name>`). |
| `list` | List authored content (filter by kind). |
| `pull` | Pull remote content files locally (backup/editing). |
| `push` | Push local content files to remote (the "inner author loop"). |
| `remove` | **Destructive.** Remove authored content. |

## api — raw API access

`labctl api <path> [flags]`

- `-X, --method <verb>` — HTTP method (default `GET`)
- `--input <file>` — request body file (`-` for stdin)
- `-s, --silent` — do not print the response body

Examples:

```bash
labctl api /auth/me
echo '{"started": true}' | labctl api /tutorials/NAME --method PATCH --input -
```

## completion

`labctl completion <shell>` — generate a shell autocompletion script.
