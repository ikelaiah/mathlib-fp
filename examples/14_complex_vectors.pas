program ComplexVectors;

{-----------------------------------------------------------------------------
  14_complex_vectors.pas

  Introduces the v1.3 complex and contiguous-array vector foundation. The
  established IMatrix vector API remains available; this example demonstrates
  the complementary TRealVector / TComplexVector kernels for numeric arrays.

  Build from examples/:
    fpc -Fu../src -FUlib 14_complex_vectors.pas
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils, Math,
  MathBase.Complex,
  AlgebraLib.Vectors,
  EngineeringLib.Signal;

var
  Z, W: TComplex;
  RealA, RealB, Products, Workspace: TRealVector;
  ComplexA, ComplexData: TComplexVector;
  I: Integer;

procedure WriteComplex(const LabelText: string; const Value: TComplex);
begin
  Write(LabelText, Value.Re:0:3);
  if Value.Im < 0.0 then
    Write(' - ', -Value.Im:0:3)
  else
    Write(' + ', Value.Im:0:3);
  WriteLn('i');
end;

begin
  { TComplex is a value record with overloaded arithmetic. }
  Z := TComplex.Create(3.0, 4.0);
  W := CSqrt(TComplex.Create(-4.0, 0.0));
  WriteLn('z magnitude = ', Z.Magnitude:0:3);
  WriteComplex('sqrt(-4) = ', W);
  WriteComplex('asinh(1 + 2i) = ', CAsinh(TComplex.Create(1.0, 2.0)));
  WriteComplex('atan(1 + 2i) = ', CAtan(TComplex.Create(1.0, 2.0)));

  { Array-vector kernels complement, rather than replace, IMatrix vectors. }
  RealA := TRealVector.Create(3.0, 4.0);
  RealB := TRealVector.Create(1.0, -2.0);
  WriteLn('a dot b = ', TVectorKit.Dot(RealA, RealB):0:3);
  WriteLn('||a|| = ', TVectorKit.Norm2(RealA):0:3);
  Products := TVectorKit.ElementWiseMultiply(RealA, RealB);
  WriteLn('a .* b = [', Products[0]:0:3, ', ', Products[1]:0:3, ']');

  { ...Into writes into caller-owned storage. Reuse Workspace in hot loops
    to avoid allocating a new result array for every operation. }
  SetLength(Workspace, Length(RealA));
  TVectorKit.AxpyInto(2.0, RealA, RealB, Workspace); { 2*a + b }
  WriteLn('2*a + b = [', Workspace[0]:0:3, ', ', Workspace[1]:0:3, ']');
  WriteLn('mean(2*a + b) = ', TVectorKit.Mean(Workspace):0:3);

  ComplexA := TComplexVector.Create(
    TComplex.Create(1.0, 1.0), TComplex.Create(2.0, 0.0));
  WriteComplex('conjugate dot(a, a) = ',
    TVectorKit.DotConjugate(ComplexA, ComplexA));

  { Complex FFT works in place. The length must be a power of two. }
  ComplexData := TComplexVector.Create(
    TComplex.Create(1.0, 0.0), TComplex.Zero,
    TComplex.Zero, TComplex.Zero);
  TSignalKit.FFT(ComplexData);
  WriteLn('FFT of an impulse:');
  for I := 0 to High(ComplexData) do
    WriteComplex('  X[' + IntToStr(I) + '] = ', ComplexData[I]);

  { The same buffer can be transformed back in place. }
  TSignalKit.FFT(ComplexData, True);
  WriteLn('IFFT restores [', ComplexData[0].Re:0:3, ', ',
    ComplexData[1].Re:0:3, ', ', ComplexData[2].Re:0:3, ', ',
    ComplexData[3].Re:0:3, ']');
end.
