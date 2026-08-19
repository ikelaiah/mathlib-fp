# mathlib-fp 1.10.0 pull-request notes

This file collects the reviewable implementation changes that make up the
1.10.0 release, following the repository's convention that implementation,
documentation, and qualification evidence ship in the same change.

## Release branch

`release/v1.10.0` (pull request against `main`).

## Implementation

- `src/GeometryLib.Geometry.pas`: added
  `function TVector2D.Rotate(const Angle: Double): TVector2D` — an O(1),
  allocation-free, value-semantic counter-clockwise rotation by radians that
  leaves the source unmodified and returns the exact zero vector for the zero
  vector. Non-finite angles/components follow the documented IEEE-754
  convention.
- `tests/TestGeometryLib.pas`: focused regression fixtures — orientation,
  angle conventions, `Perpendicular` agreement, magnitude preservation on the
  covered ordinary/extreme finite ranges, source immutability and self
  assignment, zero-vector, and non-finite behaviour.
- `tests/TestPublicAPI.pas`: public-API smoke coverage for `TVector2D.Rotate`.

## API snapshot / baseline

- The historical 1.9 public-API baseline
  (`docs/public-api-1.9.json`, `docs/API_REFERENCE_1.9.md`) is preserved
  byte-identically and pinned by SHA-256 in `tools/check_docs.py`.
- The current release snapshot and reference
  (`docs/public-api-1.10.0.json`, `docs/API_REFERENCE_1.10.0.md`) record the
  single `TVector2D.Rotate` addition with an explicit 1.9.9-to-1.10.0 diff.

## Documentation

- `docs/GeometryLib.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, `README.md`,
  `docs/SUPPORT.md`, `SECURITY.md`.
- Release/qualification records: `docs/RELEASE_NOTES_1.10.0.md`,
  `docs/QUALIFICATION_1.10.0.md`.
- `examples/12_geometry.pas` gained an output-gated rotation workflow
  (`examples/output-contracts.json`).

## Tooling

- `tools/update_api_snapshot.py` is release-parameterised and no longer
  targets the frozen 1.9 baseline.
- `tools/check_docs.py` advances `CURRENT_RELEASE=1.10.0`,
  `NEXT_RELEASE=2.0.0`, checks the live interface against the 1.10.0 current
  snapshot, and guards the frozen 1.9 baseline.
- `tools/convergence.py` / `tools/check_convergence.py` are minimally decoupled
  from live Previous/Next headings; a small separate
  `tools/check_promotion_2_0.py` validates the 2.0-next release state.

The closed 1.10.0 capability manifest, the frozen 1.9 evidence, and the
1.9.9 convergence artifacts are unchanged.