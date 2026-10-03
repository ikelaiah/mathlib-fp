# mathlib-fp 2.3.0

Version 2.3.0 adds adaptive stiff initial-value integration to the numerical
modelling toolkit.

## Added

- `TModellingKit.SolveStiffODE`, an adaptive Alexander two-stage SDIRK2 solver
  with component-scaled error control.
- Analytic, forward-mode automatic, and finite-difference Jacobian modes, with
  Newton convergence and evaluation diagnostics.
- Cubic-Hermite dense output, backward integration, directional event
  detection, and accepted/rejected step counts.
- A runnable Robertson and forced-stiff example, plus numerical reference and
  event tests.

The existing explicit `SolveODE` API is unchanged. The new solver supports
dense real-double systems in explicit form `y' = f(t, y)`. It does not provide
mass-matrix systems, DAEs, PDEs, or sparse and large-scale stiff solves.

The checksummed clean-archive qualification record is available in the
[qualification report](qualification.md) and
[workflow evidence](workflow-qualification.md).
