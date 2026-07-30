unit OptimizationLib.Optimization;

{-----------------------------------------------------------------------------
 OptimizationLib.Optimization

 Mathematical optimization for Free Pascal.
 Finds minima (or maxima) of functions — no external dependencies.

 What this domain unit gives you
 ---------------------------
 Unconstrained single-variable
   GoldenSection      — bracket minimum of f(x) on [a,b], derivative-free
   BrentMinimize      — Brent's method, parabolic interpolation + golden section

 Unconstrained multi-variable (gradient-based)
   GradientDescent    — steepest descent with backtracking line search
   Adam               — adaptive moment estimation (de-facto ML standard)
   LBFGS              — Limited-memory BFGS quasi-Newton (fast, low memory)

 Unconstrained multi-variable (derivative-free)
   NelderMead         — simplex method, works on noisy/non-smooth objectives
   SimulatedAnnealing — global optimiser, escapes local minima

 Constrained
   PenaltyMethod      — quadratic penalty with Nelder-Mead inner solves

 Linear Programming
   SimplexLP          — tableau Simplex method for standard-form LP:
                        min c'x  s.t. Ax <= b, x >= 0

 Function types
   TUnivarFunc   = function(X: Double): Double
   TMultivarFunc = function(const X: TDoubleArray): Double
   TGradFunc     = function(const X: TDoubleArray): TDoubleArray

 Usage pattern — all methods are class static
   min := TOptimizationKit.GoldenSection(f, 0, 10);
   x   := TOptimizationKit.NelderMead(f, x0, 1000);
   x   := TOptimizationKit.Adam(f, grad, x0);

 Result records
   TOptResult   — for multi-variable solvers: solution + objective value + iters
   TLPResult    — for SimplexLP: solution + objective value + feasibility flag
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes, MathBase.Iteration, MathBase.Random,
  NumericsLib.Differentiation;

type
  { Raised for invalid optimizer inputs }
  EOptimizationError = class(Exception);

  { Single-variable objective: f(x) → scalar }
  TUnivarFunc = function(X: Double): Double;

  { Multi-variable objective: f(x[]) → scalar }
  TMultivarFunc = function(const X: TDoubleArray): Double;

  { Gradient of a multi-variable function: ∇f(x) → vector }
  TGradFunc = function(const X: TDoubleArray): TDoubleArray;

  { Constraint function g(x) <= 0 }
  TConstraintFunc = function(const X: TDoubleArray): Double;

  { Result of a multi-variable optimizer }
  TOptResult = record
    X:         TDoubleArray;  { solution vector }
    FVal:      Double;        { objective value at solution }
    Iters:     Integer;       { iterations used }
    Converged: Boolean;       { True if convergence criterion was met }
    Status: TIterationStatus; { detailed termination reason }
    GradientNorm: Double;     { final gradient norm when applicable }
    ConstraintViolation: Double; { maximum positive constraint violation }
    Evaluations: Integer;     { objective/gradient/constraint evaluations }
    BestX: TDoubleArray;      { best finite iterate observed }
    BestFVal: Double;         { objective at BestX }
  end;

  TLPStatus = (lpsOptimal, lpsUnbounded, lpsIterationLimit,
    lpsUnsupportedStart, lpsInfeasible);

  { Result of SimplexLP }
  TLPResult = record
    X:        TDoubleArray;  { primal solution }
    ObjVal:   Double;        { c'x at solution }
    Feasible: Boolean;       { compatibility flag: True only when Status=optimal }
    Iters:    Integer;
    Status:   TLPStatus;     { precise termination reason }
  end;

  TOptimizationProgress = function(Iteration, Evaluations: Integer;
    Objective, GradientNorm, Feasibility: Double): Boolean;

  TOptimizationOptions = record
    AbsoluteTolerance: Double;
    RelativeTolerance: Double;
    GradientTolerance: Double;
    MaxIterations: Integer;
    MaxEvaluations: Integer;
    InitialStep: Double;
    InitialTrustRadius: Double;
    HistorySize: Integer;
    LowerBounds: TDoubleArray;
    UpperBounds: TDoubleArray;
    Seed: QWord;
    StartCount: Integer;
    Progress: TOptimizationProgress;
    class function Defaults: TOptimizationOptions; static;
  end;

  TOptimizationWorkspace = record
    WarmStartX:TDoubleArray;
    Runs:Integer;
    TotalEvaluations:Int64;
    procedure Clear;
  end;

  TConstraintKind = (ckInequality, ckEquality);

  TSmoothConstraint = record
    Value: TConstraintFunc;
    Gradient: TGradFunc;
    Kind: TConstraintKind;
    Tolerance: Double;
  end;
  TSmoothConstraints = array of TSmoothConstraint;

  TMultivarFunctions = array of TMultivarFunc;
  TOptResults = array of TOptResult;
  TObjectiveMatrix = array of TDoubleArray;

  TMultiObjectiveResult = record
    Points: TOptResults;
    ObjectiveValues: TObjectiveMatrix;
    Evaluations: Integer;
    Status: TIterationStatus;
  end;

  { TOptimizationKit — all methods are class static }
  TOptimizationKit = class
  private
    { Internal: numerical gradient via central differences }
    class function NumericalGradient(F: TMultivarFunc; const X: TDoubleArray; H: Double = 1E-5): TDoubleArray; static;
    class function NumericalGradientCounted(F: TMultivarFunc;
      const X: TDoubleArray; H: Double; var Evaluations: Integer):
      TDoubleArray; static;

    { Internal: dot product of two vectors }
    class function Dot(const A, B: TDoubleArray): Double; static;

    { Internal: vector addition }
    class function VecAdd(const A, B: TDoubleArray; Scale: Double = 1): TDoubleArray; static;

    { Internal: vector scale }
    class function VecScale(const A: TDoubleArray; S: Double): TDoubleArray; static;

    { Internal: vector norm (L2) }
    class function VecNorm(const A: TDoubleArray): Double; static;

    { Internal: copy vector }
    class function VecCopy(const A: TDoubleArray): TDoubleArray; static;

    { Internal: backtracking line search (Armijo condition) }
    class function LineSearch(
      F: TMultivarFunc;
      const X, Dir: TDoubleArray;
      FX: Double;
      Alpha0: Double = 1.0): Double; static;
    class function LineSearchCounted(
      F: TMultivarFunc;
      const X, Dir: TDoubleArray;
      FX, Alpha0: Double;
      var Evaluations: Integer): Double; static;
    class function CoreObjective(F: TMultivarFunc;
      const Constraints: array of TConstraintFunc;
      const X: TDoubleArray; PenaltyWeight: Double;
      Negate: Boolean; var Evaluations: Integer): Double; static;
    class function NelderMeadCore(F: TMultivarFunc;
      const Constraints: array of TConstraintFunc;
      const X0: TDoubleArray; Scale, Tol: Double; MaxIter: Integer;
      PenaltyWeight: Double; Negate: Boolean): TOptResult; static;

  public

    { =======================================================================
      SINGLE-VARIABLE MINIMIZATION
    ======================================================================= }

    { Golden-section search: find x* in [A, B] that minimises f(x).
      The function must be unimodal on [A,B] (one valley, no plateaus).
      Tol: absolute tolerance on the interval width (default 1e-8).
      MaxIter: maximum iterations (default 200).

      Example: find the minimum of (x-3)^2 on [0,10]
        xMin := TOptimizationKit.GoldenSection(f, 0, 10);  // ≈ 3.0 }
    class function GoldenSection(
      F: TUnivarFunc;
      A, B: Double;
      Tol: Double = 1E-8;
      MaxIter: Integer = 200): Double; static;

    { Brent's method for single-variable minimization.
      Combines golden-section with parabolic interpolation — faster than
      GoldenSection for smooth functions, equally robust.
      Requires [A, B] to bracket a minimum (f has a valley inside).
      Returns the x value at the minimum. }
    class function BrentMinimize(
      F: TUnivarFunc;
      A, B: Double;
      Tol: Double = 1E-8;
      MaxIter: Integer = 200): Double; static;

    { =======================================================================
      GRADIENT-BASED MULTI-VARIABLE MINIMIZATION
    ======================================================================= }

    { Gradient Descent (steepest descent) with backtracking line search.
      Parameters
        F      — objective function to minimise
        Grad   — gradient of F (pass nil to use numerical gradient)
        X0     — starting point
        LR     — initial learning rate / step size (default 0.1)
        Tol    — convergence: stop when ||grad|| < Tol (default 1e-6)
        MaxIter— maximum iterations (default 5000)

      When to use: simple problems, educational purposes.
      For production use Adam or LBFGS instead. }
    class function GradientDescent(
      F: TMultivarFunc;
      Grad: TGradFunc;
      const X0: TDoubleArray;
      LR: Double = 0.1;
      Tol: Double = 1E-6;
      MaxIter: Integer = 5000): TOptResult; static;

    { Adam optimizer (Adaptive Moment Estimation).
      The standard optimizer in deep learning — works well for non-convex
      problems and is robust to noisy / stochastic gradients.

      Parameters
        F      — objective function
        Grad   — gradient (pass nil to use numerical gradient)
        X0     — starting point
        LR     — learning rate (default 0.001 — the standard Adam default)
        Beta1  — decay for 1st moment estimate (default 0.9)
        Beta2  — decay for 2nd moment estimate (default 0.999)
        Eps    — numerical stability constant (default 1e-8)
        Tol    — stop when ||grad|| < Tol (default 1e-6)
        MaxIter— (default 10000)

      Adam adapts the learning rate per parameter — you rarely need to tune
      it beyond the learning rate. }
    class function Adam(
      F: TMultivarFunc;
      Grad: TGradFunc;
      const X0: TDoubleArray;
      LR: Double = 0.001;
      Beta1: Double = 0.9;
      Beta2: Double = 0.999;
      Eps: Double = 1E-8;
      Tol: Double = 1E-6;
      MaxIter: Integer = 10000): TOptResult; static;

    { L-BFGS (Limited-memory Broyden–Fletcher–Goldfarb–Shanno).
      A quasi-Newton method that approximates the inverse Hessian using
      the last M gradient differences — memory O(M*N) instead of O(N²).

      Parameters
        F      — objective function
        Grad   — gradient (pass nil to use numerical gradient)
        X0     — starting point
        M      — history size (default 10; larger = better approximation)
        Tol    — stop when ||grad|| < Tol (default 1e-6)
        MaxIter— (default 1000)

      When to use: smooth objective functions, moderate dimensionality
      (N = 10s to 1000s of variables). Much faster than Adam on smooth
      convex problems. }
    class function LBFGS(
      F: TMultivarFunc;
      Grad: TGradFunc;
      const X0: TDoubleArray;
      M: Integer = 10;
      Tol: Double = 1E-6;
      MaxIter: Integer = 1000): TOptResult; static;

    class function NonlinearConjugateGradient(F: TMultivarFunc;
      Grad: TGradFunc; const X0: TDoubleArray;
      const Options: TOptimizationOptions): TOptResult; static;
    class function BoundedLBFGS(F: TMultivarFunc; Grad: TGradFunc;
      const X0: TDoubleArray; const Options: TOptimizationOptions):
      TOptResult; static;
    class function BoundedLBFGSWithWorkspace(F:TMultivarFunc;
      Grad:TGradFunc; const X0:TDoubleArray;
      const Options:TOptimizationOptions;
      var Workspace:TOptimizationWorkspace):TOptResult; static;
    class function TrustRegion(F: TMultivarFunc; Grad: TGradFunc;
      const X0: TDoubleArray; const Options: TOptimizationOptions):
      TOptResult; static;
    class function LBFGSAuto(F: TDualFunction;
      const X0: TDoubleArray; const Options: TOptimizationOptions):
      TOptResult; static;
    class function MultiStart(F: TMultivarFunc; Grad: TGradFunc;
      const InitialPoints: array of TDoubleArray;
      const Options: TOptimizationOptions): TOptResult; static;
    class function SolveConstrained(F: TMultivarFunc; Grad: TGradFunc;
      const Constraints: TSmoothConstraints; const X0: TDoubleArray;
      const Options: TOptimizationOptions): TOptResult; static;
    class function ExplorePareto(const Objectives: TMultivarFunctions;
      const InitialPoints, Weights: array of TDoubleArray;
      const Options: TOptimizationOptions): TMultiObjectiveResult; static;

    { =======================================================================
      DERIVATIVE-FREE MULTI-VARIABLE MINIMIZATION
    ======================================================================= }

    { Nelder-Mead simplex method.
      Moves a simplex (N+1 vertices) around the search space, reflecting,
      expanding, and contracting based on function values.
      NO GRADIENT NEEDED — works on noisy, non-smooth, or black-box functions.

      Parameters
        F      — objective function
        X0     — starting point (simplex is built around it)
        Scale  — initial simplex edge length (default 1.0)
        Tol    — stop when simplex diameter < Tol (default 1e-8)
        MaxIter— (default 10000)

      When to use: simulation outputs, engineering design, hyperparameter
      tuning — any situation where you cannot compute a gradient. }
    class function NelderMead(
      F: TMultivarFunc;
      const X0: TDoubleArray;
      Scale: Double = 1.0;
      Tol: Double = 1E-8;
      MaxIter: Integer = 10000): TOptResult; static;

    { Simulated Annealing — global stochastic optimizer.
      Accepts worse solutions with probability exp(-ΔE/T), where T (temperature)
      decreases over time.  This lets it ESCAPE LOCAL MINIMA, unlike gradient
      methods.

      Parameters
        F        — objective function
        X0       — starting point
        T0       — initial temperature (default 100.0; higher = more exploration)
        TMin     — stop temperature (default 1e-8)
        CoolRate — multiplicative cooling per iteration (default 0.995)
        StepSize — random perturbation magnitude (default 0.1)
        MaxIter  — (default 100000)
        Seed     — RNG seed for reproducibility (default 42)

      When to use: highly non-convex landscapes with many local minima,
      combinatorial-flavoured continuous problems. }
    class function SimulatedAnnealing(
      F: TMultivarFunc;
      const X0: TDoubleArray;
      T0: Double = 100.0;
      TMin: Double = 1E-8;
      CoolRate: Double = 0.995;
      StepSize: Double = 0.1;
      MaxIter: Integer = 100000;
      Seed: Integer = 42): TOptResult; static;

    { =======================================================================
      CONSTRAINED OPTIMIZATION
    ======================================================================= }

    { Penalty method: convert a constrained problem to unconstrained.
      Solves: min f(x)  subject to g_i(x) <= 0 for all constraints.

      Internally runs NelderMead on the augmented objective:
        F_pen(x) = F(x) + Mu * sum(max(0, g_i(x))^2)

      Parameters
        F           — objective function
        Constraints — array of constraint functions g_i(x) <= 0
        X0          — starting point (should be feasible if possible)
        Mu          — initial penalty weight (default 1.0; auto-increased)
        Tol         — (default 1e-6)
        MaxIter     — per inner solve (default 5000)

      Tip: start with a feasible X0. Calls are serialized through the internal
      callback adapter, so concurrent callers cannot corrupt shared state. }
    class function PenaltyMethod(
      F: TMultivarFunc;
      const Constraints: array of TConstraintFunc;
      const X0: TDoubleArray;
      Mu: Double = 1.0;
      Tol: Double = 1E-6;
      MaxIter: Integer = 5000): TOptResult; static;

    { =======================================================================
      LINEAR PROGRAMMING
    ======================================================================= }

    { Tableau Simplex method for standard-form LP with a feasible slack basis:
        minimise   c' x
        subject to A x <= b,   x >= 0

      Parameters
        C  — cost vector (length N)
        A  — constraint matrix (M rows × N cols), stored row-major
        B  — right-hand side (length M); all b_i must be >= 0
             Negative right-hand sides are not supported because this
             implementation does not include a Phase I procedure.

      Result
        TLPResult.Status   →  optimal, unbounded, iteration limit, or an
                              unsupported negative-RHS starting basis
        TLPResult.Feasible = True only for an optimal result
        TLPResult.X        →  optimal primal solution
        TLPResult.ObjVal   →  c' x at optimum

      Converts to equality form internally by adding slack variables,
      then runs the Simplex pivot loop.

      Example — minimise -x1 - x2 subject to x1+x2<=4, x1<=3, x2<=3, x>=0:
        c := [-1,-1];
        A := [[1,1],[1,0],[0,1]];
        b := [4,3,3];
        r := TOptimizationKit.SimplexLP(c, A, b); }
    class function SimplexLP(
      const C: TDoubleArray;
      const A: array of TDoubleArray;
      const B: TDoubleArray): TLPResult; static;

    { =======================================================================
      UTILITY
    ======================================================================= }

    { Numerical gradient via central differences.
      Useful when you want to verify an analytical gradient:
        gradNum := TOptimizationKit.NumGrad(f, x);
        gradAna := MyGradient(x);
        // compare elementwise }
    class function NumGrad(F: TMultivarFunc; const X: TDoubleArray; H: Double = 1E-5): TDoubleArray; static;

    { Maximise F by minimising -F.  Wraps any minimizer.
      Example: find the peak of a hill function using NelderMead.
        result := TOptimizationKit.Maximize(f, x0); }
    class function Maximize(
      F: TMultivarFunc;
      const X0: TDoubleArray;
      Scale: Double = 1.0;
      Tol: Double = 1E-8;
      MaxIter: Integer = 10000): TOptResult; static;

  end;

implementation

class function TOptimizationOptions.Defaults: TOptimizationOptions;
begin
  Result:=Default(TOptimizationOptions);
  Result.AbsoluteTolerance:=1E-10;
  Result.RelativeTolerance:=1E-8;
  Result.GradientTolerance:=1E-7;
  Result.MaxIterations:=2000;
  Result.MaxEvaluations:=100000;
  Result.InitialStep:=1;
  Result.InitialTrustRadius:=1;
  Result.HistorySize:=10;
  Result.Seed:=42;
  Result.StartCount:=1;
end;

procedure TOptimizationWorkspace.Clear;
begin
  WarmStartX:=nil;
  Runs:=0;
  TotalEvaluations:=0;
end;

procedure RequireFiniteVector(const X: TDoubleArray; const Operation: string);
var
  I: Integer;
begin
  for I := 0 to High(X) do
    if IsNan(X[I]) or IsInfinite(X[I]) then
      raise EOptimizationError.CreateFmt('%s: non-finite value at index %d',
        [Operation, I]);
end;

procedure RequirePositiveFinite(const Value: Double; const Name: string);
begin
  if (Value <= 0.0) or IsNan(Value) or IsInfinite(Value) then
    raise EOptimizationError.Create(Name + ' must be finite and > 0');
end;

function EvaluateUnivariate(F: TUnivarFunc; const X: Double;
  const Operation: string): Double;
begin
  Result := F(X);
  if IsNan(Result) or IsInfinite(Result) then
    raise EOptimizationError.Create(Operation + ': objective returned a non-finite value');
end;

function EvaluateMultivariate(F: TMultivarFunc; const X: TDoubleArray;
  const Operation: string): Double;
begin
  Result := F(X);
  if IsNan(Result) or IsInfinite(Result) then
    raise EOptimizationError.Create(Operation + ': objective returned a non-finite value');
end;

type
  TDetailedObjectiveSource = record
    Objective:TMultivarFunc;
    Gradient:TGradFunc;
    DualObjective:TDualFunction;
  end;
  TVectorList = array of TDoubleArray;

procedure ValidateDetailedOptions(const X0:TDoubleArray;
  const Options:TOptimizationOptions; const Operation:String);
var
  I,N:Integer;
begin
  if Length(X0)=0 then
    raise EOptimizationError.Create(Operation+': initial point must not be empty');
  RequireFiniteVector(X0,Operation+' initial point');
  if (Options.AbsoluteTolerance<0) or
     (Options.RelativeTolerance<0) or
     (Options.AbsoluteTolerance+Options.RelativeTolerance<=0) or
     (Options.GradientTolerance<=0) or
     (Options.MaxIterations<=0) or
     (Options.MaxEvaluations<=0) or
     (Options.InitialStep<=0) or
     (Options.InitialTrustRadius<=0) or
     (Options.HistorySize<=0) or
     (Options.StartCount<=0) or
     IsNan(Options.AbsoluteTolerance) or
     IsInfinite(Options.AbsoluteTolerance) or
     IsNan(Options.RelativeTolerance) or
     IsInfinite(Options.RelativeTolerance) or
     IsNan(Options.GradientTolerance) or
     IsInfinite(Options.GradientTolerance) or
     IsNan(Options.InitialStep) or
     IsInfinite(Options.InitialStep) or
     IsNan(Options.InitialTrustRadius) or
     IsInfinite(Options.InitialTrustRadius) then
    raise EOptimizationError.Create(Operation+': invalid options');
  N:=Length(X0);
  if (Length(Options.LowerBounds)<>0) and
     (Length(Options.LowerBounds)<>N) then
    raise EOptimizationError.Create(Operation+': lower bounds length mismatch');
  if (Length(Options.UpperBounds)<>0) and
     (Length(Options.UpperBounds)<>N) then
    raise EOptimizationError.Create(Operation+': upper bounds length mismatch');
  if Length(Options.LowerBounds)>0 then
    RequireFiniteVector(Options.LowerBounds,Operation+' lower bounds');
  if Length(Options.UpperBounds)>0 then
    RequireFiniteVector(Options.UpperBounds,Operation+' upper bounds');
  for I:=0 to N-1 do
    if (Length(Options.LowerBounds)>0) and
       (Length(Options.UpperBounds)>0) and
       (Options.LowerBounds[I]>Options.UpperBounds[I]) then
      raise EOptimizationError.CreateFmt(
        '%s: lower bound exceeds upper bound at index %d',[Operation,I]);
end;

function ProjectDetailed(const X:TDoubleArray;
  const Options:TOptimizationOptions):TDoubleArray;
var
  I:Integer;
begin
  Result:=Copy(X);
  for I:=0 to High(Result) do
  begin
    if Length(Options.LowerBounds)>0 then
      Result[I]:=Max(Result[I],Options.LowerBounds[I]);
    if Length(Options.UpperBounds)>0 then
      Result[I]:=Min(Result[I],Options.UpperBounds[I]);
  end;
end;

function EvaluateDetailed(const Source:TDetailedObjectiveSource;
  const X:TDoubleArray; var Evaluations:Integer;
  const MaxEvaluations:Integer; const Operation:String):Double;
var
  DX:TDualArray;
  Y:TDual;
  I:Integer;
begin
  if Evaluations>=MaxEvaluations then
    raise EOptimizationError.Create(Operation+': evaluation limit reached');
  if Assigned(Source.DualObjective) then
  begin
    SetLength(DX,Length(X));
    for I:=0 to High(X) do DX[I]:=TDual.Create(X[I],0);
    Y:=Source.DualObjective(DX);
    Result:=Y.Value;
    if IsNan(Y.Derivative) or IsInfinite(Y.Derivative) then
      raise EOptimizationError.Create(
        Operation+': automatic objective returned a non-finite derivative');
  end
  else
    Result:=Source.Objective(X);
  Inc(Evaluations);
  if IsNan(Result) or IsInfinite(Result) then
    raise EOptimizationError.Create(
      Operation+': objective returned a non-finite value');
end;

function GradientDetailed(const Source:TDetailedObjectiveSource;
  const X:TDoubleArray; var Evaluations:Integer;
  const MaxEvaluations:Integer; const Operation:String):TDoubleArray;
var
  XP,XM:TDoubleArray;
  I:Integer;
  H,FP,FM:Double;
begin
  Result:=nil;
  if Assigned(Source.DualObjective) then
  begin
    if Evaluations+Length(X)>MaxEvaluations then
      raise EOptimizationError.Create(Operation+': evaluation limit reached');
    Result:=TDifferentiationKit.AutoGradient(Source.DualObjective,X);
    Inc(Evaluations,Length(X));
  end
  else if Assigned(Source.Gradient) then
  begin
    if Evaluations>=MaxEvaluations then
      raise EOptimizationError.Create(Operation+': evaluation limit reached');
    Result:=Source.Gradient(X);
    Inc(Evaluations);
  end
  else
  begin
    if Evaluations+2*Length(X)>MaxEvaluations then
      raise EOptimizationError.Create(Operation+': evaluation limit reached');
    XP:=Copy(X); XM:=Copy(X); SetLength(Result,Length(X));
    for I:=0 to High(X) do
    begin
      H:=Power(2.2204460492503131E-16,1/3)*Max(1,Abs(X[I]));
      XP[I]:=X[I]+H; XM[I]:=X[I]-H;
      FP:=Source.Objective(XP); FM:=Source.Objective(XM);
      Inc(Evaluations,2);
      XP[I]:=X[I]; XM[I]:=X[I];
      if IsNan(FP) or IsInfinite(FP) or IsNan(FM) or IsInfinite(FM) then
        raise EOptimizationError.Create(
          Operation+': objective returned non-finite finite-difference values');
      Result[I]:=(FP-FM)/(2*H);
    end;
  end;
  if Length(Result)<>Length(X) then
    raise EOptimizationError.Create(
      Operation+': gradient dimension mismatch');
  RequireFiniteVector(Result,Operation+' gradient');
end;

function ProjectedGradient(const X,G:TDoubleArray;
  const Options:TOptimizationOptions):TDoubleArray;
var
  I:Integer;
begin
  Result:=Copy(G);
  for I:=0 to High(Result) do
  begin
    if (Length(Options.LowerBounds)>0) and
       (X[I]<=Options.LowerBounds[I]) and (Result[I]>0) then
      Result[I]:=0;
    if (Length(Options.UpperBounds)>0) and
       (X[I]>=Options.UpperBounds[I]) and (Result[I]<0) then
      Result[I]:=0;
  end;
end;

function DotDetailed(const A,B:TDoubleArray):Double;
var
  I:Integer;
begin
  Result:=0;
  for I:=0 to High(A) do Result:=Result+A[I]*B[I];
end;

function NormDetailed(const X:TDoubleArray):Double;
var
  I:Integer;
  Scale,Sum,Value:Double;
begin
  Scale:=0; Sum:=1;
  for I:=0 to High(X) do
  begin
    Value:=Abs(X[I]);
    if Value=0 then Continue;
    if Scale<Value then
    begin
      Sum:=1+Sum*Sqr(Scale/Value);
      Scale:=Value;
    end
    else
      Sum:=Sum+Sqr(Value/Scale);
  end;
  if Scale=0 then Result:=0 else Result:=Scale*Sqrt(Sum);
end;

procedure UpdateDetailedBest(var Result:TOptResult;
  const X:TDoubleArray; const FValue:Double);
begin
  if (Length(Result.BestX)=0) or (FValue<Result.BestFVal) then
  begin
    Result.BestX:=Copy(X);
    Result.BestFVal:=FValue;
  end;
end;

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TOptimizationKit.NumericalGradientCounted(F: TMultivarFunc;
  const X:TDoubleArray; H:Double; var Evaluations:Integer):TDoubleArray;
{ Central-difference gradient: (f(x+h*ei) - f(x-h*ei)) / (2h) }
var
  I, N: Integer;
  XFwd, XBwd: TDoubleArray;
begin
  if not Assigned(F) then raise EOptimizationError.Create('NumericalGradient: objective is nil');
  RequirePositiveFinite(H, 'NumericalGradient step');
  RequireFiniteVector(X, 'NumericalGradient');
  N := Length(X);
  Result := nil;
  SetLength(Result, N);
  XFwd := VecCopy(X);
  XBwd := VecCopy(X);
  for I := 0 to N-1 do
  begin
    XFwd[I] := X[I] + H;
    XBwd[I] := X[I] - H;
    Result[I] := (EvaluateMultivariate(F, XFwd, 'NumericalGradient') -
      EvaluateMultivariate(F, XBwd, 'NumericalGradient')) / (2 * H);
    Inc(Evaluations,2);
    XFwd[I] := X[I];
    XBwd[I] := X[I];
  end;
end;

class function TOptimizationKit.NumericalGradient(F:TMultivarFunc;
  const X:TDoubleArray; H:Double):TDoubleArray;
var
  Evaluations:Integer;
begin
  Evaluations:=0;
  Result:=NumericalGradientCounted(F,X,H,Evaluations);
end;

class function TOptimizationKit.Dot(const A, B: TDoubleArray): Double;
var I: Integer;
begin
  Result := 0;
  for I := 0 to High(A) do Result := Result + A[I] * B[I];
end;

class function TOptimizationKit.VecAdd(const A, B: TDoubleArray; Scale: Double): TDoubleArray;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I] + Scale * B[I];
end;

class function TOptimizationKit.VecScale(const A: TDoubleArray; S: Double): TDoubleArray;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I] * S;
end;

class function TOptimizationKit.VecNorm(const A: TDoubleArray): Double;
var I: Integer; S: Double;
begin
  S := 0;
  for I := 0 to High(A) do S := S + A[I] * A[I];
  Result := Sqrt(S);
end;

class function TOptimizationKit.VecCopy(const A: TDoubleArray): TDoubleArray;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I];
end;

class function TOptimizationKit.LineSearchCounted(
  F: TMultivarFunc;
  const X, Dir: TDoubleArray;
  FX, Alpha0: Double;
  var Evaluations:Integer): Double;
{ Backtracking Armijo line search: halve alpha until sufficient decrease }
const
  Rho = 0.5;
  C1  = 1E-4;
var
  Alpha: Double;
  GradDot: Double;
  XNew: TDoubleArray;
  I: Integer;
begin
  Alpha   := Alpha0;
  GradDot := Dot(NumericalGradientCounted(F,X,1E-5,Evaluations),Dir);
  for I := 0 to 50 do
  begin
    XNew := VecAdd(X, Dir, Alpha);
    if EvaluateMultivariate(F, XNew, 'LineSearch') <=
       FX + C1 * Alpha * GradDot then
    begin
      Inc(Evaluations);
      Break;
    end;
    Inc(Evaluations);
    Alpha := Alpha * Rho;
  end;
  Result := Alpha;
end;

class function TOptimizationKit.LineSearch(F:TMultivarFunc;
  const X,Dir:TDoubleArray; FX:Double; Alpha0:Double):Double;
var
  Evaluations:Integer;
begin
  Evaluations:=0;
  Result:=LineSearchCounted(F,X,Dir,FX,Alpha0,Evaluations);
end;

{ ---------------------------------------------------------------------------
  GOLDEN SECTION
--------------------------------------------------------------------------- }

class function TOptimizationKit.GoldenSection(F: TUnivarFunc; A, B: Double; Tol: Double; MaxIter: Integer): Double;
{ Reduces the interval by the golden ratio φ = (√5-1)/2 ≈ 0.618 each step }
const
  Phi = 0.6180339887498949;  { (√5-1)/2 }
var
  C, D, FC, FD: Double;
  Iter: Integer;
  Converged: Boolean;
begin
  if not Assigned(F) then raise EOptimizationError.Create('GoldenSection: objective is nil');
  if IsNan(A) or IsInfinite(A) or IsNan(B) or IsInfinite(B) then
    raise EOptimizationError.Create('GoldenSection: interval endpoints must be finite');
  if B <= A then raise EOptimizationError.Create('GoldenSection: B must be > A');
  RequirePositiveFinite(Tol, 'GoldenSection tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('GoldenSection: MaxIter must be > 0');
  C  := B - Phi * (B - A);
  D  := A + Phi * (B - A);
  FC := EvaluateUnivariate(F, C, 'GoldenSection');
  FD := EvaluateUnivariate(F, D, 'GoldenSection');
  Converged := False;
  for Iter := 1 to MaxIter do
  begin
    if (B - A) < Tol then begin Converged := True; Break; end;
    if FC < FD then
    begin
      B  := D;
      D  := C;  FD := FC;
      C  := B - Phi * (B - A);
      FC := EvaluateUnivariate(F, C, 'GoldenSection');
    end
    else
    begin
      A  := C;
      C  := D;  FC := FD;
      D  := A + Phi * (B - A);
      FD := EvaluateUnivariate(F, D, 'GoldenSection');
    end;
  end;
  if not Converged then
    raise EOptimizationError.CreateFmt(
      'GoldenSection did not converge after %d iterations', [MaxIter]);
  Result := (A + B) / 2;
end;

{ ---------------------------------------------------------------------------
  BRENT MINIMIZE
--------------------------------------------------------------------------- }

class function TOptimizationKit.BrentMinimize(F: TUnivarFunc; A, B: Double; Tol: Double; MaxIter: Integer): Double;
{ Brent (1973) — combines golden section with inverse parabolic interpolation }
const
  CGold = 0.3819660112501051;  { 1 - (√5-1)/2 }
  ZEps  = 1E-10;
var
  V, W, X, U, FU, FV, FW, FX: Double;
  E, D, P, Q, R, Tol1, Tol2, XM: Double;
  Iter: Integer;
  Converged: Boolean;
begin
  if not Assigned(F) then raise EOptimizationError.Create('BrentMinimize: objective is nil');
  if IsNan(A) or IsInfinite(A) or IsNan(B) or IsInfinite(B) then
    raise EOptimizationError.Create('BrentMinimize: interval endpoints must be finite');
  if B <= A then raise EOptimizationError.Create('BrentMinimize: B must be > A');
  RequirePositiveFinite(Tol, 'BrentMinimize tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('BrentMinimize: MaxIter must be > 0');
  V  := A + CGold * (B - A);
  W  := V;  X  := V;
  FV := EvaluateUnivariate(F, V, 'BrentMinimize'); FW := FV; FX := FV;
  E  := 0;  D  := 0;
  Converged := False;

  for Iter := 1 to MaxIter do
  begin
    XM   := 0.5 * (A + B);
    Tol1 := Tol * Abs(X) + ZEps;
    Tol2 := 2 * Tol1;
    if Abs(X - XM) <= Tol2 - 0.5*(B-A) then
    begin Converged := True; Break; end;

    if Abs(E) > Tol1 then
    begin
      { Try parabolic interpolation }
      R := (X - W) * (FX - FV);
      Q := (X - V) * (FX - FW);
      P := (X - V) * Q - (X - W) * R;
      Q := 2 * (Q - R);
      if Q > 0 then P := -P else Q := -Q;
      R := E;
      E := D;
      if (Abs(P) < Abs(0.5*Q*R)) and (P > Q*(A-X)) and (P < Q*(B-X)) then
      begin
        D := P / Q;  U := X + D;
        if (U - A < Tol2) or (B - U < Tol2) then
          D := IfThen(X < XM, Tol1, -Tol1);
      end
      else
      begin
        E := IfThen(X >= XM, A - X, B - X);
        D := CGold * E;
      end;
    end
    else
    begin
      E := IfThen(X >= XM, A - X, B - X);
      D := CGold * E;
    end;

    U  := X + IfThen(Abs(D) >= Tol1, D, IfThen(D > 0, Tol1, -Tol1));
    FU := EvaluateUnivariate(F, U, 'BrentMinimize');

    if FU <= FX then
    begin
      if U < X then B := X else A := X;
      V := W;  FV := FW;
      W := X;  FW := FX;
      X := U;  FX := FU;
    end
    else
    begin
      if U < X then A := U else B := U;
      if (FU <= FW) or (W = X) then
      begin
        V := W;  FV := FW;
        W := U;  FW := FU;
      end
      else if (FU <= FV) or (V = X) or (V = W) then
      begin
        V := U;  FV := FU;
      end;
    end;
  end;
  if not Converged then
    raise EOptimizationError.CreateFmt(
      'BrentMinimize did not converge after %d iterations', [MaxIter]);
  Result := X;
end;

{ ---------------------------------------------------------------------------
  GRADIENT DESCENT
--------------------------------------------------------------------------- }

class function TOptimizationKit.GradientDescent(
  F: TMultivarFunc;
  Grad: TGradFunc;
  const X0: TDoubleArray;
  LR: Double;
  Tol: Double;
  MaxIter: Integer): TOptResult;
var
  X, G, Dir: TDoubleArray;
  FX, Alpha: Double;
  Iter: Integer;
begin
  Result:=Default(TOptResult);
  G := nil;
  Iter := 0;
  if not Assigned(F) then raise EOptimizationError.Create('GradientDescent: objective is nil');
  if Length(X0) = 0 then
    raise EOptimizationError.Create('GradientDescent: X0 must not be empty');
  RequireFiniteVector(X0, 'GradientDescent');
  RequirePositiveFinite(LR, 'GradientDescent learning rate');
  RequirePositiveFinite(Tol, 'GradientDescent tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('GradientDescent: MaxIter must be > 0');
  X   := VecCopy(X0);
  FX  := EvaluateMultivariate(F, X, 'GradientDescent');
  Inc(Result.Evaluations);
  Result.BestX:=Copy(X);
  Result.BestFVal:=FX;
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if Assigned(Grad) then
    begin G := Grad(X); Inc(Result.Evaluations); end
    else
      G := NumericalGradientCounted(F,X,1E-5,Result.Evaluations);
    if Length(G) <> Length(X) then
      raise EOptimizationError.Create('GradientDescent: gradient dimension mismatch');
    RequireFiniteVector(G, 'GradientDescent gradient');

    if VecNorm(G) < Tol then
    begin
      Result.Converged := True;
      Break;
    end;

    { Descent direction = -gradient }
    Dir   := VecScale(G, -1);
    Alpha := LineSearchCounted(F,X,Dir,FX,LR,Result.Evaluations);
    X     := VecAdd(X, Dir, Alpha);
    FX    := EvaluateMultivariate(F, X, 'GradientDescent');
    Inc(Result.Evaluations);
    UpdateDetailedBest(Result,X,FX);
  end;

  Result.X     := X;
  Result.FVal  := FX;
  Result.Iters := Iter;
  Result.GradientNorm := VecNorm(G);
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

function RunDetailedLBFGS(const Source:TDetailedObjectiveSource;
  const X0:TDoubleArray; const Options:TOptimizationOptions;
  const Operation:String):TOptResult;
var
  X,Trial,G,GNew,PG,Q,R,Direction,Step,Y:TDoubleArray;
  SBuf,YBuf:TVectorList;
  Rho,AlphaValues:TDoubleArray;
  FX,TrialF,Alpha,Beta,Gamma,SY,YY,Directional,
    StepNorm,Scale:Double;
  I,J,K,Iteration,Bound,LineIteration,N:Integer;
  Accepted:Boolean;
begin
  Result:=Default(TOptResult);
  if not Assigned(Source.Objective) and
     not Assigned(Source.DualObjective) then
    raise EOptimizationError.Create(Operation+': objective is nil');
  ValidateDetailedOptions(X0,Options,Operation);
  N:=Length(X0);
  X:=ProjectDetailed(X0,Options);
  FX:=EvaluateDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,Operation);
  G:=GradientDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,Operation);
  Result.BestFVal:=Infinity;
  UpdateDetailedBest(Result,X,FX);
  SetLength(SBuf,Options.HistorySize);
  SetLength(YBuf,Options.HistorySize);
  SetLength(Rho,Options.HistorySize);
  SetLength(AlphaValues,Options.HistorySize);
  K:=0;
  for Iteration:=1 to Options.MaxIterations do
  begin
    Result.Iters:=Iteration-1;
    PG:=ProjectedGradient(X,G,Options);
    Result.GradientNorm:=NormDetailed(PG);
    if Result.GradientNorm<=Options.GradientTolerance then
    begin
      Result.Status:=isConverged;
      Break;
    end;
    if Result.Evaluations>=Options.MaxEvaluations then
    begin
      Result.Status:=isIterationLimit;
      Break;
    end;
    Q:=Copy(PG);
    Bound:=Min(K,Options.HistorySize);
    for I:=Bound-1 downto 0 do
    begin
      J:=(K-Bound+I) mod Options.HistorySize;
      AlphaValues[I]:=Rho[J]*DotDetailed(SBuf[J],Q);
      for N:=0 to High(Q) do
        Q[N]:=Q[N]-AlphaValues[I]*YBuf[J][N];
    end;
    if K>0 then
    begin
      J:=(K-1) mod Options.HistorySize;
      SY:=DotDetailed(SBuf[J],YBuf[J]);
      YY:=DotDetailed(YBuf[J],YBuf[J]);
      if (SY>0) and (YY>0) then Gamma:=SY/YY else Gamma:=1;
    end
    else
      Gamma:=1;
    R:=Copy(Q);
    for N:=0 to High(R) do R[N]:=Gamma*R[N];
    for I:=0 to Bound-1 do
    begin
      J:=(K-Bound+I) mod Options.HistorySize;
      Beta:=Rho[J]*DotDetailed(YBuf[J],R);
      for N:=0 to High(R) do
        R[N]:=R[N]+SBuf[J][N]*(AlphaValues[I]-Beta);
    end;
    Direction:=Copy(R);
    for N:=0 to High(Direction) do
    begin
      Direction[N]:=-Direction[N];
      if (Length(Options.LowerBounds)>0) and
         (X[N]<=Options.LowerBounds[N]) and (Direction[N]<0) then
        Direction[N]:=0;
      if (Length(Options.UpperBounds)>0) and
         (X[N]>=Options.UpperBounds[N]) and (Direction[N]>0) then
        Direction[N]:=0;
    end;
    Directional:=DotDetailed(PG,Direction);
    if Directional>=0 then
    begin
      for N:=0 to High(Direction) do Direction[N]:=-PG[N];
      Directional:=-DotDetailed(PG,PG);
    end;
    if NormDetailed(Direction)=0 then
    begin
      Result.Status:=isStagnation;
      Break;
    end;
    Alpha:=Options.InitialStep;
    Accepted:=False;
    for LineIteration:=0 to 39 do
    begin
      SetLength(Trial,Length(X));
      for N:=0 to High(X) do
        Trial[N]:=X[N]+Alpha*Direction[N];
      Trial:=ProjectDetailed(Trial,Options);
      SetLength(Step,Length(X));
      for N:=0 to High(X) do Step[N]:=Trial[N]-X[N];
      StepNorm:=NormDetailed(Step);
      Scale:=Options.AbsoluteTolerance+
        Options.RelativeTolerance*Max(1,NormDetailed(X));
      if StepNorm<=Scale then
      begin
        Alpha:=Alpha/2;
        Continue;
      end;
      if Result.Evaluations>=Options.MaxEvaluations then Break;
      TrialF:=EvaluateDetailed(Source,Trial,Result.Evaluations,
        Options.MaxEvaluations,Operation);
      UpdateDetailedBest(Result,Trial,TrialF);
      if TrialF<=FX+1E-4*DotDetailed(G,Step) then
      begin
        Accepted:=True;
        Break;
      end;
      Alpha:=Alpha/2;
    end;
    if not Accepted then
    begin
      if Result.Evaluations>=Options.MaxEvaluations then
        Result.Status:=isIterationLimit
      else
        Result.Status:=isStagnation;
      Break;
    end;
    if Result.Evaluations+Length(X)>Options.MaxEvaluations then
    begin
      X:=Trial; FX:=TrialF;
      Result.Status:=isIterationLimit;
      Break;
    end;
    GNew:=GradientDetailed(Source,Trial,Result.Evaluations,
      Options.MaxEvaluations,Operation);
    SetLength(Y,Length(G));
    for N:=0 to High(G) do Y[N]:=GNew[N]-G[N];
    SY:=DotDetailed(Step,Y);
    if SY>1E-14*Max(1,NormDetailed(Step)*NormDetailed(Y)) then
    begin
      J:=K mod Options.HistorySize;
      SBuf[J]:=Copy(Step);
      YBuf[J]:=Copy(Y);
      Rho[J]:=1/SY;
      Inc(K);
    end;
    X:=Trial; FX:=TrialF; G:=GNew;
    Result.Iters:=Iteration;
    if Assigned(Options.Progress) and
       not Options.Progress(Iteration,Result.Evaluations,FX,
         NormDetailed(ProjectedGradient(X,G,Options)),0) then
    begin
      Result.Status:=isCancelled;
      Break;
    end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=Copy(Result.BestX);
  Result.FVal:=Result.BestFVal;
  Result.Converged:=Result.Status=isConverged;
  if Length(Result.X)=0 then
  begin
    Result.X:=Copy(X);
    Result.FVal:=FX;
    Result.BestX:=Copy(X);
    Result.BestFVal:=FX;
  end;
end;

class function TOptimizationKit.BoundedLBFGS(F:TMultivarFunc;
  Grad:TGradFunc; const X0:TDoubleArray;
  const Options:TOptimizationOptions):TOptResult;
var
  Source:TDetailedObjectiveSource;
begin
  Source:=Default(TDetailedObjectiveSource);
  Source.Objective:=F;
  Source.Gradient:=Grad;
  Result:=RunDetailedLBFGS(Source,X0,Options,'BoundedLBFGS');
end;

class function TOptimizationKit.BoundedLBFGSWithWorkspace(
  F:TMultivarFunc; Grad:TGradFunc; const X0:TDoubleArray;
  const Options:TOptimizationOptions;
  var Workspace:TOptimizationWorkspace):TOptResult;
var
  Start:TDoubleArray;
  Candidate:TOptimizationWorkspace;
begin
  if (Length(Workspace.WarmStartX)=Length(X0)) and
     (Length(Workspace.WarmStartX)>0) then
    Start:=Copy(Workspace.WarmStartX)
  else
    Start:=Copy(X0);
  Result:=BoundedLBFGS(F,Grad,Start,Options);
  Candidate:=Workspace;
  if Length(Result.BestX)>0 then
    Candidate.WarmStartX:=Copy(Result.BestX)
  else
    Candidate.WarmStartX:=Copy(Result.X);
  Inc(Candidate.Runs);
  if Candidate.TotalEvaluations<=High(Int64)-Result.Evaluations then
    Inc(Candidate.TotalEvaluations,Result.Evaluations)
  else
    Candidate.TotalEvaluations:=High(Int64);
  Workspace:=Candidate;
end;

class function TOptimizationKit.LBFGSAuto(F:TDualFunction;
  const X0:TDoubleArray; const Options:TOptimizationOptions):TOptResult;
var
  Source:TDetailedObjectiveSource;
begin
  Source:=Default(TDetailedObjectiveSource);
  Source.DualObjective:=F;
  Result:=RunDetailedLBFGS(Source,X0,Options,'LBFGSAuto');
end;

class function TOptimizationKit.NonlinearConjugateGradient(
  F:TMultivarFunc; Grad:TGradFunc; const X0:TDoubleArray;
  const Options:TOptimizationOptions):TOptResult;
var
  Source:TDetailedObjectiveSource;
  X,Trial,G,GNew,PG,PGNew,Direction,Step:TDoubleArray;
  FX,TrialF,Alpha,Beta,Denominator,Directional,Scale:Double;
  I,Iteration,LineIteration:Integer;
  Accepted:Boolean;
begin
  Result:=Default(TOptResult);
  if not Assigned(F) then
    raise EOptimizationError.Create(
      'NonlinearConjugateGradient: objective is nil');
  ValidateDetailedOptions(X0,Options,'NonlinearConjugateGradient');
  Source:=Default(TDetailedObjectiveSource);
  Source.Objective:=F; Source.Gradient:=Grad;
  X:=ProjectDetailed(X0,Options);
  FX:=EvaluateDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,'NonlinearConjugateGradient');
  G:=GradientDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,'NonlinearConjugateGradient');
  PG:=ProjectedGradient(X,G,Options);
  SetLength(Direction,Length(X));
  for I:=0 to High(X) do Direction[I]:=-PG[I];
  Result.BestFVal:=Infinity;
  UpdateDetailedBest(Result,X,FX);
  for Iteration:=1 to Options.MaxIterations do
  begin
    Result.GradientNorm:=NormDetailed(PG);
    if Result.GradientNorm<=Options.GradientTolerance then
    begin
      Result.Status:=isConverged;
      Break;
    end;
    Directional:=DotDetailed(PG,Direction);
    if Directional>=0 then
    begin
      for I:=0 to High(Direction) do Direction[I]:=-PG[I];
      Directional:=-DotDetailed(PG,PG);
    end;
    Alpha:=Options.InitialStep; Accepted:=False;
    for LineIteration:=0 to 39 do
    begin
      SetLength(Trial,Length(X));
      for I:=0 to High(X) do Trial[I]:=X[I]+Alpha*Direction[I];
      Trial:=ProjectDetailed(Trial,Options);
      SetLength(Step,Length(X));
      for I:=0 to High(X) do Step[I]:=Trial[I]-X[I];
      Scale:=Options.AbsoluteTolerance+
        Options.RelativeTolerance*Max(1,NormDetailed(X));
      if NormDetailed(Step)<=Scale then
      begin Alpha:=Alpha/2; Continue; end;
      if Result.Evaluations>=Options.MaxEvaluations then Break;
      TrialF:=EvaluateDetailed(Source,Trial,Result.Evaluations,
        Options.MaxEvaluations,'NonlinearConjugateGradient');
      UpdateDetailedBest(Result,Trial,TrialF);
      if TrialF<=FX+1E-4*DotDetailed(G,Step) then
      begin Accepted:=True; Break; end;
      Alpha:=Alpha/2;
    end;
    if not Accepted then
    begin
      if Result.Evaluations>=Options.MaxEvaluations then
        Result.Status:=isIterationLimit
      else
        Result.Status:=isStagnation;
      Break;
    end;
    if Result.Evaluations+Length(X)>Options.MaxEvaluations then
    begin Result.Status:=isIterationLimit; Break; end;
    GNew:=GradientDetailed(Source,Trial,Result.Evaluations,
      Options.MaxEvaluations,'NonlinearConjugateGradient');
    PGNew:=ProjectedGradient(Trial,GNew,Options);
    Denominator:=DotDetailed(PG,PG);
    if Denominator>0 then
    begin
      Beta:=0;
      for I:=0 to High(PG) do
        Beta:=Beta+PGNew[I]*(PGNew[I]-PG[I]);
      Beta:=Max(0,Beta/Denominator);
    end
    else Beta:=0;
    for I:=0 to High(Direction) do
      Direction[I]:=-PGNew[I]+Beta*Direction[I];
    X:=Trial; FX:=TrialF; G:=GNew; PG:=PGNew;
    Result.Iters:=Iteration;
    if Assigned(Options.Progress) and
       not Options.Progress(Iteration,Result.Evaluations,FX,
         NormDetailed(PG),0) then
    begin Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=Copy(Result.BestX); Result.FVal:=Result.BestFVal;
  Result.Converged:=Result.Status=isConverged;
end;

class function TOptimizationKit.TrustRegion(F:TMultivarFunc;
  Grad:TGradFunc; const X0:TDoubleArray;
  const Options:TOptimizationOptions):TOptResult;
var
  Source:TDetailedObjectiveSource;
  X,Trial,G,PG,Step:TDoubleArray;
  FX,TrialF,Radius,GradientNorm,Predicted,Actual,Rho,Scale:Double;
  I,Iteration,Stale:Integer;
begin
  Result:=Default(TOptResult);
  if not Assigned(F) then
    raise EOptimizationError.Create('TrustRegion: objective is nil');
  ValidateDetailedOptions(X0,Options,'TrustRegion');
  Source:=Default(TDetailedObjectiveSource);
  Source.Objective:=F; Source.Gradient:=Grad;
  X:=ProjectDetailed(X0,Options);
  FX:=EvaluateDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,'TrustRegion');
  G:=GradientDetailed(Source,X,Result.Evaluations,
    Options.MaxEvaluations,'TrustRegion');
  Radius:=Options.InitialTrustRadius; Stale:=0;
  Result.BestFVal:=Infinity; UpdateDetailedBest(Result,X,FX);
  for Iteration:=1 to Options.MaxIterations do
  begin
    PG:=ProjectedGradient(X,G,Options);
    GradientNorm:=NormDetailed(PG);
    Result.GradientNorm:=GradientNorm;
    if GradientNorm<=Options.GradientTolerance then
    begin Result.Status:=isConverged; Break; end;
    SetLength(Step,Length(X));
    for I:=0 to High(X) do Step[I]:=-PG[I]*Min(1,Radius/GradientNorm);
    SetLength(Trial,Length(X));
    for I:=0 to High(X) do Trial[I]:=X[I]+Step[I];
    Trial:=ProjectDetailed(Trial,Options);
    for I:=0 to High(X) do Step[I]:=Trial[I]-X[I];
    Scale:=Options.AbsoluteTolerance+
      Options.RelativeTolerance*Max(1,NormDetailed(X));
    if NormDetailed(Step)<=Scale then
    begin
      Radius:=Radius/4; Inc(Stale);
      if Stale>=12 then begin Result.Status:=isStagnation; Break; end;
      Continue;
    end;
    if Result.Evaluations>=Options.MaxEvaluations then
    begin Result.Status:=isIterationLimit; Break; end;
    TrialF:=EvaluateDetailed(Source,Trial,Result.Evaluations,
      Options.MaxEvaluations,'TrustRegion');
    UpdateDetailedBest(Result,Trial,TrialF);
    Predicted:=-DotDetailed(G,Step);
    Actual:=FX-TrialF;
    if Predicted>0 then Rho:=Actual/Predicted else Rho:=-Infinity;
    if Rho>0.1 then
    begin
      X:=Trial; FX:=TrialF;
      if Result.Evaluations+Length(X)>Options.MaxEvaluations then
      begin Result.Status:=isIterationLimit; Break; end;
      G:=GradientDetailed(Source,X,Result.Evaluations,
        Options.MaxEvaluations,'TrustRegion');
      Stale:=0;
    end
    else Inc(Stale);
    if Rho<0.25 then Radius:=Radius/4
    else if (Rho>0.75) and
      (NormDetailed(Step)>=0.9*Radius) then Radius:=2*Radius;
    Result.Iters:=Iteration;
    if Stale>=12 then begin Result.Status:=isStagnation; Break; end;
    if Assigned(Options.Progress) and
       not Options.Progress(Iteration,Result.Evaluations,FX,
         GradientNorm,0) then
    begin Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=Copy(Result.BestX); Result.FVal:=Result.BestFVal;
  Result.Converged:=Result.Status=isConverged;
end;

class function TOptimizationKit.MultiStart(F:TMultivarFunc;
  Grad:TGradFunc; const InitialPoints:array of TDoubleArray;
  const Options:TOptimizationOptions):TOptResult;
var
  RunOptions:TOptimizationOptions;
  Candidate,Point:TOptResult;
  Random:TLocalRandom;
  I,J,RunCount:Integer;
begin
  Result:=Default(TOptResult);
  if Length(InitialPoints)=0 then
    raise EOptimizationError.Create(
      'MultiStart: at least one initial point is required');
  if not Assigned(F) then
    raise EOptimizationError.Create('MultiStart: objective is nil');
  ValidateDetailedOptions(InitialPoints[0],Options,'MultiStart');
  for I:=1 to High(InitialPoints) do
    if Length(InitialPoints[I])<>Length(InitialPoints[0]) then
      raise EOptimizationError.Create(
        'MultiStart: all initial points must have the same dimension');
  RunCount:=Max(Length(InitialPoints),Options.StartCount);
  Random:=TLocalRandom.Seeded(Options.Seed);
  Result.BestFVal:=Infinity;
  for I:=0 to RunCount-1 do
  begin
    if I<Length(InitialPoints) then
      Point.X:=Copy(InitialPoints[I])
    else
    begin
      Point.X:=Copy(InitialPoints[0]);
      for J:=0 to High(Point.X) do
        Point.X[J]:=Point.X[J]+Options.InitialTrustRadius*
          (2*Random.NextDouble-1);
    end;
    RunOptions:=Options;
    RunOptions.StartCount:=1;
    RunOptions.Seed:=Options.Seed+QWord(I);
    RunOptions.MaxEvaluations:=Options.MaxEvaluations-Result.Evaluations;
    if RunOptions.MaxEvaluations<=2*Length(Point.X)+1 then
    begin
      Result.Status:=isIterationLimit;
      Break;
    end;
    Candidate:=BoundedLBFGS(F,Grad,Point.X,RunOptions);
    Inc(Result.Evaluations,Candidate.Evaluations);
    if (Length(Result.BestX)=0) or
       (Candidate.FVal<Result.BestFVal) then
    begin
      Result.BestX:=Copy(Candidate.X);
      Result.BestFVal:=Candidate.FVal;
      Result.X:=Copy(Candidate.X);
      Result.FVal:=Candidate.FVal;
      Result.GradientNorm:=Candidate.GradientNorm;
      Result.ConstraintViolation:=Candidate.ConstraintViolation;
      Result.Status:=Candidate.Status;
      Result.Converged:=Candidate.Converged;
    end;
    Inc(Result.Iters,Candidate.Iters);
    if Candidate.Status=isCancelled then
    begin Result.Status:=isCancelled; Break; end;
  end;
  if Length(Result.BestX)=0 then
    raise EOptimizationError.Create(
      'MultiStart: evaluation budget was too small for one start');
  if (Result.Status<>isCancelled) and Result.Converged then
    Result.Status:=isConverged
  else if Result.Status=isUnknown then
    Result.Status:=isIterationLimit;
end;

function ConstraintValueChecked(const Constraint:TSmoothConstraint;
  const X:TDoubleArray; var Evaluations:Integer;
  const MaxEvaluations:Integer; const Operation:String):Double;
begin
  if not Assigned(Constraint.Value) then
    raise EOptimizationError.Create(Operation+': constraint callback is nil');
  if Evaluations>=MaxEvaluations then
    raise EOptimizationError.Create(Operation+': evaluation limit reached');
  Result:=Constraint.Value(X);
  Inc(Evaluations);
  if IsNan(Result) or IsInfinite(Result) then
    raise EOptimizationError.Create(
      Operation+': constraint returned a non-finite value');
end;

function ConstraintGradientChecked(const Constraint:TSmoothConstraint;
  const X:TDoubleArray; var Evaluations:Integer;
  const MaxEvaluations:Integer; const Operation:String):TDoubleArray;
var
  XP,XM:TDoubleArray;
  I:Integer;
  H,FP,FM:Double;
begin
  Result:=nil;
  if Assigned(Constraint.Gradient) then
  begin
    if Evaluations>=MaxEvaluations then
      raise EOptimizationError.Create(Operation+': evaluation limit reached');
    Result:=Constraint.Gradient(X);
    Inc(Evaluations);
  end
  else
  begin
    if Evaluations+2*Length(X)>MaxEvaluations then
      raise EOptimizationError.Create(Operation+': evaluation limit reached');
    XP:=Copy(X); XM:=Copy(X); SetLength(Result,Length(X));
    for I:=0 to High(X) do
    begin
      H:=Power(2.2204460492503131E-16,1/3)*Max(1,Abs(X[I]));
      XP[I]:=X[I]+H; XM[I]:=X[I]-H;
      FP:=Constraint.Value(XP); FM:=Constraint.Value(XM);
      Inc(Evaluations,2);
      XP[I]:=X[I]; XM[I]:=X[I];
      if IsNan(FP) or IsInfinite(FP) or
         IsNan(FM) or IsInfinite(FM) then
        raise EOptimizationError.Create(
          Operation+': constraint returned non-finite difference values');
      Result[I]:=(FP-FM)/(2*H);
    end;
  end;
  if Length(Result)<>Length(X) then
    raise EOptimizationError.Create(
      Operation+': constraint gradient dimension mismatch');
  RequireFiniteVector(Result,Operation+' constraint gradient');
end;

class function TOptimizationKit.SolveConstrained(F:TMultivarFunc;
  Grad:TGradFunc; const Constraints:TSmoothConstraints;
  const X0:TDoubleArray; const Options:TOptimizationOptions):TOptResult;
var
  Source:TDetailedObjectiveSource;
  X,Trial,G,AugmentedGradient,CG,Step,LowPoint,HighPoint,
    MidPoint:TDoubleArray;
  Values,Multipliers:TDoubleArray;
  FX,TrialF,Merit,TrialMerit,Mu,Violation,BestFeasibility,
    Feasibility,GradientNorm,Alpha,Coefficient,Scale:Double;
  I,J,Iteration,LineIteration,Stale,EvaluationCount,Bisection:Integer;
  Accepted,AllInequality:Boolean;

  function EvaluateMerit(const AtX:TDoubleArray;
    out Objective,MaximumViolation:Double):Double;
  var
    C,Term:Double;
    ConstraintIndex:Integer;
  begin
    Objective:=EvaluateDetailed(Source,AtX,EvaluationCount,
      Options.MaxEvaluations,'SolveConstrained');
    Result:=Objective;
    MaximumViolation:=0;
    for ConstraintIndex:=0 to High(Constraints) do
    begin
      C:=ConstraintValueChecked(Constraints[ConstraintIndex],AtX,
        EvaluationCount,Options.MaxEvaluations,'SolveConstrained');
      if Constraints[ConstraintIndex].Kind=ckEquality then
      begin
        MaximumViolation:=Max(MaximumViolation,Abs(C));
        Result:=Result+Multipliers[ConstraintIndex]*C+0.5*Mu*Sqr(C);
      end
      else
      begin
        MaximumViolation:=Max(MaximumViolation,Max(0,C));
        Term:=Max(0,Multipliers[ConstraintIndex]+Mu*C);
        Result:=Result+(Sqr(Term)-Sqr(Multipliers[ConstraintIndex]))/(2*Mu);
      end;
    end;
  end;

begin
  Result:=Default(TOptResult);
  if not Assigned(F) then
    raise EOptimizationError.Create('SolveConstrained: objective is nil');
  ValidateDetailedOptions(X0,Options,'SolveConstrained');
  for I:=0 to High(Constraints) do
    if (not Assigned(Constraints[I].Value)) or
       (Constraints[I].Tolerance<0) or
       IsNan(Constraints[I].Tolerance) or
       IsInfinite(Constraints[I].Tolerance) then
      raise EOptimizationError.CreateFmt(
        'SolveConstrained: invalid constraint %d',[I]);
  Source:=Default(TDetailedObjectiveSource);
  Source.Objective:=F; Source.Gradient:=Grad;
  X:=ProjectDetailed(X0,Options);
  SetLength(Multipliers,Length(Constraints));
  SetLength(Values,Length(Constraints));
  Mu:=10; Stale:=0; BestFeasibility:=Infinity; EvaluationCount:=0;
  Merit:=EvaluateMerit(X,FX,Feasibility);
  Result.BestX:=Copy(X); Result.BestFVal:=FX;
  Result.ConstraintViolation:=Feasibility;
  BestFeasibility:=Feasibility;
  for Iteration:=1 to Options.MaxIterations do
  begin
    if EvaluationCount>=Options.MaxEvaluations then
    begin Result.Status:=isIterationLimit; Break; end;
    G:=GradientDetailed(Source,X,EvaluationCount,
      Options.MaxEvaluations,'SolveConstrained');
    AugmentedGradient:=Copy(G);
    Feasibility:=0;
    for I:=0 to High(Constraints) do
    begin
      Values[I]:=ConstraintValueChecked(Constraints[I],X,
        EvaluationCount,Options.MaxEvaluations,'SolveConstrained');
      if Constraints[I].Kind=ckEquality then
      begin
        Violation:=Abs(Values[I]);
        Coefficient:=Multipliers[I]+Mu*Values[I];
      end
      else
      begin
        Violation:=Max(0,Values[I]);
        Coefficient:=Max(0,Multipliers[I]+Mu*Values[I]);
      end;
      Feasibility:=Max(Feasibility,Violation);
      if Coefficient<>0 then
      begin
        CG:=ConstraintGradientChecked(Constraints[I],X,
          EvaluationCount,Options.MaxEvaluations,'SolveConstrained');
        for J:=0 to High(X) do
          AugmentedGradient[J]:=AugmentedGradient[J]+Coefficient*CG[J];
      end;
    end;
    GradientNorm:=NormDetailed(ProjectedGradient(X,AugmentedGradient,Options));
    Result.GradientNorm:=GradientNorm;
    Result.ConstraintViolation:=Feasibility;
    if (GradientNorm<=Options.GradientTolerance) and
       (Feasibility<=Options.AbsoluteTolerance+
        Options.RelativeTolerance) then
    begin Result.Status:=isConverged; Break; end;
    SetLength(Step,Length(X));
    for J:=0 to High(X) do Step[J]:=-AugmentedGradient[J];
    Alpha:=Options.InitialStep/Max(1,NormDetailed(Step));
    Accepted:=False;
    for LineIteration:=0 to 39 do
    begin
      SetLength(Trial,Length(X));
      for J:=0 to High(X) do Trial[J]:=X[J]+Alpha*Step[J];
      Trial:=ProjectDetailed(Trial,Options);
      Scale:=Options.AbsoluteTolerance+
        Options.RelativeTolerance*Max(1,NormDetailed(X));
      for J:=0 to High(X) do Step[J]:=Trial[J]-X[J];
      if NormDetailed(Step)<=Scale then
      begin Alpha:=Alpha/2; Continue; end;
      if EvaluationCount+Length(Constraints)+1>
         Options.MaxEvaluations then Break;
      TrialMerit:=EvaluateMerit(Trial,TrialF,Violation);
      if TrialMerit<Merit then
      begin Accepted:=True; Break; end;
      Alpha:=Alpha/2;
    end;
    if not Accepted then
    begin
      if BestFeasibility<=Options.AbsoluteTolerance+
         Options.RelativeTolerance then
        Result.Status:=isAcceptableLimit
      else
        Result.Status:=isInfeasible;
      Break;
    end;
    X:=Trial; FX:=TrialF; Merit:=TrialMerit;
    if (Violation<BestFeasibility) or
       ((Violation<=BestFeasibility) and (FX<Result.BestFVal)) then
    begin
      BestFeasibility:=Violation;
      Result.BestX:=Copy(X);
      Result.BestFVal:=FX;
      Result.ConstraintViolation:=Violation;
    end;
    for I:=0 to High(Constraints) do
    begin
      Values[I]:=ConstraintValueChecked(Constraints[I],X,
        EvaluationCount,Options.MaxEvaluations,'SolveConstrained');
      if Constraints[I].Kind=ckEquality then
        Multipliers[I]:=Multipliers[I]+Mu*Values[I]
      else
        Multipliers[I]:=Max(0,Multipliers[I]+Mu*Values[I]);
    end;
    Merit:=FX;
    for I:=0 to High(Constraints) do
      if Constraints[I].Kind=ckEquality then
        Merit:=Merit+Multipliers[I]*Values[I]+0.5*Mu*Sqr(Values[I])
      else
        Merit:=Merit+
          (Sqr(Max(0,Multipliers[I]+Mu*Values[I]))-
           Sqr(Multipliers[I]))/(2*Mu);
    if (Feasibility>Options.AbsoluteTolerance+Options.RelativeTolerance) and
       (Violation>=0.9*Feasibility) then
    begin Mu:=Min(1E12,Mu*5); Inc(Stale); end
    else Stale:=0;
    Result.Iters:=Iteration;
    if Stale>=20 then
    begin
      if BestFeasibility<=Options.AbsoluteTolerance+
         Options.RelativeTolerance then
        Result.Status:=isAcceptableLimit
      else Result.Status:=isInfeasible;
      Break;
    end;
    if Assigned(Options.Progress) and
       not Options.Progress(Iteration,EvaluationCount,FX,
         GradientNorm,Violation) then
    begin Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  AllInequality:=Length(Constraints)>0;
  for I:=0 to High(Constraints) do
    AllInequality:=AllInequality and
      (Constraints[I].Kind=ckInequality);
  if AllInequality and
     (BestFeasibility<=Options.AbsoluteTolerance+
       Options.RelativeTolerance) and
     (Feasibility>Options.AbsoluteTolerance+Options.RelativeTolerance) then
  begin
    LowPoint:=Copy(Result.BestX);
    HighPoint:=Copy(X);
    for Bisection:=1 to 48 do
    begin
      if EvaluationCount+Length(Constraints)+1>
         Options.MaxEvaluations then Break;
      SetLength(MidPoint,Length(X));
      for J:=0 to High(X) do
        MidPoint[J]:=0.5*(LowPoint[J]+HighPoint[J]);
      TrialMerit:=EvaluateMerit(MidPoint,TrialF,Violation);
      if Violation<=Options.AbsoluteTolerance+Options.RelativeTolerance then
        LowPoint:=MidPoint
      else
        HighPoint:=MidPoint;
    end;
    if EvaluationCount+Length(Constraints)+1<=Options.MaxEvaluations then
    begin
      TrialMerit:=EvaluateMerit(LowPoint,TrialF,Violation);
      if TrialF<Result.BestFVal then
      begin
        Result.BestX:=Copy(LowPoint);
        Result.BestFVal:=TrialF;
        BestFeasibility:=Violation;
      end;
    end;
    Result.Status:=isAcceptableLimit;
  end;
  Result.X:=Copy(Result.BestX);
  Result.FVal:=Result.BestFVal;
  Result.ConstraintViolation:=BestFeasibility;
  Result.Evaluations:=EvaluationCount;
  Result.Converged:=Result.Status=isConverged;
end;

function RunWeightedObjective(const Objectives:TMultivarFunctions;
  const Weights,X0:TDoubleArray; const Options:TOptimizationOptions):
  TOptResult;
var
  X,Trial,G,Step:TDoubleArray;
  FX,TrialF,Alpha,GradientNorm,Scale,WeightSum:Double;
  I,J,Iteration,LineIteration,EvaluationCount:Integer;
  Accepted:Boolean;

  function WeightedValue(const AtX:TDoubleArray):Double;
  var
    ObjectiveIndex:Integer;
    Value:Double;
  begin
    Result:=0;
    for ObjectiveIndex:=0 to High(Objectives) do
    begin
      if not Assigned(Objectives[ObjectiveIndex]) then
        raise EOptimizationError.Create(
          'ExplorePareto: objective callback is nil');
      if EvaluationCount>=Options.MaxEvaluations then
        raise EOptimizationError.Create(
          'ExplorePareto: evaluation limit reached');
      Value:=Objectives[ObjectiveIndex](AtX);
      Inc(EvaluationCount);
      if IsNan(Value) or IsInfinite(Value) then
        raise EOptimizationError.Create(
          'ExplorePareto: objective returned a non-finite value');
      Result:=Result+Weights[ObjectiveIndex]*Value;
    end;
  end;

  function WeightedGradient(const AtX:TDoubleArray):TDoubleArray;
  var
    XP,XM:TDoubleArray;
    Column:Integer;
    H:Double;
  begin
    Result:=nil;
    SetLength(Result,Length(AtX));
    XP:=Copy(AtX); XM:=Copy(AtX);
    for Column:=0 to High(AtX) do
    begin
      H:=Power(2.2204460492503131E-16,1/3)*Max(1,Abs(AtX[Column]));
      XP[Column]:=AtX[Column]+H;
      XM[Column]:=AtX[Column]-H;
      Result[Column]:=(WeightedValue(XP)-WeightedValue(XM))/(2*H);
      XP[Column]:=AtX[Column];
      XM[Column]:=AtX[Column];
    end;
  end;

begin
  Result:=Default(TOptResult);
  if (Length(Objectives)<2) or
     (Length(Weights)<>Length(Objectives)) then
    raise EOptimizationError.Create(
      'ExplorePareto: each weight vector must match at least two objectives');
  ValidateDetailedOptions(X0,Options,'ExplorePareto');
  WeightSum:=0;
  for I:=0 to High(Weights) do
  begin
    if (Weights[I]<0) or IsNan(Weights[I]) or IsInfinite(Weights[I]) then
      raise EOptimizationError.Create(
        'ExplorePareto: weights must be finite and non-negative');
    WeightSum:=WeightSum+Weights[I];
  end;
  if WeightSum<=0 then
    raise EOptimizationError.Create(
      'ExplorePareto: at least one weight must be positive');
  EvaluationCount:=0;
  X:=ProjectDetailed(X0,Options);
  FX:=WeightedValue(X);
  Result.BestX:=Copy(X); Result.BestFVal:=FX;
  for Iteration:=1 to Options.MaxIterations do
  begin
    if EvaluationCount+2*Length(X)*Length(Objectives)>
       Options.MaxEvaluations then
    begin Result.Status:=isIterationLimit; Break; end;
    G:=WeightedGradient(X);
    GradientNorm:=NormDetailed(ProjectedGradient(X,G,Options));
    Result.GradientNorm:=GradientNorm;
    if GradientNorm<=Options.GradientTolerance then
    begin Result.Status:=isConverged; Break; end;
    SetLength(Step,Length(X));
    for I:=0 to High(X) do Step[I]:=-G[I];
    Alpha:=Options.InitialStep/Max(1,GradientNorm);
    Accepted:=False;
    for LineIteration:=0 to 39 do
    begin
      SetLength(Trial,Length(X));
      for J:=0 to High(X) do Trial[J]:=X[J]+Alpha*Step[J];
      Trial:=ProjectDetailed(Trial,Options);
      Scale:=Options.AbsoluteTolerance+
        Options.RelativeTolerance*Max(1,NormDetailed(X));
      for J:=0 to High(X) do Step[J]:=Trial[J]-X[J];
      if NormDetailed(Step)<=Scale then
      begin Alpha:=Alpha/2; Continue; end;
      if EvaluationCount+Length(Objectives)>Options.MaxEvaluations then
        Break;
      TrialF:=WeightedValue(Trial);
      if TrialF<Result.BestFVal then
      begin Result.BestX:=Copy(Trial); Result.BestFVal:=TrialF; end;
      if TrialF<=FX+1E-4*DotDetailed(G,Step) then
      begin Accepted:=True; Break; end;
      Alpha:=Alpha/2;
    end;
    if not Accepted then
    begin
      if EvaluationCount>=Options.MaxEvaluations then
        Result.Status:=isIterationLimit
      else Result.Status:=isStagnation;
      Break;
    end;
    X:=Trial; FX:=TrialF; Result.Iters:=Iteration;
    if Assigned(Options.Progress) and
       not Options.Progress(Iteration,EvaluationCount,FX,
         GradientNorm,0) then
    begin Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=Copy(Result.BestX); Result.FVal:=Result.BestFVal;
  Result.Evaluations:=EvaluationCount;
  Result.Converged:=Result.Status=isConverged;
end;

class function TOptimizationKit.ExplorePareto(
  const Objectives:TMultivarFunctions;
  const InitialPoints,Weights:array of TDoubleArray;
  const Options:TOptimizationOptions):TMultiObjectiveResult;
var
  Candidates:TOptResults;
  Values:TObjectiveMatrix;
  Candidate:TOptResult;
  RunOptions:TOptimizationOptions;
  I,J,K,PointIndex,OutCount:Integer;
  Dominated,Strict:Boolean;
  Value:Double;
begin
  Result:=Default(TMultiObjectiveResult);
  if Length(Objectives)<2 then
    raise EOptimizationError.Create(
      'ExplorePareto: at least two objectives are required');
  if (Length(InitialPoints)=0) or (Length(Weights)=0) then
    raise EOptimizationError.Create(
      'ExplorePareto: initial points and weight vectors are required');
  SetLength(Candidates,Length(Weights));
  SetLength(Values,Length(Weights));
  for I:=0 to High(Weights) do
  begin
    PointIndex:=I mod Length(InitialPoints);
    RunOptions:=Options;
    RunOptions.MaxEvaluations:=Options.MaxEvaluations-Result.Evaluations;
    Candidate:=RunWeightedObjective(Objectives,Weights[I],
      InitialPoints[PointIndex],RunOptions);
    Candidates[I]:=Candidate;
    Inc(Result.Evaluations,Candidate.Evaluations);
    SetLength(Values[I],Length(Objectives));
    for J:=0 to High(Objectives) do
    begin
      if Result.Evaluations>=Options.MaxEvaluations then
      begin Result.Status:=isIterationLimit; Break; end;
      Value:=Objectives[J](Candidate.X);
      Inc(Result.Evaluations);
      if IsNan(Value) or IsInfinite(Value) then
        raise EOptimizationError.Create(
          'ExplorePareto: objective returned a non-finite value');
      Values[I][J]:=Value;
    end;
    if Result.Status=isIterationLimit then Break;
    if Candidate.Status=isCancelled then
    begin Result.Status:=isCancelled; Break; end;
  end;
  OutCount:=0;
  for I:=0 to High(Candidates) do
  begin
    if Length(Candidates[I].X)=0 then Continue;
    Dominated:=False;
    for J:=0 to High(Candidates) do
    begin
      if (I=J) or (Length(Candidates[J].X)=0) then Continue;
      Strict:=False;
      for K:=0 to High(Objectives) do
      begin
        if Values[J][K]>Values[I][K] then
        begin Strict:=False; Break; end;
        if Values[J][K]<Values[I][K] then Strict:=True;
      end;
      if Strict then begin Dominated:=True; Break; end;
    end;
    if not Dominated then
    begin
      SetLength(Result.Points,OutCount+1);
      SetLength(Result.ObjectiveValues,OutCount+1);
      Result.Points[OutCount]:=Candidates[I];
      Result.ObjectiveValues[OutCount]:=Copy(Values[I]);
      Inc(OutCount);
    end;
  end;
  if Result.Status=isUnknown then
  begin
    Result.Status:=isConverged;
    for I:=0 to High(Candidates) do
      if (Length(Candidates[I].X)>0) and
         not (Candidates[I].Status in [isConverged,isAcceptableLimit]) then
      begin Result.Status:=isAcceptableLimit; Break; end;
  end;
end;

{ ---------------------------------------------------------------------------
  ADAM
--------------------------------------------------------------------------- }

class function TOptimizationKit.Adam(
  F: TMultivarFunc;
  Grad: TGradFunc;
  const X0: TDoubleArray;
  LR, Beta1, Beta2, Eps, Tol: Double;
  MaxIter: Integer): TOptResult;
var
  X, G, M, V: TDoubleArray;
  FX, MHat, VHat, B1t, B2t: Double;
  I, Iter, N: Integer;
begin
  Result:=Default(TOptResult);
  G := nil;
  Iter := 0;
  if not Assigned(F) then raise EOptimizationError.Create('Adam: objective is nil');
  if Length(X0) = 0 then
    raise EOptimizationError.Create('Adam: X0 must not be empty');
  RequireFiniteVector(X0, 'Adam');
  RequirePositiveFinite(LR, 'Adam learning rate');
  RequirePositiveFinite(Eps, 'Adam epsilon');
  RequirePositiveFinite(Tol, 'Adam tolerance');
  if IsNan(Beta1) or IsInfinite(Beta1) or (Beta1 <= 0.0) or (Beta1 >= 1.0) or
     IsNan(Beta2) or IsInfinite(Beta2) or (Beta2 <= 0.0) or (Beta2 >= 1.0) then
    raise EOptimizationError.Create('Adam: Beta1 and Beta2 must be in (0, 1)');
  if MaxIter <= 0 then raise EOptimizationError.Create('Adam: MaxIter must be > 0');
  N   := Length(X0);
  X   := VecCopy(X0);
  SetLength(M, N);  { 1st moment (mean) }
  SetLength(V, N);  { 2nd moment (uncentred variance) }
  FillChar(M[0], N * SizeOf(Double), 0);
  FillChar(V[0], N * SizeOf(Double), 0);
  B1t := 1;  B2t := 1;
  FX  := EvaluateMultivariate(F, X, 'Adam');
  Inc(Result.Evaluations);
  Result.BestX:=Copy(X);
  Result.BestFVal:=FX;
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if Assigned(Grad) then
    begin G := Grad(X); Inc(Result.Evaluations); end
    else
      G:=NumericalGradientCounted(F,X,1E-5,Result.Evaluations);
    if Length(G) <> N then raise EOptimizationError.Create(
      'Adam: gradient dimension mismatch');
    RequireFiniteVector(G, 'Adam gradient');

    if VecNorm(G) < Tol then
    begin
      Result.Converged := True;
      Break;
    end;

    B1t := B1t * Beta1;
    B2t := B2t * Beta2;

    for I := 0 to N-1 do
    begin
      M[I] := Beta1 * M[I] + (1 - Beta1) * G[I];        { biased 1st moment }
      V[I] := Beta2 * V[I] + (1 - Beta2) * G[I] * G[I]; { biased 2nd moment }
      MHat := M[I] / (1 - B1t);   { bias correction }
      VHat := V[I] / (1 - B2t);
      X[I] := X[I] - LR * MHat / (Sqrt(VHat) + Eps);
    end;
    FX := EvaluateMultivariate(F, X, 'Adam');
    Inc(Result.Evaluations);
    UpdateDetailedBest(Result,X,FX);
  end;

  Result.X     := X;
  Result.FVal  := FX;
  Result.Iters := Iter;
  Result.GradientNorm := VecNorm(G);
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

{ ---------------------------------------------------------------------------
  L-BFGS
--------------------------------------------------------------------------- }

class function TOptimizationKit.LBFGS(
  F: TMultivarFunc;
  Grad: TGradFunc;
  const X0: TDoubleArray;
  M: Integer;
  Tol: Double;
  MaxIter: Integer): TOptResult;
{ Two-loop recursion L-BFGS (Nocedal 1980).
  Stores the last M (s_k, y_k) pairs where s_k = x_(k+1)-x_k, y_k = g_(k+1)-g_k }
var
  N, Iter, K, I, J, Bound: Integer;
  X, G, GNew, Q, R, S, Y, Alpha_arr, Rho_arr: TDoubleArray;
  SBuf, YBuf: array of TDoubleArray;
  RhoBuf: TDoubleArray;
  FX, Alpha, Beta, GammaScale, Sy, Yy, SStep: Double;
begin
  Result:=Default(TOptResult);
  Iter := 0;
  if not Assigned(F) then raise EOptimizationError.Create('LBFGS: objective is nil');
  if Length(X0) = 0 then
    raise EOptimizationError.Create('LBFGS: X0 must not be empty');
  RequireFiniteVector(X0, 'LBFGS');
  if M <= 0 then raise EOptimizationError.Create('LBFGS: history size M must be > 0');
  RequirePositiveFinite(Tol, 'LBFGS tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('LBFGS: MaxIter must be > 0');
  N  := Length(X0);
  X  := VecCopy(X0);
  FX := EvaluateMultivariate(F, X, 'LBFGS');
  Inc(Result.Evaluations);
  Result.BestX:=Copy(X);
  Result.BestFVal:=FX;
  if Assigned(Grad) then
  begin G := Grad(X); Inc(Result.Evaluations); end
  else
    G:=NumericalGradientCounted(F,X,1E-5,Result.Evaluations);
  if Length(G) <> N then raise EOptimizationError.Create('LBFGS: gradient dimension mismatch');
  RequireFiniteVector(G, 'LBFGS gradient');

  SetLength(SBuf,    M);
  SetLength(YBuf,    M);
  SetLength(RhoBuf,  M);
  SetLength(Alpha_arr, M);
  SetLength(Rho_arr,   M);
  K := 0;
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if VecNorm(G) < Tol then
    begin
      Result.Converged := True;
      Break;
    end;

    { Two-loop recursion to compute search direction }
    Q     := VecCopy(G);
    Bound := Min(K, M);

    { First loop: newest to oldest }
    for I := Bound - 1 downto 0 do
    begin
      J           := (K - Bound + I) mod M;
      Rho_arr[I]  := RhoBuf[J];
      Alpha_arr[I]:= Rho_arr[I] * Dot(SBuf[J], Q);
      Q           := VecAdd(Q, YBuf[J], -Alpha_arr[I]);
    end;

    { Scale by inverse Hessian approximation H_0 }
    if K > 0 then
    begin
      J  := (K - 1) mod M;
      Sy := Dot(SBuf[J], YBuf[J]);
      Yy := Dot(YBuf[J], YBuf[J]);
      GammaScale := IfThen(Yy > 0, Sy / Yy, 1.0);
    end
    else
      GammaScale := 1.0;
    R := VecScale(Q, GammaScale);

    { Second loop: oldest to newest }
    for I := 0 to Bound - 1 do
    begin
      J    := (K - Bound + I) mod M;
      Beta := Rho_arr[I] * Dot(YBuf[J], R);
      R    := VecAdd(R, SBuf[J], Alpha_arr[I] - Beta);
    end;

    { Search direction = -R }
    S := VecScale(R, -1);

    { Line search }
    Alpha:=LineSearchCounted(F,X,S,FX,1,Result.Evaluations);

    { Update X }
    S    := VecScale(S, Alpha);   { s_k = step taken }
    X    := VecAdd(X, S, 1);
    FX   := EvaluateMultivariate(F, X, 'LBFGS');
    Inc(Result.Evaluations);
    UpdateDetailedBest(Result,X,FX);

    { Compute new gradient }
    if Assigned(Grad) then
    begin GNew := Grad(X); Inc(Result.Evaluations); end
    else
      GNew:=NumericalGradientCounted(F,X,1E-5,Result.Evaluations);
    if Length(GNew) <> N then raise EOptimizationError.Create(
      'LBFGS: gradient dimension mismatch');
    RequireFiniteVector(GNew, 'LBFGS gradient');

    { Store (s_k, y_k) in circular buffer }
    Y      := VecAdd(GNew, G, -1);  { y_k = g_(k+1) - g_k }
    Sy     := Dot(S, Y);
    J      := K mod M;
    SBuf[J] := VecCopy(S);
    YBuf[J] := VecCopy(Y);
    RhoBuf[J] := IfThen(Abs(Sy) > 1E-15, 1.0 / Sy, 0);

    G  := GNew;
    Inc(K);
  end;

  Result.X     := X;
  Result.FVal  := FX;
  Result.Iters := Iter;
  Result.GradientNorm := VecNorm(G);
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

{ ---------------------------------------------------------------------------
  NELDER-MEAD
--------------------------------------------------------------------------- }

class function TOptimizationKit.CoreObjective(F: TMultivarFunc;
  const Constraints: array of TConstraintFunc;
  const X: TDoubleArray; PenaltyWeight: Double;
  Negate:Boolean; var Evaluations:Integer):Double;
var
  J: Integer;
  Violation: Double;
begin
  Result := EvaluateMultivariate(F, X, 'NelderMead');
  Inc(Evaluations);
  if Negate then Result := -Result;
  for J := 0 to High(Constraints) do
  begin
    Violation := Constraints[J](X);
    Inc(Evaluations);
    if IsNan(Violation) or IsInfinite(Violation) then
      raise EOptimizationError.CreateFmt(
        'NelderMead: constraint %d returned a non-finite value', [J]);
    if Violation > 0 then
      Result := Result + PenaltyWeight * Violation * Violation;
  end;
end;

class function TOptimizationKit.NelderMeadCore(
  F: TMultivarFunc;
  const Constraints: array of TConstraintFunc;
  const X0: TDoubleArray;
  Scale, Tol: Double;
  MaxIter: Integer;
  PenaltyWeight: Double;
  Negate: Boolean): TOptResult;
{ Standard Nelder-Mead with reflection α=1, expansion γ=2,
  contraction ρ=0.5, shrink σ=0.5 }
const
  Alpha = 1.0;  { reflection }
  Gamma = 2.0;  { expansion }
  Rho   = 0.5;  { contraction }
  Sigma = 0.5;  { shrink }
var
  N, NP1, I, J, Iter, Best, Worst, SecondWorst: Integer;
  Simplex: array of TDoubleArray;
  FVals: TDoubleArray;
  Centroid, XR, XE, XC, Tmp: TDoubleArray;
  FR, FE, FC, Diam, Diff: Double;
begin
  Result:=Default(TOptResult);
  Iter := 0;
  N   := Length(X0);
  NP1 := N + 1;
  if not Assigned(F) then raise EOptimizationError.Create('NelderMead: objective is nil');
  if N = 0 then raise EOptimizationError.Create('NelderMead: X0 must not be empty');
  RequireFiniteVector(X0, 'NelderMead');
  RequirePositiveFinite(Scale, 'NelderMead scale');
  RequirePositiveFinite(Tol, 'NelderMead tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('NelderMead: MaxIter must be > 0');

  { Build initial simplex: vertex 0 = X0, vertex i = X0 + Scale*e_i }
  SetLength(Simplex, NP1);
  SetLength(FVals, NP1);
  for I := 0 to NP1-1 do
  begin
    Simplex[I] := VecCopy(X0);
    if I > 0 then Simplex[I][I-1] := Simplex[I][I-1] + Scale;
    FVals[I] := CoreObjective(F, Constraints, Simplex[I],
      PenaltyWeight,Negate,Result.Evaluations);
  end;

  Result.Converged := False;
  for Iter := 1 to MaxIter do
  begin
    { Sort: find best, worst, second-worst }
    Best := 0; Worst := 0;
    for I := 1 to NP1-1 do
    begin
      if FVals[I] < FVals[Best]  then Best  := I;
      if FVals[I] > FVals[Worst] then Worst := I;
    end;
    SecondWorst := IfThen(Best = 0, 1, 0);
    for I := 0 to NP1-1 do
      if (I <> Worst) and (FVals[I] > FVals[SecondWorst]) then
        SecondWorst := I;

    { Convergence check: diameter of simplex }
    Diam := 0;
    for I := 0 to NP1-1 do
    begin
      Diff := 0;
      for J := 0 to N-1 do
        Diff := Diff + Sqr(Simplex[I][J] - Simplex[Best][J]);
      Diam := Max(Diam, Sqrt(Diff));
    end;
    if Diam < Tol then
    begin
      Result.Converged := True;
      Break;
    end;

    { Centroid of all vertices except worst }
    SetLength(Centroid, N);
    FillChar(Centroid[0], N*SizeOf(Double), 0);
    for I := 0 to NP1-1 do
      if I <> Worst then
        for J := 0 to N-1 do
          Centroid[J] := Centroid[J] + Simplex[I][J];
    for J := 0 to N-1 do Centroid[J] := Centroid[J] / N;

    { Reflection }
    XR := VecAdd(Centroid, VecAdd(Centroid, Simplex[Worst], -1), Alpha);
    FR:=CoreObjective(F,Constraints,XR,PenaltyWeight,Negate,
      Result.Evaluations);

    if (FR < FVals[Best]) then
    begin
      { Expansion }
      XE := VecAdd(Centroid, VecAdd(XR, Centroid, -1), Gamma);
      FE:=CoreObjective(F,Constraints,XE,PenaltyWeight,Negate,
        Result.Evaluations);
      if FE < FR then begin Simplex[Worst] := XE; FVals[Worst] := FE; end
      else            begin Simplex[Worst] := XR; FVals[Worst] := FR; end;
    end
    else if FR < FVals[SecondWorst] then
    begin
      Simplex[Worst] := XR;
      FVals[Worst]   := FR;
    end
    else
    begin
      { Contraction }
      if FR < FVals[Worst] then
        XC := VecAdd(Centroid, VecAdd(XR, Centroid, -1), Rho)
      else
        XC := VecAdd(Centroid, VecAdd(Simplex[Worst], Centroid, -1), Rho);
      FC:=CoreObjective(F,Constraints,XC,PenaltyWeight,Negate,
        Result.Evaluations);
      if FC < Min(FR, FVals[Worst]) then
      begin
        Simplex[Worst] := XC;
        FVals[Worst]   := FC;
      end
      else
      begin
        { Shrink: pull all vertices toward best }
        for I := 0 to NP1-1 do
          if I <> Best then
          begin
            Simplex[I] := VecAdd(Simplex[Best],
              VecAdd(Simplex[I], Simplex[Best], -1), Sigma);
            FVals[I] := CoreObjective(F, Constraints, Simplex[I],
              PenaltyWeight,Negate,Result.Evaluations);
          end;
      end;
    end;
  end;

  { Find best vertex }
  Best := 0;
  for I := 1 to NP1-1 do
    if FVals[I] < FVals[Best] then Best := I;

  Result.X     := Simplex[Best];
  Result.FVal  := FVals[Best];
  Result.BestX:=Copy(Result.X);
  Result.BestFVal:=Result.FVal;
  Result.Iters := Iter;
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

class function TOptimizationKit.NelderMead(
  F: TMultivarFunc;
  const X0: TDoubleArray;
  Scale, Tol: Double;
  MaxIter: Integer): TOptResult;
begin
  Result := NelderMeadCore(F, [], X0, Scale, Tol, MaxIter, 0.0, False);
end;

{ ---------------------------------------------------------------------------
  SIMULATED ANNEALING
--------------------------------------------------------------------------- }

class function TOptimizationKit.SimulatedAnnealing(
  F: TMultivarFunc;
  const X0: TDoubleArray;
  T0, TMin, CoolRate, StepSize: Double;
  MaxIter, Seed: Integer): TOptResult;
{ Metropolis–Hastings acceptance: accept worse if rand < exp(-ΔE/T) }
var
  X, XBest, XNew: TDoubleArray;
  FX, FBest, FNew, T, Delta: Double;
  Iter, I, N: Integer;
  RandState: DWord;

  { Simple linear congruential generator for reproducibility }
  function LCG: Double;
  begin
    {$Q-}{$R-}
    RandState := RandState * 1664525 + 1013904223;
    {$Q+}{$R+}
    Result    := (RandState and $7FFFFFFF) / $7FFFFFFF;
  end;

  function LCGSigned: Double;
  begin
    Result := LCG * 2 - 1;  { uniform in (-1, +1) }
  end;

begin
  Result:=Default(TOptResult);
  Iter := 0;
  if not Assigned(F) then raise EOptimizationError.Create(
    'SimulatedAnnealing: objective is nil');
  if Length(X0) = 0 then
    raise EOptimizationError.Create('SimulatedAnnealing: X0 must not be empty');
  RequireFiniteVector(X0, 'SimulatedAnnealing');
  RequirePositiveFinite(T0, 'SimulatedAnnealing T0');
  RequirePositiveFinite(TMin, 'SimulatedAnnealing Tmin');
  RequirePositiveFinite(StepSize, 'SimulatedAnnealing step size');
  if TMin >= T0 then raise EOptimizationError.Create(
    'SimulatedAnnealing: Tmin must be less than T0');
  if IsNan(CoolRate) or IsInfinite(CoolRate) or
     (CoolRate <= 0.0) or (CoolRate >= 1.0) then
    raise EOptimizationError.Create('SimulatedAnnealing: CoolRate must be in (0, 1)');
  if MaxIter <= 0 then raise EOptimizationError.Create(
    'SimulatedAnnealing: MaxIter must be > 0');
  N         := Length(X0);
  X         := VecCopy(X0);
  XBest     := VecCopy(X0);
  FX        := EvaluateMultivariate(F, X, 'SimulatedAnnealing');
  Inc(Result.Evaluations);
  FBest     := FX;
  T         := T0;
  RandState := DWord(Seed);
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if T < TMin then
    begin
      Result.Converged := True;
      Break;
    end;

    { Random neighbour }
    XNew := VecCopy(X);
    for I := 0 to N-1 do XNew[I] := X[I] + StepSize * LCGSigned;
    FNew := EvaluateMultivariate(F, XNew, 'SimulatedAnnealing');
    Inc(Result.Evaluations);

    { Accept or reject }
    Delta := FNew - FX;
    if (Delta < 0) or (LCG < Exp(-Delta / T)) then
    begin
      X  := XNew;
      FX := FNew;
      if FX < FBest then
      begin
        FBest  := FX;
        XBest  := VecCopy(X);
      end;
    end;

    T := T * CoolRate;
  end;

  Result.X     := XBest;
  Result.FVal  := FBest;
  Result.BestX:=Copy(XBest);
  Result.BestFVal:=FBest;
  Result.Iters := Iter;
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

{ ---------------------------------------------------------------------------
  PENALTY METHOD
--------------------------------------------------------------------------- }

class function TOptimizationKit.PenaltyMethod(
  F: TMultivarFunc;
  const Constraints: array of TConstraintFunc;
  const X0: TDoubleArray;
  Mu, Tol: Double;
  MaxIter: Integer): TOptResult;
{ Progressive penalty: solve a sequence of unconstrained problems with
  increasing Mu until the constraint violation is small }
var
  Round, I: Integer;
  XCur: TDoubleArray;
  Mu_k, Violation, MaxViolation: Double;
  AllInnerConverged: Boolean;
  TotalIterations,TotalEvaluations:Integer;
  Inner:TOptResult;
begin
  Result:=Default(TOptResult);
  if not Assigned(F) then raise EOptimizationError.Create('PenaltyMethod: objective is nil');
  if Length(X0) = 0 then raise EOptimizationError.Create('PenaltyMethod: X0 must not be empty');
  RequireFiniteVector(X0, 'PenaltyMethod');
  RequirePositiveFinite(Mu, 'PenaltyMethod penalty');
  RequirePositiveFinite(Tol, 'PenaltyMethod tolerance');
  if MaxIter <= 0 then raise EOptimizationError.Create('PenaltyMethod: MaxIter must be > 0');
  for I := 0 to High(Constraints) do
    if not Assigned(Constraints[I]) then
      raise EOptimizationError.CreateFmt('PenaltyMethod: constraint %d is nil', [I]);

  XCur := VecCopy(X0);
  Mu_k := Mu;
  AllInnerConverged := True;
  TotalIterations := 0;
  TotalEvaluations:=0;
  for Round := 1 to 10 do
  begin
    Inner:=NelderMeadCore(F,Constraints,XCur,1.0,Tol/Mu_k,
      MaxIter, Mu_k, False);
    AllInnerConverged:=AllInnerConverged and Inner.Converged;
    Inc(TotalIterations,Inner.Iters);
    Inc(TotalEvaluations,Inner.Evaluations);
    XCur:=Inner.X;
    Result:=Inner;
    Mu_k := Mu_k * 10;
  end;
  Result.FVal := EvaluateMultivariate(F, Result.X, 'PenaltyMethod');
  Inc(TotalEvaluations);
  MaxViolation := 0.0;
  for I := 0 to High(Constraints) do
  begin
    Violation := Constraints[I](Result.X);
    Inc(TotalEvaluations);
    if IsNan(Violation) or IsInfinite(Violation) then
      raise EOptimizationError.Create(
        'PenaltyMethod: constraint returned a non-finite value');
    MaxViolation := Max(MaxViolation, Violation);
  end;
  Result.Converged := AllInnerConverged and (MaxViolation <= Tol);
  Result.Iters := TotalIterations;
  Result.ConstraintViolation := Max(0.0, MaxViolation);
  Result.Evaluations:=TotalEvaluations;
  Result.BestX:=Copy(Result.X);
  Result.BestFVal:=Result.FVal;
  if Result.Converged then Result.Status := isConverged
  else Result.Status := isIterationLimit;
end;

{ ---------------------------------------------------------------------------
  SIMPLEX LP
--------------------------------------------------------------------------- }

class function TOptimizationKit.SimplexLP(
  const C: TDoubleArray;
  const A: array of TDoubleArray;
  const B: TDoubleArray): TLPResult;
var
  M,N,Rows,Cols,I,J,ArtificialCount,ArtificialStart,
    TotalVariables,IterationCount:Integer;
  Tab:array of TDoubleArray;
  Basis: TIntegerArray;
  LPStatus,PhaseStatus:TLPStatus;
  ArtificialSum:Double;
const
  MaxIter = 10000;
  Eps     = 1E-9;

  procedure Pivot(const PivotRow,PivotColumn:Integer);
  var
    Row,Column:Integer;
    Element,Factor:Double;
  begin
    Element:=Tab[PivotRow][PivotColumn];
    for Column:=0 to Cols-1 do
      Tab[PivotRow][Column]:=Tab[PivotRow][Column]/Element;
    for Row:=0 to Rows-1 do
      if Row<>PivotRow then
      begin
        Factor:=Tab[Row][PivotColumn];
        if Factor=0 then Continue;
        for Column:=0 to Cols-1 do
          Tab[Row][Column]:=Tab[Row][Column]-
            Factor*Tab[PivotRow][Column];
      end;
    Basis[PivotRow]:=PivotColumn;
  end;

  function RunPhase(const EligibleColumns:Integer):TLPStatus;
  var
    PivotColumn,PivotRow,Row,Column:Integer;
    Ratio,MinimumRatio:Double;
  begin
    Result:=lpsIterationLimit;
    while IterationCount<MaxIter do
    begin
      PivotColumn:=-1;
      { Bland's rule gives deterministic anti-cycling behavior. }
      for Column:=0 to EligibleColumns-1 do
        if Tab[M][Column]<-Eps then
        begin PivotColumn:=Column; Break; end;
      if PivotColumn<0 then Exit(lpsOptimal);
      PivotRow:=-1; MinimumRatio:=Infinity;
      for Row:=0 to M-1 do
        if Tab[Row][PivotColumn]>Eps then
        begin
          Ratio:=Tab[Row][Cols-1]/Tab[Row][PivotColumn];
          if (Ratio<MinimumRatio-Eps) or
             ((Abs(Ratio-MinimumRatio)<=Eps) and
              ((PivotRow<0) or (Basis[Row]<Basis[PivotRow]))) then
          begin
            MinimumRatio:=Ratio;
            PivotRow:=Row;
          end;
        end;
      if PivotRow<0 then Exit(lpsUnbounded);
      Pivot(PivotRow,PivotColumn);
      Inc(IterationCount);
    end;
  end;

  procedure CanonicalizeObjective;
  var
    Row,Column:Integer;
    BasicCost:Double;
  begin
    for Row:=0 to M-1 do
    begin
      if Basis[Row]<N then BasicCost:=C[Basis[Row]]
      else BasicCost:=0;
      if BasicCost<>0 then
        for Column:=0 to Cols-1 do
          Tab[M][Column]:=Tab[M][Column]-
            BasicCost*Tab[Row][Column];
    end;
  end;

begin
  Result := Default(TLPResult);
  M:=Length(A); N:=Length(C);
  if M = 0 then raise EOptimizationError.Create('SimplexLP: no constraints');
  if N = 0 then raise EOptimizationError.Create('SimplexLP: no variables');
  if Length(B) <> M then raise EOptimizationError.Create(
    'SimplexLP: B length must equal the number of constraint rows');
  RequireFiniteVector(C, 'SimplexLP cost vector');
  RequireFiniteVector(B, 'SimplexLP right-hand side');
  for I := 0 to M - 1 do
  begin
    if Length(A[I]) <> N then raise EOptimizationError.CreateFmt(
      'SimplexLP: row %d has the wrong number of columns', [I]);
    RequireFiniteVector(A[I], 'SimplexLP constraint row');
  end;
  ArtificialCount:=0;
  for I:=0 to M-1 do
    if B[I]<0 then Inc(ArtificialCount);
  ArtificialStart:=N+M;
  TotalVariables:=ArtificialStart+ArtificialCount;
  Rows:=M+1;
  Cols:=TotalVariables+1;
  SetLength(Tab, Rows);
  for I := 0 to Rows-1 do
  begin
    SetLength(Tab[I], Cols);
    FillChar(Tab[I][0], Cols * SizeOf(Double), 0);
  end;
  SetLength(Basis,M);
  ArtificialCount:=0;
  for I := 0 to M-1 do
  begin
    if B[I]>=0 then
    begin
      for J:=0 to N-1 do Tab[I][J]:=A[I][J];
      Tab[I][N+I]:=1;
      Tab[I][Cols-1]:=B[I];
      Basis[I]:=N+I;
    end
    else
    begin
      for J:=0 to N-1 do Tab[I][J]:=-A[I][J];
      Tab[I][N+I]:=-1;
      Tab[I][ArtificialStart+ArtificialCount]:=1;
      Tab[I][Cols-1]:=-B[I];
      Basis[I]:=ArtificialStart+ArtificialCount;
      Inc(ArtificialCount);
    end;
  end;
  IterationCount:=0;
  if ArtificialCount>0 then
  begin
    for J:=ArtificialStart to TotalVariables-1 do Tab[M][J]:=1;
    for I := 0 to M-1 do
      if Basis[I]>=ArtificialStart then
        for J:=0 to Cols-1 do
          Tab[M][J]:=Tab[M][J]-Tab[I][J];
    PhaseStatus:=RunPhase(ArtificialStart);
    if PhaseStatus=lpsIterationLimit then
    begin Result.Status:=lpsIterationLimit; Result.Iters:=IterationCount; Exit; end;
    ArtificialSum:=0;
    for I:=0 to M-1 do
      if Basis[I]>=ArtificialStart then
        ArtificialSum:=ArtificialSum+Max(0,Tab[I][Cols-1]);
    if ArtificialSum>1E-7 then
    begin
      Result.Status:=lpsInfeasible;
      Result.Feasible:=False;
      Result.Iters:=IterationCount;
      Exit;
    end;
    for I:=0 to M-1 do
      if Basis[I]>=ArtificialStart then
      begin
        for J:=0 to ArtificialStart-1 do
          if Abs(Tab[I][J])>Eps then
          begin Pivot(I,J); Break; end;
      end;
  end;
  FillChar(Tab[M][0],Cols*SizeOf(Double),0);
  for J:=0 to N-1 do Tab[M][J]:=C[J];
  CanonicalizeObjective;
  LPStatus:=RunPhase(ArtificialStart);
  SetLength(Result.X, N);
  FillChar(Result.X[0], N * SizeOf(Double), 0);
  for I := 0 to M-1 do
    if Basis[I] < N then
      Result.X[Basis[I]] := Tab[I][Cols-1];

  Result.ObjVal   := 0;
  for J := 0 to N-1 do Result.ObjVal := Result.ObjVal + C[J] * Result.X[J];
  Result.Status   := LPStatus;
  Result.Feasible := LPStatus = lpsOptimal;
  Result.Iters    := IterationCount;
end;

{ ---------------------------------------------------------------------------
  PUBLIC UTILITIES
--------------------------------------------------------------------------- }

class function TOptimizationKit.NumGrad(F: TMultivarFunc; const X: TDoubleArray; H: Double): TDoubleArray;
begin
  Result := NumericalGradient(F, X, H);
end;

class function TOptimizationKit.Maximize(
  F: TMultivarFunc;
  const X0: TDoubleArray;
  Scale, Tol: Double;
  MaxIter: Integer): TOptResult;
begin
  if not Assigned(F) then raise EOptimizationError.Create('Maximize: objective is nil');
  Result := NelderMeadCore(F, [], X0, Scale, Tol, MaxIter, 0.0, True);
  Result.FVal := -Result.FVal;
  Result.BestFVal:=-Result.BestFVal;
end;

end.
