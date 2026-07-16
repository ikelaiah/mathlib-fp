unit NumericsLib.Numerics;

{-----------------------------------------------------------------------------
 NumericsLib.Numerics

 Numerical methods library — no external dependencies beyond MathBase.

 Provides:
   Root Finding
     Bisection        — bracketed, guaranteed convergence
     NewtonRaphson    — fast near root with derivative
     Brent            — hybrid bracket/secant, robust default
     Secant           — derivative-free quasi-Newton

   Numerical Integration (quadrature)
     TrapezoidalRule  — 1st-order composite rule
     SimpsonRule      — 3rd-order composite rule (n must be even)
     GaussLegendre5   — 5-point Gauss-Legendre on [a,b]

   ODE Solvers (initial-value problems)
     EulerStep / EulerSolve        — 1st-order explicit Euler
     RK4Step   / RK4Solve          — 4th-order Runge-Kutta (classic)

   Interpolation
     LinearInterp     — piecewise linear between sorted knots
     LagrangeInterp   — global Lagrange polynomial (small n)
     CubicSplineNat   — natural cubic spline (clamped ends = 0 slope)

 All functions are class-static (no instantiation required):
   result := TNumericsKit.Bisection(f, a, b);
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

type
  { Function pointer types }
  TScalarFunc  = function(X: Double): Double;           // f(x)
  TODEFunc     = function(T, Y: Double): Double;        // dy/dt = f(t,y)

  { Result record for ODE solvers }
  TODESolution = record
    T: TDoubleArray;   // time/independent variable values
    Y: TDoubleArray;   // solution values
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

    { Bisection method: find root of f in [A, B] where f(A)*f(B) < 0.
      MaxIter: maximum iterations (default 100).
      Tol: absolute tolerance on the interval width (default 1e-10).
      Raises EInvalidArgument if f(A)*f(B) >= 0. }
    class function Bisection(F: TScalarFunc; A, B: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;

    { Newton-Raphson: find root starting from X0 using f and df/dx.
      Tol: tolerance on |f(x)| (default 1e-10).
      MaxIter: max iterations (default 100). }
    class function NewtonRaphson(
      F, DF: TScalarFunc;
      X0: Double;
      Tol: Double = 1E-10;
      MaxIter: Integer = 100): Double; static;

    { Brent's method: robust bracketed root-finding combining bisection,
      secant, and inverse-quadratic interpolation.
      Requires f(A)*f(B) <= 0. }
    class function Brent(F: TScalarFunc; A, B: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;

    { Secant method: derivative-free, requires two initial guesses X0, X1.
      Tol: tolerance on |f(x)| (default 1e-10).
      MaxIter: max iterations (default 100). }
    class function Secant(F: TScalarFunc; X0, X1: Double; Tol: Double = 1E-10; MaxIter: Integer = 100): Double; static;

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
      Returns a TCubicSpline that can be evaluated with SplineEval. }
    class function CubicSplineBuild(const XKnots, YKnots: TDoubleArray): TCubicSpline; static;

    { Evaluate a previously built TCubicSpline at point X.
      Clamps to endpoint values outside the knot range. }
    class function CubicSplineEval(const S: TCubicSpline; X: Double): Double; static;
  end;

implementation

{ =========================================================================
  Root Finding
  ========================================================================= }

class function TNumericsKit.Bisection(F: TScalarFunc; A, B: Double; Tol: Double; MaxIter: Integer): Double;
var
  FA, FB, FMid, Mid: Double;
  Iter: Integer;
begin
  FA := F(A);
  FB := F(B);
  if FA * FB > 0 then
    raise EInvalidArgument.Create(
      'Bisection: f(A) and f(B) must have opposite signs.');

  for Iter := 1 to MaxIter do
  begin
    Mid  := (A + B) / 2;
    FMid := F(Mid);
    if (Abs(FMid) < Tol) or ((B - A) / 2 < Tol) then
      Exit(Mid);
    if FA * FMid < 0 then
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
  Result := (A + B) / 2;
end;

class function TNumericsKit.NewtonRaphson(F, DF: TScalarFunc; X0: Double; Tol: Double; MaxIter: Integer): Double;
var
  X, FX, DFX: Double;
  Iter: Integer;
begin
  X := X0;
  for Iter := 1 to MaxIter do
  begin
    FX  := F(X);
    if Abs(FX) < Tol then
      Exit(X);
    DFX := DF(X);
    if Abs(DFX) < 1E-300 then
      raise EInvalidArgument.Create('NewtonRaphson: derivative too small (near-zero).');
    X := X - FX / DFX;
  end;
  Result := X;
end;

class function TNumericsKit.Brent(F: TScalarFunc; A, B: Double; Tol: Double; MaxIter: Integer): Double;
var
  FA, FB, FC, C, D, S: Double;
  Tmp: Double;
  Iter: Integer;
  MFlag: Boolean;
begin
  FA := F(A);
  FB := F(B);
  if FA * FB > 0 then
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
    if Abs(FB) < Tol then
      Exit(B);
    if Abs(B - A) < Tol then
      Exit(B);

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

    if FA * F(S) < 0 then
    begin
      B  := S;
      FB := F(S);
    end
    else
    begin
      A  := S;
      FA := F(S);
    end;

    if Abs(FA) < Abs(FB) then
    begin
      Tmp := A; A := B; B := Tmp;
      Tmp := FA; FA := FB; FB := Tmp;
    end;

  end;
  Result := B;
end;

class function TNumericsKit.Secant(F: TScalarFunc; X0, X1: Double; Tol: Double; MaxIter: Integer): Double;
var
  F0, F1, X2: Double;
  Iter: Integer;
begin
  F0 := F(X0);
  F1 := F(X1);
  for Iter := 1 to MaxIter do
  begin
    if Abs(F1) < Tol then
      Exit(X1);
    if Abs(F1 - F0) < 1E-300 then
      raise EInvalidArgument.Create('Secant: division by near-zero (f(x1) ≈ f(x0)).');
    X2 := X1 - F1 * (X1 - X0) / (F1 - F0);
    X0 := X1; F0 := F1;
    X1 := X2; F1 := F(X1);
  end;
  Result := X1;
end;

{ =========================================================================
  Numerical Integration
  ========================================================================= }

class function TNumericsKit.TrapezoidalRule(F: TScalarFunc; A, B: Double; N: Integer): Double;
var
  H, Sum: Double;
  I: Integer;
begin
  if N < 1 then
    raise EInvalidArgument.Create('TrapezoidalRule: N must be >= 1.');
  H   := (B - A) / N;
  Sum := (F(A) + F(B)) / 2;
  for I := 1 to N - 1 do
    Sum := Sum + F(A + I * H);
  Result := H * Sum;
end;

class function TNumericsKit.SimpsonRule(F: TScalarFunc; A, B: Double; N: Integer): Double;
var
  H, Sum: Double;
  I: Integer;
begin
  if N < 2 then N := 2;
  if Odd(N) then Inc(N);  { must be even }
  H   := (B - A) / N;
  Sum := F(A) + F(B);
  for I := 1 to N - 1 do
  begin
    if Odd(I) then
      Sum := Sum + 4 * F(A + I * H)
    else
      Sum := Sum + 2 * F(A + I * H);
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
  Mid     := (A + B) / 2;
  HalfLen := (B - A) / 2;
  Result  := HalfLen * (
    W1 * (F(Mid - HalfLen * X1) + F(Mid + HalfLen * X1)) +
    W2 * (F(Mid - HalfLen * X2) + F(Mid + HalfLen * X2)) +
    W3 *  F(Mid));
end;

{ =========================================================================
  ODE Solvers
  ========================================================================= }

class function TNumericsKit.EulerStep(F: TODEFunc; T0, Y0, H: Double): Double;
begin
  Result := Y0 + H * F(T0, Y0);
end;

class function TNumericsKit.EulerSolve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
var
  H, T, Y: Double;
  I: Integer;
begin
  Result := Default(TODESolution);
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
  K1 := F(T0,           Y0);
  K2 := F(T0 + H / 2,   Y0 + H * K1 / 2);
  K3 := F(T0 + H / 2,   Y0 + H * K2 / 2);
  K4 := F(T0 + H,        Y0 + H * K3);
  Result := Y0 + H * (K1 + 2*K2 + 2*K3 + K4) / 6;
end;

class function TNumericsKit.RK4Solve(F: TODEFunc; T0, Y0, T1: Double; N: Integer): TODESolution;
var
  H, T, Y: Double;
  I: Integer;
begin
  Result := Default(TODESolution);
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
