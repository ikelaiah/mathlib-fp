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

implementation

function ComplexMagnitude(const ARe, AIm: Double): Double;
var
  X, Y, Temp: Double;
begin
  X := Abs(ARe);
  Y := Abs(AIm);
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
  Ratio, Denominator: Double;
begin
  if Abs(B.Re) >= Abs(B.Im) then
  begin
    Ratio := B.Im / B.Re;
    Denominator := B.Re + B.Im * Ratio;
    Result := Create((A.Re + A.Im * Ratio) / Denominator,
      (A.Im - A.Re * Ratio) / Denominator);
  end
  else
  begin
    Ratio := B.Re / B.Im;
    Denominator := B.Im + B.Re * Ratio;
    Result := Create((A.Re * Ratio + A.Im) / Denominator,
      (A.Im * Ratio - A.Re) / Denominator);
  end;
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
  Scale := Exp(Z.Re);
  Result := TComplex.Create(Scale * Cos(Z.Im), Scale * Sin(Z.Im));
end;

function CLog(const Z: TComplex): TComplex;
begin
  Result := TComplex.Create(Ln(Z.Magnitude), Z.Argument);
end;

function CSqrt(const Z: TComplex): TComplex;
var
  M, T: Double;
begin
  if Z.Im = 0.0 then
  begin
    if Z.Re >= 0.0 then
      Exit(TComplex.Create(Sqrt(Z.Re), Z.Im))
    else if Z.Im < 0.0 then
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

end.
