# Closed 1.10.0 capability manifest

Version 1.9.9 closes the additive public work assigned to 1.10.0. This page
explains the closed manifest; the machine-readable source is
[`capability-manifest-1.10.0.json`](capability-manifest-1.10.0.json), checked
by `tools/check_convergence.py` against the roadmap, the 1.9.3 API decision,
the 1.9.7 migration rehearsal, and the frozen
[1.9 API snapshot](public-api-1.9.json).

The manifest is a declaration list, not an implementation. 1.9.9 adds no
public declaration; 1.10.0 implements exactly the closed declarations and
nothing else.

## Accepted declaration: `TVector2D.Rotate`

1.10.0 adds one allocation-free value operation to `GeometryLib.Geometry`:

```pascal
function TVector2D.Rotate(const Angle: Double): TVector2D;
```

Closed behavior contract:

- `Angle` is in radians; positive values rotate counter-clockwise about the
  origin.
- The source vector is not modified; the result is a new value.
- The operation is O(1) and allocation-free on the fixed-size record.
- `Rotate(Pi / 2)` agrees with `Perpendicular` and `Rotate(-a)` inverts
  `Rotate(a)` within a stated 1e-15 relative tolerance.
- The magnitude is preserved within the stated tolerance for finite inputs.
- `V := V.Rotate(a)` is an ordinary value assignment and is safe.
- Rotating the zero vector returns the exact zero vector.
- Non-finite angle or components follow the documented GeometryLib non-finite
  contract.

The closed test plan covers orientation, angle conventions, perpendicular
agreement, magnitude preservation, source immutability, zero-vector,
non-finite, and allocation-free (heap-traced) fixtures across the standard
test builds. The documentation plan extends the GeometryLib reference, the
runnable geometry example, the capability inventory, and the 1.10.0 release
notes.

## Accepted declaration: deprecation marking

1.10.0 marks **no** declaration as deprecated:

- The 1.9.7 migration rehearsal retained `TPressureKit`, `EPressureError`,
  `TVelocityKit`, and `EVelocityError` with exact type/exception identity and
  no hidden dependency. That decision is closed; no warning or package move
  follows.
- All 21 plain compiler aliases reviewed by the 1.9.3 decision remain
  retained. The common `TFluidDynamicsKit`/`EFluidDynamicsError` names stay
  preferred documentation for new cross-fluid code only.
- `IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` remain supported
  compatibility paths; no removal runway starts.
- Full 1.x source compatibility is retained throughout 1.10.0.

The closed test plan re-runs the 1.9.7 consumer projects and alias-boundary
package evidence against the 1.10.0 candidate and requires the alias review
statuses to stay `retain`/`review-only`.

## Explicit deferrals beyond 2.0

Every proposal that is not accepted into 1.10.0 is explicitly deferred rather
than left open:

| Proposal | Routing | Reason |
| --- | --- | --- |
| 3-D vector rotation | Deferred beyond 2.0 | Axis-angle/quaternion/matrix semantics plus orientation, units, normalization, and naming need a dedicated design |
| Bessel, elliptic, exponential-integral families | Deferred beyond 2.0 | No stable implementation or demonstrated downstream need |
| Advanced sparse direct algorithms | Deferred beyond 2.0 | Fill-reducing, multifrontal, distributed, out-of-core, GPU paths need separate storage/performance design |
| Block/flexible Krylov, AMG, parallel/SIMD dispatch | Deferred beyond 2.0 | No stable parallelism design; portable serial solvers remain the path |
| Advanced spectral families | Deferred beyond 2.0 | Dedicated design required beyond symmetric/Hermitian and partial solvers |
| Advanced DSP design and wavelet packets | Deferred beyond 2.0 | Conditional capability without qualified validation |
| Survival/factor analysis, robust covariance, boosting | Deferred beyond 2.0 | Prerequisite numerical validation unavailable |
| General model/decomposition persistence | Deferred beyond 2.0 | Selected adapters are stable; general persistence needs its own design |
| Additional domains or algorithm families | Deferred beyond 2.0 | New domains require the [governance](GOVERNANCE.md) contribution gate |

## Release discipline for 1.10.0

- 1.10.0 implements only this closed manifest plus the exact documentation,
  snapshot-diff, migration, and release-candidate work in the roadmap.
- At least two 2.0 release-candidate cycles run from tagged source and
  offline-documentation archives; the freeze accepts only release-blocking
  fixes with regression evidence and a reviewed API diff.
- 2.0.0 then requires only version/release metadata and promotion of the
  qualified candidate.

## Closure status

`unresolved_api_questions` is empty. The final
[1.9.9 API snapshot and diff](API_SNAPSHOT_FINAL_1.9.9.md) record an empty
compiled 1.9.0-to-1.9.9 diff, and every capability gap is either accepted
into this manifest or explicitly deferred. No API design question remains
open for the 1.10.0/2.0 handoff.
