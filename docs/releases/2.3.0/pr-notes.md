# 2.3.0 release review notes

PR [#58](https://github.com/ikelaiah/mathlib-fp/pull/58) added the stiff ODE
solver and merged into `main` as
[`b0f8d71`](https://github.com/ikelaiah/mathlib-fp/commit/b0f8d71e73cc8a50d95b92698dc1e84b820df42d).
The change preserves the published 2.2.0 API snapshot and adds a versioned
2.3.0 API reference.

Linux CI exposed a nonlinear Newton branch failure on the Robertson reference
problem. The stage solve now refreshes its Jacobian and backtracks until the
scaled implicit residual decreases. Linux and Windows CI both pass on the
merged feature commit.

The remaining release gate is the 2.3.0 checksummed clean-archive qualification
on `release/2.3.0`. This note will link the run and artifacts after that gate
passes.
