# CompositeResourceDefinition (XRD)

Source: https://docs.crossplane.io/v2.3/composition/composite-resource-definitions/

An XRD defines the API of a Composite Resource: its group, kind, versions, OpenAPI schema, and
scope. Applying an XRD makes Crossplane create the XR CRD.

## v2 shape

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  # name MUST be <plural>.<group>
  name: xdatabases.platform.acme.io
spec:
  group: platform.acme.io
  names:
    kind: XDatabase
    plural: xdatabases
  # Namespaced (v2 default) | Cluster | LegacyCluster (v1 claim behaviour)
  scope: Namespaced
  versions:
    - name: v1alpha1
      served: true          # served through the API
      referenceable: true   # Compositions may target this version (exactly one true)
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                region:
                  type: string
                size:
                  type: string
                  enum: [small, medium, large]
              required:
                - region
                - size
            status:
              type: object
              properties:
                address:
                  type: string
```

## Gotchas

- `metadata.name` **must** equal `<spec.names.plural>.<spec.group>`, or the XRD is rejected.
- Exactly **one** version should have `referenceable: true`. Multiple served versions are allowed.
- `apiextensions.crossplane.io/v2` enables the `scope` field. `/v1` XRDs behave like legacy
  cluster-scoped XRs with claims (`claimNames`).
- Crossplane injects `spec.crossplane` (composition selection) and standard `status.conditions`;
  do not redefine them.
- Under `scope: Namespaced`, the resulting XR is namespaced and there is **no** separate claim.
- Add printer columns / defaults / validation via standard OpenAPI v3 schema fields.

## Version notes

- **v1 XRDs** use `apiextensions.crossplane.io/v1`, have no `scope`, and use `spec.claimNames`
  to enable namespaced claims. Prefer v2 for new work; use `scope: LegacyCluster` on a v2 XRD only
  when migrating existing v1 consumers.
