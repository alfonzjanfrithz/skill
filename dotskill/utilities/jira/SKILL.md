---
name: jira
description: Interact with JIRA (Server / Data Center) — read and update issues, run JQL searches, manage comments, transitions and assignees. Use when the user references a JIRA issue key (e.g. PROJ-16673), a JIRA browse URL, or asks to look up, search, comment on, transition, or assign JIRA tickets. Reads connection details from JIRA_BASE_URL, JIRA_API_TOKEN and JIRA_AUTH_TYPE.
---

# JIRA Skill

This skill lets you (Claude) interact with the user's JIRA instance through its REST API v2,
using a helper script that handles authentication.

The user is a senior software engineer whose first language is not English.
**Communication style:** Use clear, simple, direct English. Short sentences. Be precise and
technical, but easy to read.

---

## Configuration (from the environment — never hardcode)

The skill reads three environment variables. Do not put any URL, token, or credential in code:

| Variable          | Meaning                                              |
|-------------------|------------------------------------------------------|
| `JIRA_BASE_URL`   | Base URL, e.g. `https://jira.example.com/`         |
| `JIRA_API_TOKEN`  | Bearer = Personal Access Token; Basic = `user:token` |
| `JIRA_AUTH_TYPE`  | `bearer` (default) or `basic`                        |

If any required variable is missing, the script stops with a clear error. If that happens,
tell the user which variable to set — do not invent values.

---

## Golden rules (always follow)

1. **Always go through the helper script** `scripts/jira.sh`. It centralizes auth, the
   corporate SSL-inspection proxy workaround (`curl -k`), and error handling.
2. **Read-only by default.** Read commands (`get`, `raw`, `search`, `comments`,
   `transitions`, `myself`) may be run freely.
3. **Write commands require explicit user permission first.** These mutate JIRA:
   `comment`, `transition`, `assign`, and any `api` call with method `POST`/`PUT`/`DELETE`.
   Confirm with the user before running them. State exactly what you will change.
4. **Never print the token.** Do not echo `JIRA_API_TOKEN` or include it in commands you show.

---

## How to run it

The script lives next to this file. Invoke it with bash:

```bash
bash ~/.claude/skills/jira/scripts/jira.sh <command> [args...]
```

### Step 0 — sanity check (optional, on first use or auth errors)

```bash
bash ~/.claude/skills/jira/scripts/jira.sh myself
```

Shows the authenticated user. If this fails, the token or auth type is wrong — stop and tell
the user.

### Reading issues

```bash
# Concise, human-readable summary of one issue:
bash ~/.claude/skills/jira/scripts/jira.sh get PROJ-16673

# Pick specific fields:
bash ~/.claude/skills/jira/scripts/jira.sh get PROJ-16673 summary,status,description

# Full raw JSON (when you need everything):
bash ~/.claude/skills/jira/scripts/jira.sh raw PROJ-16673
```

A JIRA browse URL like `https://jira.example.com/browse/PROJ-16673` maps to issue key
`PROJ-16673` — extract the key from the URL and use it.

### Searching with JQL

```bash
bash ~/.claude/skills/jira/scripts/jira.sh search 'project = PROJ AND status = "In Progress"' 20
bash ~/.claude/skills/jira/scripts/jira.sh search 'assignee = currentUser() ORDER BY updated DESC'
```

### Comments

```bash
bash ~/.claude/skills/jira/scripts/jira.sh comments PROJ-16673          # read (safe)
bash ~/.claude/skills/jira/scripts/jira.sh comment  PROJ-16673 'text'   # WRITE — confirm first
```

### Transitions (changing status)

```bash
bash ~/.claude/skills/jira/scripts/jira.sh transitions PROJ-16673       # list valid moves (safe)
bash ~/.claude/skills/jira/scripts/jira.sh transition  PROJ-16673 21    # WRITE — confirm first
```

Always run `transitions` first to discover the correct numeric id — ids differ per workflow.

### Assigning

```bash
bash ~/.claude/skills/jira/scripts/jira.sh assign PROJ-16673 jsmith     # WRITE — confirm first
```

### Escape hatch — any REST call

For anything the named commands do not cover, use the generic `api` command. The path is
everything after the base URL.

```bash
bash ~/.claude/skills/jira/scripts/jira.sh api GET  /rest/api/2/project/PROJ
bash ~/.claude/skills/jira/scripts/jira.sh api POST /rest/api/2/issue '{"fields":{...}}'   # WRITE
```

JIRA Server/Data Center REST API v2 reference:
`https://docs.atlassian.com/software/jira/docs/api/REST/latest/`

---

## Reporting results

- Summarize what you found in plain text; do not dump huge JSON unless the user asks.
- When you change something, state exactly what changed (issue key, field, old → new).
- On HTTP errors, the script prints the JIRA error body — relay the meaningful part
  (e.g. "you lack permission", "transition id invalid") rather than the raw blob.
