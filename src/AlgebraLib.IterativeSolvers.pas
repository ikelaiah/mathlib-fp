unit AlgebraLib.IterativeSolvers;

{-----------------------------------------------------------------------------
 AlgebraLib.IterativeSolvers

 Portable typed Krylov solvers for mathlib-fp 1.9. The expert Into overloads
 reuse caller-provided solution and workspace storage. The simple overloads
 allocate both and return an owned solution handle.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math,
  MathBase.Complex, MathBase.Iteration,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators;

type
  EIterativeSolverError = class(Exception);

  TIterativeMethod = (
    imConjugateGradient,
    imMINRES,
    imGMRES,
    imBiCGSTAB,
    imLSQR
  );

  TLinearBreakdownReason = (
    lbrNone,
    lbrNonFiniteValue,
    lbrZeroDenominator,
    lbrNonPositiveCurvature,
    lbrNonPositivePreconditioner,
    lbrArnoldiInvariantSubspace,
    lbrLanczosBreakdown
  );

  IIterationMonitor = interface
    function ShouldCancel: Boolean;
    procedure ReportProgress(const Method: TIterativeMethod;
      const Iteration, ProductCount: SizeInt;
      const ResidualNorm, StoppingThreshold: Double);
  end;

  TLinearSolveOptions = record
    MaxIterations: SizeInt;
    RelativeTolerance: Double;
    AbsoluteTolerance: Double;
    RestartSize: SizeInt;
    ResidualRefresh: SizeInt;
    BreakdownTolerance: Double;
    ConfirmConvergence: Boolean;
    Monitor: IIterationMonitor;
    class function Default: TLinearSolveOptions; static;
  end;

  TLinearSolveDiagnostics = record
    Method: TIterativeMethod;
    Status: TIterationStatus;
    BreakdownReason: TLinearBreakdownReason;
    Iterations: SizeInt;
    ProductCount: SizeInt;
    InitialResidualNorm: Double;
    FinalResidualNorm: Double;
    InitialNormalResidualNorm: Double;
    FinalNormalResidualNorm: Double;
    ResidualRefreshCount: SizeInt;
    RequestedTolerance: Double;
    AchievedRelativeResidual: Double;
    ResidualConfirmed: Boolean;
    ConvergenceConfirmed: Boolean;
  end;

  generic TIterativeVector<T> = array of T;
  generic TIterativeVectorList<T> = array of specialize TIterativeVector<T>;

  generic TLinearSolveResult<T> = record
    Solution: specialize IDenseMatrix<T>;
    Diagnostics: TLinearSolveDiagnostics;
  end;

  TSingleLinearSolveResult = specialize TLinearSolveResult<Single>;
  TDoubleLinearSolveResult = specialize TLinearSolveResult<Double>;
  TSingleComplexLinearSolveResult =
    specialize TLinearSolveResult<TSingleComplex>;
  TComplexLinearSolveResult = specialize TLinearSolveResult<TComplex>;

  { A workspace is mutable and intentionally not reentrant. It owns all Krylov
    vectors, operator bridge buffers, and restarted-GMRES small storage. }
  generic TIterativeWorkspace<T> = class
  private
    FInUse: LongInt;
    FRows, FCols, FRestart, FVectorLength: SizeInt;
    FVectors: array[0..17] of specialize TIterativeVector<T>;
    FBasis: specialize TIterativeVectorList<T>;
    FH: specialize TIterativeVectorList<T>;
    FG, FS, FY: specialize TIterativeVector<T>;
    FC: array of Double;
    FDomainInput, FDomainOutput: specialize IDenseMatrix<T>;
    FRangeInput, FRangeOutput: specialize IDenseMatrix<T>;
    class function CreateDense(const Rows, Cols: SizeInt):
      specialize IDenseMatrix<T>; static;
  public
    destructor Destroy; override;
    procedure Prepare(const Rows, Cols, RestartSize: SizeInt);
    procedure BeginUse;
    procedure EndUse;
    function Vector(const Index: SizeInt): specialize TIterativeVector<T>;
    function Basis(const Index: SizeInt): specialize TIterativeVector<T>;
    function GetH(const Row, Col: SizeInt): T;
    procedure SetH(const Row, Col: SizeInt; const Value: T);
    property Rows: SizeInt read FRows;
    property Cols: SizeInt read FCols;
    property RestartSize: SizeInt read FRestart;
  end;

  TSingleIterativeWorkspace = specialize TIterativeWorkspace<Single>;
  TDoubleIterativeWorkspace = specialize TIterativeWorkspace<Double>;
  TSingleComplexIterativeWorkspace =
    specialize TIterativeWorkspace<TSingleComplex>;
  TComplexIterativeWorkspace = specialize TIterativeWorkspace<TComplex>;

  generic TIterativeSolver<T> = class
  private
    type
      TVector = specialize TIterativeVector<T>;
      TDense = specialize IDenseMatrix<T>;
      TOperator = specialize ILinearOperator<T>;
      TPreconditioner = specialize IPreconditioner<T>;
      TWorkspace = specialize TIterativeWorkspace<T>;
      TResult = specialize TLinearSolveResult<T>;
    class function NewVector(const Length: SizeInt): TVector; static;
    class function CreateDense(const Rows, Cols: SizeInt): TDense; static;
    class function FiniteDouble(const Value: Double): Boolean; static;
    class function SymmetryTolerance: Double; static;
    class procedure ValidateOptions(const Options: TLinearSolveOptions); static;
    class procedure ValidateSystem(const A: TOperator; const B, X: TDense;
      const SquareRequired: Boolean; const Method: TIterativeMethod;
      const Preconditioner: TPreconditioner); static;
    class procedure Zero(var A: TVector; const N: SizeInt); static;
    class procedure Copy(const Source: TVector; var Destination: TVector;
      const N: SizeInt); static;
    class procedure Load(const Source: TDense; var Destination: TVector;
      const N: SizeInt); static;
    class procedure Store(const Source: TVector; const Destination: TDense;
      const N: SizeInt); static;
    class function Dot(const A, B: TVector; const N: SizeInt): T; static;
    class function Norm2(const A: TVector; const N: SizeInt): Double; static;
    class procedure Axpy(var Y: TVector; const Alpha: T; const X: TVector;
      const N: SizeInt); static;
    class procedure ScaleCopy(var Destination: TVector; const Source: TVector;
      const Alpha: T; const N: SizeInt); static;
    class procedure ApplyOperator(const A: TOperator; const Input: TVector;
      var Destination: TVector; const Workspace: TWorkspace;
      const Adjoint: Boolean; var ProductCount: SizeInt); static;
    class procedure ApplyPreconditioner(const M: TPreconditioner;
      const Input: TVector; var Destination: TVector;
      const Workspace: TWorkspace; const N: SizeInt); static;
    class function TrueResidual(const A: TOperator; const B, X: TVector;
      var Residual, Scratch: TVector; const Workspace: TWorkspace;
      var ProductCount: SizeInt): Double; static;
    class function NormalResidualNorm(const A: TOperator;
      const Residual: TVector; var Scratch: TVector;
      const Workspace: TWorkspace; var ProductCount: SizeInt): Double; static;
    class procedure InitializeDiagnostics(var Diagnostics: TLinearSolveDiagnostics;
      const Method: TIterativeMethod); static;
    class function Threshold(const InitialNorm: Double;
      const Options: TLinearSolveOptions): Double; static;
    class function Cancelled(const Options: TLinearSolveOptions): Boolean; static;
    class procedure Progress(const Options: TLinearSolveOptions;
      const Method: TIterativeMethod; const Iteration, ProductCount: SizeInt;
      const Residual, StopThreshold: Double); static;
    class procedure FinishDiagnostics(var Diagnostics: TLinearSolveDiagnostics;
      const InitialNorm, FinalNorm, StopThreshold: Double;
      const Confirmed: Boolean); static;
    class function MakeSimpleSolution(const Cols: SizeInt): TDense; static;
  public
    class function ConjugateGradient(const A: TOperator; const B: TDense;
      const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil): TResult; static;
    class function ConjugateGradientInto(const A: TOperator; const B,
      Solution: TDense; const Workspace: TWorkspace;
      const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil):
      TLinearSolveDiagnostics; static;
    class function MINRES(const A: TOperator; const B: TDense;
      const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil): TResult; static;
    class function MINRESInto(const A: TOperator; const B, Solution: TDense;
      const Workspace: TWorkspace; const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil):
      TLinearSolveDiagnostics; static;
    class function GMRES(const A: TOperator; const B: TDense;
      const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil): TResult; static;
    class function GMRESInto(const A: TOperator; const B, Solution: TDense;
      const Workspace: TWorkspace; const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil):
      TLinearSolveDiagnostics; static;
    class function BiCGSTAB(const A: TOperator; const B: TDense;
      const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil): TResult; static;
    class function BiCGSTABInto(const A: TOperator; const B, Solution: TDense;
      const Workspace: TWorkspace; const Options: TLinearSolveOptions;
      const Preconditioner: TPreconditioner = nil):
      TLinearSolveDiagnostics; static;
    class function LSQR(const A: TOperator; const B: TDense;
      const Options: TLinearSolveOptions): TResult; static;
    class function LSQRInto(const A: TOperator; const B, Solution: TDense;
      const Workspace: TWorkspace; const Options: TLinearSolveOptions):
      TLinearSolveDiagnostics; static;
  end;

  TSingleIterativeSolver = specialize TIterativeSolver<Single>;
  TDoubleIterativeSolver = specialize TIterativeSolver<Double>;
  TSingleComplexIterativeSolver =
    specialize TIterativeSolver<TSingleComplex>;
  TComplexIterativeSolver = specialize TIterativeSolver<TComplex>;

implementation

class function TLinearSolveOptions.Default: TLinearSolveOptions;
begin
  Result.MaxIterations := 1000;
  Result.RelativeTolerance := 1.0e-8;
  Result.AbsoluteTolerance := 0.0;
  Result.RestartSize := 30;
  Result.ResidualRefresh := 50;
  Result.BreakdownTolerance := 1.0e-30;
  Result.ConfirmConvergence := True;
  Result.Monitor := nil;
end;

class function TIterativeWorkspace.CreateDense(
  const Rows, Cols: SizeInt): specialize IDenseMatrix<T>;
begin
  case specialize TLinearScalar<T>.Kind of
    sskSingle:
      Result := specialize DenseInterfaceCast<Single, T>(
        TDenseSingleMatrix.Zeros(Rows, Cols));
    sskDouble:
      Result := specialize DenseInterfaceCast<Double, T>(
        TDenseDoubleMatrix.Zeros(Rows, Cols));
    sskSingleComplex:
      Result := specialize DenseInterfaceCast<TSingleComplex, T>(
        TDenseSingleComplexMatrix.Zeros(Rows, Cols));
  else
    Result := specialize DenseInterfaceCast<TComplex, T>(
      TDenseComplexMatrix.Zeros(Rows, Cols));
  end;
end;

destructor TIterativeWorkspace.Destroy;
begin
  { FPC 3.2.2 does not reliably finalize every repeated generic-interface
    field in this specialization. Clear the cached bridges explicitly; the
    assignments are also harmless on compilers which finalize them all. }
  FDomainInput := nil;
  FDomainOutput := nil;
  FRangeInput := nil;
  FRangeOutput := nil;
  inherited Destroy;
end;

procedure TIterativeWorkspace.Prepare(
  const Rows, Cols, RestartSize: SizeInt);
var
  I, J, RequiredLength: SizeInt;
begin
  if FInUse <> 0 then
    raise EIterativeSolverError.Create(
      'Iterative workspace: cannot resize while a solve is active.');
  if (Rows < 0) or (Cols < 0) or (RestartSize <= 0) then
    raise EIterativeSolverError.Create(
      'Iterative workspace: shapes must be non-negative and restart positive.');
  RequiredLength := Max(Rows, Cols);
  if RequiredLength > FVectorLength then
  begin
    for I := Low(FVectors) to High(FVectors) do
      SetLength(FVectors[I], RequiredLength);
    FVectorLength := RequiredLength;
  end;
  if RestartSize > FRestart then
  begin
    SetLength(FBasis, RestartSize + 1);
    for I := 0 to RestartSize do SetLength(FBasis[I], Cols);
    SetLength(FH, RestartSize + 1);
    for I := 0 to RestartSize do SetLength(FH[I], RestartSize);
    SetLength(FG, RestartSize + 1);
    SetLength(FS, RestartSize);
    SetLength(FY, RestartSize);
    SetLength(FC, RestartSize);
    FRestart := RestartSize;
  end
  else
    for I := 0 to High(FBasis) do
      if Length(FBasis[I]) < Cols then SetLength(FBasis[I], Cols);
  if (FRows <> Rows) or (FCols <> Cols) then
  begin
    FDomainInput := CreateDense(Cols, 1);
    FDomainOutput := CreateDense(Cols, 1);
    FRangeInput := CreateDense(Rows, 1);
    FRangeOutput := CreateDense(Rows, 1);
    FRows := Rows;
    FCols := Cols;
  end;
  for I := 0 to RestartSize do
    for J := 0 to RestartSize - 1 do FH[I][J] :=
      specialize TLinearScalar<T>.Zero;
end;

procedure TIterativeWorkspace.BeginUse;
begin
  if InterlockedCompareExchange(FInUse, 1, 0) <> 0 then
    raise EIterativeSolverError.Create(
      'Iterative workspace: concurrent or recursive reuse is not allowed.');
end;

procedure TIterativeWorkspace.EndUse;
begin
  InterlockedExchange(FInUse, 0);
end;

function TIterativeWorkspace.Vector(
  const Index: SizeInt): specialize TIterativeVector<T>;
begin
  if (Index < Low(FVectors)) or (Index > High(FVectors)) then
    raise EIterativeSolverError.Create(
      'Iterative workspace: vector index is outside the workspace.');
  Result := FVectors[Index];
end;

function TIterativeWorkspace.Basis(
  const Index: SizeInt): specialize TIterativeVector<T>;
begin
  if (Index < 0) or (Index >= Length(FBasis)) then
    raise EIterativeSolverError.Create(
      'Iterative workspace: basis index is outside the workspace.');
  Result := FBasis[Index];
end;

function TIterativeWorkspace.GetH(const Row, Col: SizeInt): T;
begin
  Result := FH[Row][Col];
end;

procedure TIterativeWorkspace.SetH(
  const Row, Col: SizeInt; const Value: T);
begin
  FH[Row][Col] := Value;
end;

class function TIterativeSolver.NewVector(const Length: SizeInt): TVector;
begin
  Result := nil;
  SetLength(Result, Length);
end;

class function TIterativeSolver.CreateDense(
  const Rows, Cols: SizeInt): TDense;
begin
  case specialize TLinearScalar<T>.Kind of
    sskSingle:
      Result := specialize DenseInterfaceCast<Single, T>(
        TDenseSingleMatrix.Zeros(Rows, Cols));
    sskDouble:
      Result := specialize DenseInterfaceCast<Double, T>(
        TDenseDoubleMatrix.Zeros(Rows, Cols));
    sskSingleComplex:
      Result := specialize DenseInterfaceCast<TSingleComplex, T>(
        TDenseSingleComplexMatrix.Zeros(Rows, Cols));
  else
    Result := specialize DenseInterfaceCast<TComplex, T>(
      TDenseComplexMatrix.Zeros(Rows, Cols));
  end;
end;

class function TIterativeSolver.FiniteDouble(
  const Value: Double): Boolean;
begin
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

class function TIterativeSolver.SymmetryTolerance: Double;
begin
  if specialize TLinearScalar<T>.Kind in [sskSingle, sskSingleComplex] then
    Result := 1.0e-5
  else
    Result := 1.0e-12;
end;

class procedure TIterativeSolver.ValidateOptions(
  const Options: TLinearSolveOptions);
begin
  if Options.MaxIterations < 0 then
    raise EIterativeSolverError.Create(
      'Iterative solver: maximum iterations must be non-negative.');
  if Options.RestartSize <= 0 then
    raise EIterativeSolverError.Create(
      'Iterative solver: restart size must be positive.');
  if Options.ResidualRefresh < 0 then
    raise EIterativeSolverError.Create(
      'Iterative solver: residual refresh must be non-negative.');
  if IsNan(Options.RelativeTolerance) or
     IsInfinite(Options.RelativeTolerance) or
     (Options.RelativeTolerance < 0.0) or
     IsNan(Options.AbsoluteTolerance) or
     IsInfinite(Options.AbsoluteTolerance) or
     (Options.AbsoluteTolerance < 0.0) or
     IsNan(Options.BreakdownTolerance) or
     IsInfinite(Options.BreakdownTolerance) or
     (Options.BreakdownTolerance < 0.0) then
    raise EIterativeSolverError.Create(
      'Iterative solver: tolerances must be finite and non-negative.');
end;

class procedure TIterativeSolver.ValidateSystem(const A: TOperator;
  const B, X: TDense; const SquareRequired: Boolean;
  const Method: TIterativeMethod; const Preconditioner: TPreconditioner);
begin
  if A = nil then
    raise EIterativeSolverError.Create(
      'Iterative solver: operator must not be nil.');
  if (A.ScalarKind <> specialize TLinearScalar<T>.Kind) then
    raise EIterativeSolverError.Create(
      'Iterative solver: operator scalar kind does not match solver.');
  if SquareRequired and (A.Rows <> A.Cols) then
    raise EIterativeSolverError.Create(
      'Iterative solver: this method requires a square operator.');
  if (B = nil) or (B.Rows <> A.Rows) or (B.Cols <> 1) then
    raise EIterativeSolverError.CreateFmt(
      'Iterative solver: right-hand side must have shape %d x 1.', [A.Rows]);
  if (X = nil) or (X.Rows <> A.Cols) or (X.Cols <> 1) then
    raise EIterativeSolverError.CreateFmt(
      'Iterative solver: solution must have shape %d x 1.', [A.Cols]);
  if (B.StorageIdentity <> nil) and
     (B.StorageIdentity = X.StorageIdentity) then
    raise EIterativeSolverError.Create(
      'Iterative solver: solution must not alias right-hand side.');
  if Preconditioner <> nil then
  begin
    if (Preconditioner.Size <> A.Cols) or
       (Preconditioner.ScalarKind <> A.ScalarKind) then
      raise EIterativeSolverError.Create(
        'Iterative solver: preconditioner size or scalar kind does not match.');
    if Method = imLSQR then
      raise EIterativeSolverError.Create(
        'LSQR: preconditioning is not supported by this entry point.');
  end;
end;

class procedure TIterativeSolver.Zero(var A: TVector; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do A[I] := specialize TLinearScalar<T>.Zero;
end;

class procedure TIterativeSolver.Copy(const Source: TVector;
  var Destination: TVector; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do Destination[I] := Source[I];
end;

class procedure TIterativeSolver.Load(const Source: TDense;
  var Destination: TVector; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do Destination[I] := Source[I, 0];
end;

class procedure TIterativeSolver.Store(const Source: TVector;
  const Destination: TDense; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do Destination[I, 0] := Source[I];
end;

class function TIterativeSolver.Dot(
  const A, B: TVector; const N: SizeInt): T;
var
  I: SizeInt;
begin
  Result := specialize TLinearScalar<T>.Zero;
  for I := 0 to N - 1 do
    Result := Result +
      specialize TLinearScalar<T>.Conjugate(A[I]) * B[I];
end;

class function TIterativeSolver.Norm2(
  const A: TVector; const N: SizeInt): Double;
var
  I: SizeInt;
  Scale, SumSquares, Value, Ratio: Double;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to N - 1 do
  begin
    Value := specialize TLinearScalar<T>.Magnitude(A[I]);
    if not FiniteDouble(Value) then Exit(NaN);
    if Value <> 0.0 then
      if Scale < Value then
      begin
        if Scale = 0.0 then SumSquares := 1.0
        else
        begin
          Ratio := Scale / Value;
          SumSquares := 1.0 + SumSquares * Ratio * Ratio;
        end;
        Scale := Value;
      end
      else
      begin
        Ratio := Value / Scale;
        SumSquares := SumSquares + Ratio * Ratio;
      end;
  end;
  if Scale = 0.0 then Result := 0.0
  else Result := Scale * Sqrt(SumSquares);
end;

class procedure TIterativeSolver.Axpy(var Y: TVector;
  const Alpha: T; const X: TVector; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do Y[I] := Y[I] + Alpha * X[I];
end;

class procedure TIterativeSolver.ScaleCopy(var Destination: TVector;
  const Source: TVector; const Alpha: T; const N: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to N - 1 do Destination[I] := Alpha * Source[I];
end;

class procedure TIterativeSolver.ApplyOperator(const A: TOperator;
  const Input: TVector; var Destination: TVector;
  const Workspace: TWorkspace; const Adjoint: Boolean;
  var ProductCount: SizeInt);
var
  I: SizeInt;
begin
  if Adjoint then
  begin
    for I := 0 to A.Rows - 1 do Workspace.FRangeInput[I, 0] := Input[I];
    A.ApplyAdjoint(Workspace.FRangeInput, Workspace.FDomainOutput);
    for I := 0 to A.Cols - 1 do Destination[I] :=
      Workspace.FDomainOutput[I, 0];
  end
  else
  begin
    for I := 0 to A.Cols - 1 do Workspace.FDomainInput[I, 0] := Input[I];
    A.Apply(Workspace.FDomainInput, Workspace.FRangeOutput);
    for I := 0 to A.Rows - 1 do Destination[I] :=
      Workspace.FRangeOutput[I, 0];
  end;
  Inc(ProductCount);
end;

class procedure TIterativeSolver.ApplyPreconditioner(
  const M: TPreconditioner; const Input: TVector;
  var Destination: TVector; const Workspace: TWorkspace; const N: SizeInt);
var
  I: SizeInt;
begin
  if M = nil then
  begin
    Copy(Input, Destination, N);
    Exit;
  end;
  for I := 0 to N - 1 do Workspace.FDomainInput[I, 0] := Input[I];
  M.Apply(Workspace.FDomainInput, Workspace.FDomainOutput);
  for I := 0 to N - 1 do Destination[I] :=
    Workspace.FDomainOutput[I, 0];
end;

class function TIterativeSolver.TrueResidual(const A: TOperator;
  const B, X: TVector; var Residual, Scratch: TVector;
  const Workspace: TWorkspace; var ProductCount: SizeInt): Double;
var
  I: SizeInt;
begin
  ApplyOperator(A, X, Scratch, Workspace, False, ProductCount);
  for I := 0 to A.Rows - 1 do Residual[I] := B[I] - Scratch[I];
  Result := Norm2(Residual, A.Rows);
end;

class function TIterativeSolver.NormalResidualNorm(const A: TOperator;
  const Residual: TVector; var Scratch: TVector;
  const Workspace: TWorkspace; var ProductCount: SizeInt): Double;
begin
  ApplyOperator(A, Residual, Scratch, Workspace, True, ProductCount);
  Result := Norm2(Scratch, A.Cols);
end;

class procedure TIterativeSolver.InitializeDiagnostics(
  var Diagnostics: TLinearSolveDiagnostics; const Method: TIterativeMethod);
begin
  Diagnostics.Method := Method;
  Diagnostics.Status := isUnknown;
  Diagnostics.BreakdownReason := lbrNone;
  Diagnostics.Iterations := 0;
  Diagnostics.ProductCount := 0;
  Diagnostics.InitialResidualNorm := NaN;
  Diagnostics.FinalResidualNorm := NaN;
  Diagnostics.InitialNormalResidualNorm := NaN;
  Diagnostics.FinalNormalResidualNorm := NaN;
  Diagnostics.RequestedTolerance := NaN;
  Diagnostics.AchievedRelativeResidual := NaN;
  Diagnostics.ResidualConfirmed := False;
  Diagnostics.ConvergenceConfirmed := False;
end;

class function TIterativeSolver.Threshold(const InitialNorm: Double;
  const Options: TLinearSolveOptions): Double;
begin
  Result := Max(Options.AbsoluteTolerance,
    Options.RelativeTolerance * InitialNorm);
end;

class function TIterativeSolver.Cancelled(
  const Options: TLinearSolveOptions): Boolean;
begin
  Result := (Options.Monitor <> nil) and Options.Monitor.ShouldCancel;
end;

class procedure TIterativeSolver.Progress(
  const Options: TLinearSolveOptions; const Method: TIterativeMethod;
  const Iteration, ProductCount: SizeInt;
  const Residual, StopThreshold: Double);
begin
  if Options.Monitor <> nil then
    Options.Monitor.ReportProgress(Method, Iteration, ProductCount,
      Residual, StopThreshold);
end;

class procedure TIterativeSolver.FinishDiagnostics(
  var Diagnostics: TLinearSolveDiagnostics;
  const InitialNorm, FinalNorm, StopThreshold: Double;
  const Confirmed: Boolean);
begin
  Diagnostics.InitialResidualNorm := InitialNorm;
  Diagnostics.FinalResidualNorm := FinalNorm;
  Diagnostics.RequestedTolerance := StopThreshold;
  Diagnostics.ResidualConfirmed := Confirmed;
  Diagnostics.ConvergenceConfirmed :=
    (Diagnostics.Status = isConverged) and Confirmed and
    (FinalNorm <= StopThreshold);
  if InitialNorm = 0.0 then
  begin
    if FinalNorm = 0.0 then Diagnostics.AchievedRelativeResidual := 0.0
    else Diagnostics.AchievedRelativeResidual := Infinity;
  end
  else
    Diagnostics.AchievedRelativeResidual := FinalNorm / InitialNorm;
end;

class function TIterativeSolver.MakeSimpleSolution(
  const Cols: SizeInt): TDense;
begin
  Result := CreateDense(Cols, 1);
end;

class function TIterativeSolver.ConjugateGradient(const A: TOperator;
  const B: TDense; const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TResult;
var
  Workspace: TWorkspace;
begin
  if A = nil then
    raise EIterativeSolverError.Create(
      'Conjugate gradient: operator must not be nil.');
  Result.Solution := MakeSimpleSolution(A.Cols);
  Workspace := TWorkspace.Create;
  try
    Result.Diagnostics := ConjugateGradientInto(
      A, B, Result.Solution, Workspace, Options, Preconditioner);
  finally
    Workspace.Free;
  end;
end;

class function TIterativeSolver.ConjugateGradientInto(const A: TOperator;
  const B, Solution: TDense; const Workspace: TWorkspace;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TLinearSolveDiagnostics;
var
  R, Z, P, Q, X, BV, Scratch: TVector;
  Rho, RhoNew, Denominator, Alpha, Beta: T;
  RhoReal, DenominatorReal, InitialNorm, FinalNorm, StopThreshold: Double;
  I, J: SizeInt;
  Confirmed: Boolean;
begin
  ValidateOptions(Options);
  ValidateSystem(A, B, Solution, True, imConjugateGradient, Preconditioner);
  if Workspace = nil then
    raise EIterativeSolverError.Create(
      'Conjugate gradient: workspace must not be nil.');
  Workspace.Prepare(A.Rows, A.Cols, Options.RestartSize);
  Workspace.BeginUse;
  InitializeDiagnostics(Result, imConjugateGradient);
  try
    R := Workspace.Vector(0);
    Z := Workspace.Vector(1);
    P := Workspace.Vector(2);
    Q := Workspace.Vector(3);
    X := Workspace.Vector(4);
    BV := Workspace.Vector(5);
    Scratch := Workspace.Vector(6);
    Load(B, BV, A.Rows);
    Load(Solution, X, A.Cols);
    InitialNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
      Result.ProductCount);
    FinalNorm := InitialNorm;
    StopThreshold := Threshold(InitialNorm, Options);
    Confirmed := True;
    if not FiniteDouble(InitialNorm) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonFiniteValue;
      Exit;
    end;
    if InitialNorm <= StopThreshold then
    begin
      Result.Status := isConverged;
      Exit;
    end;
    ApplyPreconditioner(Preconditioner, R, Z, Workspace, A.Cols);
    Rho := Dot(R, Z, A.Cols);
    RhoReal := specialize TLinearScalar<T>.RealPart(Rho);
    if (Abs(specialize TLinearScalar<T>.ImaginaryPart(Rho)) >
        Max(Options.BreakdownTolerance, SymmetryTolerance) *
        (1.0 + Abs(RhoReal))) or
       (RhoReal <= Options.BreakdownTolerance) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonPositivePreconditioner;
      Exit;
    end;
    Copy(Z, P, A.Cols);
    for I := 1 to Options.MaxIterations do
    begin
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      ApplyOperator(A, P, Q, Workspace, False, Result.ProductCount);
      Denominator := Dot(P, Q, A.Cols);
      DenominatorReal := specialize TLinearScalar<T>.RealPart(Denominator);
      if (Abs(specialize TLinearScalar<T>.ImaginaryPart(Denominator)) >
          Max(Options.BreakdownTolerance, SymmetryTolerance) *
          (1.0 + Abs(DenominatorReal))) or
         (DenominatorReal <= Options.BreakdownTolerance) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonPositiveCurvature;
        Break;
      end;
      Alpha := Rho / Denominator;
      Axpy(X, Alpha, P, A.Cols);
      Axpy(R, -Alpha, Q, A.Rows);
      Result.Iterations := I;
      Confirmed := False;
      if (Options.ResidualRefresh > 0) and
         (I mod Options.ResidualRefresh = 0) then
      begin
        FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
          Result.ProductCount);
        Inc(Result.ResidualRefreshCount);
        Confirmed := True;
      end
      else
        FinalNorm := Norm2(R, A.Rows);
      Progress(Options, imConjugateGradient, I, Result.ProductCount,
        FinalNorm, StopThreshold);
      if not FiniteDouble(FinalNorm) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonFiniteValue;
        Break;
      end;
      if FinalNorm <= StopThreshold then
      begin
        if Options.ConfirmConvergence and not Confirmed then
        begin
          FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
            Result.ProductCount);
          Confirmed := True;
        end;
        if FinalNorm <= StopThreshold then
        begin
          Result.Status := isConverged;
          Break;
        end;
      end;
      ApplyPreconditioner(Preconditioner, R, Z, Workspace, A.Cols);
      RhoNew := Dot(R, Z, A.Cols);
      RhoReal := specialize TLinearScalar<T>.RealPart(RhoNew);
      if (RhoReal <= Options.BreakdownTolerance) or
         not specialize TLinearScalar<T>.IsFinite(RhoNew) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonPositivePreconditioner;
        Break;
      end;
      Beta := RhoNew / Rho;
      for J := 0 to A.Cols - 1 do P[J] := Z[J] + Beta * P[J];
      Rho := RhoNew;
    end;
    if Result.Status = isUnknown then Result.Status := isIterationLimit;
    if not Confirmed then
    begin
      FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
        Result.ProductCount);
      Confirmed := True;
    end;
  finally
    Store(X, Solution, A.Cols);
    FinishDiagnostics(Result, InitialNorm, FinalNorm, StopThreshold, Confirmed);
    Workspace.EndUse;
  end;
end;

class function TIterativeSolver.MINRES(const A: TOperator; const B: TDense;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TResult;
var
  Workspace: TWorkspace;
begin
  if A = nil then
    raise EIterativeSolverError.Create('MINRES: operator must not be nil.');
  Result.Solution := MakeSimpleSolution(A.Cols);
  Workspace := TWorkspace.Create;
  try
    Result.Diagnostics := MINRESInto(A, B, Result.Solution, Workspace,
      Options, Preconditioner);
  finally
    Workspace.Free;
  end;
end;

class function TIterativeSolver.MINRESInto(const A: TOperator;
  const B, Solution: TDense; const Workspace: TWorkspace;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TLinearSolveDiagnostics;
var
  R1, R2, Y, V, W, W1, W2, X, BV, Scratch: TVector;
  DotValue: T;
  Beta1, Beta, OldBeta, Alpha, CS, SN, DBar, EpsLn, OldEps,
  Delta, GBar, Gamma, Phi, PhiBar, InitialNorm, FinalNorm,
  StopThreshold, InnerValue: Double;
  I, J: SizeInt;
  Scalar: T;
  Confirmed: Boolean;
begin
  ValidateOptions(Options);
  ValidateSystem(A, B, Solution, True, imMINRES, Preconditioner);
  if Workspace = nil then
    raise EIterativeSolverError.Create('MINRES: workspace must not be nil.');
  Workspace.Prepare(A.Rows, A.Cols, Options.RestartSize);
  Workspace.BeginUse;
  InitializeDiagnostics(Result, imMINRES);
  try
    R1 := Workspace.Vector(0);
    R2 := Workspace.Vector(1);
    Y := Workspace.Vector(2);
    V := Workspace.Vector(3);
    W := Workspace.Vector(4);
    W1 := Workspace.Vector(5);
    W2 := Workspace.Vector(6);
    X := Workspace.Vector(7);
    BV := Workspace.Vector(8);
    Scratch := Workspace.Vector(9);
    Load(B, BV, A.Rows);
    Load(Solution, X, A.Cols);
    InitialNorm := TrueResidual(A, BV, X, R2, Scratch, Workspace,
      Result.ProductCount);
    FinalNorm := InitialNorm;
    StopThreshold := Threshold(InitialNorm, Options);
    Confirmed := True;
    if not FiniteDouble(InitialNorm) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonFiniteValue;
      Exit;
    end;
    if InitialNorm <= StopThreshold then
    begin
      Result.Status := isConverged;
      Exit;
    end;
    ApplyPreconditioner(Preconditioner, R2, Y, Workspace, A.Cols);
    DotValue := Dot(R2, Y, A.Cols);
    InnerValue := specialize TLinearScalar<T>.RealPart(DotValue);
    if (InnerValue <= Options.BreakdownTolerance) or
       (Abs(specialize TLinearScalar<T>.ImaginaryPart(DotValue)) >
        Max(Options.BreakdownTolerance, SymmetryTolerance) *
        (1.0 + Abs(InnerValue))) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonPositivePreconditioner;
      Exit;
    end;
    Beta1 := Sqrt(InnerValue);
    Beta := Beta1;
    OldBeta := 0.0;
    CS := -1.0;
    SN := 0.0;
    DBar := 0.0;
    EpsLn := 0.0;
    PhiBar := Beta1;
    Zero(W, A.Cols);
    Zero(W1, A.Cols);
    Zero(W2, A.Cols);
    Zero(R1, A.Cols);
    for I := 1 to Options.MaxIterations do
    begin
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      Scalar := specialize TLinearScalar<T>.FromDouble(1.0 / Beta);
      ScaleCopy(V, Y, Scalar, A.Cols);
      ApplyOperator(A, V, Y, Workspace, False, Result.ProductCount);
      if I >= 2 then
        Axpy(Y, specialize TLinearScalar<T>.FromDouble(-Beta / OldBeta),
          R1, A.Cols);
      DotValue := Dot(V, Y, A.Cols);
      Alpha := specialize TLinearScalar<T>.RealPart(DotValue);
      if Abs(specialize TLinearScalar<T>.ImaginaryPart(DotValue)) >
         Max(Options.BreakdownTolerance, SymmetryTolerance) *
         (1.0 + Abs(Alpha)) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrLanczosBreakdown;
        Break;
      end;
      Axpy(Y, specialize TLinearScalar<T>.FromDouble(-Alpha / Beta),
        R2, A.Cols);
      Copy(R2, R1, A.Cols);
      Copy(Y, R2, A.Cols);
      ApplyPreconditioner(Preconditioner, R2, Y, Workspace, A.Cols);
      OldBeta := Beta;
      DotValue := Dot(R2, Y, A.Cols);
      InnerValue := specialize TLinearScalar<T>.RealPart(DotValue);
      if InnerValue < -Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonPositivePreconditioner;
        Break;
      end;
      Beta := Sqrt(Max(0.0, InnerValue));
      OldEps := EpsLn;
      Delta := CS * DBar + SN * Alpha;
      GBar := SN * DBar - CS * Alpha;
      EpsLn := SN * Beta;
      DBar := -CS * Beta;
      Gamma := Hypot(GBar, Beta);
      if Gamma <= Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      CS := GBar / Gamma;
      SN := Beta / Gamma;
      Phi := CS * PhiBar;
      PhiBar := SN * PhiBar;
      Copy(W1, W2, A.Cols);
      Copy(W, W1, A.Cols);
      for J := 0 to A.Cols - 1 do
        W[J] := (V[J] -
          specialize TLinearScalar<T>.FromDouble(OldEps) * W2[J] -
          specialize TLinearScalar<T>.FromDouble(Delta) * W1[J]) *
          specialize TLinearScalar<T>.FromDouble(1.0 / Gamma);
      Axpy(X, specialize TLinearScalar<T>.FromDouble(Phi), W, A.Cols);
      Result.Iterations := I;
      Confirmed := False;
      FinalNorm := Abs(PhiBar);
      if (Options.ResidualRefresh > 0) and
         (I mod Options.ResidualRefresh = 0) then
      begin
        FinalNorm := TrueResidual(A, BV, X, Scratch, V, Workspace,
          Result.ProductCount);
        Inc(Result.ResidualRefreshCount);
        Confirmed := True;
      end;
      Progress(Options, imMINRES, I, Result.ProductCount,
        FinalNorm, StopThreshold);
      if FinalNorm <= StopThreshold then
      begin
        if Options.ConfirmConvergence and not Confirmed then
        begin
          FinalNorm := TrueResidual(A, BV, X, Scratch, V, Workspace,
            Result.ProductCount);
          Confirmed := True;
        end;
        if FinalNorm <= StopThreshold then
        begin
          Result.Status := isConverged;
          Break;
        end;
      end;
      if Beta <= Options.BreakdownTolerance then
      begin
        FinalNorm := TrueResidual(A, BV, X, Scratch, V, Workspace,
          Result.ProductCount);
        Confirmed := True;
        if FinalNorm <= StopThreshold then Result.Status := isConverged
        else
        begin
          Result.Status := isNumericalBreakdown;
          Result.BreakdownReason := lbrLanczosBreakdown;
        end;
        Break;
      end;
    end;
    if Result.Status = isUnknown then Result.Status := isIterationLimit;
    if not Confirmed then
    begin
      FinalNorm := TrueResidual(A, BV, X, Scratch, V, Workspace,
        Result.ProductCount);
      Confirmed := True;
    end;
  finally
    Store(X, Solution, A.Cols);
    FinishDiagnostics(Result, InitialNorm, FinalNorm, StopThreshold, Confirmed);
    Workspace.EndUse;
  end;
end;

class function TIterativeSolver.GMRES(const A: TOperator; const B: TDense;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TResult;
var
  Workspace: TWorkspace;
begin
  if A = nil then
    raise EIterativeSolverError.Create('GMRES: operator must not be nil.');
  Result.Solution := MakeSimpleSolution(A.Cols);
  Workspace := TWorkspace.Create;
  try
    Result.Diagnostics := GMRESInto(A, B, Result.Solution, Workspace,
      Options, Preconditioner);
  finally
    Workspace.Free;
  end;
end;

class function TIterativeSolver.GMRESInto(const A: TOperator;
  const B, Solution: TDense; const Workspace: TWorkspace;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TLinearSolveDiagnostics;
var
  R, Z, W, X, BV, Scratch, VI: TVector;
  HValue, Temp, SValue, AlphaPhase: T;
  InitialNorm, FinalNorm, StopThreshold, BetaNorm, WNorm,
  AbsA, AbsB, RotationNorm: Double;
  I, J, K, InnerLimit, CycleSteps, TotalIterations: SizeInt;
  HappyBreakdown, Confirmed: Boolean;
begin
  ValidateOptions(Options);
  ValidateSystem(A, B, Solution, True, imGMRES, Preconditioner);
  if Workspace = nil then
    raise EIterativeSolverError.Create('GMRES: workspace must not be nil.');
  Workspace.Prepare(A.Rows, A.Cols, Options.RestartSize);
  Workspace.BeginUse;
  InitializeDiagnostics(Result, imGMRES);
  try
    R := Workspace.Vector(0);
    Z := Workspace.Vector(1);
    W := Workspace.Vector(2);
    X := Workspace.Vector(3);
    BV := Workspace.Vector(4);
    Scratch := Workspace.Vector(5);
    Load(B, BV, A.Rows);
    Load(Solution, X, A.Cols);
    InitialNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
      Result.ProductCount);
    FinalNorm := InitialNorm;
    StopThreshold := Threshold(InitialNorm, Options);
    Confirmed := True;
    if not FiniteDouble(InitialNorm) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonFiniteValue;
      Exit;
    end;
    if InitialNorm <= StopThreshold then
    begin
      Result.Status := isConverged;
      Exit;
    end;
    TotalIterations := 0;
    while TotalIterations < Options.MaxIterations do
    begin
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      ApplyPreconditioner(Preconditioner, R, Z, Workspace, A.Cols);
      BetaNorm := Norm2(Z, A.Cols);
      if (not FiniteDouble(BetaNorm)) or
         (BetaNorm <= Options.BreakdownTolerance) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonPositivePreconditioner;
        Break;
      end;
      VI := Workspace.Basis(0);
      ScaleCopy(VI, Z,
        specialize TLinearScalar<T>.FromDouble(1.0 / BetaNorm), A.Cols);
      for I := 0 to Options.RestartSize do
        Workspace.FG[I] := specialize TLinearScalar<T>.Zero;
      Workspace.FG[0] := specialize TLinearScalar<T>.FromDouble(BetaNorm);
      InnerLimit := Min(Options.RestartSize,
        Options.MaxIterations - TotalIterations);
      CycleSteps := 0;
      HappyBreakdown := False;
      for J := 0 to InnerLimit - 1 do
      begin
        VI := Workspace.Basis(J);
        ApplyOperator(A, VI, W, Workspace, False, Result.ProductCount);
        ApplyPreconditioner(Preconditioner, W, Z, Workspace, A.Cols);
        Copy(Z, W, A.Cols);
        for I := 0 to J do
        begin
          VI := Workspace.Basis(I);
          HValue := Dot(VI, W, A.Cols);
          Workspace.SetH(I, J, HValue);
          Axpy(W, -HValue, VI, A.Cols);
        end;
        WNorm := Norm2(W, A.Cols);
        Workspace.SetH(J + 1, J,
          specialize TLinearScalar<T>.FromDouble(WNorm));
        if WNorm > Options.BreakdownTolerance then
        begin
          VI := Workspace.Basis(J + 1);
          ScaleCopy(VI, W,
            specialize TLinearScalar<T>.FromDouble(1.0 / WNorm), A.Cols);
        end
        else
          HappyBreakdown := True;
        for I := 0 to J - 1 do
        begin
          HValue := Workspace.GetH(I, J);
          Temp := specialize TLinearScalar<T>.FromDouble(Workspace.FC[I]) *
            HValue + Workspace.FS[I] * Workspace.GetH(I + 1, J);
          Workspace.SetH(I + 1, J,
            -specialize TLinearScalar<T>.Conjugate(Workspace.FS[I]) *
            HValue +
            specialize TLinearScalar<T>.FromDouble(Workspace.FC[I]) *
            Workspace.GetH(I + 1, J));
          Workspace.SetH(I, J, Temp);
        end;
        HValue := Workspace.GetH(J, J);
        Temp := Workspace.GetH(J + 1, J);
        AbsA := specialize TLinearScalar<T>.Magnitude(HValue);
        AbsB := specialize TLinearScalar<T>.Magnitude(Temp);
        RotationNorm := Hypot(AbsA, AbsB);
        if RotationNorm <= Options.BreakdownTolerance then
        begin
          Workspace.FC[J] := 1.0;
          SValue := specialize TLinearScalar<T>.Zero;
        end
        else if AbsA = 0.0 then
        begin
          Workspace.FC[J] := 0.0;
          SValue := specialize TLinearScalar<T>.Conjugate(Temp) *
            specialize TLinearScalar<T>.FromDouble(1.0 / AbsB);
        end
        else
        begin
          Workspace.FC[J] := AbsA / RotationNorm;
          AlphaPhase := HValue *
            specialize TLinearScalar<T>.FromDouble(1.0 / AbsA);
          SValue := AlphaPhase *
            specialize TLinearScalar<T>.Conjugate(Temp) *
            specialize TLinearScalar<T>.FromDouble(1.0 / RotationNorm);
        end;
        Workspace.FS[J] := SValue;
        Workspace.SetH(J, J,
          specialize TLinearScalar<T>.FromDouble(Workspace.FC[J]) *
          HValue + SValue * Temp);
        Workspace.SetH(J + 1, J, specialize TLinearScalar<T>.Zero);
        HValue := Workspace.FG[J];
        Workspace.FG[J] :=
          specialize TLinearScalar<T>.FromDouble(Workspace.FC[J]) * HValue;
        Workspace.FG[J + 1] :=
          -specialize TLinearScalar<T>.Conjugate(SValue) * HValue;
        Inc(TotalIterations);
        CycleSteps := J + 1;
        Result.Iterations := TotalIterations;
        Progress(Options, imGMRES, TotalIterations, Result.ProductCount,
          specialize TLinearScalar<T>.Magnitude(Workspace.FG[J + 1]),
          StopThreshold);
        if Cancelled(Options) or HappyBreakdown or
           (specialize TLinearScalar<T>.Magnitude(Workspace.FG[J + 1]) <=
            StopThreshold) then Break;
      end;
      if CycleSteps = 0 then Break;
      for I := CycleSteps - 1 downto 0 do
      begin
        Temp := Workspace.FG[I];
        for K := I + 1 to CycleSteps - 1 do
          Temp := Temp - Workspace.GetH(I, K) * Workspace.FY[K];
        HValue := Workspace.GetH(I, I);
        if specialize TLinearScalar<T>.Magnitude(HValue) <=
           Options.BreakdownTolerance then
        begin
          Result.Status := isNumericalBreakdown;
          Result.BreakdownReason := lbrZeroDenominator;
          Break;
        end;
        Workspace.FY[I] := Temp / HValue;
      end;
      if Result.Status = isNumericalBreakdown then Break;
      for I := 0 to CycleSteps - 1 do
      begin
        VI := Workspace.Basis(I);
        Axpy(X, Workspace.FY[I], VI, A.Cols);
      end;
      FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
        Result.ProductCount);
      Confirmed := True;
      Progress(Options, imGMRES, TotalIterations, Result.ProductCount,
        FinalNorm, StopThreshold);
      if not FiniteDouble(FinalNorm) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonFiniteValue;
        Break;
      end;
      if FinalNorm <= StopThreshold then
      begin
        Result.Status := isConverged;
        Break;
      end;
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      if HappyBreakdown then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrArnoldiInvariantSubspace;
        Break;
      end;
    end;
    if Result.Status = isUnknown then Result.Status := isIterationLimit;
  finally
    Store(X, Solution, A.Cols);
    FinishDiagnostics(Result, InitialNorm, FinalNorm, StopThreshold, Confirmed);
    Workspace.EndUse;
  end;
end;

class function TIterativeSolver.BiCGSTAB(const A: TOperator;
  const B: TDense; const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TResult;
var
  Workspace: TWorkspace;
begin
  if A = nil then
    raise EIterativeSolverError.Create('BiCGSTAB: operator must not be nil.');
  Result.Solution := MakeSimpleSolution(A.Cols);
  Workspace := TWorkspace.Create;
  try
    Result.Diagnostics := BiCGSTABInto(A, B, Result.Solution, Workspace,
      Options, Preconditioner);
  finally
    Workspace.Free;
  end;
end;

class function TIterativeSolver.BiCGSTABInto(const A: TOperator;
  const B, Solution: TDense; const Workspace: TWorkspace;
  const Options: TLinearSolveOptions;
  const Preconditioner: TPreconditioner): TLinearSolveDiagnostics;
var
  R, RHat, P, V, S, TWork, PHat, SHat, X, BV, Scratch: TVector;
  Rho, RhoOld, Alpha, Omega, Beta, Denominator, TT: T;
  InitialNorm, FinalNorm, StopThreshold: Double;
  I, J: SizeInt;
  Confirmed: Boolean;
begin
  ValidateOptions(Options);
  ValidateSystem(A, B, Solution, True, imBiCGSTAB, Preconditioner);
  if Workspace = nil then
    raise EIterativeSolverError.Create('BiCGSTAB: workspace must not be nil.');
  Workspace.Prepare(A.Rows, A.Cols, Options.RestartSize);
  Workspace.BeginUse;
  InitializeDiagnostics(Result, imBiCGSTAB);
  try
    R := Workspace.Vector(0);
    RHat := Workspace.Vector(1);
    P := Workspace.Vector(2);
    V := Workspace.Vector(3);
    S := Workspace.Vector(4);
    TWork := Workspace.Vector(5);
    PHat := Workspace.Vector(6);
    SHat := Workspace.Vector(7);
    X := Workspace.Vector(8);
    BV := Workspace.Vector(9);
    Scratch := Workspace.Vector(10);
    Load(B, BV, A.Rows);
    Load(Solution, X, A.Cols);
    InitialNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
      Result.ProductCount);
    FinalNorm := InitialNorm;
    StopThreshold := Threshold(InitialNorm, Options);
    Confirmed := True;
    if not FiniteDouble(InitialNorm) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonFiniteValue;
      Exit;
    end;
    if InitialNorm <= StopThreshold then
    begin
      Result.Status := isConverged;
      Exit;
    end;
    Copy(R, RHat, A.Cols);
    Zero(P, A.Cols);
    Zero(V, A.Cols);
    RhoOld := specialize TLinearScalar<T>.One;
    Alpha := specialize TLinearScalar<T>.One;
    Omega := specialize TLinearScalar<T>.One;
    for I := 1 to Options.MaxIterations do
    begin
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      Rho := Dot(RHat, R, A.Cols);
      if specialize TLinearScalar<T>.Magnitude(Rho) <=
         Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      if I = 1 then Copy(R, P, A.Cols)
      else
      begin
        Beta := (Rho / RhoOld) * (Alpha / Omega);
        for J := 0 to A.Cols - 1 do
          P[J] := R[J] + Beta * (P[J] - Omega * V[J]);
      end;
      ApplyPreconditioner(Preconditioner, P, PHat, Workspace, A.Cols);
      ApplyOperator(A, PHat, V, Workspace, False, Result.ProductCount);
      Denominator := Dot(RHat, V, A.Cols);
      if specialize TLinearScalar<T>.Magnitude(Denominator) <=
         Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      Alpha := Rho / Denominator;
      Copy(R, S, A.Cols);
      Axpy(S, -Alpha, V, A.Cols);
      FinalNorm := Norm2(S, A.Cols);
      if FinalNorm <= StopThreshold then
      begin
        Axpy(X, Alpha, PHat, A.Cols);
        Result.Iterations := I;
        FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
          Result.ProductCount);
        Confirmed := True;
        if FinalNorm <= StopThreshold then Result.Status := isConverged;
        if Result.Status = isConverged then Break;
      end;
      ApplyPreconditioner(Preconditioner, S, SHat, Workspace, A.Cols);
      ApplyOperator(A, SHat, TWork, Workspace, False, Result.ProductCount);
      TT := Dot(TWork, TWork, A.Cols);
      if specialize TLinearScalar<T>.Magnitude(TT) <=
         Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      Omega := Dot(TWork, S, A.Cols) / TT;
      if specialize TLinearScalar<T>.Magnitude(Omega) <=
         Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      Axpy(X, Alpha, PHat, A.Cols);
      Axpy(X, Omega, SHat, A.Cols);
      Copy(S, R, A.Cols);
      Axpy(R, -Omega, TWork, A.Cols);
      Result.Iterations := I;
      Confirmed := False;
      if (Options.ResidualRefresh > 0) and
         (I mod Options.ResidualRefresh = 0) then
      begin
        FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
          Result.ProductCount);
        Inc(Result.ResidualRefreshCount);
        Confirmed := True;
      end
      else
        FinalNorm := Norm2(R, A.Cols);
      Progress(Options, imBiCGSTAB, I, Result.ProductCount,
        FinalNorm, StopThreshold);
      if not FiniteDouble(FinalNorm) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonFiniteValue;
        Break;
      end;
      if FinalNorm <= StopThreshold then
      begin
        if Options.ConfirmConvergence and not Confirmed then
        begin
          FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
            Result.ProductCount);
          Confirmed := True;
        end;
        if FinalNorm <= StopThreshold then
        begin
          Result.Status := isConverged;
          Break;
        end;
      end;
      RhoOld := Rho;
    end;
    if Result.Status = isUnknown then Result.Status := isIterationLimit;
    if not Confirmed then
    begin
      FinalNorm := TrueResidual(A, BV, X, R, Scratch, Workspace,
        Result.ProductCount);
      Confirmed := True;
    end;
  finally
    Store(X, Solution, A.Cols);
    FinishDiagnostics(Result, InitialNorm, FinalNorm, StopThreshold, Confirmed);
    Workspace.EndUse;
  end;
end;

class function TIterativeSolver.LSQR(const A: TOperator; const B: TDense;
  const Options: TLinearSolveOptions): TResult;
var
  Workspace: TWorkspace;
begin
  if A = nil then
    raise EIterativeSolverError.Create('LSQR: operator must not be nil.');
  Result.Solution := MakeSimpleSolution(A.Cols);
  Workspace := TWorkspace.Create;
  try
    Result.Diagnostics := LSQRInto(A, B, Result.Solution, Workspace, Options);
  finally
    Workspace.Free;
  end;
end;

class function TIterativeSolver.LSQRInto(const A: TOperator;
  const B, Solution: TDense; const Workspace: TWorkspace;
  const Options: TLinearSolveOptions): TLinearSolveDiagnostics;
var
  U, V, W, X, BV, Residual, Scratch, TempRows, TempCols: TVector;
  Alpha, Beta, RhoBar, PhiBar, Rho, C, S, Theta, Phi,
  InitialNorm, FinalNorm, InitialNormalNorm, FinalNormalNorm,
  StopThreshold: Double;
  I, J: SizeInt;
  Confirmed: Boolean;
begin
  ValidateOptions(Options);
  ValidateSystem(A, B, Solution, False, imLSQR, nil);
  if Workspace = nil then
    raise EIterativeSolverError.Create('LSQR: workspace must not be nil.');
  Workspace.Prepare(A.Rows, A.Cols, Options.RestartSize);
  Workspace.BeginUse;
  InitializeDiagnostics(Result, imLSQR);
  try
    U := Workspace.Vector(0);
    V := Workspace.Vector(1);
    W := Workspace.Vector(2);
    X := Workspace.Vector(3);
    BV := Workspace.Vector(4);
    Residual := Workspace.Vector(5);
    Scratch := Workspace.Vector(6);
    TempRows := Workspace.Vector(7);
    TempCols := Workspace.Vector(8);
    Load(B, BV, A.Rows);
    Load(Solution, X, A.Cols);
    InitialNorm := TrueResidual(A, BV, X, Residual, Scratch, Workspace,
      Result.ProductCount);
    InitialNormalNorm := NormalResidualNorm(A, Residual, TempCols,
      Workspace, Result.ProductCount);
    FinalNorm := InitialNorm;
    FinalNormalNorm := InitialNormalNorm;
    StopThreshold := Threshold(InitialNormalNorm, Options);
    Confirmed := True;
    if not FiniteDouble(InitialNorm) or
       not FiniteDouble(InitialNormalNorm) then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrNonFiniteValue;
      Exit;
    end;
    if InitialNormalNorm <= StopThreshold then
    begin
      Result.Status := isConverged;
      Exit;
    end;
    Copy(Residual, U, A.Rows);
    Beta := Norm2(U, A.Rows);
    ScaleCopy(U, U, specialize TLinearScalar<T>.FromDouble(1.0 / Beta),
      A.Rows);
    ApplyOperator(A, U, V, Workspace, True, Result.ProductCount);
    Alpha := Norm2(V, A.Cols);
    if Alpha <= Options.BreakdownTolerance then
    begin
      Result.Status := isNumericalBreakdown;
      Result.BreakdownReason := lbrLanczosBreakdown;
      Exit;
    end;
    ScaleCopy(V, V, specialize TLinearScalar<T>.FromDouble(1.0 / Alpha),
      A.Cols);
    Copy(V, W, A.Cols);
    RhoBar := Alpha;
    PhiBar := Beta;
    for I := 1 to Options.MaxIterations do
    begin
      if Cancelled(Options) then
      begin
        Result.Status := isCancelled;
        Break;
      end;
      ApplyOperator(A, V, TempRows, Workspace, False, Result.ProductCount);
      for J := 0 to A.Rows - 1 do
        U[J] := TempRows[J] -
          specialize TLinearScalar<T>.FromDouble(Alpha) * U[J];
      Beta := Norm2(U, A.Rows);
      if Beta > Options.BreakdownTolerance then
        ScaleCopy(U, U, specialize TLinearScalar<T>.FromDouble(1.0 / Beta),
          A.Rows);
      ApplyOperator(A, U, TempCols, Workspace, True, Result.ProductCount);
      for J := 0 to A.Cols - 1 do
        V[J] := TempCols[J] -
          specialize TLinearScalar<T>.FromDouble(Beta) * V[J];
      Alpha := Norm2(V, A.Cols);
      if Alpha > Options.BreakdownTolerance then
        ScaleCopy(V, V, specialize TLinearScalar<T>.FromDouble(1.0 / Alpha),
          A.Cols);
      Rho := Hypot(RhoBar, Beta);
      if Rho <= Options.BreakdownTolerance then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrZeroDenominator;
        Break;
      end;
      C := RhoBar / Rho;
      S := Beta / Rho;
      Theta := S * Alpha;
      RhoBar := -C * Alpha;
      Phi := C * PhiBar;
      PhiBar := S * PhiBar;
      Axpy(X, specialize TLinearScalar<T>.FromDouble(Phi / Rho), W,
        A.Cols);
      for J := 0 to A.Cols - 1 do
        W[J] := V[J] -
          specialize TLinearScalar<T>.FromDouble(Theta / Rho) * W[J];
      Result.Iterations := I;
      Confirmed := False;
      FinalNorm := Abs(PhiBar);
      FinalNormalNorm := Abs(Alpha * S * Phi);
      if (Options.ResidualRefresh > 0) and
         (I mod Options.ResidualRefresh = 0) then
      begin
        FinalNorm := TrueResidual(A, BV, X, Residual, Scratch, Workspace,
          Result.ProductCount);
        FinalNormalNorm := NormalResidualNorm(A, Residual, TempCols,
          Workspace, Result.ProductCount);
        Inc(Result.ResidualRefreshCount);
        Confirmed := True;
      end;
      Progress(Options, imLSQR, I, Result.ProductCount,
        FinalNormalNorm, StopThreshold);
      if not FiniteDouble(FinalNorm) or
         not FiniteDouble(FinalNormalNorm) then
      begin
        Result.Status := isNumericalBreakdown;
        Result.BreakdownReason := lbrNonFiniteValue;
        Break;
      end;
      if FinalNormalNorm <= StopThreshold then
      begin
        if Options.ConfirmConvergence and not Confirmed then
        begin
          FinalNorm := TrueResidual(A, BV, X, Residual, Scratch, Workspace,
            Result.ProductCount);
          FinalNormalNorm := NormalResidualNorm(A, Residual, TempCols,
            Workspace, Result.ProductCount);
          Confirmed := True;
        end;
        if FinalNormalNorm <= StopThreshold then
        begin
          Result.Status := isConverged;
          Break;
        end;
      end;
      if (Alpha <= Options.BreakdownTolerance) and
         (Beta <= Options.BreakdownTolerance) then
      begin
        FinalNorm := TrueResidual(A, BV, X, Residual, Scratch, Workspace,
          Result.ProductCount);
        FinalNormalNorm := NormalResidualNorm(A, Residual, TempCols,
          Workspace, Result.ProductCount);
        Confirmed := True;
        if FinalNormalNorm <= StopThreshold then
          Result.Status := isConverged
        else
        begin
          Result.Status := isNumericalBreakdown;
          Result.BreakdownReason := lbrLanczosBreakdown;
        end;
        Break;
      end;
    end;
    if Result.Status = isUnknown then Result.Status := isIterationLimit;
    if not Confirmed then
    begin
      FinalNorm := TrueResidual(A, BV, X, Residual, Scratch, Workspace,
        Result.ProductCount);
      FinalNormalNorm := NormalResidualNorm(A, Residual, TempCols,
        Workspace, Result.ProductCount);
      Confirmed := True;
    end;
  finally
    Store(X, Solution, A.Cols);
    FinishDiagnostics(Result, InitialNorm, FinalNorm, StopThreshold, Confirmed);
    Result.InitialNormalResidualNorm := InitialNormalNorm;
    Result.FinalNormalResidualNorm := FinalNormalNorm;
    Result.RequestedTolerance := StopThreshold;
    if InitialNormalNorm = 0.0 then
    begin
      if FinalNormalNorm = 0.0 then
        Result.AchievedRelativeResidual := 0.0
      else
        Result.AchievedRelativeResidual := Infinity;
    end
    else
      Result.AchievedRelativeResidual :=
        FinalNormalNorm / InitialNormalNorm;
    Result.ConvergenceConfirmed :=
      (Result.Status = isConverged) and Confirmed and
      (FinalNormalNorm <= StopThreshold);
    Workspace.EndUse;
  end;
end;

end.
