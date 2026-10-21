# Bounded global optimization

Use `OptimizationLib.Global` for a reproducible derivative-free search over
a finite real-double box. `TGlobalOptimizationKit.DifferentialEvolution`
uses DE/rand/1/bin with deferred population updates. It returns the best finite
point observed and an explicit stopping reason. A heuristic result is not a
proof of global optimality, even when the population tolerance is satisfied.

Use [local optimizers](optimization.md) when you have a useful starting point
or gradients, and [convex solvers](convex-optimization.md) for structured convex
models. This baseline does not handle integer variables, nonlinear constraints,
unbounded domains, or global-optimality certificates.

## Quick start

```pascal
uses MathBase.SharedTypes, OptimizationLib.Global;

function Objective(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0] - 0.25);
end;

var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxPolishEvaluations := 150;
  R := TGlobalOptimizationKit.DifferentialEvolution(@Objective, [-1], [1], O);
  if R.HasFiniteValue then WriteLn('best objective = ', R.FVal:0:6);
end.
```

Expected output:

```text
best objective = 0.000000
```

Run [example 46](../../../examples/46_bounded_global_search.pas) for a multimodal
Rastrigin search, replay, budget checks and explicit global termination.

## Bounds, callback and ownership

Lower and Upper must be nonempty matching arrays with finite ordered values.
Equal endpoints fix a coordinate. An all-fixed box is evaluated once and
skips polishing. Internal coordinates are normalized to [0,1]; mapping back
avoids overflowing the width of opposite-sign extreme bounds. Mutated trial
coordinates and polish steps are clamped to the box.

Reuse `OptimizationLib.Optimization.TMultivarFunc`. Each callback receives a
fresh physical-coordinate array. No input array is mutated or retained.
Returned `X` and `GlobalX` are independent copies. Copying a result record
aliases its arrays under ordinary Pascal semantics; use `Copy` before editing
arrays in a copied record. Do not retain or modify inputs to other algorithms
unless their contracts permit it.

Every callback call consumes one evaluation, including NaN and infinity.
Nonfinite results are rejected and do not become the best point. A search can
recover after a nonfinite initial population. When no finite point was found,
`HasFiniteValue=False`, `X` and `GlobalX` are empty, objectives are positive
infinity, and global status is `gssNoFiniteValue`. Callback exceptions propagate.
The caller is responsible for callback determinism and bounded execution time.

## Options and limits

| Option | Default | Valid values and meaning |
| --- | --- | --- |
| `PopulationSize` | 32 | At least 4; storage O(population × dimensions) |
| `MaxGenerations` | 1000 | Nonnegative; completed population generations after initialization |
| `MaxEvaluations` | 20000 | Positive; global phase callback limit, including initialization |
| `DifferentialWeight` | 0.8 | Finite in (0,2] |
| `CrossoverProbability` | 0.9 | Finite in [0,1]; one free coordinate always crosses |
| `PositionTolerance` | 1e-8 | Finite in (0,1]; normalized coordinate spread and polish step |
| `AbsoluteTolerance` | 1e-10 | Finite and nonnegative objective spread allowance |
| `RelativeTolerance` | 1e-8 | Finite and nonnegative objective spread scale allowance |
| `Seed` | 1729 | Local unsigned 64-bit seed |
| `MaxPolishEvaluations` | 0 | Nonnegative; separate optional polish callback limit |
| `InitialPolishStep` | 0.1 | Finite in (0,1], normalized coordinate step |

Invalid inputs raise `EOptimizationError` before any objective call or caller
random-state advance. Combined evaluation limits must fit `Integer`.
Budgets may end during initialization or a generation; the best observed
point is still returned. A partial generation is not counted in `Generations`.
Population work is O(population × dimensions + population²) per generation,
in addition to callback cost; this portable baseline is serial.

`Evaluations = GlobalEvaluations + PolishEvaluations`. The global and polish
budgets are independent; enabling polish can add its configured number of
calls after the global budget is exhausted. No wall-clock limit is implied.

## Termination and polishing

| Global status | Meaning |
| --- | --- |
| `gssPopulationTolerance` | Every population value is finite, maximum normalized coordinate range meets position tolerance, and objective spread meets absolute + relative × max(1, maximum absolute objective) tolerance |
| `gssEvaluationLimit` | Global call budget exhausted |
| `gssGenerationLimit` | Completed-generation budget exhausted |
| `gssFixedBounds` | One evaluation of an all-fixed finite box |
| `gssNoFiniteValue` | No finite callback value observed; overrides other global reasons |

At complete population boundaries tolerance takes precedence over limits;
otherwise evaluation limit precedes generation limit. Population collapse
can occur in a local basin or flat region. Inspect the point and model, use
several seeds where appropriate, and compare against domain knowledge.

Polishing starts at the best finite point, tries positive then negative steps
coordinate by coordinate, accepts strict improvements and halves the step
after an unsuccessful sweep. It stays bounded and cannot worsen the result.
`gpsStepTolerance` means the step reached `PositionTolerance`;
`gpsEvaluationLimit` means the separate budget ended; `gpsNotRun` means it was
disabled, no finite point existed, or all bounds were fixed. The global phase
status and pre-polish `GlobalX`/`GlobalFVal` remain available.

## Reproducibility and references

The default and options overloads seed a local `TLocalRandom`. The overload
with `var Random: TLocalRandom` advances the caller's explicit stream. Neither
uses RTL `RandSeed`. `FinalRandomState` can replay subsequent random draws;
it is not a checkpoint containing the population. Polishing uses no random
draws. A deterministic callback gives repeatable runs on one profile; floating
arithmetic may differ across platforms or compiler settings.

The native implementation follows [Storn and Price (1997)](https://doi.org/10.1023/A:1008202821328).
Independent analytic tests use the SFU definitions of
[Rastrigin](https://www.sfu.ca/~ssurjano/rastr.html),
[Rosenbrock](https://www.sfu.ca/~ssurjano/rosen.html),
[Ackley](https://www.sfu.ca/~ssurjano/ackley.html), and
[Sphere](https://www.sfu.ca/~ssurjano/spheref.html).
The [v2.9.0 numerical evidence](../../releases/2.9.0/numerical-evidence.json)
records tested budgets; they are corpus checks, not universal guarantees.
