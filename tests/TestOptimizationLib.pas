unit TestOptimizationLib;

{-----------------------------------------------------------------------------
 TestOptimizationLib

 Comprehensive tests for OptimizationLib.Optimization.
 All test functions have known analytical minima.

 Coverage
   GoldenSection      — unimodal 1-D bracket
   BrentMinimize      — parabolic + golden hybrid
   GradientDescent    — quadratic bowl with analytical gradient
   Adam               — non-convex Rosenbrock (numerical gradient)
   LBFGS              — quadratic, analytical gradient
   NelderMead         — Rosenbrock, Himmelblau (no gradient needed)
   SimulatedAnnealing — double-well, finds global minimum
   PenaltyMethod      — minimise subject to linear inequality constraint
   SimplexLP          — standard LP: feasible + optimal
   NumGrad            — verify numerical gradient vs analytical
   Maximize           — find maximum of concave function
   Error handling     — EOptimizationError
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  MathBase.SharedTypes,
  OptimizationLib.Optimization;

{ ---------------------------------------------------------------------------
  Shared test functions (must be global — passed as function pointers)
--------------------------------------------------------------------------- }

{ f(x) = (x-3)^2  — minimum at x=3 }
function Parabola1D(X: Double): Double;

{ f(x) = (x-2)^4 + (x-2)  — minimum near x ≈ 1.21 }
function Quartic1D(X: Double): Double;

{ f(x,y) = (x-2)^2 + (y+1)^2  — minimum at (2,-1) }
function QuadraticBowl(const X: TDoubleArray): Double;

{ Gradient of QuadraticBowl }
function QuadraticBowlGrad(const X: TDoubleArray): TDoubleArray;

{ Rosenbrock banana: f(x,y)=100(y-x^2)^2+(1-x)^2  — minimum at (1,1) }
function Rosenbrock(const X: TDoubleArray): Double;

{ Himmelblau: f(x,y)=(x^2+y-11)^2+(x+y^2-7)^2  — 4 minima all = 0 }
function Himmelblau(const X: TDoubleArray): Double;

{ Double-well: f(x)=(x^2-1)^2  — two minima at x=±1, max at x=0 }
function DoubleWell(const X: TDoubleArray): Double;

{ Negative concave paraboloid: -((x-1)^2+(y-2)^2-5)  — max at (1,2) }
function ConcaveParaboloid(const X: TDoubleArray): Double;

{ f([x]) = (x-5)^2 — 1-D NelderMead test, min at x=5 }
function F1D(const X: TDoubleArray): Double;

{ Penalty test: (x-5)^2 + (y-5)^2 — unconstrained min at (5,5) }
function ObjFn(const X: TDoubleArray): Double;

{ Penalty constraint: x+y <= 6 (written as x+y-6 <= 0) }
function Constraint1(const X: TDoubleArray): Double;

{ Penalty test 2: x^2 + y^2 }
function ObjSimple(const X: TDoubleArray): Double;

{ Penalty constraint 2: x[0] <= 1 }
function ConstrX1(const X: TDoubleArray): Double;

type
  TTestOptimizationLib = class(TTestCase)
  private
    const
      EPS_TIGHT  = 1E-5;
      EPS_MED    = 1E-3;
      EPS_LOOSE  = 1E-2;

    procedure AssertNear(const Expected, Actual, Tol: Double; const Msg: String = '');

    procedure DoGoldenSection_BadBracket;
    procedure DoBrentMin_BadBracket;
    procedure DoGradDesc_EmptyX0;
    procedure DoNelderMead_EmptyX0;
    procedure DoSA_EmptyX0;
    procedure DoSimplexLP_NoConstraints;

  published
    { -----------------------------------------------------------------------
      GOLDEN SECTION
    ----------------------------------------------------------------------- }
    procedure Test01_GoldenSection_Parabola;
    procedure Test02_GoldenSection_Quartic;
    procedure Test03_GoldenSection_BadBracket_Raises;

    { -----------------------------------------------------------------------
      BRENT MINIMIZE
    ----------------------------------------------------------------------- }
    procedure Test04_BrentMin_Parabola;
    procedure Test05_BrentMin_Quartic;
    procedure Test06_BrentMin_BadBracket_Raises;

    { -----------------------------------------------------------------------
      GRADIENT DESCENT
    ----------------------------------------------------------------------- }
    procedure Test07_GradDesc_Quadratic_Analytical;
    procedure Test08_GradDesc_Quadratic_Numerical;
    procedure Test09_GradDesc_Converges;
    procedure Test10_GradDesc_EmptyX0_Raises;

    { -----------------------------------------------------------------------
      ADAM
    ----------------------------------------------------------------------- }
    procedure Test11_Adam_Quadratic;
    procedure Test12_Adam_Rosenbrock;
    procedure Test13_Adam_Converges;

    { -----------------------------------------------------------------------
      L-BFGS
    ----------------------------------------------------------------------- }
    procedure Test14_LBFGS_Quadratic_Analytical;
    procedure Test15_LBFGS_Quadratic_Numerical;
    procedure Test16_LBFGS_Rosenbrock;

    { -----------------------------------------------------------------------
      NELDER-MEAD
    ----------------------------------------------------------------------- }
    procedure Test17_NelderMead_Quadratic;
    procedure Test18_NelderMead_Rosenbrock;
    procedure Test19_NelderMead_Himmelblau;
    procedure Test20_NelderMead_1D;
    procedure Test21_NelderMead_EmptyX0_Raises;

    { -----------------------------------------------------------------------
      SIMULATED ANNEALING
    ----------------------------------------------------------------------- }
    procedure Test22_SA_DoubleWell_FindsGlobal;
    procedure Test23_SA_Quadratic;
    procedure Test24_SA_Reproducible;

    { -----------------------------------------------------------------------
      PENALTY METHOD
    ----------------------------------------------------------------------- }
    procedure Test25_Penalty_LinearConstraint;
    procedure Test26_Penalty_FeasibleStart;

    { -----------------------------------------------------------------------
      SIMPLEX LP
    ----------------------------------------------------------------------- }
    procedure Test27_SimplexLP_Basic;
    procedure Test28_SimplexLP_Optimal;
    procedure Test29_SimplexLP_Feasible;

    { -----------------------------------------------------------------------
      UTILITIES
    ----------------------------------------------------------------------- }
    procedure Test30_NumGrad_Quadratic;
    procedure Test31_Maximize_Paraboloid;

  end;

implementation

{ ---------------------------------------------------------------------------
  Test function implementations
--------------------------------------------------------------------------- }

function Parabola1D(X: Double): Double;
begin Result := (X - 3) * (X - 3); end;

function Quartic1D(X: Double): Double;
begin Result := Power(X - 2, 4) + (X - 2); end;

function QuadraticBowl(const X: TDoubleArray): Double;
begin Result := Sqr(X[0] - 2) + Sqr(X[1] + 1); end;

function QuadraticBowlGrad(const X: TDoubleArray): TDoubleArray;
begin
  SetLength(Result, 2);
  Result[0] := 2 * (X[0] - 2);
  Result[1] := 2 * (X[1] + 1);
end;

function Rosenbrock(const X: TDoubleArray): Double;
begin
  Result := 100 * Sqr(X[1] - X[0]*X[0]) + Sqr(1 - X[0]);
end;

function Himmelblau(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0]*X[0] + X[1] - 11) + Sqr(X[0] + X[1]*X[1] - 7);
end;

function DoubleWell(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]*X[0] - 1); end;

function ConcaveParaboloid(const X: TDoubleArray): Double;
begin Result := -(Sqr(X[0]-1) + Sqr(X[1]-2) - 5); end;

function F1D(const X: TDoubleArray): Double;
begin Result := Sqr(X[0] - 5); end;

function ObjFn(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]-5) + Sqr(X[1]-5); end;

function Constraint1(const X: TDoubleArray): Double;
begin Result := X[0] + X[1] - 6; end;

function ObjSimple(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]) + Sqr(X[1]); end;

function ConstrX1(const X: TDoubleArray): Double;
begin Result := X[0] - 1; end;

{ ---------------------------------------------------------------------------
  Test class helpers
--------------------------------------------------------------------------- }

procedure TTestOptimizationLib.AssertNear(const Expected, Actual, Tol: Double; const Msg: String);
begin
  if Abs(Expected - Actual) > Tol then
    Fail(Format('%s  expected %.10f  got %.10f  (tol %.2e)',
      [Msg, Expected, Actual, Tol]));
end;

procedure TTestOptimizationLib.DoGoldenSection_BadBracket;
begin TOptimizationKit.GoldenSection(@Parabola1D, 5, 1); end;

procedure TTestOptimizationLib.DoBrentMin_BadBracket;
begin TOptimizationKit.BrentMinimize(@Parabola1D, 5, 1); end;

procedure TTestOptimizationLib.DoGradDesc_EmptyX0;
var E: TDoubleArray; begin SetLength(E, 0); TOptimizationKit.GradientDescent(@QuadraticBowl, nil, E); end;

procedure TTestOptimizationLib.DoNelderMead_EmptyX0;
var E: TDoubleArray; begin SetLength(E, 0); TOptimizationKit.NelderMead(@QuadraticBowl, E); end;

procedure TTestOptimizationLib.DoSA_EmptyX0;
var E: TDoubleArray; begin SetLength(E, 0); TOptimizationKit.SimulatedAnnealing(@QuadraticBowl, E); end;

procedure TTestOptimizationLib.DoSimplexLP_NoConstraints;
var E: TDoubleArray; begin SetLength(E, 0); TOptimizationKit.SimplexLP(TDoubleArray.Create(1), [], E); end;

{ ===========================================================================
  GOLDEN SECTION
=========================================================================== }

procedure TTestOptimizationLib.Test01_GoldenSection_Parabola;
var XMin: Double;
begin
  XMin := TOptimizationKit.GoldenSection(@Parabola1D, 0, 10);
  AssertNear(3.0, XMin, EPS_TIGHT, 'GoldenSection parabola min');
end;

procedure TTestOptimizationLib.Test02_GoldenSection_Quartic;
{ (x-2)^4 + (x-2) minimum at x = 2 - (1/4)^(1/3) ≈ 1.3700 }
var XMin: Double;
begin
  XMin := TOptimizationKit.GoldenSection(@Quartic1D, 0, 4);
  AssertNear(1.3700, XMin, EPS_MED, 'GoldenSection quartic min');
end;

procedure TTestOptimizationLib.Test03_GoldenSection_BadBracket_Raises;
begin
  AssertException('GoldenSection B<=A', EOptimizationError,
    @DoGoldenSection_BadBracket);
end;

{ ===========================================================================
  BRENT MINIMIZE
=========================================================================== }

procedure TTestOptimizationLib.Test04_BrentMin_Parabola;
var XMin: Double;
begin
  XMin := TOptimizationKit.BrentMinimize(@Parabola1D, 0, 10);
  AssertNear(3.0, XMin, EPS_TIGHT, 'BrentMin parabola');
end;

procedure TTestOptimizationLib.Test05_BrentMin_Quartic;
var XMin: Double;
begin
  XMin := TOptimizationKit.BrentMinimize(@Quartic1D, 0, 4);
  AssertNear(1.3700, XMin, EPS_MED, 'BrentMin quartic');
end;

procedure TTestOptimizationLib.Test06_BrentMin_BadBracket_Raises;
begin
  AssertException('BrentMin B<=A', EOptimizationError, @DoBrentMin_BadBracket);
end;

{ ===========================================================================
  GRADIENT DESCENT
=========================================================================== }

procedure TTestOptimizationLib.Test07_GradDesc_Quadratic_Analytical;
var R: TOptResult;
begin
  R := TOptimizationKit.GradientDescent(@QuadraticBowl, @QuadraticBowlGrad,
    TDoubleArray.Create(0, 0));
  AssertNear(2.0,  R.X[0], EPS_MED, 'GradDesc x[0]');
  AssertNear(-1.0, R.X[1], EPS_MED, 'GradDesc x[1]');
  AssertNear(0.0,  R.FVal, EPS_MED, 'GradDesc FVal');
end;

procedure TTestOptimizationLib.Test08_GradDesc_Quadratic_Numerical;
var R: TOptResult;
begin
  R := TOptimizationKit.GradientDescent(@QuadraticBowl, nil,
    TDoubleArray.Create(5, 5));
  AssertNear(2.0,  R.X[0], EPS_MED, 'GradDesc num x[0]');
  AssertNear(-1.0, R.X[1], EPS_MED, 'GradDesc num x[1]');
end;

procedure TTestOptimizationLib.Test09_GradDesc_Converges;
var R: TOptResult;
begin
  R := TOptimizationKit.GradientDescent(@QuadraticBowl, @QuadraticBowlGrad,
    TDoubleArray.Create(0, 0));
  AssertTrue('GradDesc converged', R.Converged);
end;

procedure TTestOptimizationLib.Test10_GradDesc_EmptyX0_Raises;
begin
  AssertException('GradDesc empty X0', EOptimizationError, @DoGradDesc_EmptyX0);
end;

{ ===========================================================================
  ADAM
=========================================================================== }

procedure TTestOptimizationLib.Test11_Adam_Quadratic;
var R: TOptResult;
begin
  R := TOptimizationKit.Adam(@QuadraticBowl, @QuadraticBowlGrad,
    TDoubleArray.Create(0, 0));
  AssertNear(2.0,  R.X[0], EPS_MED, 'Adam quadratic x[0]');
  AssertNear(-1.0, R.X[1], EPS_MED, 'Adam quadratic x[1]');
end;

procedure TTestOptimizationLib.Test12_Adam_Rosenbrock;
{ Rosenbrock is notoriously hard — expect loose tolerance }
var R: TOptResult;
begin
  R := TOptimizationKit.Adam(@Rosenbrock, nil,
    TDoubleArray.Create(0, 0), 0.01, 0.9, 0.999, 1E-8, 1E-5, 50000);
  AssertNear(1.0, R.X[0], EPS_LOOSE, 'Adam Rosenbrock x[0]');
  AssertNear(1.0, R.X[1], EPS_LOOSE, 'Adam Rosenbrock x[1]');
end;

procedure TTestOptimizationLib.Test13_Adam_Converges;
var R: TOptResult;
begin
  R := TOptimizationKit.Adam(@QuadraticBowl, @QuadraticBowlGrad,
    TDoubleArray.Create(0, 0));
  AssertTrue('Adam converged', R.Converged);
end;

{ ===========================================================================
  L-BFGS
=========================================================================== }

procedure TTestOptimizationLib.Test14_LBFGS_Quadratic_Analytical;
var R: TOptResult;
begin
  R := TOptimizationKit.LBFGS(@QuadraticBowl, @QuadraticBowlGrad,
    TDoubleArray.Create(0, 0));
  AssertNear(2.0,  R.X[0], EPS_TIGHT, 'LBFGS x[0]');
  AssertNear(-1.0, R.X[1], EPS_TIGHT, 'LBFGS x[1]');
  AssertNear(0.0,  R.FVal, EPS_TIGHT, 'LBFGS FVal');
end;

procedure TTestOptimizationLib.Test15_LBFGS_Quadratic_Numerical;
var R: TOptResult;
begin
  R := TOptimizationKit.LBFGS(@QuadraticBowl, nil,
    TDoubleArray.Create(10, -10));
  AssertNear(2.0,  R.X[0], EPS_MED, 'LBFGS num x[0]');
  AssertNear(-1.0, R.X[1], EPS_MED, 'LBFGS num x[1]');
end;

procedure TTestOptimizationLib.Test16_LBFGS_Rosenbrock;
var R: TOptResult;
begin
  R := TOptimizationKit.LBFGS(@Rosenbrock, nil,
    TDoubleArray.Create(0, 0), 10, 1E-6, 2000);
  AssertNear(1.0, R.X[0], EPS_MED, 'LBFGS Rosenbrock x[0]');
  AssertNear(1.0, R.X[1], EPS_MED, 'LBFGS Rosenbrock x[1]');
end;

{ ===========================================================================
  NELDER-MEAD
=========================================================================== }

procedure TTestOptimizationLib.Test17_NelderMead_Quadratic;
var R: TOptResult;
begin
  R := TOptimizationKit.NelderMead(@QuadraticBowl,
    TDoubleArray.Create(0, 0));
  AssertNear(2.0,  R.X[0], EPS_MED, 'NelderMead quadratic x[0]');
  AssertNear(-1.0, R.X[1], EPS_MED, 'NelderMead quadratic x[1]');
  AssertNear(0.0,  R.FVal, EPS_MED, 'NelderMead FVal');
end;

procedure TTestOptimizationLib.Test18_NelderMead_Rosenbrock;
var R: TOptResult;
begin
  R := TOptimizationKit.NelderMead(@Rosenbrock,
    TDoubleArray.Create(0, 0), 1.0, 1E-8, 20000);
  AssertNear(1.0, R.X[0], EPS_MED, 'NelderMead Rosenbrock x[0]');
  AssertNear(1.0, R.X[1], EPS_MED, 'NelderMead Rosenbrock x[1]');
end;

procedure TTestOptimizationLib.Test19_NelderMead_Himmelblau;
{ Himmelblau has 4 minima all at f=0; start near (3,2) → minimum (3,2) }
var R: TOptResult;
begin
  R := TOptimizationKit.NelderMead(@Himmelblau,
    TDoubleArray.Create(3, 2));
  AssertNear(0.0, R.FVal, EPS_MED, 'NelderMead Himmelblau fval');
end;

procedure TTestOptimizationLib.Test20_NelderMead_1D;
{ Degenerate 1-D case: f([x]) = (x-5)^2 }
var R: TOptResult;
begin
  R := TOptimizationKit.NelderMead(@F1D, TDoubleArray.Create(0));
  AssertNear(5.0, R.X[0], EPS_MED, 'NelderMead 1D');
end;

procedure TTestOptimizationLib.Test21_NelderMead_EmptyX0_Raises;
begin
  AssertException('NelderMead empty X0', EOptimizationError,
    @DoNelderMead_EmptyX0);
end;

{ ===========================================================================
  SIMULATED ANNEALING
=========================================================================== }

procedure TTestOptimizationLib.Test22_SA_DoubleWell_FindsGlobal;
{ (x^2-1)^2 has two minima at x=±1. SA should find one of them. }
var R: TOptResult;
begin
  R := TOptimizationKit.SimulatedAnnealing(@DoubleWell,
    TDoubleArray.Create(0), { start at local max }
    100, 1E-6, 0.995, 0.1, 100000, 42);
  AssertNear(0.0, R.FVal, EPS_MED, 'SA DoubleWell fval');
  AssertNear(1.0, Abs(R.X[0]), EPS_MED, 'SA DoubleWell |x|=1');
end;

procedure TTestOptimizationLib.Test23_SA_Quadratic;
var R: TOptResult;
begin
  R := TOptimizationKit.SimulatedAnnealing(@QuadraticBowl,
    TDoubleArray.Create(0, 0),
    50, 1E-6, 0.999, 0.05, 200000, 1);
  AssertNear(0.0, R.FVal, EPS_LOOSE, 'SA quadratic fval');
end;

procedure TTestOptimizationLib.Test24_SA_Reproducible;
{ Same seed must produce same result }
var R1, R2: TOptResult;
begin
  R1 := TOptimizationKit.SimulatedAnnealing(@DoubleWell,
    TDoubleArray.Create(0), 100, 1E-6, 0.995, 0.1, 10000, 99);
  R2 := TOptimizationKit.SimulatedAnnealing(@DoubleWell,
    TDoubleArray.Create(0), 100, 1E-6, 0.995, 0.1, 10000, 99);
  AssertNear(R1.X[0], R2.X[0], EPS_TIGHT, 'SA reproducible X');
  AssertNear(R1.FVal, R2.FVal, EPS_TIGHT, 'SA reproducible FVal');
end;

{ ===========================================================================
  PENALTY METHOD
=========================================================================== }

procedure TTestOptimizationLib.Test25_Penalty_LinearConstraint;
{ minimise (x-5)^2 + (y-5)^2  subject to x+y <= 6
  Unconstrained min = (5,5), constrained min = (3,3), fval = 8 }
var R: TOptResult;
begin
  R := TOptimizationKit.PenaltyMethod(@ObjFn,
    [TConstraintFunc(@Constraint1)],
    TDoubleArray.Create(1, 1));
  AssertNear(3.0, R.X[0], EPS_MED, 'Penalty x[0]');
  AssertNear(3.0, R.X[1], EPS_MED, 'Penalty x[1]');
  AssertNear(8.0, R.FVal, EPS_MED, 'Penalty fval');
end;

procedure TTestOptimizationLib.Test26_Penalty_FeasibleStart;
{ Feasible starting point should still converge }
var R: TOptResult;
begin
  R := TOptimizationKit.PenaltyMethod(@ObjSimple,
    [TConstraintFunc(@ConstrX1)],
    TDoubleArray.Create(0.5, 0));  { feasible start }
  AssertNear(0.0, R.X[0], EPS_MED, 'Penalty feasible x[0]');
  AssertNear(0.0, R.X[1], EPS_MED, 'Penalty feasible x[1]');
end;

{ ===========================================================================
  SIMPLEX LP
=========================================================================== }

procedure TTestOptimizationLib.Test27_SimplexLP_Basic;
{ min -x1-x2  s.t. x1+x2<=4, x1<=3, x2<=3, x>=0
  Optimal: x1=x2=2 or x1=1,x2=3 etc; ObjVal = -4 }
var R: TLPResult;
begin
  R := TOptimizationKit.SimplexLP(
    TDoubleArray.Create(-1, -1),
    [TDoubleArray.Create(1,1), TDoubleArray.Create(1,0), TDoubleArray.Create(0,1)],
    TDoubleArray.Create(4, 3, 3));
  AssertTrue('LP feasible', R.Feasible);
  AssertNear(-4.0, R.ObjVal, EPS_MED, 'LP objective = -4');
end;

procedure TTestOptimizationLib.Test28_SimplexLP_Optimal;
{ min 2x1+3x2  s.t. x1+x2>=1 → rewrite: -x1-x2<=-1 → multiply by -1
  Actually use: min 2x1+3x2  s.t. x1>=0.5 → use slack
  Simpler: min x1  s.t. x1 <= 5, x1 >= 0 → optimal x1=0, obj=0 }
var R: TLPResult;
begin
  R := TOptimizationKit.SimplexLP(
    TDoubleArray.Create(1),
    [TDoubleArray.Create(1)],
    TDoubleArray.Create(5));
  AssertTrue('LP2 feasible', R.Feasible);
  AssertNear(0.0, R.ObjVal, EPS_MED, 'LP2 min = 0');
  AssertNear(0.0, R.X[0],   EPS_MED, 'LP2 x[0] = 0');
end;

procedure TTestOptimizationLib.Test29_SimplexLP_Feasible;
{ Solution must satisfy all constraints }
var R: TLPResult;
    SumXY: Double;
begin
  R := TOptimizationKit.SimplexLP(
    TDoubleArray.Create(-1, -1),
    [TDoubleArray.Create(1,1), TDoubleArray.Create(1,0), TDoubleArray.Create(0,1)],
    TDoubleArray.Create(4, 3, 3));
  SumXY := R.X[0] + R.X[1];
  AssertTrue('x1+x2 <= 4', SumXY <= 4 + EPS_MED);
  AssertTrue('x1 >= 0', R.X[0] >= -EPS_MED);
  AssertTrue('x2 >= 0', R.X[1] >= -EPS_MED);
end;

{ ===========================================================================
  UTILITIES
=========================================================================== }

procedure TTestOptimizationLib.Test30_NumGrad_Quadratic;
{ Gradient of QuadraticBowl at (3,-2): analytical = [2,−2] }
var G: TDoubleArray;
begin
  G := TOptimizationKit.NumGrad(@QuadraticBowl, TDoubleArray.Create(3, -2));
  AssertNear(2.0,  G[0], EPS_MED, 'NumGrad G[0]');
  AssertNear(-2.0, G[1], EPS_MED, 'NumGrad G[1]');
end;

procedure TTestOptimizationLib.Test31_Maximize_Paraboloid;
{ -(x-1)^2-(y-2)^2+5 has maximum 5 at (1,2) }
var R: TOptResult;
begin
  R := TOptimizationKit.Maximize(@ConcaveParaboloid,
    TDoubleArray.Create(0, 0));
  AssertNear(1.0, R.X[0], EPS_MED, 'Maximize x[0]');
  AssertNear(2.0, R.X[1], EPS_MED, 'Maximize x[1]');
  AssertNear(5.0, R.FVal, EPS_MED, 'Maximize fval');
end;

initialization
  RegisterTest(TTestOptimizationLib);

end.
