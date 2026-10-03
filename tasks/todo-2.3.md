# 2.3 Stiff and Implicit ODEs

Implementation checklist for [spec-2.3.md](spec-2.3.md), ordered by
[plan-2.3.md](plan-2.3.md). The selected method and API are implemented; review
and release qualification remain in progress.

## 1. Contract and numerical design

- [x] Select the Alexander two-stage, second-order SDIRK method and cite its
  primary algorithm source.
- [x] Freeze public entry point, options/result types, callback signatures,
  tolerance norm, statuses, diagnostics, and validation behavior.
- [x] Specify analytic, automatic, and numerical Jacobian paths, including
  scaling, refresh/reuse, evaluation counts, and failures.
- [x] Decide cubic-Hermite dense output and directional event support.
- [x] Select the sourced Robertson reference and closed-form forced stiff
  problem with endpoint and interpolation budgets.

**Acceptance:** the spec and source expose one consistent method/API, with
independent reference values and fixed numerical budgets.

## 2. Reference data and tests

- [x] Add a closed-form forced stiff scalar fixture and verify that tighter
  tolerances reduce its endpoint error.
- [x] Add the sourced Robertson benchmark equations and reference values.
- [x] Add focused tests for callback contracts, dimensions, finite values,
  integration direction, tolerance validation, and result ownership.
- [x] Add separate coverage for each Jacobian mode and its diagnostics.
- [x] Add error/failure tests for nonlinear convergence, step limits, and
  non-finite callback output.

**Acceptance:** reference data are independent of the Pascal solver; focused
tests distinguish invalid input, numerical failure, and convergence.

## 3. Solver implementation

- [x] Implement and verify one implicit step for the selected method.
- [x] Add bounded nonlinear solves, dense linear algebra, Jacobian scaling,
  and documented refresh/reuse behavior.
- [x] Add adaptive step/order control and the accepted local-error norm.
- [x] Return trajectory and work diagnostics with stable status semantics.
- [x] Add cubic-Hermite dense output and directional event location.
- [x] Ensure caller inputs and earlier result values remain unchanged by later
  calls.
- [x] Check nested stiff-solver reentrancy from a derivative callback.

**Acceptance:** stiff reference problems meet the frozen budgets; tighter
tolerances improve measured error; failures never return a converged result.

## 4. Documentation and qualification

- [x] Add a complete stiff ODE example and output contract.
- [x] Update the modelling guide, capability inventory, and changelog.
- [x] Run the focused and full FPCUnit suites, compile all examples, verify
  output contracts, and check source and generated documentation on Windows.
- [x] Review the public API and numerical claims against the design and
  reference evidence.
- [ ] Pass Linux and Windows CI and complete release qualification before
  merge.

**Acceptance:** documentation matches the shipped API and limitations; all
required release gates pass before merge.
