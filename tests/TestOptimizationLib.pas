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
  MathBase.SharedTypes, MathBase.Iteration,
  NumericsLib.Differentiation,
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

function WrongSizeGradient(const X: TDoubleArray): TDoubleArray;
function QuadraticBowlDual(const X:TDualArray):TDual;
function Constraint1Grad(const X:TDoubleArray):TDoubleArray;
function ParetoLeft(const X:TDoubleArray):Double;
function ParetoRight(const X:TDoubleArray):Double;

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
    procedure Test32_ScalarNonConvergenceRaises;
    procedure Test33_SimplexReportsUnboundedStatus;
    procedure Test34_GradientDimensionValidation;
    procedure Test35_DetailedSmoothOptimizers;
    procedure Test36_BoundedAndMultistart;
    procedure Test37_ConstrainedFeasibility;
    procedure Test38_AutomaticDerivativeOptimizer;
    procedure Test39_MultiobjectiveOutcomes;
    procedure Test40_SimplexPhaseOneFindsFeasibleBasis;
    procedure Test41_SimplexPhaseOneReportsInfeasible;
    procedure Test42_LegacyOptimizersPopulateDiagnostics;

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
  Result := nil;
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

function WrongSizeGradient(const X: TDoubleArray): TDoubleArray;
begin
  Result := TDoubleArray.Create(1.0);
end;

function QuadraticBowlDual(const X:TDualArray):TDual;
begin
  Result:=(X[0]-2)*(X[0]-2)+(X[1]+1)*(X[1]+1);
end;

function Constraint1Grad(const X:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(1,1);
end;

function ParetoLeft(const X:TDoubleArray):Double;
begin Result:=Sqr(X[0]); end;

function ParetoRight(const X:TDoubleArray):Double;
begin Result:=Sqr(X[0]-2); end;

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

procedure TTestOptimizationLib.Test32_ScalarNonConvergenceRaises;
begin
  try
    TOptimizationKit.GoldenSection(@Parabola1D, 0.0, 10.0, 1E-30, 1);
    Fail('GoldenSection must report iteration exhaustion');
  except
    on E: EOptimizationError do { expected };
  end;
end;

procedure TTestOptimizationLib.Test33_SimplexReportsUnboundedStatus;
var
  C, B: TDoubleArray;
  A: array of TDoubleArray;
  R: TLPResult;
begin
  C := TDoubleArray.Create(-1.0);
  B := TDoubleArray.Create(1.0);
  SetLength(A, 1);
  A[0] := TDoubleArray.Create(0.0);
  R := TOptimizationKit.SimplexLP(C, A, B);
  AssertEquals('unbounded status', Ord(lpsUnbounded), Ord(R.Status));
  AssertFalse('unbounded result is not feasible/optimal', R.Feasible);
end;

procedure TTestOptimizationLib.Test34_GradientDimensionValidation;
begin
  try
    TOptimizationKit.GradientDescent(@QuadraticBowl, @WrongSizeGradient,
      TDoubleArray.Create(0.0, 0.0));
    Fail('wrong gradient dimension must raise');
  except
    on E: EOptimizationError do { expected };
  end;
end;

procedure TTestOptimizationLib.Test35_DetailedSmoothOptimizers;
var
  O:TOptimizationOptions;
  R:TOptResult;
begin
  O:=TOptimizationOptions.Defaults;
  O.MaxIterations:=500;
  R:=TOptimizationKit.NonlinearConjugateGradient(@QuadraticBowl,
    @QuadraticBowlGrad,TDoubleArray.Create(-4,5),O);
  AssertEquals('nonlinear CG status',Ord(isConverged),Ord(R.Status));
  AssertNear(2,R.X[0],1E-6,'nonlinear CG x');
  AssertNear(-1,R.X[1],1E-6,'nonlinear CG y');
  AssertTrue('nonlinear CG evaluations',R.Evaluations>0);
  AssertTrue('nonlinear CG owns best point',Length(R.BestX)=2);
  R:=TOptimizationKit.TrustRegion(@QuadraticBowl,@QuadraticBowlGrad,
    TDoubleArray.Create(-4,5),O);
  AssertEquals('trust-region status',Ord(isConverged),Ord(R.Status));
  AssertNear(2,R.X[0],1E-5,'trust-region x');
  AssertNear(-1,R.X[1],1E-5,'trust-region y');
end;

procedure TTestOptimizationLib.Test36_BoundedAndMultistart;
var
  O:TOptimizationOptions;
  R:TOptResult;
  Starts:TObjectiveMatrix;
begin
  O:=TOptimizationOptions.Defaults;
  O.LowerBounds:=TDoubleArray.Create(0,-2);
  O.UpperBounds:=TDoubleArray.Create(1,-0.5);
  R:=TOptimizationKit.BoundedLBFGS(@QuadraticBowl,@QuadraticBowlGrad,
    TDoubleArray.Create(-4,5),O);
  AssertEquals('bounded L-BFGS status',Ord(isConverged),Ord(R.Status));
  AssertNear(1,R.X[0],1E-7,'bounded L-BFGS active bound');
  AssertNear(-1,R.X[1],1E-7,'bounded L-BFGS free variable');
  O:=TOptimizationOptions.Defaults;
  O.StartCount:=4;
  SetLength(Starts,2);
  Starts[0]:=TDoubleArray.Create(-2);
  Starts[1]:=TDoubleArray.Create(2);
  R:=TOptimizationKit.MultiStart(@DoubleWell,nil,Starts,O);
  AssertTrue('multistart usable',
    R.Status in [isConverged,isAcceptableLimit]);
  AssertNear(0,R.FVal,1E-8,'multistart best objective');
  AssertNear(1,Abs(R.X[0]),1E-5,'multistart well');
end;

procedure TTestOptimizationLib.Test37_ConstrainedFeasibility;
var
  O:TOptimizationOptions;
  C:TSmoothConstraints;
  R:TOptResult;
begin
  O:=TOptimizationOptions.Defaults;
  O.MaxIterations:=1000;
  O.GradientTolerance:=1E-6;
  SetLength(C,1);
  C[0].Value:=@Constraint1;
  C[0].Gradient:=@Constraint1Grad;
  C[0].Kind:=ckInequality;
  C[0].Tolerance:=1E-7;
  R:=TOptimizationKit.SolveConstrained(@ObjFn,nil,C,
    TDoubleArray.Create(0,0),O);
  AssertTrue(Format('constrained solver usable: status=%s x=(%.6g,%.6g) feasibility=%.6g',
    [IterationStatusName(R.Status),R.X[0],R.X[1],R.ConstraintViolation]),
    R.Status in [isConverged,isAcceptableLimit]);
  AssertTrue('constrained feasibility',R.ConstraintViolation<=1E-5);
  AssertNear(3,R.X[0],2E-3,'constrained x');
  AssertNear(3,R.X[1],2E-3,'constrained y');
end;

procedure TTestOptimizationLib.Test38_AutomaticDerivativeOptimizer;
var
  O:TOptimizationOptions;
  R:TOptResult;
begin
  O:=TOptimizationOptions.Defaults;
  R:=TOptimizationKit.LBFGSAuto(@QuadraticBowlDual,
    TDoubleArray.Create(-4,5),O);
  AssertEquals('automatic L-BFGS status',Ord(isConverged),Ord(R.Status));
  AssertNear(2,R.X[0],1E-7,'automatic L-BFGS x');
  AssertNear(-1,R.X[1],1E-7,'automatic L-BFGS y');
end;

procedure TTestOptimizationLib.Test39_MultiobjectiveOutcomes;
var
  O:TOptimizationOptions;
  Objectives:TMultivarFunctions;
  Initial,Weights:TObjectiveMatrix;
  R:TMultiObjectiveResult;
  I:Integer;
begin
  O:=TOptimizationOptions.Defaults;
  SetLength(Objectives,2);
  Objectives[0]:=@ParetoLeft;
  Objectives[1]:=@ParetoRight;
  SetLength(Initial,1);
  Initial[0]:=TDoubleArray.Create(1);
  SetLength(Weights,3);
  Weights[0]:=TDoubleArray.Create(1,0);
  Weights[1]:=TDoubleArray.Create(0.5,0.5);
  Weights[2]:=TDoubleArray.Create(0,1);
  R:=TOptimizationKit.ExplorePareto(Objectives,Initial,Weights,O);
  AssertTrue('Pareto status usable',
    R.Status in [isConverged,isAcceptableLimit]);
  AssertEquals('three nondominated weighted points',3,Length(R.Points));
  for I:=0 to High(R.Points) do
    AssertTrue('Pareto point lies between extremes',
      (R.Points[I].X[0]>=-1E-5) and (R.Points[I].X[0]<=2+1E-5));
end;

procedure TTestOptimizationLib.Test40_SimplexPhaseOneFindsFeasibleBasis;
{ min x subject to 1 <= x <= 2.  The negative right-hand side requires
  phase I because the all-slack starting point is not feasible. }
var
  R:TLPResult;
begin
  R:=TOptimizationKit.SimplexLP(
    TDoubleArray.Create(1),
    [TDoubleArray.Create(-1),TDoubleArray.Create(1)],
    TDoubleArray.Create(-1,2));
  AssertEquals('phase-I feasible status',Ord(lpsOptimal),Ord(R.Status));
  AssertTrue('phase-I result feasible',R.Feasible);
  AssertNear(1,R.X[0],1E-9,'phase-I lower-bound solution');
  AssertNear(1,R.ObjVal,1E-9,'phase-I objective');
end;

procedure TTestOptimizationLib.Test41_SimplexPhaseOneReportsInfeasible;
{ x <= 0 and x >= 1 cannot both hold. }
var
  R:TLPResult;
begin
  R:=TOptimizationKit.SimplexLP(
    TDoubleArray.Create(1),
    [TDoubleArray.Create(1),TDoubleArray.Create(-1)],
    TDoubleArray.Create(0,-1));
  AssertEquals('phase-I infeasible status',Ord(lpsInfeasible),Ord(R.Status));
  AssertFalse('infeasible result is not feasible',R.Feasible);
end;

procedure TTestOptimizationLib.Test42_LegacyOptimizersPopulateDiagnostics;
var
  R:TOptResult;
  O:TOptimizationOptions;
  Workspace:TOptimizationWorkspace;
  FirstEvaluations:Integer;
begin
  R:=TOptimizationKit.GradientDescent(@QuadraticBowl,@QuadraticBowlGrad,
    TDoubleArray.Create(-4,5),0.1,1E-6,500);
  AssertTrue('gradient-descent evaluations',R.Evaluations>0);
  AssertEquals('gradient-descent best point dimension',2,Length(R.BestX));
  AssertTrue('gradient-descent best no worse than final',
    R.BestFVal<=R.FVal+1E-12);

  R:=TOptimizationKit.Adam(@QuadraticBowl,@QuadraticBowlGrad,
    TDoubleArray.Create(-4,5),0.05,0.9,0.999,1E-8,1E-5,2000);
  AssertTrue('Adam evaluations',R.Evaluations>0);
  AssertEquals('Adam best point dimension',2,Length(R.BestX));

  R:=TOptimizationKit.NelderMead(@QuadraticBowl,
    TDoubleArray.Create(-4,5));
  AssertTrue('Nelder-Mead evaluations',R.Evaluations>0);
  AssertNear(R.FVal,R.BestFVal,0,'Nelder-Mead best objective');

  R:=TOptimizationKit.SimulatedAnnealing(@DoubleWell,
    TDoubleArray.Create(0),10,1E-3,0.99,0.1,2000,42);
  AssertTrue('annealing evaluations',R.Evaluations>0);
  AssertNear(R.FVal,R.BestFVal,0,'annealing best objective');

  Workspace:=Default(TOptimizationWorkspace);
  O:=TOptimizationOptions.Defaults;
  R:=TOptimizationKit.BoundedLBFGSWithWorkspace(@QuadraticBowl,
    @QuadraticBowlGrad,TDoubleArray.Create(-4,5),O,Workspace);
  FirstEvaluations:=R.Evaluations;
  R:=TOptimizationKit.BoundedLBFGSWithWorkspace(@QuadraticBowl,
    @QuadraticBowlGrad,TDoubleArray.Create(100,100),O,Workspace);
  AssertEquals('workspace run count',2,Workspace.Runs);
  AssertEquals('workspace cumulative evaluations',
    Int64(FirstEvaluations+R.Evaluations),Workspace.TotalEvaluations);
  AssertNear(2,Workspace.WarmStartX[0],1E-7,'workspace warm-start x');
  AssertNear(-1,Workspace.WarmStartX[1],1E-7,'workspace warm-start y');
  Workspace.Clear;
  AssertEquals('workspace clear point',0,Length(Workspace.WarmStartX));
  AssertEquals('workspace clear runs',0,Workspace.Runs);
end;

initialization
  RegisterTest(TTestOptimizationLib);

end.
