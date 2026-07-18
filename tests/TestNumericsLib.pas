unit TestNumericsLib;

{-----------------------------------------------------------------------------
 TestNumericsLib

 Comprehensive tests for NumericsLib.Numerics:
   - Root finding: Bisection, NewtonRaphson, Brent, Secant
   - Numerical integration: Trapezoidal, Simpson, Gauss-Legendre 5
   - ODE solvers: Euler, RK4
   - Interpolation: Linear, Lagrange, natural cubic spline

 Each test uses analytically known answers so tolerances are tight.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  MathBase.SharedTypes,
  NumericsLib.Numerics;

type
  TTestNumericsLib = class(TTestCase)
  private
    const
      EPS_TIGHT  = 1E-8;   { root-finding, ODE, spline }
      EPS_QUAD   = 1E-6;   { quadrature (composite rules use finite N) }
      EPS_INTERP = 1E-9;   { interpolation on polynomial data }

    procedure AssertNear(const Expected, Actual, Tol: Double; const Msg: String = '');

    { Helpers for exception testing }
    procedure DoBisectionBadBracket;
    procedure DoBrentBadBracket;
    procedure DoNewtonZeroDeriv;
    procedure DoSecantStuck;
    procedure DoTrapezoidalBadN;
    procedure DoLinearInterpEmpty;
    procedure DoSplineTooFewKnots;

  published
    { Root Finding }
    procedure Test01_Bisection_Sqrt2;
    procedure Test02_Bisection_CubicRoot;
    procedure Test03_Bisection_BadBracket_Raises;
    procedure Test04_NewtonRaphson_Sqrt2;
    procedure Test05_NewtonRaphson_Cubic;
    procedure Test06_Brent_Sqrt2;
    procedure Test07_Brent_Transcendental;
    procedure Test08_Brent_BadBracket_Raises;
    procedure Test09_Secant_Sqrt2;
    procedure Test10_Secant_Transcendental;

    { Integration }
    procedure Test11_Trapezoidal_Linear;
    procedure Test12_Trapezoidal_Quadratic;
    procedure Test13_Trapezoidal_BadN_Raises;
    procedure Test14_Simpson_Linear;
    procedure Test15_Simpson_Cubic;
    procedure Test16_Simpson_ForcesEvenN;
    procedure Test17_GaussLegendre5_Polynomial;
    procedure Test18_GaussLegendre5_Sine;
    procedure Test19_GaussLegendre5_Exp;

    { ODE Solvers }
    procedure Test20_EulerStep_Exponential;
    procedure Test21_EulerSolve_Exponential_FinalValue;
    procedure Test22_EulerSolve_Length;
    procedure Test23_RK4Step_Exponential;
    procedure Test24_RK4Solve_Exponential_Accuracy;
    procedure Test25_RK4Solve_HarmonicOscillator;
    procedure Test26_RK4Solve_Length;

    { Interpolation }
    procedure Test27_LinearInterp_ExactKnot;
    procedure Test28_LinearInterp_Midpoint;
    procedure Test29_LinearInterp_ClampLeft;
    procedure Test30_LinearInterp_ClampRight;
    procedure Test31_LinearInterp_EmptyRaises;
    procedure Test32_LagrangeInterp_LinearData;
    procedure Test33_LagrangeInterp_QuadraticData;
    procedure Test34_LagrangeInterp_AtKnot;
    procedure Test35_CubicSpline_ExactAtKnots;
    procedure Test36_CubicSpline_LinearData_Accurate;
    procedure Test37_CubicSpline_QuadraticData_Accurate;
    procedure Test38_CubicSpline_Clamp;
    procedure Test39_CubicSpline_TooFewKnots_Raises;
    procedure Test40_BisectionEndpointRootRegression;
    procedure Test41_RootConvergenceIsReported;
    procedure Test42_InterpolationRejectsUnorderedKnots;
  end;

implementation

{ -------------------------------------------------------------------------
  Plain global functions (no closures in FPC — use unit-level functions)
  These are the mathematical functions passed to the numerical routines.
  ------------------------------------------------------------------------- }

{ f(x) = x^2 - 2  →  root = sqrt(2) }
function FX_XSq_Minus2(X: Double): Double;
begin Result := X*X - 2; end;

{ f'(x) = 2x }
function DFX_XSq_Minus2(X: Double): Double;
begin Result := 2 * X; end;

{ f(x) = x^3 - x - 2  →  root ≈ 1.5213797 }
function FX_Cubic(X: Double): Double;
begin Result := X*X*X - X - 2; end;

function DFX_Cubic(X: Double): Double;
begin Result := 3*X*X - 1; end;

{ f(x) = cos(x) - x  →  Dottie number ≈ 0.7390851 }
function FX_CosX_MinusX(X: Double): Double;
begin Result := Cos(X) - X; end;

function FX_Identity(X: Double): Double;
begin Result := X; end;

function DFX_CosX_MinusX(X: Double): Double;
begin Result := -Sin(X) - 1; end;

{ Integration test functions }
function F_Linear(X: Double): Double; begin Result := 2*X + 1; end;       { ∫0..1 = 2 }
function F_Quadratic(X: Double): Double; begin Result := X*X; end;           { ∫0..1 = 1/3 }
function F_Cubic(X: Double): Double; begin Result := X*X*X; end;          { ∫0..1 = 0.25 }
function F_Sine(X: Double): Double; begin Result := Sin(X); end;         { ∫0..π = 2 }
function F_Exp(X: Double): Double; begin Result := Exp(X); end;         { ∫0..1 = e-1 }
function F_Poly9(X: Double): Double; begin Result := Power(X, 9); end;    { ∫0..1 = 0.1, degree 9 }

{ ODE dy/dt = y  →  y(t) = y0 * exp(t) }
function ODE_Exponential(T, Y: Double): Double;
begin Result := Y; end;

{ ODE dy/dt = -y  →  y(t) = y0 * exp(-t) }
function ODE_DecayExponential(T, Y: Double): Double;
begin Result := -Y; end;

{ ODE dy/dt = -x (harmonic oscillator position, with velocity as y)
  Here we solve v' = -x directly with x(0)=0, v(0)=1 on [0, π]
  Exact solution at t=π: x = sin(π) = 0 }
function ODE_HarmonicVelocity(T, Y: Double): Double;
begin Result := -Sin(T); end;  { d(cos t)/dt = -sin t }

{ -------------------------------------------------------------------------
  TTestNumericsLib helper
  ------------------------------------------------------------------------- }

procedure TTestNumericsLib.AssertNear(const Expected, Actual, Tol: Double; const Msg: String);
begin
  AssertTrue(Msg + Format(' (expected %.10g, got %.10g, tol %.3g)',
    [Expected, Actual, Tol]), Abs(Expected - Actual) <= Tol);
end;

{ --- exception helpers --- }

procedure TTestNumericsLib.DoBisectionBadBracket;
begin
  { f(x)=x^2-2: f(2)=2>0, f(3)=7>0 → same sign, no root in [2,3] }
  TNumericsKit.Bisection(@FX_XSq_Minus2, 2, 3);
end;

procedure TTestNumericsLib.DoBrentBadBracket;
begin
  TNumericsKit.Brent(@FX_XSq_Minus2, 2, 3);
end;

procedure TTestNumericsLib.DoNewtonZeroDeriv;
begin
  { f(x)=1 everywhere, df(x)=0 → division by zero }
  TNumericsKit.NewtonRaphson(@F_Linear, @F_Quadratic, 0.0);
  { F_Linear(0)=1, F_Quadratic(0)=0 → df=0 }
end;

procedure TTestNumericsLib.DoSecantStuck;
begin
  { constant function → f(x0) = f(x1) → division by zero }
  TNumericsKit.Secant(@F_Quadratic, 0.0, 0.0);
end;

procedure TTestNumericsLib.DoTrapezoidalBadN;
begin
  TNumericsKit.TrapezoidalRule(@F_Linear, 0, 1, 0);
end;

procedure TTestNumericsLib.DoLinearInterpEmpty;
var X, Y: TDoubleArray;
begin
  SetLength(X, 0); SetLength(Y, 0);
  TNumericsKit.LinearInterp(X, Y, 0.5);
end;

procedure TTestNumericsLib.DoSplineTooFewKnots;
var X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(1.0);
  Y := TDoubleArray.Create(2.0);
  TNumericsKit.CubicSplineBuild(X, Y);
end;

{ =========================================================================
  Root Finding Tests
  ========================================================================= }

procedure TTestNumericsLib.Test01_Bisection_Sqrt2;
var Root: Double;
begin
  Root := TNumericsKit.Bisection(@FX_XSq_Minus2, 1.0, 2.0);
  AssertNear(Sqrt(2), Root, EPS_TIGHT, 'Bisection sqrt(2)');
end;

procedure TTestNumericsLib.Test02_Bisection_CubicRoot;
var Root: Double;
begin
  Root := TNumericsKit.Bisection(@FX_Cubic, 1.0, 2.0);
  AssertNear(1.5213797, Root, 1E-6, 'Bisection cubic root');
end;

procedure TTestNumericsLib.Test03_Bisection_BadBracket_Raises;
begin
  AssertException('Bisection bad bracket must raise',
    EInvalidArgument, @DoBisectionBadBracket);
end;

procedure TTestNumericsLib.Test04_NewtonRaphson_Sqrt2;
var Root: Double;
begin
  Root := TNumericsKit.NewtonRaphson(@FX_XSq_Minus2, @DFX_XSq_Minus2, 1.5);
  AssertNear(Sqrt(2), Root, EPS_TIGHT, 'Newton-Raphson sqrt(2)');
end;

procedure TTestNumericsLib.Test05_NewtonRaphson_Cubic;
var Root: Double;
begin
  Root := TNumericsKit.NewtonRaphson(@FX_Cubic, @DFX_Cubic, 1.5);
  AssertNear(1.5213797, Root, 1E-6, 'Newton-Raphson cubic');
end;

procedure TTestNumericsLib.Test06_Brent_Sqrt2;
var Root: Double;
begin
  Root := TNumericsKit.Brent(@FX_XSq_Minus2, 1.0, 2.0);
  AssertNear(Sqrt(2), Root, EPS_TIGHT, 'Brent sqrt(2)');
end;

procedure TTestNumericsLib.Test07_Brent_Transcendental;
var Root: Double;
begin
  { Dottie number: cos(x) = x  →  root ≈ 0.7390851332 }
  Root := TNumericsKit.Brent(@FX_CosX_MinusX, 0.0, 1.0);
  AssertNear(0.7390851332, Root, 1E-7, 'Brent Dottie number');
end;

procedure TTestNumericsLib.Test08_Brent_BadBracket_Raises;
begin
  AssertException('Brent bad bracket must raise',
    EInvalidArgument, @DoBrentBadBracket);
end;

procedure TTestNumericsLib.Test09_Secant_Sqrt2;
var Root: Double;
begin
  Root := TNumericsKit.Secant(@FX_XSq_Minus2, 1.0, 2.0);
  AssertNear(Sqrt(2), Root, EPS_TIGHT, 'Secant sqrt(2)');
end;

procedure TTestNumericsLib.Test10_Secant_Transcendental;
var Root: Double;
begin
  Root := TNumericsKit.Secant(@FX_CosX_MinusX, 0.5, 1.0);
  AssertNear(0.7390851332, Root, 1E-7, 'Secant Dottie number');
end;

{ =========================================================================
  Integration Tests
  ========================================================================= }

procedure TTestNumericsLib.Test11_Trapezoidal_Linear;
var R: Double;
begin
  { ∫₀¹ (2x+1) dx = 2  — trapezoidal is exact for linear functions }
  R := TNumericsKit.TrapezoidalRule(@F_Linear, 0, 1, 1000);
  AssertNear(2.0, R, EPS_QUAD, 'Trapezoidal linear');
end;

procedure TTestNumericsLib.Test12_Trapezoidal_Quadratic;
var R: Double;
begin
  { ∫₀¹ x² dx = 1/3 }
  R := TNumericsKit.TrapezoidalRule(@F_Quadratic, 0, 1, 10000);
  AssertNear(1/3, R, 1E-7, 'Trapezoidal quadratic');
end;

procedure TTestNumericsLib.Test13_Trapezoidal_BadN_Raises;
begin
  AssertException('Trapezoidal N=0 must raise',
    EInvalidArgument, @DoTrapezoidalBadN);
end;

procedure TTestNumericsLib.Test14_Simpson_Linear;
var R: Double;
begin
  { Exact for polynomials up to degree 3; linear is trivially exact }
  R := TNumericsKit.SimpsonRule(@F_Linear, 0, 1, 100);
  AssertNear(2.0, R, EPS_TIGHT, 'Simpson linear');
end;

procedure TTestNumericsLib.Test15_Simpson_Cubic;
var R: Double;
begin
  { ∫₀¹ x³ dx = 0.25 — Simpson's exact for degree ≤ 3 }
  R := TNumericsKit.SimpsonRule(@F_Cubic, 0, 1, 100);
  AssertNear(0.25, R, EPS_TIGHT, 'Simpson cubic');
end;

procedure TTestNumericsLib.Test16_Simpson_ForcesEvenN;
var R: Double;
begin
  { Pass odd N=5; SimpsonRule must auto-increment to 6 and still be accurate }
  R := TNumericsKit.SimpsonRule(@F_Quadratic, 0, 1, 5);
  AssertNear(1/3, R, 1E-5, 'Simpson odd N auto-fix');
end;

procedure TTestNumericsLib.Test17_GaussLegendre5_Polynomial;
var R: Double;
begin
  { Degree-9 polynomial: Gauss-Legendre 5 is exact for deg ≤ 9 }
  R := TNumericsKit.GaussLegendre5(@F_Poly9, 0, 1);
  AssertNear(0.1, R, EPS_TIGHT, 'Gauss-Legendre5 degree-9 polynomial');
end;

procedure TTestNumericsLib.Test18_GaussLegendre5_Sine;
var R: Double;
begin
  { ∫₀^π sin(x) dx = 2 }
  R := TNumericsKit.GaussLegendre5(@F_Sine, 0, Pi);
  AssertNear(2.0, R, 1E-4, 'Gauss-Legendre5 sin over [0,pi]');
end;

procedure TTestNumericsLib.Test19_GaussLegendre5_Exp;
var R: Double;
begin
  { ∫₀¹ exp(x) dx = e − 1 }
  R := TNumericsKit.GaussLegendre5(@F_Exp, 0, 1);
  AssertNear(Exp(1) - 1, R, 1E-6, 'Gauss-Legendre5 exp on [0,1]');
end;

{ =========================================================================
  ODE Solver Tests
  ========================================================================= }

procedure TTestNumericsLib.Test20_EulerStep_Exponential;
var Y1: Double;
begin
  { dy/dt=y, y(0)=1, h=0.01 → y(0.01) ≈ 1 + 0.01*1 = 1.01 }
  Y1 := TNumericsKit.EulerStep(@ODE_Exponential, 0, 1, 0.01);
  AssertNear(1.01, Y1, 1E-12, 'Euler single step');
end;

procedure TTestNumericsLib.Test21_EulerSolve_Exponential_FinalValue;
var Sol: TODESolution;
begin
  { dy/dt=y, y(0)=1, exact y(1)=e ≈ 2.71828.
    Euler is 1st-order; with 10000 steps error ~ h = 1e-4. }
  Sol := TNumericsKit.EulerSolve(@ODE_Exponential, 0, 1, 1, 10000);
  AssertNear(Exp(1), Sol.Y[10000], 3E-4, 'Euler solve exp, final value');
end;

procedure TTestNumericsLib.Test22_EulerSolve_Length;
var Sol: TODESolution;
begin
  Sol := TNumericsKit.EulerSolve(@ODE_Exponential, 0, 1, 1, 50);
  AssertEquals('Euler solution length', 51, Length(Sol.T));
  AssertEquals('Euler solution Y length', 51, Length(Sol.Y));
  AssertNear(0.0, Sol.T[0], EPS_TIGHT, 'Euler T[0] = 0');
  AssertNear(1.0, Sol.T[50], EPS_TIGHT, 'Euler T[50] = 1');
end;

procedure TTestNumericsLib.Test23_RK4Step_Exponential;
var Y1, Exact: Double;
begin
  { RK4 local error is O(h^5); with h=0.1, y(0)=1, exact y(0.1) = e^0.1 }
  Y1    := TNumericsKit.RK4Step(@ODE_Exponential, 0, 1, 0.1);
  Exact := Exp(0.1);
  AssertNear(Exact, Y1, 1E-7, 'RK4 single step accuracy');
end;

procedure TTestNumericsLib.Test24_RK4Solve_Exponential_Accuracy;
var Sol: TODESolution;
begin
  { RK4 with 100 steps over [0,1]: error should be well below 1e-7 }
  Sol := TNumericsKit.RK4Solve(@ODE_Exponential, 0, 1, 1, 100);
  AssertNear(Exp(1), Sol.Y[100], 1E-7, 'RK4 solve exp, final value');
end;

procedure TTestNumericsLib.Test25_RK4Solve_HarmonicOscillator;
var Sol: TODESolution;
begin
  { y(t) = cos(t), dy/dt = -sin(t).
    Start at y(0)=1, integrate to t=π: exact y(π) = cos(π) = -1. }
  Sol := TNumericsKit.RK4Solve(@ODE_HarmonicVelocity, 0, 1, Pi, 1000);
  AssertNear(-1.0, Sol.Y[1000], 1E-5, 'RK4 harmonic y(pi) = -1');
end;

procedure TTestNumericsLib.Test26_RK4Solve_Length;
var Sol: TODESolution;
begin
  Sol := TNumericsKit.RK4Solve(@ODE_Exponential, 0, 1, 1, 20);
  AssertEquals('RK4 length T', 21, Length(Sol.T));
  AssertEquals('RK4 length Y', 21, Length(Sol.Y));
end;

{ =========================================================================
  Interpolation Tests
  ========================================================================= }

procedure TTestNumericsLib.Test27_LinearInterp_ExactKnot;
var X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(0, 1, 2, 3);
  Y := TDoubleArray.Create(0, 1, 4, 9);
  AssertNear(4.0, TNumericsKit.LinearInterp(X, Y, 2.0), EPS_INTERP,
    'LinearInterp at knot x=2');
end;

procedure TTestNumericsLib.Test28_LinearInterp_Midpoint;
var X, Y: TDoubleArray;
begin
  { Linear data: Y = 2X → midpoint at x=0.5 should give 1.0 }
  X := TDoubleArray.Create(0, 1, 2);
  Y := TDoubleArray.Create(0, 2, 4);
  AssertNear(1.0, TNumericsKit.LinearInterp(X, Y, 0.5), EPS_INTERP,
    'LinearInterp midpoint linear data');
end;

procedure TTestNumericsLib.Test29_LinearInterp_ClampLeft;
var X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(1, 2, 3);
  Y := TDoubleArray.Create(10, 20, 30);
  AssertNear(10.0, TNumericsKit.LinearInterp(X, Y, -5.0), EPS_INTERP,
    'LinearInterp clamp left');
end;

procedure TTestNumericsLib.Test30_LinearInterp_ClampRight;
var X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(1, 2, 3);
  Y := TDoubleArray.Create(10, 20, 30);
  AssertNear(30.0, TNumericsKit.LinearInterp(X, Y, 100.0), EPS_INTERP,
    'LinearInterp clamp right');
end;

procedure TTestNumericsLib.Test31_LinearInterp_EmptyRaises;
begin
  AssertException('LinearInterp empty arrays must raise',
    EInvalidArgument, @DoLinearInterpEmpty);
end;

procedure TTestNumericsLib.Test32_LagrangeInterp_LinearData;
var X, Y: TDoubleArray;
begin
  { 3 points on line y=2x+1: Lagrange must reproduce it }
  X := TDoubleArray.Create(0, 1, 2);
  Y := TDoubleArray.Create(1, 3, 5);
  AssertNear(4.0, TNumericsKit.LagrangeInterp(X, Y, 1.5), EPS_INTERP,
    'Lagrange linear at x=1.5');
end;

procedure TTestNumericsLib.Test33_LagrangeInterp_QuadraticData;
var X, Y: TDoubleArray;
begin
  { y = x^2: 4 knots, query at x=1.5 → 2.25 }
  X := TDoubleArray.Create(0, 1, 2, 3);
  Y := TDoubleArray.Create(0, 1, 4, 9);
  AssertNear(2.25, TNumericsKit.LagrangeInterp(X, Y, 1.5), EPS_INTERP,
    'Lagrange quadratic at x=1.5');
end;

procedure TTestNumericsLib.Test34_LagrangeInterp_AtKnot;
var X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(1, 2, 3, 4, 5);
  Y := TDoubleArray.Create(1, 4, 9, 16, 25);
  AssertNear(9.0, TNumericsKit.LagrangeInterp(X, Y, 3.0), EPS_INTERP,
    'Lagrange at knot x=3');
end;

procedure TTestNumericsLib.Test35_CubicSpline_ExactAtKnots;
var X, Y: TDoubleArray;
    S: TCubicSpline;
    I: Integer;
begin
  X := TDoubleArray.Create(0, 1, 2, 3, 4);
  Y := TDoubleArray.Create(0, 1, 4, 9, 16);
  S := TNumericsKit.CubicSplineBuild(X, Y);
  for I := 0 to 4 do
    AssertNear(Y[I], TNumericsKit.CubicSplineEval(S, X[I]), EPS_TIGHT,
      Format('Spline exact at knot %d', [I]));
end;

procedure TTestNumericsLib.Test36_CubicSpline_LinearData_Accurate;
var X, Y: TDoubleArray;
    S: TCubicSpline;
begin
  { Cubic spline through linear data must reproduce the line exactly }
  X := TDoubleArray.Create(0, 1, 2, 3);
  Y := TDoubleArray.Create(0, 2, 4, 6);
  S := TNumericsKit.CubicSplineBuild(X, Y);
  AssertNear(3.0, TNumericsKit.CubicSplineEval(S, 1.5), 1E-6,
    'Spline linear data at x=1.5');
  AssertNear(5.0, TNumericsKit.CubicSplineEval(S, 2.5), 1E-6,
    'Spline linear data at x=2.5');
end;

procedure TTestNumericsLib.Test37_CubicSpline_QuadraticData_Accurate;
var X, Y: TDoubleArray;
    S: TCubicSpline;
begin
  { y=x^2 at integer knots 0..4; midpoints should be close to x^2 }
  X := TDoubleArray.Create(0, 1, 2, 3, 4);
  Y := TDoubleArray.Create(0, 1, 4, 9, 16);
  S := TNumericsKit.CubicSplineBuild(X, Y);
  { x=0.5 → exact=0.25; natural BC at boundary introduces more error }
  AssertNear(0.25, TNumericsKit.CubicSplineEval(S, 0.5), 0.12,
    'Spline x^2 at x=0.5 (natural BC may introduce small error)');
  { x=2.5 → exact=6.25 }
  AssertNear(6.25, TNumericsKit.CubicSplineEval(S, 2.5), 0.05,
    'Spline x^2 at x=2.5');
end;

procedure TTestNumericsLib.Test38_CubicSpline_Clamp;
var X, Y: TDoubleArray;
    S: TCubicSpline;
begin
  X := TDoubleArray.Create(1, 2, 3);
  Y := TDoubleArray.Create(10, 20, 30);
  S := TNumericsKit.CubicSplineBuild(X, Y);
  AssertNear(10.0, TNumericsKit.CubicSplineEval(S, -10.0), EPS_TIGHT,
    'Spline clamp left');
  AssertNear(30.0, TNumericsKit.CubicSplineEval(S, 100.0), EPS_TIGHT,
    'Spline clamp right');
end;

procedure TTestNumericsLib.Test39_CubicSpline_TooFewKnots_Raises;
begin
  AssertException('Spline 1 knot must raise',
    EInvalidArgument, @DoSplineTooFewKnots);
end;

procedure TTestNumericsLib.Test40_BisectionEndpointRootRegression;
var
  Outcome: TRootResult;
begin
  Outcome := TNumericsKit.BisectionResult(@FX_Identity, 0.0, 1.0, 1E-12, 50);
  AssertTrue('endpoint result converged', Outcome.Converged);
  AssertEquals('left endpoint root', 0.0, Outcome.Root, 0.0);
  AssertEquals('endpoint takes no iterations', 0, Outcome.Iterations);
end;

procedure TTestNumericsLib.Test41_RootConvergenceIsReported;
var
  Outcome: TRootResult;
begin
  Outcome := TNumericsKit.BisectionResult(@FX_XSq_Minus2, 0.0, 2.0,
    1E-15, 1);
  AssertFalse('one step cannot meet tight tolerance', Outcome.Converged);
  AssertEquals('iteration count is reported', 1, Outcome.Iterations);
  try
    TNumericsKit.Bisection(@FX_XSq_Minus2, 0.0, 2.0, 1E-15, 1);
    Fail('scalar compatibility API must raise on non-convergence');
  except
    on E: ENumericsConvergenceError do { expected };
  end;
end;

procedure TTestNumericsLib.Test42_InterpolationRejectsUnorderedKnots;
var
  X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(0.0, 2.0, 1.0);
  Y := TDoubleArray.Create(0.0, 4.0, 1.0);
  try
    TNumericsKit.LinearInterp(X, Y, 0.5);
    Fail('unordered knots must be rejected');
  except
    on E: EInvalidArgument do { expected };
  end;
end;

initialization
  RegisterTest(TTestNumericsLib);

end.
