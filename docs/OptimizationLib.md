# OptimizationLib Reference

`OptimizationLib.Optimization` — mathematical optimization for Free Pascal.

---

## Quick Start

```pascal
uses OptimizationLib.Optimization;

// Single-variable: find x that minimises (x-3)^2 on [0,10]
xMin := TOptimizationKit.GoldenSection(@MyFunc, 0, 10);  // ≈ 3.0

// Multi-variable: minimise f(x,y) = (x-2)^2 + (y+1)^2
result := TOptimizationKit.NelderMead(@MyFunc, TDoubleArray.Create(0, 0));
// result.X[0] ≈ 2.0,  result.X[1] ≈ -1.0

// Linear programming: minimise -x1-x2 subject to x1+x2 ≤ 4
lp := TOptimizationKit.SimplexLP([-1,-1], [[1,1],[1,0],[0,1]], [4,3,3]);
```

All methods are **class static** — no `Create`/`Free` needed.

---

## Function Types

```pascal
TUnivarFunc   = function(X: Double): Double;
TMultivarFunc = function(const X: TDoubleArray): Double;
TGradFunc     = function(const X: TDoubleArray): TDoubleArray;
TConstraintFunc = function(const X: TDoubleArray): Double;  // g(x) <= 0
```

---

## Result Records

```pascal
TOptResult = record
  X:         TDoubleArray;  { solution vector }
  FVal:      Double;        { objective value at solution }
  Iters:     Integer;       { iterations used }
  Converged: Boolean;       { True if convergence criterion was met }
end;

TLPStatus = (lpsOptimal, lpsUnbounded, lpsIterationLimit,
  lpsUnsupportedStart);

TLPResult = record
  X:        TDoubleArray;
  ObjVal:   Double;
  Feasible: Boolean;
  Iters:    Integer;
  Status:   TLPStatus;
end;
```

---

## Solver Selection Guide

| Problem type | Recommended solver | Why |
|---|---|---|
| 1-D, unimodal | `BrentMinimize` | Fastest, superlinear convergence |
| 1-D, guaranteed bracket | `GoldenSection` | Simplest, no function smoothness needed |
| Smooth multi-var, gradient available | `LBFGS` | Fast quasi-Newton, low memory |
| Smooth multi-var, no gradient | `NelderMead` | Reliable, no derivatives |
| ML / deep learning style | `Adam` | Adaptive rates, handles noise |
| Non-convex, many local minima | `SimulatedAnnealing` | Global search |
| Constrained problems | `PenaltyMethod` + `NelderMead` | Easy to set up |
| Small standard-form linear programs | `SimplexLP` | Tableau simplex with an immediately feasible slack basis |

---

## Single-Variable Minimization

### GoldenSection

```pascal
xMin := TOptimizationKit.GoldenSection(F, A, B);
xMin := TOptimizationKit.GoldenSection(F, A, B, Tol, MaxIter);
```

Reduces the interval by the golden ratio each step. Requires `f` to be **unimodal** on [A, B] (one valley). Guaranteed O(log(1/Tol)) evaluations.

### BrentMinimize

```pascal
xMin := TOptimizationKit.BrentMinimize(F, A, B);
```

Combines golden-section with parabolic interpolation. **Faster** than golden section on smooth functions, same guarantees. Preferred default for 1-D problems.

---

## Multi-Variable Minimization

### GradientDescent

```pascal
result := TOptimizationKit.GradientDescent(F, Grad, X0);
result := TOptimizationKit.GradientDescent(F, nil, X0);  // uses numerical gradient
```

Steepest descent with Armijo backtracking line search. Simple but slow — primarily useful for education or as a baseline.

**Parameters:** `LR` (step size, default 0.1), `Tol` (gradient norm threshold, default 1e-6), `MaxIter` (default 5000).

### Adam

```pascal
result := TOptimizationKit.Adam(F, Grad, X0);
result := TOptimizationKit.Adam(F, nil, X0, LR := 0.001);
```

Adaptive moment estimation. The standard optimizer in machine learning. Robust to:
- Non-convex landscapes
- Noisy/stochastic gradients
- Different scales across dimensions

**Parameters:** `LR` (0.001), `Beta1` (0.9), `Beta2` (0.999), `Eps` (1e-8), `Tol` (1e-6), `MaxIter` (10000).

### L-BFGS

```pascal
result := TOptimizationKit.LBFGS(F, Grad, X0);
result := TOptimizationKit.LBFGS(F, nil, X0, M := 10);
```

Limited-memory quasi-Newton. Uses the last `M` gradient differences to approximate the inverse Hessian. **Much faster than gradient descent** on smooth convex problems (super-linear convergence). Memory: O(M × N) instead of O(N²) for full BFGS.

**Parameters:** `M` history size (default 10), `Tol` (1e-6), `MaxIter` (1000).

### NelderMead (Simplex)

```pascal
result := TOptimizationKit.NelderMead(F, X0);
result := TOptimizationKit.NelderMead(F, X0, Scale, Tol, MaxIter);
```

Moves a geometric simplex (N+1 points) through the search space. **No gradient needed.** Works on:
- Non-smooth functions
- Simulation outputs (black-box)
- Functions with noise

**Parameters:** `Scale` — initial simplex size (default 1.0, reduce for fine-grained search), `Tol` (1e-8), `MaxIter` (10000).

### SimulatedAnnealing

```pascal
result := TOptimizationKit.SimulatedAnnealing(F, X0);
result := TOptimizationKit.SimulatedAnnealing(F, X0, T0, TMin, CoolRate, StepSize, MaxIter, Seed);
```

Probabilistic global search. Accepts worse solutions with probability `exp(-ΔE/T)`, where T decreases over time (cooling schedule). Can **escape local minima** — other solvers cannot.

**Parameters:**
- `T0` — initial temperature (default 100; higher = more exploration)
- `TMin` — stop temperature (default 1e-8)
- `CoolRate` — cooling factor per step (default 0.995; closer to 1 = slower cooling)
- `StepSize` — random perturbation size (default 0.1)
- `Seed` — RNG seed for reproducibility (default 42)

**Tuning tips:**
- If the solver misses the global minimum: increase `T0` or increase `CoolRate` closer to 1
- If cooling is too slow: decrease `CoolRate`
- For higher-dimensional problems: increase `MaxIter`

---

## Constrained Optimization

### PenaltyMethod

```pascal
// minimise f(x)  subject to g1(x) <= 0, g2(x) <= 0, ...
result := TOptimizationKit.PenaltyMethod(F, [g1, g2], X0);
```

Converts the constrained problem to unconstrained by adding a quadratic penalty:

```
F_pen(x) = F(x) + Mu * Σ max(0, g_i(x))²
```

Mu is automatically increased across 10 outer iterations to drive constraint violations to zero. Uses `NelderMead` internally so no gradient is needed.

**Example:**
```pascal
function MyObj(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]-5) + Sqr(X[1]-5); end;

function Constraint1(const X: TDoubleArray): Double;
begin Result := X[0] + X[1] - 6; end;  // x1 + x2 <= 6

result := TOptimizationKit.PenaltyMethod(@MyObj,
  [TConstraintFunc(@Constraint1)],
  TDoubleArray.Create(1, 1));
// X ≈ [3, 3],  FVal ≈ 8
```

---

## Linear Programming

### SimplexLP

```pascal
// minimise   c' x
// subject to A x <= b,   x >= 0

lp := TOptimizationKit.SimplexLP(C, A, B);
if lp.Feasible then
  WriteLn('Optimal: ', lp.ObjVal);
```

`Feasible` is retained as a compatibility flag and is `True` only when
`Status = lpsOptimal`. Inspect `Status` to distinguish an unbounded model, an
iteration limit, and an unsupported negative-right-hand-side starting basis.

**Standard form requirements:**

- All right-hand sides `b[i] >= 0`, so the added slack variables form the
  initial feasible basis
- Variables implicitly >= 0
- Only `<=` constraints are supported; there is no Phase I procedure for
  `>=`, equality, or a non-obvious initial feasible basis

**Example — capacity-constrained production:**

```pascal
// maximise x1+x2 by minimising -x1-x2
// subject to x1+x2 <= 4, x1 <= 3, x2 <= 3, and x >= 0

lp := TOptimizationKit.SimplexLP(
  TDoubleArray.Create(-1, -1),
  [TDoubleArray.Create(1, 1),
   TDoubleArray.Create(1, 0),
   TDoubleArray.Create(0, 1)],
  TDoubleArray.Create(4, 3, 3));
```

`Feasible = False` is also used for an unbounded tableau, so the result does
not distinguish infeasibility from unboundedness.

---

## Utilities

### Numerical Gradient

```pascal
// Central differences: (f(x+h*e_i) - f(x-h*e_i)) / 2h
G := TOptimizationKit.NumGrad(F, X);
G := TOptimizationKit.NumGrad(F, X, H := 1E-5);
```

Useful for verifying analytical gradients or using gradient-based solvers without implementing a gradient function.

### Maximize

```pascal
// Find the maximum of F by minimising -F internally
result := TOptimizationKit.Maximize(F, X0);
// result.FVal is the maximum value (positive)
```

---

## Passing Nil for Gradient

All gradient-based solvers (`GradientDescent`, `Adam`, `LBFGS`) accept `nil` for the `Grad` parameter. They will compute a numerical gradient internally using central differences.

```pascal
// Both of these work:
result := TOptimizationKit.LBFGS(@MyFunc, @MyGrad, X0);   // analytical
result := TOptimizationKit.LBFGS(@MyFunc, nil, X0);        // numerical
```

Numerical gradients are slightly slower (~2N function evaluations per gradient) but require no extra implementation.

---

## Error Handling

`EOptimizationError` is raised for:

- `GoldenSection` / `BrentMinimize`: B <= A
- Any multi-variable solver: empty `X0`
- `SimplexLP`: no constraints or no variables provided
- nil callbacks, non-finite inputs or callback results, and gradient dimension mismatches
- non-positive tolerances or iteration counts and invalid solver hyperparameters
- ragged or mismatched linear-program dimensions
- scalar solvers exhausting their iteration limit

`PenaltyMethod` and `Maximize` use unit-level callback state to bridge Free
Pascal procedure-variable restrictions. Calls through these adapters are
serialized so overlapping threads cannot corrupt the shared callback state.

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`

No other external libraries required.
