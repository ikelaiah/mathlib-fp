### Added

- Added expanding-window and fixed-width rolling-window validation splits
  with explicit training sizes, horizons, steps and row gaps.
- Added a deterministic future-holdout PLS workflow and hand-enumerated tests
  for chronology, overlapping horizons, omitted partial windows and failures.

### Compatibility

- Existing seeded split and PLS paths remain available. Chronological builders
  use caller row order and no random state; gaps measure rows, not durations.
