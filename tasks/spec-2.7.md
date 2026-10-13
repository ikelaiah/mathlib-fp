# Specification: v2.7.0 generalized linear models

## Objective and scope

Complete the Statistics II roadmap gate with native real-double Bernoulli
logistic regression (logit link) and Poisson regression (log link). Users can
fit binary outcomes or integer counts, inspect failure and convergence,
interpret model diagnostics, and predict from the same typed dense design.
No foreign numerical runtime is required. Existing inference APIs stay source
compatible. Weights, offsets/exposure, grouped binomial trials, regularization,
robust covariance, and other GLM families remain future work.

## Public contract

Add the focused `StatsLib.GLM` unit with `EGLMError`, `TGLMFamily`,
`TGLMStatus`, `TGLMOptions`, `TGLMFitResult`, and `TGLMKit`.
`FitLogistic` and `FitPoisson` each have a simple overload and an options
overload accepting `IDenseDoubleMatrix` and `TDoubleArray` responses.
`PredictMean` accepts a converged result and another compatible design.
`TGLMOptions.Default` supplies 100 iterations, 1e-8 convergence tolerance,
1e-12 relative rank tolerance, and 1e-10 minimum QR condition indicator.

Designs are zero-indexed: rows are observations, columns are coefficients.
Callers include a constant column when an intercept is wanted. Fit requires
at least one column and at least as many rows as columns. All design and
response values must be finite; logistic responses are exactly 0 or 1;
Poisson responses are nonnegative integer-valued doubles. Invalid requests
raise `EGLMError` before fitting. No automatic omission or imputation occurs.

Fits never mutate or retain the design or response. Result arrays are freshly
allocated; copying a result record follows ordinary Pascal dynamic-array
aliasing rules, so callers use `Copy` before editing a copied array. There is
no hidden mutable state. Standard errors are present only for a converged,
identifiable fit and use the inverse expected information with dispersion 1.
Prediction validates the entire design and returns fresh storage; it rejects
nonconverged results and nonrepresentable inverse-link results.

Results expose family, status, message, iteration count, numerical rank,
condition indicator, identifiable flag, coefficients, fitted means, response
and signed deviance residuals, standard errors, deviance, null deviance,
Pearson chi-square, residual degrees of freedom, and accepted deviance history.
Null deviance is the constant-mean comparator even for a design without an
intercept. Degrees of freedom are observations minus numerical rank.

## Numerical and failure behavior

Use IRLS/Newton corrections solved with the existing column-pivoted QR,
not normal equations. Normalize predictor columns and weighted systems;
map coefficients and standard errors back to original units. The reported
condition indicator is the QR minimum/maximum accepted diagonal ratio,
not a rigorous reciprocal condition number. Rank/conditioning failure is
explicit, and minimum-norm substitution is never silently accepted.

Evaluate logistic loss through stable softplus expressions and Poisson loss
through the log link. Backtracking accepts only finite non-increasing
deviance, with at most 40 halvings per IRLS step. Convergence requires both
relative deviance and scaled coefficient change. Iteration limits and stalled
steps are explicit results. Numerical overflow becomes numerical failure with
the last finite iterate rather than false convergence.

Any logistic iterate with strictly positive signed margins for every row is
a complete-separation certificate and returns separation status. This is a
certificate search, not an exhaustive linear-programming separation test;
undetected separation or quasi-separation may return boundary, rank,
conditioning, or iteration failure. Fits reaching logistic |eta| >= 36 or
Poisson |eta| >= 700 return boundary status before convergence: the finite
double information is no longer reliably estimable. An all-zero Poisson
response with a strictly negative fitted linear predictor on every row also
certifies a boundary MLE. Standard errors and prediction are unavailable for
all failed fits. Accepted finite means/residuals/deviance remain diagnostic
last-iterate values, not an estimated finite MLE.

## Structure, style and verification

Source belongs in `src/StatsLib.GLM.pas`, FPCUnit behavior tests in
`tests/TestGLM.pas`, standard-library Decimal fixtures in
`tools/generate_glm_reference.py` and `tests/GLMReference.inc`, and a complete
workflow in `examples/44_generalized_linear_models.pas`. Follow the adjacent
advanced-record and Kit static-method style; use explicit operation errors.

Focused build/run (PowerShell, create output directories first):

```powershell
fpc -B -FcUTF8 -Fusrc -Futests -FUbuild-temp/glm/units -FEbuild-temp/glm tests/TestRunner.lpr
build-temp/glm/TestRunner.exe --suite=TGLMTest --format=plain
python tools/generate_glm_reference.py --check
```

Independent high-precision fixtures use Decimal Newton normal equations and
Gaussian elimination, deliberately distinct from portable binary64 QR IRLS.
Validate coefficients, fitted means, standard errors, deviance and Pearson
statistics; add analytic intercept/group identities and adversarial rank,
separation, quasi-separation, extreme-scale, finite-input and failure tests.

Run full local release qualification:
`python tools/qualify_release.py --release 2.7.0 --compiler fpc`.
Also require exact-commit Linux/Windows CI, Win64/Win32 package consumers,
offline checksummed clean-archive qualification, and built documentation.

## Documentation and publication

Before tagging update the API snapshot/reference, capability inventory,
statistics/model-selection/task guides, example catalogue/output contract,
numerical provenance/evidence, support and security policy, roadmap,
release index, version/package metadata, README, CHANGELOG, and qualification
records. Closed historical evidence is immutable. Merge reviewed code and
docs through PRs, qualify the final main commit, then annotate `v2.7.0` and
publish `mathlib-fp 2.7.0`. The release body contains only changelog entries,
starting with `### Added`, without the release title. Verify downloaded
source and offline docs, checksums, attached assets, and deployed site.

## References

- R's documented GLM/IWLS contract:
  <https://stat.ethz.ch/R-manual/R-patched/library/stats/html/glm.html>.
- Canonical links, family variance and deviance definitions:
  <https://www.statsmodels.org/stable/glm.html>.
- Independent implementation is repository-authored Pascal; cited packages
  are mathematical references, not runtime or build dependencies.
