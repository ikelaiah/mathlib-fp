# Spec: 2.3 Stiff and Implicit ODEs

**Status:** Method and API selected; implementation and qualification in progress.

## Objective

Add a native, adaptive solver for stiff initial-value problems
`y' = f(t, y)` in real double precision. Users should be able to integrate
stiff systems with component-scaled error control, inspect convergence and
work diagnostics, and choose how the solver obtains the state Jacobian. The
solver extends the existing explicit `SolveODE` workflow without changing its
contract.

Success means at least one stiff method is supported by independent numerical
evidence, clear failure behavior, a runnable example, and guidance that helps
users choose between explicit and stiff integration.

## Frozen design decisions

1. The initial scope is real `Double` systems with a dense state Jacobian and
   caller-provided derivative callbacks, matching the existing modelling API.
2. v2.3 will qualify one method: Alexander's two-stage, second-order,
   singly diagonally implicit Runge-Kutta (SDIRK) method. Supporting additional
   methods requires a separate maintenance case.
3. The API is additive in `NumericsLib.Modelling`, with the public names and
   field layout below; `SolveODE` remains unchanged.
4. The Jacobian policy covers analytic callbacks, automatic differentiation,
   and numerical finite differences. Automatic differentiation uses a new
   time-aware callback over the existing dual-number type.
5. Existing conventions for forward/backward integration, scalar or
   component-wise absolute tolerances, reentrant callbacks, and result status
   should be preserved where the selected method permits.
6. This is a solver for explicit-form ODEs `y'=f(t,y)`. Mass-matrix systems,
   DAEs, PDEs, complex state, and sparse/large-scale Jacobian solvers remain
   outside this gate.

## Frozen numerical contract

- Accept finite `T0`, `T1` with `T0 <> T1`, and a non-empty finite initial
  state. Support either integration direction. Validate derivative and
  Jacobian dimensions and reject non-finite callback values.
- Use the two-stage SDIRK tableau
  `A = [[γ, 0], [1-γ, γ]]`, `b = [1-γ, γ]`, `c = [γ, 1]`, where
  `γ = 1 - 1/sqrt(2)`. This is the strongly S-stable second-order,
  two-stage method derived for stiff ODEs by Alexander. Cite the primary
  source: [Alexander (1977), SIAM Journal on Numerical Analysis,
  DOI 10.1137/0714068](https://doi.org/10.1137/0714068).
- For a step of signed size `h`, solve
  `Y1 = y + γ h f(t + γh, Y1)` and
  `Y2 = y + h(1-γ) f(t + γh, Y1) + γ h f(t+h, Y2)`.
  The accepted second-order value is `Y2` (the method is stiffly accurate).
  Each stage uses bounded modified Newton iteration with a dense real LU
  factorization of `I - γ h J`; form and factor this matrix separately for
  each stage and reuse it during that stage's Newton iterations.
- Use the embedded first-order value `yHat = y + h f(t+γh,Y1)`. Estimate
  error by the maximum component ratio of `Y2-yHat` to
  `atol[i] + rtol * max(abs(y[i]),abs(Y2[i]))`. Accept the second-order value
  when that norm is at most one. Update step size with order-one exponent
  `1/2`, a safety factor, and bounded growth/shrinkage. This conservative
  embedded difference is not claimed to be a direct estimate of the
  second-order method's local truncation error.
- Control error using the maximum component ratio, matching the existing
  explicit solver's rule so a small number of badly scaled components cannot
  be hidden by an RMS average. Accept scalar or component-wise nonnegative
  absolute tolerances, with positive combined scale for every component.
- Define deterministic Jacobian selection and fallback behavior for analytic,
  forward-mode automatic, and scaled finite-difference derivatives. Report
  derivative/Jacobian work in diagnostics. Never silently change derivative
  modes after a callback failure.
- Use at most eight Newton updates per stage by default, with the limit
  configurable. Converge a stage when the maximum scaled Newton correction is
  at most `0.1`; otherwise reject the step and reduce its size. A failed solve
  at minimum step returns numerical breakdown.
- Bound step attempts, nonlinear iterations, and any linear-solver work. A
  successful result must satisfy the requested error test. Limit exhaustion,
  nonlinear failure, singular linear systems, and arithmetic breakdown must
  produce a distinct documented status or modelling exception; partial output
  must never be marked converged.
- Return accepted times and states plus enough diagnostics to explain the
  result, including accepted/rejected steps, derivative/Jacobian evaluations,
  nonlinear iterations, and termination status. Copy or own result storage so
  later solver calls cannot alter earlier results.
- Provide cubic-Hermite dense output from accepted endpoint states and
  derivatives; use that interpolant to localize directional events.
- Keep callbacks synchronous and reentrant, avoid unit-global mutable solver
  state, and do not mutate caller inputs.

## Public API contract

The implemented callback and mode types in `NumericsLib.Modelling` are:

```pascal
TODEJacobianFunction = function(T: Double;
  const Y: TDoubleArray): TModelMatrix;
TODEAutoVectorFunction = function(T: Double;
  const Y: TDualArray): TDualArray;
TStiffODEJacobianMode = (sjmFiniteDifference, sjmAnalytic, sjmAutomatic);

TStiffODEOptions = record
  AbsoluteTolerance: Double;
  AbsoluteTolerances: TDoubleArray;
  RelativeTolerance: Double;
  InitialStep, MinimumStep, MaximumStep: Double;
  MaxSteps, MaxNewtonIterations: Integer;
  NewtonTolerance: Double;
  JacobianMode: TStiffODEJacobianMode;
  Jacobian: TODEJacobianFunction;
  AutoDerivative: TODEAutoVectorFunction;
  Event: TODEEventFunction;
  EventDirection: Integer;
  Progress: TProgressFunction;
  class function Defaults: TStiffODEOptions; static;
end;

TStiffODESolution = record
  T: TDoubleArray;
  Y, Derivatives: TVectorSeries;
  AcceptedSteps, RejectedSteps, Evaluations: Integer;
  JacobianEvaluations, NewtonIterations: Integer;
  EventFound: Boolean;
  EventTime: Double;
  EventState: TDoubleArray;
  Status: TIterationStatus;
  function Evaluate(Time: Double): TDoubleArray;
end;
```

`TStiffODEOptions` contains scalar and per-component absolute tolerances,
relative tolerance, initial/minimum/maximum step, maximum steps, maximum
Newton iterations, Newton correction tolerance, Jacobian mode and the
corresponding analytic or dual callback, event callback/direction, and progress
callback. `Defaults` uses absolute tolerance `1E-9`, relative tolerance
`1E-7`, automatic initial step, minimum step `1E-12`, unbounded maximum step,
100000 steps, eight Newton iterations, Newton correction tolerance `0.1`, and
finite-difference Jacobians. Supplying a Jacobian callback inconsistent with
the selected mode is invalid.

`TStiffODESolution` returns accepted `T`, `Y`, and endpoint `Derivatives`,
accepted/rejected step counts, derivative/Jacobian/Newton counts, event fields,
and `TIterationStatus`. Its `Evaluate(Time)` uses cubic-Hermite interpolation
and returns defensive copies at stored points. The entry point is
`TModellingKit.SolveStiffODE(F, T0, Y0, T1, Options)`. It follows `SolveODE`
validation, event-direction, callback, and result ownership conventions.

`Evaluations` counts ordinary and dual derivative calls plus event callback
calls. `JacobianEvaluations` counts assembled Jacobians, including calls to an
analytic Jacobian callback; `NewtonIterations` counts linear correction solves.
An automatic Jacobian assembles columns by seeding one state component at a
time in `TODEAutoVectorFunction`; that dual callback must represent the same
function as `F`.

## Method selection and numerical evidence

The selected SDIRK method keeps the two stage solve matrices dense and lets
each stage reuse its LU factor during Newton correction. Its embedded
first-order comparison favors a small, auditable implementation while remaining
conservative about accepted steps. The library's own code remains the
implementation; third-party libraries may supply references and independent
comparison data but may not become runtime dependencies.

The reference set includes:

- a scalar forced stiff problem with a closed-form solution, such as
  `y' = -k (y - cos(t)) - sin(t)`, whose solution for `y(0)=0` is
  `cos(t) - exp(-k*t)`;
- the three-species Robertson kinetics system, with equations, initial state,
  tolerances, and final reference values at `t=4e10` taken from the published
  SUNDIALS example;
- a non-stiff problem solved by both explicit and implicit paths to check
  accuracy and avoid presenting the stiff solver as universally preferable;
- failure cases for nonlinear iteration, invalid Jacobians, and evaluation or
  step limits, where the implementation exposes those outcomes.

The Robertson regression uses `rtol=1E-4`, absolute tolerances
`[1E-8, 1E-14, 1E-6]`, and verifies the final state within ten times the
reference weighting used by SUNDIALS. The closed-form forced stiff problem
checks a tighter endpoint budget, tolerance tightening, interpolation, and
event time. Both references are independent of this implementation and usable
offline by the normal test suite. The coupled reference source is the
[SUNDIALS `cvRoberts_dns.c` example](https://github.com/LLNL/sundials/blob/main/examples/cvode/serial/cvRoberts_dns.c).

## Project structure and implementation surface

- Source: `src/NumericsLib.Modelling.pas`; shared dual-number support remains
  in `src/NumericsLib.Differentiation.pas` unless the design justifies a small
  additive extension.
- Tests: focused cases in `tests/TestNumericalModelling.pas`, with any
  reference corpus and loader kept in `tests/`.
- User documentation: `docs/guides/domains/numerical-modelling.md` and
  `docs/reference/capabilities.md`.
- Examples: one complete stiff initial-value program under `examples/`, with
  its output contract and README entry.
- Release evidence: update `CHANGELOG.md` and the v2.3 task/spec files; do not
  rewrite frozen historical API snapshots.

## Code style and dependencies

Use the existing Object Pascal callback, record-options, and result-status
style in `NumericsLib.Modelling`. Keep numerical helpers small and private to
the unit until another stable use requires a shared abstraction. Use existing
matrix and differentiation facilities where their semantics fit. Add no
mandatory runtime dependency; target the supported FPC versions and platforms.

The current explicit call remains the reference for the existing path:

```pascal
Options := TAdaptiveODEOptions.Defaults;
Solution := TModellingKit.SolveODE(@Derivative, T0, InitialState, T1, Options);
```

The new stiff entry point follows the same callback and options conventions.

## Commands and verification

From `tests/`, build and run the full FPCUnit suite using the repository's CI
commands:

```text
fpc -B -FcUTF8 -Fu../src -FUlib/ci TestRunner.lpr
./TestRunner -a --format=plain
```

On Windows, use the configured FPC compiler and `./TestRunner.exe -a
--format=plain`. Build and run examples with `sh ./build-examples.sh` on Unix
or `./build-examples.ps1` on Windows. From the repository root, run
`python tools/check_docs.py` and the project's release qualification before
merge. Linux and Windows CI must pass.

## Test strategy and success criteria

- Unit tests cover validation, both integration directions, scalar and
  component tolerances, Jacobian modes, status/diagnostics, reentrancy, and
  result ownership.
- Numerical tests compare accepted endpoint and dense-output values to the
  independent corpus across stiffness ratios and state scales. They check
  convergence as tolerances tighten and compare shared non-stiff cases with
  `SolveODE`.
- Event tests check direction and event-time accuracy if the selected dense
  output path supports events.
- Qualification passes on supported Linux and Windows configurations, with
  examples, docs, and release evidence consistent with the final API.
- Documentation explains method scope, Jacobian choices and costs, tolerance
  meaning, convergence failures, and when the existing explicit solver is a
  better choice.

## Boundaries

- **Always:** preserve `SolveODE`; validate dimensions and finite values; keep
  numerical behavior and failure states documented; commit independent
  reference provenance with the corpus.
- **Ask first:** add a runtime dependency, change existing public signatures,
  add mass-matrix or sparse-solver scope, or broaden this gate to additional
  equation classes.
- **Never:** return a non-converged partial trajectory as a successful result,
  silently fall back between Jacobian modes, or claim general DAE/PDE support.

## Implementation status

The public names, result fields, solver formula, and reference case are fixed
above and implemented in `NumericsLib.Modelling`. Focused tests cover all three
Jacobian modes, the closed-form forced problem, Robertson kinetics, backward
integration, tolerance tightening, interpolation, events, and invalid
Jacobians. The remaining release gate is full regression/example/documentation
qualification and review of the final code and claims.
