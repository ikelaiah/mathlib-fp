# v2.8.0 Data Analysis II specification

## Outcome

Add an approachable partial least squares regression workflow for one
continuous response and a row-major matrix of correlated predictors. The
default entry point fits a model and selects its component count with seeded
cross-validation. It returns coefficients on the caller's original predictor
scale and predicts directly from new rows.

This is the PLS1 regression case. Multi-response PLS2, classification,
missing-value estimation, sparse/streaming matrices, VIP scores, uncertainty
estimates, and robust PLS are outside this release.

## Public API and data contract

Add `MLLib.PLS`, reusing `MLLib.MachineLearning.TDoubleMatrix` and
`MathBase.SharedTypes.TDoubleArray`:

- `TPLSOptions.Default`, with automatic component cap (`MaxComponents=0`),
  automatic fold count (`Folds=0`), deterministic `Seed=1729`, predictor
  scaling enabled, and relative rank tolerance `1e-12`.
- `TPLSKit.Fit(X, Y)` and `Fit(X, Y, Options)`.
- `TPLSKit.Predict(Model, XNew)`.
- `TPLSModel`, containing original-scale coefficients and intercept, predictor
  means/scales, selected component count, full predictor numerical rank,
  cross-validation RMSE by component count, actual fold count and seed, and a
  `TPLSStatus` (`plsConverged` or `plsMeanOnly`).
- `EPLSError` for invalid shapes/options, non-finite values, numerical range
  failures, or a manually requested component cap above the full-data rank.

Rows are observations and columns are predictors. Inputs require at least 3
observations, at least 1 predictor, matching response length, rectangular
rows, and finite values. No input is mutated or retained. `Predict` validates
the model shape and all new predictor values and returns a fresh array.
Returned dynamic arrays follow ordinary Pascal aliasing when a model record is
copied; callers use `Copy` before editing an array from a copied record.

Predictors are centered and, by default, divided by their sample standard
deviation. With scaling disabled they are centered only. Constant predictor
columns are retained in the coefficient shape with coefficient zero and do
not contribute to numerical rank. The response is centered and scaled
internally for arithmetic, then the final coefficients and intercept are
mapped to original units. A constant response is a valid mean-only model.

The full-data numerical rank is measured on the centered/scaled predictor
matrix with two-pass modified Gram-Schmidt and the requested relative rank
tolerance. `MaxComponents=0` uses that rank. A positive maximum above that
rank raises `EPLSError`. The algorithm may stop earlier if the remaining
response/predictor covariance is numerically zero; the returned status and
component count then describe the available predictive model.

## Fitting and model selection

Use univariate NIPALS PLS regression with sequential predictor and response
deflation. Each predictor weight is the normalized cross-product of the
current predictor residual with the current response residual. Compute score
and loadings, re-orthogonalize scores twice, and accumulate rotation weights
so coefficient reconstruction remains in the original predictor coordinates.
No covariance inverse or normal equations are used. Keep row-major dense
storage and no global random state.

Cross-validation shuffles observation indexes with a local fixed-width
generator and assigns them round-robin to folds. `Folds=0` uses
`min(5, N-1)`; otherwise valid values are 2 through N-1. Every observation is
held out once. Each fold recomputes centering/scaling and PLS components from
its training rows only. Report pooled RMSECV at component counts 0 through the
largest count available in every fold; count zero is the per-fold training
mean baseline. Select the smallest count attaining the lowest RMSECV. The
random fold scheme assumes exchangeable rows; it is not time-series or
group-aware validation.

## Verification and documentation

Add analytic identities, an independent standard-library Decimal reference
generator/corpus, correlated-predictor examples, and failure/ownership tests.
The reference generator uses high-precision arithmetic and explicit fixture
folds, separate from the production fold generator.

Before tagging, update the machine-learning/domain and task guides, example
catalogue/output contract, current API snapshot/reference, capability
inventory, evidence/provenance, roadmap, package/version metadata, README,
CHANGELOG, release index, support/security docs where needed, and qualification
records. All existing examples and the new PLS example must compile and run
from a clean checkout and release archive. Historical release evidence stays
unchanged.

## References

- Wold, Sjöström and Eriksson, “PLS-regression: a basic tool of chemometrics,”
  *Chemometrics and Intelligent Laboratory Systems* 58 (2001), 109–130,
  [doi:10.1016/S0169-7439(01)00155-1](https://doi.org/10.1016/S0169-7439(01)00155-1).
- Björck et al., “Fast and stable partial least squares modelling: A benchmark
  study with theoretical comments,” *Journal of Chemometrics* (2017),
  [doi:10.1002/cem.2898](https://doi.org/10.1002/cem.2898).
- Denham, “Choosing the number of factors in partial least squares regression:
  estimating and minimizing the mean squared error of prediction,”
  *Journal of Chemometrics* 14 (2000), 351–361,
  [doi:10.1002/1099-128X(200007/08)14:4<351::AID-CEM598>3.0.CO;2-Q](https://doi.org/10.1002/1099-128X(200007/08)14:4%3C351%3A%3AAID-CEM598%3E3.0.CO%3B2-Q).
