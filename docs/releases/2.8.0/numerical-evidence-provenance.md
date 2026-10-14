# v2.8.0 PLS numerical provenance

The [current catalogue](numerical-evidence.json) carries forward the six
qualified algorithm-family records from v2.7.0 and adds
`partial_least_squares_regression`. Production uses binary64 PLS1 sequential
predictor/response deflation, two-pass score re-orthogonalization, and rotation
weights for coefficient reconstruction. It does not form covariance inverses
or normal equations.

The repository-authored MIT [reference generator](../../../tools/generate_pls_reference.py)
uses Python's standard-library Decimal at 80-digit precision. It independently
evaluates the PLS1 equations, computes original-unit coefficients, and scores
five fixed-seed folds using preprocessing fitted on each training partition.
The generated [fixture](../../../tests/PLSReference.inc) checks intercept,
three coefficients, and pooled RMSECV for the mean-only model and two
components. Regenerate with `python tools/generate_pls_reference.py` and verify
with `--check`; no third-party Python package is needed.

The [focused FPCUnit suite](../../../tests/TestPLS.pas) adds exact linear
identities, strongly correlated and rank-deficient designs, constant inputs
and responses, reproducible folds, prediction, missing/non-finite rejection,
component bounds, shape validation, and input ownership checks. The runnable
[example](../../../examples/45_partial_least_squares.pas) exercises the same
two-latent-direction case.

The algorithm and prediction contract are informed by Wold, Sjöström and
Eriksson's [PLS-regression review](https://doi.org/10.1016/S0169-7439(01)00155-1)
and the numerical-stability study by Björck et al.
[doi:10.1002/cem.2898](https://doi.org/10.1002/cem.2898). Component selection
uses held-out pooled RMSECV, a common model-complexity criterion discussed by
Denham, [doi:10.1002/1099-128X(200007/08)14:4%3C351%3AAID-CEM598%3E3.0.CO%3B2-Q](https://doi.org/10.1002/1099-128X(200007/08)14:4%3C351%3AAID-CEM598%3E3.0.CO%3B2-Q).
These are mathematical references; the implementation and runtime are native
Free Pascal.
