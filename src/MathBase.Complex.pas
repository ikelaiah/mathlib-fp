unit MathBase.Complex;

{-----------------------------------------------------------------------------
 MathBase.Complex

 Portable double-precision complex arithmetic for mathlib-fp.

 The functions in this unit use principal values where a complex function is
 multivalued. TComplex is a value type: arithmetic never mutates an operand.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Math;

type
  TComplex = record
    Re: Double;
    Im: Double;
    class function Create(const ARe, AIm: Double): TComplex; static;
    class function FromPolar(const Radius, Angle: Double): TComplex; static;
    class function Zero: TComplex; static;
    class function One: TComplex; static;
    class function ImaginaryUnit: TComplex; static;
    class operator +(const A, B: TComplex): TComplex;
    class operator +(const A: TComplex; const B: Double): TComplex;
    class operator +(const A: Double; const B: TComplex): TComplex;
    class operator -(const A, B: TComplex): TComplex;
    class operator -(const A: TComplex; const B: Double): TComplex;
    class operator -(const A: Double; const B: TComplex): TComplex;
    class operator -(const A: TComplex): TComplex;
    class operator *(const A, B: TComplex): TComplex;
    class operator *(const A: TComplex; const B: Double): TComplex;
    class operator *(const A: Double; const B: TComplex): TComplex;
    class operator /(const A, B: TComplex): TComplex;
    class operator /(const A: TComplex; const B: Double): TComplex;
    class operator /(const A: Double; const B: TComplex): TComplex;
    class operator =(const A, B: TComplex): Boolean;
    class operator <>(const A, B: TComplex): Boolean;
    function Conjugate: TComplex;
    function SqrMagnitude: Double;
    function Magnitude: Double;
    function Argument: Double;
    function IsFinite: Boolean;
  end;

  TComplexArray = array of TComplex;

function CExp(const Z: TComplex): TComplex;
function CLog(const Z: TComplex): TComplex;
function CSqrt(const Z: TComplex): TComplex;
function CPow(const Base, Exponent: TComplex): TComplex;
function CPow(const Base: TComplex; const Exponent: Double): TComplex;
function CSin(const Z: TComplex): TComplex;
function CCos(const Z: TComplex): TComplex;
function CTan(const Z: TComplex): TComplex;
function CSinh(const Z: TComplex): TComplex;
function CCosh(const Z: TComplex): TComplex;
function CTanh(const Z: TComplex): TComplex;
function CAsin(const Z: TComplex): TComplex;
function CAcos(const Z: TComplex): TComplex;
function CAtan(const Z: TComplex): TComplex;
function CAsinh(const Z: TComplex): TComplex;
function CAcosh(const Z: TComplex): TComplex;
function CAtanh(const Z: TComplex): TComplex;

implementation

function ComplexMagnitude(const ARe, AIm: Double): Double;
var
  X, Y, Temp: Double;
begin
  X := Abs(ARe);
  Y := Abs(AIm);
  { Match hypot-style IEEE-754 behavior and avoid Inf / Inf invalid
    operations in the scaled calculation below. }
  if IsInfinite(X) or IsInfinite(Y) then
    Exit(Infinity);
  if IsNan(X) or IsNan(Y) then
    Exit(NaN);
  if X < Y then
  begin
    Temp := X;
    X := Y;
    Y := Temp;
  end;
  if X = 0.0 then
    Exit(0.0);
  Result := X * Sqrt(1.0 + Sqr(Y / X));
end;

function Log1PAccurate(const X: Double): Double;
var
  Y: Double;
begin
  Y := 1.0 + X;
  if Y = 1.0 then
    Exit(X);
  Result := Ln(Y) * X / (Y - 1.0);
end;

function ComplexLogMagnitude(const ARe, AIm: Double): Double;
var
  X, Y, Temp, Ratio: Double;
begin
  X := Abs(ARe);
  Y := Abs(AIm);
  if IsInfinite(X) or IsInfinite(Y) then
    Exit(Infinity);
  if IsNan(X) or IsNan(Y) then
    Exit(NaN);
  if X < Y then
  begin
    Temp := X;
    X := Y;
    Y := Temp;
  end;
  if X = 0.0 then
    Exit(-Infinity);
  Ratio := Y / X;
  Result := Ln(X) + 0.5 * Log1PAccurate(Ratio * Ratio);
end;

function RealArcSinhStable(const X: Double): Double;
var
  AbsoluteX, Value: Double;
begin
  if IsNan(X) or IsInfinite(X) then
    Exit(X);
  AbsoluteX := Abs(X);
  if AbsoluteX < 1.0E-8 then
    Exit(X)
  else if AbsoluteX > 1.0E150 then
    Value := Ln(AbsoluteX) + Ln(2.0)
  else
    Value := Log1PAccurate(AbsoluteX + AbsoluteX * AbsoluteX /
      (1.0 + Sqrt(1.0 + AbsoluteX * AbsoluteX)));
  if X < 0.0 then
    Result := -Value
  else
    Result := Value;
end;

function RealArcCoshStable(const X: Double): Double;
begin
  if IsNan(X) or (X < 1.0) then
    Exit(NaN);
  if IsInfinite(X) then
    Exit(Infinity);
  if X = 1.0 then
    Exit(0.0);
  if X > 1.0E150 then
    Exit(Ln(X) + Ln(2.0));
  Result := Log1PAccurate((X - 1.0) +
    Sqrt((X - 1.0) * (X + 1.0)));
end;

function IsNegativeZero(const Value: Double): Boolean;
var
  Bits: QWord;
begin
  Bits := 0;
  Move(Value, Bits, SizeOf(Value));
  Result := (Value = 0.0) and ((Bits and QWord($8000000000000000)) <> 0);
end;

function ComplexNaN: TComplex;
begin
  Result := TComplex.Create(NaN, NaN);
end;

function ComplexLog1P(const Z: TComplex): TComplex;
var
  OnePlusReal, RadiusSquaredMinusOne: Double;
begin
  if IsNan(Z.Re) or IsNan(Z.Im) then
    Exit(ComplexNaN);

  OnePlusReal := 1.0 + Z.Re;
  if (Abs(Z.Re) < 0.5) and (Abs(Z.Im) < 0.5) then
  begin
    { |1+z|^2 = 1 + 2 Re(z) + |z|^2.  log1p retains the
      first-order term when 1+Re(z) itself rounds to one. }
    RadiusSquaredMinusOne := 2.0 * Z.Re + Z.Re * Z.Re + Z.Im * Z.Im;
    Result.Re := 0.5 * Log1PAccurate(RadiusSquaredMinusOne);
  end
  else
    Result.Re := Ln(ComplexMagnitude(OnePlusReal, Z.Im));
  Result.Im := ArcTan2(Z.Im, OnePlusReal);
end;

class function TComplex.Create(const ARe, AIm: Double): TComplex;
begin
  Result.Re := ARe;
  Result.Im := AIm;
end;

class function TComplex.FromPolar(const Radius, Angle: Double): TComplex;
begin
  Result.Re := Radius * Cos(Angle);
  Result.Im := Radius * Sin(Angle);
end;

class function TComplex.Zero: TComplex;
begin
  Result := Create(0.0, 0.0);
end;

class function TComplex.One: TComplex;
begin
  Result := Create(1.0, 0.0);
end;

class function TComplex.ImaginaryUnit: TComplex;
begin
  Result := Create(0.0, 1.0);
end;

class operator TComplex.+(const A, B: TComplex): TComplex;
begin
  Result := Create(A.Re + B.Re, A.Im + B.Im);
end;

class operator TComplex.+(const A: TComplex; const B: Double): TComplex;
begin
  Result := Create(A.Re + B, A.Im);
end;

class operator TComplex.+(const A: Double; const B: TComplex): TComplex;
begin
  Result := Create(A + B.Re, B.Im);
end;

class operator TComplex.-(const A, B: TComplex): TComplex;
begin
  Result := Create(A.Re - B.Re, A.Im - B.Im);
end;

class operator TComplex.-(const A: TComplex; const B: Double): TComplex;
begin
  Result := Create(A.Re - B, A.Im);
end;

class operator TComplex.-(const A: Double; const B: TComplex): TComplex;
begin
  Result := Create(A - B.Re, -B.Im);
end;

class operator TComplex.-(const A: TComplex): TComplex;
begin
  Result := Create(-A.Re, -A.Im);
end;

class operator TComplex.*(const A, B: TComplex): TComplex;
begin
  Result := Create(A.Re * B.Re - A.Im * B.Im,
    A.Re * B.Im + A.Im * B.Re);
end;

class operator TComplex.*(const A: TComplex; const B: Double): TComplex;
begin
  Result := Create(A.Re * B, A.Im * B);
end;

class operator TComplex.*(const A: Double; const B: TComplex): TComplex;
begin
  Result := Create(A * B.Re, A * B.Im);
end;

class operator TComplex./(const A, B: TComplex): TComplex;
var
  Scale, BR, BI, AR, AI, Denominator: Double;
begin
  if IsNan(A.Re) or IsNan(A.Im) or IsNan(B.Re) or IsNan(B.Im) then
    Exit(ComplexNaN);

  if IsInfinite(B.Re) or IsInfinite(B.Im) then
  begin
    if A.IsFinite then
      Exit(Create(0.0, 0.0))
    else
      Exit(ComplexNaN);
  end;

  Scale := Max(Abs(B.Re), Abs(B.Im));
  if Scale = 0.0 then
  begin
    Result := Create(A.Re / Scale, A.Im / Scale);
    Exit;
  end;

  BR := B.Re / Scale;
  BI := B.Im / Scale;
  AR := A.Re / Scale;
  AI := A.Im / Scale;
  Denominator := BR * BR + BI * BI;
  Result := Create((AR * BR + AI * BI) / Denominator,
    (AI * BR - AR * BI) / Denominator);
end;

class operator TComplex./(const A: TComplex; const B: Double): TComplex;
begin
  Result := Create(A.Re / B, A.Im / B);
end;

class operator TComplex./(const A: Double; const B: TComplex): TComplex;
begin
  Result := Create(A, 0.0) / B;
end;

class operator TComplex.=(const A, B: TComplex): Boolean;
begin
  Result := (A.Re = B.Re) and (A.Im = B.Im);
end;

class operator TComplex.<>(const A, B: TComplex): Boolean;
begin
  Result := not (A = B);
end;

function TComplex.Conjugate: TComplex;
begin
  Result := Create(Re, -Im);
end;

function TComplex.SqrMagnitude: Double;
begin
  Result := Re * Re + Im * Im;
end;

function TComplex.Magnitude: Double;
begin
  Result := ComplexMagnitude(Re, Im);
end;

function TComplex.Argument: Double;
begin
  if (Im = 0.0) and (Re < 0.0) then
  begin
    if IsNegativeZero(Im) then
      Result := -Pi
    else
      Result := Pi;
  end
  else
    Result := ArcTan2(Im, Re);
end;

function TComplex.IsFinite: Boolean;
begin
  Result := not IsNan(Re) and not IsInfinite(Re) and
    not IsNan(Im) and not IsInfinite(Im);
end;

function CExp(const Z: TComplex): TComplex;
var
  Scale: Double;
begin
  if IsNan(Z.Re) or IsNan(Z.Im) or IsInfinite(Z.Im) then
    Exit(ComplexNaN);
  if IsInfinite(Z.Re) and (Z.Re > 0.0) and (Z.Im = 0.0) then
    Exit(TComplex.Create(Infinity, Z.Im));
  Scale := Exp(Z.Re);
  Result := TComplex.Create(Scale * Cos(Z.Im), Scale * Sin(Z.Im));
end;

function CLog(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(ComplexLogMagnitude(Z.Re, Z.Im), Z.Argument);
end;

function CSqrt(const Z: TComplex): TComplex;
var
  M, T: Double;
begin
  if IsInfinite(Z.Im) then
    Exit(TComplex.Create(Infinity, Z.Im));
  if IsInfinite(Z.Re) then
  begin
    if Z.Re > 0.0 then
      Exit(TComplex.Create(Infinity, Z.Im * 0.0));
    if (Z.Im < 0.0) or IsNegativeZero(Z.Im) then
      Exit(TComplex.Create(0.0, -Infinity))
    else
      Exit(TComplex.Create(0.0, Infinity));
  end;
  if IsNan(Z.Re) or IsNan(Z.Im) then
    Exit(ComplexNaN);

  if Z.Im = 0.0 then
  begin
    if Z.Re >= 0.0 then
      Exit(TComplex.Create(Sqrt(Z.Re), Z.Im))
    else if IsNegativeZero(Z.Im) then
      Exit(TComplex.Create(0.0, -Sqrt(-Z.Re)))
    else
      Exit(TComplex.Create(0.0, Sqrt(-Z.Re)));
  end;

  M := Z.Magnitude;
  if Z.Re >= 0.0 then
  begin
    T := Sqrt(0.5 * (M + Z.Re));
    Result := TComplex.Create(T, Z.Im / (2.0 * T));
  end
  else
  begin
    T := Sqrt(0.5 * (M - Z.Re));
    Result := TComplex.Create(Abs(Z.Im) / (2.0 * T), Sign(Z.Im) * T);
  end;
end;

function CPow(const Base, Exponent: TComplex): TComplex;
begin
  Result := CExp(Exponent * CLog(Base));
end;

function CPow(const Base: TComplex; const Exponent: Double): TComplex;
begin
  Result := CPow(Base, TComplex.Create(Exponent, 0.0));
end;

function CSin(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Sin(Z.Re) * Cosh(Z.Im),
    Cos(Z.Re) * Sinh(Z.Im));
end;

function CCos(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Cos(Z.Re) * Cosh(Z.Im),
    -Sin(Z.Re) * Sinh(Z.Im));
end;

function CTan(const Z: TComplex): TComplex;
begin
  Result := CSin(Z) / CCos(Z);
end;

function CSinh(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Sinh(Z.Re) * Cos(Z.Im),
    Cosh(Z.Re) * Sin(Z.Im));
end;

function CCosh(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Cosh(Z.Re) * Cos(Z.Im),
    Sinh(Z.Re) * Sin(Z.Im));
end;

function CTanh(const Z: TComplex): TComplex;
begin
  Result := CSinh(Z) / CCosh(Z);
end;

function CAsin(const Z: TComplex): TComplex;
var
  IUnit: TComplex;
begin
  IUnit := TComplex.ImaginaryUnit;
  Result := -IUnit * CAsinh(IUnit * Z);
end;

function CAcos(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Pi / 2.0, 0.0) - CAsin(Z);
end;

function CAtan(const Z: TComplex): TComplex;
var
  IUnit: TComplex;
begin
  IUnit := TComplex.ImaginaryUnit;
  Result := -IUnit * CAtanh(IUnit * Z);
end;

function CAsinh(const Z: TComplex): TComplex;
const
  LargeThreshold = 1.0E150;
var
  A, AbsB, B, Cosine, MaxComponent, RMinus, RPlus, RealPart: Double;
begin
  if IsNan(Z.Re) or IsNan(Z.Im) then
    Exit(ComplexNaN);

  MaxComponent := Max(Abs(Z.Re), Abs(Z.Im));
  if MaxComponent >= LargeThreshold then
  begin
    { asinh(z) ~ log(2z).  Reflect through the origin on the left
      half-plane so the principal branch and signed-zero side are kept. }
    if (Z.Re < 0.0) or IsNegativeZero(Z.Re) then
      Exit(-(CLog(-Z) + Ln(2.0)))
    else
      Exit(CLog(Z) + Ln(2.0));
  end;

  if Z.Re = 0.0 then
  begin
    { The imaginary axis outside [-i,i] is the asinh branch cut.  Handle it
      explicitly so signed zero selects the requested side. }
    A := Abs(Z.Im);
    if A <= 1.0 then
      Exit(TComplex.Create(Z.Re, ArcSin(Z.Im)));
    RealPart := RealArcCoshStable(A);
    if IsNegativeZero(Z.Re) then
      RealPart := -RealPart;
    if Z.Im < 0.0 then
      Exit(TComplex.Create(RealPart, -Pi / 2.0))
    else
      Exit(TComplex.Create(RealPart, Pi / 2.0));
  end;

  { Let A = (|z+i| + |z-i|)/2 = cosh(Re(asinh(z))) and
    B = Im(z)/A = sin(Im(asinh(z))).  This component form avoids z*z,
    whose equal large components can cancel differently across targets. }
  RPlus := ComplexMagnitude(Z.Re, Z.Im + 1.0);
  RMinus := ComplexMagnitude(Z.Re, Z.Im - 1.0);
  A := 0.5 * RPlus + 0.5 * RMinus;
  if A < 1.0 then
    A := 1.0;
  B := Z.Im / A;
  if B > 1.0 then
    B := 1.0
  else if B < -1.0 then
    B := -1.0;
  AbsB := Abs(B);
  Cosine := Sqrt(Max(0.0, (1.0 - AbsB) * (1.0 + AbsB)));
  if Cosine = 0.0 then
  begin
    RealPart := RealArcCoshStable(A);
    if Z.Re < 0.0 then
      RealPart := -RealPart;
  end
  else
    RealPart := RealArcSinhStable(Z.Re / Cosine);
  Result := TComplex.Create(RealPart, ArcSin(B));
end;

function CAcosh(const Z: TComplex): TComplex;
begin
  if IsNan(Z.Re) or IsNan(Z.Im) then
    Exit(ComplexNaN);
  { This equivalent principal-value formula avoids multiplying two square
    roots, which can overflow even when acosh(z) is representable. }
  Result := 2.0 * CLog(CSqrt(0.5 * (Z + TComplex.One)) +
    CSqrt(0.5 * (Z - TComplex.One)));
end;

function CAtanh(const Z: TComplex): TComplex;
const
  AsymptoticThreshold = 1.0E8;
var
  BranchImaginary: Double;
begin
  if IsNan(Z.Re) or IsNan(Z.Im) then
    Exit(ComplexNaN);

  if Max(Abs(Z.Re), Abs(Z.Im)) >= AsymptoticThreshold then
  begin
    if (Z.Im < 0.0) or IsNegativeZero(Z.Im) then
      BranchImaginary := -Pi / 2.0
    else
      BranchImaginary := Pi / 2.0;
    Result := TComplex.One / Z + TComplex.Create(0.0, BranchImaginary);
    Exit;
  end;

  Result := 0.5 * (ComplexLog1P(Z) - ComplexLog1P(-Z));
end;

end.
