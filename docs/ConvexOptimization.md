# Convex optimisation

`OptimizationLib.Convex` adds diagnostic dense quadratic and second-order-cone
workflows while retaining the compatible `TOptimizationKit` API.

## 60-second example

```pascal
uses MathBase.SharedTypes, MathBase.Iteration, OptimizationLib.Convex;

var M:TQuadraticProgram; O:TConvexOptions; R:TConvexResult;
begin
  SetLength(M.Q,1);
  M.Q[0]:=TDoubleArray.Create(2);
  M.C:=TDoubleArray.Create(-4);  { (x-2)^2, constant omitted }
  M.LowerBounds:=TDoubleArray.Create(0);
  M.UpperBounds:=TDoubleArray.Create(3);
  O:=TConvexOptions.Defaults;
  R:=TConvexOptimizationKit.SolveQuadraticProgram(M,O);
  WriteLn(IterationStatusName(R.Status),' x=',R.X[0]:0:5);
end.
```

See [`18_convex_optimization.pas`](../examples/18_convex_optimization.pas) for
QP and cone-constrained workflows.

## Choose a solver

| Model | Entry point | Assumptions and scale |
| --- | --- | --- |
| Scalar/unconstrained/non-smooth local objective | `TOptimizationKit` | Existing compatibility API |
| Small standard-form LP with non-negative right sides | `SimplexLP` | Tableau simplex; inspect `TLPResult.Status` |
| Dense convex quadratic with box/linear constraints | `SolveQuadraticProgram` | Symmetric positive-semidefinite `Q`; small/medium dense models |
| Dense affine second-order cones | `SolveSecondOrderConeProgram` | Strictly feasible initial point; small/medium dense models |

The QP solver uses explicit alternating projection for box, equality, and
half-space feasibility, followed by projected gradient steps. It is not a
penalty-only facade. The SOCP solver follows a feasible log-barrier path and
never accepts a step outside a cone.

## Public model and result contracts

`TQuadraticProgram` represents

```text
minimise  0.5*x'*Q*x + C'*x
subject to InequalityA*x <= InequalityB
           EqualityA*x = EqualityB
           LowerBounds <= x <= UpperBounds
```

Matrices use `TConvexMatrix` (`array of TDoubleArray`) with zero-based,
non-ragged rows. Bounds may independently be empty. `Q` is checked for symmetry
and numerical positive semidefiniteness through the typed symmetric
eigensystem.

`TSecondOrderCone` represents
`Norm2(A*x + B) <= Dot(D,x) + E`; `TSecondOrderCones` is an array of those
records. A cone solve requires a strictly feasible `TConvexOptions.InitialX`.
Failure to supply one is an input error; a non-strict start is returned as
`isInfeasible` with its measured violation.

`TConvexOptions.Defaults` supplies absolute, relative, and feasibility
tolerances plus an iteration limit. `TConvexProgress` can cancel a solve.

`TConvexResult` owns `X` and reports `Objective`, projected/barrier
`GradientNorm`, maximum `Feasibility` violation, `Iterations`, `Evaluations`,
and `TIterationStatus`. `isAcceptableLimit` means a feasible barrier point met
the documented duality-gap scale even if the inner line search could not make
another representable step.

## Errors, ownership, and limitations

`EConvexOptimizationError` names invalid shapes, non-finite values, inconsistent
bounds, rank-deficient equalities, non-convex `Q`, or invalid options. Inputs
are borrowed, never retained or mutated; results own their arrays.

The units are reentrant and have no global model, callback, RNG, or workspace.
Calls are thread-safe unless the caller concurrently mutates the same input
arrays or callback state.

Complexity is O(n³) for convexity/equality checks and O(iterations × constraints
× n) or more for projections/barrier evaluations. The 1.7 stable boundary is
dense continuous convex QP and affine SOCP. Sparse constraints, semidefinite
programming, general non-convex QP, integer/mixed-integer optimisation, and
infeasibility certificates for arbitrary cones are not claimed.

