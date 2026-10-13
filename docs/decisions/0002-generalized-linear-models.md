# ADR-0002: Diagnosed canonical-link generalized linear models

## Status

Accepted

## Date

2026-10-14

## Context

The Statistics II roadmap calls for binary and count regression with explicit
convergence/failure diagnostics. Existing `TInferenceKit.FitLogistic` has a
retained integer-label result contract and shares a broad inference unit.

## Decision

Add a focused `StatsLib.GLM` unit for Bernoulli logit and Poisson log models,
with explicit options/results and compatible typed dense input. Reuse the
existing pivoted QR on scaled designs, solve Newton corrections through IRLS,
backtrack by deviance, and require a small unhalved correction for convergence.
Compute standard errors from the final information. Certify complete
separation only when a strict separating iterate is found; report numerical
and information boundaries separately from convergence.

Use independent 90-digit Decimal Newton normal equations for development
fixtures, so validation does not reuse the production QR implementation.
The standard test path consumes checked-in values and has no foreign runtime.

## Alternatives considered

Extending the existing logistic result would mix the legacy contract with
new family and failure rules. Normal equations in production would square
conditioning. A generic link/family callback framework or an exhaustive LP
separation classifier would expand this bounded baseline substantially.

## Consequences

Existing APIs retain their semantics. The new workflow has clear ownership,
prediction and failure behavior. Unsupported weights, offsets, grouped
binomial outcomes, regularization and other families are documented. No
performance or exhaustive separation-detection claim is made.
