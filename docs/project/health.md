# Release maintenance view

Refreshed for v2.11.0 on 2026-10-22.

Counts describe the current source/API and curated capability inventory.
They are not a scorecard or a substitute for numerical and platform evidence.

- Units and declaration rows come from the [current API snapshot](../reference/api/public-api-2.11.0.json).
- Stable families come from [capabilities.json](../reference/capabilities.json); zero means this curated inventory has no separately measured family for that domain.
- Example counts use domain labels in [examples/README.md](../../examples/README.md); shared examples may count in more than one domain.
- Qualification status is in the [v2.11.0 report](../releases/2.11.0/qualification.md), not inferred from source counts.

| Domain | Stable capability families | Units | Public API rows | Runnable examples | Important limitations |
| --- | ---: | ---: | ---: | ---: | --- |
| AlgebraLib | 13 | 14 | 1209 | 13 | Dense and sparse serial baselines; sparse fill is data dependent; partial eigensystems target largest magnitude |
| CombinatoricsLib | 0 | 1 | 43 | 1 | Fixed-width integer overflow limits; no arbitrary precision |
| EngineeringLib | 3 | 8 | 472 | 6 | SOS Butterworth/Chebyshev I prototype orders 1–12; no equiripple, resampling or broader wavelet families |
| FinanceLib | 0 | 3 | 71 | 2 | Documented rate/time conventions and bounded numerical models |
| GeometryLib | 0 | 1 | 133 | 1 | Zero/non-finite normalization and degenerate constructions follow explicit contracts |
| InterchangeLib | 1 | 1 | 14 | 1 | Selected model adapters; no arbitrary model/decomposition graph persistence |
| MLLib | 3 | 3 | 168 | 6 | Dense serial analysis with grouped/stratified/chronological validation and PLS1; no duration windows, PLS2, imputation, or robust fitting |
| MathBase | 6 | 10 | 258 | 14 | Function-specific real domains and fixture budgets; no general symbolic algebra |
| NumericsLib | 4 | 4 | 310 | 5 | Dense SDIRK2 stiff ODE baseline; no DAEs, mass matrices or sparse stiff systems |
| OptimizationLib | 3 | 3 | 166 | 4 | Finite-box heuristic global search and local/dense constrained baselines; no mixed-integer or global-optimality certificates |
| ProbabilityLib | 0 | 1 | 76 | 2 | Documented distribution parameter/domain conventions and finite scalar arithmetic |
| StatsLib | 3 | 4 | 221 | 7 | Canonical Bernoulli/Poisson GLMs; no weights, offsets, regularization or robust covariance; moderate dense data |
| TimeSeriesLib | 1 | 2 | 116 | 4 | Linear-Gaussian filtering/forecasting baseline; no missing-observation or smoothing workflow |

The snapshot contains 55 units and 3,257 declarations; the example catalogue contains 49 programs.
Declarations include advanced, compatibility and specialization support; they
are not a count of recommended application entry points.

## Current evidence

See the [numerical catalogue](../releases/2.11.0/numerical-evidence.json),
[workflow qualification](../releases/2.11.0/workflow-qualification.md),
[performance contract](../releases/2.11.0/performance-evidence.json), and
[support matrix](support.md). The [historical 1.9.9 provenance audit](../releases/1.9.9/provenance-audit.md)
remains frozen evidence for its own baseline; new numerical families carry
their own cited provenance and validation in the current release.
