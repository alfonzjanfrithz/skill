# Excalidraw Diagram Skill

A coding agent skill that generates beautiful and practical Excalidraw diagrams from natural language descriptions. Not just boxes-and-arrows - diagrams that **argue visually**.

Compatible with any coding agent that supports skills.

## What Makes This Different

- **Diagrams that argue, not display.** Every shape/group of shapes mirrors the concept it represents — fan-outs for one-to-many, timelines for sequences, convergence for aggregation. No uniform card grids.
- **Evidence artifacts.** As an example, technical diagrams include real code snippets and actual JSON payloads.
- **Built-in visual validation.** A Playwright-based render pipeline lets the agent see its own output, catch layout issues (overlapping text, misaligned arrows, unbalanced spacing), and fix them in a loop before delivering.
- **Brand-customizable.** All colors and brand styles live in a single file (`references/color-palette.md`). Swap it out and every diagram follows your palette.

## Setup

The skill includes a render pipeline that lets the agent visually validate its diagrams. There are two ways to set it up:

**Option A: Ask your coding agent (easiest)**

Just tell your agent: *"Set up the Excalidraw diagram skill renderer by following the instructions in SKILL.md."*
It will run the commands for you.

**Option B: Manual**

Run these commands from the skill's `references` directory:

```bash
cd <skill-path>/excalidraw/references
uv sync
uv run playwright install chromium
```

Replace `<skill-path>` with your agent's skills directory (e.g., `.claude/skills`, `.cursor/skills`, `.opencode/skills`).

**Quick test**

To verify the renderer works, run:

```bash
cd <skill-path>/excalidraw/references
uv run python render_excalidraw.py test.excalidraw --output test_output.png
```

If setup is correct, this will produce a `test_output.png` file.