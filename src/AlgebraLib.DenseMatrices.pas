unit AlgebraLib.DenseMatrices;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseMatrices

 Typed, row-major dense storage for mathlib-fp 1.5.

 Public matrices are reference-counted handles.  A matrix created by a factory
 owns aligned storage. Clone is a deep copy. Views retain the storage owner and
 are mutable aliases: writes through either handle are immediately visible
 through the other. No public view borrows an untracked raw pointer.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.Matrices;

const
  DENSE_ALIGNMENT = 32;

type
  EDenseMatrixError = class(Exception);

  TSingleMatrixArray = array of array of Single;
  TComplexMatrixArray = array of array of TComplex;
  TSingleComplexMatrixArray = array of array of TSingleComplex;
  TSizeIntArray = array of SizeInt;

  TDenseShape = record
    Rows: SizeInt;
    Cols: SizeInt;
    class function Create(const ARows, ACols: SizeInt): TDenseShape; static;
    function ElementCount: SizeUInt;
  end;

  { Allocation-free 2x2 value used for tiny and batched workloads. Matrix
    multiplication and elementwise addition/subtraction are natural operators;
    no general dense handle or heap allocation is involved. }
  generic TSmallDenseMatrix2<T> = record
  private
    FValues: array[0..3] of T;
    function GetValue(const Row, Col: SizeInt): T;
  public
    class function Create(const M00, M01, M10, M11: T):
      specialize TSmallDenseMatrix2<T>; static;
    class operator +(const A, B: specialize TSmallDenseMatrix2<T>):
      specialize TSmallDenseMatrix2<T>;
    class operator -(const A, B: specialize TSmallDenseMatrix2<T>):
      specialize TSmallDenseMatrix2<T>;
    class operator *(const A, B: specialize TSmallDenseMatrix2<T>):
      specialize TSmallDenseMatrix2<T>;
    class operator *(const A: specialize TSmallDenseMatrix2<T>;
      const Scalar: T): specialize TSmallDenseMatrix2<T>;
    class operator *(const Scalar: T;
      const A: specialize TSmallDenseMatrix2<T>):
      specialize TSmallDenseMatrix2<T>;
    property Values[const Row, Col: SizeInt]: T read GetValue; default;
  end;

  TSmallSingleMatrix2 = specialize TSmallDenseMatrix2<Single>;
  TSmallDoubleMatrix2 = specialize TSmallDenseMatrix2<Double>;
  TSmallSingleComplexMatrix2 =
    specialize TSmallDenseMatrix2<TSingleComplex>;
  TSmallComplexMatrix2 = specialize TSmallDenseMatrix2<TComplex>;
  TSmallSingleMatrix2Batch = array of TSmallSingleMatrix2;
  TSmallDoubleMatrix2Batch = array of TSmallDoubleMatrix2;
  TSmallSingleComplexMatrix2Batch = array of TSmallSingleComplexMatrix2;
  TSmallComplexMatrix2Batch = array of TSmallComplexMatrix2;

  generic IDenseMatrix<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetValue(const Row, Col: SizeInt): T;
    procedure SetValue(const Row, Col: SizeInt; const Value: T);
    function GetIsContiguous: Boolean;
    function GetDataPointer: Pointer;
    function GetStorageIdentity: Pointer;
    function Clone: specialize IDenseMatrix<T>;
    function View(const StartRow, StartCol, RowCount, ColCount: SizeInt):
      specialize IDenseMatrix<T>;
    function RowView(const Row: SizeInt): specialize IDenseMatrix<T>;
    function ColumnView(const Col: SizeInt): specialize IDenseMatrix<T>;
    function DiagonalView(const Offset: SizeInt = 0): specialize IDenseMatrix<T>;
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    property Values[const Row, Col: SizeInt]: T read GetValue write SetValue; default;
    property IsContiguous: Boolean read GetIsContiguous;
    { Nil for strided views. The pointer remains valid while this matrix or a
      view retaining the same storage is alive. }
    property DataPointer: Pointer read GetDataPointer;
    { Opaque token for conservative alias detection. Do not dereference it. }
    property StorageIdentity: Pointer read GetStorageIdentity;
  end;

  IDenseSingleMatrix = specialize IDenseMatrix<Single>;
  IDenseDoubleMatrix = specialize IDenseMatrix<Double>;
  IDenseSingleComplexMatrix = specialize IDenseMatrix<TSingleComplex>;
  IDenseComplexMatrix = specialize IDenseMatrix<TComplex>;

  TDenseSingleMatrix = class
  public
    class function Zeros(const Rows, Cols: SizeInt): IDenseSingleMatrix; static;
    class function FromValues(const Rows, Cols: SizeInt;
      const Values: array of Single): IDenseSingleMatrix; static;
    class function FromArray(const Values: TSingleMatrixArray):
      IDenseSingleMatrix; static;
    class function FromVector(const Values: TSingleArray;
      const AsColumn: Boolean = True): IDenseSingleMatrix; static;
  end;

  TDenseDoubleMatrix = class
  public
    class function Zeros(const Rows, Cols: SizeInt): IDenseDoubleMatrix; static;
    class function FromValues(const Rows, Cols: SizeInt;
      const Values: array of Double): IDenseDoubleMatrix; static;
    class function FromArray(const Values: TMatrixArray):
      IDenseDoubleMatrix; static;
    class function FromVector(const Values: TDoubleArray;
      const AsColumn: Boolean = True): IDenseDoubleMatrix; static;
    class function FromIMatrix(const Values: IMatrix): IDenseDoubleMatrix; static;
  end;

  TDenseSingleComplexMatrix = class
  public
    class function Zeros(const Rows, Cols: SizeInt):
      IDenseSingleComplexMatrix; static;
    class function FromValues(const Rows, Cols: SizeInt;
      const Values: array of TSingleComplex): IDenseSingleComplexMatrix; static;
    class function FromArray(const Values: TSingleComplexMatrixArray):
      IDenseSingleComplexMatrix; static;
    class function FromVector(const Values: TSingleComplexArray;
      const AsColumn: Boolean = True): IDenseSingleComplexMatrix; static;
  end;

  TDenseComplexMatrix = class
  public
    class function Zeros(const Rows, Cols: SizeInt): IDenseComplexMatrix; static;
    class function FromValues(const Rows, Cols: SizeInt;
      const Values: array of TComplex): IDenseComplexMatrix; static;
    class function FromArray(const Values: TComplexMatrixArray):
      IDenseComplexMatrix; static;
    class function FromVector(const Values: TComplexArray;
      const AsColumn: Boolean = True): IDenseComplexMatrix; static;
  end;

function ToArray(const Matrix: IDenseSingleMatrix): TSingleMatrixArray; overload;
function ToArray(const Matrix: IDenseDoubleMatrix): TMatrixArray; overload;
function ToArray(const Matrix: IDenseSingleComplexMatrix):
  TSingleComplexMatrixArray; overload;
function ToArray(const Matrix: IDenseComplexMatrix):
  TComplexMatrixArray; overload;
function ToVector(const Matrix: IDenseSingleMatrix): TSingleArray; overload;
function ToVector(const Matrix: IDenseDoubleMatrix): TDoubleArray; overload;
function ToVector(const Matrix: IDenseSingleComplexMatrix):
  TSingleComplexArray; overload;
function ToVector(const Matrix: IDenseComplexMatrix): TComplexArray; overload;
function ToIMatrix(const Matrix: IDenseDoubleMatrix): IMatrix;
function ConvertToDouble(const Matrix: IDenseSingleMatrix):
  IDenseDoubleMatrix;
function ConvertToSingle(const Matrix: IDenseDoubleMatrix):
  IDenseSingleMatrix;
function ConvertToComplex(const Matrix: IDenseDoubleMatrix):
  IDenseComplexMatrix; overload;
function ConvertToComplex(const Matrix: IDenseSingleMatrix):
  IDenseSingleComplexMatrix; overload;
function ConvertToReal(const Matrix: IDenseComplexMatrix):
  IDenseDoubleMatrix; overload;
function ConvertToReal(const Matrix: IDenseSingleComplexMatrix):
  IDenseSingleMatrix; overload;
function ConvertToDoubleComplex(const Matrix: IDenseSingleComplexMatrix):
  IDenseComplexMatrix;
function ConvertToSingleComplex(const Matrix: IDenseComplexMatrix):
  IDenseSingleComplexMatrix;

implementation

type
  generic IAlignedStorage<T> = interface
    function GetData: Pointer;
    function GetCount: SizeUInt;
    property Data: Pointer read GetData;
    property Count: SizeUInt read GetCount;
  end;

  generic TAlignedStorage<T> = class(TInterfacedObject,
    specialize IAlignedStorage<T>)
  private
    FRaw: Pointer;
    FData: Pointer;
    FCount: SizeUInt;
  public
    constructor Create(const Count: SizeUInt);
    destructor Destroy; override;
    function GetData: Pointer;
    function GetCount: SizeUInt;
  end;

  generic TDenseMatrixImpl<T> = class(TInterfacedObject,
    specialize IDenseMatrix<T>)
  private type
    PScalar = ^T;
  private
    FStorage: specialize IAlignedStorage<T>;
    FRows, FCols: SizeInt;
    FOffset, FRowStride, FColStride: SizeUInt;
    function ScalarPointer(const Row, Col: SizeInt): PScalar;
  public
    constructor CreateOwned(const Rows, Cols: SizeInt);
    constructor CreateView(const Storage: specialize IAlignedStorage<T>;
      const Rows, Cols: SizeInt; const Offset, RowStride, ColStride: SizeUInt);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetValue(const Row, Col: SizeInt): T;
    procedure SetValue(const Row, Col: SizeInt; const Value: T);
    function GetIsContiguous: Boolean;
    function GetDataPointer: Pointer;
    function GetStorageIdentity: Pointer;
    function Clone: specialize IDenseMatrix<T>;
    function View(const StartRow, StartCol, RowCount, ColCount: SizeInt):
      specialize IDenseMatrix<T>;
    function RowView(const Row: SizeInt): specialize IDenseMatrix<T>;
    function ColumnView(const Col: SizeInt): specialize IDenseMatrix<T>;
    function DiagonalView(const Offset: SizeInt = 0):
      specialize IDenseMatrix<T>;
  end;

function CheckedElementCount(const Rows, Cols: SizeInt;
  const ElementSize: SizeUInt): SizeUInt;
var
  URows, UCols: SizeUInt;
begin
  if (Rows < 0) or (Cols < 0) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix shape: rows and columns must be non-negative; got %d x %d.',
      [Rows, Cols]);
  URows := SizeUInt(Rows);
  UCols := SizeUInt(Cols);
  if (UCols <> 0) and (URows > High(SizeUInt) div UCols) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix allocation: shape %d x %d overflows native-size arithmetic.',
      [Rows, Cols]);
  Result := URows * UCols;
  if (Result <> 0) and (ElementSize > High(SizeUInt) div Result) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix allocation: shape %d x %d byte size overflows native-size arithmetic.',
      [Rows, Cols]);
  if Result * ElementSize > SizeUInt(High(SizeInt)) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix allocation: shape %d x %d exceeds the supported address-space limit.',
      [Rows, Cols]);
end;

class function TSmallDenseMatrix2.Create(const M00, M01, M10, M11: T):
  specialize TSmallDenseMatrix2<T>;
begin
  Result.FValues[0] := M00;
  Result.FValues[1] := M01;
  Result.FValues[2] := M10;
  Result.FValues[3] := M11;
end;

function TSmallDenseMatrix2.GetValue(const Row, Col: SizeInt): T;
begin
  if (Row < 0) or (Row > 1) or (Col < 0) or (Col > 1) then
    raise EDenseMatrixError.CreateFmt(
      'Small 2x2 matrix element access: index [%d,%d] is outside shape 2 x 2.',
      [Row, Col]);
  Result := FValues[Row * 2 + Col];
end;

class operator TSmallDenseMatrix2.+(const A, B:
  specialize TSmallDenseMatrix2<T>): specialize TSmallDenseMatrix2<T>;
begin
  Result := specialize TSmallDenseMatrix2<T>.Create(
    A.FValues[0] + B.FValues[0], A.FValues[1] + B.FValues[1],
    A.FValues[2] + B.FValues[2], A.FValues[3] + B.FValues[3]);
end;

class operator TSmallDenseMatrix2.-(const A, B:
  specialize TSmallDenseMatrix2<T>): specialize TSmallDenseMatrix2<T>;
begin
  Result := specialize TSmallDenseMatrix2<T>.Create(
    A.FValues[0] - B.FValues[0], A.FValues[1] - B.FValues[1],
    A.FValues[2] - B.FValues[2], A.FValues[3] - B.FValues[3]);
end;

class operator TSmallDenseMatrix2.*(const A, B:
  specialize TSmallDenseMatrix2<T>): specialize TSmallDenseMatrix2<T>;
begin
  Result := specialize TSmallDenseMatrix2<T>.Create(
    A.FValues[0] * B.FValues[0] + A.FValues[1] * B.FValues[2],
    A.FValues[0] * B.FValues[1] + A.FValues[1] * B.FValues[3],
    A.FValues[2] * B.FValues[0] + A.FValues[3] * B.FValues[2],
    A.FValues[2] * B.FValues[1] + A.FValues[3] * B.FValues[3]);
end;

class operator TSmallDenseMatrix2.*(const A:
  specialize TSmallDenseMatrix2<T>; const Scalar: T):
  specialize TSmallDenseMatrix2<T>;
begin
  Result := specialize TSmallDenseMatrix2<T>.Create(
    A.FValues[0] * Scalar, A.FValues[1] * Scalar,
    A.FValues[2] * Scalar, A.FValues[3] * Scalar);
end;

class operator TSmallDenseMatrix2.*(const Scalar: T; const A:
  specialize TSmallDenseMatrix2<T>): specialize TSmallDenseMatrix2<T>;
begin
  Result := A * Scalar;
end;

class function TDenseShape.Create(const ARows, ACols: SizeInt): TDenseShape;
begin
  CheckedElementCount(ARows, ACols, 1);
  Result.Rows := ARows;
  Result.Cols := ACols;
end;

function TDenseShape.ElementCount: SizeUInt;
begin
  Result := CheckedElementCount(Rows, Cols, 1);
end;

function AlignmentPaddedByteCount(const ByteCount: SizeUInt): SizeUInt;
begin
  if ByteCount > High(SizeUInt) - SizeUInt(DENSE_ALIGNMENT - 1) then
    raise EDenseMatrixError.Create(
      'Dense matrix allocation: alignment padding overflows native-size arithmetic.');
  Result := SizeUInt(QWord(ByteCount) + QWord(DENSE_ALIGNMENT - 1));
end;

function AlignDensePointer(const Raw: Pointer): Pointer;
begin
  { PtrUInt is the RTL's pointer-width unsigned type. This isolated ordinal
    round trip only rounds a GetMem address up to the documented alignment. }
  {$PUSH}{$WARN 4055 OFF}{$WARN 4056 OFF}
  Result := Pointer((PtrUInt(Raw) + PtrUInt(DENSE_ALIGNMENT - 1)) and
    not PtrUInt(DENSE_ALIGNMENT - 1));
  {$POP}
end;

constructor TAlignedStorage.Create(const Count: SizeUInt);
var
  ByteCount, RawByteCount: SizeUInt;
begin
  inherited Create;
  FRaw := nil;
  FData := nil;
  FCount := Count;
  if Count = 0 then
    Exit;
  if SizeUInt(SizeOf(T)) > High(SizeUInt) div Count then
    raise EDenseMatrixError.Create(
      'Dense matrix allocation: byte size overflows native-size arithmetic.');
  ByteCount := Count * SizeUInt(SizeOf(T));
  RawByteCount := AlignmentPaddedByteCount(ByteCount);
  try
    GetMem(FRaw, RawByteCount);
  except
    on E: EOutOfMemory do
      raise EDenseMatrixError.CreateFmt(
        'Dense matrix allocation: unable to allocate %d bytes.', [ByteCount]);
  end;
  FData := AlignDensePointer(FRaw);
  FillChar(FData^, ByteCount, 0);
end;

destructor TAlignedStorage.Destroy;
begin
  if FRaw <> nil then
    FreeMem(FRaw);
  inherited Destroy;
end;

function TAlignedStorage.GetData: Pointer;
begin
  Result := FData;
end;

function TAlignedStorage.GetCount: SizeUInt;
begin
  Result := FCount;
end;

constructor TDenseMatrixImpl.CreateOwned(const Rows, Cols: SizeInt);
var
  Count: SizeUInt;
begin
  inherited Create;
  Count := CheckedElementCount(Rows, Cols, SizeOf(T));
  FStorage := specialize TAlignedStorage<T>.Create(Count);
  FRows := Rows;
  FCols := Cols;
  FOffset := 0;
  FRowStride := SizeUInt(Cols);
  FColStride := 1;
end;

constructor TDenseMatrixImpl.CreateView(
  const Storage: specialize IAlignedStorage<T>; const Rows, Cols: SizeInt;
  const Offset, RowStride, ColStride: SizeUInt);
begin
  inherited Create;
  FStorage := Storage;
  FRows := Rows;
  FCols := Cols;
  FOffset := Offset;
  FRowStride := RowStride;
  FColStride := ColStride;
end;

function TDenseMatrixImpl.ScalarPointer(const Row, Col: SizeInt): PScalar;
var
  Index: SizeUInt;
begin
  if (Row < 0) or (Row >= FRows) or (Col < 0) or (Col >= FCols) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix element access: index [%d,%d] is outside shape %d x %d.',
      [Row, Col, FRows, FCols]);
  Index := FOffset + SizeUInt(Row) * FRowStride + SizeUInt(Col) * FColStride;
  if Index >= FStorage.Count then
    raise EDenseMatrixError.Create(
      'Dense matrix element access: validated view exceeds its backing storage.');
  Result := PScalar(PByte(FStorage.Data) + Index * SizeUInt(SizeOf(T)));
end;

function TDenseMatrixImpl.GetRows: SizeInt;
begin
  Result := FRows;
end;

function TDenseMatrixImpl.GetCols: SizeInt;
begin
  Result := FCols;
end;

function TDenseMatrixImpl.GetValue(const Row, Col: SizeInt): T;
begin
  Result := ScalarPointer(Row, Col)^;
end;

procedure TDenseMatrixImpl.SetValue(const Row, Col: SizeInt; const Value: T);
begin
  ScalarPointer(Row, Col)^ := Value;
end;

function TDenseMatrixImpl.GetIsContiguous: Boolean;
begin
  Result := (FRows = 0) or (FCols = 0) or
    ((FColStride = 1) and
     ((FRows = 1) or (FRowStride = SizeUInt(FCols))));
end;

function TDenseMatrixImpl.GetDataPointer: Pointer;
begin
  if not GetIsContiguous or (FRows = 0) or (FCols = 0) then
    Exit(nil);
  Result := PByte(FStorage.Data) + FOffset * SizeUInt(SizeOf(T));
end;

function TDenseMatrixImpl.GetStorageIdentity: Pointer;
begin
  Result := FStorage.Data;
end;

function TDenseMatrixImpl.Clone: specialize IDenseMatrix<T>;
var
  R, C: SizeInt;
begin
  Result := specialize TDenseMatrixImpl<T>.CreateOwned(FRows, FCols);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      Result[R, C] := GetValue(R, C);
end;

function TDenseMatrixImpl.View(const StartRow, StartCol, RowCount,
  ColCount: SizeInt): specialize IDenseMatrix<T>;
var
  NewOffset: SizeUInt;
begin
  if (StartRow < 0) or (StartCol < 0) or (RowCount < 0) or (ColCount < 0) or
     (StartRow > FRows) or (StartCol > FCols) or
     (RowCount > FRows - StartRow) or (ColCount > FCols - StartCol) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix View: rectangle [%d,%d] + %d x %d is outside shape %d x %d.',
      [StartRow, StartCol, RowCount, ColCount, FRows, FCols]);
  if (RowCount = 0) or (ColCount = 0) then
    NewOffset := FOffset
  else
    NewOffset := FOffset + SizeUInt(StartRow) * FRowStride +
      SizeUInt(StartCol) * FColStride;
  Result := specialize TDenseMatrixImpl<T>.CreateView(FStorage, RowCount,
    ColCount, NewOffset, FRowStride, FColStride);
end;

function TDenseMatrixImpl.RowView(const Row: SizeInt):
  specialize IDenseMatrix<T>;
begin
  Result := View(Row, 0, 1, FCols);
end;

function TDenseMatrixImpl.ColumnView(const Col: SizeInt):
  specialize IDenseMatrix<T>;
begin
  Result := View(0, Col, FRows, 1);
end;

function TDenseMatrixImpl.DiagonalView(const Offset: SizeInt):
  specialize IDenseMatrix<T>;
var
  StartRow, StartCol, Count: SizeInt;
begin
  if Offset = Low(SizeInt) then
    raise EDenseMatrixError.Create(
      'Dense matrix DiagonalView: offset magnitude exceeds SizeInt.');
  if Offset >= 0 then
  begin
    StartRow := 0;
    StartCol := Offset;
  end
  else
  begin
    StartRow := -Offset;
    StartCol := 0;
  end;
  if (StartRow >= FRows) or (StartCol >= FCols) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix DiagonalView: offset %d is outside shape %d x %d.',
      [Offset, FRows, FCols]);
  Count := Min(FRows - StartRow, FCols - StartCol);
  Result := specialize TDenseMatrixImpl<T>.CreateView(FStorage, Count, 1,
    FOffset + SizeUInt(StartRow) * FRowStride +
      SizeUInt(StartCol) * FColStride,
    FRowStride + FColStride, 1);
end;

generic function MatrixFromValues<T>(const Rows, Cols: SizeInt;
  const Values: array of T): specialize IDenseMatrix<T>;
var
  Count: SizeUInt;
  I: SizeInt;
begin
  Count := CheckedElementCount(Rows, Cols, SizeOf(T));
  if Count <> SizeUInt(Length(Values)) then
    raise EDenseMatrixError.CreateFmt(
      'Dense matrix FromValues: shape %d x %d needs %d values; got %d.',
      [Rows, Cols, Count, Length(Values)]);
  Result := specialize TDenseMatrixImpl<T>.CreateOwned(Rows, Cols);
  for I := 0 to SizeInt(Count) - 1 do
    Result[I div Cols, I mod Cols] := Values[I];
end;

class function TDenseSingleMatrix.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleMatrix;
begin
  Result := specialize TDenseMatrixImpl<Single>.CreateOwned(Rows, Cols);
end;

class function TDenseSingleMatrix.FromValues(const Rows, Cols: SizeInt;
  const Values: array of Single): IDenseSingleMatrix;
begin
  Result := specialize MatrixFromValues<Single>(Rows, Cols, Values);
end;

class function TDenseSingleMatrix.FromArray(
  const Values: TSingleMatrixArray): IDenseSingleMatrix;
var
  R, C, Cols: SizeInt;
begin
  if Length(Values) = 0 then
    Exit(Zeros(0, 0));
  Cols := Length(Values[0]);
  Result := Zeros(Length(Values), Cols);
  for R := 0 to High(Values) do
  begin
    if Length(Values[R]) <> Cols then
      raise EDenseMatrixError.CreateFmt(
        'Dense single matrix FromArray: row %d has length %d; expected %d.',
        [R, Length(Values[R]), Cols]);
    for C := 0 to Cols - 1 do
      Result[R, C] := Values[R, C];
  end;
end;

class function TDenseSingleMatrix.FromVector(const Values: TSingleArray;
  const AsColumn: Boolean): IDenseSingleMatrix;
begin
  if AsColumn then
    Result := FromValues(Length(Values), 1, Values)
  else
    Result := FromValues(1, Length(Values), Values);
end;

class function TDenseDoubleMatrix.Zeros(const Rows, Cols: SizeInt):
  IDenseDoubleMatrix;
begin
  Result := specialize TDenseMatrixImpl<Double>.CreateOwned(Rows, Cols);
end;

class function TDenseDoubleMatrix.FromValues(const Rows, Cols: SizeInt;
  const Values: array of Double): IDenseDoubleMatrix;
begin
  Result := specialize MatrixFromValues<Double>(Rows, Cols, Values);
end;

class function TDenseDoubleMatrix.FromArray(const Values: TMatrixArray):
  IDenseDoubleMatrix;
var
  R, C, Cols: SizeInt;
begin
  if Length(Values) = 0 then
    Exit(Zeros(0, 0));
  Cols := Length(Values[0]);
  Result := Zeros(Length(Values), Cols);
  for R := 0 to High(Values) do
  begin
    if Length(Values[R]) <> Cols then
      raise EDenseMatrixError.CreateFmt(
        'Dense double matrix FromArray: row %d has length %d; expected %d.',
        [R, Length(Values[R]), Cols]);
    for C := 0 to Cols - 1 do
      Result[R, C] := Values[R, C];
  end;
end;

class function TDenseDoubleMatrix.FromVector(const Values: TDoubleArray;
  const AsColumn: Boolean): IDenseDoubleMatrix;
begin
  if AsColumn then
    Result := FromValues(Length(Values), 1, Values)
  else
    Result := FromValues(1, Length(Values), Values);
end;

class function TDenseDoubleMatrix.FromIMatrix(const Values: IMatrix):
  IDenseDoubleMatrix;
var
  R, C: SizeInt;
begin
  if Values = nil then
    raise EDenseMatrixError.Create('Dense double matrix FromIMatrix: source is nil.');
  Result := Zeros(Values.Rows, Values.Cols);
  for R := 0 to Values.Rows - 1 do
    for C := 0 to Values.Cols - 1 do
      Result[R, C] := Values[R, C];
end;

class function TDenseSingleComplexMatrix.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleComplexMatrix;
begin
  Result := specialize TDenseMatrixImpl<TSingleComplex>.CreateOwned(Rows, Cols);
end;

class function TDenseSingleComplexMatrix.FromValues(const Rows, Cols: SizeInt;
  const Values: array of TSingleComplex): IDenseSingleComplexMatrix;
begin
  Result := specialize MatrixFromValues<TSingleComplex>(Rows, Cols, Values);
end;

class function TDenseSingleComplexMatrix.FromArray(
  const Values: TSingleComplexMatrixArray): IDenseSingleComplexMatrix;
var
  R, C, Cols: SizeInt;
begin
  if Length(Values) = 0 then
    Exit(Zeros(0, 0));
  Cols := Length(Values[0]);
  Result := Zeros(Length(Values), Cols);
  for R := 0 to High(Values) do
  begin
    if Length(Values[R]) <> Cols then
      raise EDenseMatrixError.CreateFmt(
        'Dense single-complex matrix FromArray: row %d has length %d; expected %d.',
        [R, Length(Values[R]), Cols]);
    for C := 0 to Cols - 1 do
      Result[R, C] := Values[R, C];
  end;
end;

class function TDenseSingleComplexMatrix.FromVector(
  const Values: TSingleComplexArray; const AsColumn: Boolean):
  IDenseSingleComplexMatrix;
begin
  if AsColumn then
    Result := FromValues(Length(Values), 1, Values)
  else
    Result := FromValues(1, Length(Values), Values);
end;

class function TDenseComplexMatrix.Zeros(const Rows, Cols: SizeInt):
  IDenseComplexMatrix;
begin
  Result := specialize TDenseMatrixImpl<TComplex>.CreateOwned(Rows, Cols);
end;

class function TDenseComplexMatrix.FromValues(const Rows, Cols: SizeInt;
  const Values: array of TComplex): IDenseComplexMatrix;
begin
  Result := specialize MatrixFromValues<TComplex>(Rows, Cols, Values);
end;

class function TDenseComplexMatrix.FromArray(
  const Values: TComplexMatrixArray): IDenseComplexMatrix;
var
  R, C, Cols: SizeInt;
begin
  if Length(Values) = 0 then
    Exit(Zeros(0, 0));
  Cols := Length(Values[0]);
  Result := Zeros(Length(Values), Cols);
  for R := 0 to High(Values) do
  begin
    if Length(Values[R]) <> Cols then
      raise EDenseMatrixError.CreateFmt(
        'Dense complex matrix FromArray: row %d has length %d; expected %d.',
        [R, Length(Values[R]), Cols]);
    for C := 0 to Cols - 1 do
      Result[R, C] := Values[R, C];
  end;
end;

class function TDenseComplexMatrix.FromVector(const Values: TComplexArray;
  const AsColumn: Boolean): IDenseComplexMatrix;
begin
  if AsColumn then
    Result := FromValues(Length(Values), 1, Values)
  else
    Result := FromValues(1, Length(Values), Values);
end;

function ToArray(const Matrix: IDenseSingleMatrix): TSingleMatrixArray;
var
  R, C: SizeInt;
begin
  Result := nil;
  if Matrix = nil then
    raise EDenseMatrixError.Create('ToArray(single): source is nil.');
  SetLength(Result, Matrix.Rows);
  for R := 0 to Matrix.Rows - 1 do
  begin
    SetLength(Result[R], Matrix.Cols);
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := Matrix[R, C];
  end;
end;

function ToArray(const Matrix: IDenseDoubleMatrix): TMatrixArray;
var
  R, C: SizeInt;
begin
  Result := nil;
  if Matrix = nil then
    raise EDenseMatrixError.Create('ToArray(double): source is nil.');
  SetLength(Result, Matrix.Rows);
  for R := 0 to Matrix.Rows - 1 do
  begin
    SetLength(Result[R], Matrix.Cols);
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := Matrix[R, C];
  end;
end;

function ToArray(const Matrix: IDenseSingleComplexMatrix):
  TSingleComplexMatrixArray;
var
  R, C: SizeInt;
begin
  Result := nil;
  if Matrix = nil then
    raise EDenseMatrixError.Create('ToArray(single complex): source is nil.');
  SetLength(Result, Matrix.Rows);
  for R := 0 to Matrix.Rows - 1 do
  begin
    SetLength(Result[R], Matrix.Cols);
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := Matrix[R, C];
  end;
end;

function ToArray(const Matrix: IDenseComplexMatrix): TComplexMatrixArray;
var
  R, C: SizeInt;
begin
  Result := nil;
  if Matrix = nil then
    raise EDenseMatrixError.Create('ToArray(complex): source is nil.');
  SetLength(Result, Matrix.Rows);
  for R := 0 to Matrix.Rows - 1 do
  begin
    SetLength(Result[R], Matrix.Cols);
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := Matrix[R, C];
  end;
end;

function ToIMatrix(const Matrix: IDenseDoubleMatrix): IMatrix;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ToIMatrix: source is nil.');
  Result := TMatrixKit.CreateFromArray(ToArray(Matrix));
end;

generic function MatrixVectorLength<T>(const Matrix: specialize IDenseMatrix<T>;
  const Operation: string): SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create(Operation + ': source is nil.');
  if (Matrix.Rows <> 1) and (Matrix.Cols <> 1) then
    raise EDenseMatrixError.CreateFmt(
      '%s: source must be a row or column vector; got %d x %d.',
      [Operation, Matrix.Rows, Matrix.Cols]);
  if Matrix.Rows = 1 then
    Result := Matrix.Cols
  else
    Result := Matrix.Rows;
end;

function ToVector(const Matrix: IDenseSingleMatrix): TSingleArray;
var
  I, Count: SizeInt;
begin
  Result := nil;
  Count := specialize MatrixVectorLength<Single>(Matrix, 'ToVector(single)');
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    if Matrix.Rows = 1 then
      Result[I] := Matrix[0, I]
    else
      Result[I] := Matrix[I, 0];
end;

function ToVector(const Matrix: IDenseDoubleMatrix): TDoubleArray;
var
  I, Count: SizeInt;
begin
  Result := nil;
  Count := specialize MatrixVectorLength<Double>(Matrix, 'ToVector(double)');
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    if Matrix.Rows = 1 then
      Result[I] := Matrix[0, I]
    else
      Result[I] := Matrix[I, 0];
end;

function ToVector(const Matrix: IDenseSingleComplexMatrix):
  TSingleComplexArray;
var
  I, Count: SizeInt;
begin
  Result := nil;
  Count := specialize MatrixVectorLength<TSingleComplex>(Matrix,
    'ToVector(single complex)');
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    if Matrix.Rows = 1 then
      Result[I] := Matrix[0, I]
    else
      Result[I] := Matrix[I, 0];
end;

function ToVector(const Matrix: IDenseComplexMatrix): TComplexArray;
var
  I, Count: SizeInt;
begin
  Result := nil;
  Count := specialize MatrixVectorLength<TComplex>(Matrix, 'ToVector(complex)');
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    if Matrix.Rows = 1 then
      Result[I] := Matrix[0, I]
    else
      Result[I] := Matrix[I, 0];
end;

function ConvertToDouble(const Matrix: IDenseSingleMatrix):
  IDenseDoubleMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToDouble: source is nil.');
  Result := TDenseDoubleMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := Matrix[R, C];
end;

function ConvertToSingle(const Matrix: IDenseDoubleMatrix):
  IDenseSingleMatrix;
var
  R, C: SizeInt;
  Value: Double;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToSingle: source is nil.');
  Result := TDenseSingleMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
    begin
      Value := Matrix[R, C];
      if not IsNan(Value) and not IsInfinite(Value) and
         (Abs(Value) > MaxSingle) then
        raise EDenseMatrixError.CreateFmt(
          'ConvertToSingle: element [%d,%d] is outside the finite Single range.',
          [R, C]);
      Result[R, C] := Value;
    end;
end;

function ConvertToComplex(const Matrix: IDenseDoubleMatrix):
  IDenseComplexMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToComplex(double): source is nil.');
  Result := TDenseComplexMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := TComplex.Create(Matrix[R, C], 0.0);
end;

function ConvertToComplex(const Matrix: IDenseSingleMatrix):
  IDenseSingleComplexMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToComplex(single): source is nil.');
  Result := TDenseSingleComplexMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := TSingleComplex.Create(Matrix[R, C], 0.0);
end;

function ConvertToReal(const Matrix: IDenseComplexMatrix):
  IDenseDoubleMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToReal(double): source is nil.');
  Result := TDenseDoubleMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
    begin
      if Matrix[R, C].Im <> 0.0 then
        raise EDenseMatrixError.CreateFmt(
          'ConvertToReal(double): element [%d,%d] has a non-zero imaginary component.',
          [R, C]);
      Result[R, C] := Matrix[R, C].Re;
    end;
end;

function ConvertToReal(const Matrix: IDenseSingleComplexMatrix):
  IDenseSingleMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create('ConvertToReal(single): source is nil.');
  Result := TDenseSingleMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
    begin
      if Matrix[R, C].Im <> 0.0 then
        raise EDenseMatrixError.CreateFmt(
          'ConvertToReal(single): element [%d,%d] has a non-zero imaginary component.',
          [R, C]);
      Result[R, C] := Matrix[R, C].Re;
    end;
end;

function ConvertToDoubleComplex(const Matrix: IDenseSingleComplexMatrix):
  IDenseComplexMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create(
      'ConvertToDoubleComplex: source is nil.');
  Result := TDenseComplexMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
      Result[R, C] := ToComplex(Matrix[R, C]);
end;

function ConvertToSingleComplex(const Matrix: IDenseComplexMatrix):
  IDenseSingleComplexMatrix;
var
  R, C: SizeInt;
begin
  if Matrix = nil then
    raise EDenseMatrixError.Create(
      'ConvertToSingleComplex: source is nil.');
  Result := TDenseSingleComplexMatrix.Zeros(Matrix.Rows, Matrix.Cols);
  for R := 0 to Matrix.Rows - 1 do
    for C := 0 to Matrix.Cols - 1 do
    try
      Result[R, C] := ToSingleComplex(Matrix[R, C]);
    except
      on E: ERangeError do
        raise EDenseMatrixError.CreateFmt(
          'ConvertToSingleComplex: element [%d,%d] is outside the finite Single range.',
          [R, C]);
    end;
end;

end.
