# 1.9.4 numerical evidence

Version 1.9.4 closes the numerical-evidence audit for the library's stable
capability families. It does not add or alter public APIs, and it does not use
ordinary example output as a universal correctness claim.

The machine-readable catalogue is
[`numerical-evidence-1.9.4.json`](../../numerical-evidence-1.9.4.json). It contains
one record for each stable family in
[`capabilities.json`](../../capabilities.json): 28 records at the time of release.

| Evidence category | Families covered |
| --- | --- |
| Exact properties | Value and storage primitives, random number generation, status, interchange, persistence, and expressions |
| Reference comparisons | Scalar special functions, interpolation, differentiation, statistics, applied DSP, and data utilities |
| Residual and reconstruction checks | Dense and sparse direct solvers, iterative methods, factorizations, eigenvalue routines, and modelling |
| Feasibility and diagnostics | Optimisation, convex optimisation, and state estimation |

Each record defines its input domain, edge cases, budget, reference provenance,
and tests that exercise the claim. `budget.kind` distinguishes absolute and
relative error, residual, backward error, reconstruction error, feasibility,
and exact properties. A zero limit is allowed only for exact properties;
numerical estimates remain estimates rather than proofs.

## Provenance and regeneration

Reference entries identify the method, source, precision, parameters, and
licence. The catalogue is regenerated and checked from repository-controlled
inputs only: it needs neither a network connection nor an external DLL.

Run the offline gates from the repository root:

```text
python tools/test_numerical_evidence.py
python tools/check_numerical_evidence.py
python tools/test_numerical_mutation.py
python tools/run_numerical_mutation.py --compiler fpc
```

The mutation gate copies the relevant source and test suite into an isolated
temporary tree. Three sampled high-risk defects must compile and then be
detected by FPCUnit: a `GammaLn` Lanczos result replacement, a double-precision
dense direct-solve replacement, and a Bluestein transform replacement. The
working tree remains unchanged; case logs are retained only when a mutation is
not detected.

## Limits

This evidence is not a proof of correctness over every real input, every
compiler, or every platform. It records the release's bounded claims and keeps
their validation executable, so future changes can be measured against the
same domains and budgets.
