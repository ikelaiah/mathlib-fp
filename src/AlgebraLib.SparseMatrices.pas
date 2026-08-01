unit AlgebraLib.SparseMatrices;

{-----------------------------------------------------------------------------
 AlgebraLib.SparseMatrices

 Canonical immutable CSR/CSC and compact structured storage for mathlib-fp
 1.9. All public indices are zero based and use SizeInt. Factories deep-copy
 caller arrays; triplet builders are the only mutable construction path.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, TypInfo,
  MathBase.Complex,
  AlgebraLib.DenseMatrices;

type
  ESparseMatrixError = class(Exception);

  TSparseFormat = (sfCSR, sfCSC);
  TSparseStoredZeroPolicy = (szDrop, szKeep);
  TSparseScalarKind = (sskSingle, sskDouble, sskSingleComplex, sskComplex);
  TStructuredMatrixKind = (smDiagonal, smTridiagonal, smBand);

  { Immutable compressed sparse matrix. OuterPointer, InnerIndex, and
    StoredValue expose read-only canonical storage without copying it. }
  generic ISparseMatrix<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetNonZeroCount: SizeInt;
    function GetFormat: TSparseFormat;
    function GetScalarKind: TSparseScalarKind;
    function GetStoredZeroPolicy: TSparseStoredZeroPolicy;
    function GetOuterPointer(const Position: SizeInt): SizeInt;
    function GetInnerIndex(const Position: SizeInt): SizeInt;
    function GetStoredValue(const Position: SizeInt): T;
    function GetValue(const Row, Col: SizeInt): T;
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    property NonZeroCount: SizeInt read GetNonZeroCount;
    property Format: TSparseFormat read GetFormat;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property StoredZeroPolicy: TSparseStoredZeroPolicy
      read GetStoredZeroPolicy;
    property Values[const Row, Col: SizeInt]: T read GetValue; default;
  end;

  ISparseSingleMatrix = specialize ISparseMatrix<Single>;
  ISparseDoubleMatrix = specialize ISparseMatrix<Double>;
  ISparseSingleComplexMatrix = specialize ISparseMatrix<TSingleComplex>;
  ISparseComplexMatrix = specialize ISparseMatrix<TComplex>;

  generic TSparseValueArray<T> = array of T;
  TSparseSizeIntArray = array of SizeInt;

  { Validated immutable implementation shared by the four public factories.
    Constructing it directly has the same validation and deep-copy contract. }
  generic TSparseMatrixStorage<T> = class(TInterfacedObject,
    specialize ISparseMatrix<T>)
  private
    FRows, FCols: SizeInt;
    FFormat: TSparseFormat;
    FScalarKind: TSparseScalarKind;
    FZeroPolicy: TSparseStoredZeroPolicy;
    FOuter, FInner: TSparseSizeIntArray;
    FValues: specialize TSparseValueArray<T>;
    class procedure ValidateCompressed(const Rows, Cols: SizeInt;
      const Format: TSparseFormat; const Outer, Inner: array of SizeInt;
      const Values: array of T; const Kind: TSparseScalarKind;
      const ZeroPolicy: TSparseStoredZeroPolicy); static;
  public
    class function CheckedCount(const A, B, ElementSize: SizeInt;
      const Operation: string): SizeUInt; static;
    class procedure RequireIndex(const Index, Limit: SizeInt;
      const Name, Operation: string); static;
    class function ScalarKindOf: TSparseScalarKind; static;
    class function ScalarIsFinite(const Value: T;
      const Kind: TSparseScalarKind): Boolean; static;
    class function ScalarIsZero(const Value: T): Boolean; static;
    class function ScalarConjugate(const Value: T;
      const Kind: TSparseScalarKind): T; static;
    class function ScalarAbsSquared(const Value: T;
      const Kind: TSparseScalarKind): Double; static;
    constructor Create(const Rows, Cols: SizeInt;
      const Format: TSparseFormat; const Kind: TSparseScalarKind;
      const Outer, Inner: array of SizeInt; const Values: array of T;
      const ZeroPolicy: TSparseStoredZeroPolicy);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetNonZeroCount: SizeInt;
    function GetFormat: TSparseFormat;
    function GetScalarKind: TSparseScalarKind;
    function GetStoredZeroPolicy: TSparseStoredZeroPolicy;
    function GetOuterPointer(const Position: SizeInt): SizeInt;
    function GetInnerIndex(const Position: SizeInt): SizeInt;
    function GetStoredValue(const Position: SizeInt): T;
    function GetValue(const Row, Col: SizeInt): T;
  end;

  generic TSparseTriplet<T> = record
    Row, Col, Sequence: SizeInt;
    Value: T;
  end;
  generic TSparseTripletArray<T> = array of specialize TSparseTriplet<T>;

  { Mutable append-only builder. Finalisation is deterministic O(k log k)
    and leaves the builder reusable. }
  generic TSparseTripletBuilder<T> = class
  private type
    TItem = specialize TSparseTriplet<T>;
    TItems = specialize TSparseTripletArray<T>;
  private
    FRows, FCols, FCount, FCapacity: SizeInt;
    FTriplets: TItems;
    procedure EnsureCapacity(const Required: SizeInt);
    function Less(const A, B: TItem;
      const Format: TSparseFormat): Boolean;
    procedure Sort(var Items: TItems;
      const Left, Right: SizeInt; const Format: TSparseFormat);
    function Build(const Format: TSparseFormat;
      const ZeroPolicy: TSparseStoredZeroPolicy):
      specialize ISparseMatrix<T>;
  public
    constructor Create(const Rows, Cols: SizeInt);
    procedure Add(const Row, Col: SizeInt; const Value: T);
    procedure Clear;
    function ToCSR(const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>;
    function ToCSC(const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>;
    property Count: SizeInt read FCount;
    property Rows: SizeInt read FRows;
    property Cols: SizeInt read FCols;
  end;

  TSparseSingleTripletBuilder =
    specialize TSparseTripletBuilder<Single>;
  TSparseDoubleTripletBuilder =
    specialize TSparseTripletBuilder<Double>;
  TSparseSingleComplexTripletBuilder =
    specialize TSparseTripletBuilder<TSingleComplex>;
  TSparseComplexTripletBuilder =
    specialize TSparseTripletBuilder<TComplex>;

  { Typed factory and arithmetic facade. These specialisations are the public
    entry points TSparseSingleMatrix, TSparseDoubleMatrix,
    TSparseSingleComplexMatrix, and TSparseComplexMatrix. }
  generic TSparseMatrixFactory<T> = class
  private
    type
      TMatrix = specialize ISparseMatrix<T>;
      TDenseMatrix = specialize IDenseMatrix<T>;
    class function CreateDense(const Rows, Cols: SizeInt): TDenseMatrix; static;
    class function TransposeCore(const A: TMatrix;
      const ConjugateValues: Boolean): TMatrix; static;
  public
    class function Zeros(const Rows, Cols: SizeInt;
      const Format: TSparseFormat = sfCSR):
      specialize ISparseMatrix<T>; static;
    class function FromCSR(const Rows, Cols: SizeInt;
      const RowPointers, ColumnIndices: array of SizeInt;
      const Values: array of T;
      const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>; static;
    class function FromCSC(const Rows, Cols: SizeInt;
      const ColumnPointers, RowIndices: array of SizeInt;
      const Values: array of T;
      const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>; static;
    class function FromTriplets(const Rows, Cols: SizeInt;
      const TripletRows, TripletCols: array of SizeInt;
      const TripletValues: array of T;
      const Format: TSparseFormat = sfCSR;
      const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>; static;
    class function FromDense(const Matrix: specialize IDenseMatrix<T>;
      const Format: TSparseFormat = sfCSR;
      const ZeroPolicy: TSparseStoredZeroPolicy = szDrop):
      specialize ISparseMatrix<T>; static;
    class function ToDense(const Matrix: specialize ISparseMatrix<T>):
      specialize IDenseMatrix<T>; static;
    class function Convert(const Matrix: specialize ISparseMatrix<T>;
      const Format: TSparseFormat): specialize ISparseMatrix<T>; static;
    class function Add(const A, B: specialize ISparseMatrix<T>):
      specialize ISparseMatrix<T>; static;
    class function Scale(const A: specialize ISparseMatrix<T>;
      const Scalar: T): specialize ISparseMatrix<T>; static;
    class function Transpose(const A: specialize ISparseMatrix<T>):
      specialize ISparseMatrix<T>; static;
    class function ConjugateTranspose(const A: specialize ISparseMatrix<T>):
      specialize ISparseMatrix<T>; static;
    class function Multiply(const A, B: specialize ISparseMatrix<T>):
      specialize ISparseMatrix<T>; static;
    class procedure MultiplyDenseInto(const A: specialize ISparseMatrix<T>;
      const X, Destination: specialize IDenseMatrix<T>); static;
    class function Row(const A: specialize ISparseMatrix<T>;
      const RowIndex: SizeInt): specialize IDenseMatrix<T>; static;
    class function Column(const A: specialize ISparseMatrix<T>;
      const ColumnIndex: SizeInt): specialize IDenseMatrix<T>; static;
    class function Norm2(const A: specialize ISparseMatrix<T>): Double; static;
  end;

  TSparseSingleMatrix = specialize TSparseMatrixFactory<Single>;
  TSparseDoubleMatrix = specialize TSparseMatrixFactory<Double>;
  TSparseSingleComplexMatrix =
    specialize TSparseMatrixFactory<TSingleComplex>;
  TSparseComplexMatrix = specialize TSparseMatrixFactory<TComplex>;

  { Immutable compact diagonal/tridiagonal/band storage. }
  generic IStructuredMatrix<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetKind: TStructuredMatrixKind;
    function GetScalarKind: TSparseScalarKind;
    function GetLowerBandwidth: SizeInt;
    function GetUpperBandwidth: SizeInt;
    function GetValue(const Row, Col: SizeInt): T;
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    property Kind: TStructuredMatrixKind read GetKind;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property LowerBandwidth: SizeInt read GetLowerBandwidth;
    property UpperBandwidth: SizeInt read GetUpperBandwidth;
    property Values[const Row, Col: SizeInt]: T read GetValue; default;
  end;

  IStructuredSingleMatrix = specialize IStructuredMatrix<Single>;
  IStructuredDoubleMatrix = specialize IStructuredMatrix<Double>;
  IStructuredSingleComplexMatrix =
    specialize IStructuredMatrix<TSingleComplex>;
  IStructuredComplexMatrix = specialize IStructuredMatrix<TComplex>;

  generic TStructuredMatrixStorage<T> = class(TInterfacedObject,
    specialize IStructuredMatrix<T>)
  private
    FRows, FCols, FLower, FUpper: SizeInt;
    FKind: TStructuredMatrixKind;
    FScalarKind: TSparseScalarKind;
    FValues: specialize TSparseValueArray<T>;
  public
    constructor Create(const Rows, Cols, LowerBandwidth,
      UpperBandwidth: SizeInt; const Kind: TStructuredMatrixKind;
      const ScalarKind: TSparseScalarKind; const Values: array of T);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetKind: TStructuredMatrixKind;
    function GetScalarKind: TSparseScalarKind;
    function GetLowerBandwidth: SizeInt;
    function GetUpperBandwidth: SizeInt;
    function GetValue(const Row, Col: SizeInt): T;
  end;

  generic TStructuredMatrixFactory<T> = class
  private
    type
      TDenseMatrix = specialize IDenseMatrix<T>;
    class function CreateDense(const Rows, Cols: SizeInt): TDenseMatrix; static;
  public
    class function Diagonal(const Rows, Cols: SizeInt;
      const DiagonalValues: array of T):
      specialize IStructuredMatrix<T>; static;
    class function Tridiagonal(const Lower, DiagonalValues,
      Upper: array of T): specialize IStructuredMatrix<T>; static;
    class function Band(const Rows, Cols, LowerBandwidth,
      UpperBandwidth: SizeInt; const CompactValues: array of T):
      specialize IStructuredMatrix<T>; static;
    class function ToSparse(const Matrix: specialize IStructuredMatrix<T>;
      const Format: TSparseFormat = sfCSR):
      specialize ISparseMatrix<T>; static;
    class function ToDense(const Matrix: specialize IStructuredMatrix<T>):
      specialize IDenseMatrix<T>; static;
    class procedure MultiplyDenseInto(
      const A: specialize IStructuredMatrix<T>;
      const X, Destination: specialize IDenseMatrix<T>); static;
  end;

  TStructuredSingleMatrix = specialize TStructuredMatrixFactory<Single>;
  TStructuredDoubleMatrix = specialize TStructuredMatrixFactory<Double>;
  TStructuredSingleComplexMatrix =
    specialize TStructuredMatrixFactory<TSingleComplex>;
  TStructuredComplexMatrix =
    specialize TStructuredMatrixFactory<TComplex>;

implementation

class function TSparseMatrixStorage.CheckedCount(
  const A, B, ElementSize: SizeInt;
  const Operation: string): SizeUInt;
var
  UA, UB: SizeUInt;
begin
  if (A < 0) or (B < 0) then
    raise ESparseMatrixError.CreateFmt(
      '%s: dimensions must be non-negative; got %d and %d.',
      [Operation, A, B]);
  UA := SizeUInt(A);
  UB := SizeUInt(B);
  if (UB <> 0) and (UA > High(SizeUInt) div UB) then
    raise ESparseMatrixError.Create(Operation +
      ': native-size element count overflows.');
  Result := UA * UB;
  if (Result <> 0) and
     (SizeUInt(ElementSize) > High(SizeUInt) div Result) then
    raise ESparseMatrixError.Create(Operation +
      ': native-size byte count overflows.');
  if Result * SizeUInt(ElementSize) > SizeUInt(High(SizeInt)) then
    raise ESparseMatrixError.Create(Operation +
      ': allocation exceeds the supported address-space limit.');
end;

class function TSparseMatrixStorage.ScalarKindOf: TSparseScalarKind;
var
  Name: string;
begin
  Name := PTypeInfo(TypeInfo(T))^.Name;
  if SameText(Name, 'Single') then
    Exit(sskSingle);
  if SameText(Name, 'Double') then
    Exit(sskDouble);
  if SameText(Name, 'TSingleComplex') then
    Exit(sskSingleComplex);
  if SameText(Name, 'TComplex') then
    Exit(sskComplex);
  raise ESparseMatrixError.CreateFmt(
    'Sparse scalar type %s is unsupported.', [Name]);
end;

class function TSparseMatrixStorage.ScalarIsFinite(const Value: T;
  const Kind: TSparseScalarKind): Boolean;
var
  S: Single;
  D: Double;
  CS: TSingleComplex;
  CD: TComplex;
begin
  case Kind of
    sskSingle:
      begin
        Move(Value, S, SizeOf(S));
        Result := not IsNan(S) and not IsInfinite(S);
      end;
    sskDouble:
      begin
        Move(Value, D, SizeOf(D));
        Result := not IsNan(D) and not IsInfinite(D);
      end;
    sskSingleComplex:
      begin
        Move(Value, CS, SizeOf(CS));
        Result := CS.IsFinite;
      end;
  else
    begin
      Move(Value, CD, SizeOf(CD));
      Result := CD.IsFinite;
    end;
  end;
end;

class function TSparseMatrixStorage.ScalarIsZero(const Value: T): Boolean;
var
  Zero: T;
begin
  Zero := Default(T);
  Result := Value = Zero;
end;

class function TSparseMatrixStorage.ScalarConjugate(const Value: T;
  const Kind: TSparseScalarKind): T;
var
  CS: TSingleComplex;
  CD: TComplex;
begin
  Result := Value;
  case Kind of
    sskSingleComplex:
      begin
        Move(Value, CS, SizeOf(CS));
        CS := CS.Conjugate;
        Move(CS, Result, SizeOf(CS));
      end;
    sskComplex:
      begin
        Move(Value, CD, SizeOf(CD));
        CD := CD.Conjugate;
        Move(CD, Result, SizeOf(CD));
      end;
  end;
end;

class function TSparseMatrixStorage.ScalarAbsSquared(const Value: T;
  const Kind: TSparseScalarKind): Double;
var
  S: Single;
  D: Double;
  CS: TSingleComplex;
  CD: TComplex;
begin
  case Kind of
    sskSingle:
      begin
        Move(Value, S, SizeOf(S));
        Result := Double(S) * S;
      end;
    sskDouble:
      begin
        Move(Value, D, SizeOf(D));
        Result := D * D;
      end;
    sskSingleComplex:
      begin
        Move(Value, CS, SizeOf(CS));
        Result := CS.SqrMagnitude;
      end;
  else
    begin
      Move(Value, CD, SizeOf(CD));
      Result := CD.SqrMagnitude;
    end;
  end;
end;

class procedure TSparseMatrixStorage.RequireIndex(
  const Index, Limit: SizeInt; const Name,
  Operation: string);
begin
  if (Index < 0) or (Index >= Limit) then
    raise ESparseMatrixError.CreateFmt(
      '%s: %s %d is outside zero-based range [0,%d).',
      [Operation, Name, Index, Limit]);
end;

class procedure TSparseMatrixStorage.ValidateCompressed(
  const Rows, Cols: SizeInt;
  const Format: TSparseFormat; const Outer, Inner: array of SizeInt;
  const Values: array of T; const Kind: TSparseScalarKind;
  const ZeroPolicy: TSparseStoredZeroPolicy);
var
  ExpectedOuter, I, K, Limit: SizeInt;
begin
  CheckedCount(Rows, Cols, SizeOf(T), 'Sparse matrix shape');
  if Format = sfCSR then
  begin
    if Rows = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse compressed storage: row pointer length exceeds SizeInt.');
    ExpectedOuter := Rows + 1;
    Limit := Cols;
  end
  else
  begin
    if Cols = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse compressed storage: column pointer length exceeds SizeInt.');
    ExpectedOuter := Cols + 1;
    Limit := Rows;
  end;
  if Length(Outer) <> ExpectedOuter then
    raise ESparseMatrixError.CreateFmt(
      'Sparse compressed storage: expected %d outer offsets; got %d.',
      [ExpectedOuter, Length(Outer)]);
  if Length(Inner) <> Length(Values) then
    raise ESparseMatrixError.CreateFmt(
      'Sparse compressed storage: %d inner indices do not match %d values.',
      [Length(Inner), Length(Values)]);
  if (Length(Outer) = 0) or (Outer[0] <> 0) or
     (Outer[High(Outer)] <> Length(Values)) then
    raise ESparseMatrixError.Create(
      'Sparse compressed storage: outer offsets must start at zero and end at nnz.');
  for I := 0 to High(Outer) - 1 do
  begin
    if (Outer[I] < 0) or (Outer[I] > Outer[I + 1]) then
      raise ESparseMatrixError.CreateFmt(
        'Sparse compressed storage: outer offsets decrease at %d.', [I]);
    for K := Outer[I] to Outer[I + 1] - 1 do
    begin
      RequireIndex(Inner[K], Limit, 'inner index',
        'Sparse compressed storage');
      if (K > Outer[I]) and (Inner[K] <= Inner[K - 1]) then
        raise ESparseMatrixError.CreateFmt(
          'Sparse compressed storage: inner indices are not strictly sorted in outer position %d.',
          [I]);
      if not ScalarIsFinite(Values[K], Kind) then
        raise ESparseMatrixError.CreateFmt(
          'Sparse compressed storage: value %d is non-finite.', [K]);
      if (ZeroPolicy = szDrop) and
         ScalarIsZero(Values[K]) then
        raise ESparseMatrixError.CreateFmt(
          'Sparse compressed storage: stored exact zero at %d violates szDrop.',
          [K]);
    end;
  end;
end;

constructor TSparseMatrixStorage.Create(const Rows, Cols: SizeInt;
  const Format: TSparseFormat; const Kind: TSparseScalarKind;
  const Outer, Inner: array of SizeInt; const Values: array of T;
  const ZeroPolicy: TSparseStoredZeroPolicy);
var
  I: SizeInt;
begin
  inherited Create;
  ValidateCompressed(Rows, Cols, Format, Outer, Inner,
    Values, Kind, ZeroPolicy);
  FRows := Rows;
  FCols := Cols;
  FFormat := Format;
  FScalarKind := Kind;
  FZeroPolicy := ZeroPolicy;
  SetLength(FOuter, Length(Outer));
  for I := 0 to High(Outer) do FOuter[I] := Outer[I];
  SetLength(FInner, Length(Inner));
  SetLength(FValues, Length(Values));
  for I := 0 to High(Inner) do
  begin
    FInner[I] := Inner[I];
    FValues[I] := Values[I];
  end;
end;

function TSparseMatrixStorage.GetRows: SizeInt;
begin
  Result := FRows;
end;

function TSparseMatrixStorage.GetCols: SizeInt;
begin
  Result := FCols;
end;

function TSparseMatrixStorage.GetNonZeroCount: SizeInt;
begin
  Result := Length(FValues);
end;

function TSparseMatrixStorage.GetFormat: TSparseFormat;
begin
  Result := FFormat;
end;

function TSparseMatrixStorage.GetScalarKind: TSparseScalarKind;
begin
  Result := FScalarKind;
end;

function TSparseMatrixStorage.GetStoredZeroPolicy: TSparseStoredZeroPolicy;
begin
  Result := FZeroPolicy;
end;

function TSparseMatrixStorage.GetOuterPointer(const Position: SizeInt): SizeInt;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Position, Length(FOuter), 'outer position',
    'Sparse OuterPointer');
  Result := FOuter[Position];
end;

function TSparseMatrixStorage.GetInnerIndex(const Position: SizeInt): SizeInt;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Position, Length(FInner), 'stored position',
    'Sparse InnerIndex');
  Result := FInner[Position];
end;

function TSparseMatrixStorage.GetStoredValue(const Position: SizeInt): T;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Position, Length(FValues), 'stored position',
    'Sparse StoredValue');
  Result := FValues[Position];
end;

function TSparseMatrixStorage.GetValue(const Row, Col: SizeInt): T;
var
  First, LastValue, Mid, Target: SizeInt;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Row, FRows, 'row', 'Sparse element access');
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Col, FCols, 'column', 'Sparse element access');
  if FFormat = sfCSR then
  begin
    First := FOuter[Row];
    LastValue := FOuter[Row + 1] - 1;
    Target := Col;
  end
  else
  begin
    First := FOuter[Col];
    LastValue := FOuter[Col + 1] - 1;
    Target := Row;
  end;
  while First <= LastValue do
  begin
    Mid := First + (LastValue - First) div 2;
    if FInner[Mid] = Target then Exit(FValues[Mid]);
    if FInner[Mid] < Target then First := Mid + 1
    else LastValue := Mid - 1;
  end;
  Result := Default(T);
end;

procedure TSparseTripletBuilder.EnsureCapacity(const Required: SizeInt);
var
  NewCapacity: SizeInt;
begin
  if Required <= FCapacity then Exit;
  NewCapacity := FCapacity;
  if NewCapacity < 16 then NewCapacity := 16;
  while NewCapacity < Required do
  begin
    if NewCapacity > High(SizeInt) div 2 then
      raise ESparseMatrixError.Create(
        'Sparse triplet builder: capacity exceeds SizeInt.');
    NewCapacity := NewCapacity * 2;
  end;
  SetLength(FTriplets, NewCapacity);
  FCapacity := NewCapacity;
end;

constructor TSparseTripletBuilder.Create(const Rows, Cols: SizeInt);
begin
  inherited Create;
  specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Cols, SizeOf(T), 'Sparse triplet builder shape');
  FRows := Rows;
  FCols := Cols;
end;

procedure TSparseTripletBuilder.Add(const Row, Col: SizeInt; const Value: T);
var
  Kind: TSparseScalarKind;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Row, FRows, 'row', 'Sparse triplet Add');
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Col, FCols, 'column', 'Sparse triplet Add');
  Kind := specialize TSparseMatrixStorage<T>.ScalarKindOf;
  if not specialize TSparseMatrixStorage<T>.ScalarIsFinite(Value, Kind) then
    raise ESparseMatrixError.Create(
      'Sparse triplet Add: value must be finite.');
  if FCount = High(SizeInt) then
    raise ESparseMatrixError.Create(
      'Sparse triplet Add: contribution count exceeds SizeInt.');
  EnsureCapacity(FCount + 1);
  FTriplets[FCount].Row := Row;
  FTriplets[FCount].Col := Col;
  FTriplets[FCount].Sequence := FCount;
  FTriplets[FCount].Value := Value;
  Inc(FCount);
end;

procedure TSparseTripletBuilder.Clear;
begin
  FCount := 0;
end;

function TSparseTripletBuilder.Less(
  const A, B: TItem;
  const Format: TSparseFormat): Boolean;
begin
  if Format = sfCSR then
  begin
    if A.Row <> B.Row then Exit(A.Row < B.Row);
    if A.Col <> B.Col then Exit(A.Col < B.Col);
  end
  else
  begin
    if A.Col <> B.Col then Exit(A.Col < B.Col);
    if A.Row <> B.Row then Exit(A.Row < B.Row);
  end;
  Result := A.Sequence < B.Sequence;
end;

procedure TSparseTripletBuilder.Sort(
  var Items: TItems;
  const Left, Right: SizeInt; const Format: TSparseFormat);
var
  I, J: SizeInt;
  Pivot, Temp: TItem;
begin
  I := Left;
  J := Right;
  Pivot := Items[Left + (Right - Left) div 2];
  repeat
    while Less(Items[I], Pivot, Format) do Inc(I);
    while Less(Pivot, Items[J], Format) do Dec(J);
    if I <= J then
    begin
      Temp := Items[I];
      Items[I] := Items[J];
      Items[J] := Temp;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if Left < J then Sort(Items, Left, J, Format);
  if I < Right then Sort(Items, I, Right, Format);
end;

function TSparseTripletBuilder.Build(const Format: TSparseFormat;
  const ZeroPolicy: TSparseStoredZeroPolicy): specialize ISparseMatrix<T>;
var
  Work: TItems;
  Outer, Inner: TSparseSizeIntArray;
  Values: specialize TSparseValueArray<T>;
  I, OutputCount, OuterPosition, CurrentOuter, InnerPosition: SizeInt;
  Sum: T;
  Kind: TSparseScalarKind;
begin
  Kind := specialize TSparseMatrixStorage<T>.ScalarKindOf;
  Work := nil;
  Outer := nil;
  Inner := nil;
  Values := nil;
  if Format = sfCSR then
  begin
    if FRows = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse triplet builder: CSR pointer length exceeds SizeInt.');
    SetLength(Outer, FRows + 1);
  end
  else
  begin
    if FCols = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse triplet builder: CSC pointer length exceeds SizeInt.');
    SetLength(Outer, FCols + 1);
  end;
  if FCount = 0 then
    Exit(specialize TSparseMatrixStorage<T>.Create(FRows, FCols, Format,
      Kind, Outer, Inner, Values, ZeroPolicy));
  SetLength(Work, FCount);
  for I := 0 to FCount - 1 do Work[I] := FTriplets[I];
  Sort(Work, 0, FCount - 1, Format);
  SetLength(Inner, FCount);
  SetLength(Values, FCount);
  OutputCount := 0;
  I := 0;
  CurrentOuter := 0;
  while I < FCount do
  begin
    if Format = sfCSR then
    begin
      OuterPosition := Work[I].Row;
      InnerPosition := Work[I].Col;
    end
    else
    begin
      OuterPosition := Work[I].Col;
      InnerPosition := Work[I].Row;
    end;
    while CurrentOuter <= OuterPosition do
    begin
      Outer[CurrentOuter] := OutputCount;
      Inc(CurrentOuter);
    end;
    Sum := Work[I].Value;
    Inc(I);
    while (I < FCount) and
      (Work[I].Row = Work[I - 1].Row) and
      (Work[I].Col = Work[I - 1].Col) do
    begin
      Sum := Sum + Work[I].Value;
      Inc(I);
    end;
    if (ZeroPolicy = szKeep) or
       not specialize TSparseMatrixStorage<T>.ScalarIsZero(Sum) then
    begin
      Inner[OutputCount] := InnerPosition;
      Values[OutputCount] := Sum;
      Inc(OutputCount);
    end;
  end;
  while CurrentOuter < Length(Outer) do
  begin
    Outer[CurrentOuter] := OutputCount;
    Inc(CurrentOuter);
  end;
  SetLength(Inner, OutputCount);
  SetLength(Values, OutputCount);
  Result := specialize TSparseMatrixStorage<T>.Create(FRows, FCols, Format,
    Kind, Outer, Inner, Values, ZeroPolicy);
end;

function TSparseTripletBuilder.ToCSR(
  const ZeroPolicy: TSparseStoredZeroPolicy): specialize ISparseMatrix<T>;
begin
  Result := Build(sfCSR, ZeroPolicy);
end;

function TSparseTripletBuilder.ToCSC(
  const ZeroPolicy: TSparseStoredZeroPolicy): specialize ISparseMatrix<T>;
begin
  Result := Build(sfCSC, ZeroPolicy);
end;

class function TSparseMatrixFactory.CreateDense(const Rows, Cols: SizeInt):
  TDenseMatrix;
begin
  case specialize TSparseMatrixStorage<T>.ScalarKindOf of
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

class function TSparseMatrixFactory.Zeros(const Rows, Cols: SizeInt;
  const Format: TSparseFormat): specialize ISparseMatrix<T>;
var
  Outer, Inner: TSparseSizeIntArray;
  Values: specialize TSparseValueArray<T>;
begin
  Outer := nil;
  Inner := nil;
  Values := nil;
  specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Cols, SizeOf(T), 'Sparse Zeros');
  if Format = sfCSR then
  begin
    if Rows = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse Zeros: CSR pointer length exceeds SizeInt.');
    SetLength(Outer, Rows + 1);
  end
  else
  begin
    if Cols = High(SizeInt) then
      raise ESparseMatrixError.Create(
        'Sparse Zeros: CSC pointer length exceeds SizeInt.');
    SetLength(Outer, Cols + 1);
  end;
  Result := specialize TSparseMatrixStorage<T>.Create(Rows, Cols, Format,
    specialize TSparseMatrixStorage<T>.ScalarKindOf,
    Outer, Inner, Values, szDrop);
end;

class function TSparseMatrixFactory.FromCSR(const Rows, Cols: SizeInt;
  const RowPointers, ColumnIndices: array of SizeInt;
  const Values: array of T; const ZeroPolicy: TSparseStoredZeroPolicy):
  specialize ISparseMatrix<T>;
begin
  Result := specialize TSparseMatrixStorage<T>.Create(Rows, Cols, sfCSR,
    specialize TSparseMatrixStorage<T>.ScalarKindOf,
    RowPointers, ColumnIndices, Values,
    ZeroPolicy);
end;

class function TSparseMatrixFactory.FromCSC(const Rows, Cols: SizeInt;
  const ColumnPointers, RowIndices: array of SizeInt;
  const Values: array of T; const ZeroPolicy: TSparseStoredZeroPolicy):
  specialize ISparseMatrix<T>;
begin
  Result := specialize TSparseMatrixStorage<T>.Create(Rows, Cols, sfCSC,
    specialize TSparseMatrixStorage<T>.ScalarKindOf,
    ColumnPointers, RowIndices, Values,
    ZeroPolicy);
end;

class function TSparseMatrixFactory.FromTriplets(const Rows, Cols: SizeInt;
  const TripletRows, TripletCols: array of SizeInt;
  const TripletValues: array of T; const Format: TSparseFormat;
  const ZeroPolicy: TSparseStoredZeroPolicy): specialize ISparseMatrix<T>;
var
  Builder: specialize TSparseTripletBuilder<T>;
  I: SizeInt;
begin
  if (Length(TripletRows) <> Length(TripletCols)) or
     (Length(TripletRows) <> Length(TripletValues)) then
    raise ESparseMatrixError.Create(
      'Sparse FromTriplets: row, column, and value counts must match.');
  Builder := specialize TSparseTripletBuilder<T>.Create(Rows, Cols);
  try
    for I := 0 to High(TripletValues) do
      Builder.Add(TripletRows[I], TripletCols[I], TripletValues[I]);
    if Format = sfCSR then Result := Builder.ToCSR(ZeroPolicy)
    else Result := Builder.ToCSC(ZeroPolicy);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.FromDense(
  const Matrix: specialize IDenseMatrix<T>; const Format: TSparseFormat;
  const ZeroPolicy: TSparseStoredZeroPolicy): specialize ISparseMatrix<T>;
var
  Builder: specialize TSparseTripletBuilder<T>;
  R, C: SizeInt;
  Value: T;
begin
  if Matrix = nil then
    raise ESparseMatrixError.Create(
      'Sparse FromDense: matrix handle must not be nil.');
  Builder := specialize TSparseTripletBuilder<T>.Create(
    Matrix.Rows, Matrix.Cols);
  try
    for R := 0 to Matrix.Rows - 1 do
      for C := 0 to Matrix.Cols - 1 do
      begin
        Value := Matrix[R, C];
        if (ZeroPolicy = szKeep) or
           not specialize TSparseMatrixStorage<T>.ScalarIsZero(Value) then
          Builder.Add(R, C, Value);
      end;
    if Format = sfCSR then Result := Builder.ToCSR(ZeroPolicy)
    else Result := Builder.ToCSC(ZeroPolicy);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.ToDense(
  const Matrix: specialize ISparseMatrix<T>): specialize IDenseMatrix<T>;
var
  K, R, C: SizeInt;
begin
  if Matrix = nil then
    raise ESparseMatrixError.Create(
      'Sparse ToDense: matrix handle must not be nil.');
  Result := CreateDense(Matrix.Rows, Matrix.Cols);
  if Matrix.Format = sfCSR then
    for R := 0 to Matrix.Rows - 1 do
      for K := Matrix.GetOuterPointer(R) to
        Matrix.GetOuterPointer(R + 1) - 1 do
        Result[R, Matrix.GetInnerIndex(K)] := Matrix.GetStoredValue(K)
  else
    for C := 0 to Matrix.Cols - 1 do
      for K := Matrix.GetOuterPointer(C) to
        Matrix.GetOuterPointer(C + 1) - 1 do
        Result[Matrix.GetInnerIndex(K), C] := Matrix.GetStoredValue(K);
end;

class function TSparseMatrixFactory.Convert(
  const Matrix: specialize ISparseMatrix<T>; const Format: TSparseFormat):
  specialize ISparseMatrix<T>;
var
  Builder: specialize TSparseTripletBuilder<T>;
  OuterIndex, K: SizeInt;
begin
  if Matrix = nil then
    raise ESparseMatrixError.Create(
      'Sparse Convert: matrix handle must not be nil.');
  { Always rebuild to preserve the immutable deep-copy conversion contract. }
  Builder := specialize TSparseTripletBuilder<T>.Create(
    Matrix.Rows, Matrix.Cols);
  try
    if Matrix.Format = sfCSR then
      for OuterIndex := 0 to Matrix.Rows - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
          Builder.Add(OuterIndex, Matrix.GetInnerIndex(K),
            Matrix.GetStoredValue(K))
    else
      for OuterIndex := 0 to Matrix.Cols - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
          Builder.Add(Matrix.GetInnerIndex(K), OuterIndex,
            Matrix.GetStoredValue(K));
    if Format = sfCSR then
      Result := Builder.ToCSR(Matrix.StoredZeroPolicy)
    else
      Result := Builder.ToCSC(Matrix.StoredZeroPolicy);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.Add(
  const A, B: specialize ISparseMatrix<T>): specialize ISparseMatrix<T>;
var
  AC, BC: TMatrix;
  Builder: specialize TSparseTripletBuilder<T>;
  R, IA, IB, EA, EB, CA, CB: SizeInt;
  Value: T;
begin
  if (A = nil) or (B = nil) then
    raise ESparseMatrixError.Create(
      'Sparse Add: matrix handles must not be nil.');
  if (A.Rows <> B.Rows) or (A.Cols <> B.Cols) then
    raise ESparseMatrixError.CreateFmt(
      'Sparse Add: shape mismatch %d x %d versus %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  AC := Convert(A, sfCSR);
  BC := Convert(B, sfCSR);
  Builder := specialize TSparseTripletBuilder<T>.Create(A.Rows, A.Cols);
  try
    for R := 0 to A.Rows - 1 do
    begin
      IA := AC.GetOuterPointer(R);
      EA := AC.GetOuterPointer(R + 1);
      IB := BC.GetOuterPointer(R);
      EB := BC.GetOuterPointer(R + 1);
      while (IA < EA) or (IB < EB) do
      begin
        if (IB >= EB) or
           ((IA < EA) and
            (AC.GetInnerIndex(IA) < BC.GetInnerIndex(IB))) then
        begin
          Builder.Add(R, AC.GetInnerIndex(IA), AC.GetStoredValue(IA));
          Inc(IA);
        end
        else if (IA >= EA) or
          (BC.GetInnerIndex(IB) < AC.GetInnerIndex(IA)) then
        begin
          Builder.Add(R, BC.GetInnerIndex(IB), BC.GetStoredValue(IB));
          Inc(IB);
        end
        else
        begin
          CA := AC.GetInnerIndex(IA);
          CB := BC.GetInnerIndex(IB);
          Value := AC.GetStoredValue(IA) + BC.GetStoredValue(IB);
          if CA <> CB then
            raise ESparseMatrixError.Create(
              'Sparse Add: internal merge invariant failed.');
          Builder.Add(R, CA, Value);
          Inc(IA);
          Inc(IB);
        end;
      end;
    end;
    Result := Builder.ToCSR(szDrop);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.Scale(
  const A: specialize ISparseMatrix<T>; const Scalar: T):
  specialize ISparseMatrix<T>;
var
  Builder: specialize TSparseTripletBuilder<T>;
  OuterIndex, K: SizeInt;
begin
  if A = nil then
    raise ESparseMatrixError.Create(
      'Sparse Scale: matrix handle must not be nil.');
  if not specialize TSparseMatrixStorage<T>.ScalarIsFinite(
    Scalar, specialize TSparseMatrixStorage<T>.ScalarKindOf) then
    raise ESparseMatrixError.Create('Sparse Scale: scalar must be finite.');
  Builder := specialize TSparseTripletBuilder<T>.Create(A.Rows, A.Cols);
  try
    if A.Format = sfCSR then
      for OuterIndex := 0 to A.Rows - 1 do
        for K := A.GetOuterPointer(OuterIndex) to
          A.GetOuterPointer(OuterIndex + 1) - 1 do
          Builder.Add(OuterIndex, A.GetInnerIndex(K),
            A.GetStoredValue(K) * Scalar)
    else
      for OuterIndex := 0 to A.Cols - 1 do
        for K := A.GetOuterPointer(OuterIndex) to
          A.GetOuterPointer(OuterIndex + 1) - 1 do
          Builder.Add(A.GetInnerIndex(K), OuterIndex,
            A.GetStoredValue(K) * Scalar);
    if A.Format = sfCSR then Result := Builder.ToCSR(szDrop)
    else Result := Builder.ToCSC(szDrop);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.TransposeCore(const A: TMatrix;
  const ConjugateValues: Boolean): TMatrix;
var
  Outer, Inner: TSparseSizeIntArray;
  Values: specialize TSparseValueArray<T>;
  I: SizeInt;
  NewFormat: TSparseFormat;
begin
  if A = nil then
    raise ESparseMatrixError.Create(
      'Sparse transpose: matrix handle must not be nil.');
  if A.Format = sfCSR then
  begin
    NewFormat := sfCSC;
    SetLength(Outer, A.Rows + 1);
  end
  else
  begin
    NewFormat := sfCSR;
    SetLength(Outer, A.Cols + 1);
  end;
  SetLength(Inner, A.NonZeroCount);
  SetLength(Values, A.NonZeroCount);
  for I := 0 to High(Outer) do Outer[I] := A.GetOuterPointer(I);
  for I := 0 to A.NonZeroCount - 1 do
  begin
    Inner[I] := A.GetInnerIndex(I);
    if ConjugateValues then
      Values[I] := specialize TSparseMatrixStorage<T>.ScalarConjugate(
        A.GetStoredValue(I), A.ScalarKind)
    else
      Values[I] := A.GetStoredValue(I);
  end;
  Result := specialize TSparseMatrixStorage<T>.Create(
    A.Cols, A.Rows, NewFormat, A.ScalarKind, Outer, Inner, Values,
    A.StoredZeroPolicy);
end;

class function TSparseMatrixFactory.Transpose(
  const A: specialize ISparseMatrix<T>): specialize ISparseMatrix<T>;
begin
  Result := TransposeCore(A, False);
end;

class function TSparseMatrixFactory.ConjugateTranspose(
  const A: specialize ISparseMatrix<T>): specialize ISparseMatrix<T>;
begin
  Result := TransposeCore(A, True);
end;

class procedure TSparseMatrixFactory.MultiplyDenseInto(
  const A: specialize ISparseMatrix<T>;
  const X, Destination: specialize IDenseMatrix<T>);
var
  AC: TMatrix;
  Temp: TDenseMatrix;
  R, J, K, C: SizeInt;
  Sum: T;
begin
  if (A = nil) or (X = nil) or (Destination = nil) then
    raise ESparseMatrixError.Create(
      'Sparse MultiplyDenseInto: handles must not be nil.');
  if A.Cols <> X.Rows then
    raise ESparseMatrixError.CreateFmt(
      'Sparse MultiplyDenseInto: inner dimensions %d and %d do not match.',
      [A.Cols, X.Rows]);
  if (Destination.Rows <> A.Rows) or (Destination.Cols <> X.Cols) then
    raise ESparseMatrixError.CreateFmt(
      'Sparse MultiplyDenseInto: destination must have shape %d x %d.',
      [A.Rows, X.Cols]);
  if (Destination.StorageIdentity = X.StorageIdentity) and
     (Destination.StorageIdentity <> nil) then
    raise ESparseMatrixError.Create(
      'Sparse MultiplyDenseInto: destination must not alias the input.');
  AC := Convert(A, sfCSR);
  Temp := CreateDense(A.Rows, X.Cols);
  for R := 0 to A.Rows - 1 do
    for C := 0 to X.Cols - 1 do
    begin
      Sum := Default(T);
      for K := AC.GetOuterPointer(R) to AC.GetOuterPointer(R + 1) - 1 do
      begin
        J := AC.GetInnerIndex(K);
        Sum := Sum + AC.GetStoredValue(K) * X[J, C];
      end;
      Temp[R, C] := Sum;
    end;
  for R := 0 to Destination.Rows - 1 do
    for C := 0 to Destination.Cols - 1 do
      Destination[R, C] := Temp[R, C];
end;

class function TSparseMatrixFactory.Multiply(
  const A, B: specialize ISparseMatrix<T>): specialize ISparseMatrix<T>;
var
  AC, BC: TMatrix;
  Builder: specialize TSparseTripletBuilder<T>;
  Marker: TSparseSizeIntArray;
  Accumulator: specialize TSparseValueArray<T>;
  Touched: TSparseSizeIntArray;
  R, KA, KB, J, C, TouchedCount, I: SizeInt;
  Product: T;
begin
  if (A = nil) or (B = nil) then
    raise ESparseMatrixError.Create(
      'Sparse Multiply: matrix handles must not be nil.');
  if A.Cols <> B.Rows then
    raise ESparseMatrixError.CreateFmt(
      'Sparse Multiply: inner dimensions %d and %d do not match.',
      [A.Cols, B.Rows]);
  AC := Convert(A, sfCSR);
  BC := Convert(B, sfCSR);
  SetLength(Marker, B.Cols);
  SetLength(Accumulator, B.Cols);
  SetLength(Touched, B.Cols);
  for C := 0 to B.Cols - 1 do Marker[C] := -1;
  Builder := specialize TSparseTripletBuilder<T>.Create(A.Rows, B.Cols);
  try
    for R := 0 to A.Rows - 1 do
    begin
      TouchedCount := 0;
      for KA := AC.GetOuterPointer(R) to AC.GetOuterPointer(R + 1) - 1 do
      begin
        J := AC.GetInnerIndex(KA);
        for KB := BC.GetOuterPointer(J) to BC.GetOuterPointer(J + 1) - 1 do
        begin
          C := BC.GetInnerIndex(KB);
          Product := AC.GetStoredValue(KA) * BC.GetStoredValue(KB);
          if Marker[C] <> R then
          begin
            Marker[C] := R;
            Accumulator[C] := Product;
            Touched[TouchedCount] := C;
            Inc(TouchedCount);
          end
          else
            Accumulator[C] := Accumulator[C] + Product;
        end;
      end;
      { Builder sorting canonicalises the unsorted touched columns. }
      for I := 0 to TouchedCount - 1 do
      begin
        C := Touched[I];
        if not specialize TSparseMatrixStorage<T>.ScalarIsZero(
          Accumulator[C]) then
          Builder.Add(R, C, Accumulator[C]);
        Accumulator[C] := Default(T);
      end;
    end;
    Result := Builder.ToCSR(szDrop);
  finally
    Builder.Free;
  end;
end;

class function TSparseMatrixFactory.Row(
  const A: specialize ISparseMatrix<T>; const RowIndex: SizeInt):
  specialize IDenseMatrix<T>;
var
  AC: TMatrix;
  K: SizeInt;
begin
  if A = nil then
    raise ESparseMatrixError.Create('Sparse Row: matrix must not be nil.');
  specialize TSparseMatrixStorage<T>.RequireIndex(
    RowIndex, A.Rows, 'row', 'Sparse Row');
  AC := Convert(A, sfCSR);
  Result := CreateDense(1, A.Cols);
  for K := AC.GetOuterPointer(RowIndex) to
    AC.GetOuterPointer(RowIndex + 1) - 1 do
    Result[0, AC.GetInnerIndex(K)] := AC.GetStoredValue(K);
end;

class function TSparseMatrixFactory.Column(
  const A: specialize ISparseMatrix<T>; const ColumnIndex: SizeInt):
  specialize IDenseMatrix<T>;
var
  AC: TMatrix;
  K: SizeInt;
begin
  if A = nil then
    raise ESparseMatrixError.Create('Sparse Column: matrix must not be nil.');
  specialize TSparseMatrixStorage<T>.RequireIndex(
    ColumnIndex, A.Cols, 'column', 'Sparse Column');
  AC := Convert(A, sfCSC);
  Result := CreateDense(A.Rows, 1);
  for K := AC.GetOuterPointer(ColumnIndex) to
    AC.GetOuterPointer(ColumnIndex + 1) - 1 do
    Result[AC.GetInnerIndex(K), 0] := AC.GetStoredValue(K);
end;

class function TSparseMatrixFactory.Norm2(
  const A: specialize ISparseMatrix<T>): Double;
var
  ScaleValue, SumSquares, Magnitude: Double;
  K: SizeInt;
begin
  if A = nil then
    raise ESparseMatrixError.Create('Sparse Norm2: matrix must not be nil.');
  ScaleValue := 0.0;
  SumSquares := 1.0;
  for K := 0 to A.NonZeroCount - 1 do
  begin
    Magnitude := Sqrt(specialize TSparseMatrixStorage<T>.ScalarAbsSquared(
      A.GetStoredValue(K), A.ScalarKind));
    if Magnitude <> 0.0 then
      if ScaleValue < Magnitude then
      begin
        SumSquares := 1.0 + SumSquares * Sqr(ScaleValue / Magnitude);
        ScaleValue := Magnitude;
      end
      else
        SumSquares := SumSquares + Sqr(Magnitude / ScaleValue);
  end;
  if ScaleValue = 0.0 then Result := 0.0
  else Result := ScaleValue * Sqrt(SumSquares);
end;

constructor TStructuredMatrixStorage.Create(
  const Rows, Cols, LowerBandwidth,
  UpperBandwidth: SizeInt; const Kind: TStructuredMatrixKind;
  const ScalarKind: TSparseScalarKind; const Values: array of T);
var
  Expected, Width, I, R, Offset, C: SizeInt;
begin
  inherited Create;
  specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Cols, SizeOf(T), 'Structured matrix shape');
  if (LowerBandwidth < 0) or (UpperBandwidth < 0) then
    raise ESparseMatrixError.Create(
      'Structured matrix: bandwidths must be non-negative.');
  if (Rows > 0) and (LowerBandwidth >= Rows) then
    raise ESparseMatrixError.Create(
      'Structured matrix: lower bandwidth must be smaller than rows.');
  if (Cols > 0) and (UpperBandwidth >= Cols) then
    raise ESparseMatrixError.Create(
      'Structured matrix: upper bandwidth must be smaller than columns.');
  if SizeUInt(LowerBandwidth) + SizeUInt(UpperBandwidth) + 1 >
     SizeUInt(High(SizeInt)) then
    raise ESparseMatrixError.Create(
      'Structured matrix: compact row width exceeds SizeInt.');
  Width := LowerBandwidth + UpperBandwidth + 1;
  Expected := SizeInt(specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Width, SizeOf(T), 'Structured compact storage'));
  if Length(Values) <> Expected then
    raise ESparseMatrixError.CreateFmt(
      'Structured matrix: compact storage needs %d values; got %d.',
      [Expected, Length(Values)]);
  FRows := Rows;
  FCols := Cols;
  FLower := LowerBandwidth;
  FUpper := UpperBandwidth;
  FKind := Kind;
  FScalarKind := ScalarKind;
  SetLength(FValues, Length(Values));
  for I := 0 to High(Values) do
  begin
    if not specialize TSparseMatrixStorage<T>.ScalarIsFinite(
      Values[I], ScalarKind) then
      raise ESparseMatrixError.CreateFmt(
        'Structured matrix: value %d is non-finite.', [I]);
    FValues[I] := Values[I];
  end;
  { Padding outside the logical rectangle must be zero. }
  for R := 0 to Rows - 1 do
    for Offset := -LowerBandwidth to UpperBandwidth do
    begin
      C := R + Offset;
      if ((C < 0) or (C >= Cols)) and
         not specialize TSparseMatrixStorage<T>.ScalarIsZero(
            FValues[R * Width +
             Offset + LowerBandwidth]) then
        raise ESparseMatrixError.Create(
          'Structured matrix: compact padding outside the shape must be zero.');
    end;
end;

function TStructuredMatrixStorage.GetRows: SizeInt;
begin
  Result := FRows;
end;

function TStructuredMatrixStorage.GetCols: SizeInt;
begin
  Result := FCols;
end;

function TStructuredMatrixStorage.GetKind: TStructuredMatrixKind;
begin
  Result := FKind;
end;

function TStructuredMatrixStorage.GetScalarKind: TSparseScalarKind;
begin
  Result := FScalarKind;
end;

function TStructuredMatrixStorage.GetLowerBandwidth: SizeInt;
begin
  Result := FLower;
end;

function TStructuredMatrixStorage.GetUpperBandwidth: SizeInt;
begin
  Result := FUpper;
end;

function TStructuredMatrixStorage.GetValue(const Row, Col: SizeInt): T;
var
  Offset, Width: SizeInt;
begin
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Row, FRows, 'row', 'Structured element access');
  specialize TSparseMatrixStorage<T>.RequireIndex(
    Col, FCols, 'column', 'Structured element access');
  Offset := Col - Row;
  if (Offset < -FLower) or (Offset > FUpper) then
    Exit(Default(T));
  Width := FLower + FUpper + 1;
  Result := FValues[Row * Width + Offset + FLower];
end;

class function TStructuredMatrixFactory.CreateDense(
  const Rows, Cols: SizeInt): TDenseMatrix;
begin
  case specialize TSparseMatrixStorage<T>.ScalarKindOf of
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

class function TStructuredMatrixFactory.Diagonal(const Rows, Cols: SizeInt;
  const DiagonalValues: array of T): specialize IStructuredMatrix<T>;
var
  Values: specialize TSparseValueArray<T>;
  R, Count: SizeInt;
begin
  specialize TSparseMatrixStorage<T>.CheckedCount(
    Rows, Cols, SizeOf(T), 'Structured Diagonal');
  Count := Min(Rows, Cols);
  if Length(DiagonalValues) <> Count then
    raise ESparseMatrixError.CreateFmt(
      'Structured Diagonal: expected %d diagonal values; got %d.',
      [Count, Length(DiagonalValues)]);
  SetLength(Values, Rows);
  for R := 0 to Count - 1 do Values[R] := DiagonalValues[R];
  Result := specialize TStructuredMatrixStorage<T>.Create(
    Rows, Cols, 0, 0, smDiagonal,
    specialize TSparseMatrixStorage<T>.ScalarKindOf, Values);
end;

class function TStructuredMatrixFactory.Tridiagonal(
  const Lower, DiagonalValues, Upper: array of T):
  specialize IStructuredMatrix<T>;
var
  Values: specialize TSparseValueArray<T>;
  N, I, Width: SizeInt;
begin
  N := Length(DiagonalValues);
  if (Length(Lower) <> Max(0, N - 1)) or
     (Length(Upper) <> Max(0, N - 1)) then
    raise ESparseMatrixError.Create(
      'Structured Tridiagonal: lower and upper arrays must have length n-1.');
  Width := 3;
  SetLength(Values, N * Width);
  for I := 0 to N - 1 do Values[I * Width + 1] := DiagonalValues[I];
  for I := 0 to N - 2 do
  begin
    Values[(I + 1) * Width] := Lower[I];
    Values[I * Width + 2] := Upper[I];
  end;
  Result := specialize TStructuredMatrixStorage<T>.Create(
    N, N, 1, 1, smTridiagonal,
    specialize TSparseMatrixStorage<T>.ScalarKindOf, Values);
end;

class function TStructuredMatrixFactory.Band(const Rows, Cols,
  LowerBandwidth, UpperBandwidth: SizeInt;
  const CompactValues: array of T): specialize IStructuredMatrix<T>;
begin
  Result := specialize TStructuredMatrixStorage<T>.Create(
    Rows, Cols, LowerBandwidth, UpperBandwidth, smBand,
    specialize TSparseMatrixStorage<T>.ScalarKindOf, CompactValues);
end;

class function TStructuredMatrixFactory.ToSparse(
  const Matrix: specialize IStructuredMatrix<T>;
  const Format: TSparseFormat): specialize ISparseMatrix<T>;
var
  Builder: specialize TSparseTripletBuilder<T>;
  R, C, FirstCol, LastCol: SizeInt;
  Value: T;
begin
  if Matrix = nil then
    raise ESparseMatrixError.Create(
      'Structured ToSparse: matrix handle must not be nil.');
  Builder := specialize TSparseTripletBuilder<T>.Create(
    Matrix.Rows, Matrix.Cols);
  try
    for R := 0 to Matrix.Rows - 1 do
    begin
      FirstCol := Max(0, R - Matrix.LowerBandwidth);
      LastCol := Min(Matrix.Cols - 1, R + Matrix.UpperBandwidth);
      for C := FirstCol to LastCol do
      begin
        Value := Matrix[R, C];
        if not specialize TSparseMatrixStorage<T>.ScalarIsZero(Value) then
          Builder.Add(R, C, Value);
      end;
    end;
    if Format = sfCSR then Result := Builder.ToCSR(szDrop)
    else Result := Builder.ToCSC(szDrop);
  finally
    Builder.Free;
  end;
end;

class function TStructuredMatrixFactory.ToDense(
  const Matrix: specialize IStructuredMatrix<T>):
  specialize IDenseMatrix<T>;
var
  R, C, FirstCol, LastCol: SizeInt;
begin
  if Matrix = nil then
    raise ESparseMatrixError.Create(
      'Structured ToDense: matrix handle must not be nil.');
  Result := CreateDense(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
  begin
    FirstCol := Max(0, R - Matrix.LowerBandwidth);
    LastCol := Min(Matrix.Cols - 1, R + Matrix.UpperBandwidth);
    for C := FirstCol to LastCol do Result[R, C] := Matrix[R, C];
  end;
end;

class procedure TStructuredMatrixFactory.MultiplyDenseInto(
  const A: specialize IStructuredMatrix<T>;
  const X, Destination: specialize IDenseMatrix<T>);
var
  Temp: TDenseMatrix;
  R, C, J, FirstCol, LastCol: SizeInt;
  Sum: T;
begin
  if (A = nil) or (X = nil) or (Destination = nil) then
    raise ESparseMatrixError.Create(
      'Structured MultiplyDenseInto: handles must not be nil.');
  if A.Cols <> X.Rows then
    raise ESparseMatrixError.Create(
      'Structured MultiplyDenseInto: inner dimensions do not match.');
  if (Destination.Rows <> A.Rows) or (Destination.Cols <> X.Cols) then
    raise ESparseMatrixError.CreateFmt(
      'Structured MultiplyDenseInto: destination must have shape %d x %d.',
      [A.Rows, X.Cols]);
  if (Destination.StorageIdentity = X.StorageIdentity) and
     (Destination.StorageIdentity <> nil) then
    raise ESparseMatrixError.Create(
      'Structured MultiplyDenseInto: destination must not alias input.');
  Temp := CreateDense(A.Rows, X.Cols);
  for R := 0 to A.Rows - 1 do
  begin
    FirstCol := Max(0, R - A.LowerBandwidth);
    LastCol := Min(A.Cols - 1, R + A.UpperBandwidth);
    for C := 0 to X.Cols - 1 do
    begin
      Sum := Default(T);
      for J := FirstCol to LastCol do
        Sum := Sum + A[R, J] * X[J, C];
      Temp[R, C] := Sum;
    end;
  end;
  for R := 0 to Destination.Rows - 1 do
    for C := 0 to Destination.Cols - 1 do
      Destination[R, C] := Temp[R, C];
end;

end.
