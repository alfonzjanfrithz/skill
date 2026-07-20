---
name: pr-review-brief
description: Generate a standalone HTML briefing that helps a human reviewer understand and review a pull request faster. Use when the user asks to "review this PR", "make a PR review brief/briefing", "prep a PR for review", "explain this PR", "what changed in this branch/PR", or points at a diff, branch, or PR number to be reviewed. Explains PR intent and issue-tracker context (Jira/GitHub issues/etc., via whatever integration is available, or asks the user to paste it), maps changed files, shows before/after snippets of important logic, links tests to code, and lists evidence-based, actionable findings (blocking vs suggestion) with confidence. It prepares the reviewer; it does NOT replace human review and does NOT post comments anywhere.
---

# PR Review Briefing

Produce **one self-contained HTML file** that lets a human reviewer understand a pull
request and review it well. The output answers, in order:

```
What is this PR trying to do?  →  What changed and where?  →  What behavior changed?
→  Which tests prove it?  →  What are the risks?  →  What is worth commenting on?
```

The reader is a **senior software engineer whose first language is not English**.
Write clear, simple, direct English. Short sentences. Keep real technical terms; simplify
the connecting language.

**This skill prepares a reviewer. It does not replace review and never posts comments,
approves, or transitions anything.** It only reads and produces a local HTML file.

---

## Two halves, kept separate

The brief has a **comprehension** half (help the reviewer build a mental model) and a
**judgment** half (your assessment). Keep them in separate sections — never let an opinion
masquerade as a fact in the comprehension half.

- Comprehension: ticket context, change map, visual flow, before/after snippets, test-to-code map.
- Judgment: risk level, findings (blocking/important/suggestion), missing tests, architecture concerns, reviewer recommendation.

---

## Step 1 — Gather inputs

Collect as much real evidence as is available. Never invent any of it.

1. **Identify the PR scope.** Ask the user only if it is unclear. Resolve to a diff:
   - A branch/PR: find the merge base and diff against it.
     ```bash
     base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)
     git diff --stat "$base"...HEAD          # file-level overview
     git diff "$base"...HEAD                 # full diff
     git log --oneline "$base"..HEAD         # commit messages (intent signal)
     ```
     Do not assume the default branch is `main`. Detect it:
     `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null` (often `develop` in this kind of
     repo), or fall back to trying `origin/main`, `main`, `origin/develop`, `develop`. If the
     user named a base/target branch, use that.
   - If the user gives a GitHub/Bitbucket PR number and the `gh` CLI is available, you may
     fetch the PR title/description with it. Otherwise work from the local diff.
2. **Read full files, not just the diff,** for every file with non-trivial logic changes.
   The diff hides surrounding context (guards, transactions, existing constraints). State
   clearly when a conclusion depends on code you could not see.
3. **Pull supporting context** when present and relevant: README, design docs, test files,
   DB migrations, API/OpenAPI specs, dependency files, CI/linter output.
4. **Get the PR title/description** from the user, the commit messages, or `gh`.

### Ticket / issue context (capability detection, with fallbacks)

The PR usually references an issue tracker key — most often Jira (e.g. `PROJ-26559`), but
possibly GitHub/GitLab issues, Linear, etc. Look in the branch name, PR title/description,
and commit messages. **This skill does not require any specific tracker integration.** Walk
this ladder and use the first option that works; never invent ticket content.

1. **A dedicated tracker skill is available.** Check the skills offered to you this session
   (e.g. a `jira` skill, or any issue-tracker skill). If one matches the key you found, use
   it **read-only** to fetch the ticket. Follow that skill's own rules; do not run any write
   command (comment/transition/assign) — this skill must never mutate the tracker.
2. **A tracker MCP tool or CLI is available.** If no skill exists but you can see an Atlassian/
   Jira/GitHub MCP tool, or `gh`/`glab`/`jira` CLIs are installed and configured, use a
   read-only call to fetch the issue.
3. **The user pasted ticket details.** If the user gave the summary / acceptance criteria in
   the conversation, use that.
4. **Nothing is available.** Do **not** guess. Tell the user plainly, naming the key:
   *"I found ticket `<KEY>` but I have no integration to read it (no tracker skill, MCP tool,
   or CLI configured). Paste the ticket summary and acceptance criteria and I'll fold them
   in, or I can proceed without it."* Then continue and mark the **Ticket Context** section
   as *"Not available — no tracker integration; provided by user / omitted."*
5. **No key found at all.** Say so and ask the user whether a ticket exists.

Whichever source you use, extract: summary, business goal, acceptance criteria, constraints,
out-of-scope items, and ambiguities. In the HTML, note which source the context came from
(tracker skill / MCP / CLI / user-provided / none) so the reviewer knows how trustworthy it is.

---

## Step 2 — Analyze (the review method)

Do this analysis before writing HTML. For a large PR, consider spawning parallel Explore
agents per file group to read full files.

1. **Change intent.** From Jira + PR title/description + commits + diff, state the business
   goal, the before/after behavior, constraints, and out-of-scope items. If intent is
   unclear, say so explicitly — do not fabricate it.
2. **Change map.** Group changed files by purpose (core logic / API / data model /
   migrations / config / dependencies / tests / docs / generated-mechanical). For each
   group note what changed, why it matters, and a review priority.
3. **Important logic changes.** Select the changes that actually matter for review:
   business rules, auth/permissions, validation, state transitions, DB writes/migrations,
   external calls, error handling, retry/timeout, API compatibility, security, performance,
   concurrency, and the tests that prove them. Skip formatting, imports, renames, generated
   files, and boilerplate.
4. **Test-to-code mapping.** For each important production change, find the tests that
   exercise it. Note what is covered and what edge cases / failure paths / concurrency are
   not.
5. **Risk.** Assign Low / Medium / High using evidence (PR size, modules touched,
   criticality, DB/API/auth/security changes, test coverage, complexity, unknowns).
6. **Quality pass** across: correctness, security, reliability, maintainability,
   performance, tests, API compatibility, documentation. Capture only concrete, evidenced
   issues.

---

## Step 3 — Decide findings (be disciplined)

A finding goes in **only if it passes every check**:

```
1. Tied to a concrete file / function / line / diff / test / doc.
2. There is a plausible correctness, security, reliability, maintainability,
   performance, test, API, or documentation risk.
3. It is actionable — the reviewer can do something with it.
4. It is not personal preference.
5. It is not pure style a formatter/linter already handles.
6. It is not just repeating linter/static-analysis output (unless you add real reasoning).
7. Any uncertainty is stated.
```

**Reject** broad complaints without a fix, large refactors unrelated to the PR goal,
speculation stated as fact, and comments that would not change the PR outcome.

**Severity:** `blocking` (must fix before merge) / `important` (should fix, non-blocking) /
`suggestion` (optional).

**Confidence:**
- `high` — visible directly in diff/tests/docs.
- `medium` — likely from visible evidence, some surrounding context missing.
- `low` — plausible but depends on assumptions. **Put low-confidence items as
  "Questions for reviewer", not as definitive findings.**

Every finding states: title, location, category, severity, evidence, why it matters,
suggested fix, confidence, and what is uncertain.

---

## Step 4 — Build the HTML

Use `assets/template.html` (in this skill's folder). Write only the body content and the
metadata fields; the template provides the light theme, auto table-of-contents, anchors,
Mermaid, and code highlighting. Do not edit its CSS/JS.

Replace these placeholders:
- `{{TITLE}}` — e.g. `PR Review: <short PR title>`.
- `{{SUBTITLE}}` — one plain line, e.g. `PROJ-26559 · 14 files · branch feature/x → develop`.
- `{{PURPOSE}}` — `PR Review Briefing`.
- `{{DATE}}` — today's date, `YYYY-MM-DD` (it is given in your context; do not shell out).
- `{{BODY}}` — the body HTML below.

### Body sections (use `<h2>` per section so the TOC builds itself)

1. **Reviewer Brief** — open with a `<div class="callout tldr">` (2–4 sentences: what the PR
   does, the main behavior change, the highest-risk area). Then the overall risk and
   confidence as badges, and a **recommended review order** (`<ol>`) for large PRs.
2. **Ticket Context** — summary, business goal, acceptance criteria, constraints,
   out-of-scope, ambiguities, and a one-line note of the source (tracker skill / MCP / CLI /
   user-provided / none). If no integration was available, say so here (see Step 1) instead
   of inventing.
3. **High-Level Change Map** — a `<table>`: Area · Files · What changed · Why it matters ·
   Review priority (use priority badges).
4. **Visual Flow** — one or two Mermaid diagrams: the request/logic flow, and/or a
   Jira→code→test relationship graph. Only when there is real flow to show.
5. **Critical Code Changes** — for each important change use a `<div class="change">` with a
   `<div class="ba-grid">` before/after pair, then behavior difference, related Jira
   requirement, related tests, review focus, and a risk badge. Keep snippets ~10–40 lines;
   do not dump whole files. This section is for *understanding* — a snippet may show a good
   change, not only a problem.
6. **Test-to-Code Mapping** — a `<table>`: Production code · Behavior · Test · What it covers ·
   Possible gaps. Add test snippets where useful.
7. **Findings** — group by severity using `<div class="finding blocking|important|suggestion">`
   cards (see HTML patterns). Order: blocking, then important, then suggestions. If there are
   none in a tier, say so briefly.
8. **Missing Tests** — behavior/edge cases that look under-tested: related code, why it
   matters, a suggested test case, confidence.
9. **Architecture / Maintainability Concerns** — only concrete, evidenced concerns. No vague
   "this could be cleaner".
10. **Reviewer Recommendation** — based on ownership / recent authorship / touched modules
    if `git log`/`git blame` give you that signal; otherwise say no ownership data was
    available and recommend by domain (e.g. "someone familiar with the RDS provisioner").
11. **Questions & Confidence Notes** — low-confidence items as questions, plus what you
    analyzed, what was missing, and where uncertainty remains.

Cut sections that genuinely do not apply (e.g. no migrations, no API change) rather than
padding them.

---

## Step 5 — Write the file and report back

1. Write to the current working directory, named in kebab-case from the PR/ticket, e.g.
   `./pr-review-PROJ-26559.html`. Use the user's path if they gave one.
2. Tell the user: the file path, how to open it (`open <file>` on macOS), the overall risk
   level and a one-line headline of the top finding, and that Mermaid + highlight.js load
   from a CDN (first open needs internet).

---

## HTML patterns (copy these)

Badges — risk / severity / confidence / priority / category:
```html
<span class="badge risk-high">High risk</span>
<span class="badge sev-blocking">Blocking</span>
<span class="badge sev-important">Important</span>
<span class="badge sev-suggestion">Suggestion</span>
<span class="badge conf-medium">Confidence: medium</span>
<span class="badge prio-start">Start here</span>
<span class="badge prio-after">Review after core logic</span>
<span class="badge prio-low">Low priority</span>
<span class="badge cat">reliability</span>
```

Before/after change block:
```html
<div class="change">
  <h3>Refund eligibility now rejects duplicate requests</h3>
  <p><code>RefundService.java</code> · <code>createRefund(orderId)</code>
     <span class="badge risk-medium">Medium risk</span></p>
  <p><strong>Why it matters:</strong> main business rule for the ticket.</p>
  <div class="ba-grid">
    <div class="before"><h5>Before</h5>
      <pre><code class="language-java">if (!order.isCompleted()) throw new ...;
return repo.save(new Refund(order));</code></pre></div>
    <div class="after"><h5>After</h5>
      <pre><code class="language-java">if (!order.isCompleted()) throw new ...;
if (repo.existsByOrderId(order.getId()))
    throw new DuplicateRefundException();
return repo.save(new Refund(order));</code></pre></div>
  </div>
  <p><strong>Behavior difference:</strong> creation now also blocks a second refund for the same order.</p>
  <p><strong>Jira:</strong> "Users must not request multiple refunds for one order."</p>
  <p><strong>Related tests:</strong> <code>shouldRejectDuplicateRefund()</code>, <code>shouldAllowFirstRefund()</code></p>
  <p><strong>Review focus:</strong> is the check atomic under concurrent requests?</p>
</div>
```

Finding card:
```html
<div class="finding important">
  <h4><span class="title-text">Duplicate check may be race-prone</span>
    <span class="badge sev-important">Important</span>
    <span class="badge cat">reliability</span>
    <span class="badge conf-medium">Confidence: medium</span></h4>
  <dl>
    <dt>Location</dt><dd><code>RefundService.java</code>, <code>createRefund()</code></dd>
    <dt>Evidence</dt><dd>Code checks <code>existsByOrderId</code> then inserts, with no
        transaction, lock, or unique constraint visible in the changed files.</dd>
    <dt>Why it matters</dt><dd>Two concurrent requests can both pass the check and double-insert.</dd>
    <dt>Suggested fix</dt><dd>Add a DB unique constraint on <code>order_id</code>, or wrap
        check+insert in a transaction with a lock.</dd>
    <dt>Uncertainty</dt><dd>A unique constraint may already exist outside the diff — verify the schema.</dd>
  </dl>
</div>
```

Code blocks must carry a `language-XXX` class (`language-java`, `language-yaml`,
`language-sql`, `language-bash`, `language-json`, `language-xml`, `language-text`) and have
`<`, `>`, `&` HTML-escaped. Mermaid goes in `<pre class="mermaid">…</pre>` with no `theme`
set. Long supporting detail can go in `<details><summary>…</summary>…</details>`.

---

## Guardrails

- Read-only. Generate a local HTML file only. Never post comments, approve, merge, or
  mutate the issue tracker.
- No required integrations. Jira/GitHub/etc. are optional inputs — degrade gracefully when
  they are absent (see the ticket-context ladder) rather than failing or guessing.
- Evidence over speculation. If you did not see it, say you did not see it.
- No invented ticket content, no invented file paths, no invented test names.
- Comprehension facts and your opinions stay in their separate halves.
- Scale effort to the PR: a 2-file change gets a short brief; a broad refactor gets the full
  set of sections and a recommended review order.
