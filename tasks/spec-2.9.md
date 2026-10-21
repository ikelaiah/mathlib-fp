# v2.9.0 Optimization II specification

## Outcome and scope

Provide reproducible derivative-free minimization of a scalar callback on a
finite real-double box. Implement DE/rand/1/bin with deferred population
updates and optional bounded coordinate-search polishing. This is a heuristic:
no global-optimality certificate, mixed-integer search, nonlinear constraints,
or unbounded search is provided. Existing optimization APIs remain unchanged.

## Public contract

Add `OptimizationLib.Global`, using `TDoubleArray`, `TMultivarFunc`,
`EOptimizationError`, and `MathBase.Random.TLocalRandom`.

- `TGlobalOptimizationOptions.Defaults`: population 32, 1000 generations,
  20000 global evaluations, differential weight 0.8, crossover probability
  0.9, normalized position tolerance 1e-8, absolute objective tolerance
  1e-10, relative objective tolerance 1e-8, seed 1729; polishing disabled
  (`MaxPolishEvaluations=0`), initial normalized polish step 0.1.
- `TGlobalOptimizationKit.DifferentialEvolution(F, Lower, Upper)` and an
  options overload seed a local generator. An overload taking options and
  `var Random: TLocalRandom` uses and advances the caller's explicit state.
- `TGlobalOptimizationResult`: best finite `X`, `FVal`, `HasFiniteValue`,
  pre-polish `GlobalX`/`GlobalFVal`, global and polish evaluation counts,
  total `Evaluations`, completed `Generations`, `Status`, `PolishStatus`,
  and `FinalRandomState`.
- Global statuses: population tolerance, evaluation limit, generation limit,
  all bounds fixed, no finite value. Polish statuses: not run, step tolerance,
  evaluation limit. No status claims global optimality.

Bounds must have matching nonzero lengths and finite Lower <= Upper. Equal
bounds fix coordinates; an entirely fixed box is evaluated exactly once.
Population must be >=4; global budget >=1; generation/polish budgets >=0.
Weight is finite in (0,2], crossover in [0,1], position tolerance in (0,1],
objective tolerances finite and nonnegative, polish step in (0,1]. Invalid
input raises before any objective call or random-state advance.

Normalize free coordinates to [0,1] for mutation and polishing. Generate a
uniform initial population. Draw three distinct donor indexes excluding the
target, force one crossover coordinate, clamp mutations to [0,1], replace a
target on <= objective, and apply all replacements after each generation.
A partial final generation may improve the returned best but is not counted
as completed. Stop on population tolerance only after a complete population
exists and all objective values are finite: both maximum coordinate range
and objective spread must meet their tolerances. Check tolerance before
limits at complete generation boundaries; evaluation limit precedes generation
limit otherwise. No finite point at termination overrides the limit status.

Each callback invocation counts exactly once, including NaN/infinity results.
Nonfinite values are rejected, with no finite result represented by empty X,
positive infinity FVal, and HasFiniteValue=False. Callback exceptions propagate.
Callbacks receive a fresh physical-coordinate array; inputs are neither
mutated nor retained. Callback determinism and bounded execution are caller
responsibilities. Global RNG state is untouched. State can replay the random
stream but is not a resumable population checkpoint. Repeated runs on one
profile are deterministic; floating arithmetic need not be bit-identical
across platforms. Result arrays own separate copies; ordinary Pascal record
copies alias dynamic arrays.

Polishing starts at the best finite point, tries positive then negative
coordinate steps in order, accepts strict improvements, and halves the step
after a full sweep without improvement. It stays inside bounds and never
worsens the best. Stop when the normalized step <= position tolerance or
the separate polish budget is exhausted. Global status and pre-polish result
remain available. Total evaluations equal the sum of the two budgets used.
All-fixed boxes and searches without a finite result skip polishing.

## References and implementation choices

Algorithm: Storn and Price, Journal of Global Optimization 11 (1997),
341-359, DOI 10.1023/A:1008202821328. Implement from the mathematical
description; no third-party code or runtime dependency. Independent analytic
problems use the SFU Virtual Library of Simulation Experiments definitions
(Sphere, Rastrigin, Rosenbrock, Ackley). Tests check known minima and budgets,
not a promise that every seed/problem finds the global minimum.

## Structure, style and verification

Follow existing Object Pascal static Kit/advanced-record conventions:
`Options := TGlobalOptimizationOptions.Defaults;`. Source in `src/`,
FPCUnit tests in `tests/TestGlobalOptimization.pas`, runnable example 47 in
`examples/`, guide and release evidence in `docs/`. No new dependencies.

Compile and run: `fpc -B -FcUTF8 -Fusrc -FUbuild-temp/global tests/TestRunner.lpr`
then `tests/TestRunner.exe --all --format=plain` (create output directory first).
Release: `python tools/qualify_release.py --release 2.9.0 --compiler fpc`.
Exercise deterministic replay, caller state, global RNG isolation, partial
budgets, constant/nonfinite objectives, narrow/extreme/fixed bounds,
callback ownership/exceptions, known multimodal minima, polish outcomes,
and invalid inputs. Require normal, optimized and checked/heap builds.

Always validate before work, preserve historical artifacts, publish truthful
evidence, and obtain green exact-commit Linux/Windows CI and clean-archive
qualification before tagging main. Never weaken gates, remove failing tests,
commit secrets, or claim an unperformed check. The user's end-to-end release
instruction authorizes implementation, review, branch/PR, merge and publication.
