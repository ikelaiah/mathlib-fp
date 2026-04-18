program example09_optimization;

{-----------------------------------------------------------------------------
 Example 09 — OptimizationLib Walkthrough

 Written for someone new to mathematical optimization.
 Each section introduces one optimizer with a plain-English explanation
 of what it does, when to use it, and a concrete example.

 Compile:  fpc example09_optimization.lpr
 Run:      ./example09_optimization   (Linux/Mac)
           example09_optimization.exe (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  OptimizationLib.Optimization;

procedure Sep; begin WriteLn(StringOfChar('-', 55)); end;

procedure ShowVec(const Lbl: String; const V: TDoubleArray);
var I: Integer;
begin
  Write(Format('  %-30s [', [Lbl]));
  for I := 0 to High(V) do
  begin
    if I > 0 then Write(', ');
    Write(Format('%.6f', [V[I]]));
  end;
  WriteLn(']');
end;

{ ---------------------------------------------------------------------------
  Test functions — must be global (passed as function pointers)
--------------------------------------------------------------------------- }

{ Single-variable: f(x) = (x - 3.7)^2  — minimum at x = 3.7 }
function Parabola(X: Double): Double;
begin Result := Sqr(X - 3.7); end;

{ Multi-variable: bowl f(x,y) = (x-2)^2 + (y+1)^2  — minimum at (2,-1) }
function Bowl(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]-2) + Sqr(X[1]+1); end;

{ Gradient of Bowl (optional — can pass nil to use numerical gradient) }
function BowlGrad(const X: TDoubleArray): TDoubleArray;
begin
  SetLength(Result, 2);
  Result[0] := 2*(X[0]-2);
  Result[1] := 2*(X[1]+1);
end;

{ Rosenbrock "banana": f(x,y)=100(y-x^2)^2+(1-x)^2  — minimum at (1,1)
  This is a classic hard test: narrow curved valley }
function Rosenbrock(const X: TDoubleArray): Double;
begin Result := 100*Sqr(X[1]-X[0]*X[0]) + Sqr(1-X[0]); end;

{ Himmelblau: four minima at f=0 — tests that solver finds ONE of them }
function Himmelblau(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]*X[0]+X[1]-11) + Sqr(X[0]+X[1]*X[1]-7); end;

{ Double-well: (x^2-1)^2  — two equal minima at x=±1, max at x=0
  Tests global search (SA) vs local search (gradient methods) }
function DoubleWell(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]*X[0]-1); end;

{ Concave function to be maximised: -(x-4)^2-(y-1)^2+10  — max at (4,1) }
function ConcaveHill(const X: TDoubleArray): Double;
begin Result := -(Sqr(X[0]-4)+Sqr(X[1]-1)) + 10; end;

{ Constraint for penalty demo: g(x) = x[0]+x[1]-6 <= 0 }
function SumConstraint(const X: TDoubleArray): Double;
begin Result := X[0] + X[1] - 6; end;

{ Constrained objective: minimise distance from (5,5) }
function DistFrom5(const X: TDoubleArray): Double;
begin Result := Sqr(X[0]-5) + Sqr(X[1]-5); end;

{ ============================================================
  SECTION 1 — Single-variable: GoldenSection & Brent
============================================================ }
procedure Demo1D;
var XMin: Double;
begin
  WriteLn;
  WriteLn('=== 1-D MINIMIZATION ===');
  WriteLn('f(x) = (x - 3.7)^2  — minimum at x = 3.7');
  Sep;

  XMin := TOptimizationKit.GoldenSection(@Parabola, 0, 10);
  WriteLn(Format('  GoldenSection       x* = %.6f  (exact: 3.700000)', [XMin]));

  XMin := TOptimizationKit.BrentMinimize(@Parabola, 0, 10);
  WriteLn(Format('  BrentMinimize       x* = %.6f  (faster for smooth f)', [XMin]));

  WriteLn;
  WriteLn('  When to use each:');
  WriteLn('  - GoldenSection: simple, any unimodal function');
  WriteLn('  - BrentMinimize: smoother functions, fewer evaluations needed');
end;

{ ============================================================
  SECTION 2 — Gradient Descent (the simplest multi-var method)
============================================================ }
procedure DemoGradientDescent;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== GRADIENT DESCENT ===');
  WriteLn('f(x,y) = (x-2)^2 + (y+1)^2  — minimum at (2, -1)');
  WriteLn('Starting from (0, 0).');
  Sep;

  { With analytical gradient }
  R := TOptimizationKit.GradientDescent(@Bowl, @BowlGrad,
    TDoubleArray.Create(0, 0));
  ShowVec('Solution X*',   R.X);
  WriteLn(Format('  f(X*)      = %.8f  (expected: 0)', [R.FVal]));
  WriteLn(Format('  Iterations = %d,  Converged = %s',
    [R.Iters, BoolToStr(R.Converged, True)]));

  WriteLn;
  WriteLn('  Now using NUMERICAL gradient (pass nil for Grad):');
  R := TOptimizationKit.GradientDescent(@Bowl, nil,
    TDoubleArray.Create(5, 5));
  ShowVec('Solution X*', R.X);
  WriteLn(Format('  f(X*)      = %.8f', [R.FVal]));
  WriteLn;
  WriteLn('  When to use: simple learning, understanding optimization basics.');
  WriteLn('  Tip: use Adam or L-BFGS for anything serious.');
end;

{ ============================================================
  SECTION 3 — Adam (the ML standard)
============================================================ }
procedure DemoAdam;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== ADAM OPTIMIZER ===');
  WriteLn('Rosenbrock f(x,y)=100(y-x^2)^2+(1-x)^2 — tricky curved valley');
  WriteLn('Minimum at (1, 1), f=0. Starting from (0, 0).');
  Sep;

  R := TOptimizationKit.Adam(@Rosenbrock, nil,
    TDoubleArray.Create(0, 0),
    0.01,   { LR }
    0.9,    { Beta1 }
    0.999,  { Beta2 }
    1E-8,   { Eps }
    1E-5,   { Tol }
    50000); { MaxIter }
  ShowVec('Solution X*', R.X);
  WriteLn(Format('  f(X*)      = %.8f  (expected: 0)', [R.FVal]));
  WriteLn(Format('  Iterations = %d,  Converged = %s',
    [R.Iters, BoolToStr(R.Converged, True)]));
  WriteLn;
  WriteLn('  When to use: machine learning, non-convex objectives,');
  WriteLn('  when gradients are noisy or computed in mini-batches.');
end;

{ ============================================================
  SECTION 4 — L-BFGS (fast quasi-Newton)
============================================================ }
procedure DemoLBFGS;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== L-BFGS ===');
  WriteLn('Bowl f(x,y)=(x-2)^2+(y+1)^2 with analytical gradient.');
  WriteLn('L-BFGS uses gradient history to approximate curvature.');
  Sep;

  R := TOptimizationKit.LBFGS(@Bowl, @BowlGrad,
    TDoubleArray.Create(10, -10));
  ShowVec('Solution X*', R.X);
  WriteLn(Format('  f(X*)      = %.10f', [R.FVal]));
  WriteLn(Format('  Iterations = %d,  Converged = %s',
    [R.Iters, BoolToStr(R.Converged, True)]));
  WriteLn;
  WriteLn('  When to use: smooth functions, scientific computing,');
  WriteLn('  when L-BFGS''s superlinear convergence beats Adam.');
end;

{ ============================================================
  SECTION 5 — Nelder-Mead (no gradient required)
============================================================ }
procedure DemoNelderMead;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== NELDER-MEAD SIMPLEX ===');
  WriteLn('No gradient needed — works on any function including black-box.');
  Sep;

  WriteLn('  Test 1: Rosenbrock from (0,0)');
  R := TOptimizationKit.NelderMead(@Rosenbrock,
    TDoubleArray.Create(0, 0), 1.0, 1E-8, 20000);
  ShowVec('  X*', R.X);
  WriteLn(Format('  f(X*) = %.8f  (expected: 0)', [R.FVal]));

  WriteLn;
  WriteLn('  Test 2: Himmelblau (4 minima) from (3, 2)');
  R := TOptimizationKit.NelderMead(@Himmelblau,
    TDoubleArray.Create(3, 2));
  ShowVec('  X*', R.X);
  WriteLn(Format('  f(X*) = %.8f  (expected: 0)', [R.FVal]));
  WriteLn;
  WriteLn('  When to use: simulation outputs, noisy functions,');
  WriteLn('  engineering design, hyperparameter tuning.');
end;

{ ============================================================
  SECTION 6 — Simulated Annealing (global search)
============================================================ }
procedure DemoSimulatedAnnealing;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== SIMULATED ANNEALING ===');
  WriteLn('Double-well: f(x)=(x^2-1)^2  — two minima at x=±1, MAX at x=0.');
  WriteLn('Starting at x=0.1 (near local maximum — gradient methods would fail).');
  Sep;

  R := TOptimizationKit.SimulatedAnnealing(@DoubleWell,
    TDoubleArray.Create(0.1),  { start near the saddle point }
    100,     { T0 }
    1E-8,    { TMin }
    0.995,   { CoolRate }
    0.2,     { StepSize }
    200000,  { MaxIter }
    42);     { Seed — fixed for reproducibility }
  ShowVec('Solution X*', R.X);
  WriteLn(Format('  f(X*)      = %.8f  (expected: 0)', [R.FVal]));
  WriteLn(Format('  |X*|       = %.6f  (expected: 1)', [Abs(R.X[0])]));
  WriteLn;
  WriteLn('  When to use: highly non-convex problems with many local minima.');
  WriteLn('  Tip: use Seed parameter for reproducible results.');
end;

{ ============================================================
  SECTION 7 — Penalty Method (constrained optimization)
============================================================ }
procedure DemoPenaltyMethod;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== PENALTY METHOD (CONSTRAINED) ===');
  WriteLn('minimise  (x-5)^2 + (y-5)^2');
  WriteLn('subject to  x + y <= 6');
  WriteLn('Unconstrained min = (5,5), constrained min = (3,3), f=8.');
  Sep;

  R := TOptimizationKit.PenaltyMethod(@DistFrom5,
    [TConstraintFunc(@SumConstraint)],
    TDoubleArray.Create(1, 1));  { feasible starting point }
  ShowVec('Solution X*', R.X);
  WriteLn(Format('  f(X*)      = %.6f  (expected: 8.0)', [R.FVal]));
  WriteLn(Format('  x+y        = %.6f  (should be <= 6)', [R.X[0]+R.X[1]]));
  WriteLn;
  WriteLn('  When to use: add inequality constraints to any NelderMead problem.');
  WriteLn('  Constraints written as g(x) <= 0.');
end;

{ ============================================================
  SECTION 8 — Linear Programming (SimplexLP)
============================================================ }
procedure DemoLinearProgramming;
var LP: TLPResult;
begin
  WriteLn;
  WriteLn('=== LINEAR PROGRAMMING (SIMPLEX) ===');
  WriteLn('A factory makes two products:');
  WriteLn('  Product A: profit $3/unit, uses 1h machine time');
  WriteLn('  Product B: profit $5/unit, uses 2h machine time');
  WriteLn('  Machine capacity: 8h/day');
  WriteLn('  Demand cap:  A <= 5 units,  B <= 3 units');
  WriteLn('Maximise profit = 3A + 5B');
  WriteLn('→ Minimise -3A - 5B  s.t.  A+2B<=8, A<=5, B<=3, A,B>=0');
  Sep;

  LP := TOptimizationKit.SimplexLP(
    TDoubleArray.Create(-3, -5),                    { cost (negated profit) }
    [TDoubleArray.Create(1, 2),                     { machine time }
     TDoubleArray.Create(1, 0),                     { A demand cap }
     TDoubleArray.Create(0, 1)],                    { B demand cap }
    TDoubleArray.Create(8, 5, 3));                  { RHS }

  WriteLn(Format('  Feasible   = %s', [BoolToStr(LP.Feasible, True)]));
  ShowVec('  X* = [A, B]', LP.X);
  WriteLn(Format('  Max Profit = $%.2f/day', [-LP.ObjVal]));
  WriteLn(Format('  Iterations = %d', [LP.Iters]));
end;

{ ============================================================
  SECTION 9 — Maximization helper
============================================================ }
procedure DemoMaximize;
var R: TOptResult;
begin
  WriteLn;
  WriteLn('=== MAXIMIZATION ===');
  WriteLn('Find the peak of  f(x,y) = -(x-4)^2-(y-1)^2+10');
  WriteLn('Maximum = 10 at (4, 1). Use TOptimizationKit.Maximize.');
  Sep;

  R := TOptimizationKit.Maximize(@ConcaveHill,
    TDoubleArray.Create(0, 0));
  ShowVec('Peak X*', R.X);
  WriteLn(Format('  f(X*) = %.6f  (expected: 10.0)', [R.FVal]));
end;

{ ============================================================
  SECTION 10 — Numerical gradient utility
============================================================ }
procedure DemoNumGrad;
var G: TDoubleArray;
begin
  WriteLn;
  WriteLn('=== NUMERICAL GRADIENT ===');
  WriteLn('Bowl at point (3, -2): analytical grad = [2*(3-2), 2*(-2+1)] = [2, -2]');
  Sep;
  G := TOptimizationKit.NumGrad(@Bowl, TDoubleArray.Create(3, -2));
  ShowVec('Numerical gradient', G);
  WriteLn('  Use to verify your analytical gradient, or pass nil to');
  WriteLn('  gradient-based solvers — they call NumGrad automatically.');
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp — OptimizationLib Example');
  WriteLn('=====================================');

  Demo1D;
  DemoGradientDescent;
  DemoAdam;
  DemoLBFGS;
  DemoNelderMead;
  DemoSimulatedAnnealing;
  DemoPenaltyMethod;
  DemoLinearProgramming;
  DemoMaximize;
  DemoNumGrad;

  WriteLn;
  WriteLn('Done.');
end.
