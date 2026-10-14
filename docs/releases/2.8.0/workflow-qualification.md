# v2.8.0 workflow qualification

The runnable [PLS workflow](../../../examples/45_partial_least_squares.pas)
creates three correlated predictors from two latent directions, fits one
continuous response, selects components with deterministic five-fold
cross-validation, and predicts a new observation.

Its checked output selects two components, reports pooled RMSECV `5.126896`,
`2.263450`, and `0.000000` for zero, one, and two components, and predicts
`5.275000`. The full example suite and output contracts are recorded in
[`qualification.md`](qualification.md) after release qualification.
