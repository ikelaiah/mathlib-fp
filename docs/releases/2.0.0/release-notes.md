# mathlib-fp 2.0.0

Version 2.0.0 is the published stable release. It promotes the frozen 1.10.0
API after two release-candidate cycles, an exercised 30-day soak, and the
Linux/Windows clean-archive qualification of `v2.0.0-rc.2`.

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
changes in this release. See the [migration guide](../../guides/migration/to-2.0.md).

## Qualification scope

The release is supported by qualified Linux and Windows clean-archive
workflows, versioned/offline documentation, representative workflows, and the
full native Pascal test suite. The final `v2.0.0` tag triggers the release and
documentation workflows from this finalized release record.

## Known limitations and deferrals

The limitations and 2.1+ deferrals recorded by the frozen
[1.10.0 capability manifest](../1.10.0/capability-manifest.md) remain in
effect. In particular, 2.1 special functions, 2.2 generalised spectral
algebra, 2.3 stiff/implicit ODEs, and 2.4 sparse direct work are not part of
2.0.0.
