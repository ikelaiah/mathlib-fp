unit AlgebraLib.VectorKernels;

{-----------------------------------------------------------------------------
 AlgebraLib.VectorKernels

 Array-vector kernels complement the established matrix-as-vector API in
 AlgebraLib.Vectors. They are intended for inner loops and contiguous data.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Complex;

type
  EVectorError = class(Exception);
  TRealVector = TDoubleArray;
  TComplexVector = TComplexArray;

  TVectorKit = class
  public
    class function Add(const A, B: TRealVector): TRealVector; static;
    class procedure AddInto(const A, B: TRealVector; var Destination: TRealVector); static;
    class function Subtract(const A, B: TRealVector): TRealVector; static;
    class procedure SubtractInto(const A, B: TRealVector; var Destination: TRealVector); static;
    class function ElementWiseMultiply(const A, B: TRealVector): TRealVector; static;
    class procedure ElementWiseMultiplyInto(const A, B: TRealVector; var Destination: TRealVector); static;
    class function ElementWiseDivide(const A, B: TRealVector): TRealVector; static;
    class procedure ElementWiseDivideInto(const A, B: TRealVector; var Destination: TRealVector); static;
    class function Scale(const A: TRealVector; const Scalar: Double): TRealVector; static;
    class procedure ScaleInto(const A: TRealVector; const Scalar: Double; var Destination: TRealVector); static;
    class function Axpy(const Alpha: Double; const X, Y: TRealVector): TRealVector; static;
    class procedure AxpyInto(const Alpha: Double; const X, Y: TRealVector; var Destination: TRealVector); static;
    class function Dot(const A, B: TRealVector): Double; static;
    class function Sum(const A: TRealVector): Double; static;
    class function Mean(const A: TRealVector): Double; static;
    class function Min(const A: TRealVector): Double; static;
    class function Max(const A: TRealVector): Double; static;
    class function Norm2(const A: TRealVector): Double; static;
    class function Normalize(const A: TRealVector): TRealVector; static;
    class procedure NormalizeInto(const A: TRealVector; var Destination: TRealVector); static;

    class function Add(const A, B: TComplexVector): TComplexVector; static;
    class procedure AddInto(const A, B: TComplexVector; var Destination: TComplexVector); static;
    class function Subtract(const A, B: TComplexVector): TComplexVector; static;
    class procedure SubtractInto(const A, B: TComplexVector; var Destination: TComplexVector); static;
    class function Scale(const A: TComplexVector; const Scalar: TComplex): TComplexVector; static;
    class procedure ScaleInto(const A: TComplexVector; const Scalar: TComplex; var Destination: TComplexVector); static;
    class function Axpy(const Alpha: TComplex; const X, Y: TComplexVector): TComplexVector; static;
    class procedure AxpyInto(const Alpha: TComplex; const X, Y: TComplexVector; var Destination: TComplexVector); static;
    class function Dot(const A, B: TComplexVector): TComplex; static;
    class function DotConjugate(const A, B: TComplexVector): TComplex; static;
    class function Norm2(const A: TComplexVector): Double; static;
    class function Normalize(const A: TComplexVector): TComplexVector; static;
    class procedure NormalizeInto(const A: TComplexVector; var Destination: TComplexVector); static;
  end;

implementation

procedure RequireSameLength(const ALength, BLength: Integer; const Operation: string);
begin
  if ALength <> BLength then
    raise EVectorError.CreateFmt('%s: vector lengths must match.', [Operation]);
end;

procedure RequireFiniteRealVector(const A: TRealVector; const Operation: string);
var
  I: Integer;
begin
  for I := 0 to High(A) do
    if IsNan(A[I]) or IsInfinite(A[I]) then
      raise EVectorError.CreateFmt('%s: vector values must be finite.', [Operation]);
end;

procedure RequireFiniteComplexVector(const A: TComplexVector; const Operation: string);
var
  I: Integer;
begin
  for I := 0 to High(A) do
    if not A[I].IsFinite then
      raise EVectorError.CreateFmt('%s: vector values must be finite.', [Operation]);
end;

procedure UpdateScaledSum(const Value: Double; var Scale, SumSquares: Double);
var
  AbsoluteValue, Ratio: Double;
begin
  AbsoluteValue := Abs(Value);
  if AbsoluteValue = 0.0 then
    Exit;
  if Scale < AbsoluteValue then
  begin
    if Scale = 0.0 then
      SumSquares := 1.0
    else
    begin
      Ratio := Scale / AbsoluteValue;
      SumSquares := 1.0 + SumSquares * Sqr(Ratio);
    end;
    Scale := AbsoluteValue;
  end
  else
  begin
    Ratio := AbsoluteValue / Scale;
    SumSquares := SumSquares + Sqr(Ratio);
  end;
end;

procedure PrepareRealDestination(const Source: TRealVector; var Destination: TRealVector);
begin
  if Length(Destination) <> Length(Source) then
    SetLength(Destination, Length(Source));
end;

procedure PrepareComplexDestination(const Source: TComplexVector;
  var Destination: TComplexVector);
begin
  if Length(Destination) <> Length(Source) then
    SetLength(Destination, Length(Source));
end;

procedure AddCompensated(const Value: Double; var Sum, Compensation: Double);
var
  Updated: Double;
begin
  Updated := Sum + Value;
  if Abs(Sum) >= Abs(Value) then
    Compensation := Compensation + ((Sum - Updated) + Value)
  else
    Compensation := Compensation + ((Value - Updated) + Sum);
  Sum := Updated;
end;

function CompensatedTotal(const Sum, Compensation: Double): Double;
begin
  Result := Sum + Compensation;
end;

class function TVectorKit.Add(const A, B: TRealVector): TRealVector;
begin
  Result := nil;
  AddInto(A, B, Result);
end;

class procedure TVectorKit.AddInto(const A, B: TRealVector;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'AddInto');
  RequireFiniteRealVector(A, 'AddInto');
  RequireFiniteRealVector(B, 'AddInto');
  PrepareRealDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] + B[I];
end;

class function TVectorKit.Subtract(const A, B: TRealVector): TRealVector;
begin
  Result := nil;
  SubtractInto(A, B, Result);
end;

class procedure TVectorKit.SubtractInto(const A, B: TRealVector;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'SubtractInto');
  RequireFiniteRealVector(A, 'SubtractInto');
  RequireFiniteRealVector(B, 'SubtractInto');
  PrepareRealDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] - B[I];
end;

class function TVectorKit.ElementWiseMultiply(const A, B: TRealVector): TRealVector;
begin
  Result := nil;
  ElementWiseMultiplyInto(A, B, Result);
end;

class procedure TVectorKit.ElementWiseMultiplyInto(const A, B: TRealVector;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'ElementWiseMultiplyInto');
  RequireFiniteRealVector(A, 'ElementWiseMultiplyInto');
  RequireFiniteRealVector(B, 'ElementWiseMultiplyInto');
  PrepareRealDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] * B[I];
end;

class function TVectorKit.ElementWiseDivide(const A, B: TRealVector): TRealVector;
begin
  Result := nil;
  ElementWiseDivideInto(A, B, Result);
end;

class procedure TVectorKit.ElementWiseDivideInto(const A, B: TRealVector;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'ElementWiseDivideInto');
  RequireFiniteRealVector(A, 'ElementWiseDivideInto');
  RequireFiniteRealVector(B, 'ElementWiseDivideInto');
  PrepareRealDestination(A, Destination);
  for I := 0 to High(A) do
  begin
    if B[I] = 0.0 then
      raise EVectorError.Create('ElementWiseDivideInto: divisor must be non-zero.');
    Destination[I] := A[I] / B[I];
  end;
end;

class function TVectorKit.Scale(const A: TRealVector; const Scalar: Double): TRealVector;
begin
  Result := nil;
  ScaleInto(A, Scalar, Result);
end;

class procedure TVectorKit.ScaleInto(const A: TRealVector; const Scalar: Double;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireFiniteRealVector(A, 'ScaleInto');
  if IsNan(Scalar) or IsInfinite(Scalar) then
    raise EVectorError.Create('ScaleInto: scalar must be finite.');
  PrepareRealDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] * Scalar;
end;

class function TVectorKit.Axpy(const Alpha: Double; const X, Y: TRealVector): TRealVector;
begin
  Result := nil;
  AxpyInto(Alpha, X, Y, Result);
end;

class procedure TVectorKit.AxpyInto(const Alpha: Double; const X, Y: TRealVector;
  var Destination: TRealVector);
var
  I: Integer;
begin
  RequireSameLength(Length(X), Length(Y), 'AxpyInto');
  RequireFiniteRealVector(X, 'AxpyInto');
  RequireFiniteRealVector(Y, 'AxpyInto');
  if IsNan(Alpha) or IsInfinite(Alpha) then
    raise EVectorError.Create('AxpyInto: scalar must be finite.');
  PrepareRealDestination(X, Destination);
  for I := 0 to High(X) do
    Destination[I] := Alpha * X[I] + Y[I];
end;

class function TVectorKit.Dot(const A, B: TRealVector): Double;
var
  I: Integer;
  Compensation: Double;
begin
  RequireSameLength(Length(A), Length(B), 'Dot');
  RequireFiniteRealVector(A, 'Dot');
  RequireFiniteRealVector(B, 'Dot');
  Result := 0.0;
  Compensation := 0.0;
  for I := 0 to High(A) do
    AddCompensated(A[I] * B[I], Result, Compensation);
  Result := CompensatedTotal(Result, Compensation);
end;

class function TVectorKit.Sum(const A: TRealVector): Double;
var
  I: Integer;
  Compensation: Double;
begin
  RequireFiniteRealVector(A, 'Sum');
  Result := 0.0;
  Compensation := 0.0;
  for I := 0 to High(A) do
    AddCompensated(A[I], Result, Compensation);
  Result := CompensatedTotal(Result, Compensation);
end;

class function TVectorKit.Mean(const A: TRealVector): Double;
begin
  if Length(A) = 0 then
    raise EVectorError.Create('Mean: vector must not be empty.');
  Result := Sum(A) / Length(A);
end;

class function TVectorKit.Min(const A: TRealVector): Double;
var
  I: Integer;
begin
  RequireFiniteRealVector(A, 'Min');
  if Length(A) = 0 then
    raise EVectorError.Create('Min: vector must not be empty.');
  Result := A[0];
  for I := 1 to High(A) do
    if A[I] < Result then Result := A[I];
end;

class function TVectorKit.Max(const A: TRealVector): Double;
var
  I: Integer;
begin
  RequireFiniteRealVector(A, 'Max');
  if Length(A) = 0 then
    raise EVectorError.Create('Max: vector must not be empty.');
  Result := A[0];
  for I := 1 to High(A) do
    if A[I] > Result then Result := A[I];
end;

class function TVectorKit.Norm2(const A: TRealVector): Double;
var
  I: Integer;
  NormScale, SumSquares: Double;
begin
  RequireFiniteRealVector(A, 'Norm2');
  NormScale := 0.0;
  SumSquares := 0.0;
  for I := 0 to High(A) do
    UpdateScaledSum(A[I], NormScale, SumSquares);
  Result := NormScale * Sqrt(SumSquares);
end;

class function TVectorKit.Normalize(const A: TRealVector): TRealVector;
begin
  Result := nil;
  NormalizeInto(A, Result);
end;

class procedure TVectorKit.NormalizeInto(const A: TRealVector;
  var Destination: TRealVector);
var
  LengthA: Double;
begin
  LengthA := Norm2(A);
  if LengthA = 0.0 then
    raise EVectorError.Create('NormalizeInto: zero vector has no direction.');
  ScaleInto(A, 1.0 / LengthA, Destination);
end;

class function TVectorKit.Add(const A, B: TComplexVector): TComplexVector;
begin
  Result := nil;
  AddInto(A, B, Result);
end;

class procedure TVectorKit.AddInto(const A, B: TComplexVector;
  var Destination: TComplexVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex AddInto');
  RequireFiniteComplexVector(A, 'Complex AddInto');
  RequireFiniteComplexVector(B, 'Complex AddInto');
  PrepareComplexDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] + B[I];
end;

class function TVectorKit.Subtract(const A, B: TComplexVector): TComplexVector;
begin
  Result := nil;
  SubtractInto(A, B, Result);
end;

class procedure TVectorKit.SubtractInto(const A, B: TComplexVector;
  var Destination: TComplexVector);
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex SubtractInto');
  RequireFiniteComplexVector(A, 'Complex SubtractInto');
  RequireFiniteComplexVector(B, 'Complex SubtractInto');
  PrepareComplexDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] - B[I];
end;

class function TVectorKit.Scale(const A: TComplexVector; const Scalar: TComplex): TComplexVector;
begin
  Result := nil;
  ScaleInto(A, Scalar, Result);
end;

class procedure TVectorKit.ScaleInto(const A: TComplexVector;
  const Scalar: TComplex; var Destination: TComplexVector);
var
  I: Integer;
begin
  RequireFiniteComplexVector(A, 'Complex ScaleInto');
  if not Scalar.IsFinite then
    raise EVectorError.Create('Complex ScaleInto: scalar must be finite.');
  PrepareComplexDestination(A, Destination);
  for I := 0 to High(A) do
    Destination[I] := A[I] * Scalar;
end;

class function TVectorKit.Axpy(const Alpha: TComplex; const X, Y: TComplexVector): TComplexVector;
begin
  Result := nil;
  AxpyInto(Alpha, X, Y, Result);
end;

class procedure TVectorKit.AxpyInto(const Alpha: TComplex; const X,
  Y: TComplexVector; var Destination: TComplexVector);
var
  I: Integer;
begin
  RequireSameLength(Length(X), Length(Y), 'Complex AxpyInto');
  RequireFiniteComplexVector(X, 'Complex AxpyInto');
  RequireFiniteComplexVector(Y, 'Complex AxpyInto');
  if not Alpha.IsFinite then
    raise EVectorError.Create('Complex AxpyInto: scalar must be finite.');
  PrepareComplexDestination(X, Destination);
  for I := 0 to High(X) do
    Destination[I] := Alpha * X[I] + Y[I];
end;

class function TVectorKit.Dot(const A, B: TComplexVector): TComplex;
var
  I: Integer;
  SumRe, SumIm, CompensationRe, CompensationIm: Double;
  Product: TComplex;
begin
  RequireSameLength(Length(A), Length(B), 'Complex Dot');
  RequireFiniteComplexVector(A, 'Complex Dot');
  RequireFiniteComplexVector(B, 'Complex Dot');
  SumRe := 0.0;
  SumIm := 0.0;
  CompensationRe := 0.0;
  CompensationIm := 0.0;
  for I := 0 to High(A) do
  begin
    Product := A[I] * B[I];
    AddCompensated(Product.Re, SumRe, CompensationRe);
    AddCompensated(Product.Im, SumIm, CompensationIm);
  end;
  Result := TComplex.Create(CompensatedTotal(SumRe, CompensationRe),
    CompensatedTotal(SumIm, CompensationIm));
end;

class function TVectorKit.DotConjugate(const A, B: TComplexVector): TComplex;
var
  I: Integer;
  SumRe, SumIm, CompensationRe, CompensationIm: Double;
  Product: TComplex;
begin
  RequireSameLength(Length(A), Length(B), 'Complex DotConjugate');
  RequireFiniteComplexVector(A, 'Complex DotConjugate');
  RequireFiniteComplexVector(B, 'Complex DotConjugate');
  SumRe := 0.0;
  SumIm := 0.0;
  CompensationRe := 0.0;
  CompensationIm := 0.0;
  for I := 0 to High(A) do
  begin
    Product := A[I].Conjugate * B[I];
    AddCompensated(Product.Re, SumRe, CompensationRe);
    AddCompensated(Product.Im, SumIm, CompensationIm);
  end;
  Result := TComplex.Create(CompensatedTotal(SumRe, CompensationRe),
    CompensatedTotal(SumIm, CompensationIm));
end;

class function TVectorKit.Norm2(const A: TComplexVector): Double;
var
  I: Integer;
  NormScale, SumSquares: Double;
begin
  RequireFiniteComplexVector(A, 'Complex Norm2');
  NormScale := 0.0;
  SumSquares := 0.0;
  for I := 0 to High(A) do
  begin
    UpdateScaledSum(A[I].Re, NormScale, SumSquares);
    UpdateScaledSum(A[I].Im, NormScale, SumSquares);
  end;
  Result := NormScale * Sqrt(SumSquares);
end;

class function TVectorKit.Normalize(const A: TComplexVector): TComplexVector;
begin
  Result := nil;
  NormalizeInto(A, Result);
end;

class procedure TVectorKit.NormalizeInto(const A: TComplexVector;
  var Destination: TComplexVector);
var
  LengthA: Double;
begin
  LengthA := Norm2(A);
  if LengthA = 0.0 then
    raise EVectorError.Create('Complex NormalizeInto: zero vector has no direction.');
  ScaleInto(A, TComplex.Create(1.0 / LengthA, 0.0), Destination);
end;

end.
