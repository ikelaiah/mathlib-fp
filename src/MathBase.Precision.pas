unit MathBase.Precision;

{-----------------------------------------------------------------------------
 MathBase.Precision

 Core special functions used as building blocks by higher-level math libs:
   - GammaLn      — ln(Γ(x)), Lanczos approximation
   - Beta          — B(z,w) = Γ(z)Γ(w)/Γ(z+w)
   - BetaInc       — Incomplete beta function I_x(a,b)
   - Erf           — Error function
   - NormalCDF     — Standard normal CDF
   - StudentT      — Student's t CDF
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math;

{ Natural logarithm of the gamma function (Lanczos approximation).
  Input X must be positive. }
function GammaLn(const X: Double): Double;

{ Beta function B(z,w) = Γ(z)Γ(w)/Γ(z+w). }
function Beta(const Z, W: Double): Double;

{ Regularised incomplete beta function I_x(a,b).
  X must be in [0,1]. }
function BetaInc(const A, B, X: Double): Double;

{ Error function (Horner polynomial approximation, max error < 1.5e-7). }
function Erf(const X: Double): Double;

{ Standard normal CDF: Φ(x) = 0.5 * (1 + Erf(x / √2)). }
function NormalCDF(const X: Double): Double;

{ Student's t cumulative distribution function.
  DF = degrees of freedom (must be >= 1). }
function StudentT(const DF: Integer; const X: Double): Double;

implementation

function GammaLn(const X: Double): Double;
const
  Coeff: array[0..5] of Double = (
     76.18009172947146,
    -86.50532032941677,
     24.01409824083091,
     -1.231739572450155,
      0.1208650973866179e-2,
     -0.5395239384953e-5);
var
  Y, Tmp, Ser: Double;
  J: Integer;
begin
  Y   := X;
  Tmp := X + 5.5;
  Tmp := (X + 0.5) * Ln(Tmp) - Tmp;
  Ser := 1.000000000190015;
  for J := 0 to 5 do
    Ser := Ser + Coeff[J] / (Y + J + 1);
  Result := Tmp + Ln(2.5066282746310005 * Ser / X);
end;

function Beta(const Z, W: Double): Double;
begin
  Result := Exp(GammaLn(Z) + GammaLn(W) - GammaLn(Z + W));
end;

{ Evaluate the continued fraction for the incomplete beta via Lentz's method.
  Returns the CF value; caller handles the x^a*(1-x)^b/B(a,b) prefactor. }
function BetaCF(const A, B, X: Double): Double;
const
  MaxIter = 200;
  Eps     = 3.0e-7;
  FPMin   = 1.0e-300;
var
  Qab, Qam, Qap, C, D, H, AA, Del: Double;
  M, M2: Integer;
begin
  Qab := A + B;
  Qap := A + 1.0;
  Qam := A - 1.0;
  C   := 1.0;
  D   := 1.0 - Qab * X / Qap;
  if Abs(D) < FPMin then D := FPMin;
  D   := 1.0 / D;
  H   := D;
  for M := 1 to MaxIter do
  begin
    M2 := 2 * M;
    { Even step }
    AA := M * (B - M) * X / ((Qam + M2) * (A + M2));
    D  := 1.0 + AA * D;
    if Abs(D) < FPMin then D := FPMin;
    C  := 1.0 + AA / C;
    if Abs(C) < FPMin then C := FPMin;
    D  := 1.0 / D;
    H  := H * D * C;
    { Odd step }
    AA := -(A + M) * (Qab + M) * X / ((A + M2) * (Qap + M2));
    D  := 1.0 + AA * D;
    if Abs(D) < FPMin then D := FPMin;
    C  := 1.0 + AA / C;
    if Abs(C) < FPMin then C := FPMin;
    D  := 1.0 / D;
    Del := D * C;
    H   := H * Del;
    if Abs(Del - 1.0) < Eps then Break;
  end;
  Result := H;
end;

function BetaInc(const A, B, X: Double): Double;
var
  Bt: Double;
begin
  if X <= 0 then Exit(0);
  if X >= 1 then Exit(1);
  Bt := Exp(GammaLn(A + B) - GammaLn(A) - GammaLn(B)
            + A * Ln(X) + B * Ln(1.0 - X));
  { Use symmetry relation when x > (a+1)/(a+b+2) for better convergence }
  if X < (A + 1.0) / (A + B + 2.0) then
    Result := Bt * BetaCF(A, B, X) / A
  else
    Result := 1.0 - Bt * BetaCF(B, A, 1.0 - X) / B;
end;

function Erf(const X: Double): Double;
const
  A1 =  0.254829592;
  A2 = -0.284496736;
  A3 =  1.421413741;
  A4 = -1.453152027;
  A5 =  1.061405429;
  P  =  0.3275911;
var
  T, Sign: Double;
begin
  if X < 0 then Sign := -1 else Sign := 1;
  T      := 1.0 / (1.0 + P * Abs(X));
  Result := Sign * (1 - ((((A5 * T + A4) * T + A3) * T + A2) * T + A1) * T * Exp(-X * X));
end;

function NormalCDF(const X: Double): Double;
begin
  Result := 0.5 * (1 + Erf(X / Sqrt(2)));
end;

function StudentT(const DF: Integer; const X: Double): Double;
var
  A: Double;
begin
  A      := (DF + 1) / 2;
  Result := 1 - 0.5 * BetaInc(A, 0.5, DF / (DF + Sqr(X)));
end;

end.
