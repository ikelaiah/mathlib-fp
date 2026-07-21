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
    class function Subtract(const A, B: TRealVector): TRealVector; static;
    class function Scale(const A: TRealVector; const Scalar: Double): TRealVector; static;
    class function Axpy(const Alpha: Double; const X, Y: TRealVector): TRealVector; static;
    class function Dot(const A, B: TRealVector): Double; static;
    class function Norm2(const A: TRealVector): Double; static;
    class function Normalize(const A: TRealVector): TRealVector; static;

    class function Add(const A, B: TComplexVector): TComplexVector; static;
    class function Subtract(const A, B: TComplexVector): TComplexVector; static;
    class function Scale(const A: TComplexVector; const Scalar: TComplex): TComplexVector; static;
    class function Axpy(const Alpha: TComplex; const X, Y: TComplexVector): TComplexVector; static;
    class function Dot(const A, B: TComplexVector): TComplex; static;
    class function DotConjugate(const A, B: TComplexVector): TComplex; static;
    class function Norm2(const A: TComplexVector): Double; static;
    class function Normalize(const A: TComplexVector): TComplexVector; static;
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

class function TVectorKit.Add(const A, B: TRealVector): TRealVector;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Add');
  RequireFiniteRealVector(A, 'Add');
  RequireFiniteRealVector(B, 'Add');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] + B[I];
end;

class function TVectorKit.Subtract(const A, B: TRealVector): TRealVector;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Subtract');
  RequireFiniteRealVector(A, 'Subtract');
  RequireFiniteRealVector(B, 'Subtract');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] - B[I];
end;

class function TVectorKit.Scale(const A: TRealVector; const Scalar: Double): TRealVector;
var
  I: Integer;
begin
  RequireFiniteRealVector(A, 'Scale');
  if IsNan(Scalar) or IsInfinite(Scalar) then
    raise EVectorError.Create('Scale: scalar must be finite.');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] * Scalar;
end;

class function TVectorKit.Axpy(const Alpha: Double; const X, Y: TRealVector): TRealVector;
var
  I: Integer;
begin
  RequireSameLength(Length(X), Length(Y), 'Axpy');
  RequireFiniteRealVector(X, 'Axpy');
  RequireFiniteRealVector(Y, 'Axpy');
  if IsNan(Alpha) or IsInfinite(Alpha) then
    raise EVectorError.Create('Axpy: scalar must be finite.');
  Result := nil;
  SetLength(Result, Length(X));
  for I := 0 to High(X) do
    Result[I] := Alpha * X[I] + Y[I];
end;

class function TVectorKit.Dot(const A, B: TRealVector): Double;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Dot');
  RequireFiniteRealVector(A, 'Dot');
  RequireFiniteRealVector(B, 'Dot');
  Result := 0.0;
  for I := 0 to High(A) do
    Result := Result + A[I] * B[I];
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
var
  LengthA: Double;
begin
  LengthA := Norm2(A);
  if LengthA = 0.0 then
    raise EVectorError.Create('Normalize: zero vector has no direction.');
  Result := Scale(A, 1.0 / LengthA);
end;

class function TVectorKit.Add(const A, B: TComplexVector): TComplexVector;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex Add');
  RequireFiniteComplexVector(A, 'Complex Add');
  RequireFiniteComplexVector(B, 'Complex Add');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] + B[I];
end;

class function TVectorKit.Subtract(const A, B: TComplexVector): TComplexVector;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex Subtract');
  RequireFiniteComplexVector(A, 'Complex Subtract');
  RequireFiniteComplexVector(B, 'Complex Subtract');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] - B[I];
end;

class function TVectorKit.Scale(const A: TComplexVector; const Scalar: TComplex): TComplexVector;
var
  I: Integer;
begin
  RequireFiniteComplexVector(A, 'Complex Scale');
  if not Scalar.IsFinite then
    raise EVectorError.Create('Complex Scale: scalar must be finite.');
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] * Scalar;
end;

class function TVectorKit.Axpy(const Alpha: TComplex; const X, Y: TComplexVector): TComplexVector;
var
  I: Integer;
begin
  RequireSameLength(Length(X), Length(Y), 'Complex Axpy');
  RequireFiniteComplexVector(X, 'Complex Axpy');
  RequireFiniteComplexVector(Y, 'Complex Axpy');
  if not Alpha.IsFinite then
    raise EVectorError.Create('Complex Axpy: scalar must be finite.');
  Result := nil;
  SetLength(Result, Length(X));
  for I := 0 to High(X) do
    Result[I] := Alpha * X[I] + Y[I];
end;

class function TVectorKit.Dot(const A, B: TComplexVector): TComplex;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex Dot');
  RequireFiniteComplexVector(A, 'Complex Dot');
  RequireFiniteComplexVector(B, 'Complex Dot');
  Result := TComplex.Zero;
  for I := 0 to High(A) do
    Result := Result + A[I] * B[I];
end;

class function TVectorKit.DotConjugate(const A, B: TComplexVector): TComplex;
var
  I: Integer;
begin
  RequireSameLength(Length(A), Length(B), 'Complex DotConjugate');
  RequireFiniteComplexVector(A, 'Complex DotConjugate');
  RequireFiniteComplexVector(B, 'Complex DotConjugate');
  Result := TComplex.Zero;
  for I := 0 to High(A) do
    Result := Result + A[I].Conjugate * B[I];
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
var
  LengthA: Double;
begin
  LengthA := Norm2(A);
  if LengthA = 0.0 then
    raise EVectorError.Create('Complex Normalize: zero vector has no direction.');
  Result := Scale(A, TComplex.Create(1.0 / LengthA, 0.0));
end;

end.
