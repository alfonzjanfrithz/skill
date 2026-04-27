# Skills — Software Fundamentals for AI Coding

> Based on [Matt Pocock's skills for AI coding](https://github.com/mattpocock/skills) introduced in his  [Talk](https://www.youtube.com/watch?v=v4F1gFy-hqg). Adapted to be stack-agnostic and slimmer.

> **Thesis**: Bad code is expensive. AI in a good codebase thrives; AI in a bad one produces garbage faster. Software fundamentals matter more than ever.

---

## The Skills

### vet — "The AI didn't do what I wanted"

You and the AI don't share a **design concept**. Fix this by letting the AI grill you — 40, 60, 100 questions — until every branch of the design tree is resolved.

### write-prd — "Turn the conversation into a spec"

Once vetting is complete, synthesize the shared understanding into a written PRD. The PRD becomes the single source of truth for implementation.

### breakdown — "The PRD is too big to build at once"

Split the PRD into thin vertical slices (tracer bullets), each written as a local issue file. Prioritize AFK (autonomous) slices over HITL (human-in-the-loop) ones.

### tdd — "The AI built the right thing, but it doesn't work"

The AI **outruns its headlights** — writing piles of code before checking if any works. Fix: red-green-refactor, one vertical slice at a time. One test → one implementation → repeat.

### glossarize — "The AI is way too verbose" (use as needed)

No shared language means you talk past each other. Extract a canonical glossary into `GLOSSARY.md`. Use those terms everywhere — vetting, PRDs, code review. The AI thinks more concisely and implements closer to intent.

### deepen — "The AI doesn't understand my code" (use as needed)

The codebase is full of **shallow modules** — complex interfaces, no functionality behind them. Build **deep modules** instead: simple interface, lots of behavior inside. Easier for humans and AI to navigate, easier to test at the interface.

### domain-model — "My brain can't keep up" (use as needed)

You're reviewing implementation details you shouldn't need to think about. Stress-test plans against existing `CONTEXT.md` and `docs/adr/`, updating them inline as decisions crystallize. Design the interface, delegate the implementation.

---

## How They Flow Together

```
vet → write-prd → breakdown → ralph (run.sh) → [loop]
 ↑                                              |
 └──────────────────────────────────────────────┘
```

1. **vet** — Think through a plan. Get grilled until the design concept is solid.
2. **write-prd** — Turn the vetted conversation into a written PRD.
3. **breakdown** — Split the PRD into independently workable issues (tracer bullets).
4. **ralph** — Execute via `run.sh`. Picks AFK issues, implements with TDD behind the scenes, runs feedback loops, and commits.

**As needed**, inject **glossarize**, **domain-model**, or **deepen** whenever language drifts, architecture friction appears, or context gaps emerge.

Then loop back when new code introduces new concepts or friction.

All skills work on brownfield projects. No prerequisites needed.

---

## Key References

- *A Philosophy of Software Design* — John Ousterhout (deep modules, complexity)
- *The Pragmatic Programmer* — Andy Hunt & Dave Thomas (software entropy, feedback loops, outrunning your headlights)
- *The Design of Design* — Frederick P. Brooks (design concept, design tree)
- *Domain-Driven Design* — Eric Evans (ubiquitous language)
