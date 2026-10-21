### Added

- Added explicit training/validation row-set validation, deterministic grouped
  and stratified split builders, and PLS component selection on supplied splits.
- PLS reports pooled and per-split RMSE with scored row counts. A grouped
  workflow compares PLS and ordinary least squares on an untouched outer group.

### Compatibility

- Existing seeded holdout, K-fold assignments, and default PLS fit behavior
  remain available. New split builders use local random state.

### Documentation

- Updated model-selection guidance, API, examples, capability inventory,
  and qualification evidence for v2.10.0.
