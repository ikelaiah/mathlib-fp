### Added

- Added known additive offsets for Bernoulli-logit and Poisson-log GLMs, and positive Poisson exposure through its logarithm.
- Added explicit new-row prediction inputs and fitted input-kind flags, offset-aware null deviance and analytic count-rate and logistic fixtures.
- Added a count-rate workflow explaining expected counts versus rates and required deployment exposure.

### Compatibility

- Existing unadjusted calls and independent GLM fixtures remain available. Simultaneous offset/exposure is allowed; no training inputs are retained or reused for prediction.
