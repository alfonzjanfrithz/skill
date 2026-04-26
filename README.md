# Skills — Software Fundamentals for AI Coding

> Based on [Matt Pocock's skills for AI coding](https://github.com/mattpocock/skills) introduced in his  [Talk](https://www.youtube.com/watch?v=v4F1gFy-hqg). Adapted to be stack-agnostic and slimmer.

> **Thesis**: Bad code is expensive. AI in a good codebase thrives; AI in a bad one produces garbage faster. Software fundamentals matter more than ever.

---

## The Skills

### vet — "The AI didn't do what I wanted"

You and the AI don't share a **design concept**. Fix this by letting the AI grill you — 40, 60, 100 questions — until every branch of the design tree is resolved.

### glossarize — "The AI is way too verbose"

No shared language means you talk past each other. Extract a canonical glossary into `GLOSSARY.md`. Use those terms everywhere — vetting, PRDs, code review. The AI thinks more concisely and implements closer to intent.

### tdd — "The AI built the right thing, but it doesn't work"

The AI **outruns its headlights** — writing piles of code before checking if any works. Fix: red-green-refactor, one vertical slice at a time. One test → one implementation → repeat.

### deepen — "The AI doesn't understand my code"

The codebase is full of **shallow modules** — complex interfaces, no functionality behind them. Build **deep modules** instead: simple interface, lots of behavior inside. Easier for humans and AI to navigate, easier to test at the interface.

### domain-model — "My brain can't keep up"

You're reviewing implementation details you shouldn't need to think about. Stress-test plans against existing `CONTEXT.md` and `docs/adr/`, updating them inline as decisions crystallize. Design the interface, delegate the implementation.

---

## How They Flow Together

```
vet → domain-model → glossarize → deepen → tdd
 ↑                                              |
 └──────────────────────────────────────────────┘
```

1. **vet** — Think through a plan. Get grilled.
2. **domain-model** — Vet against existing docs. Write decisions to `CONTEXT.md` and `docs/adr/`.
3. **glossarize** — Extract canonical terms into `GLOSSARY.md`.
4. **deepen** — Find architectural friction. Propose deep modules.
5. **tdd** — Implement with red-green-refactor.

Then loop back when new code introduces new concepts or friction.

All skills work on brownfield projects. No prerequisites needed.

---

## Key References

- *A Philosophy of Software Design* — John Ousterhout (deep modules, complexity)
- *The Pragmatic Programmer* — Andy Hunt & Dave Thomas (software entropy, feedback loops, outrunning your headlights)
- *The Design of Design* — Frederick P. Brooks (design concept, design tree)
- *Domain-Driven Design* — Eric Evans (ubiquitous language)
