# Crossplane concepts (pinned to `VERSION`)

Source: https://docs.crossplane.io/v2.3/ — re-fetch and rewrite via the Self-update procedure when
`VERSION` changes.

## The object model

| Object | What it is |
|--------|------------|
| **Managed Resource (MR)** | A Kubernetes CRD representing one external resource (an S3 bucket, an RDS instance). Reconciled by a **Provider**. Namespaced by default in v2. |
| **Provider** | A package that installs MR CRDs and a controller that talks to an external API (AWS, GCP, Azure, Kubernetes, Helm, …). |
| **ProviderConfig** | Auth + connection settings a Provider uses (credentials source, region, etc.). Referenced by MRs via `spec.providerConfigRef`. |
| **Composite Resource (XR)** | A custom high-level API you define. Its schema comes from an **XRD**; its behaviour comes from a **Composition**. Namespaced by default in v2. |
| **CompositeResourceDefinition (XRD)** | Defines the XR's API: group, kind, versions, schema, and scope. See `xrd.md`. |
| **Composition** | Tells Crossplane how to turn one XR into a set of composed resources, via a **function pipeline**. See `composition.md`. |
| **Composition Function** | A packaged program (`Function` package) run in the Composition pipeline to generate/patch composed resources. See `functions.md`. |
| **EnvironmentConfig** | Cluster-scoped config data functions can pull into the pipeline (region maps, shared settings). |
| **Operation / CronOperation / WatchOperation** | Alpha `ops.crossplane.io` resources that run function pipelines as one-off, scheduled, or watch-triggered tasks — for day-2 automation, not resource ownership. |

## v1 → v2 behaviour changes (verify against `.../whats-new/`)

- **Namespaced by default.** XRs and MRs live in namespaces; set `spec.scope` on the XRD.
- **Claims removed.** In v1 users created a namespaced Claim that mapped to a cluster-scoped XR.
  In v2 users create the namespaced XR directly. Use XRD `scope: LegacyCluster` to keep the old
  cluster-scoped-XR + claim behaviour during migration.
- **Functions only.** Native (inline) patch-and-transform was removed. Compositions must use
  `mode: Pipeline` with functions.
- **Any Kubernetes resource can be composed** — not just infrastructure MRs.

## How the pieces connect

```
User ──applies──▶ XR (namespaced, kind from XRD)
                    │  selected by matching compositeTypeRef
                    ▼
                 Composition (mode: Pipeline)
                    │  runs steps
                    ▼
             Function pipeline ──generates──▶ composed resources
                                               (MRs, K8s objects, other XRs)
                    │
                    ▼
                 Providers reconcile MRs ──▶ external cloud APIs
```

## API groups (v2 — confirm in the docs API reference)

| Group | Used for |
|-------|----------|
| `apiextensions.crossplane.io` | XRD (`/v2`), Composition (`/v1`), CompositionRevision |
| `pkg.crossplane.io` | Provider, Function, Configuration, and their *Revision* kinds |
| `ops.crossplane.io` | Operation, CronOperation, WatchOperation (alpha) |
| provider groups, e.g. `s3.aws.m.upbound.io` | Managed Resources (the `.m.` marks namespaced MRs) |
