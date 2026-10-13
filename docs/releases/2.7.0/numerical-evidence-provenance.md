# v2.7.0 numerical provenance

The [catalogue](numerical-evidence.json) carries forward the existing
numerical families from 2.6.0 and adds `canonical_generalized_linear_models`.
The production implementation uses scaled binary64 pivoted QR and IRLS.
The repository-authored MIT [reference generator](../../../tools/generate_glm_reference.py)
instead uses 90-digit Python Decimal Newton normal equations and pivoted
Gaussian elimination. It generates coefficients, means, final-information
standard errors, deviance and Pearson chi-square for six small fits.

The checked-in [fixture](../../../tests/GLMReference.inc) has Bernoulli and
Poisson intercept, two-predictor and three-predictor models, plus changed
predictor units. Regenerate with `python tools/generate_glm_reference.py`;
verify with `--check`. No third-party Python package is needed and ordinary
FPCUnit execution reads only the committed literals.

The [focused tests](../../../tests/TestGLM.pas) assert 2e-8 absolute/relative
coefficient/standard-error, 2e-9 mean and 2e-8 absolute deviance/Pearson budgets
on that corpus. Analytic intercept information, signed deviance residuals,
separation, rank/conditioning, quasi-separation, iteration limits, numerical
failure, extreme units, no-intercept cases and strided designs add independent
checks. The mutation gate independently perturbs information scaling,
separation status and rank recognition; these must be detected.

Canonical family/link/deviance definitions are cited from the
[statsmodels GLM reference](https://www.statsmodels.org/stable/glm.html) and
IRLS behavior from the [R documentation](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/glm.html).
Both are development references; all production code is native Pascal.
