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

PR [#59](https://github.com/ikelaiah/mathlib-fp/pull/59) passed Linux and
Windows CI on its release commit. The full checksummed clean-archive
qualification also passed on both platforms; Linux ran with outbound
connections blocked, and Windows built the Lazarus package for Win32 and
Win64. Run and artifact details are in the
[qualification record](qualification.md).
