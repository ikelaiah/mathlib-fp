unit TestPartialEigensystems;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.Complex, MathBase.Iteration,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators,
  AlgebraLib.PartialEigensystems;

type
  TPartialEigensystemTest = class(TTestCase)
  published
    procedure TestLanczosSelectedPairsAndDeterminism;
    procedure TestArnoldiGeneralResidual;
    procedure TestComplexAndSingleCoverage;
    procedure TestTargetAndShapeValidation;
  end;

implementation

procedure TPartialEigensystemTest.TestLanczosSelectedPairsAndDeterminism;
var
  A: ISparseDoubleMatrix;
  Options: TSpectralOptions;
  First, Second: TSpectralResult;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 3, [0, 1, 2, 3],
    [0, 1, 2], [1.0, 3.0, 5.0]);
  Options := TSpectralOptions.Default;
  Options.EigenpairCount := 2;
  Options.KrylovDimension := 3;
  Options.Tolerance := 1e-10;
  First := TDoublePartialEigenSolver.Lanczos(
    TDoubleLinearOperator.FromSparse(A), Options);
  Second := TDoublePartialEigenSolver.Lanczos(
    TDoubleLinearOperator.FromSparse(A), Options);
  AssertEquals('Lanczos converged', Ord(isConverged), Ord(First.Status));
  AssertEquals('two selected pairs', 2, First.ConvergedCount);
  AssertEquals('largest eigenvalue', 5.0, First.Eigenvalues[0].Re, 1e-9);
  AssertEquals('second eigenvalue', 3.0, First.Eigenvalues[1].Re, 1e-8);
  AssertTrue('first residual checked', First.ResidualNorms[0] < 1e-9);
  AssertEquals('deterministic value', First.Eigenvalues[0].Re,
    Second.Eigenvalues[0].Re, 0.0);
  AssertEquals('seed reported', Options.StartingSeed, First.StartingSeed);
end;

procedure TPartialEigensystemTest.TestArnoldiGeneralResidual;
var
  A: ISparseDoubleMatrix;
  Options: TSpectralOptions;
  ResultValue: TSpectralResult;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 4, 5],
    [0, 1, 1, 2, 2], [1.0, 2.0, 3.0, 1.0, 4.0]);
  Options := TSpectralOptions.Default;
  Options.KrylovDimension := 3;
  Options.Tolerance := 1e-9;
  ResultValue := TDoublePartialEigenSolver.Arnoldi(
    TDoubleLinearOperator.FromSparse(A), Options);
  AssertEquals('Arnoldi converged', Ord(isConverged),
    Ord(ResultValue.Status));
  AssertEquals('largest general eigenvalue', 4.0,
    ResultValue.Eigenvalues[0].Re, 1e-8);
  AssertEquals('real eigenvalue imaginary part', 0.0,
    ResultValue.Eigenvalues[0].Im, 1e-8);
  AssertTrue('Arnoldi residual checked',
    ResultValue.ResidualNorms[0] < 1e-8);
  AssertTrue('operator products reported', ResultValue.ProductCount > 0);
end;

procedure TPartialEigensystemTest.TestComplexAndSingleCoverage;
var
  AC: ISparseComplexMatrix;
  ASingle: ISparseSingleMatrix;
  ASingleComplex: ISparseSingleComplexMatrix;
  Options: TSpectralOptions;
  ResultValue: TSpectralResult;
begin
  AC := TSparseComplexMatrix.FromCSR(2, 2, [0, 2, 3],
    [0, 1, 1],
    [TComplex.Create(2, 0), TComplex.Create(0, 1),
     TComplex.Create(1, 0)]);
  Options := TSpectralOptions.Default;
  Options.KrylovDimension := 2;
  Options.Tolerance := 1e-9;
  ResultValue := TComplexPartialEigenSolver.Arnoldi(
    TComplexLinearOperator.FromSparse(AC), Options);
  AssertEquals('complex Arnoldi eigenvalue', 2.0,
    ResultValue.Eigenvalues[0].Re, 1e-8);
  AssertTrue('complex Arnoldi residual',
    ResultValue.ResidualNorms[0] < 1e-8);

  ASingle := TSparseSingleMatrix.FromCSR(2, 2, [0, 1, 2],
    [0, 1], [2.0, 5.0]);
  Options.Tolerance := 1e-5;
  ResultValue := TSinglePartialEigenSolver.Lanczos(
    TSingleLinearOperator.FromSparse(ASingle), Options);
  AssertEquals('single Lanczos eigenvalue', 5.0,
    ResultValue.Eigenvalues[0].Re, 1e-4);

  ASingleComplex := TSparseSingleComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(5.0, 0.0)]);
  ResultValue := TSingleComplexPartialEigenSolver.Lanczos(
    TSingleComplexLinearOperator.FromSparse(ASingleComplex), Options);
  AssertEquals('single-complex Lanczos eigenvalue', 5.0,
    ResultValue.Eigenvalues[0].Re, 1e-4);
  AssertTrue('single-complex Lanczos residual',
    ResultValue.ResidualNorms[0] < 1e-4);
end;

procedure TPartialEigensystemTest.TestTargetAndShapeValidation;
var
  A: ISparseDoubleMatrix;
  Options: TSpectralOptions;
  ResultValue: TSpectralResult;
  Failed: Boolean;
begin
  A := TSparseDoubleMatrix.Zeros(2, 3);
  Options := TSpectralOptions.Default;
  Options.KrylovDimension := 2;
  Failed := False;
  try
    ResultValue := TDoublePartialEigenSolver.Arnoldi(
      TDoubleLinearOperator.FromSparse(A), Options);
  except
    on EPartialEigensystemError do Failed := True;
  end;
  AssertTrue('rectangular operator rejected', Failed);

  A := TSparseDoubleMatrix.Zeros(2, 2);
  Options.EigenpairCount := 2;
  Options.KrylovDimension := 2;
  Failed := False;
  try
    ResultValue := TDoublePartialEigenSolver.Lanczos(
      TDoubleLinearOperator.FromSparse(A), Options);
  except
    on EPartialEigensystemError do Failed := True;
  end;
  AssertTrue('Krylov dimension contract enforced', Failed);
end;

initialization
  RegisterTest(TPartialEigensystemTest);

end.
