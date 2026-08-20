# mathlib-fp 1.9.9 release notes

Version 1.9.9 is the final 1.9.x convergence release. It introduces no
planned public capability. It closes the evidence, compatibility decisions,
and exact manifest of additive public work assigned to 1.10.0, and is the
handoff to the minor release that completes the approved API before the final
2.0 freeze.

## Closed 1.10.0 capability manifest

The machine-readable [`capability-manifest-1.10.0.json`](../../capability-manifest-1.10.0.json)
and its human-readable [explanation](../1.10.0/capability-manifest.md) close
every accepted capability gap:

- `TVector2D.Rotate(const Angle: Double): TVector2D` is declared for 1.10.0
  only, with a complete behavior contract (radians, counter-clockwise
  positive, allocation-free value operation, source immutability,
  `Perpendicular` agreement at π/2, magnitude tolerance, zero-vector, and
  non-finite behavior), a test plan, a documentation plan, and an empty
  compatibility impact.
- The deprecation-marking decision closes as **no-deprecation**: the 1.9.7
  rehearsal decisions stand, all 21 aliases remain retained, and full 1.x
  source compatibility is retained throughout 1.10.0.
- Every other proposal — 3-D rotation, advanced spectral/sparse/iterative/DSP
  families, conditional statistics, general persistence, parallelism, and any
  new domain — is explicitly deferred beyond 2.0 with a recorded reason.

`tools/check_convergence.py` enforces the manifest against the roadmap, the
1.9.3 API decision, the 1.9.7 rehearsal, the capability inventory, and the
frozen 1.9 API snapshot on every change.

## Final candidate API snapshot and diff

The [final snapshot and exact diff](api-snapshot-final.md) confirm the
compiled 1.9.0-to-1.9.9 diff is empty across source, behavior, warnings, and
packaging. The candidate 2.0 surface is exactly the frozen
[1.9 snapshot](../../public-api-1.9.json) plus the closed 1.10.0 additions.

## Provenance and governance

- The [provenance audit](provenance-audit.md) covers every stable
  `src/` unit: algorithm provenance, fixture provenance, MIT licence status,
  and the no-third-party-code/no-runtime-dependency guarantees.
- The [governance policies](../../project/governance.md) complete the 2.x maintenance
  policy, support policy, deprecation policy, contribution gate for new
  domains, and security support window. `SECURITY.md` and `CONTRIBUTING.md`
  carry the user-facing statements.

## Upgrade notes

- Existing 1.9 code requires no edit; the public 1.9 interface remains
  frozen.
- 1.9.9 adds no declaration, no warning, no behavior change, and no package
  change.
- The closed manifest is a declaration for 1.10.0; 1.9.x does not implement
  it.

## Qualification boundary

Local evidence is recorded in [QUALIFICATION_1.9.9.md](qualification.md).
Exact Linux and Windows checksummed, network-isolated clean-archive candidate
jobs remain mandatory before tagging; no local result is generalized to a
target that did not run.

## Known limitations

- 1.10.0 and 2.0.0 remain future releases; the 1.9.x line ends with this
  release.
- Deferred families remain visible as unsupported in the
  [capability inventory](../../reference/capabilities.md) until a future design activates
  them.
