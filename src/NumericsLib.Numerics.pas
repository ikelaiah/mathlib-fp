unit NumericsLib.Numerics;

{-----------------------------------------------------------------------------
 NumericsLib.Numerics

 Numerical methods domain unit — no external dependencies beyond MathBase.

 Provides:
   Root Finding
     Bisection        — bracketed, guaranteed convergence
     NewtonRaphson    — fast near root with derivative
     Brent            — hybrid bracket/secant, robust default
     Secant           — derivative-free quasi-Newton

   Numerical Integration (quadrature)
     TrapezoidalRule  — composite rule with O(h^2) global error
     SimpsonRule      — composite rule with O(h^4) global error (n even)
     GaussLegendre5   — 5-point Gauss-Legendre on [a,b]

   ODE Solvers (initial-value problems)
     EulerStep / EulerSolve        — 1st-order explicit Euler
     RK4Step   / RK4Solve          — 4th-order Runge-Kutta (classic)

   Interpolation
     LinearInterp     — piecewise linear between sorted knots
     LagrangeInterp   — global Lagrange polynomial (small n)
     CubicSplineBuild / CubicSplineEval — natural cubic spline
                         (zero second derivatives at both ends)

 All functions are class-static (no instantiation required):
   result := TNumericsKit.Bisection(f, a, b);
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

type
  ENumericsError = class(Exception);
  ENumericsConvergenceError = class(EInvalidArgument);

  { Function pointer types }
  TScalarFunc  = function(X: Double): Double;           // f(x)
  TODEFunc     = function(T, Y: Double): Double;        // dy/dt = f(t,y)

  { Result record for ODE solvers }
  TODESolution = record
    T: TDoubleArray;   // time/independent variable values
    Y: TDoubleArray;   // solution values
  end;

  { Detailed root-finder outcome. The existing scalar-returning entry points
    raise ENumericsConvergenceError when Converged is False. }
  TRootResult = record
    Root: Double;
    Residual: Double;
    Iterations: Integer;
    Converged: Boolean;
  end;

  { Result record for cubic spline (internal coefficients) }
  TCubicSpline = record
    X:  TDoubleArray;  // knot x-values (must be sorted ascending)
    A:  TDoubleArray;  // constant term  (= y_i)
    B:  TDoubleArray;  // linear term
    C:  TDoubleArray;  // quadratic term
    D:  TDoubleArray;  // cubic term
  end;

  { TNumericsKit — all methods are class-static }
  TNumericsKit = class
  public
    { -----------------------------------------------------------------------
      Root Finding
    ----------------------------------------------------------------------- }

    { Bisection method: find root of f in [A, B] where the endpoint values
      have opposite signs. Endpoint roots are returned immediately.
      MaxIter: maximum iterations (default 100).
      Tol: absolute tolerance on the interval width (default 1e-10).
      Raises EInvalidArgument for invalid controls or a bad bracket, and
      ENumericsConvergenceError if MaxIter is exhausted. }
    class function Bisection(F: TScalarFunc; A, B: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;
    class function BisectionResult(F: TScalarFunc; A, B: Double;
      Tol: Double = 1E-10; MaxIter: Integer = 100): TRootResult; static;

    { Newton-Raphson: find root starting from X0 using f and df/dx.
      Tol: tolerance on |f(x)| (default 1e-10).
      MaxIter: max iterations (default 100). }
    class function NewtonRaphson(
      F, DF: TScalarFunc;
      X0: Double;
      Tol: Double = 1E-10;
      MaxIter: Integer = 100): Double; static;
    class function NewtonRaphsonResult(
      F, DF: TScalarFunc; X0: Double; Tol: Double = 1E-10;
      MaxIter: Integer = 100): TRootResult; static;

    { Brent's method: robust bracketed root-finding combining bisection,
      secant, and inverse-quadratic interpolation.
      Requires f(A)*f(B) <= 0. }
    class function Brent(F: TScalarFunc; A, B: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;
    class function BrentResult(F: TScalarFunc; A, B: Double;
      Tol: Double = 1E-10; MaxIter: Integer = 100): TRootResult; static;

    { Secant method: derivative-free, requires two initial guesses X0, X1.
      Tol: tolerance on |f(x)| (default 1e-10).
      MaxIter: max iterations (default 100). }
    class function Secant(F: TScalarFunc; X0, X1: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;
    class function SecantResult(F: TScalarFunc; X0, X1: Double;
      Tol: Double = 1E-10; MaxIter: Integer = 100): TRootResult; static;

    { -----------------------------------------------------------------------
      Numerical Integration
    ----------------------------------------------------------------------- }

    { Composite trapezoidal rule on [A,B] with N sub-intervals. }
    class function TrapezoidalRule(F: TScalarFunc; A, B: Double; N: Integer = 1000): Double; static;

    { Composite Simpson's rule on [A,B] with N sub-intervals (N must be even;
      if odd, N is automatically incremented). }
    class function SimpsonRule(F: TScalarFunc; A, B: Double; N: Integer = 1000): Double; static;

    { 5-point Gauss-Legendre quadrature on [A,B]. Very accurate for smooth
      functions; exact for polynomials up to degree 9. }
    class function GaussLegendre5(F: TScalarFunc; A, B: Double): Double; static;

    { -----------------------------------------------------------------------
      ODE Solvers — dy/dt = F(t, y),  y(T0) = Y0
    ----------------------------------------------------------------------- }

    { Single Euler step: returns y(T0+H). }
    class function EulerStep(F: TODEFunc; T0, Y0, H: Double): Double; static;

    { Euler solver over [T0, T1] with N steps.
      Returns TODESolution with T and Y arrays of length N+1. }
    class function EulerSolve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution; static;

    { Single RK4 step: returns y(T0+H). }
    class function RK4Step(F: TODEFunc; T0, Y0, H: Double): Double; static;

    { RK4 solver over [T0, T1] with N steps.
      Returns TODESolution with T and Y arrays of length N+1. }
    class function RK4Solve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution; static;

    { -----------------------------------------------------------------------
      Interpolation
    ----------------------------------------------------------------------- }

    { Piecewise linear interpolation.
      XKnots/YKnots must be the same length, XKnots sorted ascending.
      Clamps to endpoint values outside the range. }
    class function LinearInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double; static;

    { Global Lagrange polynomial interpolation through all N knots.
      XKnots/YKnots must be the same length.
      Warning: ill-conditioned for N > ~10; prefer spline for larger sets. }
    class function LagrangeInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double; static;

    { Build a natural cubic spline through the given knots (XKnots sorted asc).
      Returns a TCubicSpline that can be evaluated with CubicSplineEval. }
    class function CubicSplineBuild(const XKnots, YKnots: TDoubleArray): TCubicSpline; static;

    { Evaluate a previously built TCubicSpline at point X.
      Clamps to endpoint values outside the knot range. }
    class function CubicSplineEval(const S: TCubicSpline; X: Double): Double; static;
  end;

implementation

{ =========================================================================
  Root Finding
  ========================================================================= }

procedure ValidateRootControls(const MethodName: String; F: TScalarFunc;
  const Tol: Double; const MaxIter: Integer);
begin
  if not Assigned(F) then
    raise EInvalidArgument.Create(MethodName + ': function callback is nil.');
  if (Tol <= 0) or IsNan(Tol) or IsInfinite(Tol) then
    raise EInvalidArgument.Create(MethodName + ': Tol must be finite and positive.');
  if MaxIter <= 0 then
    raise EInvalidArgument.Create(MethodName + ': MaxIter must be positive.');
end;

function EvaluateFinite(const MethodName: String; F: TScalarFunc;
  const X: Double): Double;
begin
  Result := F(X);
  if IsNan(Result) or IsInfinite(Result) then
    raise ENumericsError.Create(MethodName + ': callback returned a non-finite value.');
end;

function SameNonZeroSign(const A, B: Double): Boolean; inline;
begin
  Result := ((A > 0) and (B > 0)) or ((A < 0) and (B < 0));
end;

procedure ValidateFiniteArray(const Values: TDoubleArray; const Name: String);
var
  I: Integer;
begin
  for I := 0 to High(Values) do
    if IsNan(Values[I]) or IsInfinite(Values[I]) then
      raise EInvalidArgument.CreateFmt('%s contains a non-finite value at index %d.',
        [Name, I]);
end;

function EvaluateFiniteODE(F: TODEFunc; const T, Y: Double;
  const MethodName: String): Double;
begin
  Result := F(T, Y);
  if IsNan(Result) or IsInfinite(Result) then
    raise ENumericsError.Create(MethodName + ': derivative returned a non-finite value.');
end;

procedure ValidateFiniteInterval(F: TScalarFunc; const A, B: Double;
  const MethodName: String);
begin
  if not Assigned(F) then
    raise EInvalidArgument.Create(MethodName + ': function callback must be assigned.');
  if IsNan(A) or IsInfinite(A) or IsNan(B) or IsInfinite(B) then
    raise EInvalidArgument.Create(MethodName + ': interval endpoints must be finite.');
end;

procedure ValidateKnots(const XKnots, YKnots: TDoubleArray;
  const MethodName: String; const RequireIncreasing: Boolean);
var
  I, J: Integer;
begin
  ValidateFiniteArray(XKnots, MethodName + ' XKnots');
  ValidateFiniteArray(YKnots, MethodName + ' YKnots');
  if RequireIncreasing then
  begin
    for I := 1 to High(XKnots) do
      if XKnots[I] <= XKnots[I - 1] then
        raise EInvalidArgument.Create(MethodName +
          ': XKnots must be strictly increasing.');
  end
  else
    for I := 0 to High(XKnots) - 1 do
      for J := I + 1 to High(XKnots) do
        if XKnots[I] = XKnots[J] then
          raise EInvalidArgument.Create(MethodName +
            ': XKnots must be distinct.');
end;

class function TNumericsKit.BisectionResult(F: TScalarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): TRootResult;
var
  FA, FB, FMid, Mid: Double;
  Iter: Integer;
begin
  Result := Default(TRootResult);
  ValidateRootControls('Bisection', F, Tol, MaxIter);
  if IsNan(A) or IsInfinite(A) or IsNan(B) or IsInfinite(B) or (A >= B) then
    raise EInvalidArgument.Create('Bisection: require finite A < B.');

  FA := EvaluateFinite('Bisection', F, A);
  FB := EvaluateFinite('Bisection', F, B);
  if Abs(FA) <= Tol then
  begin
    Result.Root := A; Result.Residual := Abs(FA); Result.Converged := True;
    Exit;
  end;
  if Abs(FB) <= Tol then
  begin
    Result.Root := B; Result.Residual := Abs(FB); Result.Converged := True;
    Exit;
  end;
  if SameNonZeroSign(FA, FB) then
    raise EInvalidArgument.Create(
      'Bisection: f(A) and f(B) must have opposite signs.');

  for Iter := 1 to MaxIter do
  begin
    Mid  := A + (B - A) / 2;
    FMid := EvaluateFinite('Bisection', F, Mid);
    Result.Root := Mid;
    Result.Residual := Abs(FMid);
    Result.Iterations := Iter;
    if (Result.Residual <= Tol) or (Abs(B - A) / 2 <= Tol) then
    begin
      Result.Converged := True;
      Exit;
    end;
    if not SameNonZeroSign(FA, FMid) then
    begin
      B  := Mid;
      FB := FMid;
    end
    else
    begin
      A  := Mid;
      FA := FMid;
    end;
  end;
  Result.Root := A + (B - A) / 2;
  Result.Residual := Abs(EvaluateFinite('Bisection', F, Result.Root));
end;

class function TNumericsKit.Bisection(F: TScalarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): Double;
var
  Outcome: TRootResult;
begin
  Outcome := BisectionResult(F, A, B, Tol, MaxIter);
  if not Outcome.Converged then
    raise ENumericsConvergenceError.CreateFmt(
      'Bisection did not converge after %d iterations (residual %.6g).',
      [Outcome.Iterations, Outcome.Residual]);
  Result := Outcome.Root;
end;

class function TNumericsKit.NewtonRaphsonResult(F, DF: TScalarFunc;
  X0: Double; Tol: Double; MaxIter: Integer): TRootResult;
var
  X, FX, DFX: Double;
  Iter: Integer;
begin
  Result := Default(TRootResult);
  ValidateRootControls('NewtonRaphson', F, Tol, MaxIter);
  if not Assigned(DF) then
    raise EInvalidArgument.Create('NewtonRaphson: derivative callback is nil.');
  if IsNan(X0) or IsInfinite(X0) then
    raise EInvalidArgument.Create('NewtonRaphson: X0 must be finite.');
  X := X0;
  for Iter := 1 to MaxIter do
  begin
    FX := EvaluateFinite('NewtonRaphson', F, X);
    Result.Root := X;
    Result.Residual := Abs(FX);
    Result.Iterations := Iter;
    if Result.Residual <= Tol then
    begin
      Result.Converged := True;
      Exit;
    end;
    DFX := EvaluateFinite('NewtonRaphson derivative', DF, X);
    if Abs(DFX) < 1E-300 then
      raise EInvalidArgument.Create('NewtonRaphson: derivative too small (near-zero).');
    X := X - FX / DFX;
    if IsNan(X) or IsInfinite(X) then
      raise ENumericsError.Create('NewtonRaphson: iteration became non-finite.');
  end;
  Result.Root := X;
  Result.Residual := Abs(EvaluateFinite('NewtonRaphson', F, X));
end;

class function TNumericsKit.NewtonRaphson(F, DF: TScalarFunc; X0: Double;
  Tol: Double; MaxIter: Integer): Double;
var
  Outcome: TRootResult;
begin
  Outcome := NewtonRaphsonResult(F, DF, X0, Tol, MaxIter);
  if not Outcome.Converged then
    raise ENumericsConvergenceError.CreateFmt(
      'NewtonRaphson did not converge after %d iterations (residual %.6g).',
      [Outcome.Iterations, Outcome.Residual]);
  Result := Outcome.Root;
end;

class function TNumericsKit.BrentResult(F: TScalarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): TRootResult;
var
  FA, FB, FC, FS, C, D, S: Double;
  Tmp: Double;
  Iter: Integer;
  MFlag: Boolean;
begin
  Result := Default(TRootResult);
  ValidateRootControls('Brent', F, Tol, MaxIter);
  if IsNan(A) or IsInfinite(A) or IsNan(B) or IsInfinite(B) or (A >= B) then
    raise EInvalidArgument.Create('Brent: require finite A < B.');
  FA := EvaluateFinite('Brent', F, A);
  FB := EvaluateFinite('Brent', F, B);
  if Abs(FA) <= Tol then
  begin
    Result.Root := A; Result.Residual := Abs(FA); Result.Converged := True;
    Exit;
  end;
  if Abs(FB) <= Tol then
  begin
    Result.Root := B; Result.Residual := Abs(FB); Result.Converged := True;
    Exit;
  end;
  if SameNonZeroSign(FA, FB) then
    raise EInvalidArgument.Create(
      'Brent: f(A) and f(B) must have opposite signs.');

  if Abs(FA) < Abs(FB) then
  begin
    Tmp := A; A := B; B := Tmp;
    Tmp := FA; FA := FB; FB := Tmp;
  end;

  C     := A;
  FC    := FA;
  MFlag := True;
  D     := 0;

  for Iter := 1 to MaxIter do
  begin
    Result.Root := B;
    Result.Residual := Abs(FB);
    Result.Iterations := Iter;
    if (Result.Residual <= Tol) or (Abs(B - A) <= Tol) then
    begin
      Result.Converged := True;
      Exit;
    end;

    if (FA <> FC) and (FB <> FC) then
    begin
      { Inverse quadratic interpolation }
      S := A * FB * FC / ((FA - FB) * (FA - FC))
         + B * FA * FC / ((FB - FA) * (FB - FC))
         + C * FA * FB / ((FC - FA) * (FC - FB));
    end
    else
    begin
      { Secant }
      S := B - FB * (B - A) / (FB - FA);
    end;

    { Conditions to fall back to bisection }
    if not (
         ((S > (3 * A + B) / 4) and (S < B)) or
         ((S < (3 * A + B) / 4) and (S > B))
       ) or
       (MFlag  and (Abs(S - B) >= Abs(B - C) / 2)) or
       (not MFlag and (Abs(S - B) >= Abs(C - D) / 2)) or
       (MFlag  and (Abs(B - C) < Tol)) or
       (not MFlag and (Abs(C - D) < Tol))
    then
    begin
      S     := (A + B) / 2;
      MFlag := True;
    end
    else
      MFlag := False;

    D  := C;
    C  := B;
    FC := FB;
    FS := EvaluateFinite('Brent', F, S);

    if not SameNonZeroSign(FA, FS) then
    begin
      B  := S;
      FB := FS;
    end
    else
    begin
      A  := S;
      FA := FS;
    end;

    if Abs(FA) < Abs(FB) then
    begin
      Tmp := A; A := B; B := Tmp;
      Tmp := FA; FA := FB; FB := Tmp;
    end;

  end;
  Result.Root := B;
  Result.Residual := Abs(FB);
end;

class function TNumericsKit.Brent(F: TScalarFunc; A, B: Double;
  Tol: Double; MaxIter: Integer): Double;
var
  Outcome: TRootResult;
begin
  Outcome := BrentResult(F, A, B, Tol, MaxIter);
  if not Outcome.Converged then
    raise ENumericsConvergenceError.CreateFmt(
      'Brent did not converge after %d iterations (residual %.6g).',
      [Outcome.Iterations, Outcome.Residual]);
  Result := Outcome.Root;
end;

class function TNumericsKit.SecantResult(F: TScalarFunc; X0, X1: Double;
  Tol: Double; MaxIter: Integer): TRootResult;
var
  F0, F1, X2: Double;
  Iter: Integer;
begin
  Result := Default(TRootResult);
  ValidateRootControls('Secant', F, Tol, MaxIter);
  if IsNan(X0) or IsInfinite(X0) or IsNan(X1) or IsInfinite(X1) or (X0 = X1) then
    raise EInvalidArgument.Create('Secant: require distinct finite initial guesses.');
  F0 := EvaluateFinite('Secant', F, X0);
  F1 := EvaluateFinite('Secant', F, X1);
  for Iter := 1 to MaxIter do
  begin
    Result.Root := X1;
    Result.Residual := Abs(F1);
    Result.Iterations := Iter;
    if Result.Residual <= Tol then
    begin
      Result.Converged := True;
      Exit;
    end;
    if Abs(F1 - F0) < 1E-300 then
      raise EInvalidArgument.Create('Secant: division by near-zero (f(x1) ≈ f(x0)).');
    X2 := X1 - F1 * (X1 - X0) / (F1 - F0);
    if IsNan(X2) or IsInfinite(X2) then
      raise ENumericsError.Create('Secant: iteration became non-finite.');
    X0 := X1; F0 := F1;
    X1 := X2; F1 := EvaluateFinite('Secant', F, X1);
  end;
  Result.Root := X1;
  Result.Residual := Abs(F1);
end;

class function TNumericsKit.Secant(F: TScalarFunc; X0, X1: Double;
  Tol: Double; MaxIter: Integer): Double;
var
  Outcome: TRootResult;
begin
  Outcome := SecantResult(F, X0, X1, Tol, MaxIter);
  if not Outcome.Converged then
    raise ENumericsConvergenceError.CreateFmt(
      'Secant did not converge after %d iterations (residual %.6g).',
      [Outcome.Iterations, Outcome.Residual]);
  Result := Outcome.Root;
end;

{ =========================================================================
  Numerical Integration
  ========================================================================= }

class function TNumericsKit.TrapezoidalRule(F: TScalarFunc; A, B: Double; N: Integer): Double;
var
  H, Sum: Double;
  I: Integer;
begin
  ValidateFiniteInterval(F, A, B, 'TrapezoidalRule');
  if N < 1 then
    raise EInvalidArgument.Create('TrapezoidalRule: N must be >= 1.');
  H   := (B - A) / N;
  Sum := (EvaluateFinite('TrapezoidalRule', F, A) +
    EvaluateFinite('TrapezoidalRule', F, B)) / 2;
  for I := 1 to N - 1 do
    Sum := Sum + EvaluateFinite('TrapezoidalRule', F, A + I * H);
  Result := H * Sum;
end;

class function TNumericsKit.SimpsonRule(F: TScalarFunc; A, B: Double; N: Integer): Double;
var
  H, Sum: Double;
  I: Integer;
begin
  ValidateFiniteInterval(F, A, B, 'SimpsonRule');
  if N < 2 then
    raise EInvalidArgument.Create('SimpsonRule: N must be >= 2.');
  if Odd(N) then Inc(N);  { must be even }
  H   := (B - A) / N;
  Sum := EvaluateFinite('SimpsonRule', F, A) +
    EvaluateFinite('SimpsonRule', F, B);
  for I := 1 to N - 1 do
  begin
    if Odd(I) then
      Sum := Sum + 4 * EvaluateFinite('SimpsonRule', F, A + I * H)
    else
      Sum := Sum + 2 * EvaluateFinite('SimpsonRule', F, A + I * H);
  end;
  Result := H * Sum / 3;
end;

class function TNumericsKit.GaussLegendre5(F: TScalarFunc; A, B: Double): Double;
{ Nodes and weights for 5-point Gauss-Legendre on [-1,1] }
const
  X1 =  0.90617984593866399280;
  X2 =  0.53846931010568309104;
  X3 =  0.0;
  W1 =  0.23692688505618908751;
  W2 =  0.47862867049936646804;
  W3 =  0.56888888888888888889;
var
  Mid, HalfLen: Double;
begin
  ValidateFiniteInterval(F, A, B, 'GaussLegendre5');
  Mid     := (A + B) / 2;
  HalfLen := (B - A) / 2;
  Result  := HalfLen * (
    W1 * (EvaluateFinite('GaussLegendre5', F, Mid - HalfLen * X1) +
          EvaluateFinite('GaussLegendre5', F, Mid + HalfLen * X1)) +
    W2 * (EvaluateFinite('GaussLegendre5', F, Mid - HalfLen * X2) +
          EvaluateFinite('GaussLegendre5', F, Mid + HalfLen * X2)) +
    W3 * EvaluateFinite('GaussLegendre5', F, Mid));
end;

{ =========================================================================
  ODE Solvers
  ========================================================================= }

class function TNumericsKit.EulerStep(F: TODEFunc; T0, Y0, H: Double): Double;
begin
  if not Assigned(F) then raise EInvalidArgument.Create('EulerStep: function callback is nil.');
  if IsNan(T0) or IsInfinite(T0) or IsNan(Y0) or IsInfinite(Y0) or
     IsNan(H) or IsInfinite(H) then
    raise EInvalidArgument.Create('EulerStep: T0, Y0, and H must be finite.');
  Result := Y0 + H * EvaluateFiniteODE(F, T0, Y0, 'EulerStep');
  if IsNan(Result) or IsInfinite(Result) then
    raise ENumericsError.Create('EulerStep: step produced a non-finite value.');
end;

class function TNumericsKit.EulerSolve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
var
  H, T, Y: Double;
  I: Integer;
begin
  Result := Default(TODESolution);
  if not Assigned(F) then raise EInvalidArgument.Create('EulerSolve: function callback is nil.');
  if IsNan(T0) or IsInfinite(T0) or IsNan(Y0) or IsInfinite(Y0) or
     IsNan(T1) or IsInfinite(T1) then
    raise EInvalidArgument.Create('EulerSolve: T0, Y0, and T1 must be finite.');
  if N < 1 then
    raise EInvalidArgument.Create('EulerSolve: N must be >= 1.');
  H := (T1 - T0) / N;
  SetLength(Result.T, N + 1);
  SetLength(Result.Y, N + 1);
  T := T0; Y := Y0;
  Result.T[0] := T;
  Result.Y[0] := Y;
  for I := 1 to N do
  begin
    Y := EulerStep(F, T, Y, H);
    T := T0 + I * H;
    Result.T[I] := T;
    Result.Y[I] := Y;
  end;
end;

class function TNumericsKit.RK4Step(F: TODEFunc; T0, Y0, H: Double): Double;
var
  K1, K2, K3, K4: Double;
begin
  if not Assigned(F) then raise EInvalidArgument.Create('RK4Step: function callback is nil.');
  if IsNan(T0) or IsInfinite(T0) or IsNan(Y0) or IsInfinite(Y0) or
     IsNan(H) or IsInfinite(H) then
    raise EInvalidArgument.Create('RK4Step: T0, Y0, and H must be finite.');
  K1 := EvaluateFiniteODE(F, T0, Y0, 'RK4Step');
  K2 := EvaluateFiniteODE(F, T0 + H / 2, Y0 + H * K1 / 2, 'RK4Step');
  K3 := EvaluateFiniteODE(F, T0 + H / 2, Y0 + H * K2 / 2, 'RK4Step');
  K4 := EvaluateFiniteODE(F, T0 + H, Y0 + H * K3, 'RK4Step');
  Result := Y0 + H * (K1 + 2*K2 + 2*K3 + K4) / 6;
  if IsNan(Result) or IsInfinite(Result) then
    raise ENumericsError.Create('RK4Step: step produced a non-finite value.');
end;

class function TNumericsKit.RK4Solve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
var
  H, T, Y: Double;
  I: Integer;
begin
  Result := Default(TODESolution);
  if not Assigned(F) then raise EInvalidArgument.Create('RK4Solve: function callback is nil.');
  if IsNan(T0) or IsInfinite(T0) or IsNan(Y0) or IsInfinite(Y0) or
     IsNan(T1) or IsInfinite(T1) then
    raise EInvalidArgument.Create('RK4Solve: T0, Y0, and T1 must be finite.');
  if N < 1 then
    raise EInvalidArgument.Create('RK4Solve: N must be >= 1.');
  H := (T1 - T0) / N;
  SetLength(Result.T, N + 1);
  SetLength(Result.Y, N + 1);
  T := T0; Y := Y0;
  Result.T[0] := T;
  Result.Y[0] := Y;
  for I := 1 to N do
  begin
    Y := RK4Step(F, T, Y, H);
    T := T0 + I * H;
    Result.T[I] := T;
    Result.Y[I] := Y;
  end;
end;

{ =========================================================================
  Interpolation
  ========================================================================= }

class function TNumericsKit.LinearInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double;
var
  N, Lo, Hi, Mid: Integer;
  T: Double;
begin
  N := Length(XKnots);
  if N = 0 then
    raise EInvalidArgument.Create('LinearInterp: empty knot arrays.');
  if N <> Length(YKnots) then
    raise EInvalidArgument.Create('LinearInterp: XKnots and YKnots must have the same length.');
  ValidateKnots(XKnots, YKnots, 'LinearInterp', True);
  if IsNan(X) or IsInfinite(X) then
    raise EInvalidArgument.Create('LinearInterp: X must be finite.');
  if N = 1 then
    Exit(YKnots[0]);

  { Clamp }
  if X <= XKnots[0] then Exit(YKnots[0]);
  if X >= XKnots[N - 1] then Exit(YKnots[N - 1]);

  { Binary search for the interval }
  Lo := 0; Hi := N - 2;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if X > XKnots[Mid + 1] then Lo := Mid + 1
    else Hi := Mid;
  end;

  T      := (X - XKnots[Lo]) / (XKnots[Lo + 1] - XKnots[Lo]);
  Result := YKnots[Lo] + T * (YKnots[Lo + 1] - YKnots[Lo]);
end;

class function TNumericsKit.LagrangeInterp(const XKnots, YKnots: TDoubleArray; X: Double): Double;
var
  N, I, J: Integer;
  L, Sum: Double;
begin
  N := Length(XKnots);
  if N = 0 then
    raise EInvalidArgument.Create('LagrangeInterp: empty knot arrays.');
  if N <> Length(YKnots) then
    raise EInvalidArgument.Create('LagrangeInterp: XKnots and YKnots must have the same length.');
  ValidateKnots(XKnots, YKnots, 'LagrangeInterp', False);
  if IsNan(X) or IsInfinite(X) then
    raise EInvalidArgument.Create('LagrangeInterp: X must be finite.');

  Sum := 0;
  for I := 0 to N - 1 do
  begin
    L := 1;
    for J := 0 to N - 1 do
      if J <> I then
        L := L * (X - XKnots[J]) / (XKnots[I] - XKnots[J]);
    Sum := Sum + YKnots[I] * L;
  end;
  Result := Sum;
end;

class function TNumericsKit.CubicSplineBuild(const XKnots, YKnots: TDoubleArray): TCubicSpline;
{ Natural cubic spline: second derivatives at endpoints = 0.
  Solves the tridiagonal system with Thomas algorithm. }
var
  N, I: Integer;
  H: TDoubleArray;      { interval widths }
  Alpha: TDoubleArray;  { right-hand side }
  L, Mu, Z: TDoubleArray;
  C: TDoubleArray;
begin
  Result := Default(TCubicSpline);
  N := Length(XKnots);
  if N < 2 then
    raise EInvalidArgument.Create('CubicSplineBuild: need at least 2 knots.');
  if N <> Length(YKnots) then
    raise EInvalidArgument.Create('CubicSplineBuild: XKnots and YKnots must have the same length.');
  ValidateKnots(XKnots, YKnots, 'CubicSplineBuild', True);

  SetLength(H,     N - 1);
  SetLength(Alpha, N - 1);
  SetLength(L,     N);
  SetLength(Mu,    N);
  SetLength(Z,     N);
  SetLength(C,     N);

  for I := 0 to N - 2 do
    H[I] := XKnots[I + 1] - XKnots[I];

  for I := 1 to N - 2 do
    Alpha[I] := 3 / H[I]   * (YKnots[I + 1] - YKnots[I])
              - 3 / H[I-1] * (YKnots[I]     - YKnots[I-1]);

  { Thomas algorithm (forward sweep) }
  L[0]  := 1; Mu[0] := 0; Z[0] := 0;
  for I := 1 to N - 2 do
  begin
    L[I]  := 2 * (XKnots[I+1] - XKnots[I-1]) - H[I-1] * Mu[I-1];
    Mu[I] := H[I] / L[I];
    Z[I]  := (Alpha[I] - H[I-1] * Z[I-1]) / L[I];
  end;
  L[N-1] := 1; Z[N-1] := 0; C[N-1] := 0;

  { Back substitution }
  SetLength(Result.B, N - 1);
  SetLength(Result.C, N);
  SetLength(Result.D, N - 1);

  for I := N - 2 downto 0 do
  begin
    C[I]        := Z[I] - Mu[I] * C[I+1];
    Result.D[I] := (C[I+1] - C[I]) / (3 * H[I]);
    Result.B[I] := (YKnots[I+1] - YKnots[I]) / H[I]
                 - H[I] * (C[I+1] + 2*C[I]) / 3;
  end;

  Result.X := Copy(XKnots);
  SetLength(Result.A, N);
  for I := 0 to N - 1 do
    Result.A[I] := YKnots[I];

  for I := 0 to N - 1 do
    Result.C[I] := C[I];
end;

class function TNumericsKit.CubicSplineEval(const S: TCubicSpline; X: Double): Double;
var
  N, Lo, Hi, Mid: Integer;
  DX: Double;
begin
  N := Length(S.X);
  if N = 0 then
    raise EInvalidArgument.Create('CubicSplineEval: spline has no knots.');
  if (Length(S.A) <> N) or (Length(S.B) <> N - 1) or
     (Length(S.C) <> N) or (Length(S.D) <> N - 1) then
    raise EInvalidArgument.Create('CubicSplineEval: invalid spline coefficient dimensions.');
  ValidateKnots(S.X, S.A, 'CubicSplineEval', True);
  ValidateFiniteArray(S.B, 'CubicSplineEval B');
  ValidateFiniteArray(S.C, 'CubicSplineEval C');
  ValidateFiniteArray(S.D, 'CubicSplineEval D');
  if IsNan(X) or IsInfinite(X) then
    raise EInvalidArgument.Create('CubicSplineEval: X must be finite.');

  { Clamp }
  if X <= S.X[0] then Exit(S.A[0]);
  if X >= S.X[N-1] then Exit(S.A[N-1]);

  { Binary search }
  Lo := 0; Hi := N - 2;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if X > S.X[Mid + 1] then Lo := Mid + 1
    else Hi := Mid;
  end;

  DX     := X - S.X[Lo];
  Result := S.A[Lo]
          + S.B[Lo] * DX
          + S.C[Lo] * DX * DX
          + S.D[Lo] * DX * DX * DX;
end;

end.
