---
name: crossplane
description: Author and reason about Crossplane resources — CompositeResourceDefinitions (XRD), Compositions, Composite Resources (XR), Composition Functions, Managed Resources, Providers, ProviderConfig, EnvironmentConfigs and Operations. Always grounded in the latest major.minor Crossplane docs (docs.crossplane.io), and self-updating: when the docs move to a new version the skill can refresh its own reference files. Use when the user asks to create, edit, review, or explain any Crossplane manifest or concept.
---

# Crossplane Skill

Help the user build and understand Crossplane control-plane resources. Every answer must match
the **currently pinned docs version** in `VERSION` — never rely on stale memory of Crossplane
APIs, because Crossplane changed heavily between v1 and v2 (namespaced XRs, claims removed,
function-only compositions).

The user is a senior software engineer whose first language is not English. Use clear, simple,
direct English. Short sentences. Be precise and technical, but easy to read.

---

## First move on every invocation

1. **Read `VERSION`** (in this skill's folder). It records the docs version the reference files
   were written against, e.g. `2.3`.
2. **Read the relevant `references/*.md`** for the task before writing YAML. Do not answer from
   memory — the reference files are the source of truth.
3. **If the user names a different version**, or you suspect the pinned version is behind, run the
   **Self-update** procedure below before producing manifests.

The canonical docs root is:

```
https://docs.crossplane.io/            # redirects to latest, e.g. /v2.3/
https://docs.crossplane.io/v<MAJOR>.<MINOR>/
```

---

## What this skill helps create

| Concept | Kind / apiVersion (v2) | Reference |
|---------|------------------------|-----------|
| CompositeResourceDefinition (XRD) | `CompositeResourceDefinition` · `apiextensions.crossplane.io/v2` | `references/xrd.md` |
| Composition | `Composition` · `apiextensions.crossplane.io/v1` (Pipeline mode) | `references/composition.md` |
| Composition Functions | `Function` package + pipeline steps | `references/functions.md` |
| Composite Resource (XR) | your XRD's group/kind (namespaced by default in v2) | `references/concepts.md` |
| Managed Resources / Providers / ProviderConfig | provider-specific CRDs | `references/concepts.md` |
| Operations (Operation / CronOperation / WatchOperation) | `ops.crossplane.io` (alpha) | `references/concepts.md` |

Ready-to-copy starting points live in `templates/`.

---

## Workflow for authoring a manifest

1. **Confirm scope.** Ask (only if unclear): which resource kind, the API group the user owns
   (e.g. `platform.acme.io`), the version (`v1alpha1`), and whether the XR should be `Namespaced`
   (v2 default), `Cluster`, or `LegacyCluster` (v1-compatible claims behaviour).
2. **Load the reference** for that kind and, if useful, the matching `templates/*.yaml`.
3. **Generate the YAML** using the pinned version's exact `apiVersion` and field names. Never mix
   v1 and v2 field shapes.
4. **Cross-check** against the reference file's "gotchas" section (e.g. `served`/`referenceable`
   flags on XRD versions, `mode: Pipeline` required on Compositions).
5. **Explain briefly** what each block does and what the user must install (functions, providers).

### v2 defaults to remember (verify against `VERSION`/docs)

- XRs and Managed Resources are **namespaced by default**. Set `spec.scope` on the XRD explicitly.
- **Claims are removed.** Use namespaced XRs directly. `LegacyCluster` scope keeps v1 claim behaviour.
- **Compositions must use functions.** Native patch-and-transform was removed; use
  `mode: Pipeline` with `function-patch-and-transform` (or other functions).

---

## Self-update procedure

Use this when the docs advance to a new major.minor, when the user asks to update the skill, or
when a generated manifest is rejected by a newer/older cluster.

1. **Detect the latest version.** Fetch `https://docs.crossplane.io/` and read the version it
   resolves to (the `/v<MAJOR>.<MINOR>/` path), or ask the user which version they run.
2. **Compare** with `VERSION`. If unchanged and the user did not report a discrepancy, stop —
   nothing to do. Otherwise continue.
3. **Re-fetch the primary pages** for the affected concepts (only what changed if you know it):
   - `.../composition/composite-resource-definitions/` → `references/xrd.md`
   - `.../composition/compositions/` → `references/composition.md`
   - `.../composition/composition-functions/` → `references/functions.md`
   - `.../composition/composite-resources/` and `.../managed-resources/` → `references/concepts.md`
   - `.../whats-new/` → diff v-to-v behaviour changes
4. **Rewrite the changed `references/*.md` and `templates/*.yaml`** to match the new docs. Keep the
   same file structure and the "gotchas" sections. Update every `apiVersion`, field name, and
   default that changed.
5. **Write the new version into `VERSION`** (bare `MAJOR.MINOR`, e.g. `2.4`).
6. **Tell the user** exactly what changed between the old and new version — cite the doc URLs you
   read — so they can review the diff before committing.

Always cite the doc page URL for any claim you take from the docs. If a page is unreachable, say so
and fall back to the pinned reference files; never invent field names.

---

## Guardrails

- **Docs are truth, memory is not.** For anything version-sensitive, read `references/*.md` or the
  live docs before answering.
- **Never mix API versions.** A v2 XRD (`.../v2`) with v1 field shapes will not apply.
- **State prerequisites.** Compositions need their `Function` and `Provider` packages installed;
  say which ones.
- **Read-only to clusters by default.** Generate manifests; only `kubectl apply`/`crossplane`
  commands when the user explicitly asks, and show the command first.
- **Tool-agnostic.** For fetching docs use this environment's web tool (`WebFetch`/`WebSearch` in
  Claude Code); for asking the user use its structured question tool if present.
