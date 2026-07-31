unit TestIterativeSolvers;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex, MathBase.Iteration,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators,
  AlgebraLib.IterativeSolvers;

type
  TDoubleMatrixFreeAction = class(TInterfacedObject,
    IMatrixFreeDoubleAction)
  public
    procedure Apply(const Input, Destination: IDenseDoubleMatrix);
    procedure ApplyAdjoint(const Input, Destination: IDenseDoubleMatrix);
    function GetIsReentrant: Boolean;
  end;

  TLargeDiagonalAction = class(TInterfacedObject,
    IMatrixFreeDoubleAction)
  private
    FSize: SizeInt;
  public
    constructor Create(const ASize: SizeInt);
    procedure Apply(const Input, Destination: IDenseDoubleMatrix);
    procedure ApplyAdjoint(const Input, Destination: IDenseDoubleMatrix);
    function GetIsReentrant: Boolean;
  end;

  TCancelMonitor = class(TInterfacedObject, IIterationMonitor)
  private
    FReports: SizeInt;
  public
    function ShouldCancel: Boolean;
    procedure ReportProgress(const Method: TIterativeMethod;
      const Iteration, ProductCount: SizeInt;
      const ResidualNorm, StoppingThreshold: Double);
  end;

  TRecordingMonitor = class(TInterfacedObject, IIterationMonitor)
  private
    FReports: SizeInt;
  public
    function ShouldCancel: Boolean;
    procedure ReportProgress(const Method: TIterativeMethod;
      const Iteration, ProductCount: SizeInt;
      const ResidualNorm, StoppingThreshold: Double);
    property Reports: SizeInt read FReports;
  end;

  TPreconditionerApplyThread = class(TThread)
  private
    FPreconditioner: IDoublePreconditioner;
    FInput, FDestination: IDenseDoubleMatrix;
    FFailure: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const APreconditioner: IDoublePreconditioner;
      const AInput, ADestination: IDenseDoubleMatrix);
    property Failure: string read FFailure;
  end;

  TWorkspaceSolveThread = class(TThread)
  private
    FOperator: ILinearDoubleOperator;
    FRightHandSide, FSolution: IDenseDoubleMatrix;
    FWorkspace: TDoubleIterativeWorkspace;
    FOptions: TLinearSolveOptions;
    FFailure: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOperator: ILinearDoubleOperator;
      const ARightHandSide, ASolution: IDenseDoubleMatrix;
      const AWorkspace: TDoubleIterativeWorkspace;
      const AOptions: TLinearSolveOptions);
    property Failure: string read FFailure;
  end;

  TIterativeSolverTest = class(TTestCase)
  published
    procedure TestOperatorAdaptersAndAdjoints;
    procedure TestPreconditionersAndStructureFailures;
    procedure TestCGScalarCoverageAndReuse;
    procedure TestMINRESGMRESBiCGSTAB;
    procedure TestLSQRRectangular;
    procedure TestTerminationOutcomes;
    procedure TestLargeMatrixFreePathDoesNotDensify;
    procedure TestPreconditionerLifecycleContracts;
    procedure TestWorkspaceAliasingConcurrencyAndFailure;
    procedure TestFourScalarAllIterativeMethods;
    procedure TestProgressAndResidualRefresh;
    procedure TestFourScalarPreconditionerFamilies;
  end;

implementation

procedure TDoubleMatrixFreeAction.Apply(const Input,
  Destination: IDenseDoubleMatrix);
begin
  Destination[0, 0] := 2.0 * Input[0, 0] + Input[1, 0];
  Destination[1, 0] := Input[0, 0] + 3.0 * Input[1, 0];
end;

procedure TDoubleMatrixFreeAction.ApplyAdjoint(const Input,
  Destination: IDenseDoubleMatrix);
begin
  Apply(Input, Destination);
end;

function TDoubleMatrixFreeAction.GetIsReentrant: Boolean;
begin
  Result := True;
end;

constructor TLargeDiagonalAction.Create(const ASize: SizeInt);
begin
  inherited Create;
  FSize := ASize;
end;

procedure TLargeDiagonalAction.Apply(const Input,
  Destination: IDenseDoubleMatrix);
var
  I: SizeInt;
begin
  for I := 0 to FSize - 1 do Destination[I, 0] := 2.0 * Input[I, 0];
end;

procedure TLargeDiagonalAction.ApplyAdjoint(const Input,
  Destination: IDenseDoubleMatrix);
begin
  Apply(Input, Destination);
end;

function TLargeDiagonalAction.GetIsReentrant: Boolean;
begin
  Result := True;
end;

function TCancelMonitor.ShouldCancel: Boolean;
begin
  Result := True;
end;

constructor TPreconditionerApplyThread.Create(
  const APreconditioner: IDoublePreconditioner;
  const AInput, ADestination: IDenseDoubleMatrix);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPreconditioner := APreconditioner;
  FInput := AInput;
  FDestination := ADestination;
end;

procedure TPreconditionerApplyThread.Execute;
begin
  try
    FPreconditioner.Apply(FInput, FDestination);
  except
    on E: Exception do FFailure := E.Message;
  end;
end;

constructor TWorkspaceSolveThread.Create(
  const AOperator: ILinearDoubleOperator;
  const ARightHandSide, ASolution: IDenseDoubleMatrix;
  const AWorkspace: TDoubleIterativeWorkspace;
  const AOptions: TLinearSolveOptions);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOperator := AOperator;
  FRightHandSide := ARightHandSide;
  FSolution := ASolution;
  FWorkspace := AWorkspace;
  FOptions := AOptions;
end;

procedure TWorkspaceSolveThread.Execute;
var
  Diagnostics: TLinearSolveDiagnostics;
begin
  try
    Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
      FOperator, FRightHandSide, FSolution, FWorkspace, FOptions);
    if Diagnostics.Status = isUnknown then
      FFailure := 'solver returned an unknown status';
  except
    on E: Exception do FFailure := E.Message;
  end;
end;

procedure TCancelMonitor.ReportProgress(const Method: TIterativeMethod;
  const Iteration, ProductCount: SizeInt;
  const ResidualNorm, StoppingThreshold: Double);
begin
  Inc(FReports);
end;

function TRecordingMonitor.ShouldCancel: Boolean;
begin
  Result := False;
end;

procedure TRecordingMonitor.ReportProgress(const Method: TIterativeMethod;
  const Iteration, ProductCount: SizeInt;
  const ResidualNorm, StoppingThreshold: Double);
begin
  Inc(FReports);
end;

procedure TIterativeSolverTest.TestOperatorAdaptersAndAdjoints;
var
  Sparse: ISparseComplexMatrix;
  Structured: IStructuredComplexMatrix;
  Dense: IDenseDoubleMatrix;
  ComplexOp: ILinearComplexOperator;
  DoubleOp, MatrixFreeOp: ILinearDoubleOperator;
  CX, CY: IDenseComplexMatrix;
  X, Y: IDenseDoubleMatrix;
  Action: IMatrixFreeDoubleAction;
  SparseSingle: ISparseSingleMatrix;
  SingleOp: ILinearSingleOperator;
  SX, SY: IDenseSingleMatrix;
  SparseSingleComplex: ISparseSingleComplexMatrix;
  SingleComplexOp: ILinearSingleComplexOperator;
  SCX, SCY: IDenseSingleComplexMatrix;
begin
  Sparse := TSparseComplexMatrix.FromCSR(2, 2, [0, 2, 3], [0, 1, 1],
    [TComplex.Create(2, 0), TComplex.Create(1, 1),
     TComplex.Create(3, 0)]);
  ComplexOp := TComplexLinearOperator.FromSparse(Sparse);
  CX := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(1, -1), TComplex.Create(2, 0)]);
  CY := TDenseComplexMatrix.Zeros(2, 1);
  ComplexOp.Apply(CX, CY);
  AssertEquals('complex sparse product real 0', 4.0, CY[0, 0].Re, 1e-12);
  AssertEquals('complex sparse product imag 0', 0.0, CY[0, 0].Im, 1e-12);
  AssertEquals('complex sparse product real 1', 6.0, CY[1, 0].Re, 1e-12);
  ComplexOp.ApplyAdjoint(CX, CY);
  AssertEquals('adjoint real 0', 2.0, CY[0, 0].Re, 1e-12);
  AssertEquals('adjoint imag 0', -2.0, CY[0, 0].Im, 1e-12);
  AssertEquals('adjoint real 1', 6.0, CY[1, 0].Re, 1e-12);
  AssertEquals('adjoint imag 1', -2.0, CY[1, 0].Im, 1e-12);
  AssertTrue('immutable adapter reentrant', ComplexOp.IsReentrant);

  Structured := TStructuredComplexMatrix.Diagonal(2, 2,
    [TComplex.Create(2, 0), TComplex.Create(3, 0)]);
  ComplexOp := TComplexLinearOperator.FromStructured(Structured);
  ComplexOp.Apply(CX, CY);
  AssertEquals('structured product', 6.0, CY[1, 0].Re, 1e-12);

  Dense := TDenseDoubleMatrix.FromValues(2, 2, [2.0, 1.0, 1.0, 3.0]);
  DoubleOp := TDoubleLinearOperator.FromDense(Dense);
  X := TDenseDoubleMatrix.FromValues(2, 1, [1.0, 2.0]);
  Y := TDenseDoubleMatrix.Zeros(2, 1);
  DoubleOp.Apply(X, Y);
  AssertEquals('dense product 0', 4.0, Y[0, 0], 1e-12);
  AssertEquals('dense product 1', 7.0, Y[1, 0], 1e-12);
  AssertFalse('mutable dense adapter not reentrant', DoubleOp.IsReentrant);

  Action := TDoubleMatrixFreeAction.Create;
  MatrixFreeOp := TDoubleLinearOperator.MatrixFree(2, 2, Action);
  MatrixFreeOp.Apply(X, Y);
  AssertEquals('matrix-free product', 7.0, Y[1, 0], 1e-12);
  AssertEquals('delegated ownership', Ord(looDelegated),
    Ord(MatrixFreeOp.Ownership));

  SparseSingle := TSparseSingleMatrix.FromCSR(
    2, 2, [0, 2, 3], [0, 1, 1], [2.0, -1.0, 3.0]);
  SingleOp := TSingleLinearOperator.FromSparse(SparseSingle);
  SX := TDenseSingleMatrix.FromValues(2, 1, [1.0, 2.0]);
  SY := TDenseSingleMatrix.Zeros(2, 1);
  SingleOp.Apply(SX, SY);
  AssertEquals('single operator product', 6.0, SY[1, 0], 1.0e-6);
  SingleOp.ApplyAdjoint(SX, SY);
  AssertEquals('single operator adjoint', 5.0, SY[1, 0], 1.0e-6);

  SparseSingleComplex := TSparseSingleComplexMatrix.FromCSR(
    2, 2, [0, 2, 3], [0, 1, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(-1.0, 1.0),
     TSingleComplex.Create(3.0, 0.0)]);
  SingleComplexOp :=
    TSingleComplexLinearOperator.FromSparse(SparseSingleComplex);
  SCX := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.One, TSingleComplex.Create(2.0, 0.0)]);
  SCY := TDenseSingleComplexMatrix.Zeros(2, 1);
  SingleComplexOp.Apply(SCX, SCY);
  AssertEquals('single-complex operator product real',
    0.0, SCY[0, 0].Re, 1.0e-5);
  AssertEquals('single-complex operator product imaginary',
    2.0, SCY[0, 0].Im, 1.0e-5);
  SingleComplexOp.ApplyAdjoint(SCX, SCY);
  AssertEquals('single-complex operator adjoint real',
    5.0, SCY[1, 0].Re, 1.0e-5);
  AssertEquals('single-complex operator adjoint imaginary',
    -1.0, SCY[1, 0].Im, 1.0e-5);
end;

procedure TIterativeSolverTest.TestPreconditionersAndStructureFailures;
var
  SPD, General, Bad: ISparseDoubleMatrix;
  P: IDoublePreconditioner;
  X, Y, X2, Y2: IDenseDoubleMatrix;
  Failed: Boolean;
  Thread1, Thread2: TPreconditionerApplyThread;
begin
  SPD := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 5, 7],
    [0, 1, 0, 1, 2, 1, 2],
    [4.0, 1.0, 1.0, 4.0, 1.0, 1.0, 3.0]);
  X := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 3.0]);
  Y := TDenseDoubleMatrix.Zeros(3, 1);
  P := TDoublePreconditioner.SparseDiagonal(SPD);
  P.Apply(X, Y);
  AssertEquals('diagonal inverse', 0.25, Y[0, 0], 1e-12);
  AssertEquals('diagonal inverse tail', 1.0, Y[2, 0], 1e-12);
  X2 := TDenseDoubleMatrix.FromValues(3, 1, [4.0, 8.0, 12.0]);
  P.Apply(X2, X2);
  AssertEquals('diagonal supports documented in-place apply',
    1.0, X2[0, 0], 1e-12);

  Y2 := TDenseDoubleMatrix.Zeros(3, 1);
  Thread1 := TPreconditionerApplyThread.Create(P, X, Y);
  Thread2 := TPreconditionerApplyThread.Create(P,
    TDenseDoubleMatrix.FromValues(3, 1, [4.0, 8.0, 12.0]), Y2);
  try
    Thread1.Start;
    Thread2.Start;
    Thread1.WaitFor;
    Thread2.WaitFor;
    AssertEquals('first concurrent preconditioner apply succeeded',
      '', Thread1.Failure);
    AssertEquals('second concurrent preconditioner apply succeeded',
      '', Thread2.Failure);
    AssertEquals('concurrent result isolated', 1.0, Y2[0, 0], 1e-12);
  finally
    Thread1.Free;
    Thread2.Free;
  end;

  P := TDoublePreconditioner.IncompleteCholesky0(SPD);
  P.Apply(X, Y);
  AssertTrue('IC result finite', not IsNan(Y[0, 0]));

  General := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 5, 7],
    [0, 1, 0, 1, 2, 1, 2],
    [4.0, 1.0, 2.0, 4.0, 1.0, 3.0, 3.0]);
  P := TDoublePreconditioner.ILU0(General);
  P.Apply(X, Y);
  AssertTrue('ILU result finite', not IsNan(Y[2, 0]));

  Bad := TSparseDoubleMatrix.FromCSR(2, 2, [0, 1, 2],
    [1, 0], [1.0, 1.0]);
  Failed := False;
  try
    P := TDoublePreconditioner.ILU0(Bad);
  except
    on EPreconditionerError do Failed := True;
  end;
  AssertTrue('missing ILU diagonal rejected', Failed);
  AssertTrue('failed construction leaves previous factor published', P <> nil);
  Failed := False;
  try
    P := TDoublePreconditioner.IncompleteCholesky0(General);
  except
    on EPreconditionerError do Failed := True;
  end;
  AssertTrue('non-Hermitian IC input rejected', Failed);
end;

procedure TIterativeSolverTest.TestCGScalarCoverageAndReuse;
var
  A: ISparseDoubleMatrix;
  Op: ILinearDoubleOperator;
  B, X: IDenseDoubleMatrix;
  P: IDoublePreconditioner;
  Options: TLinearSolveOptions;
  Workspace: TDoubleIterativeWorkspace;
  D: TLinearSolveDiagnostics;
  ASingle: ISparseSingleMatrix;
  SingleResult: TSingleLinearSolveResult;
  AComplex: ISparseComplexMatrix;
  ComplexResult: TComplexLinearSolveResult;
begin
  A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 2, 4], [0, 1, 0, 1],
    [4.0, 1.0, 1.0, 3.0]);
  Op := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(2, 1, [1.0, 2.0]);
  X := TDenseDoubleMatrix.Zeros(2, 1);
  P := TDoublePreconditioner.IncompleteCholesky0(A);
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1e-12;
  Workspace := TDoubleIterativeWorkspace.Create;
  try
    D := TDoubleIterativeSolver.ConjugateGradientInto(
      Op, B, X, Workspace, Options, P);
    AssertEquals('CG converged', Ord(isConverged), Ord(D.Status));
    AssertEquals('CG x0', 0.0909090909090909, X[0, 0], 1e-10);
    AssertEquals('CG x1', 0.6363636363636364, X[1, 0], 1e-10);
    X[0, 0] := 0.0;
    X[1, 0] := 0.0;
    D := TDoubleIterativeSolver.ConjugateGradientInto(
      Op, B, X, Workspace, Options, P);
    AssertEquals('workspace reused', Ord(isConverged), Ord(D.Status));
    Workspace.BeginUse;
    try
      try
        Workspace.BeginUse;
        Fail('recursive workspace use must be rejected');
      except
        on EIterativeSolverError do ;
      end;
    finally
      Workspace.EndUse;
    end;
  finally
    Workspace.Free;
  end;

  ASingle := TSparseSingleMatrix.FromCSR(2, 2, [0, 2, 4],
    [0, 1, 0, 1], [4.0, 1.0, 1.0, 3.0]);
  SingleResult := TSingleIterativeSolver.ConjugateGradient(
    TSingleLinearOperator.FromSparse(ASingle),
    TDenseSingleMatrix.FromValues(2, 1, [1.0, 2.0]), Options);
  AssertEquals('single CG', 7.0 / 11.0,
    SingleResult.Solution[1, 0], 1e-5);

  AComplex := TSparseComplexMatrix.FromCSR(2, 2, [0, 2, 4],
    [0, 1, 0, 1],
    [TComplex.Create(4, 0), TComplex.Create(1, 1),
     TComplex.Create(1, -1), TComplex.Create(3, 0)]);
  ComplexResult := TComplexIterativeSolver.ConjugateGradient(
    TComplexLinearOperator.FromSparse(AComplex),
    TDenseComplexMatrix.FromValues(2, 1,
      [TComplex.Create(7, 5), TComplex.Create(8, -3)]), Options);
  AssertEquals('complex CG x0 real', 1.0,
    ComplexResult.Solution[0, 0].Re, 1e-10);
  AssertEquals('complex CG x0 imag', 1.0,
    ComplexResult.Solution[0, 0].Im, 1e-10);
  AssertEquals('complex CG x1 real', 2.0,
    ComplexResult.Solution[1, 0].Re, 1e-10);
  AssertEquals('complex CG x1 imag', -1.0,
    ComplexResult.Solution[1, 0].Im, 1e-10);
end;

procedure TIterativeSolverTest.TestMINRESGMRESBiCGSTAB;
var
  A: ISparseDoubleMatrix;
  Op: ILinearDoubleOperator;
  B: IDenseDoubleMatrix;
  Options: TLinearSolveOptions;
  ResultValue: TDoubleLinearSolveResult;
  P: IDoublePreconditioner;
begin
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1e-12;
  Options.RestartSize := 2;

  A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 1, 2], [1, 0],
    [1.0, 1.0]);
  Op := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(2, 1, [2.0, 1.0]);
  ResultValue := TDoubleIterativeSolver.MINRES(Op, B, Options);
  AssertEquals('MINRES converged', Ord(isConverged),
    Ord(ResultValue.Diagnostics.Status));
  AssertEquals('MINRES x0', 1.0, ResultValue.Solution[0, 0], 1e-9);
  AssertEquals('MINRES x1', 2.0, ResultValue.Solution[1, 0], 1e-9);

  A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 2, 4], [0, 1, 0, 1],
    [4.0, 1.0, 2.0, 3.0]);
  Op := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(2, 1, [1.0, 1.0]);
  P := TDoublePreconditioner.ILU0(A);
  ResultValue := TDoubleIterativeSolver.GMRES(Op, B, Options, P);
  AssertEquals('GMRES converged', Ord(isConverged),
    Ord(ResultValue.Diagnostics.Status));
  AssertEquals('GMRES x0', 0.2, ResultValue.Solution[0, 0], 1e-9);
  AssertEquals('GMRES x1', 0.2, ResultValue.Solution[1, 0], 1e-9);
  ResultValue := TDoubleIterativeSolver.BiCGSTAB(Op, B, Options, P);
  AssertEquals('BiCGSTAB converged', Ord(isConverged),
    Ord(ResultValue.Diagnostics.Status));
  AssertEquals('BiCGSTAB x0', 0.2, ResultValue.Solution[0, 0], 1e-9);
end;

procedure TIterativeSolverTest.TestLSQRRectangular;
var
  A: ISparseDoubleMatrix;
  Options: TLinearSolveOptions;
  ResultValue: TDoubleLinearSolveResult;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 2, [0, 1, 2, 4],
    [0, 1, 0, 1], [1.0, 1.0, 1.0, 1.0]);
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1e-12;
  ResultValue := TDoubleIterativeSolver.LSQR(
    TDoubleLinearOperator.FromSparse(A),
    TDenseDoubleMatrix.FromValues(3, 1, [2.0, -1.0, 1.0]), Options);
  AssertEquals('LSQR converged', Ord(isConverged),
    Ord(ResultValue.Diagnostics.Status));
  AssertEquals('LSQR x0', 2.0, ResultValue.Solution[0, 0], 1e-9);
  AssertEquals('LSQR x1', -1.0, ResultValue.Solution[1, 0], 1e-9);

  ResultValue := TDoubleIterativeSolver.LSQR(
    TDoubleLinearOperator.FromSparse(A),
    TDenseDoubleMatrix.FromValues(3, 1, [2.0, -1.0, 2.0]), Options);
  AssertEquals('inconsistent LSQR reaches least-squares stationarity',
    Ord(isConverged), Ord(ResultValue.Diagnostics.Status));
  AssertEquals('inconsistent LSQR x0', 2.3333333333333333,
    ResultValue.Solution[0, 0], 1e-9);
  AssertEquals('inconsistent LSQR x1', -0.6666666666666667,
    ResultValue.Solution[1, 0], 1e-9);
  AssertTrue('least-squares residual remains nonzero',
    ResultValue.Diagnostics.FinalResidualNorm > 0.5);
  AssertTrue('normal residual satisfies stopping contract',
    ResultValue.Diagnostics.FinalNormalResidualNorm <=
      ResultValue.Diagnostics.RequestedTolerance);
  AssertTrue('least-squares convergence explicitly confirmed',
    ResultValue.Diagnostics.ConvergenceConfirmed);
end;

procedure TIterativeSolverTest.TestTerminationOutcomes;
var
  A: ISparseDoubleMatrix;
  Op: ILinearDoubleOperator;
  B: IDenseDoubleMatrix;
  Options: TLinearSolveOptions;
  ResultValue: TDoubleLinearSolveResult;
  Monitor: IIterationMonitor;
begin
  A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 2, 4], [0, 1, 0, 1],
    [4.0, 1.0, 2.0, 3.0]);
  Op := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(2, 1, [1.0, 1.0]);
  Options := TLinearSolveOptions.Default;
  Options.MaxIterations := 0;
  ResultValue := TDoubleIterativeSolver.GMRES(Op, B, Options);
  AssertEquals('iteration limit', Ord(isIterationLimit),
    Ord(ResultValue.Diagnostics.Status));

  Options := TLinearSolveOptions.Default;
  Monitor := TCancelMonitor.Create;
  Options.Monitor := Monitor;
  ResultValue := TDoubleIterativeSolver.BiCGSTAB(Op, B, Options);
  AssertEquals('cancelled', Ord(isCancelled),
    Ord(ResultValue.Diagnostics.Status));

  A := TSparseDoubleMatrix.Zeros(2, 2);
  Options := TLinearSolveOptions.Default;
  ResultValue := TDoubleIterativeSolver.BiCGSTAB(
    TDoubleLinearOperator.FromSparse(A), B, Options);
  AssertEquals('breakdown', Ord(isNumericalBreakdown),
    Ord(ResultValue.Diagnostics.Status));
  AssertTrue('breakdown reason retained',
    ResultValue.Diagnostics.BreakdownReason <> lbrNone);
end;

procedure TIterativeSolverTest.TestLargeMatrixFreePathDoesNotDensify;
const
  N = 20000;
var
  Action, ShapeOnlyAction: IMatrixFreeDoubleAction;
  OperatorValue, ShapeOnlyOperator: ILinearDoubleOperator;
  B, X: IDenseDoubleMatrix;
  Workspace: TDoubleIterativeWorkspace;
  Options: TLinearSolveOptions;
  Diagnostics: TLinearSolveDiagnostics;
  I, DenseProductLimitDimension, TooLargeDimension: SizeInt;
  Failed: Boolean;
begin
  { This shape's hypothetical dense byte count exceeds High(SizeInt) on every
    target, while either vector dimension remains independently representable.
    Constructing the delegated operator must not apply a dense-product limit. }
  DenseProductLimitDimension :=
    Trunc(Sqrt(High(SizeInt) div SizeOf(Double))) + 1;
  ShapeOnlyAction := TLargeDiagonalAction.Create(DenseProductLimitDimension);
  ShapeOnlyOperator := TDoubleLinearOperator.MatrixFree(
    DenseProductLimitDimension, DenseProductLimitDimension, ShapeOnlyAction);
  AssertEquals('matrix-free rows ignore hypothetical dense product',
    DenseProductLimitDimension, ShapeOnlyOperator.Rows);
  AssertEquals('matrix-free columns ignore hypothetical dense product',
    DenseProductLimitDimension, ShapeOnlyOperator.Cols);

  Failed := False;
  try
    ShapeOnlyOperator := TDoubleLinearOperator.MatrixFree(
      -1, DenseProductLimitDimension, ShapeOnlyAction);
  except
    on ELinearOperatorError do Failed := True;
  end;
  AssertTrue('negative matrix-free dimension rejected', Failed);

  TooLargeDimension := High(SizeInt) div SizeOf(Double) + 1;
  Failed := False;
  try
    ShapeOnlyOperator := TDoubleLinearOperator.MatrixFree(
      TooLargeDimension, 1, ShapeOnlyAction);
  except
    on ELinearOperatorError do Failed := True;
  end;
  AssertTrue('unrepresentable matrix-free vector rejected', Failed);

  { A dense N x N allocation would require 3.2 GB. This fixture runs within
    linear operator/vector storage and is the regression tripwire against
    accidental densification. }
  Action := TLargeDiagonalAction.Create(N);
  OperatorValue := TDoubleLinearOperator.MatrixFree(N, N, Action);
  B := TDenseDoubleMatrix.Zeros(N, 1);
  X := TDenseDoubleMatrix.Zeros(N, 1);
  for I := 0 to N - 1 do B[I, 0] := 1.0;
  Options := TLinearSolveOptions.Default;
  Options.MaxIterations := 4;
  Options.RestartSize := 2;
  Options.RelativeTolerance := 1.0e-12;
  Workspace := TDoubleIterativeWorkspace.Create;
  try
    Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
      OperatorValue, B, X, Workspace, Options);
  finally
    Workspace.Free;
  end;
  AssertEquals('large matrix-free converged',
    Ord(isConverged), Ord(Diagnostics.Status));
  AssertEquals('large matrix-free first value', 0.5, X[0, 0], 1.0e-12);
  AssertEquals('large matrix-free last value',
    0.5, X[N - 1, 0], 1.0e-12);
  AssertTrue('large true residual confirmed',
    Diagnostics.ResidualConfirmed);
end;

procedure TIterativeSolverTest.TestPreconditionerLifecycleContracts;
var
  DiagonalValues: TDoubleArray;
  SPD, General: ISparseDoubleMatrix;
  P: IDoublePreconditioner;
  Input, Expected, InPlace, OtherInput, OtherOutput,
    Shared, InputView, DestinationView, BadDestination: IDenseDoubleMatrix;
  Thread1, Thread2: TPreconditionerApplyThread;
  Failed: Boolean;
begin
  DiagonalValues := TDoubleArray.Create(2.0, 4.0);
  P := TDoublePreconditioner.Diagonal(DiagonalValues);
  DiagonalValues[0] := 100.0;
  DiagonalValues[1] := 100.0;
  Input := TDenseDoubleMatrix.FromValues(2, 1, [4.0, 8.0]);
  Expected := TDenseDoubleMatrix.Zeros(2, 1);
  P.Apply(Input, Expected);
  AssertEquals('diagonal preconditioner owns caller values',
    2.0, Expected[0, 0], 1.0e-12);
  AssertEquals('diagonal preconditioner retained second inverse',
    2.0, Expected[1, 0], 1.0e-12);

  SPD := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 5, 7],
    [0, 1, 0, 1, 2, 1, 2],
    [4.0, 1.0, 1.0, 4.0, 1.0, 1.0, 3.0]);
  Input := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 3.0]);
  Expected := TDenseDoubleMatrix.Zeros(3, 1);
  P := TDoublePreconditioner.IncompleteCholesky0(SPD);
  P.Apply(Input, Expected);
  InPlace := Input.Clone;
  P.Apply(InPlace, InPlace);
  AssertEquals('IC exact in-place x0',
    Expected[0, 0], InPlace[0, 0], 1.0e-12);
  AssertEquals('IC exact in-place tail',
    Expected[2, 0], InPlace[2, 0], 1.0e-12);

  OtherInput := TDenseDoubleMatrix.FromValues(3, 1, [2.0, 4.0, 6.0]);
  OtherOutput := TDenseDoubleMatrix.Zeros(3, 1);
  Thread1 := TPreconditionerApplyThread.Create(P, Input, Expected);
  Thread2 := TPreconditionerApplyThread.Create(P, OtherInput, OtherOutput);
  try
    Thread1.Start;
    Thread2.Start;
    Thread1.WaitFor;
    Thread2.WaitFor;
    AssertEquals('IC concurrent apply one', '', Thread1.Failure);
    AssertEquals('IC concurrent apply two', '', Thread2.Failure);
    AssertTrue('IC concurrent result finite',
      not IsNan(OtherOutput[2, 0]));
  finally
    Thread1.Free;
    Thread2.Free;
  end;

  Shared := TDenseDoubleMatrix.FromValues(
    3, 2, [1.0, 101.0, 2.0, 202.0, 3.0, 303.0]);
  InputView := Shared.ColumnView(0);
  DestinationView := Shared.ColumnView(1);
  Failed := False;
  try
    P.Apply(InputView, DestinationView);
  except
    on EPreconditionerError do Failed := True;
  end;
  AssertTrue('IC partial destination alias rejected', Failed);
  AssertEquals('IC alias failure leaves destination unchanged',
    202.0, DestinationView[1, 0], 0.0);

  BadDestination := TDenseDoubleMatrix.FromValues(2, 1, [77.0, 88.0]);
  Failed := False;
  try
    P.Apply(Input, BadDestination);
  except
    on EPreconditionerError do Failed := True;
  end;
  AssertTrue('preconditioner shape failure reported', Failed);
  AssertEquals('preconditioner validation failure is destination-atomic',
    77.0, BadDestination[0, 0], 0.0);
  P.Apply(Input, Expected);
  AssertTrue('IC reusable after validation failure',
    not IsNan(Expected[0, 0]));

  General := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 5, 7],
    [0, 1, 0, 1, 2, 1, 2],
    [4.0, 1.0, 2.0, 4.0, 1.0, 3.0, 3.0]);
  P := TDoublePreconditioner.ILU0(General);
  P.Apply(Input, Expected);
  InPlace := Input.Clone;
  P.Apply(InPlace, InPlace);
  AssertEquals('ILU exact in-place x0',
    Expected[0, 0], InPlace[0, 0], 1.0e-12);
  AssertEquals('ILU exact in-place tail',
    Expected[2, 0], InPlace[2, 0], 1.0e-12);

  Thread1 := TPreconditionerApplyThread.Create(P, Input, Expected);
  Thread2 := TPreconditionerApplyThread.Create(P, OtherInput, OtherOutput);
  try
    Thread1.Start;
    Thread2.Start;
    Thread1.WaitFor;
    Thread2.WaitFor;
    AssertEquals('ILU concurrent apply one', '', Thread1.Failure);
    AssertEquals('ILU concurrent apply two', '', Thread2.Failure);
  finally
    Thread1.Free;
    Thread2.Free;
  end;
end;

procedure TIterativeSolverTest.TestWorkspaceAliasingConcurrencyAndFailure;
var
  A: ISparseDoubleMatrix;
  OperatorValue: ILinearDoubleOperator;
  B, X, Shared, BView, XView: IDenseDoubleMatrix;
  Workspace: TDoubleIterativeWorkspace;
  Options: TLinearSolveOptions;
  Diagnostics: TLinearSolveDiagnostics;
  ThreadValue: TWorkspaceSolveThread;
  Failed: Boolean;
begin
  A := TSparseDoubleMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1], [2.0, 3.0]);
  OperatorValue := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(2, 1, [4.0, 9.0]);
  X := TDenseDoubleMatrix.FromValues(2, 1, [71.0, 72.0]);
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1.0e-12;
  Workspace := TDoubleIterativeWorkspace.Create;
  try
    Failed := False;
    try
      Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
        OperatorValue, B, B, Workspace, Options);
    except
      on EIterativeSolverError do Failed := True;
    end;
    AssertTrue('exact RHS/solution alias rejected', Failed);
    AssertEquals('exact alias failure leaves RHS unchanged',
      4.0, B[0, 0], 0.0);

    Shared := TDenseDoubleMatrix.FromValues(
      2, 2, [4.0, 81.0, 9.0, 82.0]);
    BView := Shared.ColumnView(0);
    XView := Shared.ColumnView(1);
    Failed := False;
    try
      Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
        OperatorValue, BView, XView, Workspace, Options);
    except
      on EIterativeSolverError do Failed := True;
    end;
    AssertTrue('partial RHS/solution alias rejected', Failed);
    AssertEquals('partial alias failure leaves solution unchanged',
      82.0, XView[1, 0], 0.0);

    Options.RelativeTolerance := -1.0;
    Failed := False;
    try
      Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
        OperatorValue, B, X, Workspace, Options);
    except
      on EIterativeSolverError do Failed := True;
    end;
    AssertTrue('invalid options rejected before solve', Failed);
    AssertEquals('option failure leaves solution unchanged',
      71.0, X[0, 0], 0.0);

    Options := TLinearSolveOptions.Default;
    Options.RelativeTolerance := 1.0e-12;
    X[0, 0] := 0.0;
    X[1, 0] := 0.0;
    Workspace.BeginUse;
    ThreadValue := TWorkspaceSolveThread.Create(
      OperatorValue, B, X, Workspace, Options);
    try
      ThreadValue.Start;
      ThreadValue.WaitFor;
      AssertTrue('concurrent workspace use rejected',
        Pos('Iterative workspace:', ThreadValue.Failure) > 0);
    finally
      ThreadValue.Free;
      Workspace.EndUse;
    end;
    AssertEquals('concurrent rejection leaves solution unchanged',
      0.0, X[0, 0], 0.0);

    Diagnostics := TDoubleIterativeSolver.ConjugateGradientInto(
      OperatorValue, B, X, Workspace, Options);
    AssertEquals('workspace reusable after failures',
      Ord(isConverged), Ord(Diagnostics.Status));
    AssertEquals('workspace reuse solution x0', 2.0, X[0, 0], 1.0e-12);
    AssertEquals('workspace reuse solution x1', 3.0, X[1, 0], 1.0e-12);
  finally
    Workspace.Free;
  end;
end;

procedure TIterativeSolverTest.TestFourScalarAllIterativeMethods;
var
  Options: TLinearSolveOptions;
  ASingle, RectSingle: ISparseSingleMatrix;
  AD, RectD: ISparseDoubleMatrix;
  ASC, RectSC: ISparseSingleComplexMatrix;
  AC, RectC: ISparseComplexMatrix;
  OpS, RectOpS: ILinearSingleOperator;
  OpD, RectOpD: ILinearDoubleOperator;
  OpSC, RectOpSC: ILinearSingleComplexOperator;
  OpC, RectOpC: ILinearComplexOperator;
  BS, RectBS: IDenseSingleMatrix;
  BD, RectBD: IDenseDoubleMatrix;
  BSC, RectBSC: IDenseSingleComplexMatrix;
  BC, RectBC: IDenseComplexMatrix;
  RS: TSingleLinearSolveResult;
  RD: TDoubleLinearSolveResult;
  RSC: TSingleComplexLinearSolveResult;
  RC: TComplexLinearSolveResult;
begin
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1.0e-5;
  Options.AbsoluteTolerance := 1.0e-6;
  Options.RestartSize := 2;

  ASingle := TSparseSingleMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1], [2.0, 3.0]);
  RectSingle := TSparseSingleMatrix.FromCSR(
    3, 2, [0, 1, 2, 2], [0, 1], [2.0, 3.0]);
  OpS := TSingleLinearOperator.FromSparse(ASingle);
  RectOpS := TSingleLinearOperator.FromSparse(RectSingle);
  BS := TDenseSingleMatrix.FromValues(2, 1, [2.0, 6.0]);
  RectBS := TDenseSingleMatrix.FromValues(3, 1, [2.0, 6.0, 0.0]);
  RS := TSingleIterativeSolver.ConjugateGradient(OpS, BS, Options);
  AssertEquals('single CG status', Ord(isConverged),
    Ord(RS.Diagnostics.Status));
  RS := TSingleIterativeSolver.MINRES(OpS, BS, Options);
  AssertEquals('single MINRES status', Ord(isConverged),
    Ord(RS.Diagnostics.Status));
  RS := TSingleIterativeSolver.GMRES(OpS, BS, Options);
  AssertEquals('single GMRES status', Ord(isConverged),
    Ord(RS.Diagnostics.Status));
  RS := TSingleIterativeSolver.BiCGSTAB(OpS, BS, Options);
  AssertEquals('single BiCGSTAB status', Ord(isConverged),
    Ord(RS.Diagnostics.Status));
  RS := TSingleIterativeSolver.LSQR(RectOpS, RectBS, Options);
  AssertEquals('single LSQR status', Ord(isConverged),
    Ord(RS.Diagnostics.Status));
  AssertEquals('single LSQR solution', 2.0, RS.Solution[1, 0], 1.0e-4);

  AD := TSparseDoubleMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1], [2.0, 3.0]);
  RectD := TSparseDoubleMatrix.FromCSR(
    3, 2, [0, 1, 2, 2], [0, 1], [2.0, 3.0]);
  OpD := TDoubleLinearOperator.FromSparse(AD);
  RectOpD := TDoubleLinearOperator.FromSparse(RectD);
  BD := TDenseDoubleMatrix.FromValues(2, 1, [2.0, 6.0]);
  RectBD := TDenseDoubleMatrix.FromValues(3, 1, [2.0, 6.0, 0.0]);
  RD := TDoubleIterativeSolver.ConjugateGradient(OpD, BD, Options);
  AssertEquals('double CG status', Ord(isConverged),
    Ord(RD.Diagnostics.Status));
  RD := TDoubleIterativeSolver.MINRES(OpD, BD, Options);
  AssertEquals('double MINRES status', Ord(isConverged),
    Ord(RD.Diagnostics.Status));
  RD := TDoubleIterativeSolver.GMRES(OpD, BD, Options);
  AssertEquals('double GMRES status', Ord(isConverged),
    Ord(RD.Diagnostics.Status));
  RD := TDoubleIterativeSolver.BiCGSTAB(OpD, BD, Options);
  AssertEquals('double BiCGSTAB status', Ord(isConverged),
    Ord(RD.Diagnostics.Status));
  RD := TDoubleIterativeSolver.LSQR(RectOpD, RectBD, Options);
  AssertEquals('double LSQR status', Ord(isConverged),
    Ord(RD.Diagnostics.Status));
  AssertEquals('double LSQR solution', 2.0, RD.Solution[1, 0], 1.0e-8);

  ASC := TSparseSingleComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(3.0, 0.0)]);
  RectSC := TSparseSingleComplexMatrix.FromCSR(
    3, 2, [0, 1, 2, 2], [0, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(3.0, 0.0)]);
  OpSC := TSingleComplexLinearOperator.FromSparse(ASC);
  RectOpSC := TSingleComplexLinearOperator.FromSparse(RectSC);
  BSC := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.Create(2.0, 2.0),
     TSingleComplex.Create(6.0, -3.0)]);
  RectBSC := TDenseSingleComplexMatrix.FromValues(3, 1,
    [TSingleComplex.Create(2.0, 2.0),
     TSingleComplex.Create(6.0, -3.0), TSingleComplex.Zero]);
  RSC := TSingleComplexIterativeSolver.ConjugateGradient(
    OpSC, BSC, Options);
  AssertEquals('single-complex CG status', Ord(isConverged),
    Ord(RSC.Diagnostics.Status));
  RSC := TSingleComplexIterativeSolver.MINRES(OpSC, BSC, Options);
  AssertEquals('single-complex MINRES status', Ord(isConverged),
    Ord(RSC.Diagnostics.Status));
  RSC := TSingleComplexIterativeSolver.GMRES(OpSC, BSC, Options);
  AssertEquals('single-complex GMRES status', Ord(isConverged),
    Ord(RSC.Diagnostics.Status));
  RSC := TSingleComplexIterativeSolver.BiCGSTAB(OpSC, BSC, Options);
  AssertEquals('single-complex BiCGSTAB status', Ord(isConverged),
    Ord(RSC.Diagnostics.Status));
  RSC := TSingleComplexIterativeSolver.LSQR(RectOpSC, RectBSC, Options);
  AssertEquals('single-complex LSQR status', Ord(isConverged),
    Ord(RSC.Diagnostics.Status));
  AssertEquals('single-complex LSQR solution real',
    2.0, RSC.Solution[1, 0].Re, 1.0e-4);
  AssertEquals('single-complex LSQR solution imaginary',
    -1.0, RSC.Solution[1, 0].Im, 1.0e-4);

  AC := TSparseComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TComplex.Create(2.0, 0.0), TComplex.Create(3.0, 0.0)]);
  RectC := TSparseComplexMatrix.FromCSR(
    3, 2, [0, 1, 2, 2], [0, 1],
    [TComplex.Create(2.0, 0.0), TComplex.Create(3.0, 0.0)]);
  OpC := TComplexLinearOperator.FromSparse(AC);
  RectOpC := TComplexLinearOperator.FromSparse(RectC);
  BC := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(2.0, 2.0), TComplex.Create(6.0, -3.0)]);
  RectBC := TDenseComplexMatrix.FromValues(3, 1,
    [TComplex.Create(2.0, 2.0), TComplex.Create(6.0, -3.0),
     TComplex.Zero]);
  RC := TComplexIterativeSolver.ConjugateGradient(OpC, BC, Options);
  AssertEquals('complex CG status', Ord(isConverged),
    Ord(RC.Diagnostics.Status));
  RC := TComplexIterativeSolver.MINRES(OpC, BC, Options);
  AssertEquals('complex MINRES status', Ord(isConverged),
    Ord(RC.Diagnostics.Status));
  RC := TComplexIterativeSolver.GMRES(OpC, BC, Options);
  AssertEquals('complex GMRES status', Ord(isConverged),
    Ord(RC.Diagnostics.Status));
  RC := TComplexIterativeSolver.BiCGSTAB(OpC, BC, Options);
  AssertEquals('complex BiCGSTAB status', Ord(isConverged),
    Ord(RC.Diagnostics.Status));
  RC := TComplexIterativeSolver.LSQR(RectOpC, RectBC, Options);
  AssertEquals('complex LSQR status', Ord(isConverged),
    Ord(RC.Diagnostics.Status));
  AssertEquals('complex LSQR solution real',
    2.0, RC.Solution[1, 0].Re, 1.0e-8);
  AssertEquals('complex LSQR solution imaginary',
    -1.0, RC.Solution[1, 0].Im, 1.0e-8);
end;

procedure TIterativeSolverTest.TestProgressAndResidualRefresh;
var
  A: ISparseDoubleMatrix;
  Options: TLinearSolveOptions;
  ResultValue: TDoubleLinearSolveResult;
  MonitorObject: TRecordingMonitor;
  Monitor: IIterationMonitor;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 3, [0, 2, 5, 7],
    [0, 1, 0, 1, 2, 1, 2],
    [4.0, 1.0, 1.0, 4.0, 1.0, 1.0, 3.0]);
  MonitorObject := TRecordingMonitor.Create;
  Monitor := MonitorObject;
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1.0e-12;
  Options.ResidualRefresh := 1;
  Options.Monitor := Monitor;
  ResultValue := TDoubleIterativeSolver.ConjugateGradient(
    TDoubleLinearOperator.FromSparse(A),
    TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 3.0]),
    Options);
  AssertEquals('refresh fixture converged', Ord(isConverged),
    Ord(ResultValue.Diagnostics.Status));
  AssertTrue('progress callback invoked', MonitorObject.Reports > 0);
  AssertTrue('explicit residual refresh occurred',
    ResultValue.Diagnostics.ResidualRefreshCount > 0);
  AssertTrue('refresh result residual confirmed',
    ResultValue.Diagnostics.ResidualConfirmed);
  AssertTrue('refresh result convergence confirmed',
    ResultValue.Diagnostics.ConvergenceConfirmed);
end;

procedure TIterativeSolverTest.TestFourScalarPreconditionerFamilies;
var
  PS: ISinglePreconditioner;
  PD: IDoublePreconditioner;
  PSC: ISingleComplexPreconditioner;
  PC: IComplexPreconditioner;
  SparseS: ISparseSingleMatrix;
  SparseSC: ISparseSingleComplexMatrix;
  SparseC: ISparseComplexMatrix;
  XS, YS: IDenseSingleMatrix;
  XD, YD: IDenseDoubleMatrix;
  XSC, YSC: IDenseSingleComplexMatrix;
  XC, YC: IDenseComplexMatrix;
begin
  XS := TDenseSingleMatrix.FromValues(2, 1, [2.0, 8.0]);
  YS := TDenseSingleMatrix.Zeros(2, 1);
  PS := TSinglePreconditioner.Identity(2);
  PS.Apply(XS, YS);
  AssertEquals('single identity preconditioner',
    8.0, YS[1, 0], 1.0e-6);
  PS := TSinglePreconditioner.Diagonal([2.0, 4.0]);
  PS.Apply(XS, YS);
  AssertEquals('single diagonal preconditioner',
    2.0, YS[1, 0], 1.0e-6);
  SparseS := TSparseSingleMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1], [2.0, 4.0]);
  PS := TSinglePreconditioner.IncompleteCholesky0(SparseS);
  PS.Apply(XS, YS);
  AssertEquals('single IC preconditioner',
    2.0, YS[1, 0], 1.0e-5);
  PS := TSinglePreconditioner.ILU0(SparseS);
  PS.Apply(XS, YS);
  AssertEquals('single ILU preconditioner',
    2.0, YS[1, 0], 1.0e-5);

  XD := TDenseDoubleMatrix.FromValues(2, 1, [2.0, 8.0]);
  YD := TDenseDoubleMatrix.Zeros(2, 1);
  PD := TDoublePreconditioner.Identity(2);
  PD.Apply(XD, YD);
  AssertEquals('double identity preconditioner',
    8.0, YD[1, 0], 1.0e-12);
  PD := TDoublePreconditioner.Diagonal([2.0, 4.0]);
  PD.Apply(XD, YD);
  AssertEquals('double diagonal preconditioner',
    2.0, YD[1, 0], 1.0e-12);

  XSC := TDenseSingleComplexMatrix.FromValues(2, 1,
    [TSingleComplex.Create(2.0, 2.0),
     TSingleComplex.Create(8.0, -4.0)]);
  YSC := TDenseSingleComplexMatrix.Zeros(2, 1);
  PSC := TSingleComplexPreconditioner.Identity(2);
  PSC.Apply(XSC, YSC);
  AssertEquals('single-complex identity real',
    8.0, YSC[1, 0].Re, 1.0e-5);
  AssertEquals('single-complex identity imaginary',
    -4.0, YSC[1, 0].Im, 1.0e-5);
  PSC := TSingleComplexPreconditioner.Diagonal(
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(4.0, 0.0)]);
  PSC.Apply(XSC, YSC);
  AssertEquals('single-complex diagonal real',
    2.0, YSC[1, 0].Re, 1.0e-5);
  AssertEquals('single-complex diagonal imaginary',
    -1.0, YSC[1, 0].Im, 1.0e-5);
  SparseSC := TSparseSingleComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TSingleComplex.Create(2.0, 0.0),
     TSingleComplex.Create(4.0, 0.0)]);
  PSC := TSingleComplexPreconditioner.IncompleteCholesky0(SparseSC);
  PSC.Apply(XSC, YSC);
  AssertEquals('single-complex IC real',
    2.0, YSC[1, 0].Re, 1.0e-5);
  PSC := TSingleComplexPreconditioner.ILU0(SparseSC);
  PSC.Apply(XSC, YSC);
  AssertEquals('single-complex ILU imaginary',
    -1.0, YSC[1, 0].Im, 1.0e-5);

  XC := TDenseComplexMatrix.FromValues(2, 1,
    [TComplex.Create(2.0, 2.0), TComplex.Create(8.0, -4.0)]);
  YC := TDenseComplexMatrix.Zeros(2, 1);
  PC := TComplexPreconditioner.Identity(2);
  PC.Apply(XC, YC);
  AssertEquals('complex identity real',
    8.0, YC[1, 0].Re, 1.0e-12);
  PC := TComplexPreconditioner.Diagonal(
    [TComplex.Create(2.0, 0.0), TComplex.Create(4.0, 0.0)]);
  PC.Apply(XC, YC);
  AssertEquals('complex diagonal imaginary',
    -1.0, YC[1, 0].Im, 1.0e-12);
  SparseC := TSparseComplexMatrix.FromCSR(
    2, 2, [0, 1, 2], [0, 1],
    [TComplex.Create(2.0, 0.0), TComplex.Create(4.0, 0.0)]);
  PC := TComplexPreconditioner.IncompleteCholesky0(SparseC);
  PC.Apply(XC, YC);
  AssertEquals('complex IC real',
    2.0, YC[1, 0].Re, 1.0e-12);
  PC := TComplexPreconditioner.ILU0(SparseC);
  PC.Apply(XC, YC);
  AssertEquals('complex ILU imaginary',
    -1.0, YC[1, 0].Im, 1.0e-12);
end;

initialization
  RegisterTest(TIterativeSolverTest);

end.
