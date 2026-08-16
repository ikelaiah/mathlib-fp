# Exact proposed 1.9-to-2.0 API diff

The reviewed proposal is an empty compiled API diff. The complete 1.9 public
surface remains available in 2.0; version 1.9.3 changes how the surface is
presented, not what programs compile or how calls behave. An empty diff is a
deliberate compatibility decision, not missing analysis.

The normative machine-readable diff is
[`api-diff-1.9-to-2.0.json`](api-diff-1.9-to-2.0.json). It is checked against
the exact owner/kind/name/signature baseline in
[`public-api-1.9.json`](public-api-1.9.json).

## Consequences by category

| Category | Exact proposed consequence |
| --- | --- |
| Source | None. No declaration is added, removed, renamed, hidden, or given a different signature/default. |
| Behaviour | None. No numerical rule, ownership/mutation/aliasing contract, exception, status, tolerance, RNG, callback, or thread-safety behavior changes. |
| Warnings | None. No deprecation or compiler warning is added or removed. |
| Packaging | None. All current source units—including pressure, velocity, and focused finance alias units—direct-source use, and the Lazarus package remain present. |
| Documentary defaults | The 13 common paths appear first; advanced stable declarations remain documented; all 21 exact aliases and compatibility rows receive explicit guidance; generic scaffolding is labelled implementation support. |

## Why compatibility entries remain

`IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` are not removed and receive no
deprecation warning. New double-real code is directed to the named typed
facades through explicit copying conversions. `FinanceLib.Bonds` and
`FinanceLib.NPV` are retained because their focused aliases are semantically
exact and useful; age or naming taste is not a removal reason.

The exact-alias review originally identified `TPressureKit`/`EPressureError`
and `TVelocityKit`/`EVelocityError` as prospective canonicalization candidates.
The 1.9.7 migration and package-boundary rehearsal retained all four: focused
imports remain useful, exact, and dependency-neutral. Documentation may prefer
the common facade for cross-fluid code, but no deprecation warning, removal, or
package move is approved.

## Separately routed capability

The common-program review identified ergonomic 2-D and 3-D vector rotation as
useful. The 1.9.9 convergence gate closed the routing in the
[1.10.0 capability manifest](CAPABILITY_MANIFEST_1.10.0.md):

- 2-D `TVector2D.Rotate(const Angle: Double): TVector2D` is declared for
  1.10.0 only, with a closed contract (radians, counter-clockwise positive,
  allocation-free value operation, source immutability, `Perpendicular`
  agreement at π/2, magnitude preservation tolerance, zero-vector, and
  non-finite behavior), a test plan, a documentation plan, and an empty
  compatibility impact.
- 3-D rotation is explicitly deferred beyond 2.0 because it must choose among
  axis-angle, quaternion, and matrix semantics and settle orientation, units,
  normalization, and naming.

This document still proposes no 1.9.x declaration, and 1.9.x does not
implement the 1.10.0 addition.

## Mechanical closure

`tools/check_api_decision.py` fails if any declaration lacks one of the five
classifications, any plain compiler alias lacks exactly one five-part review,
any compatibility row lacks exactly one decision/note, any
recommended selector lacks an output-checked common example, any common
example names generic implementation support, any domain/unit or convention is
unresolved, or any source/behaviour/warning/packaging consequence differs from
the explicit empty lists above.
