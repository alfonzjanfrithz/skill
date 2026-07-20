# Composition Functions

Source: https://docs.crossplane.io/v2.3/composition/composition-functions/

Functions are packaged programs that run in a Composition's `pipeline`. In v2 they are the **only**
way to compose resources. Each function reads the observed XR + composed resources and returns the
**desired** state; the next step builds on that.

## Installing a Function

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.9.0
```

- `metadata.name` is what `functionRef.name` in a Composition points to.
- Pin `:vX.Y.Z` tags; check the function's repo/registry for the current version.
- A `Function` install creates FunctionRevisions, like Providers.

## How the pipeline runs

```
observed XR + observed composed resources
        │
   step 1 function ──▶ desired state (v1)
        │
   step 2 function ──▶ desired state (v2)   # sees step 1's output
        │
        ▼
  Crossplane applies the final desired composed resources
```

- Order matters. Put generators (patch-and-transform, go-templating, kcl) before finalizers
  (auto-ready).
- Each step's `input` is function-specific; its `apiVersion`/`kind` are defined by that function
  (e.g. `pt.fn.crossplane.io/v1beta1` `Resources` for patch-and-transform).
- Functions can read **EnvironmentConfigs** and connection details when the pipeline provides them.

## Gotchas

- A Composition referencing a function that is not installed will not compose — install the
  `Function` package first.
- Keep function input schema versions in sync with the installed function version.
- Prefer official `crossplane-contrib` functions; verify the latest tag rather than guessing.

## Common functions

| Function | Package (name) | Use |
|----------|----------------|-----|
| Patch & Transform | `function-patch-and-transform` | Declarative bases + patches. |
| Auto-Ready | `function-auto-ready` | XR ready when composed resources are ready. |
| Go Templating | `function-go-templating` | Template resources with Go templates + Sprig. |
| KCL | `function-kcl` | Generate/mutate with KCL. |
| Python | `function-python` | Generate/mutate with Python. |
