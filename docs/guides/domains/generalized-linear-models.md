# Logistic and Poisson regression

`StatsLib.GLM` fits a binary outcome with a Bernoulli logit model or an integer
count with a Poisson log model. Both use real-double typed dense designs and
return coefficients, fitted means, standard errors and model diagnostics.
Check `Status = glsConverged` and `Identifiable` before interpreting a fit.

## Choose a model

| Response | Entry point | Link and mean | Assumptions |
| --- | --- | --- | --- |
| Continuous real measurement | `TInferenceKit.FitOLS` | Linear conditional mean | OLS residual assumptions for inference |
| Individual binary observation, exactly 0 or 1 | `TGLMKit.FitLogistic` | `log(p/(1-p)) = X*beta + offset` | Independent Bernoulli observations |
| Nonnegative integer count | `TGLMKit.FitPoisson` | `log(mean) = X*beta + offset + ln(exposure)` | Independent counts with conditional variance equal to mean |

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

### Known offsets and exposure

Initialize `TGLMInputs.Default` and set `Offsets` and/or `Exposures` before
calling `FitLogistic(Design, Response, Inputs)` or `FitPoisson(Design, Response,
Inputs)`. Both also accept a final `TGLMOptions`. Each nonempty input array
must match design rows. Offsets are finite known additions to the linear
predictor with coefficient fixed at one. Positive finite exposure is Poisson
only; its logarithm is added to the predictor. Both may be supplied together.
Empty arrays mean zero offset and unit exposure. Invalid inputs raise
`EGLMError` before fitting, including exposure on a logistic fit.

`UsesOffsets` and `UsesExposure` record the supplied input kinds. Use
`PredictMean(Fit, NewDesign, NewInputs)` with the same kinds on the new rows;
missing or unexpected kinds fail, even when training used zeros or units.
Training values are never reused. Prediction returns expected counts for a
Poisson model. Dividing by new-row exposure gives a rate; any offset effect
remains in that rate. [Example 49](../../../examples/49_count_rates.pas) fits
unequal exposure and predicts a count and rate at a new exposure.

Null deviance uses a fitted free intercept with the same known offsets and
exposures, even when the full design has no intercept. It is therefore not
generally a constant count mean. The Poisson null rate is total count divided
by total effective exposure; the Bernoulli null intercept solves its monotone
score equation. Numerical failure to represent that diagnostic is explicit.

### Integer frequency weights

Set `Inputs.FrequencyWeights` to a `TGLMFrequencyWeights` array of nonnegative
integer counts. A count means independent row replication, including its
response, offset and exposure. Nil means unit weights; zero excludes a row from
estimation and diagnostics. All stored input values must still satisfy their
domain/finite checks. The positive total is at most
`GLM_MAX_FREQUENCY_COUNT` (2,147,483,647 on every target); invalid lengths, zero
total or count overflow raise `EGLMError`. Fitting never allocates the expanded
replicated dataset. Working memory depends on stored rows.

`FrequencyCount` is the total observation count. With explicit weights,
`DiagnosticRows` maps the positive-weight stored rows to `FittedMeans`,
`ResponseResiduals` and `DevianceResiduals`, in original row order. Response
residuals remain y minus mean; deviance residuals include the square root of
frequency so their squares sum to total deviance. Nil weights leave
`DiagnosticRows` empty and preserve the full-row result arrays. Standard errors,
null deviance, Pearson statistics and residual degrees of freedom use the
replicated-data interpretation. Zero-weight rows cannot supply rank or prevent
separation. These counts are not fractional/analytic, survey or importance weights.

Weights are training inputs: prediction rejects nonempty new-row frequency
weights and requires only the fitted offset/exposure kinds.
[Example 50](../../../examples/50_frequency_weighted_glm.pas) stores three rows
representing six observations and checks prediction against explicit replication.

Use `TGLMOptions.Default` before changing options:

| Field | Default | Meaning |
| --- | --- | --- |
| `MaxIterations` | 100 | 1 through 10,000 IRLS iterations |
| `Tolerance` | 1e-8 | Relative deviance, unhalved normalized coefficient and linear-predictor corrections; finite, greater than 0 and at most 0.01 |
| `RankTolerance` | 1e-12 | Equivalent replicated-design absolute QR cutoff, adjusted for maximum-root normalization; unit weights use this value times `sqrt(rows)`; finite, strictly between 0 and 1 |
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
a tiny backtracking step alone cannot signal success. No fractional/analytic
weights, grouped-binomial trials, regularization or additional families
are implemented in this release.

## Result and failure interpretation

`TGLMFitResult` contains `Family`, `Status`, `Message`, `Iterations`, `Rank`,
`DegreesOfFreedom`, `ConditionIndicator`, `Identifiable`, `HasFiniteIterate`,
`UsesOffsets`, `UsesExposure`,
`FrequencyCount`, `DiagnosticRows`,
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
degrees of freedom are total frequency minus that rank. Standard errors are
computed from the final expected information, with column permutations and
predictor units restored. Failed fits have empty `StandardErrors` and
`Identifiable = False`; prediction rejects them.

Response residuals are observed minus fitted mean. Signed deviance residual
squares sum to deviance. Without known offsets/exposure, `NullDeviance` compares
with a constant mean even when the supplied design has no intercept. History contains the initial objective
and each accepted step, with the stated roundoff allowance.

The separation search produces a strict certificate when an IRLS iterate
separates every row using the fitted `X*beta` direction, excluding fixed offsets.
It is not an exhaustive linear-programming test;
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

## Portable prediction

`TGLMKit.ToPredictionModel(Fit)` validates a converged, identifiable fit and
returns owned `TGLMPredictionModel` coefficients, family and offset/exposure
requirements. `PredictMean` accepts that record with the same new-row contract.
Optional [prediction persistence](interchange.md#selected-model-persistence)
saves this record without training rows, frequency weights or fit diagnostics.

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
