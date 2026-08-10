# mathlib-fp v1.9.4

## Numerical trust closure

1.9.4 publishes a release-owned numerical evidence catalogue for all 28 stable
capability families. The release adds validation tooling that rejects missing,
duplicated, or ill-formed records; distinguishes exact checks from numerical
budgets; and verifies that each cited test and reference source is present.

Three high-risk families also have compile-and-test mutation checks. Each
sampled fault must be detected by the existing FPCUnit suite in an isolated
source overlay.

See [the numerical evidence report](NUMERICAL_EVIDENCE_1.9.4.md) and [the
machine-readable catalogue](numerical-evidence-1.9.4.json) for the individual
claims, domains, budgets, and provenance.

## Compatibility

The public API remains frozen at the 1.9 baseline. Unsupported families remain
unsupported; this release documents and validates stable behaviour rather than
promoting experimental functionality.

## Qualification

The release qualification runs the normal build, test, package, documentation,
and numerical-evidence gates without network access. The completed
qualification report records the exact candidate commit and command outcomes.
