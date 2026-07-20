unit MathBase.Precision;

{-----------------------------------------------------------------------------
 MathBase.Precision

 Core special functions used as building blocks by higher-level math libs:
   - GammaLn      — ln(Gamma(x)), Lanczos approximation
   - Beta         — B(z,w) = Gamma(z)Gamma(w)/Gamma(z+w)
   - BetaInc      — regularised incomplete beta function I_x(a,b)
   - Erf          — error function
   - NormalCDF    — standard normal CDF
   - StudentT     — upper-half Student's t CDF helper

 The implementations favour predictable IEEE-754 results: invalid shape
 parameters return NaN, endpoint limits are handled explicitly, iterative
 fractions detect non-convergence, and scale-sensitive expressions are
 evaluated in the logarithmic domain where practical.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math;

{ Natural logarithm of the gamma function for finite X > 0.
  Returns NaN outside that domain and +Infinity at +Infinity. }
function GammaLn(const X: Double): Double;

{ Beta function B(z,w) for finite positive parameters.
  Returns NaN for invalid parameters and 0/+Infinity when the mathematical
  result underflows/overflows Double. }
function Beta(const Z, W: Double): Double;

{ Regularised incomplete beta function I_x(a,b). X values outside [0,1]
  clamp to the corresponding endpoint. A and B must be finite and positive;
  invalid parameters or failure to converge return NaN. }
function BetaInc(const A, B, X: Double): Double;

{ Error function, evaluated to approximately Double precision. }
function Erf(const X: Double): Double;

{ Standard normal CDF. The negative tail is evaluated directly rather than
  by subtracting nearly equal values. }
function NormalCDF(const X: Double): Double;

{ Student's t CDF helper for finite X >= 0 and DF >= 1. Returns NaN for
  invalid inputs. Negative-X symmetry is intentionally left to callers. }
function StudentT(const DF: Integer; const X: Double): Double;

implementation

const
  HalfLogTwoPi = 0.91893853320467274178032973640562;
  LogMaxDouble = 709.782712893383973096206318587;
  LogMinDouble = -745.133219101941108420;
  SqrtMaxDouble = 1.3407807929942596E154;

function Log1PAccurate(const X: Double): Double;
var
  Y: Double;
begin
  Y := 1.0 + X;
  if Y = 1.0 then
    Exit(X);
  { Correct for the rounding which occurred while forming 1+X. }
  Result := Ln(Y) * X / (Y - 1.0);
end;

function StirlingErrorFromInverse(const InvX: Double): Double;
var
  InvX2, Power: Double;
begin
  InvX2 := InvX * InvX;
  Power := InvX;
  Result := Power / 12.0;
  Power := Power * InvX2;
  Result := Result - Power / 360.0;
  Power := Power * InvX2;
  Result := Result + Power / 1260.0;
  Power := Power * InvX2;
  Result := Result - Power / 1680.0;
  Power := Power * InvX2;
  Result := Result + Power / 1188.0;
  Power := Power * InvX2;
  Result := Result - Power * (691.0 / 360360.0);
end;

function StirlingError(const X: Double): Double;
begin
  Result := StirlingErrorFromInverse(1.0 / X);
end;

function GammaLn(const X: Double): Double;
const
  G = 7.0;
  Coeff: array[0..8] of Double = (
       0.99999999999980993,
     676.5203681218851,
   -1259.1392167224028,
     771.32342877765313,
    -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
       9.9843695780195716E-6,
       1.5056327351493116E-7);
var
  J: Integer;
  Sum, T, Z: Double;
begin
  if IsNan(X) or (X <= 0.0) then
    Exit(NaN);
  if IsInfinite(X) then
    Exit(Infinity);

  { Reflection avoids the large 1/X Lanczos term near zero. }
  if X < 0.5 then
    Exit(Ln(Pi) - Ln(Sin(Pi * X)) - GammaLn(1.0 - X));

  Z := X - 1.0;
  Sum := Coeff[0];
  for J := 1 to High(Coeff) do
    Sum := Sum + Coeff[J] / (Z + J);
  T := Z + G + 0.5;
  Result := HalfLogTwoPi + (Z + 0.5) * Ln(T) - T + Ln(Sum);
end;

{ Compute log(Beta(A,B)) without subtracting nearly equal log-gamma values
  for large or strongly unbalanced parameters. }
function LogBeta(const A, B: Double): Double;
var
  InvSum, Large, LogRatioPlusOne, LogSum, Ratio, Small: Double;
begin
  if IsNan(A) or IsNan(B) or IsInfinite(A) or IsInfinite(B) or
     (A <= 0.0) or (B <= 0.0) then
    Exit(NaN);

  if A >= B then
  begin
    Large := A;
    Small := B;
  end
  else
  begin
    Large := B;
    Small := A;
  end;

  if Large < 8.0 then
    Exit(GammaLn(A) + GammaLn(B) - GammaLn(A + B));

  Ratio := Small / Large;
  LogRatioPlusOne := Log1PAccurate(Ratio);
  LogSum := Ln(Large) + LogRatioPlusOne;
  InvSum := (1.0 / Large) / (1.0 + Ratio);

  if Small >= 8.0 then
    Result := (Large - 0.5) * (-LogRatioPlusOne) +
      (Small - 0.5) * (Ln(Ratio) - LogRatioPlusOne) -
      0.5 * LogSum + HalfLogTwoPi +
      StirlingError(Large) + StirlingError(Small) -
      StirlingErrorFromInverse(InvSum)
  else
    Result := GammaLn(Small) -
      (Large - 0.5) * LogRatioPlusOne - Small * LogSum + Small +
      StirlingError(Large) - StirlingErrorFromInverse(InvSum);
end;

function Beta(const Z, W: Double): Double;
var
  LogValue: Double;
begin
  LogValue := LogBeta(Z, W);
  if IsNan(LogValue) then
    Exit(NaN);
  if LogValue > LogMaxDouble then
    Exit(Infinity);
  if LogValue < LogMinDouble then
    Exit(0.0);
  Result := Exp(LogValue);
end;

function SignedFloor(const Value, FloorValue: Double): Double;
begin
  if Abs(Value) >= FloorValue then
    Exit(Value);
  if Value < 0.0 then
    Result := -FloorValue
  else
    Result := FloorValue;
end;

{ Evaluate the continued fraction for the incomplete beta using Lentz's
  method. The caller supplies valid finite positive shape parameters. }
function BetaCF(const A, B, X: Double; out Converged: Boolean): Double;
const
  MaxIter = 10000;
  Eps = 8.0E-15;
  FPMin = 1.0E-300;
var
  AA, C, D, Del, H, Qab, Qam, Qap: Double;
  M, M2: Integer;
begin
  Qab := A + B;
  Qap := A + 1.0;
  Qam := A - 1.0;
  C := 1.0;
  D := SignedFloor(1.0 - Qab * X / Qap, FPMin);
  D := 1.0 / D;
  H := D;
  Converged := False;

  for M := 1 to MaxIter do
  begin
    M2 := 2 * M;
    AA := M * (B - M) * X / ((Qam + M2) * (A + M2));
    D := SignedFloor(1.0 + AA * D, FPMin);
    C := SignedFloor(1.0 + AA / C, FPMin);
    D := 1.0 / D;
    H := H * D * C;

    AA := -(A + M) * (Qab + M) * X /
      ((A + M2) * (Qap + M2));
    D := SignedFloor(1.0 + AA * D, FPMin);
    C := SignedFloor(1.0 + AA / C, FPMin);
    D := 1.0 / D;
    Del := D * C;
    H := H * Del;

    if IsNan(H) or IsInfinite(H) then
      Break;
    if Abs(Del - 1.0) <= Eps then
    begin
      Converged := True;
      Break;
    end;
  end;
  Result := H;
end;

function StableFraction(const Numerator, Other: Double): Double;
var
  Ratio: Double;
begin
  if Numerator >= Other then
    Result := 1.0 / (1.0 + Other / Numerator)
  else
  begin
    Ratio := Numerator / Other;
    Result := Ratio / (1.0 + Ratio);
  end;
end;

function BetaInc(const A, B, X: Double): Double;
var
  BT, CFValue, LogPrefactor, Threshold: Double;
  Converged: Boolean;
begin
  if IsNan(X) or IsNan(A) or IsNan(B) or IsInfinite(A) or IsInfinite(B) or
     (A <= 0.0) or (B <= 0.0) then
    Exit(NaN);
  if X <= 0.0 then
    Exit(0.0);
  if X >= 1.0 then
    Exit(1.0);
  if (A = B) and (X = 0.5) then
    Exit(0.5);

  LogPrefactor := A * Ln(X) + B * Log1PAccurate(-X) - LogBeta(A, B);
  if IsNan(LogPrefactor) then
    Exit(NaN);
  if LogPrefactor < LogMinDouble then
    BT := 0.0
  else if LogPrefactor > LogMaxDouble then
    Exit(NaN)
  else
    BT := Exp(LogPrefactor);

  { (A+1)/(A+B+2), formed without overflowing A+B. }
  Threshold := StableFraction(A + 1.0, B + 1.0);
  if X < Threshold then
  begin
    CFValue := BetaCF(A, B, X, Converged);
    if not Converged then
      Exit(NaN);
    Result := BT * CFValue / A;
  end
  else
  begin
    CFValue := BetaCF(B, A, 1.0 - X, Converged);
    if not Converged then
      Exit(NaN);
    Result := 1.0 - BT * CFValue / B;
  end;

  { Contain the last few ulps of continued-fraction round-off. }
  if Result < 0.0 then
    Result := 0.0
  else if Result > 1.0 then
    Result := 1.0;
end;

{ Evaluate both regularised incomplete gamma ratios. This private kernel is
  used with A=1/2 to obtain accurate erf/normal tails. }
procedure GammaRatios(const A, X: Double; out PValue, QValue: Double;
  out Converged: Boolean);
const
  MaxIter = 10000;
  Eps = 8.0E-15;
  FPMin = 1.0E-300;
var
  AP, B, C, D, Del, H, LogFactor, Sum, Term: Double;
  N: Integer;
begin
  Converged := False;
  PValue := NaN;
  QValue := NaN;
  if X = 0.0 then
  begin
    PValue := 0.0;
    QValue := 1.0;
    Converged := True;
    Exit;
  end;
  if IsInfinite(X) then
  begin
    PValue := 1.0;
    QValue := 0.0;
    Converged := True;
    Exit;
  end;

  LogFactor := -X + A * Ln(X) - GammaLn(A);
  if X < A + 1.0 then
  begin
    AP := A;
    Term := 1.0 / A;
    Sum := Term;
    for N := 1 to MaxIter do
    begin
      AP := AP + 1.0;
      Term := Term * X / AP;
      Sum := Sum + Term;
      if Abs(Term) <= Abs(Sum) * Eps then
      begin
        PValue := Sum * Exp(LogFactor);
        if PValue < 0.0 then PValue := 0.0;
        if PValue > 1.0 then PValue := 1.0;
        QValue := 1.0 - PValue;
        Converged := True;
        Exit;
      end;
    end;
  end
  else
  begin
    B := X + 1.0 - A;
    C := 1.0 / FPMin;
    D := 1.0 / B;
    H := D;
    for N := 1 to MaxIter do
    begin
      Term := -N * (N - A);
      B := B + 2.0;
      D := SignedFloor(Term * D + B, FPMin);
      C := SignedFloor(B + Term / C, FPMin);
      D := 1.0 / D;
      Del := D * C;
      H := H * Del;
      if Abs(Del - 1.0) <= Eps then
      begin
        if LogFactor < LogMinDouble then
          QValue := 0.0
        else
          QValue := Exp(LogFactor) * H;
        if QValue < 0.0 then QValue := 0.0;
        if QValue > 1.0 then QValue := 1.0;
        PValue := 1.0 - QValue;
        Converged := True;
        Exit;
      end;
    end;
  end;
end;

function Erf(const X: Double): Double;
const
  TwoOverSqrtPi = 1.1283791670955125738961589031215;
var
  AX, PValue, QValue, X2: Double;
  Converged: Boolean;
begin
  if IsNan(X) then
    Exit(NaN);
  if IsInfinite(X) then
  begin
    if X < 0.0 then Exit(-1.0) else Exit(1.0);
  end;

  AX := Abs(X);
  if AX < 1.0E-5 then
  begin
    X2 := X * X;
    Exit(TwoOverSqrtPi * X * (1.0 - X2 / 3.0 + X2 * X2 / 10.0));
  end;

  if AX > SqrtMaxDouble then
    PValue := 1.0
  else
  begin
    GammaRatios(0.5, AX * AX, PValue, QValue, Converged);
    if not Converged then
      Exit(NaN);
  end;
  if X < 0.0 then
    Result := -PValue
  else
    Result := PValue;
end;

function NormalCDF(const X: Double): Double;
var
  PValue, QValue, Z: Double;
  Converged: Boolean;
begin
  if IsNan(X) then
    Exit(NaN);
  if IsInfinite(X) then
  begin
    if X < 0.0 then Exit(0.0) else Exit(1.0);
  end;
  if Abs(X) > SqrtMaxDouble then
  begin
    if X < 0.0 then Exit(0.0) else Exit(1.0);
  end;

  Z := 0.5 * X * X;
  GammaRatios(0.5, Z, PValue, QValue, Converged);
  if not Converged then
    Exit(NaN);
  if X < 0.0 then
    Result := 0.5 * QValue
  else
    Result := 1.0 - 0.5 * QValue;
end;

function StudentT(const DF: Integer; const X: Double): Double;
var
  BetaX, ScaledX, Tail: Double;
begin
  if (DF < 1) or IsNan(X) or (X < 0.0) then
    Exit(NaN);
  if IsInfinite(X) then
    Exit(1.0);
  if X = 0.0 then
    Exit(0.5);

  ScaledX := X / Sqrt(DF);
  if ScaledX > SqrtMaxDouble then
    BetaX := 0.0
  else
    BetaX := 1.0 / (1.0 + ScaledX * ScaledX);
  { CDF(x) is one minus half the regularised incomplete beta value at
    df/(df+x^2), with shape parameters df/2 and 1/2. }
  Tail := 0.5 * BetaInc(0.5 * DF, 0.5, BetaX);
  if IsNan(Tail) then
    Exit(NaN);
  Result := 1.0 - Tail;
end;

end.
