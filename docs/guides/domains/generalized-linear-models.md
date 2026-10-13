# Logistic and Poisson regression

`StatsLib.GLM` fits a binary outcome with a Bernoulli logit model or an integer
count with a Poisson log model. Both use real-double typed dense designs and
return coefficients, fitted means, standard errors and model diagnostics.
Check `Status = glsConverged` and `Identifiable` before interpreting a fit.

## Choose a model

| Response | Entry point | Link and mean | Assumptions |
| --- | --- | --- | --- |
| Continuous real measurement | `TInferenceKit.FitOLS` | Linear conditional mean | OLS residual assumptions for inference |
| Individual binary observation, exactly 0 or 1 | `TGLMKit.FitLogistic` | `log(p/(1-p)) = X*beta` | Independent Bernoulli observations |
| Nonnegative integer count | `TGLMKit.FitPoisson` | `log(mean) = X*beta` | Independent counts with conditional variance equal to mean |

A Poisson model may fit a count mean while understating uncertainty when data
are overdispersed. Inspect `PearsonChiSquare / DegreesOfFreedom` when degrees
of freedom are positive; this is a diagnostic, not an automatic model test or
dispersion correction. Supplied standard errors fix dispersion at 1 for both
families. Causal interpretation requires a suitable study design.

## First fit

Rows are observations and columns are coefficients. Include a column of ones
when you want an intercept; the library does not insert one.

```pascal
uses SysUtils, MathBase.SharedTypes, AlgebraLib.DenseMatrices, StatsLib.GLM;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult;
begin
  X := TDenseDoubleMatrix.FromValues(4, 1, [1,1,1,1]);
  Fit := TGLMKit.FitLogistic(X, TDoubleArray.Create(0,1,1,1));
  if not Fit.Identifiable then raise Exception.Create(Fit.Message);
  Writeln('log odds: ', Fit.Coefficients[0]:0:6);
  Fit := TGLMKit.FitPoisson(X, TDoubleArray.Create(0,1,2,5));
  if not Fit.Identifiable then raise Exception.Create(Fit.Message);
  Writeln('mean count: ', Fit.FittedMeans[0]:0:6);
end.
```

Expected output:

```text
log odds: 1.098612
mean count: 2.000000
```

The [complete GLM workflow](../../../examples/44_generalized_linear_models.pas)
fits slopes, compares deviance with the constant-mean model, predicts new
counts and handles a complete-separation certificate.

## API and input contract

`TGLMFamily` contains `gfBernoulliLogit` and `gfPoissonLog`. `TGLMKit` has
`FitLogistic(Design, Response)` and `FitPoisson(Design, Response)`, plus
overloads accepting `TGLMOptions`. `PredictMean(Fit, Design)` returns
probabilities or expected counts for a compatible prediction design.

Use `TGLMOptions.Default` before changing options:

| Field | Default | Meaning |
| --- | --- | --- |
| `MaxIterations` | 100 | 1 through 10,000 IRLS iterations |
| `Tolerance` | 1e-8 | Relative deviance, unhalved normalized coefficient and linear-predictor corrections; finite, greater than 0 and at most 0.01 |
| `RankTolerance` | 1e-12 | Absolute QR cutoff is this value times `sqrt(rows)` on normalized weighted design; finite, strictly between 0 and 1 |
| `MinimumConditionIndicator` | 1e-10 | Minimum accepted QR diagonal ratio; finite, greater than 0 and at most 1 |

Fit requires a nonnil design with at least one column, at least as many rows
as columns, a response per row, and finite values throughout. Responses must
be exactly binary or nonnegative integer-valued doubles as appropriate.
Missing values, fractional Poisson counts, invalid options and incompatible
shapes raise `EGLMError`. Fit accepts strided matrix views and leaves caller
storage unchanged. A prediction design can have zero rows and must have the
same number of columns as the fitted coefficient vector.

The unit uses existing column-pivoted QR to solve IRLS corrections, scales
predictor columns, and checks every accepted objective. The shared QR
temporarily materializes a full Q matrix, so
working memory is O(rows^2 + rows*columns + columns^2); use this baseline for
moderate dense data. Up to 40 step halvings
are allowed. An increase of at most 8 binary64 epsilons times `1 + deviance`
is treated as summation roundoff. The unhalved correction must be small before
convergence, and the unhalved linear-predictor correction must also be small;
a tiny backtracking step alone cannot signal success. No weights,
offset/exposure, grouped-binomial trials, regularization or additional families
are implemented in this release.

## Result and failure interpretation

`TGLMFitResult` contains `Family`, `Status`, `Message`, `Iterations`, `Rank`,
`DegreesOfFreedom`, `ConditionIndicator`, `Identifiable`, `HasFiniteIterate`,
`Coefficients`, `StandardErrors`, `FittedMeans`, `ResponseResiduals`,
`DevianceResiduals`, `Deviance`, `NullDeviance`, `PearsonChiSquare` and
`DevianceHistory`.

| `TGLMStatus` | Interpretation |
| --- | --- |
| `glsConverged` | Full-rank information passed the requested condition threshold and stopping criteria |
| `glsIterationLimit` | The iteration budget was exhausted |
| `glsRankDeficient` | The design or final/iterative weighted information lost numerical rank |
| `glsIllConditioned` | Full rank, but the normalized QR diagonal ratio is below the requested minimum |
| `glsCompleteSeparation` | Strict signed margins for every binary row certify that the finite logistic MLE does not exist |
| `glsBoundary` | An all-zero Poisson recession certificate or the inverse-link information boundary was reached |
| `glsNumericalFailure` | An intermediate, coefficient or diagnostic could not be represented |
| `glsStalled` | Backtracking found no acceptable finite step |

`ConditionIndicator` is the minimum/maximum accepted QR diagonal ratio of the
normalized weighted design. It is an indicator, not a rigorous reciprocal
condition number. `Rank` describes the last factored information, and residual
degrees of freedom are observation count minus that rank. Standard errors are
computed from the final expected information, with column permutations and
predictor units restored. Failed fits have empty `StandardErrors` and
`Identifiable = False`; prediction rejects them.

Response residuals are observed minus fitted mean. Signed deviance residual
squares sum to deviance. `NullDeviance` compares with a constant mean even when
the supplied design has no intercept. History contains the initial objective
and each accepted step, with the stated roundoff allowance.

The separation search produces a strict certificate when an IRLS iterate
separates every row. It is not an exhaustive linear-programming test;
quasi-separation or other undetected separation can instead end at a rank,
condition, boundary or iteration failure. Logistic fits stop at `abs(eta) >= 36`
and Poisson fits at `abs(eta) >= 700` before declaring convergence. These
limits protect finite-double information estimation. Single-class data can
have a finite fit when the design omits an intercept, so they are not rejected
solely because one class is missing.

Failed results with `HasFiniteIterate = True` retain the last finite
coefficients, means and deviance history as diagnostics. A numerical failure
clears residuals and uses zero placeholders for unavailable null/Pearson
statistics. When even the initial objective is not representable,
`HasFiniteIterate = False`, mean/history arrays are empty and unavailable
statistics are zero. None of these failure values is a finite MLE.

All returned arrays are freshly owned and inputs are not retained. Ordinary
Pascal record assignment aliases dynamic arrays; use `Copy` before editing an
array in a copied result. Separate fits and predictions share no mutable
global state. Prediction returns a fresh array, handles large finite logits
as probabilities rounded to 0 or 1. Poisson predictions require
`abs(eta) <= 700`, matching the bounded inverse-link evaluation domain.
An unsupported inverse-link domain or nonrepresentable linear predictor raises
`EGLMError`.

## Numerical evidence and compatibility

Six independent 90-digit Decimal reference fits cover both families,
intercepts, multiple predictors and unequal predictor units. Tests compare
coefficients and standard errors with a 2e-8 absolute/relative budget, means
with 2e-9 absolute/relative, and deviance/Pearson statistics with 2e-8 absolute
error. These are validated fixture budgets, not a guarantee for arbitrary
ill-conditioned data. Analytic and adversarial tests cover information,
residuals, boundaries, separation, ownership, row order and extreme units.
See the [numerical provenance](../../releases/2.7.0/numerical-evidence-provenance.md).

`TInferenceKit.FitLogistic` remains available with its existing integer-label
signature and behavior. The new unit provides the explicit GLM family and
failure workflow; no existing call is reinterpreted or deprecated.

Family and link definitions are described in the
[statsmodels GLM reference](https://www.statsmodels.org/stable/glm.html), and
IRLS behavior in the [R GLM documentation](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/glm.html).
The production Pascal implementation and Decimal fixtures are independently
authored and MIT licensed.
