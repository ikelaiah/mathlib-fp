# mathlib-fp 1.10.0 release notes

Version 1.10.0 is the backward-compatible minor release that implements the
closed 1.9.9 capability manifest and then freezes the code, API,
documentation sources, support claims, migration material, qualification
procedure, and distribution artifacts promoted to 2.0. It adds exactly one
public declaration and marks no declaration deprecated.

## Added: `TVector2D.Rotate`

`GeometryLib.Geometry` gains one allocation-free value operation on the
`TVector2D` fixed-size record:

```pascal
function TVector2D.Rotate(const Angle: Double): TVector2D;
```

Closed behavior contract:

- `Angle` is in radians; positive values rotate counter-clockwise about the
  origin.
- The source vector is not modified; the result is a new value, so
  `V := V.Rotate(a)` is an ordinary value assignment.
- The operation is O(1), allocation-free, thread-safe, and reentrant.
- `Rotate(Pi / 2)` agrees with `TVector2D.Perpendicular` and `Rotate(-a)`
  inverts `Rotate(a)` within a stated 1e-15 relative tolerance.
- The magnitude is preserved within that tolerance for finite inputs.
- Rotating the zero vector returns the exact zero vector.
- Non-finite angles or components follow the documented GeometryLib IEEE-754
  convention (NaN propagates through `Sin`/`Cos`).

The method is documented in the
[GeometryLib reference](../../guides/domains/geometry.md) and demonstrated by the runnable
[geometry example](../../../examples/12_geometry.pas), which is now covered by the
example-output gate. Focused regression fixtures live in
[`tests/TestGeometryLib.pas`](../../../tests/TestGeometryLib.pas) and the public-API
smoke suite (`TestPublicAPI`) is extended in the same change.

## Deprecation decision: no-deprecation

1.10.0 marks **no** declaration as deprecated:

- The 1.9.7 migration rehearsal retained `TPressureKit`, `EPressureError`,
  `TVelocityKit`, and `EVelocityError` with exact type/exception identity and
  no hidden dependency. That decision is unchanged.
- All 21 plain compiler aliases reviewed by the 1.9.3 decision remain
  retained; the common `TFluidDynamicsKit`/`EFluidDynamicsError` names stay
  preferred documentation for new cross-fluid code only.
- `IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` remain supported
  compatibility paths directed to the typed facades through explicit copying
  conversions; no removal runway starts.

No warning, hint, or package move is added. Full 1.x source compatibility is
retained throughout 1.10.0.

## API snapshot and diff

The historical 1.9 public-API baseline
([`public-api-1.9.json`](../../public-api-1.9.json) and
[`API_REFERENCE_1.9.md`](../1.9.0/api-reference.md)) is preserved byte-identically
and is pinned by SHA-256 in `tools/check_docs.py`; the frozen 1.9.0-to-1.9.9
diff therefore remains empty without ever mutating its baseline. The current
release snapshot and reference
([`public-api-1.10.0.json`](../../public-api-1.10.0.json) and
[`API_REFERENCE_1.10.0.md`](../../reference/api/reference-1.10.0.md)) are generated from the
live `src/` interfaces. The exact 1.9.9-to-1.10.0 diff is one added
`TVector2D.Rotate` function row on the `TVector2D` record (classified
`recommended` through the existing `TVector2D` common path) plus the
corresponding `GeometryLib.Geometry` unit-interface hash change. No existing
declaration, behavior, default, warning, or package membership changes. The
2.0-candidate decision and diff
([`api-decision-2.0.json`](../../api-decision-2.0.json),
[`api-diff-1.9-to-2.0.json`](../../api-diff-1.9-to-2.0.json)) name the decided 2-D
contract; 3-D rotation remains deferred beyond 2.0.

## Upgrade notes

- Existing 1.9 code requires no edit and compiles unchanged.
- `TVector2D.Rotate` is a pure addition on an existing value record; callers
  keep every existing method, operator, and alias.
- No migration step or compatibility package is required for 1.10.0.

## Qualification boundary

Local evidence is recorded in [QUALIFICATION_1.10.0.md](qualification.md).
Exact Linux and Windows checksummed, network-isolated clean-archive release
candidate jobs remain mandatory before tagging. The final 2.0 release requires
at least two 2.0 release-candidate cycles from tagged source and offline
documentation archives per the roadmap.

## Known limitations

- 3-D vector rotation is explicitly deferred beyond 2.0 pending a design
  choice among axis-angle, quaternion, and matrix semantics.
- Deferred families remain visible as unsupported in the capability
  inventory until a future design activates them.