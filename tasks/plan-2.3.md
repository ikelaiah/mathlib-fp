# Implementation plan: 2.3 Stiff and Implicit ODEs

## Overview

Add one robust adaptive stiff initial-value solver to
`NumericsLib.Modelling`, using the selected and specified method. The
[v2.3 spec](spec-2.3.md) frames the numerical and API decisions; the roadmap
continues to own release scope. Preserve the existing explicit `SolveODE`
contract and make the new path additive.

## Architecture decisions

- Use Alexander's two-stage, second-order SDIRK formula with
  `γ = 1 - 1/sqrt(2)`. The method is strongly S-stable and tailored to stiff
  ODEs; the primary citation is included in [spec-2.3.md](spec-2.3.md).
- Use its second-order stiffly accurate stage as the accepted value and the
  first stage as an embedded first-order estimate. Control the maximum scaled
  component difference with an order-one step-size exponent.
- Solve each implicit stage with modified Newton iteration, a dense
  `I - γ h J` matrix, and a reusable pivoted LU factorization. Each stage has
  its own Jacobian and factorization.
- Keep the first release in `NumericsLib.Modelling` with dense real-double
  state/Jacobian storage and the repository's modelling error/status style.
- Add the `SolveStiffODE` entry point, options and result records, callback
  types, validation rules, tolerance norm, termination statuses, and
  diagnostics.
- Implement analytic, automatic-differentiation, and finite-difference
  Jacobian paths with explicit mode validation, evaluation counts, and
  per-stage Jacobian/factorization reuse. The automatic path uses a
  time-aware dual callback over the existing `TDual` scalar.
- Qualify cubic-Hermite dense output and directional event location against
  independent endpoint and event-time budgets.
- Keep committed reference data independent and offline. No numerical
  runtime dependency is added.

## Ordered work

### Phase 1: API contract and reference problem selection (complete)

- Freeze the exact public names and callback signatures from
  [spec-2.3.md](spec-2.3.md) before implementation. **Complete.**
- Use the sourced SUNDIALS Robertson reference values at `t=4e10` and the
  closed-form forced stiff scalar case; freeze their endpoint and interpolation
  budgets in tests.

**Checkpoint:** the public API matches the method, error estimate, nonlinear
and linear solve safeguards, Jacobian modes, result statuses, and scope in the
spec. Reference data can be checked without a runtime third-party package.

### Phase 2: Contract tests and callback behavior (in progress)

- Add focused tests for the approved API, dimensions, finite-value validation,
  forward/backward integration, scalar/component tolerances, and ownership.
- Test analytic, automatic, and finite-difference Jacobian routes separately,
  including evaluation accounting and explicit failure behavior.
- Add the closed-form forced stiff scalar problem and load independent
  published coupled-system reference data.

### Phase 3: Implicit step and nonlinear solve (implemented; review pending)

- Implement the selected method's smallest complete implicit step using the
  approved dense linear algebra path.
- Add bounded nonlinear iterations with scale-aware convergence checks,
  Jacobian refresh rules, and actionable breakdown status.
- Verify the step against linear stiff modes and the reference problem before
  adding full adaptive control.

### Phase 4: Adaptive integration and diagnostics (implemented; review pending)

- Add the selected method's startup/order strategy and bounded step-size
  controller, using the approved local-error norm.
- Return accepted trajectory points and independent result storage; report
  accepted/rejected steps, derivative/Jacobian calls, nonlinear iterations,
  and termination status.
- Cover tolerance tightening, state components on different scales, a
  non-stiff comparison with `SolveODE`, and deterministic failure cases.

### Phase 5: Dense output, events, and user guidance (in progress)

- Implement and qualify the selected continuous extension and event location
  if included in the approved contract; otherwise state the limit clearly.
- Add a complete runnable stiff example and explain method/Jacobian choices,
  tolerance interpretation, limitations, and when to use the explicit solver.
- Update the capability inventory and changelog without revising historical
  release snapshots.

### Phase 6: Qualification and release evidence (local gates complete; CI pending)

- Run focused and complete FPCUnit suites, all examples and output contracts,
  and source/generated documentation checks on Windows. **Complete.**
- Review numerical claims against the committed corpus and cite method
  provenance in the guide and design record. **Complete.**
- Pass supported Linux and Windows CI and complete release qualification
  before merge. **Pending.**

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Candidate method is too broad for one release | Compare candidates first and ship one fully qualified method with bounded order/scope. |
| Newton iteration fails on difficult stiffness or poor initial guesses | Bound iterations, use scale-aware residual tests and damping safeguards, and report nonlinear failure distinctly. |
| Jacobian estimates are inaccurate across state scales | Define component scaling, compare all Jacobian modes against independent derivatives, and test strongly unequal state magnitudes. |
| Automatic differentiation does not fit the time-dependent callback | Decide the dual callback shape before coding; keep analytic and finite-difference paths complete independently. |
| Error controller accepts inaccurate stiff transients | Validate local and global errors across stiffness ratios and tighter tolerances against independent references. |
| Dense output or event interpolation is inconsistent with the solver step | Treat it as a qualified design gate; publish only interpolation and event accuracy supported by tests. |
| Dense factorizations limit large state sizes | State the dense-system boundary and measure representative work; route sparse/large-scale work to a later design. |

## Dependencies and likely files

The algorithm and public contract precede implementation. The implicit step
uses the approved Jacobian and dense linear solve contracts; adaptivity follows
the verified step; dense output and events use cubic-Hermite interpolation
from accepted endpoint derivatives.

Likely files include `src/NumericsLib.Modelling.pas`, possibly
`src/NumericsLib.Differentiation.pas`, `tests/TestNumericalModelling.pas`,
reference data/generation files under `tests/`,
`docs/guides/domains/numerical-modelling.md`,
`docs/reference/capabilities.md`, a new example and output contract,
`examples/README.md`, `CHANGELOG.md`, and the v2.3 task/spec files.
