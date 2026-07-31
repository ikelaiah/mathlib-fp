unit TestSparseMatrices;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices;

type
  TSparseMatrixTest = class(TTestCase)
  published
    procedure TestCanonicalCSRCSCAndTriplets;
    procedure TestValidationAndFailureAtomicBuilder;
    procedure TestArithmeticAndDenseProducts;
    procedure TestScalarParity;
    procedure TestStructuredStorageAndProducts;
  end;

implementation

procedure TSparseMatrixTest.TestCanonicalCSRCSCAndTriplets;
var
  Builder: TSparseDoubleTripletBuilder;
  A, C: ISparseDoubleMatrix;
begin
  Builder := TSparseDoubleTripletBuilder.Create(3, 4);
  try
    Builder.Add(2, 1, 4.0);
    Builder.Add(0, 3, 2.0);
    Builder.Add(2, 1, -1.0);
    Builder.Add(1, 0, 5.0);
    A := Builder.ToCSR;
    C := Builder.ToCSC;
    AssertEquals('triplet contribution count retained', 4, Builder.Count);
  finally
    Builder.Free;
  end;

  AssertEquals('CSR rows', 3, A.Rows);
  AssertEquals('CSR columns', 4, A.Cols);
  AssertEquals('duplicates combined', 3, A.NonZeroCount);
  AssertEquals('combined value', 3.0, A[2, 1], 0.0);
  AssertEquals('implicit zero', 0.0, A[0, 0], 0.0);
  AssertEquals('first row pointer', 0, A.GetOuterPointer(0));
  AssertEquals('last row pointer', 3, A.GetOuterPointer(3));
  AssertEquals('CSC format', Ord(sfCSC), Ord(C.Format));
  AssertEquals('CSC round-trip value', 5.0, C[1, 0], 0.0);

  C := TSparseDoubleMatrix.Convert(C, sfCSR);
  AssertEquals('format conversion', Ord(sfCSR), Ord(C.Format));
  AssertEquals('format conversion value', 2.0, C[0, 3], 0.0);
end;

procedure TSparseMatrixTest.TestValidationAndFailureAtomicBuilder;
var
  Builder: TSparseDoubleTripletBuilder;
  A: ISparseDoubleMatrix;
  Failed: Boolean;
  Outer: array[0..2] of SizeInt;
  Inner: array[0..1] of SizeInt;
  Values: array[0..1] of Double;
begin
  Failed := False;
  try
    A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 2, 2],
      [1, 0], [1.0, 2.0]);
  except
    on ESparseMatrixError do Failed := True;
  end;
  AssertTrue('unsorted row rejected', Failed);

  Failed := False;
  try
    A := TSparseDoubleMatrix.FromCSR(1, 1, [0, 1], [0], [0.0], szDrop);
  except
    on ESparseMatrixError do Failed := True;
  end;
  AssertTrue('stored zero policy enforced', Failed);

  Outer[0] := 0; Outer[1] := 1; Outer[2] := 2;
  Inner[0] := 0; Inner[1] := 1;
  Values[0] := 2.0; Values[1] := 3.0;
  A := TSparseDoubleMatrix.FromCSR(2, 2, Outer, Inner, Values);
  Outer[1] := 0;
  Inner[0] := 1;
  Values[0] := 99.0;
  AssertEquals('factory deep-copies caller storage', 2.0, A[0, 0], 0.0);
  AssertEquals('copied canonical indices are immutable', 0, A.GetInnerIndex(0));

  Builder := TSparseDoubleTripletBuilder.Create(2, 2);
  try
    Builder.Add(0, 0, 1.0);
    Failed := False;
    try
      Builder.Add(2, 0, 9.0);
    except
      on ESparseMatrixError do Failed := True;
    end;
    AssertTrue('out-of-range contribution rejected', Failed);
    AssertEquals('failed add leaves builder unchanged', 1, Builder.Count);
    A := Builder.ToCSR;
    AssertEquals('builder reusable after failure', 1.0, A[0, 0], 0.0);
  finally
    Builder.Free;
  end;
end;

procedure TSparseMatrixTest.TestArithmeticAndDenseProducts;
var
  A, B, C: ISparseDoubleMatrix;
  X, Y, Dense: IDenseDoubleMatrix;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 3, 5],
    [0, 2, 1, 0, 2], [2.0, 1.0, 3.0, 4.0, 5.0]);
  B := TSparseDoubleMatrix.FromCSR(3, 3, [0, 1, 2, 3],
    [0, 1, 2], [1.0, 2.0, 3.0]);
  C := TSparseDoubleMatrix.Add(A, B);
  AssertEquals('sparse addition', 5.0, C[1, 1], 0.0);
  C := TSparseDoubleMatrix.Scale(C, 0.5);
  AssertEquals('sparse scaling', 4.0, C[2, 2], 0.0);

  C := TSparseDoubleMatrix.Multiply(A, B);
  AssertEquals('sparse multiply diagonal scale [0,2]',
    3.0, C[0, 2], 0.0);
  AssertEquals('sparse multiply diagonal scale [2,0]',
    4.0, C[2, 0], 0.0);

  X := TDenseDoubleMatrix.FromValues(3, 2,
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
  Y := TDenseDoubleMatrix.Zeros(3, 2);
  TSparseDoubleMatrix.MultiplyDenseInto(A, X, Y);
  AssertEquals('sparse/dense product [0,0]', 7.0, Y[0, 0], 0.0);
  AssertEquals('sparse/dense product [2,1]', 38.0, Y[2, 1], 0.0);

  Dense := TSparseDoubleMatrix.ToDense(A);
  AssertEquals('explicit dense conversion', 4.0, Dense[2, 0], 0.0);
  AssertEquals('row extraction', 5.0,
    TSparseDoubleMatrix.Row(A, 2)[0, 2], 0.0);
  AssertEquals('column extraction', 4.0,
    TSparseDoubleMatrix.Column(A, 0)[2, 0], 0.0);
  AssertEquals('Frobenius norm', Sqrt(55.0),
    TSparseDoubleMatrix.Norm2(A), 1E-14);
end;

procedure TSparseMatrixTest.TestScalarParity;
var
  S: ISparseSingleMatrix;
  D: ISparseDoubleMatrix;
  CS: ISparseSingleComplexMatrix;
  CD, H: ISparseComplexMatrix;
  XS, YS: IDenseSingleMatrix;
  XD, YD: IDenseDoubleMatrix;
  XCS, YCS: IDenseSingleComplexMatrix;
  XCD, YCD: IDenseComplexMatrix;
begin
  S := TSparseSingleMatrix.FromCSR(2, 2, [0, 2, 3],
    [0, 1, 1], [2.0, -1.0, 3.0]);
  D := TSparseDoubleMatrix.FromCSR(2, 2, [0, 2, 3],
    [0, 1, 1], [2.0, -1.0, 3.0]);
  CS := TSparseSingleComplexMatrix.FromCSR(2, 2, [0, 2, 3],
    [0, 1, 1], [TSingleComplex.Create(2, 0),
      TSingleComplex.Create(-1, 1), TSingleComplex.Create(3, 0)]);
  CD := TSparseComplexMatrix.FromCSR(2, 2, [0, 2, 3],
    [0, 1, 1], [TComplex.Create(2, 0),
      TComplex.Create(-1, 1), TComplex.Create(3, 0)]);

  XS := TDenseSingleMatrix.FromValues(2, 1, [1.0, 2.0]);
  XD := TDenseDoubleMatrix.FromValues(2, 1, [1.0, 2.0]);
  XCS := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.One, TSingleComplex.Create(2, 0)]);
  XCD := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.One, TComplex.Create(2, 0)]);
  YS := TDenseSingleMatrix.Zeros(2, 1);
  YD := TDenseDoubleMatrix.Zeros(2, 1);
  YCS := TDenseSingleComplexMatrix.Zeros(2, 1);
  YCD := TDenseComplexMatrix.Zeros(2, 1);
  TSparseSingleMatrix.MultiplyDenseInto(S, XS, YS);
  TSparseDoubleMatrix.MultiplyDenseInto(D, XD, YD);
  TSparseSingleComplexMatrix.MultiplyDenseInto(CS, XCS, YCS);
  TSparseComplexMatrix.MultiplyDenseInto(CD, XCD, YCD);

  AssertEquals('single product', 0.0, YS[0, 0], 1E-6);
  AssertEquals('double product', 0.0, YD[0, 0], 1E-14);
  AssertEquals('single complex real', 0.0, YCS[0, 0].Re, 1E-5);
  AssertEquals('single complex imaginary', 2.0, YCS[0, 0].Im, 1E-5);
  AssertEquals('complex real', 0.0, YCD[0, 0].Re, 1E-14);
  AssertEquals('complex imaginary', 2.0, YCD[0, 0].Im, 1E-14);

  H := TSparseComplexMatrix.ConjugateTranspose(CD);
  AssertEquals('conjugate transpose real', -1.0, H[1, 0].Re, 0.0);
  AssertEquals('conjugate transpose imaginary', -1.0, H[1, 0].Im, 0.0);
end;

procedure TSparseMatrixTest.TestStructuredStorageAndProducts;
var
  T: IStructuredDoubleMatrix;
  B: IStructuredComplexMatrix;
  X, Y: IDenseDoubleMatrix;
  Sparse: ISparseDoubleMatrix;
begin
  T := TStructuredDoubleMatrix.Tridiagonal(
    [-1.0, -1.0], [2.0, 2.0, 2.0], [-1.0, -1.0]);
  AssertEquals('tridiagonal kind', Ord(smTridiagonal), Ord(T.Kind));
  AssertEquals('tridiagonal lower', -1.0, T[2, 1], 0.0);
  AssertEquals('tridiagonal structural zero', 0.0, T[0, 2], 0.0);
  X := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 4.0]);
  Y := TDenseDoubleMatrix.Zeros(3, 1);
  TStructuredDoubleMatrix.MultiplyDenseInto(T, X, Y);
  AssertEquals('tridiagonal product [0]', 0.0, Y[0, 0], 0.0);
  AssertEquals('tridiagonal product [1]', -1.0, Y[1, 0], 0.0);
  AssertEquals('tridiagonal product [2]', 6.0, Y[2, 0], 0.0);
  Sparse := TStructuredDoubleMatrix.ToSparse(T);
  AssertEquals('structured sparse count', 7, Sparse.NonZeroCount);

  B := TStructuredComplexMatrix.Band(2, 3, 0, 1,
    [TComplex.Create(1, 0), TComplex.Create(2, 1),
     TComplex.Create(3, 0), TComplex.Create(4, -1)]);
  AssertEquals('rectangular band', 2.0, B[0, 1].Re, 0.0);
  AssertEquals('rectangular band padding', 0.0, B[1, 0].Re, 0.0);
end;

initialization
  RegisterTest(TSparseMatrixTest);

end.
