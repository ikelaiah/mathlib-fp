# v2.10.0 numerical and performance provenance

The [numerical catalogue](numerical-evidence.json) carries forward v2.9.0
qualified family records and adds `validation_splits`. The new integer row
membership fixtures are hand-enumerated; the grouped model workflow has the
analytic response `y = 5 + 1.5*t - 0.8*u`, so expected outer-test error is
known independently of PLS and OLS. The implementation and fixtures are
repository-authored Pascal under MIT.

The [performance contract](performance-evidence.json) carries forward the
existing benchmark rows. No split-builder or PLS speedup is claimed.
