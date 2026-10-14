# ADR 0003: A focused PLS1 regression workflow

- **Status:** Accepted for v2.8.0.
- **Date:** 2026-10-14.
- **Decision owners:** mathlib-fp maintainers.

## Context

The roadmap assigns v2.8.0 a PLS regression workflow for correlated
multivariate predictors, including component selection and cross-validation.
PLS has several related variants and complex configuration surfaces. The
first stable API should solve one common workflow without exposing a large
collection of algorithm switches.

## Decision

Ship dense, real-double PLS1 for one continuous response in `MLLib.PLS`. Reuse
the existing row-major `TDoubleMatrix`, center and by default sample-scale
predictors, and return original-unit regression coefficients. Use sequential
NIPALS predictor/response deflation with two-pass score re-orthogonalization
and a local seeded shuffle for leakage-free K-fold model selection. Report
RMSECV including the mean-only baseline and select the simplest model attaining
the lowest observed RMSECV.

Constant predictors have zero coefficients and are excluded from numerical
rank. Collinear predictors are handled through rank-limited components. A
component cap above measured rank is a clear input error. Non-finite and
missing values are rejected. Constant responses produce a valid mean-only
model. Inputs are not retained or mutated, and fit/predict use no global
mutable random state.

Multi-response PLS2, incomplete-data algorithms, sparse/streaming variants,
uncertainty and feature-importance statistics, and nonlinear variants remain
outside this release.

## Consequences

The API has a short default path and still exposes the seed, folds, scaling,
rank tolerance, and maximum component count. Cross-validation cost is
approximately proportional to folds times candidate components times dense
data size; the implementation is a moderate in-memory baseline. Fold-based
validation assumes exchangeable rows. Users with temporal, grouped, or
otherwise dependent rows need an external split until a separate contract is
designed.

The method follows the predictive two-block PLS regression literature; the
published references and independent Decimal corpus are recorded in the
[v2.8.0 specification](../../tasks/spec-2.8.md).
