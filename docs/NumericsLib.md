# NumericsLib

Numerical methods library for Free Pascal — root finding, quadrature, ODE solvers, and interpolation.

Depends on: **MathBase**

## Units

| Unit | File | Class |
|------|------|-------|
| `NumericsLib.Numerics` | [NumericsLib.Numerics.pas](../src/NumericsLib.Numerics.pas) | `TNumericsKit` |

All methods are class-static — no instantiation required:

```pascal
Root := TNumericsKit.Brent(@F, 1.0, 2.0);
```

---

## Function Types

```pascal
TScalarFunc = function(X: Double): Double;        // f(x) — used by root finders and integrators
TODEFunc    = function(T, Y: Double): Double;     // dy/dt = f(t,y) — used by ODE solvers
```

## Result Records

```pascal
TODESolution = record
  T: TDoubleArray;   // independent variable values (length N+1)
  Y: TDoubleArray;   // solution values             (length N+1)
end;

TCubicSpline = record
  X: TDoubleArray;   // knot x-values (sorted ascending)
  A, B, C, D: TDoubleArray;  // polynomial coefficients per interval
end;
```

---

## Root Finding

All methods find x such that f(x) ≈ 0. Tolerance parameters control convergence.

### `Bisection`

```pascal
class function Bisection(F: TScalarFunc; A, B: Double;
  Tol: Double = 1E-10; MaxIter: Integer = 100): Double;
```

Guaranteed convergence for bracketed roots. Requires f(A) · f(B) < 0.
Raises `EInvalidArgument` if the bracket is invalid.

**Best for:** when robustness matters more than speed; verifying root existence.

### `NewtonRaphson`

```pascal
class function NewtonRaphson(F, DF: TScalarFunc; X0: Double;
  Tol: Double = 1E-10; MaxIter: Integer = 100): Double;
```

Quadratic convergence near the root using f and its derivative df/dx.
Raises `EInvalidArgument` if df/dx is near zero (flat region).

**Best for:** smooth functions where the derivative is cheap to evaluate.

### `Brent`

```pascal
class function Brent(F: TScalarFunc; A, B: Double;
  Tol: Double = 1E-10; MaxIter: Integer = 100): Double;
```

Hybrid method combining bisection, secant, and inverse-quadratic interpolation.
Superlinear convergence in practice; falls back to bisection when necessary.
Raises `EInvalidArgument` if f(A) · f(B) > 0.

**Best for:** general use — the recommended default solver.

### `Secant`

```pascal
class function Secant(F: TScalarFunc; X0, X1: Double;
  Tol: Double = 1E-10; MaxIter: Integer = 100): Double;
```

Derivative-free quasi-Newton using two initial guesses. Superlinear convergence
but may diverge without a good bracket.

**Best for:** when a derivative is unavailable and you have a good initial estimate.

---

## Numerical Integration

### `TrapezoidalRule`

```pascal
class function TrapezoidalRule(F: TScalarFunc; A, B: Double;
  N: Integer = 1000): Double;
```

Composite trapezoidal rule with N sub-intervals. Error O(h²). Exact for linear functions.

### `SimpsonRule`

```pascal
class function SimpsonRule(F: TScalarFunc; A, B: Double;
  N: Integer = 1000): Double;
```

Composite Simpson's 1/3 rule with N sub-intervals (N is auto-incremented to even if odd).
Error O(h⁴). Exact for polynomials of degree ≤ 3.

### `GaussLegendre5`

```pascal
class function GaussLegendre5(F: TScalarFunc; A, B: Double): Double;
```

5-point Gauss-Legendre quadrature on [A, B]. Exact for polynomials of degree ≤ 9.
Very accurate for smooth functions with only 5 function evaluations.

**Comparison:**

| Method | Order | Evaluations per call | Notes |
|--------|-------|---------------------|-------|
| `TrapezoidalRule` | O(h²) | N+1 | Robust, slow |
| `SimpsonRule` | O(h⁴) | N+1 | Good default |
| `GaussLegendre5` | exact deg 9 | 5 | Best for smooth f |

---

## ODE Solvers

Solve dy/dt = f(t, y), y(t₀) = y₀ over the interval [T0, T1].

### Single Steps

```pascal
class function EulerStep(F: TODEFunc; T0, Y0, H: Double): Double;
class function RK4Step(F: TODEFunc; T0, Y0, H: Double): Double;
```

Return the solution at T0 + H given the current state (T0, Y0).

### Full Solvers

```pascal
class function EulerSolve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
class function RK4Solve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
```

Integrate from T0 to T1 using N uniform steps of size h = (T1−T0)/N.
Return a `TODESolution` with T and Y arrays of length N+1.

**Accuracy comparison** for dy/dt = y, y(0) = 1 over [0, 1] (exact: e ≈ 2.71828):

| Method | Steps | Typical error |
|--------|-------|--------------|
| `EulerSolve` | 10 000 | ~1×10⁻⁴ |
| `RK4Solve` | 100 | ~1×10⁻⁷ |
| `RK4Solve` | 1 000 | ~1×10⁻¹¹ |

---

## Interpolation

### `LinearInterp`

```pascal
class function LinearInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double;
```

Piecewise linear interpolation between sorted knots using binary search.
Clamps to endpoint values outside the knot range.

### `LagrangeInterp`

```pascal
class function LagrangeInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double;
```

Global Lagrange polynomial interpolation through all N knots. Exact at every knot.

> **Warning:** ill-conditioned for N > ~10 (Runge phenomenon). Prefer `CubicSplineBuild` for larger datasets.

### `CubicSplineBuild` / `CubicSplineEval`

```pascal
class function CubicSplineBuild(const XKnots, YKnots: TDoubleArray): TCubicSpline;
class function CubicSplineEval(const S: TCubicSpline; X: Double): Double;
```

Natural cubic spline (zero second-derivative boundary conditions) solved via the
Thomas tridiagonal algorithm. Exact at every knot; smooth C² between knots.
Clamps to endpoint values outside the knot range.

---

## Quick Start

```pascal
uses NumericsLib.Numerics;

{ --- functions for root finding and integration --- }
function F(X: Double): Double; begin Result := X*X - 2; end;
function DF(X: Double): Double; begin Result := 2*X; end;
function G(X: Double): Double; begin Result := X*X; end;

{ --- ODE: dy/dt = y  →  exact solution y(t) = e^t --- }
function DYDT(T, Y: Double): Double; begin Result := Y; end;

var
  Root, Integral: Double;
  Sol: TODESolution;
  XK, YK: TDoubleArray;
  Spline: TCubicSpline;
begin
  { Root: Brent's method — recommended default }
  Root := TNumericsKit.Brent(@F, 1.0, 2.0);
  Writeln('sqrt(2) = ', Root:0:10);      // 1.4142135624

  { Root: Newton-Raphson — fast with derivative }
  Root := TNumericsKit.NewtonRaphson(@F, @DF, 1.5);
  Writeln('sqrt(2) = ', Root:0:10);

  { Integration: ∫₀¹ x² dx = 0.3333... }
  Integral := TNumericsKit.SimpsonRule(@G, 0, 1, 1000);
  Writeln('Integral = ', Integral:0:6);  // 0.333333

  { ODE: RK4 is accurate with far fewer steps than Euler }
  Sol := TNumericsKit.RK4Solve(@DYDT, 0, 1.0, 1.0, 100);
  Writeln('y(1) = e = ', Sol.Y[100]:0:8);  // 2.71828183

  { Spline interpolation through y = x² at integer knots }
  XK := TDoubleArray.Create(0, 1, 2, 3, 4);
  YK := TDoubleArray.Create(0, 1, 4, 9, 16);
  Spline := TNumericsKit.CubicSplineBuild(XK, YK);
  Writeln('Spline(1.5) = ', TNumericsKit.CubicSplineEval(Spline, 1.5):0:4);  // ≈ 2.25
end.
```

---

## Error Handling

| Condition | Exception |
|-----------|-----------|
| Bisection/Brent: f(A) and f(B) same sign | `EInvalidArgument` |
| NewtonRaphson: derivative near zero | `EInvalidArgument` |
| Secant: f(x₁) ≈ f(x₀) (division by near-zero) | `EInvalidArgument` |
| TrapezoidalRule: N < 1 | `EInvalidArgument` |
| EulerSolve / RK4Solve: N < 1 | `EInvalidArgument` |
| LinearInterp / LagrangeInterp: empty arrays | `EInvalidArgument` |
| CubicSplineBuild: fewer than 2 knots | `EInvalidArgument` |

---

## Design Notes

- All functions are **class-static** — pass function pointers, not method pointers.
  In FPC, module-level `function` declarations are compatible with `TScalarFunc` / `TODEFunc`.
- The cubic spline uses **natural boundary conditions** (S''(x₀) = S''(xₙ) = 0).
  This is the standard choice when no derivative information is available at the boundaries.
- `GaussLegendre5` performs only **5 function evaluations** regardless of the smoothness
  of f. For oscillatory functions, use `SimpsonRule` with a large N instead.
- `TODESolution` arrays are **1-indexed from 0**: `Sol.T[0] = T0`, `Sol.T[N] = T1`.
