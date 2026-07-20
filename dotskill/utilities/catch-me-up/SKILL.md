---
name: catch-me-up
description: Get up to speed on an unfamiliar repository fast, through one of six focused lenses — Architecture, Convention, Feature Trace, Syntax/API, Testing, or History. Produces an evidence-based, ESL-friendly briefing (with a Mermaid diagram) in the terminal and offers a shareable HTML export. Use when the user says "catch me up", "get me up to speed", "onboard me to this repo", "help me understand this codebase", "how does X work here", or points at an inner-source repo they need to grasp quickly. It orients the reader with real evidence; it never modifies the repo.
---

# Catch Me Up

Help an engineer get up to speed on an unfamiliar repository **fast**. This is an onboarding
accelerator for a large inner-source organisation: getting read access and raising a PR is easy,
but *understanding* a repo you did not write is the real bottleneck — especially for juniors, or
for a senior engineer arriving from a different domain.

The reader is **a software engineer whose first language is not English**. Write clear, simple,
direct English. Short sentences. Keep real technical terms; simplify the connecting language.

You produce an **evidence-based briefing** through one of six lenses (modes). You read and reason;
**you never modify the analysed repository.** Every claim is grounded in real code you looked at —
cite `file:line`. When you cannot determine something, say so; never invent.

## The six modes

| Mode | Goal (one line) | Method file |
|------|-----------------|-------------|
| `architecture` | The system's overall structure and how components relate. | `modes/architecture.md` |
| `convention` | Coding standards, naming patterns, internal best practices. | `modes/convention.md` |
| `feature-trace` | End-to-end data flow and code path for a specific feature. | `modes/feature-trace.md` |
| `syntax-api` | Language idioms, framework APIs, and non-obvious usage. | `modes/syntax-api.md` |
| `testing` | How the code is tested and which frameworks are in use. | `modes/testing.md` |
| `history` | The historical context behind past changes. | `modes/history.md` |

## Inputs

Read what the user typed after invoking the skill and infer these. Do **not** require a rigid
argument syntax — pick them out of natural language, then ask only for what is missing.

- **mode** — one of the six above. If absent, **ask** with `AskUserQuestion` (list all six, one
  line each). Match loose phrasing: "how is this built" → `architecture`, "how does login work" →
  `feature-trace` with target "login", "how do they test" → `testing`, "why was this changed" →
  `history`.
- **target** — an optional feature name, subsystem, or subpath to focus on (required for
  `feature-trace`; helpful narrowing for the others).
- **depth** — `junior` | `domain-new` | `expert`. Default **`domain-new`**. See Depth below.
- **repo path** — an optional path so the user can point at a *sibling* inner-source repo. Default
  to the current working directory.

## Workflow

### Step 1 — Resolve scope

Confirm the repo path (default: cwd). Establish the ground truth before reading deeply:

```bash
ls -la <repo>                                  # top-level layout
git -C <repo> rev-parse --is-inside-work-tree  # is it a git repo? (needed for history mode)
```

Detect the primary language(s) and stack from manifest/build files present (`package.json`,
`go.mod`, `pom.xml`/`build.gradle`, `pyproject.toml`/`requirements.txt`, `Cargo.toml`, `*.tf`,
`Chart.yaml`, etc.) and get a rough size (file and directory counts) so you can **scale effort** —
a small repo is read directly; a large one is fanned out (Step 4).

### Step 2 — Select mode + depth

If the mode is still unknown, ask now. Then state back to the user, in one line, the lens and depth
you are about to run — e.g. *"Running **feature-trace** on `checkout` at **domain-new** depth."*

### Step 3 — Load the method

Read the matching `modes/<mode>.md` in this skill's folder. Follow its recipe: what to gather, how
to investigate, the output structure, and the diagram to draw. Load only the mode you are running.

### Step 4 — Gather evidence

Read the **real files** — not just names. For anything non-trivial, open the file and confirm.

- **Small repo / narrow target:** read directly with the search and read tools.
- **Large repo / broad mode:** fan out **parallel `Explore` agents**, one per subsystem or
  file-group, and have each report back the files, entry points, and relationships it found. Then
  read the specific files that matter to close the gaps.

Rules while gathering:
- **Never invent.** If a conclusion depends on code you did not see, say so plainly.
- Cite evidence as `path:line`. These are clickable and let the reader verify you.
- Note which tools/capabilities were available (git, package manifests, CI config) so the reader
  knows how trustworthy the briefing is.

### Step 5 — Synthesise the briefing

Produce the mode's briefing in the structure its method file defines. Every mode includes at least
one **Mermaid diagram** as a first-class part of the output (see Diagrams). Emit it as a fenced
` ```mermaid ` block so it renders in the terminal preview and in the HTML export.

Adapt the wording to the chosen **depth**.

### Step 6 — Report + offer export

Render the briefing in the terminal first. Then offer:

> Want me to save this as a shareable HTML file? (y/n)

If yes, read `assets/template.html` (in this skill's folder), fill its placeholders
(`{{TITLE}}`, `{{SUBTITLE}}`, `{{MODE}}`, `{{BODY}}`, `{{DATE}}`) with the briefing (convert the
markdown body to HTML; keep ` ```mermaid ` blocks as `<pre class="mermaid">` so the bundled Mermaid
script renders them), and write it next to the repo or where the user asks. Use the session's date
for `{{DATE}}`; do not fabricate a date.

**HTML formatting — write descriptions point-by-point.** The HTML is for quick scanning, so favour
short bullet points over paragraphs. In the exported body:

- Render every description, summary, and explanation as a **bulleted list** (`<ul><li>`), one idea
  per point — do not use dense multi-sentence paragraphs.
- Keep each point to one short sentence. Lead with the key noun, then the detail.
- Keep tables, code blocks, `file:line` references, and ` ```mermaid ` diagrams as-is — only the
  prose descriptions become bullets.
- The one-line summary at the top of a section may stay a single sentence; everything below it is points.

### Step 7 — Close

Always end the briefing with two short sections:

- **Where to go next** — the concrete files / entry points the reader should open first, in order.
- **Open questions / gaps** — what you could not determine, and why (missing access, no git, code
  not read, ambiguous ownership). This tells the reader where their own follow-up is needed.

## Depth

Adapt explanation depth to the reader's familiarity. Same evidence, different framing.

| Depth | Reader | How to write |
|-------|--------|--------------|
| `junior` | New to programming or to this kind of stack. | Explain the concepts and vocabulary as you go, more hand-holding, define idioms and patterns before using them. |
| `domain-new` *(default)* | Senior engineer, new to this repo/domain. | Assume engineering fluency. Teach *this* repo and *this* domain: the map, the conventions, the "why". Skip programming basics. |
| `expert` | Knows the domain, wants the map fast. | Terse. Just the structure, the key files, and the non-obvious parts. Minimal prose. |

## Diagrams (first-class in every mode)

A picture is the fastest way to orient someone new, so a diagram is a core deliverable — not
decoration. Each mode has a **default diagram**, written in **Mermaid** so it renders in the
terminal briefing and in the HTML export.

| Mode | Default diagram |
|------|-----------------|
| `architecture` | `flowchart`/`graph` component map — modules, boundaries, data stores, external systems. |
| `feature-trace` | `sequenceDiagram` of the call path: entry → controller → service → data → response. |
| `convention` | `flowchart` "how to add a new X" recipe, or a directory-layout `graph`. |
| `syntax-api` | Usually annotated snippets; add a small `flowchart` when control/dispatch flow is non-obvious. |
| `testing` | `flowchart` of the test pyramid / how a test run flows through suites and CI gates. |
| `history` | `timeline` (or `gitGraph`) of the key changes and turning points in the area. |

Diagram rules:
- **Evidence-based:** every node and edge must reflect a real file or relationship you found — not a guess.
- **Readable:** cap node count; group or collapse when the picture gets large.
- **Labelled edges:** name the real mechanism on each edge — HTTP, event, import, FK, CLI call.

## Guardrails

- **Read-only.** Never modify, commit, or push to the analysed repo. Reading and running read-only
  commands (`git log`, `ls`, `grep`) is fine.
- **Evidence over speculation.** Cite `file:line`. When unsure, say so and put it under "Open questions".
- **Scale effort to repo size.** Small repo → read directly; large repo → fan out `Explore` agents.
- **Degrade gracefully.** If a needed capability is missing (e.g. `history` needs git, or a repo has
  no test suite for `testing`), say so and give the best briefing you can — do not fabricate.
- Write clear, ESL-friendly English throughout.
- **Tool-agnostic.** This skill runs in different coding agents (Claude Code, Cursor, opencode).
  Where it names a specific tool, use your environment's equivalent: for asking the user, use a
  structured question tool if present (`AskUserQuestion` in Claude Code, `question` in opencode),
  else ask in plain text; for the large-repo fan-out, use parallel sub-agents/tasks if the
  environment supports them (`Explore` agents in Claude Code), else read directory-by-directory.
