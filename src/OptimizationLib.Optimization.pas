unit OptimizationLib.Optimization;

{-----------------------------------------------------------------------------
 OptimizationLib.Optimization

 Mathematical optimization for Free Pascal.
 Finds minima (or maxima) of functions — no external dependencies.

 What this library gives you
 ---------------------------
 Unconstrained single-variable
   GoldenSection      — bracket minimum of f(x) on [a,b], derivative-free
   BrentMinimize      — Brent's method, parabolic interpolation + golden section

 Unconstrained multi-variable (gradient-based)
   GradientDescent    — vanilla steepest-descent with fixed step
   Adam               — adaptive moment estimation (de-facto ML standard)
   LBFGS              — Limited-memory BFGS quasi-Newton (fast, low memory)

 Unconstrained multi-variable (derivative-free)
   NelderMead         — simplex method, works on noisy/non-smooth objectives
   SimulatedAnnealing — global optimiser, escapes local minima

 Constrained
   PenaltyMethod      — convert a constrained problem to unconstrained via
                        quadratic penalty; works with any unconstrained solver

 Linear Programming
   SimplexLP          — revised Simplex method for standard-form LP:
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

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

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
  end;

  { Result of SimplexLP }
  TLPResult = record
    X:        TDoubleArray;  { primal solution }
    ObjVal:   Double;        { c'x at solution }
    Feasible: Boolean;       { False if problem is infeasible or unbounded }
    Iters:    Integer;
  end;

  { TOptimizationKit — all methods are class static }
  TOptimizationKit = class
  private
    { Internal: numerical gradient via central differences }
    class function NumericalGradient(F: TMultivarFunc;
      const X: TDoubleArray; H: Double = 1E-5): TDoubleArray; static;

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
    class function LineSearch(F: TMultivarFunc; const X, Dir: TDoubleArray;
      FX: Double; Alpha0: Double = 1.0): Double; static;

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
    class function GoldenSection(F: TUnivarFunc; A, B: Double;
      Tol: Double = 1E-8; MaxIter: Integer = 200): Double; static;

    { Brent's method for single-variable minimization.
      Combines golden-section with parabolic interpolation — faster than
      GoldenSection for smooth functions, equally robust.
      Requires [A, B] to bracket a minimum (f has a valley inside).
      Returns the x value at the minimum. }
    class function BrentMinimize(F: TUnivarFunc; A, B: Double;
      Tol: Double = 1E-8; MaxIter: Integer = 200): Double; static;

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
    class function GradientDescent(F: TMultivarFunc; Grad: TGradFunc;
      const X0: TDoubleArray; LR: Double = 0.1;
      Tol: Double = 1E-6; MaxIter: Integer = 5000): TOptResult; static;

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
    class function Adam(F: TMultivarFunc; Grad: TGradFunc;
      const X0: TDoubleArray;
      LR: Double = 0.001; Beta1: Double = 0.9; Beta2: Double = 0.999;
      Eps: Double = 1E-8; Tol: Double = 1E-6;
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
    class function LBFGS(F: TMultivarFunc; Grad: TGradFunc;
      const X0: TDoubleArray; M: Integer = 10;
      Tol: Double = 1E-6; MaxIter: Integer = 1000): TOptResult; static;

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
    class function NelderMead(F: TMultivarFunc; const X0: TDoubleArray;
      Scale: Double = 1.0; Tol: Double = 1E-8;
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
    class function SimulatedAnnealing(F: TMultivarFunc;
      const X0: TDoubleArray;
      T0: Double = 100.0; TMin: Double = 1E-8;
      CoolRate: Double = 0.995; StepSize: Double = 0.1;
      MaxIter: Integer = 100000; Seed: Integer = 42): TOptResult; static;

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

      Tip: start with a feasible X0. If the solution violates constraints
      significantly, increase Mu or MaxIter. }
    class function PenaltyMethod(F: TMultivarFunc;
      const Constraints: array of TConstraintFunc;
      const X0: TDoubleArray;
      Mu: Double = 1.0; Tol: Double = 1E-6;
      MaxIter: Integer = 5000): TOptResult; static;

    { =======================================================================
      LINEAR PROGRAMMING
    ======================================================================= }

    { Revised Simplex method for standard-form LP:
        minimise   c' x
        subject to A x <= b,   x >= 0

      Parameters
        C  — cost vector (length N)
        A  — constraint matrix (M rows × N cols), stored row-major
        B  — right-hand side (length M); all b_i must be >= 0
             (multiply any negative constraint by -1 before calling)

      Result
        TLPResult.Feasible = False  →  infeasible or unbounded
        TLPResult.X        →  optimal primal solution
        TLPResult.ObjVal   →  c' x at optimum

      Converts to equality form internally by adding slack variables,
      then runs the Simplex pivot loop.

      Example — minimise -x1 - x2 subject to x1+x2<=4, x1<=3, x2<=3, x>=0:
        c := [-1,-1];
        A := [[1,1],[1,0],[0,1]];
        b := [4,3,3];
        r := TOptimizationKit.SimplexLP(c, A, b); }
    class function SimplexLP(const C: TDoubleArray;
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
    class function NumGrad(F: TMultivarFunc; const X: TDoubleArray;
      H: Double = 1E-5): TDoubleArray; static;

    { Maximise F by minimising -F.  Wraps any minimizer.
      Example: find the peak of a hill function using NelderMead.
        result := TOptimizationKit.Maximize(f, x0); }
    class function Maximize(F: TMultivarFunc; const X0: TDoubleArray;
      Scale: Double = 1.0; Tol: Double = 1E-8;
      MaxIter: Integer = 10000): TOptResult; static;

  end;

implementation

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TOptimizationKit.NumericalGradient(F: TMultivarFunc;
  const X: TDoubleArray; H: Double): TDoubleArray;
{ Central-difference gradient: (f(x+h*ei) - f(x-h*ei)) / (2h) }
var
  I, N: Integer;
  XFwd, XBwd: TDoubleArray;
begin
  N := Length(X);
  SetLength(Result, N);
  XFwd := VecCopy(X);
  XBwd := VecCopy(X);
  for I := 0 to N-1 do
  begin
    XFwd[I] := X[I] + H;
    XBwd[I] := X[I] - H;
    Result[I] := (F(XFwd) - F(XBwd)) / (2 * H);
    XFwd[I] := X[I];
    XBwd[I] := X[I];
  end;
end;

class function TOptimizationKit.Dot(const A, B: TDoubleArray): Double;
var I: Integer;
begin
  Result := 0;
  for I := 0 to High(A) do Result := Result + A[I] * B[I];
end;

class function TOptimizationKit.VecAdd(const A, B: TDoubleArray;
  Scale: Double): TDoubleArray;
var I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I] + Scale * B[I];
end;

class function TOptimizationKit.VecScale(const A: TDoubleArray;
  S: Double): TDoubleArray;
var I: Integer;
begin
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
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := A[I];
end;

class function TOptimizationKit.LineSearch(F: TMultivarFunc;
  const X, Dir: TDoubleArray; FX: Double; Alpha0: Double): Double;
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
  GradDot := Dot(NumericalGradient(F, X), Dir);
  for I := 0 to 50 do
  begin
    XNew := VecAdd(X, Dir, Alpha);
    if F(XNew) <= FX + C1 * Alpha * GradDot then
      Break;
    Alpha := Alpha * Rho;
  end;
  Result := Alpha;
end;

{ ---------------------------------------------------------------------------
  GOLDEN SECTION
--------------------------------------------------------------------------- }

class function TOptimizationKit.GoldenSection(F: TUnivarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): Double;
{ Reduces the interval by the golden ratio φ = (√5-1)/2 ≈ 0.618 each step }
const
  Phi = 0.6180339887498949;  { (√5-1)/2 }
var
  C, D, FC, FD: Double;
  Iter: Integer;
begin
  if B <= A then raise EOptimizationError.Create('GoldenSection: B must be > A');
  C  := B - Phi * (B - A);
  D  := A + Phi * (B - A);
  FC := F(C);
  FD := F(D);
  for Iter := 1 to MaxIter do
  begin
    if (B - A) < Tol then Break;
    if FC < FD then
    begin
      B  := D;
      D  := C;  FD := FC;
      C  := B - Phi * (B - A);
      FC := F(C);
    end
    else
    begin
      A  := C;
      C  := D;  FC := FD;
      D  := A + Phi * (B - A);
      FD := F(D);
    end;
  end;
  Result := (A + B) / 2;
end;

{ ---------------------------------------------------------------------------
  BRENT MINIMIZE
--------------------------------------------------------------------------- }

class function TOptimizationKit.BrentMinimize(F: TUnivarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): Double;
{ Brent (1973) — combines golden section with inverse parabolic interpolation }
const
  CGold = 0.3819660112501051;  { 1 - (√5-1)/2 }
  ZEps  = 1E-10;
var
  V, W, X, U, FU, FV, FW, FX: Double;
  E, D, P, Q, R, Tol1, Tol2, XM: Double;
  Iter: Integer;
begin
  if B <= A then raise EOptimizationError.Create('BrentMinimize: B must be > A');
  V  := A + CGold * (B - A);
  W  := V;  X  := V;
  FV := F(V); FW := FV; FX := FV;
  E  := 0;  D  := 0;

  for Iter := 1 to MaxIter do
  begin
    XM   := 0.5 * (A + B);
    Tol1 := Tol * Abs(X) + ZEps;
    Tol2 := 2 * Tol1;
    if Abs(X - XM) <= Tol2 - 0.5*(B-A) then Break;

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
    FU := F(U);

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
  Result := X;
end;

{ ---------------------------------------------------------------------------
  GRADIENT DESCENT
--------------------------------------------------------------------------- }

class function TOptimizationKit.GradientDescent(F: TMultivarFunc;
  Grad: TGradFunc; const X0: TDoubleArray; LR: Double; Tol: Double;
  MaxIter: Integer): TOptResult;
var
  X, G, Dir: TDoubleArray;
  FX, Alpha: Double;
  Iter: Integer;
begin
  if Length(X0) = 0 then
    raise EOptimizationError.Create('GradientDescent: X0 must not be empty');
  X   := VecCopy(X0);
  FX  := F(X);
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if Assigned(Grad) then G := Grad(X)
    else G := NumericalGradient(F, X);

    if VecNorm(G) < Tol then
    begin
      Result.Converged := True;
      Break;
    end;

    { Descent direction = -gradient }
    Dir   := VecScale(G, -1);
    Alpha := LineSearch(F, X, Dir, FX, LR);
    X     := VecAdd(X, Dir, Alpha);
    FX    := F(X);
  end;

  Result.X     := X;
  Result.FVal  := FX;
  Result.Iters := Iter;
end;

{ ---------------------------------------------------------------------------
  ADAM
--------------------------------------------------------------------------- }

class function TOptimizationKit.Adam(F: TMultivarFunc; Grad: TGradFunc;
  const X0: TDoubleArray; LR, Beta1, Beta2, Eps, Tol: Double;
  MaxIter: Integer): TOptResult;
var
  X, G, M, V: TDoubleArray;
  FX, MHat, VHat, B1t, B2t: Double;
  I, Iter, N: Integer;
begin
  if Length(X0) = 0 then
    raise EOptimizationError.Create('Adam: X0 must not be empty');
  N   := Length(X0);
  X   := VecCopy(X0);
  SetLength(M, N);  { 1st moment (mean) }
  SetLength(V, N);  { 2nd moment (uncentred variance) }
  FillChar(M[0], N * SizeOf(Double), 0);
  FillChar(V[0], N * SizeOf(Double), 0);
  B1t := 1;  B2t := 1;
  FX  := F(X);
  Result.Converged := False;

  for Iter := 1 to MaxIter do
  begin
    if Assigned(Grad) then G := Grad(X)
    else G := NumericalGradient(F, X);

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
    FX := F(X);
  end;

  Result.X     := X;
  Result.FVal  := FX;
  Result.Iters := Iter;
end;

{ ---------------------------------------------------------------------------
  L-BFGS
--------------------------------------------------------------------------- }

class function TOptimizationKit.LBFGS(F: TMultivarFunc; Grad: TGradFunc;
  const X0: TDoubleArray; M: Integer; Tol: Double;
  MaxIter: Integer): TOptResult;
{ Two-loop recursion L-BFGS (Nocedal 1980).
  Stores the last M (s_k, y_k) pairs where s_k = x_{k+1}-x_k, y_k = g_{k+1}-g_k }
var
  N, Iter, K, I, J, Bound: Integer;
  X, G, GNew, Q, R, S, Y, Alpha_arr, Rho_arr: TDoubleArray;
  SBuf, YBuf: array of TDoubleArray;
  RhoBuf: TDoubleArray;
  FX, Alpha, Beta, GammaScale, Sy, Yy, SStep: Double;
begin
  if Length(X0) = 0 then
    raise EOptimizationError.Create('LBFGS: X0 must not be empty');
  N  := Length(X0);
  X  := VecCopy(X0);
  FX := F(X);
  if Assigned(Grad) then G := Grad(X)
  else G := NumericalGradient(F, X);

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
    Alpha := LineSearch(F, X, S, FX);

    { Update X }
    S    := VecScale(S, Alpha);   { s_k = step taken }
    X    := VecAdd(X, S, 1);
    FX   := F(X);

    { Compute new gradient }
    if Assigned(Grad) then GNew := Grad(X)
    else GNew := NumericalGradient(F, X);

    { Store (s_k, y_k) in circular buffer }
    Y      := VecAdd(GNew, G, -1);  { y_k = g_{k+1} - g_k }
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
end;

{ ---------------------------------------------------------------------------
  NELDER-MEAD
--------------------------------------------------------------------------- }

class function TOptimizationKit.NelderMead(F: TMultivarFunc;
  const X0: TDoubleArray; Scale, Tol: Double; MaxIter: Integer): TOptResult;
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
  N   := Length(X0);
  NP1 := N + 1;
  if N = 0 then raise EOptimizationError.Create('NelderMead: X0 must not be empty');

  { Build initial simplex: vertex 0 = X0, vertex i = X0 + Scale*e_i }
  SetLength(Simplex, NP1);
  SetLength(FVals, NP1);
  for I := 0 to NP1-1 do
  begin
    Simplex[I] := VecCopy(X0);
    if I > 0 then Simplex[I][I-1] := Simplex[I][I-1] + Scale;
    FVals[I] := F(Simplex[I]);
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
    FR := F(XR);

    if (FR < FVals[Best]) then
    begin
      { Expansion }
      XE := VecAdd(Centroid, VecAdd(XR, Centroid, -1), Gamma);
      FE := F(XE);
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
      FC := F(XC);
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
            FVals[I] := F(Simplex[I]);
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
  Result.Iters := Iter;
end;

{ ---------------------------------------------------------------------------
  SIMULATED ANNEALING
--------------------------------------------------------------------------- }

class function TOptimizationKit.SimulatedAnnealing(F: TMultivarFunc;
  const X0: TDoubleArray; T0, TMin, CoolRate, StepSize: Double;
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
    RandState := RandState * 1664525 + 1013904223;
    Result    := (RandState and $7FFFFFFF) / $7FFFFFFF;
  end;

  function LCGSigned: Double;
  begin
    Result := LCG * 2 - 1;  { uniform in (-1, +1) }
  end;

begin
  if Length(X0) = 0 then
    raise EOptimizationError.Create('SimulatedAnnealing: X0 must not be empty');
  N         := Length(X0);
  X         := VecCopy(X0);
  XBest     := VecCopy(X0);
  FX        := F(X);
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
    FNew := F(XNew);

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
  Result.Iters := Iter;
end;

{ ---------------------------------------------------------------------------
  PENALTY METHOD
--------------------------------------------------------------------------- }

class function TOptimizationKit.PenaltyMethod(F: TMultivarFunc;
  const Constraints: array of TConstraintFunc;
  const X0: TDoubleArray; Mu, Tol: Double; MaxIter: Integer): TOptResult;
{ Progressive penalty: solve a sequence of unconstrained problems with
  increasing Mu until the constraint violation is small }
var
  Round, NC, I: Integer;
  XCur: TDoubleArray;
  Mu_k: Double;
  NC_: Integer;
  Constrs: array of TConstraintFunc;

  { Build penalised objective for current Mu }
  function MakePenalised(const X_: TDoubleArray): Double;
  var J: Integer; Viol: Double;
  begin
    Result := F(X_);
    for J := 0 to High(Constrs) do
    begin
      Viol := Constrs[J](X_);
      if Viol > 0 then Result := Result + Mu_k * Viol * Viol;
    end;
  end;

begin
  NC   := Length(Constraints);
  SetLength(Constrs, NC);
  for I := 0 to NC-1 do Constrs[I] := Constraints[I];

  XCur := VecCopy(X0);
  Mu_k := Mu;

  for Round := 1 to 10 do  { outer penalty loop }
  begin
    Result := NelderMead(@MakePenalised, XCur, 1.0, Tol / Mu_k, MaxIter);
    XCur   := Result.X;
    Mu_k   := Mu_k * 10;   { increase penalty each round }
  end;
  { Recompute true objective at solution }
  Result.FVal := F(Result.X);
end;

{ ---------------------------------------------------------------------------
  SIMPLEX LP
--------------------------------------------------------------------------- }

class function TOptimizationKit.SimplexLP(const C: TDoubleArray;
  const A: array of TDoubleArray; const B: TDoubleArray): TLPResult;
{ Standard Simplex in tableau form.
  Adds slack variables to convert Ax <= b into Ax + Is = b (s >= 0).
  Tableau: M+1 rows × (N+M+1) cols — last row = reduced costs. }
var
  M, N, Rows, Cols, I, J, PivCol, PivRow, BVar: Integer;
  Tab: array of TDoubleArray;  { tableau }
  Basis: TIntegerArray;
  MinVal, Ratio, MinRatio, PivElem: Double;
  Iter: Integer;
  Feasible: Boolean;
const
  MaxIter = 10000;
  Eps     = 1E-9;
begin
  M    := Length(A);
  N    := Length(C);
  Rows := M + 1;
  Cols := N + M + 1;  { N original + M slack + 1 RHS }

  if M = 0 then raise EOptimizationError.Create('SimplexLP: no constraints');
  if N = 0 then raise EOptimizationError.Create('SimplexLP: no variables');

  { Build tableau }
  SetLength(Tab, Rows);
  for I := 0 to Rows-1 do
  begin
    SetLength(Tab[I], Cols);
    FillChar(Tab[I][0], Cols * SizeOf(Double), 0);
  end;

  { Constraint rows: [A | I | b] }
  for I := 0 to M-1 do
  begin
    for J := 0 to N-1 do Tab[I][J] := A[I][J];
    Tab[I][N + I] := 1;          { slack }
    Tab[I][Cols-1] := B[I];
    if B[I] < 0 then
    begin
      Result.Feasible := False;
      Result.ObjVal   := 0;
      Exit;
    end;
  end;

  { Objective row: [-C | 0 | 0] (we minimise, so negate for tableau max form) }
  for J := 0 to N-1 do Tab[M][J] := -C[J];

  { Initial basis: slack variables N, N+1, ..., N+M-1 }
  SetLength(Basis, M);
  for I := 0 to M-1 do Basis[I] := N + I;

  Feasible := True;
  for Iter := 1 to MaxIter do
  begin
    { Find pivot column: most negative reduced cost }
    PivCol  := -1;
    MinVal  := -Eps;
    for J := 0 to Cols-2 do
      if Tab[M][J] < MinVal then begin MinVal := Tab[M][J]; PivCol := J; end;
    if PivCol = -1 then Break;  { optimal }

    { Find pivot row: minimum ratio test }
    PivRow   := -1;
    MinRatio := MaxDouble;
    for I := 0 to M-1 do
      if Tab[I][PivCol] > Eps then
      begin
        Ratio := Tab[I][Cols-1] / Tab[I][PivCol];
        if Ratio < MinRatio then begin MinRatio := Ratio; PivRow := I; end;
      end;
    if PivRow = -1 then begin Feasible := False; Break; end;  { unbounded }

    { Pivot }
    PivElem := Tab[PivRow][PivCol];
    for J := 0 to Cols-1 do Tab[PivRow][J] := Tab[PivRow][J] / PivElem;
    for I := 0 to Rows-1 do
      if I <> PivRow then
      begin
        PivElem := Tab[I][PivCol];
        for J := 0 to Cols-1 do
          Tab[I][J] := Tab[I][J] - PivElem * Tab[PivRow][J];
      end;

    Basis[PivRow] := PivCol;
  end;

  { Extract solution }
  SetLength(Result.X, N);
  FillChar(Result.X[0], N * SizeOf(Double), 0);
  for I := 0 to M-1 do
    if Basis[I] < N then
      Result.X[Basis[I]] := Tab[I][Cols-1];

  Result.ObjVal   := 0;
  for J := 0 to N-1 do Result.ObjVal := Result.ObjVal + C[J] * Result.X[J];
  Result.Feasible := Feasible;
  Result.Iters    := Iter;
end;

{ ---------------------------------------------------------------------------
  PUBLIC UTILITIES
--------------------------------------------------------------------------- }

class function TOptimizationKit.NumGrad(F: TMultivarFunc;
  const X: TDoubleArray; H: Double): TDoubleArray;
begin
  Result := NumericalGradient(F, X, H);
end;

class function TOptimizationKit.Maximize(F: TMultivarFunc;
  const X0: TDoubleArray; Scale, Tol: Double; MaxIter: Integer): TOptResult;
{ Minimise -F }
  function NegF(const X: TDoubleArray): Double;
  begin Result := -F(X); end;
begin
  Result      := NelderMead(@NegF, X0, Scale, Tol, MaxIter);
  Result.FVal := -Result.FVal;  { convert back to original scale }
end;

end.
