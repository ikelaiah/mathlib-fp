unit AlgebraLib.LinearOperators;

{-----------------------------------------------------------------------------
 AlgebraLib.LinearOperators

 Typed linear-operator and preconditioner contracts for mathlib-fp 1.9.
 Stored adapters retain their source handles. Sparse and structured handles are
 immutable and reentrant; a dense adapter retains mutable caller storage and is
 therefore not declared reentrant. Matrix-free behavior is delegated explicitly
 to an action object supplied by the caller.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices;

type
  ELinearOperatorError = class(Exception);
  EPreconditionerError = class(Exception);

  TLinearOperatorOwnership = (
    looRetainedImmutable,
    looRetainedMutable,
    looDelegated
  );

  TPreconditionerKind = (
    pkIdentity,
    pkDiagonal,
    pkIncompleteCholesky,
    pkILU0
  );

  generic TLinearScalar<T> = class
  private
    type
      PSingleValue = ^Single;
      PDoubleValue = ^Double;
      PSingleComplexValue = ^TSingleComplex;
      PComplexValue = ^TComplex;
  public
    class function Zero: T; static;
    class function One: T; static;
    class function FromDouble(const Value: Double): T; static;
    class function RealPart(const Value: T): Double; static;
    class function ImaginaryPart(const Value: T): Double; static;
    class function Conjugate(const Value: T): T; static;
    class function AbsSquared(const Value: T): Double; static;
    class function Magnitude(const Value: T): Double; static;
    class function IsFinite(const Value: T): Boolean; static;
    class function Kind: TSparseScalarKind; static;
    class procedure ValidateApplyShapes(
      const Input, Destination: specialize IDenseMatrix<T>;
      const InputRows, OutputRows: SizeInt;
      const Operation: string); static;
    class procedure ValidatePreconditionerVector(
      const Input, Destination: specialize IDenseMatrix<T>;
      const Size: SizeInt; const Operation: string); static;
  end;

  generic ILinearOperator<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOwnership: TLinearOperatorOwnership;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property Ownership: TLinearOperatorOwnership read GetOwnership;
    property IsReentrant: Boolean read GetIsReentrant;
  end;

  ILinearSingleOperator = specialize ILinearOperator<Single>;
  ILinearDoubleOperator = specialize ILinearOperator<Double>;
  ILinearSingleComplexOperator =
    specialize ILinearOperator<TSingleComplex>;
  ILinearComplexOperator = specialize ILinearOperator<TComplex>;

  generic IMatrixFreeAction<T> = interface
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
    function GetIsReentrant: Boolean;
    property IsReentrant: Boolean read GetIsReentrant;
  end;

  IMatrixFreeSingleAction = specialize IMatrixFreeAction<Single>;
  IMatrixFreeDoubleAction = specialize IMatrixFreeAction<Double>;
  IMatrixFreeSingleComplexAction =
    specialize IMatrixFreeAction<TSingleComplex>;
  IMatrixFreeComplexAction = specialize IMatrixFreeAction<TComplex>;

  generic TSparseLinearOperator<T> = class(TInterfacedObject,
    specialize ILinearOperator<T>)
  private
    FMatrix: specialize ISparseMatrix<T>;
  public
    constructor Create(const Matrix: specialize ISparseMatrix<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOwnership: TLinearOperatorOwnership;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TStructuredLinearOperator<T> = class(TInterfacedObject,
    specialize ILinearOperator<T>)
  private
    FMatrix: specialize IStructuredMatrix<T>;
  public
    constructor Create(const Matrix: specialize IStructuredMatrix<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOwnership: TLinearOperatorOwnership;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TDenseLinearOperator<T> = class(TInterfacedObject,
    specialize ILinearOperator<T>)
  private
    FMatrix: specialize IDenseMatrix<T>;
  public
    constructor Create(const Matrix: specialize IDenseMatrix<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOwnership: TLinearOperatorOwnership;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TMatrixFreeLinearOperator<T> = class(TInterfacedObject,
    specialize ILinearOperator<T>)
  private
    FRows, FCols: SizeInt;
    FAction: specialize IMatrixFreeAction<T>;
  public
    constructor Create(const Rows, Cols: SizeInt;
      const Action: specialize IMatrixFreeAction<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOwnership: TLinearOperatorOwnership;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    procedure ApplyAdjoint(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TLinearOperatorFactory<T> = class
  public
    class function FromSparse(const Matrix: specialize ISparseMatrix<T>):
      specialize ILinearOperator<T>; static;
    class function FromStructured(
      const Matrix: specialize IStructuredMatrix<T>):
      specialize ILinearOperator<T>; static;
    class function FromDense(const Matrix: specialize IDenseMatrix<T>):
      specialize ILinearOperator<T>; static;
    class function MatrixFree(const Rows, Cols: SizeInt;
      const Action: specialize IMatrixFreeAction<T>):
      specialize ILinearOperator<T>; static;
  end;

  TSingleLinearOperator = specialize TLinearOperatorFactory<Single>;
  TDoubleLinearOperator = specialize TLinearOperatorFactory<Double>;
  TSingleComplexLinearOperator =
    specialize TLinearOperatorFactory<TSingleComplex>;
  TComplexLinearOperator = specialize TLinearOperatorFactory<TComplex>;

  generic IPreconditioner<T> = interface
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetKind: TPreconditionerKind;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
    property Size: SizeInt read GetSize;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property Kind: TPreconditionerKind read GetKind;
    property IsReentrant: Boolean read GetIsReentrant;
  end;

  ISinglePreconditioner = specialize IPreconditioner<Single>;
  IDoublePreconditioner = specialize IPreconditioner<Double>;
  ISingleComplexPreconditioner =
    specialize IPreconditioner<TSingleComplex>;
  IComplexPreconditioner = specialize IPreconditioner<TComplex>;

  generic TIdentityPreconditioner<T> = class(TInterfacedObject,
    specialize IPreconditioner<T>)
  private
    FSize: SizeInt;
  public
    constructor Create(const ASize: SizeInt);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetKind: TPreconditionerKind;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TDiagonalPreconditioner<T> = class(TInterfacedObject,
    specialize IPreconditioner<T>)
  private
    FInverse: specialize TSparseValueArray<T>;
  public
    constructor Create(const Diagonal: array of T;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetKind: TPreconditionerKind;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TILU0Preconditioner<T> = class(TInterfacedObject,
    specialize IPreconditioner<T>)
  private
    FSize: SizeInt;
    FOuter, FInner, FDiagonal: TSparseSizeIntArray;
    FValues: specialize TSparseValueArray<T>;
    FPivotTolerance: Double;
    function FindPosition(const Row, Col: SizeInt): SizeInt;
  public
    constructor Create(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetKind: TPreconditionerKind;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TIC0Preconditioner<T> = class(TInterfacedObject,
    specialize IPreconditioner<T>)
  private
    FSize: SizeInt;
    FOuter, FInner, FDiagonal: TSparseSizeIntArray;
    FValues: specialize TSparseValueArray<T>;
    FPivotTolerance: Double;
    function FindPosition(const Row, Col: SizeInt): SizeInt;
  public
    constructor Create(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetKind: TPreconditionerKind;
    function GetIsReentrant: Boolean;
    procedure Apply(const Input, Destination: specialize IDenseMatrix<T>);
  end;

  generic TPreconditionerFactory<T> = class
  public
    class function Identity(const Size: SizeInt):
      specialize IPreconditioner<T>; static;
    class function Diagonal(const Values: array of T;
      const PivotTolerance: Double = 1.0e-14):
      specialize IPreconditioner<T>; static;
    class function SparseDiagonal(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize IPreconditioner<T>; static;
    class function IncompleteCholesky0(
      const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize IPreconditioner<T>; static;
    class function ILU0(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize IPreconditioner<T>; static;
  end;

  TSinglePreconditioner = specialize TPreconditionerFactory<Single>;
  TDoublePreconditioner = specialize TPreconditionerFactory<Double>;
  TSingleComplexPreconditioner =
    specialize TPreconditionerFactory<TSingleComplex>;
  TComplexPreconditioner = specialize TPreconditionerFactory<TComplex>;

implementation

class function TLinearScalar.Zero: T;
begin
  Result := Default(T);
end;

class function TLinearScalar.One: T;
begin
  Result := FromDouble(1.0);
end;

class function TLinearScalar.FromDouble(const Value: Double): T;
begin
  Result := Default(T);
  case Kind of
    sskSingle:
      PSingleValue(@Result)^ := Single(Value);
    sskDouble:
      PDoubleValue(@Result)^ := Value;
    sskSingleComplex:
      PSingleComplexValue(@Result)^ := TSingleComplex.Create(Value, 0.0);
    sskComplex:
      PComplexValue(@Result)^ := TComplex.Create(Value, 0.0);
  end;
end;

class function TLinearScalar.RealPart(const Value: T): Double;
begin
  case Kind of
    sskSingle:
      Result := PSingleValue(@Value)^;
    sskDouble:
      Result := PDoubleValue(@Value)^;
    sskSingleComplex:
      Result := PSingleComplexValue(@Value)^.Re;
  else
    Result := PComplexValue(@Value)^.Re;
  end;
end;

class function TLinearScalar.ImaginaryPart(const Value: T): Double;
begin
  case Kind of
    sskSingle, sskDouble:
      Result := 0.0;
    sskSingleComplex:
      Result := PSingleComplexValue(@Value)^.Im;
  else
    Result := PComplexValue(@Value)^.Im;
  end;
end;

class function TLinearScalar.Conjugate(const Value: T): T;
begin
  Result := specialize TSparseMatrixStorage<T>.ScalarConjugate(Value, Kind);
end;

class function TLinearScalar.AbsSquared(const Value: T): Double;
begin
  Result := specialize TSparseMatrixStorage<T>.ScalarAbsSquared(Value, Kind);
end;

class function TLinearScalar.Magnitude(const Value: T): Double;
begin
  Result := Sqrt(AbsSquared(Value));
end;

class function TLinearScalar.IsFinite(const Value: T): Boolean;
begin
  Result := specialize TSparseMatrixStorage<T>.ScalarIsFinite(Value, Kind);
end;

class function TLinearScalar.Kind: TSparseScalarKind;
begin
  Result := specialize TSparseMatrixStorage<T>.ScalarKindOf;
end;

class procedure TLinearScalar.ValidateApplyShapes(
  const Input, Destination: specialize IDenseMatrix<T>;
  const InputRows, OutputRows: SizeInt; const Operation: string);
begin
  if Input = nil then
    raise ELinearOperatorError.CreateFmt('%s: input must not be nil.',
      [Operation]);
  if Destination = nil then
    raise ELinearOperatorError.CreateFmt('%s: destination must not be nil.',
      [Operation]);
  if (Input.Rows <> InputRows) or (Input.Cols <> 1) then
    raise ELinearOperatorError.CreateFmt(
      '%s: input must have shape %d x 1.', [Operation, InputRows]);
  if (Destination.Rows <> OutputRows) or (Destination.Cols <> 1) then
    raise ELinearOperatorError.CreateFmt(
      '%s: destination must have shape %d x 1.', [Operation, OutputRows]);
  if (Input.StorageIdentity <> nil) and
     (Input.StorageIdentity = Destination.StorageIdentity) then
    raise ELinearOperatorError.CreateFmt(
      '%s: destination must not alias input.', [Operation]);
end;

class procedure TLinearScalar.ValidatePreconditionerVector(
  const Input, Destination: specialize IDenseMatrix<T>;
  const Size: SizeInt; const Operation: string);
begin
  if (Input = nil) or (Destination = nil) then
    raise EPreconditionerError.CreateFmt(
      '%s: input and destination must not be nil.', [Operation]);
  if (Input.Rows <> Size) or (Input.Cols <> 1) or
     (Destination.Rows <> Size) or (Destination.Cols <> 1) then
    raise EPreconditionerError.CreateFmt(
      '%s: input and destination must have shape %d x 1.',
      [Operation, Size]);
  if (Input.StorageIdentity <> nil) and
     (Input.StorageIdentity = Destination.StorageIdentity) and
     (Input <> Destination) then
    raise EPreconditionerError.CreateFmt(
      '%s: separate overlapping views are not supported.', [Operation]);
end;

constructor TSparseLinearOperator.Create(
  const Matrix: specialize ISparseMatrix<T>);
begin
  inherited Create;
  if Matrix = nil then
    raise ELinearOperatorError.Create(
      'Sparse linear operator: matrix must not be nil.');
  FMatrix := Matrix;
end;

function TSparseLinearOperator.GetRows: SizeInt;
begin
  Result := FMatrix.Rows;
end;

function TSparseLinearOperator.GetCols: SizeInt;
begin
  Result := FMatrix.Cols;
end;

function TSparseLinearOperator.GetScalarKind: TSparseScalarKind;
begin
  Result := FMatrix.ScalarKind;
end;

function TSparseLinearOperator.GetOwnership: TLinearOperatorOwnership;
begin
  Result := looRetainedImmutable;
end;

function TSparseLinearOperator.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TSparseLinearOperator.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C, K: SizeInt;
  Value: T;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Cols, FMatrix.Rows,
    'Sparse operator Apply');
  for R := 0 to FMatrix.Rows - 1 do
    Destination[R, 0] := specialize TLinearScalar<T>.Zero;
  if FMatrix.Format = sfCSR then
    for R := 0 to FMatrix.Rows - 1 do
      for K := FMatrix.GetOuterPointer(R) to
        FMatrix.GetOuterPointer(R + 1) - 1 do
      begin
        C := FMatrix.GetInnerIndex(K);
        Destination[R, 0] := Destination[R, 0] +
          FMatrix.GetStoredValue(K) * Input[C, 0];
      end
  else
    for C := 0 to FMatrix.Cols - 1 do
      for K := FMatrix.GetOuterPointer(C) to
        FMatrix.GetOuterPointer(C + 1) - 1 do
      begin
        R := FMatrix.GetInnerIndex(K);
        Value := Destination[R, 0] +
          FMatrix.GetStoredValue(K) * Input[C, 0];
        Destination[R, 0] := Value;
      end;
end;

procedure TSparseLinearOperator.ApplyAdjoint(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C, K: SizeInt;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Rows, FMatrix.Cols,
    'Sparse operator ApplyAdjoint');
  for C := 0 to FMatrix.Cols - 1 do
    Destination[C, 0] := specialize TLinearScalar<T>.Zero;
  if FMatrix.Format = sfCSR then
    for R := 0 to FMatrix.Rows - 1 do
      for K := FMatrix.GetOuterPointer(R) to
        FMatrix.GetOuterPointer(R + 1) - 1 do
      begin
        C := FMatrix.GetInnerIndex(K);
        Destination[C, 0] := Destination[C, 0] +
          specialize TLinearScalar<T>.Conjugate(
            FMatrix.GetStoredValue(K)) * Input[R, 0];
      end
  else
    for C := 0 to FMatrix.Cols - 1 do
      for K := FMatrix.GetOuterPointer(C) to
        FMatrix.GetOuterPointer(C + 1) - 1 do
      begin
        R := FMatrix.GetInnerIndex(K);
        Destination[C, 0] := Destination[C, 0] +
          specialize TLinearScalar<T>.Conjugate(
            FMatrix.GetStoredValue(K)) * Input[R, 0];
      end;
end;

constructor TStructuredLinearOperator.Create(
  const Matrix: specialize IStructuredMatrix<T>);
begin
  inherited Create;
  if Matrix = nil then
    raise ELinearOperatorError.Create(
      'Structured linear operator: matrix must not be nil.');
  FMatrix := Matrix;
end;

function TStructuredLinearOperator.GetRows: SizeInt;
begin
  Result := FMatrix.Rows;
end;

function TStructuredLinearOperator.GetCols: SizeInt;
begin
  Result := FMatrix.Cols;
end;

function TStructuredLinearOperator.GetScalarKind: TSparseScalarKind;
begin
  Result := FMatrix.ScalarKind;
end;

function TStructuredLinearOperator.GetOwnership: TLinearOperatorOwnership;
begin
  Result := looRetainedImmutable;
end;

function TStructuredLinearOperator.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TStructuredLinearOperator.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C, FirstCol, LastCol: SizeInt;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Cols, FMatrix.Rows,
    'Structured operator Apply');
  for R := 0 to FMatrix.Rows - 1 do
  begin
    Destination[R, 0] := specialize TLinearScalar<T>.Zero;
    FirstCol := Max(0, R - FMatrix.LowerBandwidth);
    LastCol := Min(FMatrix.Cols - 1, R + FMatrix.UpperBandwidth);
    for C := FirstCol to LastCol do
      Destination[R, 0] := Destination[R, 0] +
        FMatrix[R, C] * Input[C, 0];
  end;
end;

procedure TStructuredLinearOperator.ApplyAdjoint(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C, FirstCol, LastCol: SizeInt;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Rows, FMatrix.Cols,
    'Structured operator ApplyAdjoint');
  for C := 0 to FMatrix.Cols - 1 do
    Destination[C, 0] := specialize TLinearScalar<T>.Zero;
  for R := 0 to FMatrix.Rows - 1 do
  begin
    FirstCol := Max(0, R - FMatrix.LowerBandwidth);
    LastCol := Min(FMatrix.Cols - 1, R + FMatrix.UpperBandwidth);
    for C := FirstCol to LastCol do
      Destination[C, 0] := Destination[C, 0] +
        specialize TLinearScalar<T>.Conjugate(FMatrix[R, C]) * Input[R, 0];
  end;
end;

constructor TDenseLinearOperator.Create(
  const Matrix: specialize IDenseMatrix<T>);
begin
  inherited Create;
  if Matrix = nil then
    raise ELinearOperatorError.Create(
      'Dense linear operator: matrix must not be nil.');
  FMatrix := Matrix;
end;

function TDenseLinearOperator.GetRows: SizeInt;
begin
  Result := FMatrix.Rows;
end;

function TDenseLinearOperator.GetCols: SizeInt;
begin
  Result := FMatrix.Cols;
end;

function TDenseLinearOperator.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TDenseLinearOperator.GetOwnership: TLinearOperatorOwnership;
begin
  Result := looRetainedMutable;
end;

function TDenseLinearOperator.GetIsReentrant: Boolean;
begin
  Result := False;
end;

procedure TDenseLinearOperator.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Cols, FMatrix.Rows,
    'Dense operator Apply');
  for R := 0 to FMatrix.Rows - 1 do
  begin
    Destination[R, 0] := specialize TLinearScalar<T>.Zero;
    for C := 0 to FMatrix.Cols - 1 do
      Destination[R, 0] := Destination[R, 0] +
        FMatrix[R, C] * Input[C, 0];
  end;
end;

procedure TDenseLinearOperator.ApplyAdjoint(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FMatrix.Rows, FMatrix.Cols,
    'Dense operator ApplyAdjoint');
  for C := 0 to FMatrix.Cols - 1 do
  begin
    Destination[C, 0] := specialize TLinearScalar<T>.Zero;
    for R := 0 to FMatrix.Rows - 1 do
      Destination[C, 0] := Destination[C, 0] +
        specialize TLinearScalar<T>.Conjugate(FMatrix[R, C]) * Input[R, 0];
  end;
end;

constructor TMatrixFreeLinearOperator.Create(const Rows, Cols: SizeInt;
  const Action: specialize IMatrixFreeAction<T>);
begin
  inherited Create;
  specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Cols, SizeOf(T), 'Matrix-free operator shape');
  if Action = nil then
    raise ELinearOperatorError.Create(
      'Matrix-free operator: action must not be nil.');
  FRows := Rows;
  FCols := Cols;
  FAction := Action;
end;

function TMatrixFreeLinearOperator.GetRows: SizeInt;
begin
  Result := FRows;
end;

function TMatrixFreeLinearOperator.GetCols: SizeInt;
begin
  Result := FCols;
end;

function TMatrixFreeLinearOperator.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TMatrixFreeLinearOperator.GetOwnership: TLinearOperatorOwnership;
begin
  Result := looDelegated;
end;

function TMatrixFreeLinearOperator.GetIsReentrant: Boolean;
begin
  Result := FAction.IsReentrant;
end;

procedure TMatrixFreeLinearOperator.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FCols, FRows,
    'Matrix-free operator Apply');
  FAction.Apply(Input, Destination);
end;

procedure TMatrixFreeLinearOperator.ApplyAdjoint(const Input,
  Destination: specialize IDenseMatrix<T>);
begin
  specialize TLinearScalar<T>.ValidateApplyShapes(
    Input, Destination, FRows, FCols,
    'Matrix-free operator ApplyAdjoint');
  FAction.ApplyAdjoint(Input, Destination);
end;

class function TLinearOperatorFactory.FromSparse(
  const Matrix: specialize ISparseMatrix<T>): specialize ILinearOperator<T>;
begin
  Result := specialize TSparseLinearOperator<T>.Create(Matrix);
end;

class function TLinearOperatorFactory.FromStructured(
  const Matrix: specialize IStructuredMatrix<T>): specialize ILinearOperator<T>;
begin
  Result := specialize TStructuredLinearOperator<T>.Create(Matrix);
end;

class function TLinearOperatorFactory.FromDense(
  const Matrix: specialize IDenseMatrix<T>): specialize ILinearOperator<T>;
begin
  Result := specialize TDenseLinearOperator<T>.Create(Matrix);
end;

class function TLinearOperatorFactory.MatrixFree(const Rows, Cols: SizeInt;
  const Action: specialize IMatrixFreeAction<T>): specialize ILinearOperator<T>;
begin
  Result := specialize TMatrixFreeLinearOperator<T>.Create(Rows, Cols, Action);
end;

constructor TIdentityPreconditioner.Create(const ASize: SizeInt);
begin
  inherited Create;
  if ASize < 0 then
    raise EPreconditionerError.Create(
      'Identity preconditioner: size must be non-negative.');
  FSize := ASize;
end;

function TIdentityPreconditioner.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TIdentityPreconditioner.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TIdentityPreconditioner.GetKind: TPreconditionerKind;
begin
  Result := pkIdentity;
end;

function TIdentityPreconditioner.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TIdentityPreconditioner.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  I: SizeInt;
begin
  specialize TLinearScalar<T>.ValidatePreconditionerVector(
    Input, Destination, FSize,
    'Identity preconditioner Apply');
  if Input.StorageIdentity = Destination.StorageIdentity then Exit;
  for I := 0 to FSize - 1 do Destination[I, 0] := Input[I, 0];
end;

constructor TDiagonalPreconditioner.Create(const Diagonal: array of T;
  const PivotTolerance: Double);
var
  I: SizeInt;
begin
  inherited Create;
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise EPreconditionerError.Create(
      'Diagonal preconditioner: pivot tolerance must be finite and non-negative.');
  SetLength(FInverse, Length(Diagonal));
  for I := 0 to High(Diagonal) do
  begin
    if not specialize TLinearScalar<T>.IsFinite(Diagonal[I]) then
      raise EPreconditionerError.CreateFmt(
        'Diagonal preconditioner: diagonal %d is non-finite.', [I]);
    if specialize TLinearScalar<T>.Magnitude(Diagonal[I]) <= PivotTolerance then
      raise EPreconditionerError.CreateFmt(
        'Diagonal preconditioner: zero pivot at diagonal %d.', [I]);
    FInverse[I] := specialize TLinearScalar<T>.One / Diagonal[I];
  end;
end;

function TDiagonalPreconditioner.GetSize: SizeInt;
begin
  Result := Length(FInverse);
end;

function TDiagonalPreconditioner.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TDiagonalPreconditioner.GetKind: TPreconditionerKind;
begin
  Result := pkDiagonal;
end;

function TDiagonalPreconditioner.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TDiagonalPreconditioner.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  I: SizeInt;
begin
  specialize TLinearScalar<T>.ValidatePreconditionerVector(
    Input, Destination, Length(FInverse),
    'Diagonal preconditioner Apply');
  for I := 0 to High(FInverse) do
    Destination[I, 0] := FInverse[I] * Input[I, 0];
end;

function TILU0Preconditioner.FindPosition(const Row, Col: SizeInt): SizeInt;
var
  L, H, M: SizeInt;
begin
  L := FOuter[Row];
  H := FOuter[Row + 1] - 1;
  while L <= H do
  begin
    M := L + (H - L) div 2;
    if FInner[M] = Col then Exit(M);
    if FInner[M] < Col then L := M + 1
    else H := M - 1;
  end;
  Result := -1;
end;

constructor TILU0Preconditioner.Create(
  const Matrix: specialize ISparseMatrix<T>; const PivotTolerance: Double);
var
  I, J, K, P, Q, Position: SizeInt;
  Multiplier, Pivot: T;
begin
  inherited Create;
  if Matrix = nil then
    raise EPreconditionerError.Create('ILU(0): matrix must not be nil.');
  if (Matrix.Rows <> Matrix.Cols) or (Matrix.Format <> sfCSR) then
    raise EPreconditionerError.Create(
      'ILU(0): matrix must be square canonical CSR.');
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise EPreconditionerError.Create(
      'ILU(0): pivot tolerance must be finite and non-negative.');
  FSize := Matrix.Rows;
  FPivotTolerance := PivotTolerance;
  SetLength(FOuter, FSize + 1);
  SetLength(FInner, Matrix.NonZeroCount);
  SetLength(FValues, Matrix.NonZeroCount);
  SetLength(FDiagonal, FSize);
  for I := 0 to FSize do FOuter[I] := Matrix.GetOuterPointer(I);
  for P := 0 to Matrix.NonZeroCount - 1 do
  begin
    FInner[P] := Matrix.GetInnerIndex(P);
    FValues[P] := Matrix.GetStoredValue(P);
  end;
  for I := 0 to FSize - 1 do
  begin
    FDiagonal[I] := FindPosition(I, I);
    if FDiagonal[I] < 0 then
      raise EPreconditionerError.CreateFmt(
        'ILU(0): missing diagonal entry at row %d.', [I]);
  end;
  for I := 0 to FSize - 1 do
  begin
    P := FOuter[I];
    while (P < FOuter[I + 1]) and (FInner[P] < I) do
    begin
      J := FInner[P];
      Pivot := FValues[FDiagonal[J]];
      if specialize TLinearScalar<T>.Magnitude(Pivot) <= FPivotTolerance then
        raise EPreconditionerError.CreateFmt(
          'ILU(0): zero pivot at row %d.', [J]);
      FValues[P] := FValues[P] / Pivot;
      Multiplier := FValues[P];
      for Q := FDiagonal[J] + 1 to FOuter[J + 1] - 1 do
      begin
        K := FInner[Q];
        Position := FindPosition(I, K);
        if Position >= 0 then
          FValues[Position] := FValues[Position] -
            Multiplier * FValues[Q];
      end;
      Inc(P);
    end;
    if specialize TLinearScalar<T>.Magnitude(
         FValues[FDiagonal[I]]) <= FPivotTolerance then
      raise EPreconditionerError.CreateFmt(
        'ILU(0): zero pivot at row %d.', [I]);
  end;
end;

function TILU0Preconditioner.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TILU0Preconditioner.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TILU0Preconditioner.GetKind: TPreconditionerKind;
begin
  Result := pkILU0;
end;

function TILU0Preconditioner.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TILU0Preconditioner.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  I, P, J: SizeInt;
  Sum: T;
begin
  specialize TLinearScalar<T>.ValidatePreconditionerVector(
    Input, Destination, FSize, 'ILU(0) Apply');
  for I := 0 to FSize - 1 do
  begin
    Sum := Input[I, 0];
    for P := FOuter[I] to FDiagonal[I] - 1 do
    begin
      J := FInner[P];
      Sum := Sum - FValues[P] * Destination[J, 0];
    end;
    Destination[I, 0] := Sum;
  end;
  for I := FSize - 1 downto 0 do
  begin
    Sum := Destination[I, 0];
    for P := FDiagonal[I] + 1 to FOuter[I + 1] - 1 do
    begin
      J := FInner[P];
      Sum := Sum - FValues[P] * Destination[J, 0];
    end;
    Destination[I, 0] := Sum / FValues[FDiagonal[I]];
  end;
end;

function TIC0Preconditioner.FindPosition(const Row, Col: SizeInt): SizeInt;
var
  L, H, M: SizeInt;
begin
  L := FOuter[Row];
  H := FOuter[Row + 1] - 1;
  while L <= H do
  begin
    M := L + (H - L) div 2;
    if FInner[M] = Col then Exit(M);
    if FInner[M] < Col then L := M + 1
    else H := M - 1;
  end;
  Result := -1;
end;

constructor TIC0Preconditioner.Create(
  const Matrix: specialize ISparseMatrix<T>; const PivotTolerance: Double);
var
  I, J, K, P, PI, PJ, Count: SizeInt;
  Sum, Mirror: T;
  DiagonalReal, Scale: Double;
begin
  inherited Create;
  if Matrix = nil then
    raise EPreconditionerError.Create(
      'Incomplete Cholesky(0): matrix must not be nil.');
  if (Matrix.Rows <> Matrix.Cols) or (Matrix.Format <> sfCSR) then
    raise EPreconditionerError.Create(
      'Incomplete Cholesky(0): matrix must be square canonical CSR.');
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise EPreconditionerError.Create(
      'Incomplete Cholesky(0): pivot tolerance must be finite and non-negative.');
  FSize := Matrix.Rows;
  FPivotTolerance := PivotTolerance;
  SetLength(FOuter, FSize + 1);
  Count := 0;
  for I := 0 to FSize - 1 do
  begin
    FOuter[I] := Count;
    for P := Matrix.GetOuterPointer(I) to Matrix.GetOuterPointer(I + 1) - 1 do
      if Matrix.GetInnerIndex(P) <= I then Inc(Count);
  end;
  FOuter[FSize] := Count;
  SetLength(FInner, Count);
  SetLength(FValues, Count);
  SetLength(FDiagonal, FSize);
  Count := 0;
  for I := 0 to FSize - 1 do
    for P := Matrix.GetOuterPointer(I) to Matrix.GetOuterPointer(I + 1) - 1 do
      if Matrix.GetInnerIndex(P) <= I then
      begin
        J := Matrix.GetInnerIndex(P);
        Mirror := Matrix[J, I];
        if specialize TLinearScalar<T>.Magnitude(
             Matrix.GetStoredValue(P) -
             specialize TLinearScalar<T>.Conjugate(Mirror)) >
           PivotTolerance * (1.0 +
             specialize TLinearScalar<T>.Magnitude(Matrix.GetStoredValue(P))) then
          raise EPreconditionerError.CreateFmt(
            'Incomplete Cholesky(0): matrix is not Hermitian at (%d,%d).',
            [I, J]);
        FInner[Count] := J;
        FValues[Count] := Matrix.GetStoredValue(P);
        if J = I then FDiagonal[I] := Count;
        Inc(Count);
      end;
  for I := 0 to FSize - 1 do
    if (FOuter[I] = FOuter[I + 1]) or
       (FInner[FOuter[I + 1] - 1] <> I) then
      raise EPreconditionerError.CreateFmt(
        'Incomplete Cholesky(0): missing diagonal entry at row %d.', [I]);
  for I := 0 to FSize - 1 do
  begin
    for P := FOuter[I] to FDiagonal[I] - 1 do
    begin
      J := FInner[P];
      Sum := FValues[P];
      PI := FOuter[I];
      PJ := FOuter[J];
      while (PI < P) and (PJ < FDiagonal[J]) do
      begin
        if FInner[PI] = FInner[PJ] then
        begin
          Sum := Sum - FValues[PI] *
            specialize TLinearScalar<T>.Conjugate(FValues[PJ]);
          Inc(PI);
          Inc(PJ);
        end
        else if FInner[PI] < FInner[PJ] then Inc(PI)
        else Inc(PJ);
      end;
      if specialize TLinearScalar<T>.Magnitude(
           FValues[FDiagonal[J]]) <= FPivotTolerance then
        raise EPreconditionerError.CreateFmt(
          'Incomplete Cholesky(0): zero pivot at row %d.', [J]);
      FValues[P] := Sum / FValues[FDiagonal[J]];
    end;
    Sum := FValues[FDiagonal[I]];
    for K := FOuter[I] to FDiagonal[I] - 1 do
      Sum := Sum - FValues[K] *
        specialize TLinearScalar<T>.Conjugate(FValues[K]);
    DiagonalReal := specialize TLinearScalar<T>.RealPart(Sum);
    Scale := 1.0 + specialize TLinearScalar<T>.Magnitude(Sum);
    if (Abs(specialize TLinearScalar<T>.ImaginaryPart(Sum)) >
        FPivotTolerance * Scale) or
       (DiagonalReal <= FPivotTolerance) then
      raise EPreconditionerError.CreateFmt(
        'Incomplete Cholesky(0): non-positive pivot at row %d.', [I]);
    FValues[FDiagonal[I]] :=
      specialize TLinearScalar<T>.FromDouble(Sqrt(DiagonalReal));
  end;
end;

function TIC0Preconditioner.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TIC0Preconditioner.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TIC0Preconditioner.GetKind: TPreconditionerKind;
begin
  Result := pkIncompleteCholesky;
end;

function TIC0Preconditioner.GetIsReentrant: Boolean;
begin
  Result := True;
end;

procedure TIC0Preconditioner.Apply(const Input,
  Destination: specialize IDenseMatrix<T>);
var
  I, P, J, Position: SizeInt;
  Sum: T;
begin
  specialize TLinearScalar<T>.ValidatePreconditionerVector(
    Input, Destination, FSize,
    'Incomplete Cholesky(0) Apply');
  for I := 0 to FSize - 1 do
  begin
    Sum := Input[I, 0];
    for P := FOuter[I] to FDiagonal[I] - 1 do
    begin
      J := FInner[P];
      Sum := Sum - FValues[P] * Destination[J, 0];
    end;
    Destination[I, 0] := Sum / FValues[FDiagonal[I]];
  end;
  for I := FSize - 1 downto 0 do
  begin
    Sum := Destination[I, 0];
    for J := I + 1 to FSize - 1 do
    begin
      Position := FindPosition(J, I);
      if Position >= 0 then
        Sum := Sum -
          specialize TLinearScalar<T>.Conjugate(FValues[Position]) *
          Destination[J, 0];
    end;
    Destination[I, 0] := Sum /
      specialize TLinearScalar<T>.Conjugate(FValues[FDiagonal[I]]);
  end;
end;

class function TPreconditionerFactory.Identity(const Size: SizeInt):
  specialize IPreconditioner<T>;
begin
  Result := specialize TIdentityPreconditioner<T>.Create(Size);
end;

class function TPreconditionerFactory.Diagonal(const Values: array of T;
  const PivotTolerance: Double): specialize IPreconditioner<T>;
begin
  Result := specialize TDiagonalPreconditioner<T>.Create(
    Values, PivotTolerance);
end;

class function TPreconditionerFactory.SparseDiagonal(
  const Matrix: specialize ISparseMatrix<T>; const PivotTolerance: Double):
  specialize IPreconditioner<T>;
var
  Values: specialize TSparseValueArray<T>;
  I: SizeInt;
begin
  if Matrix = nil then
    raise EPreconditionerError.Create(
      'Sparse diagonal preconditioner: matrix must not be nil.');
  if Matrix.Rows <> Matrix.Cols then
    raise EPreconditionerError.Create(
      'Sparse diagonal preconditioner: matrix must be square.');
  SetLength(Values, Matrix.Rows);
  for I := 0 to Matrix.Rows - 1 do Values[I] := Matrix[I, I];
  Result := specialize TDiagonalPreconditioner<T>.Create(
    Values, PivotTolerance);
end;

class function TPreconditionerFactory.IncompleteCholesky0(
  const Matrix: specialize ISparseMatrix<T>; const PivotTolerance: Double):
  specialize IPreconditioner<T>;
begin
  Result := specialize TIC0Preconditioner<T>.Create(
    Matrix, PivotTolerance);
end;

class function TPreconditionerFactory.ILU0(
  const Matrix: specialize ISparseMatrix<T>; const PivotTolerance: Double):
  specialize IPreconditioner<T>;
begin
  Result := specialize TILU0Preconditioner<T>.Create(
    Matrix, PivotTolerance);
end;

end.
