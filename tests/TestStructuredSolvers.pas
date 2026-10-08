unit TestStructuredSolvers;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.StructuredSolvers;

type
  TFactorSolveThread = class(TThread)
  private
    FFactor: IStructuredDoubleDirectFactor;
    FRightHandSide, FDestination: IDenseDoubleMatrix;
    FFailure: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFactor: IStructuredDoubleDirectFactor;
      const ARightHandSide, ADestination: IDenseDoubleMatrix);
    property Failure: string read FFailure;
  end;

  TSparseFactorSolveThread = class(TThread)
  private
    FFactor: ISparseDoubleLUFactor;
    FRightHandSide, FDestination: IDenseDoubleMatrix;
    FFailure: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFactor: ISparseDoubleLUFactor;
      const ARightHandSide, ADestination: IDenseDoubleMatrix);
    property Failure: string read FFailure;
  end;

  TStructuredSolverTest = class(TTestCase)
  published
    procedure TestPivotedTridiagonalMultipleRightHandSides;
    procedure TestBandFactorAndSingularity;
    procedure TestSparseLUFillPivotAndComplexSolve;
    procedure TestSingleAndSingleComplexCoverage;
    procedure TestFactorLifecycleContracts;
    procedure TestFourScalarDirectFamilies;
    procedure TestSparseLUAnalysisReuseAndOrdering;
  end;

implementation

constructor TFactorSolveThread.Create(
  const AFactor: IStructuredDoubleDirectFactor;
  const ARightHandSide, ADestination: IDenseDoubleMatrix);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FFactor := AFactor;
  FRightHandSide := ARightHandSide;
  FDestination := ADestination;
end;

procedure TStructuredSolverTest.TestSparseLUAnalysisReuseAndOrdering;
var
  A, A2, Changed, Overflow: ISparseDoubleMatrix;
  Natural, MinimumDegree: ISparseDoubleLUAnalysis;
  NaturalFactor, MinimumFactor, ReusedFactor: ISparseDoubleLUFactor;
  B, X: IDenseDoubleMatrix;
  OverflowAnalysis: ISparseDoubleLUAnalysis;
  Failed: Boolean;
begin
  A := TSparseDoubleMatrix.FromCSR(5, 5,
    [0, 2, 5, 7, 10, 13],
    [0, 3, 1, 3, 4, 2, 4, 0, 1, 3, 1, 2, 4],
    [4.0, -1.0, 4.0, -1.0, -1.0, 4.0, -1.0,
     -1.0, -1.0, 4.0, -1.0, -1.0, 4.0]);
  Natural := TDoubleStructuredSolver.AnalyzeSparseLU(A, soNatural);
  MinimumDegree := TDoubleStructuredSolver.AnalyzeSparseLU(A, soMinimumDegree);
  AssertEquals('natural analysis ordering', Ord(soNatural),
    Ord(Natural.Ordering));
  AssertEquals('minimum-degree analysis ordering', Ord(soMinimumDegree),
    Ord(MinimumDegree.Ordering));
  NaturalFactor := Natural.Factorize(A);
  MinimumFactor := MinimumDegree.Factorize(A);
  AssertTrue('minimum-degree ordering does not add fill',
    MinimumFactor.FillNonZeroCount <= NaturalFactor.FillNonZeroCount);
  AssertTrue('minimum-degree fill fixture is discriminating',
    MinimumFactor.FillNonZeroCount < NaturalFactor.FillNonZeroCount);

  A2 := TSparseDoubleMatrix.FromCSC(5, 5,
    [0, 2, 5, 7, 10, 13],
    [0, 3, 1, 3, 4, 2, 4, 0, 1, 3, 1, 2, 4],
    [5.0, -1.0, 5.0, -1.0, -1.0, 5.0, -1.0,
     -1.0, -1.0, 5.0, -1.0, -1.0, 5.0]);
  AssertEquals('same structural pattern is reusable', True,
    MinimumDegree.Matches(A2));
  ReusedFactor := MinimumDegree.Factorize(A2);
  B := TDenseDoubleMatrix.FromValues(5, 1, [4.0, 3.0, 4.0, 3.0, 3.0]);
  X := TDenseDoubleMatrix.Zeros(5, 1);
  ReusedFactor.SolveInto(B, X);
  AssertEquals('reused factor solution x0', 1.0, X[0, 0], 1e-12);
  AssertEquals('reused factor solution x1', 1.0, X[1, 0], 1e-12);
  AssertEquals('reused factor solution x2', 1.0, X[2, 0], 1e-12);
  AssertEquals('reused factor solution x3', 1.0, X[3, 0], 1e-12);
  AssertEquals('reused factor solution x4', 1.0, X[4, 0], 1e-12);

  Changed := TSparseDoubleMatrix.FromCSR(5, 5,
    [0, 2, 5, 6, 9, 11],
    [0, 3, 1, 3, 4, 2, 0, 1, 3, 1, 4],
    [5.0, -1.0, 5.0, -1.0, -1.0, 5.0, -1.0,
     -1.0, 5.0, -1.0, 4.0]);
  AssertEquals('different pattern rejected', False,
    MinimumDegree.Matches(Changed));
  try
    ReusedFactor := MinimumDegree.Factorize(Changed);
    Fail('factorization must reject a structural mismatch');
  except
    on ESparseDirectSolveError do ;
  end;

  Overflow := TSparseDoubleMatrix.FromCSR(2, 2,
    [0, 2, 4], [0, 1, 0, 1],
    [1.0e308, 1.5e308, -1.0e308, 1.0e308]);
  OverflowAnalysis := TDoubleStructuredSolver.AnalyzeSparseLU(
    Overflow, soNatural);
  Failed := False;
  try
    ReusedFactor := OverflowAnalysis.Factorize(Overflow);
  except
    on ESparseDirectSolveError do Failed := True;
  end;
  AssertTrue('non-finite elimination update rejected', Failed);
end;

procedure TFactorSolveThread.Execute;
begin
  try
    FFactor.SolveInto(FRightHandSide, FDestination);
  except
    on E: Exception do FFailure := E.Message;
  end;
end;

constructor TSparseFactorSolveThread.Create(
  const AFactor: ISparseDoubleLUFactor;
  const ARightHandSide, ADestination: IDenseDoubleMatrix);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FFactor := AFactor;
  FRightHandSide := ARightHandSide;
  FDestination := ADestination;
end;

procedure TSparseFactorSolveThread.Execute;
begin
  try
    FFactor.SolveInto(FRightHandSide, FDestination);
  except
    on E: Exception do FFailure := E.Message;
  end;
end;

procedure TStructuredSolverTest.TestPivotedTridiagonalMultipleRightHandSides;
var
  A: IStructuredDoubleMatrix;
  Factor: IStructuredDoubleDirectFactor;
  B, X, B2, X2: IDenseDoubleMatrix;
  Thread1, Thread2: TFactorSolveThread;
begin
  A := TStructuredDoubleMatrix.Tridiagonal(
    [2.0, 1.0], [0.0, 3.0, 4.0], [1.0, 1.0]);
  Factor := TDoubleStructuredSolver.FactorTridiagonal(A);
  AssertTrue('tridiagonal reports pivot support', Factor.PivotingUsed);
  AssertTrue('tridiagonal interchanged first rows',
    Factor.InterchangeCount > 0);
  B := TDenseDoubleMatrix.FromValues(3, 2,
    [2.0, 0.0, 11.0, 5.0, 14.0, 4.0]);
  X := TDenseDoubleMatrix.Zeros(3, 2);
  Factor.SolveInto(B, X);
  AssertEquals('first rhs x0', 1.0, X[0, 0], 1e-12);
  AssertEquals('first rhs x1', 2.0, X[1, 0], 1e-12);
  AssertEquals('first rhs x2', 3.0, X[2, 0], 1e-12);
  AssertEquals('second rhs x0', 2.0, X[0, 1], 1e-12);
  AssertEquals('second rhs x1', 0.0, X[1, 1], 1e-12);
  AssertEquals('second rhs x2', 1.0, X[2, 1], 1e-12);

  B2 := TDenseDoubleMatrix.FromValues(3, 1, [3.0, 17.0, 19.0]);
  X2 := TDenseDoubleMatrix.Zeros(3, 1);
  Thread1 := TFactorSolveThread.Create(Factor, B2, X2);
  Thread2 := TFactorSolveThread.Create(Factor, B, X);
  try
    Thread1.Start;
    Thread2.Start;
    Thread1.WaitFor;
    Thread2.WaitFor;
    AssertEquals('first concurrent factor solve succeeded',
      '', Thread1.Failure);
    AssertEquals('second concurrent factor solve succeeded',
      '', Thread2.Failure);
    AssertEquals('factor reuse result', 2.0, X2[0, 0], 1e-12);
    AssertEquals('factor reuse tail', 4.0, X2[2, 0], 1e-12);
  finally
    Thread1.Free;
    Thread2.Free;
  end;

  Factor.SolveInto(B2, B2);
  AssertEquals('factor supports documented in-place solve',
    2.0, B2[0, 0], 1e-12);
end;

procedure TStructuredSolverTest.TestBandFactorAndSingularity;
var
  A, Singular: IStructuredDoubleMatrix;
  Factor: IStructuredDoubleDirectFactor;
  B, X: IDenseDoubleMatrix;
  Failed: Boolean;
begin
  A := TStructuredDoubleMatrix.Band(4, 4, 1, 2,
    [0.0, 4.0, 1.0, 1.0,
     1.0, 4.0, 1.0, 1.0,
     1.0, 4.0, 1.0, 0.0,
     1.0, 3.0, 0.0, 0.0]);
  Factor := TDoubleStructuredSolver.FactorBand(A);
  AssertFalse('band no-pivot limitation visible', Factor.PivotingUsed);
  B := TDenseDoubleMatrix.FromValues(4, 1, [6.0, 7.0, 6.0, 4.0]);
  X := TDenseDoubleMatrix.Zeros(4, 1);
  Factor.SolveInto(B, X);
  AssertEquals('band solve x0', 1.0, X[0, 0], 1e-12);
  AssertEquals('band solve x3', 1.0, X[3, 0], 1e-12);

  Singular := TStructuredDoubleMatrix.Diagonal(2, 2, [0.0, 1.0]);
  Failed := False;
  try
    Factor := TDoubleStructuredSolver.FactorBand(Singular);
  except
    on EStructuredSolveError do Failed := True;
  end;
  AssertTrue('band zero pivot rejected', Failed);
  AssertTrue('failed factor construction leaves prior factor published',
    Factor <> nil);
end;

procedure TStructuredSolverTest.TestSparseLUFillPivotAndComplexSolve;
var
  A: ISparseComplexMatrix;
  Analysis: ISparseComplexLUAnalysis;
  Factor: ISparseComplexLUFactor;
  B, X: IDenseComplexMatrix;
begin
  A := TSparseComplexMatrix.FromCSR(2, 2, [0, 1, 3],
    [1, 0, 1],
    [TComplex.Create(1, 1), TComplex.Create(2, 0),
     TComplex.Create(3, 0)]);
  Analysis := TComplexStructuredSolver.AnalyzeSparseLU(A, soMinimumDegree);
  Factor := Analysis.Factorize(A);
  AssertEquals('minimum-degree ordering visible', Ord(soMinimumDegree),
    Ord(Factor.Ordering));
  AssertTrue('sparse LU pivoted', Factor.InterchangeCount > 0);
  AssertTrue('factor count retained',
    Factor.FactorNonZeroCount >= Factor.OriginalNonZeroCount);
  B := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(1, 3), TComplex.Create(8, 1)]);
  X := TDenseComplexMatrix.Zeros(2, 1);
  Factor.SolveInto(B, X);
  AssertEquals('complex sparse x0 real', 1.0, X[0, 0].Re, 1e-12);
  AssertEquals('complex sparse x0 imag', -1.0, X[0, 0].Im, 1e-12);
  AssertEquals('complex sparse x1 real', 2.0, X[1, 0].Re, 1e-12);
  AssertEquals('complex sparse x1 imag', 1.0, X[1, 0].Im, 1e-12);
end;

procedure TStructuredSolverTest.TestSingleAndSingleComplexCoverage;
var
  ASingle: IStructuredSingleMatrix;
  FSingle: IStructuredSingleDirectFactor;
  BS, XS: IDenseSingleMatrix;
  AC: IStructuredSingleComplexMatrix;
  FC: IStructuredSingleComplexDirectFactor;
  BC, XC: IDenseSingleComplexMatrix;
begin
  ASingle := TStructuredSingleMatrix.Tridiagonal(
    [1.0], [2.0, 3.0], [1.0]);
  FSingle := TSingleStructuredSolver.FactorTridiagonal(ASingle);
  BS := TDenseSingleMatrix.FromValues(2, 1, [4.0, 7.0]);
  XS := TDenseSingleMatrix.Zeros(2, 1);
  FSingle.SolveInto(BS, XS);
  AssertEquals('single tridiagonal x0', 1.0, XS[0, 0], 1e-5);
  AssertEquals('single tridiagonal x1', 2.0, XS[1, 0], 1e-5);

  AC := TStructuredSingleComplexMatrix.Tridiagonal(
    [TSingleComplex.Create(1, 0)],
    [TSingleComplex.Create(2, 0), TSingleComplex.Create(3, 0)],
    [TSingleComplex.Create(1, 0)]);
  FC := TSingleComplexStructuredSolver.FactorTridiagonal(AC);
  BC := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.Create(4, 2), TSingleComplex.Create(7, 1)]);
  XC := TDenseSingleComplexMatrix.Zeros(2, 1);
  FC.SolveInto(BC, XC);
  AssertEquals('single complex x0 real', 1.0, XC[0, 0].Re, 1e-5);
  AssertEquals('single complex x0 imag', 1.0, XC[0, 0].Im, 1e-5);
  AssertEquals('single complex x1 real', 2.0, XC[1, 0].Re, 1e-5);
end;

procedure TStructuredSolverTest.TestFactorLifecycleContracts;
var
  BandValues, SparseValues: TDoubleArray;
  RowPointers, ColumnIndices: TSizeIntArray;
  BandMatrix: IStructuredDoubleMatrix;
  SparseMatrix, SingularSparse: ISparseDoubleMatrix;
  BandFactor: IStructuredDoubleDirectFactor;
  SparseFactor: ISparseDoubleLUFactor;
  B1, B2, X1, X2, Shared, RHSView, DestinationView,
    BadDestination: IDenseDoubleMatrix;
  BandThread1, BandThread2: TFactorSolveThread;
  SparseThread1, SparseThread2: TSparseFactorSolveThread;
  Failed: Boolean;
begin
  BandValues := TDoubleArray.Create(2.0, 3.0);
  BandMatrix := TStructuredDoubleMatrix.Band(
    2, 2, 0, 0, BandValues);
  BandFactor := TDoubleStructuredSolver.FactorBand(BandMatrix);
  BandValues[0] := 99.0;
  BandValues[1] := 99.0;

  B1 := TDenseDoubleMatrix.FromValues(2, 1, [4.0, 9.0]);
  X1 := TDenseDoubleMatrix.Zeros(2, 1);
  BandFactor.SolveInto(B1, X1);
  AssertEquals('band factor owns source snapshot x0',
    2.0, X1[0, 0], 1.0e-12);
  AssertEquals('band factor owns source snapshot x1',
    3.0, X1[1, 0], 1.0e-12);
  B2 := TDenseDoubleMatrix.FromValues(2, 1, [8.0, 15.0]);
  X2 := TDenseDoubleMatrix.Zeros(2, 1);
  BandThread1 := TFactorSolveThread.Create(BandFactor, B1, X1);
  BandThread2 := TFactorSolveThread.Create(BandFactor, B2, X2);
  try
    BandThread1.Start;
    BandThread2.Start;
    BandThread1.WaitFor;
    BandThread2.WaitFor;
    AssertEquals('band concurrent solve one', '', BandThread1.Failure);
    AssertEquals('band concurrent solve two', '', BandThread2.Failure);
    AssertEquals('band concurrent result', 5.0, X2[1, 0], 1.0e-12);
  finally
    BandThread1.Free;
    BandThread2.Free;
  end;
  BandFactor.SolveInto(B2, B2);
  AssertEquals('band exact in-place solve', 4.0, B2[0, 0], 1.0e-12);

  Shared := TDenseDoubleMatrix.FromValues(
    2, 2, [4.0, 101.0, 9.0, 202.0]);
  RHSView := Shared.ColumnView(0);
  DestinationView := Shared.ColumnView(1);
  Failed := False;
  try
    BandFactor.SolveInto(RHSView, DestinationView);
  except
    on EStructuredSolveError do Failed := True;
  end;
  AssertTrue('band partial destination alias rejected', Failed);
  AssertEquals('band alias rejection leaves destination unchanged',
    101.0, DestinationView[0, 0], 0.0);
  BadDestination := TDenseDoubleMatrix.FromValues(1, 1, [123.0]);
  Failed := False;
  try
    BandFactor.SolveInto(B1, BadDestination);
  except
    on EStructuredSolveError do Failed := True;
  end;
  AssertTrue('band shape failure reported', Failed);
  AssertEquals('band validation failure is destination-atomic',
    123.0, BadDestination[0, 0], 0.0);
  BandFactor.SolveInto(B1, X1);
  AssertEquals('band factor reusable after failure',
    3.0, X1[1, 0], 1.0e-12);

  RowPointers := TSizeIntArray.Create(0, 1, 2);
  ColumnIndices := TSizeIntArray.Create(0, 1);
  SparseValues := TDoubleArray.Create(2.0, 3.0);
  SparseMatrix := TSparseDoubleMatrix.FromCSR(
    2, 2, RowPointers, ColumnIndices, SparseValues);
  SparseFactor := TDoubleStructuredSolver.FactorSparseLU(SparseMatrix);
  RowPointers[1] := 0;
  ColumnIndices[0] := 1;
  SparseValues[0] := 99.0;
  B1 := TDenseDoubleMatrix.FromValues(2, 1, [4.0, 9.0]);
  X1 := TDenseDoubleMatrix.Zeros(2, 1);
  SparseFactor.SolveInto(B1, X1);
  AssertEquals('sparse factor owns source snapshot x0',
    2.0, X1[0, 0], 1.0e-12);
  AssertEquals('sparse factor owns source snapshot x1',
    3.0, X1[1, 0], 1.0e-12);

  B2 := TDenseDoubleMatrix.FromValues(2, 1, [8.0, 15.0]);
  X2 := TDenseDoubleMatrix.Zeros(2, 1);
  SparseThread1 := TSparseFactorSolveThread.Create(
    SparseFactor, B1, X1);
  SparseThread2 := TSparseFactorSolveThread.Create(
    SparseFactor, B2, X2);
  try
    SparseThread1.Start;
    SparseThread2.Start;
    SparseThread1.WaitFor;
    SparseThread2.WaitFor;
    AssertEquals('sparse concurrent solve one', '', SparseThread1.Failure);
    AssertEquals('sparse concurrent solve two', '', SparseThread2.Failure);
    AssertEquals('sparse concurrent result', 4.0, X2[0, 0], 1.0e-12);
  finally
    SparseThread1.Free;
    SparseThread2.Free;
  end;
  SparseFactor.SolveInto(B2, B2);
  AssertEquals('sparse exact in-place solve', 5.0, B2[1, 0], 1.0e-12);

  Shared := TDenseDoubleMatrix.FromValues(
    2, 2, [4.0, 101.0, 9.0, 202.0]);
  RHSView := Shared.ColumnView(0);
  DestinationView := Shared.ColumnView(1);
  Failed := False;
  try
    SparseFactor.SolveInto(RHSView, DestinationView);
  except
    on ESparseDirectSolveError do Failed := True;
  end;
  AssertTrue('sparse partial destination alias rejected', Failed);
  AssertEquals('sparse alias rejection leaves destination unchanged',
    202.0, DestinationView[1, 0], 0.0);

  SingularSparse := TSparseDoubleMatrix.FromCSR(
    2, 2, [0, 0, 1], [1], [1.0]);
  Failed := False;
  try
    SparseFactor := TDoubleStructuredSolver.FactorSparseLU(SingularSparse);
  except
    on ESparseDirectSolveError do Failed := True;
  end;
  AssertTrue('sparse singular construction rejected', Failed);
  AssertTrue('failed sparse construction preserves prior factor',
    SparseFactor <> nil);
  X1[0, 0] := 0.0;
  X1[1, 0] := 0.0;
  SparseFactor.SolveInto(B1, X1);
  AssertEquals('sparse factor reusable after failure',
    2.0, X1[0, 0], 1.0e-12);
end;

procedure TStructuredSolverTest.TestFourScalarDirectFamilies;
var
  SingleBand: IStructuredSingleMatrix;
  SingleBandFactor: IStructuredSingleDirectFactor;
  SingleSparse: ISparseSingleMatrix;
  SingleSparseAnalysis: ISparseSingleLUAnalysis;
  SingleSparseFactor: ISparseSingleLUFactor;
  SingleB, SingleX: IDenseSingleMatrix;
  SingleComplexBand: IStructuredSingleComplexMatrix;
  SingleComplexBandFactor: IStructuredSingleComplexDirectFactor;
  SingleComplexSparse: ISparseSingleComplexMatrix;
  SingleComplexSparseAnalysis: ISparseSingleComplexLUAnalysis;
  SingleComplexSparseFactor: ISparseSingleComplexLUFactor;
  SingleComplexB, SingleComplexX: IDenseSingleComplexMatrix;
  ComplexTridiagonal, ComplexBand: IStructuredComplexMatrix;
  ComplexFactor: IStructuredComplexDirectFactor;
  ComplexB, ComplexX: IDenseComplexMatrix;
begin
  SingleBand := TStructuredSingleMatrix.Band(
    2, 2, 0, 0, [2.0, 3.0]);
  SingleBandFactor := TSingleStructuredSolver.FactorBand(SingleBand);
  SingleB := TDenseSingleMatrix.FromValues(2, 1, [2.0, 6.0]);
  SingleX := TDenseSingleMatrix.Zeros(2, 1);
  SingleBandFactor.SolveInto(SingleB, SingleX);
  AssertEquals('single band factor', 2.0, SingleX[1, 0], 1.0e-5);

  SingleSparse := TSparseSingleMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1], [2.0, 3.0]);
  SingleSparseAnalysis :=
    TSingleStructuredSolver.AnalyzeSparseLU(SingleSparse, soMinimumDegree);
  SingleSparseFactor := SingleSparseAnalysis.Factorize(SingleSparse);
  SingleX[0, 0] := 0.0;
  SingleX[1, 0] := 0.0;
  SingleSparseFactor.SolveInto(SingleB, SingleX);
  AssertEquals('single sparse LU factor',
    1.0, SingleX[0, 0], 1.0e-5);

  SingleComplexBand := TStructuredSingleComplexMatrix.Band(
    2, 2, 0, 0,
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(3.0, 0.0)]);
  SingleComplexBandFactor :=
    TSingleComplexStructuredSolver.FactorBand(SingleComplexBand);
  SingleComplexB := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.Create(2.0, 2.0),
     TSingleComplex.Create(6.0, -3.0)]);
  SingleComplexX := TDenseSingleComplexMatrix.Zeros(2, 1);
  SingleComplexBandFactor.SolveInto(SingleComplexB, SingleComplexX);
  AssertEquals('single-complex band real',
    2.0, SingleComplexX[1, 0].Re, 1.0e-5);
  AssertEquals('single-complex band imaginary',
    -1.0, SingleComplexX[1, 0].Im, 1.0e-5);

  SingleComplexSparse := TSparseSingleComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(3.0, 0.0)]);
  SingleComplexSparseAnalysis := TSingleComplexStructuredSolver.AnalyzeSparseLU(
    SingleComplexSparse, soMinimumDegree);
  SingleComplexSparseFactor :=
    SingleComplexSparseAnalysis.Factorize(SingleComplexSparse);
  SingleComplexX[0, 0] := TSingleComplex.Zero;
  SingleComplexX[1, 0] := TSingleComplex.Zero;
  SingleComplexSparseFactor.SolveInto(SingleComplexB, SingleComplexX);
  AssertEquals('single-complex sparse LU real',
    1.0, SingleComplexX[0, 0].Re, 1.0e-5);
  AssertEquals('single-complex sparse LU imaginary',
    1.0, SingleComplexX[0, 0].Im, 1.0e-5);

  ComplexTridiagonal := TStructuredComplexMatrix.Tridiagonal(
    [TComplex.Zero],
    [TComplex.Create(2.0, 0.0), TComplex.Create(3.0, 0.0)],
    [TComplex.Zero]);
  ComplexFactor :=
    TComplexStructuredSolver.FactorTridiagonal(ComplexTridiagonal);
  ComplexB := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(2.0, 2.0), TComplex.Create(6.0, -3.0)]);
  ComplexX := TDenseComplexMatrix.Zeros(2, 1);
  ComplexFactor.SolveInto(ComplexB, ComplexX);
  AssertEquals('complex tridiagonal real',
    1.0, ComplexX[0, 0].Re, 1.0e-12);
  AssertEquals('complex tridiagonal imaginary',
    1.0, ComplexX[0, 0].Im, 1.0e-12);

  ComplexBand := TStructuredComplexMatrix.Band(
    2, 2, 0, 0,
    [TComplex.Create(2.0, 0.0), TComplex.Create(3.0, 0.0)]);
  ComplexFactor := TComplexStructuredSolver.FactorBand(ComplexBand);
  ComplexX[0, 0] := TComplex.Zero;
  ComplexX[1, 0] := TComplex.Zero;
  ComplexFactor.SolveInto(ComplexB, ComplexX);
  AssertEquals('complex band real',
    2.0, ComplexX[1, 0].Re, 1.0e-12);
  AssertEquals('complex band imaginary',
    -1.0, ComplexX[1, 0].Im, 1.0e-12);
end;

initialization
  RegisterTest(TStructuredSolverTest);

end.
