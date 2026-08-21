# mathlib-fp 2.0.0 release candidate

This branch prepares the frozen 2.0.0 release candidate. It is **not** a
published stable release: 1.10.0 remains the latest published stable version
until final 2.0.0 publication.

## Promotion outcome

2.0.0 promotes the API proven during the 1.x runway. The generated 2.0 API
snapshot matches the frozen 1.10.0 snapshot; the only release-state difference
is the version identity. The library remains a clean native Pascal
implementation with no mandatory third-party runtime.

## Migration and compatibility

Existing supported 1.x code continues to compile. The recommended 2.0 paths
are the typed/common paths already introduced and rehearsed during 1.x;
intentional compatibility symbols remain available. There are no new breaking
changes, deprecations, warning changes, default changes, or numerical-result
changes in this candidate. See the [migration guide](../../guides/migration/to-2.0.md).

## Qualification scope

The candidate is prepared for qualified Linux and Windows RC workflows,
versioned/offline documentation, representative workflows, and the full
native Pascal test suite. Final publication requires normal CI review and the
approved RC qualification workflow; this branch does not tag, publish, or
replace stable Pages content.

## Known limitations and deferrals

The limitations and 2.1+ deferrals recorded by the frozen
[1.10.0 capability manifest](../1.10.0/capability-manifest.md) remain in
effect. In particular, 2.1 special functions, 2.2 generalised spectral
algebra, 2.3 stiff/implicit ODEs, and 2.4 sparse direct work are not part of
2.0.0.
