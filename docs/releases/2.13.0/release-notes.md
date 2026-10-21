### Added

- Added nonnegative integer GLM frequency weights, including offset/exposure fits, without expanding the replicated dataset.
- Added checked observation totals, frequency-based information, deviance, null deviance, Pearson statistics and degrees of freedom, plus explicit positive-weight diagnostic row mapping.
- Added replicated-data tests for both families, zero-weight rank/separation and count overflow, and a repeated-observation workflow.

### Compatibility

- Nil weights preserve unit-weight behavior. Frequency weights are training inputs and are not required for prediction; fractional, analytic and survey weights remain outside the contract.
