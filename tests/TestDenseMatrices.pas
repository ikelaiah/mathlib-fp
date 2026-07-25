unit TestDenseMatrices;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex, AlgebraLib.Matrices,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels,
  AlgebraLib.DenseSolvers;

type
  TDenseMatrixTest = class(TTestCase)
  published
    procedure TestStorageViewsCopiesAndConversions;
    procedure TestCheckedShapes;
    procedure TestDoubleKernelsAndAliasing;
    procedure TestSingleAndComplexOperationParity;
    procedure TestEmptyOddAndExtremeMultiply;
    procedure TestLUSolveAndReuse;
    procedure TestSingleAndComplexSolve;
    procedure TestCholesky;
    procedure TestValidationLeavesDestinationUnchanged;
    procedure TestSmallAllocationFreeExpressions;
  end;

implementation

function SquareDouble(const Value: Double): Double;
begin
  Result := Value * Value;
end;

function FailOnTwo(const Value: Double): Double;
begin
  if Value = 2.0 then
    raise Exception.Create('deliberate callback failure');
  Result := Value;
end;

procedure TDenseMatrixTest.TestStorageViewsCopiesAndConversions;
var
  A, CopyValue, Sub, Row, Col, Diagonal, RoundTrip: IDenseDoubleMatrix;
  SingleValue: IDenseSingleMatrix;
  ComplexValue: IDenseComplexMatrix;
  VectorValue: TDoubleArray;
  Legacy: IMatrix;
begin
  A := TDenseDoubleMatrix.FromValues(3, 4,
    [1.0, 2.0, 3.0, 4.0,
     5.0, 6.0, 7.0, 8.0,
     9.0, 10.0, 11.0, 12.0]);
  AssertTrue('owned storage is contiguous', A.IsContiguous);
  AssertTrue('owned storage is 32-byte aligned',
    (PtrUInt(A.DataPointer) mod DENSE_ALIGNMENT) = 0);

  Sub := A.View(1, 1, 2, 2);
  AssertFalse('rectangular subview is strided', Sub.IsContiguous);
  AssertTrue('strided data pointer is hidden', Sub.DataPointer = nil);
  Sub[0, 0] := 60.0;
  AssertEquals('view aliases retained owner', 60.0, A[1, 1], 0.0);

  CopyValue := A.Clone;
  CopyValue[1, 1] := -6.0;
  AssertEquals('clone is deep copy', 60.0, A[1, 1], 0.0);

  Row := A.RowView(0);
  Col := A.ColumnView(2);
  Diagonal := A.DiagonalView;
  AssertEquals('row shape', 4, Row.Cols);
  AssertEquals('column shape', 3, Col.Rows);
  AssertEquals('diagonal length', 3, Diagonal.Rows);
  AssertEquals('diagonal value', 11.0, Diagonal[2, 0], 0.0);

  Legacy := ToIMatrix(A);
  RoundTrip := TDenseDoubleMatrix.FromIMatrix(Legacy);
  AssertEquals('legacy round trip rows', A.Rows, RoundTrip.Rows);
  AssertEquals('legacy round trip value', 12.0, RoundTrip[2, 3], 0.0);
  Legacy[2, 3] := 99.0;
  AssertEquals('conversion copy is explicit and independent',
    12.0, RoundTrip[2, 3], 0.0);

  VectorValue := ToVector(Row);
  AssertEquals('vector conversion length', 4, Length(VectorValue));
  AssertEquals('vector conversion value', 4.0, VectorValue[3], 0.0);
  SingleValue := ConvertToSingle(
    TDenseDoubleMatrix.FromValues(1, 1, [1.25]));
  AssertEquals('explicit single conversion', 1.25, SingleValue[0, 0], 0.0);
  ComplexValue := ConvertToComplex(
    TDenseDoubleMatrix.FromValues(1, 1, [2.5]));
  AssertEquals('real to complex', 2.5, ComplexValue[0, 0].Re, 0.0);
  AssertEquals('complex to real',
    2.5, ConvertToReal(ComplexValue)[0, 0], 0.0);
end;

procedure TDenseMatrixTest.TestCheckedShapes;
var
  Failed: Boolean;
  A: IDenseDoubleMatrix;
  S: IDenseSingleMatrix;
  R: IDenseDoubleMatrix;
begin
  Failed := False;
  try
    A := TDenseDoubleMatrix.Zeros(-1, 2);
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('negative dimension rejected', Failed);

  Failed := False;
  try
    A := TDenseDoubleMatrix.Zeros(High(SizeInt), 2);
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('native-size multiplication overflow rejected', Failed);

  Failed := False;
  try
    A := TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0]);
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('shape/value mismatch rejected', Failed);

  Failed := False;
  try
    S := ConvertToSingle(
      TDenseDoubleMatrix.FromValues(1, 1, [Double(MaxSingle) * 2.0]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('out-of-range narrowing rejected', Failed);

  Failed := False;
  try
    R := ConvertToReal(TDenseComplexMatrix.FromValues(1, 1,
      [TComplex.Create(1.0, 1.0)]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('imaginary component is never silently discarded', Failed);
end;

procedure TDenseMatrixTest.TestDoubleKernelsAndAliasing;
var
  A, B, C, Destination, Base, Source, Shifted, Zero: IDenseDoubleMatrix;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0, 4.0]);
  B := TDenseDoubleMatrix.FromValues(2, 2, [5.0, 6.0, 7.0, 8.0]);
  C := Add(A, B);
  AssertEquals('add', 10.0, C[1, 0], 0.0);
  C := Subtract(B, A);
  AssertEquals('subtract', 4.0, C[0, 1], 0.0);
  C := ElementWiseMultiply(A, B);
  AssertEquals('Hadamard', 32.0, C[1, 1], 0.0);
  C := Scale(A, 0.5);
  AssertEquals('scale', 1.5, C[1, 0], 0.0);
  C := Axpy(2.0, A, B);
  AssertEquals('AXPY', 16.0, C[1, 1], 0.0);
  AssertEquals('compensated sum', 10.0, Sum(A), 0.0);
  AssertEquals('scale-safe matrix norm', Sqrt(30.0), Norm2(A), 1E-15);
  C := Apply(A, @SquareDouble);
  AssertEquals('shared unary apply kernel', 16.0, C[1, 1], 0.0);
  C := Transpose(A);
  AssertEquals('transpose', 3.0, C[0, 1], 0.0);

  Base := TDenseDoubleMatrix.FromValues(1, 4, [1.0, 2.0, 3.0, 4.0]);
  Source := Base.View(0, 0, 1, 3);
  Shifted := Base.View(0, 1, 1, 3);
  CopyInto(Source, Shifted);
  AssertEquals('shifted CopyInto alias [2]', 2.0, Base[0, 2], 0.0);
  AssertEquals('shifted CopyInto alias [3]', 3.0, Base[0, 3], 0.0);

  Base := TDenseDoubleMatrix.FromValues(1, 4, [1.0, 2.0, 3.0, 4.0]);
  Source := Base.View(0, 0, 1, 3);
  Shifted := Base.View(0, 1, 1, 3);
  Zero := TDenseDoubleMatrix.Zeros(1, 3);
  AddInto(Source, Zero, Shifted);
  AssertEquals('shifted AddInto alias [2]', 2.0, Base[0, 2], 0.0);
  AssertEquals('shifted AddInto alias [3]', 3.0, Base[0, 3], 0.0);

  Base := TDenseDoubleMatrix.FromValues(1, 4, [1.0, 2.0, 3.0, 4.0]);
  Source := Base.View(0, 0, 1, 3);
  Shifted := Base.View(0, 1, 1, 3);
  ScaleInto(Source, Shifted, 2.0);
  AssertEquals('shifted ScaleInto alias [2]', 4.0, Base[0, 2], 0.0);
  AssertEquals('shifted ScaleInto alias [3]', 6.0, Base[0, 3], 0.0);

  Base := TDenseDoubleMatrix.FromValues(1, 4, [1.0, 2.0, 3.0, 4.0]);
  Source := Base.View(0, 0, 1, 3);
  Shifted := Base.View(0, 1, 1, 3);
  AxpyInto(2.0, Source, Zero, Shifted);
  AssertEquals('shifted AxpyInto alias [2]', 4.0, Base[0, 2], 0.0);
  AssertEquals('shifted AxpyInto alias [3]', 6.0, Base[0, 3], 0.0);

  Base := TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0, 4.0]);
  TransposeInto(Base, Base);
  AssertEquals('in-place transpose alias [0,1]', 3.0, Base[0, 1], 0.0);
  AssertEquals('in-place transpose alias [1,0]', 2.0, Base[1, 0], 0.0);

  Destination := A;
  MultiplyInto(A, B, Destination);
  AssertEquals('multiply alias [0,0]', 19.0, Destination[0, 0], 0.0);
  AssertEquals('multiply alias [1,1]', 50.0, Destination[1, 1], 0.0);
end;

procedure TDenseMatrixTest.TestSingleAndComplexOperationParity;
var
  S1, S2, S3: IDenseSingleMatrix;
  C1, C2, C3: IDenseComplexMatrix;
  SC1, SC2, SC3: IDenseSingleComplexMatrix;
begin
  S1 := TDenseSingleMatrix.FromValues(1, 2, [1.0, 2.0]);
  S2 := TDenseSingleMatrix.FromValues(2, 1, [3.0, 4.0]);
  S3 := Multiply(S1, S2);
  AssertEquals('single multiply', 11.0, S3[0, 0], 1E-6);
  AssertEquals('single row/column dot', 11.0, Dot(S1, S2), 1E-6);

  C1 := TDenseComplexMatrix.FromValues(1, 2,
    [TComplex.Create(1, 1), TComplex.Create(2, -1)]);
  C2 := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(3, 0), TComplex.Create(0, 2)]);
  C3 := Multiply(C1, C2);
  AssertEquals('complex multiply real', 5.0, C3[0, 0].Re, 1E-14);
  AssertEquals('complex multiply imag', 7.0, C3[0, 0].Im, 1E-14);
  C3 := ConjugateTranspose(C1);
  AssertEquals('complex conjugate transpose rows', 2, C3.Rows);
  AssertEquals('complex conjugate transpose imag',
    -1.0, C3[0, 0].Im, 0.0);
  C3 := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(1, 1), TComplex.Create(2, -1),
     TComplex.Create(3, 2), TComplex.Create(4, -2)]);
  ConjugateTransposeInto(C3, C3);
  AssertEquals('in-place conjugate transpose real',
    3.0, C3[0, 1].Re, 0.0);
  AssertEquals('in-place conjugate transpose imag',
    -2.0, C3[0, 1].Im, 0.0);

  SC1 := TDenseSingleComplexMatrix.FromValues(1, 1,
    [TSingleComplex.Create(1, 2)]);
  SC2 := TDenseSingleComplexMatrix.FromValues(1, 1,
    [TSingleComplex.Create(3, -1)]);
  SC3 := Add(SC1, SC2);
  AssertEquals('single complex add real', 4.0, SC3[0, 0].Re, 1E-6);
  AssertEquals('single complex add imag', 1.0, SC3[0, 0].Im, 1E-6);
end;

procedure TDenseMatrixTest.TestEmptyOddAndExtremeMultiply;
var
  EmptyA, EmptyB, EmptyC, A, B, C: IDenseDoubleMatrix;
begin
  EmptyA := TDenseDoubleMatrix.Zeros(0, 3);
  EmptyB := TDenseDoubleMatrix.Zeros(3, 2);
  EmptyC := Multiply(EmptyA, EmptyB);
  AssertEquals('empty product rows', 0, EmptyC.Rows);
  AssertEquals('empty product columns preserved', 2, EmptyC.Cols);

  A := TDenseDoubleMatrix.FromValues(3, 5,
    [1.0, 2.0, 3.0, 4.0, 5.0,
     6.0, 7.0, 8.0, 9.0, 10.0,
     11.0, 12.0, 13.0, 14.0, 15.0]);
  B := TDenseDoubleMatrix.FromValues(5, 1,
    [1.0, -1.0, 1.0, -1.0, 1.0]);
  C := Multiply(A, B);
  AssertEquals('odd shape row 0', 3.0, C[0, 0], 0.0);
  AssertEquals('odd shape row 2', 13.0, C[2, 0], 0.0);

  A := TDenseDoubleMatrix.FromValues(1, 2, [1E200, 1E-200]);
  B := TDenseDoubleMatrix.FromValues(2, 1, [1E-200, 1E200]);
  C := Multiply(A, B);
  AssertEquals('mixed extreme scales remain representable', 2.0, C[0, 0],
    1E-15);
end;

procedure TDenseMatrixTest.TestLUSolveAndReuse;
var
  A, B, X, AX, MultiB, MultiX: IDenseDoubleMatrix;
  Factor: IDenseDoubleLU;
  Residual, ScaleValue: Double;
begin
  A := TDenseDoubleMatrix.FromValues(3, 3,
    [3.0, 2.0, -1.0,
     2.0, -2.0, 4.0,
     -1.0, 0.5, -1.0]);
  B := TDenseDoubleMatrix.FromValues(3, 1, [1.0, -2.0, 0.0]);
  X := Solve(A, B);
  AssertEquals('solve x0', 1.0, X[0, 0], 1E-13);
  AssertEquals('solve x1', -2.0, X[1, 0], 1E-13);
  AssertEquals('solve x2', -2.0, X[2, 0], 1E-13);

  AX := Multiply(A, X);
  Residual := Max(Max(Abs(AX[0, 0] - B[0, 0]),
    Abs(AX[1, 0] - B[1, 0])), Abs(AX[2, 0] - B[2, 0]));
  ScaleValue := 4.0 * 2.0 + 2.0;
  AssertTrue('published backward-error style residual',
    Residual / ScaleValue < 1E-14);

  Factor := FactorLU(A);
  MultiB := TDenseDoubleMatrix.FromValues(3, 2,
    [1.0, 2.0, -2.0, -4.0, 0.0, 0.0]);
  MultiX := Factor.Solve(MultiB);
  AssertEquals('factor reuse rhs 1', 1.0, MultiX[0, 0], 1E-13);
  AssertEquals('factor reuse rhs 2', 2.0, MultiX[0, 1], 1E-13);
  AssertTrue('factor diagnostic is finite', Factor.PivotRatio > 0.0);
end;

procedure TDenseMatrixTest.TestSingleAndComplexSolve;
var
  SA, SB, SX: IDenseSingleMatrix;
  CA, CB, CX: IDenseComplexMatrix;
  SCA, SCB, SCX: IDenseSingleComplexMatrix;
begin
  SA := TDenseSingleMatrix.FromValues(2, 2, [4.0, 1.0, 2.0, 3.0]);
  SB := TDenseSingleMatrix.FromValues(2, 1, [9.0, 8.0]);
  SX := Solve(SA, SB);
  AssertEquals('single solve x0', 1.9, SX[0, 0], 2E-6);
  AssertEquals('single solve x1', 1.4, SX[1, 0], 2E-6);

  CA := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(2, 1), TComplex.Create(1, 0),
     TComplex.Create(0, 0), TComplex.Create(1, -1)]);
  CB := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(4, 1), TComplex.Create(1, -1)]);
  CX := Solve(CA, CB);
  AssertEquals('complex solve x0 real', 1.4, CX[0, 0].Re, 1E-14);
  AssertEquals('complex solve x0 imag', -0.2, CX[0, 0].Im, 1E-14);
  AssertEquals('complex solve x1 real', 1.0, CX[1, 0].Re, 1E-14);

  SCA := TDenseSingleComplexMatrix.FromValues(1, 1,
    [TSingleComplex.Create(2, -1)]);
  SCB := TDenseSingleComplexMatrix.FromValues(1, 1,
    [TSingleComplex.Create(5, 0)]);
  SCX := Solve(SCA, SCB);
  AssertEquals('single-complex solve real', 2.0, SCX[0, 0].Re, 2E-6);
  AssertEquals('single-complex solve imag', 1.0, SCX[0, 0].Im, 2E-6);
end;

procedure TDenseMatrixTest.TestCholesky;
var
  A, B, X: IDenseDoubleMatrix;
  C, CB, CX: IDenseComplexMatrix;
  Factor: IDenseDoubleCholesky;
begin
  A := TDenseDoubleMatrix.FromValues(3, 3,
    [4.0, 12.0, -16.0,
     12.0, 37.0, -43.0,
     -16.0, -43.0, 98.0]);
  Factor := FactorCholesky(A);
  AssertEquals('Cholesky L00', 2.0, Factor.L[0, 0], 1E-14);
  B := TDenseDoubleMatrix.FromValues(3, 1, [4.0, 6.0, 10.0]);
  X := Factor.Solve(B);
  AssertEquals('Cholesky residual row 0', B[0, 0],
    Multiply(A, X)[0, 0], 1E-12);

  C := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(4, 0), TComplex.Create(1, 1),
     TComplex.Create(1, -1), TComplex.Create(3, 0)]);
  CB := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(1, 0), TComplex.Create(2, -1)]);
  CX := FactorCholesky(C).Solve(CB);
  AssertEquals('complex Cholesky residual real', CB[1, 0].Re,
    Multiply(C, CX)[1, 0].Re, 1E-13);
  AssertEquals('complex Cholesky residual imag', CB[1, 0].Im,
    Multiply(C, CX)[1, 0].Im, 1E-13);

  A := TDenseDoubleMatrix.FromValues(1, 1, [1E-200]);
  AssertEquals('scale-relative Cholesky accepts tiny SPD matrix', 1E-100,
    FactorCholesky(A).L[0, 0], 1E-115);
end;

procedure TDenseMatrixTest.TestValidationLeavesDestinationUnchanged;
var
  A, B, Destination, Singular, IllConditioned: IDenseDoubleMatrix;
  Failed: Boolean;
begin
  A := TDenseDoubleMatrix.FromValues(1, 2, [1.0, 2.0]);
  B := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 3.0]);
  Destination := TDenseDoubleMatrix.FromValues(1, 1, [42.0]);
  Failed := False;
  try
    MultiplyInto(A, B, Destination);
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('invalid multiply rejected', Failed);
  AssertEquals('destination unchanged on validation failure',
    42.0, Destination[0, 0], 0.0);

  Destination := TDenseDoubleMatrix.FromValues(1, 2, [42.0, 43.0]);
  Failed := False;
  try
    ApplyInto(A, Destination, @FailOnTwo);
  except
    on Exception do Failed := True;
  end;
  AssertTrue('callback failure propagated', Failed);
  AssertEquals('callback failure leaves destination unchanged',
    43.0, Destination[0, 1], 0.0);

  Singular := TDenseDoubleMatrix.FromValues(2, 2,
    [1.0, 2.0, 2.0, 4.0]);
  Failed := False;
  try
    Solve(Singular, TDenseDoubleMatrix.FromValues(2, 1, [1.0, 2.0]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('singularity reported', Failed);

  IllConditioned := TDenseDoubleMatrix.FromValues(2, 2,
    [1.0, 0.0, 0.0, 1E-10]);
  Failed := False;
  try
    Solve(IllConditioned,
      TDenseDoubleMatrix.FromValues(2, 1, [1.0, 1E-10]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('simple Solve reports ill-conditioning', Failed);
  AssertTrue('reusable factor exposes ill-conditioning',
    FactorLU(IllConditioned).IsIllConditioned);
end;

procedure TDenseMatrixTest.TestSmallAllocationFreeExpressions;
var
  A, B, C: TSmallDoubleMatrix2;
  Z, W: TSmallComplexMatrix2;
  Batch: TSmallDoubleMatrix2Batch;
begin
  A := TSmallDoubleMatrix2.Create(1.0, 2.0, 3.0, 4.0);
  B := TSmallDoubleMatrix2.Create(5.0, 6.0, 7.0, 8.0);
  C := 0.5 * (A * B + A - A);
  AssertEquals('small expression [0,0]', 9.5, C[0, 0], 0.0);
  AssertEquals('small expression [1,1]', 25.0, C[1, 1], 0.0);
  SetLength(Batch, 2);
  Batch[0] := A;
  Batch[1] := B;
  AssertEquals('small batch keeps value records',
    8.0, Batch[1].Values[1, 1], 0.0);

  Z := TSmallComplexMatrix2.Create(TComplex.One, TComplex.Zero,
    TComplex.Zero, TComplex.Create(0.0, 1.0));
  W := Z * Z;
  AssertEquals('small complex product real', -1.0, W[1, 1].Re, 0.0);
  AssertEquals('small complex product imag', 0.0, W[1, 1].Im, 0.0);
end;

initialization
  RegisterTest(TDenseMatrixTest);

end.
