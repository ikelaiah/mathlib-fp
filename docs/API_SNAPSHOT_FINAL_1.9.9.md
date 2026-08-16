# Final 1.9.9 API snapshot and exact diff from 1.9.0

The 1.9.9 convergence gate publishes the final candidate public-API snapshot
and its exact diff from 1.9.0. The machine-readable source is
[`api-snapshot-final-1.9.9.json`](api-snapshot-final-1.9.9.json); the frozen
declaration baseline remains [`public-api-1.9.json`](public-api-1.9.json), and
the exact proposed 1.9-to-2.0 consequences remain
[`api-diff-1.9-to-2.0.json`](api-diff-1.9-to-2.0.json).

## The final candidate surface

The 2.0 candidate surface has exactly two parts:

1. **The 1.9.0 public API surface, unchanged.** The 2,880-row frozen snapshot
   is byte-identical from 1.9.0 through 1.9.9. Every `src/*.pas` interface
   digest matches the baseline, so 1.9.1–1.9.9 added no declaration, removed
   no declaration, and changed no signature, default, behavior, warning, or
   package membership.
2. **The closed 1.10.0 additions.** The
   [closed capability manifest](CAPABILITY_MANIFEST_1.10.0.md) declares
   `TVector2D.Rotate` for 1.10.0 only and applies no deprecation. 1.9.x adds
   no declaration.

## Exact diff from 1.9.0, by category

| Category | Exact 1.9.0-to-1.9.9 consequence |
| --- | --- |
| Compatibility-preserving corrections | None. No source declaration, behavior, warning, or packaging correction was required after 1.9.0. |
| Source | Empty. No declaration is added, removed, renamed, hidden, or re-signatured in the 1.9.x line. |
| Behaviour | Empty. No numerical rule, ownership/mutation/aliasing contract, exception, status, tolerance, RNG, callback, or thread-safety behavior changes. |
| Warnings | Empty. No deprecation or compiler warning is added or removed. |
| Packaging | Empty. All units, direct-source use, and the Lazarus package remain present. |
| 2.0 documentation | The 1.9.3 documentary defaults (common paths first, compatibility differences explicit, generic scaffolding labelled implementation support) plus the versioned web/offline documentation, checked examples, and evidence accumulated across 1.9.x. |

## Closure

The diff has no open questions. The compiled 1.9-to-2.0 proposal remains the
empty source/behaviour/warning/packaging diff published by 1.9.3; the only
future source change is the closed 1.10.0 addition declared in the manifest.
`tools/check_convergence.py` fails if the snapshot status, the diff
categories, or the manifest disagree with the roadmap and the 1.9.3 decision
artifacts.
