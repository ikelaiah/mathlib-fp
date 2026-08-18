# Release maintenance view

> Refreshed for each stable release. Automation of this page is future work.

This table is a maintenance snapshot for the current stable release (1.9.9),
not a scorecard. Every count is reproducible from the cited files:

- **Stable capability families** — stable families tracked in
  [`capabilities.json`](capabilities.json). The capability inventory
  deliberately enumerates only the curated families that carry qualification
  evidence; domains it does not enumerate are marked `not measured` rather
  than estimated.
- **Units** — public units in the frozen
  [`public-api-1.9.json`](public-api-1.9.json) snapshot, matching the
  [`provenance-audit-1.9.9.json`](provenance-audit-1.9.9.json) unit list.
- **Public API rows** — declarations in the frozen 2,880-row 1.9 snapshot,
  summed per domain. The count includes every snapshot classification
  (recommended, advanced, compatibility, experimental, and implementation
  support), so it is an upper bound on the application-facing surface, not the
  curated common path.
- **Runnable examples** — examples in
  [`examples/README.md`](../examples/README.md) whose domain column names the
  domain; the cross-domain migration example (`23_api_migration_preview.pas`)
  is counted separately.
- **Qualification status** — provenance audit coverage in 1.9.9. Deeper
  numerical, performance, and workflow evidence is in the release-specific
  reports listed below.
- **Known limitations** — the guide or capability-inventory boundary for each
  domain, not an exhaustive list.

| Domain | Stable capability families | Units | Public API rows | Runnable examples | Qualification status | Known limitations |
| ------ | -------------------------- | ----: | --------------: | ----------------: | -------------------- | ----------------- |
| AlgebraLib | 12 | 13 | 1064 | 6 | Provenance-audited (13 units) | Dense row-major, no broadcasting; LU `Solve` is square-only; no nonsymmetric/generalised/polynomial eigensystems; sparse products may create fill; partial eigensystems are largest-magnitude only |
| CombinatoricsLib | not measured | 1 | 43 | 1 | Provenance-audited (1 unit) | Fixed-width integers overflow at documented maxima (`Factorial` > 20, `CatalanNumber` > 30, `BellNumber` > 18); `K <= N` required; not arbitrary precision |
| EngineeringLib | 1 | 8 | 421 | 6 | Provenance-audited (8 units) | Temperature conversions are affine; time units are fixed-duration conventions; Haar is power-of-two; equiripple/Chebyshev/elliptic IIR design and wavelets beyond Haar are outside 1.8 |
| FinanceLib | not measured | 3 | 71 | 2 | Provenance-audited (3 units) | Rates are decimals; discrete period compounding except Black-Scholes (continuous); IRR needs a positive initial investment and one positive future flow |
| GeometryLib | not measured | 1 | 132 | 1 | Provenance-audited (1 unit) | `Normalise` raises on zero/non-finite vectors; arithmetic operators propagate NaN/Infinity; degenerate constructions raise |
| InterchangeLib | 1 | 1 | 14 | 1 | Provenance-audited (1 unit) | Only the documented spline/FIR/standardizer/scalar-Kalman adapters persist; decomposition factors and general object graphs are not stable formats |
| MathBase | 5 | 9 | 239 | 7 | Provenance-audited (9 units) | `StudentT` covers `X >= 0` only; triangle/circle helpers do not validate degenerate input; budgets are corpus-tested, not worst-case proofs |
| MLLib | 1 | 2 | 129 | 3 | Provenance-audited (2 units) | Dense, serial, in-memory baselines; no boosting, distributed training, or multiclass LDA; forest importance is not causal |
| NumericsLib | 3 | 4 | 272 | 4 | Provenance-audited (4 units) | Explicit non-stiff ODE path only (stiff systems are a post-2.0 gate); `LagrangeInterp` ill-conditioned beyond ~10 knots; `GaussLegendre5` uses five evaluations |
| OptimizationLib | 2 | 2 | 126 | 3 | Provenance-audited (2 units) | Local solvers are local only; `SimplexLP` is standard-form `min c'x` with `Ax <= b`, `x >= 0`; no MILP or interior-point LP |
| ProbabilityLib | not measured | 1 | 76 | 2 | Provenance-audited (1 unit) | PDF/PMF return 0 and CDF clamps out-of-domain `X`; parameter order is `(X, params...)`; `StudentTTwoTail` for two-sided tests |
| StatsLib | 2 | 3 | 177 | 6 | Provenance-audited (3 units) | Sample `Variance` (n−1) versus population `StdDev` (n); tests are two-sided; covariance-style standard errors need full rank; no survival/factor/robust-covariance families |
| TimeSeriesLib | 1 | 2 | 116 | 4 | Provenance-audited (2 units) | `ARIMAForecast` needs the original series to undifference; Kalman filters are linear-Gaussian baselines; `Undifference` needs `D` initial values |

## Qualification evidence for this release

Qualification and evidence are published per release; the 1.9.9 set includes
the [qualification report](QUALIFICATION_1.9.9.md),
[workflow qualification](WORKFLOW_QUALIFICATION_1.9.8.md),
[numerical evidence](NUMERICAL_EVIDENCE_1.9.4.md),
[performance evidence](PERFORMANCE_EVIDENCE_1.9.5.md),
[portability evidence](PORTABILITY_EVIDENCE_1.9.6.md), and the
[provenance audit](PROVENANCE_AUDIT_1.9.9.md). The
[capability inventory](CAPABILITIES.md) is the authority for maturity and
limitations.

## What this page does not measure

Line counts and test-file counts are not the principal health measure and are
not used to rank domains. As a secondary context note, the current `src/`
contains about 49,400 lines of Pascal across 50 units, dominated by AlgebraLib
(~17,200 lines) followed by EngineeringLib (~4,800) and MathBase (~4,600).
Size reflects history and algorithm density, not health.
