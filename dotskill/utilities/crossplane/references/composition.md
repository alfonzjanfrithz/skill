# Composition

Source: https://docs.crossplane.io/v2.3/composition/compositions/

A Composition tells Crossplane how to realise an XR as composed resources. In v2 a Composition
**must** run a function pipeline (`mode: Pipeline`); inline patch-and-transform was removed.

## v2 shape (Pipeline with function-patch-and-transform)

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: xdatabases.platform.acme.io
spec:
  # Which XR this Composition satisfies. Must match a referenceable XRD version.
  compositeTypeRef:
    apiVersion: platform.acme.io/v1alpha1
    kind: XDatabase
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform   # the installed Function's metadata.name
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: bucket
            base:
              apiVersion: s3.aws.m.upbound.io/v1beta1
              kind: Bucket
              spec:
                forProvider:
                  region: us-east-2
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.region
                toFieldPath: spec.forProvider.region
    # Optional: auto-detect readiness of composed resources
    - step: ready
      functionRef:
        name: function-auto-ready
```

## Gotchas

- `mode: Pipeline` is required in v2. Each step needs a `step` name and a `functionRef.name` that
  matches an **installed** `Function` package.
- Steps run **in order**; each function receives the previous function's desired state and can add
  or mutate composed resources.
- `compositeTypeRef` must reference an XRD version marked `referenceable: true`.
- Composition still uses `apiextensions.crossplane.io/v1` even though the XRD it targets is `/v2`.
- Pick a Composition per XR via `spec.crossplane.compositionRef` / `compositionSelector` on the XR,
  or set the XRD's default composition policy.
- Applying a changed Composition creates a new **CompositionRevision**; XRs roll forward per their
  update policy.

## Common functions

| Function | Purpose |
|----------|---------|
| `function-patch-and-transform` | Declarative resources + patches (replaces native P&T). |
| `function-auto-ready` | Marks the XR ready when composed resources are ready. |
| `function-go-templating` | Generate resources from Go templates. |
| `function-kcl` / `function-python` | Generate resources with KCL / Python. |

See `functions.md` for how to install and chain functions.
