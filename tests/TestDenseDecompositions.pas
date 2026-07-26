unit TestDenseDecompositions;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels,
  AlgebraLib.DenseDecompositions, AlgebraLib.DenseSolvers;

type
  TDenseDecompositionTest = class(TTestCase)
  private
    procedure AssertMatrixClose(const MessageText: string;
      const Expected, Actual: IDenseDoubleMatrix; const Tolerance: Double);
    procedure AssertComplexMatrixClose(const MessageText: string;
      const Expected, Actual: IDenseComplexMatrix; const Tolerance: Double);
  published
    procedure TestTriangularOperationVariants;
    procedure TestQRReconstructionLeastSquaresAndReuse;
    procedure TestPivotedQRRankAndPermutation;
    procedure TestSVDTallWideAndMinimumNorm;
    procedure TestComplexQRAndSVD;
    procedure TestSymmetricAndHermitianEigen;
    procedure TestEmptyClusteredAndDifficultScaleCases;
    procedure TestSinglePrecisionParity;
    procedure TestSquareAndPositiveDefiniteDiagnostics;
    procedure TestValidationAndImmutableFactors;
  end;

implementation

procedure TDenseDecompositionTest.AssertMatrixClose(const MessageText: string;
  const Expected, Actual: IDenseDoubleMatrix; const Tolerance: Double);
var
  I, J: SizeInt;
begin
  AssertEquals(MessageText + ' rows', Expected.Rows, Actual.Rows);
  AssertEquals(MessageText + ' columns', Expected.Cols, Actual.Cols);
  for I := 0 to Expected.Rows - 1 do
    for J := 0 to Expected.Cols - 1 do
      AssertEquals(MessageText + Format(' [%d,%d]', [I, J]),
        Expected[I, J], Actual[I, J], Tolerance);
end;

procedure TDenseDecompositionTest.AssertComplexMatrixClose(
  const MessageText: string;
  const Expected, Actual: IDenseComplexMatrix; const Tolerance: Double);
var
  I, J: SizeInt;
begin
  AssertEquals(MessageText + ' rows', Expected.Rows, Actual.Rows);
  AssertEquals(MessageText + ' columns', Expected.Cols, Actual.Cols);
  for I := 0 to Expected.Rows - 1 do
    for J := 0 to Expected.Cols - 1 do
    begin
      AssertEquals(MessageText + Format(' real [%d,%d]', [I, J]),
        Expected[I, J].Re, Actual[I, J].Re, Tolerance);
      AssertEquals(MessageText + Format(' imaginary [%d,%d]', [I, J]),
        Expected[I, J].Im, Actual[I, J].Im, Tolerance);
    end;
end;

function ReconstructSVD(const Factor: IDenseDoubleSVD): IDenseDoubleMatrix;
var
  US: IDenseDoubleMatrix;
  I, J: SizeInt;
  SingularValues: TDoubleArray;
begin
  US := Factor.U;
  SingularValues := Factor.SingularValues;
  for J := 0 to US.Cols - 1 do
    for I := 0 to US.Rows - 1 do
      US[I, J] := US[I, J] * SingularValues[J];
  Result := Multiply(US, Transpose(Factor.V));
end;

procedure TDenseDecompositionTest.TestTriangularOperationVariants;
var
  L, LSelected, U, B, X: IDenseDoubleMatrix;
  C, CB, CX: IDenseComplexMatrix;
begin
  L := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 99.0, 99.0,
     3.0, 1.0, 99.0,
     1.0, -2.0, 4.0]);
  B := TDenseDoubleMatrix.FromValues(3, 2,
    [2.0, 4.0, 5.0, 7.0, 9.0, 13.0]);
  X := SolveTriangular(L, B, dtLower);
  LSelected := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 0.0, 0.0, 3.0, 1.0, 0.0, 1.0, -2.0, 4.0]);
  AssertMatrixClose('lower triangular multiple RHS', B,
    Multiply(LSelected, X), 1E-13);
  X := SolveTriangular(L, B, dtLower, dtNoTranspose, ddUnit);
  LSelected := TDenseDoubleMatrix.FromValues(3, 3,
    [1.0, 0.0, 0.0, 3.0, 1.0, 0.0, 1.0, -2.0, 1.0]);
  AssertMatrixClose('unit diagonal is implicit', B,
    Multiply(LSelected, X), 1E-13);

  U := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 1.0, -1.0, 0.0, 3.0, 2.0, 0.0, 0.0, 4.0]);
  X := SolveTriangular(U, B, dtUpper, dtTranspose);
  AssertMatrixClose('transposed upper', B, Multiply(Transpose(U), X), 1E-13);

  C := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(2.0, 0.0), TComplex.Create(1.0, 2.0),
     TComplex.Zero, TComplex.Create(3.0, -1.0)]);
  CB := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(1.0, -1.0), TComplex.Create(2.0, 3.0)]);
  CX := SolveTriangular(C, CB, dtUpper, dtConjugateTranspose);
  AssertComplexMatrixClose('conjugate-transposed upper', CB,
    Multiply(ConjugateTranspose(C), CX), 1E-12);
end;

procedure TDenseDecompositionTest.TestQRReconstructionLeastSquaresAndReuse;
var
  A, B, Q, R, X, X2, Expected: IDenseDoubleMatrix;
  Factor: IDenseDoubleQR;
  Diagnostics: TDenseSolveDiagnostics;
begin
  A := TDenseDoubleMatrix.FromValues(4, 2,
    [1.0, 1.0, 1.0, 2.0, 1.0, 3.0, 1.0, 4.0]);
  B := TDenseDoubleMatrix.FromValues(4, 1, [6.0, 5.0, 7.0, 10.0]);
  Factor := FactorQR(A);
  Q := Factor.Q;
  R := Factor.R;
  AssertMatrixClose('QR reconstruction', A, Multiply(Q, R), 2E-13);
  AssertMatrixClose('Q orthogonality',
    TDenseDoubleMatrix.FromValues(2, 2, [1.0, 0.0, 0.0, 1.0]),
    Multiply(Transpose(Q), Q), 2E-13);
  X := Factor.SolveLeastSquaresWithInfo(B, Diagnostics);
  Expected := TDenseDoubleMatrix.FromValues(2, 1, [3.5, 1.4]);
  AssertMatrixClose('least-squares reference', Expected, X, 2E-13);
  AssertEquals('least-squares numerical rank', 2, Diagnostics.NumericalRank);
  AssertTrue('least-squares residual is inspectable',
    Diagnostics.ResidualNorm > 0.0);
  X2 := Factor.SolveLeastSquares(
    TDenseDoubleMatrix.FromValues(4, 1, [1.0, 2.0, 3.0, 4.0]));
  AssertMatrixClose('reused QR factor',
    TDenseDoubleMatrix.FromValues(2, 1, [0.0, 1.0]), X2, 2E-13);
end;

procedure TDenseDecompositionTest.TestPivotedQRRankAndPermutation;
var
  A, B, AP, QR, X: IDenseDoubleMatrix;
  Factor: IDenseDoubleQR;
  Diagnostics: TDenseSolveDiagnostics;
  Permutation: TSizeIntArray;
  I, J: SizeInt;
begin
  A := TDenseDoubleMatrix.FromValues(4, 3,
    [1.0, 100.0, 2.0,
     2.0, 200.0, 4.0,
     3.0, 300.0, 6.0,
     4.0, 400.0, 8.0]);
  Factor := FactorPivotedQR(A);
  AssertEquals('rank-deficient CPQR rank', 1, Factor.NumericalRank);
  Permutation := Factor.Permutation;
  AssertEquals('largest column is selected first', 1, Permutation[0]);
  AP := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  for J := 0 to A.Cols - 1 do
    for I := 0 to A.Rows - 1 do
      AP[I, J] := A[I, Permutation[J]];
  QR := Multiply(Factor.Q, Factor.R);
  AssertMatrixClose('CPQR permutation identity', AP, QR, 2E-11);
  B := TDenseDoubleMatrix.FromValues(4, 2,
    [1.0, 10.0, 2.0, 20.0, 3.0, 30.0, 4.0, 40.0]);
  X := Factor.SolveLeastSquaresWithInfo(B, Diagnostics);
  AssertMatrixClose('rank-revealing basic solution residual', B,
    Multiply(A, X), 2E-13);
  AssertEquals('rank-revealing multiple RHS columns', 2, X.Cols);
  AssertTrue('rank deficiency is explicit', Diagnostics.IsRankDeficient);
end;

procedure TDenseDecompositionTest.TestSVDTallWideAndMinimumNorm;
var
  Tall, Wide, B, X: IDenseDoubleMatrix;
  TallFactor, WideFactor: IDenseDoubleSVD;
  Diagnostics: TDenseSolveDiagnostics;
  SingularValues: TDoubleArray;
begin
  Tall := TDenseDoubleMatrix.FromValues(3, 2,
    [3.0, 0.0, 0.0, 2.0, 0.0, 0.0]);
  TallFactor := FactorSVD(Tall);
  SingularValues := TallFactor.SingularValues;
  AssertEquals('descending singular value 0', 3.0, SingularValues[0], 1E-13);
  AssertEquals('descending singular value 1', 2.0, SingularValues[1], 1E-13);
  AssertMatrixClose('tall SVD reconstruction', Tall,
    ReconstructSVD(TallFactor), 2E-13);

  Wide := TDenseDoubleMatrix.FromValues(2, 3,
    [1.0, 0.0, 1.0, 0.0, 1.0, 1.0]);
  WideFactor := FactorSVD(Wide);
  AssertMatrixClose('wide SVD reconstruction', Wide,
    ReconstructSVD(WideFactor), 2E-12);
  B := TDenseDoubleMatrix.FromValues(2, 2, [2.0, 4.0, 2.0, 1.0]);
  X := WideFactor.SolveMinimumNormWithInfo(B, Diagnostics);
  AssertMatrixClose('wide minimum-norm residual', B, Multiply(Wide, X),
    2E-12);
  AssertEquals('minimum norm known x0', 0.6666666666666667,
    X[0, 0], 2E-12);
  AssertEquals('minimum norm known x1', 0.6666666666666667,
    X[1, 0], 2E-12);
  AssertEquals('minimum norm known x2', 1.3333333333333333,
    X[2, 0], 2E-12);
  AssertEquals('full row rank', 2, Diagnostics.NumericalRank);
end;

procedure TDenseDecompositionTest.TestComplexQRAndSVD;
var
  A, B, X, US, Reconstruction: IDenseComplexMatrix;
  QR: IDenseComplexQR;
  SVD: IDenseComplexSVD;
  SingularValues: TDoubleArray;
  I, J: SizeInt;
  Diagnostics: TDenseSolveDiagnostics;
begin
  A := TDenseComplexMatrix.FromValues(3, 2,
    [TComplex.Create(1.0, 1.0), TComplex.Create(2.0, 0.0),
     TComplex.Create(0.0, 1.0), TComplex.Create(1.0, -1.0),
     TComplex.Create(2.0, 0.0), TComplex.Create(0.0, 1.0)]);
  QR := FactorQR(A);
  AssertComplexMatrixClose('complex QR reconstruction', A,
    Multiply(QR.Q, QR.R), 2E-12);
  B := TDenseComplexMatrix.FromValues(3, 1,
    [TComplex.Create(3.0, 1.0), TComplex.Create(1.0, 0.0),
     TComplex.Create(2.0, 1.0)]);
  X := QR.SolveLeastSquaresWithInfo(B, Diagnostics);
  AssertEquals('complex QR rank', 2, Diagnostics.NumericalRank);
  AssertEquals('complex least-squares result rows', 2, X.Rows);
  AssertTrue('complex QR residual finite',
    not IsNan(Diagnostics.ResidualNorm));

  SVD := FactorSVD(A);
  US := SVD.U;
  SingularValues := SVD.SingularValues;
  for J := 0 to US.Cols - 1 do
    for I := 0 to US.Rows - 1 do
      US[I, J] := US[I, J] * TComplex.Create(SingularValues[J], 0.0);
  Reconstruction := Multiply(US, ConjugateTranspose(SVD.V));
  AssertComplexMatrixClose('complex SVD reconstruction', A,
    Reconstruction, 2E-11);
end;

procedure TDenseDecompositionTest.TestSymmetricAndHermitianEigen;
var
  A, V, AV: IDenseDoubleMatrix;
  C, CV, CAV: IDenseComplexMatrix;
  E: IDenseDoubleSymmetricEigen;
  CE: IDenseComplexHermitianEigen;
  Values: TDoubleArray;
  I, J: SizeInt;
begin
  A := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 1.0, 0.0, 1.0, 2.0, 0.0, 0.0, 0.0, 5.0]);
  E := FactorSymmetricEigen(A);
  Values := E.Eigenvalues;
  AssertEquals('eigenvalue ascending 0', 1.0, Values[0], 2E-13);
  AssertEquals('eigenvalue ascending 1', 3.0, Values[1], 2E-13);
  AssertEquals('eigenvalue ascending 2', 5.0, Values[2], 2E-13);
  V := E.Eigenvectors;
  AV := Multiply(A, V);
  for J := 0 to V.Cols - 1 do
    for I := 0 to V.Rows - 1 do
      AssertEquals('real eigenpair residual', AV[I, J],
        V[I, J] * Values[J], 2E-12);
  AssertMatrixClose('real eigenvectors orthogonal',
    TDenseDoubleMatrix.FromValues(3, 3,
      [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]),
    Multiply(Transpose(V), V), 2E-12);

  C := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(2.0, 0.0), TComplex.Create(0.0, 1.0),
     TComplex.Create(0.0, -1.0), TComplex.Create(2.0, 0.0)]);
  CE := FactorHermitianEigen(C);
  Values := CE.Eigenvalues;
  AssertEquals('Hermitian eigenvalue 0', 1.0, Values[0], 2E-12);
  AssertEquals('Hermitian eigenvalue 1', 3.0, Values[1], 2E-12);
  CV := CE.Eigenvectors;
  CAV := Multiply(C, CV);
  for J := 0 to CV.Cols - 1 do
    for I := 0 to CV.Rows - 1 do
    begin
      AssertEquals('complex eigenpair residual real', CAV[I, J].Re,
        (CV[I, J] * TComplex.Create(Values[J], 0.0)).Re, 2E-12);
      AssertEquals('complex eigenpair residual imaginary', CAV[I, J].Im,
        (CV[I, J] * TComplex.Create(Values[J], 0.0)).Im, 2E-12);
    end;
end;

procedure TDenseDecompositionTest.TestEmptyClusteredAndDifficultScaleCases;
var
  Empty, Singleton, SingletonRhs, Tiny, Repeated,
    NearlyRankDeficient: IDenseDoubleMatrix;
  EmptyQR: IDenseDoubleQR;
  EmptySVD: IDenseDoubleSVD;
  EmptyEigen, TinyEigen, RepeatedEigen: IDenseDoubleSymmetricEigen;
  CPQR: IDenseDoubleQR;
  Values: TDoubleArray;
begin
  Empty := TDenseDoubleMatrix.Zeros(0, 0);
  EmptyQR := FactorQR(Empty);
  EmptySVD := FactorSVD(Empty);
  EmptyEigen := FactorSymmetricEigen(Empty);
  AssertEquals('empty QR Q rows', 0, EmptyQR.Q.Rows);
  AssertEquals('empty QR R columns', 0, EmptyQR.R.Cols);
  AssertEquals('empty SVD compact values', 0,
    Length(EmptySVD.SingularValues));
  AssertEquals('empty eigenvalues', 0, Length(EmptyEigen.Eigenvalues));

  Singleton := TDenseDoubleMatrix.FromValues(1, 1, [-3.0]);
  SingletonRhs := TDenseDoubleMatrix.FromValues(1, 1, [6.0]);
  AssertEquals('singleton QR solve', -2.0,
    FactorQR(Singleton).SolveLeastSquares(SingletonRhs)[0, 0], 0.0);
  AssertEquals('singleton singular value', 3.0,
    FactorSVD(Singleton).SingularValues[0], 0.0);
  AssertEquals('singleton eigenvalue', -3.0,
    FactorSymmetricEigen(Singleton).Eigenvalues[0], 0.0);

  Tiny := TDenseDoubleMatrix.FromValues(2, 2,
    [2E-200, 1E-200, 1E-200, 2E-200]);
  TinyEigen := FactorSymmetricEigen(Tiny);
  Values := TinyEigen.Eigenvalues;
  AssertEquals('tiny-scale eigenvalue 0', 1E-200, Values[0], 1E-214);
  AssertEquals('tiny-scale eigenvalue 1', 3E-200, Values[1], 1E-214);

  Repeated := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 2.0]);
  RepeatedEigen := FactorSymmetricEigen(Repeated);
  Values := RepeatedEigen.Eigenvalues;
  AssertEquals('repeated eigenvalue', 2.0, Values[1], 0.0);
  AssertMatrixClose('repeated eigenbasis is orthogonal', Repeated,
    Multiply(Multiply(RepeatedEigen.Eigenvectors,
      TDenseDoubleMatrix.FromValues(3, 3,
        [2.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 2.0])),
      Transpose(RepeatedEigen.Eigenvectors)), 2E-13);

  NearlyRankDeficient := TDenseDoubleMatrix.FromValues(3, 2,
    [1.0, 1.0, 2.0, 2.0 + 1E-12, 3.0, 3.0]);
  CPQR := FactorPivotedQR(NearlyRankDeficient, 1E-10);
  AssertEquals('caller tolerance controls near-rank decision', 1,
    CPQR.NumericalRank);
  AssertTrue('condition indicator is inspectable',
    CPQR.ConditionIndicator > 0.0);
end;

procedure TDenseDecompositionTest.TestSinglePrecisionParity;
var
  A, B, X: IDenseSingleMatrix;
  C: IDenseSingleComplexMatrix;
  Diagnostics: TDenseSolveDiagnostics;
begin
  A := TDenseSingleMatrix.FromValues(3, 2,
    [1.0, 0.0, 0.0, 2.0, 1.0, 1.0]);
  B := TDenseSingleMatrix.FromValues(3, 1, [1.0, 2.0, 2.0]);
  X := LeastSquares(A, B, Diagnostics);
  AssertEquals('single QR x0', 1.0, X[0, 0], 2E-5);
  AssertEquals('single QR x1', 1.0, X[1, 0], 2E-5);
  AssertEquals('single SVD rank', 2, FactorSVD(A).NumericalRank);
  AssertEquals('single symmetric eigen size', 2,
    FactorSymmetricEigen(TDenseSingleMatrix.FromValues(2, 2,
      [2.0, 1.0, 1.0, 2.0])).Size);

  C := TDenseSingleComplexMatrix.FromValues(2, 2,
    [TSingleComplex.Create(2.0, 0.0), TSingleComplex.Create(0.0, 1.0),
     TSingleComplex.Create(0.0, -1.0), TSingleComplex.Create(2.0, 0.0)]);
  AssertEquals('single complex Hermitian eigen size', 2,
    FactorHermitianEigen(C).Size);
  AssertEquals('single complex SVD rank', 2, FactorSVD(C).NumericalRank);
end;

procedure TDenseDecompositionTest.TestSquareAndPositiveDefiniteDiagnostics;
var
  A, B, X: IDenseDoubleMatrix;
  Diagnostics: TDenseSolveDiagnostics;
  LU: IDenseDoubleLU;
  Cholesky: IDenseDoubleCholesky;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [4.0, 1.0, 2.0, 3.0]);
  B := TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0, 4.0]);
  LU := FactorLU(A);
  X := LU.SolveWithInfo(B, Diagnostics);
  AssertMatrixClose('LU diagnostic solve residual', B, Multiply(A, X),
    2E-13);
  AssertEquals('LU rank', 2, Diagnostics.NumericalRank);
  AssertEquals('LU condition indicator property',
    LU.ConditionIndicator, Diagnostics.ConditionIndicator, 0.0);
  AssertTrue('LU backward error is bounded',
    Diagnostics.BackwardError < 1E-14);

  A := TDenseDoubleMatrix.FromValues(2, 2, [4.0, 1.0, 1.0, 3.0]);
  Cholesky := FactorCholesky(A);
  X := Cholesky.SolveWithInfo(B, Diagnostics);
  AssertMatrixClose('Cholesky diagnostic solve residual', B,
    Multiply(A, X), 2E-13);
  AssertEquals('Cholesky rank', 2, Diagnostics.NumericalRank);
  AssertEquals('Cholesky condition indicator property',
    Cholesky.ConditionIndicator, Diagnostics.ConditionIndicator, 0.0);
  X := SolvePositiveDefinite(A, B, Diagnostics);
  AssertMatrixClose('positive-definite convenience path', B,
    Multiply(A, X), 2E-13);
end;

procedure TDenseDecompositionTest.TestValidationAndImmutableFactors;
var
  A, Snapshot: IDenseDoubleMatrix;
  Factor: IDenseDoubleQR;
  Failed: Boolean;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [2.0, 0.0, 0.0, 3.0]);
  Factor := FactorQR(A);
  A[0, 0] := 99.0;
  Snapshot := Multiply(Factor.Q, Factor.R);
  AssertEquals('factor owns source snapshot', 2.0, Snapshot[0, 0], 1E-14);

  Failed := False;
  try
    FactorQR(TDenseDoubleMatrix.FromValues(1, 2, [1.0, 2.0]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('wide QR is rejected with SVD guidance', Failed);

  Failed := False;
  try
    FactorSymmetricEigen(
      TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0, 4.0]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('nonsymmetric eigen input is rejected', Failed);

  Failed := False;
  try
    FactorSVD(TDenseDoubleMatrix.FromValues(1, 1, [NaN]));
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('non-finite SVD input is rejected', Failed);
end;

initialization
  RegisterTest(TDenseDecompositionTest);

end.
