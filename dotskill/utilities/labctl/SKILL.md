---
name: labctl
description: Drive iximiuz Labs entirely from the CLI with labctl — authenticate, and start/stop/SSH into Linux, Docker, Kubernetes and networking playgrounds; solve challenges; follow tutorials and courses; forward and expose ports; copy files; and author content. Use whenever the user mentions iximiuz, iximiuz Labs, labctl, a "playground", a DevOps "challenge/tutorial/course" on iximiuz, or asks to run/SSH/expose/port-forward a lab environment from the terminal. On every invocation it runs a freshness self-check (installed version + auth + live `--help`) so it stays aligned with the latest CLI.
---

# labctl — iximiuz Labs from the command line

`labctl` is the official CLI for [iximiuz Labs](https://labs.iximiuz.com) — a platform of
disposable Linux, Docker, Kubernetes, and networking **playgrounds**, plus **challenges**,
**tutorials**, and **courses**. This skill lets you (the agent) perform *all* of a user's
iximiuz work from the terminal: authenticate, launch environments, connect, move data, expose
services, and author content.

The user may be a software engineer whose first language is not English. Use clear, simple,
direct English. Short sentences. Keep the real technical terms.

> **`labctl --help` is the source of truth.** This file and `references/commands.md` are a
> curated map, but the installed CLI can change. Always confirm exact flags with
> `labctl <command> --help` before running anything non-trivial, and prefer what the live
> help says over what is written here.

---

## 1. Freshness self-check (run this FIRST, every invocation)

Before doing real work, run these three quick checks and report anything wrong to the user.
This is what keeps the skill aligned with the latest CLI and documentation.

```bash
# a) Is labctl installed, and what version?
labctl version 2>/dev/null || echo "labctl NOT installed"

# b) Is there an authenticated session?
labctl auth whoami 2>/dev/null || echo "NOT logged in"

# c) What commands does THIS install actually expose? (authoritative)
labctl --help 2>&1
```

Interpret the results:

- **Not installed** → offer to install (see §2). Do not fabricate output.
- **Not logged in** → tell the user to run `labctl auth login` (it opens a browser with a
  one-time URL). You cannot complete the browser step for them — ask them to run it, e.g.
  suggest they type `! labctl auth login` in the prompt so the output lands in the session.
- **Version staleness (best-effort, only when web access is available):** compare the
  installed version against the latest release. If newer, mention it and offer to upgrade —
  never force it.
  ```bash
  # Latest published version (needs network):
  curl -sf https://api.github.com/repos/iximiuz/labctl/releases/latest \
    | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
  ```
- **Command drift:** if `labctl --help` lists a command not documented in
  `references/commands.md`, trust the live help and run `labctl <command> --help` to learn it.
  Mention the gap so the reference can be refreshed later.

If web access is not available in the current tool, skip the version comparison silently and
rely on live `--help` output — do not block the task.

---

## 2. Installation

Only if the self-check shows labctl is missing. Confirm with the user before installing.

```bash
# Official one-liner (macOS/Linux)
curl -sf https://labs.iximiuz.com/cli/install.sh | sh

# Or Homebrew
brew install labctl
```

The binary typically lands at `~/.iximiuz/labctl/bin/labctl`. After install, run
`labctl auth login`.

---

## 3. How to work

1. **Self-check** (§1). Fix install/auth gaps before anything else.
2. **Confirm the exact command** with `labctl <command> --help` — flags evolve.
3. **Identify the target.** Most session commands take a `<playground-id>` (a hex id like
   `65e78a64366c2b0cf9ddc34c`). Get it from `labctl playground list`. Many commands accept
   `-q/--quiet` to print only ids — useful for scripting/capturing.
4. **Run the command.** Capture ids and URLs it prints; reuse them in follow-ups.
5. **Be careful with destructive and outward-facing actions** — see §5.

### Command groups at a glance

| Group | Purpose |
|-------|---------|
| `auth` | `login`, `logout`, `whoami` — session identity |
| `playground` (`p`) | `catalog`, `start`, `list`, `stop`, `restart`, `destroy`, `persist`, `machines`, `tasks`, `manifest`, `create`, `update`, `remove` |
| `ssh` / `ssh-proxy` | Open an SSH session (or proxy) into a playground machine |
| `cp` | Copy files to/from a playground (`-r` for dirs) |
| `port-forward` | Local (`-L`) / remote (`-R`) port forwarding; `--list` / `--restore` / `--remove` saved ports |
| `expose` (`e`) | `port`, `shell`, `list`, `remove` — publish HTTP services or a web terminal |
| `challenge` (`ch`) | `catalog`, `start`, `list`, `stop` — solve DevOps challenges |
| `tutorial` (`tut`) | `catalog`, `start`, `stop` — follow tutorials |
| `course` | `start`, `stop` — course lessons |
| `content` (`c`) | `create`, `list`, `pull`, `push`, `remove` — author content |
| `api` | Raw authenticated calls to the iximiuz Labs API |

Full flag-level detail and examples live in **`references/commands.md`**. Read it when you
need specifics; do not paste its whole contents at the user.

---

## 4. Common recipes

```bash
# Start a playground and SSH straight in
labctl playground start ubuntu-24-04 --ssh

# Browse what's available, then start k3s and open it in a browser
labctl playground catalog
labctl playground start k3s --open

# List sessions, capture the first id, run a command over SSH
labctl playground list
labctl ssh <playground-id> -- kubectl get nodes

# Copy a local file in, and a result out
labctl cp ./app.yaml <playground-id>:~/app.yaml
labctl cp <playground-id>:~/out.log ./out.log

# Forward a service running in the playground to localhost:8080
labctl port-forward <playground-id> -L 8080:80

# Expose an HTTP service publicly and open it
labctl expose port <playground-id> 8080 --open

# Share a web terminal
labctl expose shell <playground-id>

# Solve a challenge / follow a tutorial from the terminal
labctl challenge catalog
labctl challenge start <challenge-name>
labctl tutorial start <tutorial-name>

# Raw API call
labctl api /auth/me
```

Open a playground directly in a local IDE: `labctl playground start docker --ide code`
(also `cursor`, `windsurf`).

---

## 5. Safety and etiquette

- **Destructive:** `playground destroy` completely deletes a session and its data;
  `playground remove` / `content remove` delete authored artifacts. Confirm with the user and
  name the exact target before running these. `stop` only pauses (state is preserved) — much
  safer than `destroy`.
- **Outward-facing:** `expose port ... --public` and `expose shell ... --public` publish a
  URL anyone with the link can reach. Confirm intent before making anything public, and remind
  the user to `expose remove` when done.
- **`--forward-agent` is INSECURE** (per the CLI's own help). Only use it if the user
  explicitly asks and understands the risk.
- **The browser auth step is the user's to do.** Never claim you logged them in.
- Report outcomes faithfully. If a command fails, show its actual output; do not invent ids,
  URLs, or success.

---

## 6. Keeping this skill current

The on-invoke self-check (§1) is the primary mechanism. When you notice drift between the live
`labctl --help` and `references/commands.md` (new/renamed commands or flags), tell the user and
offer to update `references/commands.md`. That file is meant to be regenerated from
`labctl <command> --help` output — it is a cache, not a spec.
