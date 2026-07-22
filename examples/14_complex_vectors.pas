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
  Math,
  MathBase.Complex,
  AlgebraLib.Vectors,
  EngineeringLib.Signal;

var
  Z, W: TComplex;
  RealA, RealB: TRealVector;
  ComplexData: TComplexVector;
  I: Integer;

begin
  { TComplex is a value record with overloaded arithmetic. }
  Z := TComplex.Create(3.0, 4.0);
  W := CSqrt(TComplex.Create(-4.0, 0.0));
  WriteLn('z magnitude = ', Z.Magnitude:0:3);
  WriteLn('sqrt(-4) = ', W.Re:0:3, ' + ', W.Im:0:3, 'i');

  { Array-vector kernels complement, rather than replace, IMatrix vectors. }
  RealA := TRealVector.Create(3.0, 4.0);
  RealB := TRealVector.Create(1.0, -2.0);
  WriteLn('a dot b = ', TVectorKit.Dot(RealA, RealB):0:3);
  WriteLn('||a|| = ', TVectorKit.Norm2(RealA):0:3);

  { Complex FFT works in place. The length must be a power of two. }
  ComplexData := TComplexVector.Create(
    TComplex.Create(1.0, 0.0), TComplex.Zero,
    TComplex.Zero, TComplex.Zero);
  TSignalKit.FFT(ComplexData);
  WriteLn('FFT of an impulse:');
  for I := 0 to High(ComplexData) do
    WriteLn('  X[', I, '] = ', ComplexData[I].Re:0:3, ' + ',
      ComplexData[I].Im:0:3, 'i');
end.
