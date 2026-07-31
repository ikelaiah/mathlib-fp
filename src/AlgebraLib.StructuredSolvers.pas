unit AlgebraLib.StructuredSolvers;

{-----------------------------------------------------------------------------
 AlgebraLib.StructuredSolvers

 Reusable direct factors for tridiagonal, band, and explicitly requested sparse
 systems. Tridiagonal factors use adjacent partial pivoting. General band
 factors use no pivoting and report that limitation. Sparse LU uses natural
 ordering with row partial pivoting and retains only actual factor fill.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators;

type
  EStructuredSolveError = class(Exception);
  ESparseDirectSolveError = class(Exception);

  TSparseOrdering = (soNatural);

  generic IStructuredDirectFactor<T> = interface
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetLowerBandwidth: SizeInt;
    function GetUpperBandwidth: SizeInt;
    function GetPivotingUsed: Boolean;
    function GetInterchangeCount: SizeInt;
    function GetMinimumPivotMagnitude: Double;
    procedure SolveInto(const RightHandSide,
      Destination: specialize IDenseMatrix<T>);
    property Size: SizeInt read GetSize;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property LowerBandwidth: SizeInt read GetLowerBandwidth;
    property UpperBandwidth: SizeInt read GetUpperBandwidth;
    property PivotingUsed: Boolean read GetPivotingUsed;
    property InterchangeCount: SizeInt read GetInterchangeCount;
    property MinimumPivotMagnitude: Double read GetMinimumPivotMagnitude;
  end;

  IStructuredSingleDirectFactor =
    specialize IStructuredDirectFactor<Single>;
  IStructuredDoubleDirectFactor =
    specialize IStructuredDirectFactor<Double>;
  IStructuredSingleComplexDirectFactor =
    specialize IStructuredDirectFactor<TSingleComplex>;
  IStructuredComplexDirectFactor =
    specialize IStructuredDirectFactor<TComplex>;

  generic ISparseLUFactor<T> = interface
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOrdering: TSparseOrdering;
    function GetOriginalNonZeroCount: SizeInt;
    function GetFactorNonZeroCount: SizeInt;
    function GetFillNonZeroCount: SizeInt;
    function GetInterchangeCount: SizeInt;
    function GetMinimumPivotMagnitude: Double;
    procedure SolveInto(const RightHandSide,
      Destination: specialize IDenseMatrix<T>);
    property Size: SizeInt read GetSize;
    property ScalarKind: TSparseScalarKind read GetScalarKind;
    property Ordering: TSparseOrdering read GetOrdering;
    property OriginalNonZeroCount: SizeInt read GetOriginalNonZeroCount;
    property FactorNonZeroCount: SizeInt read GetFactorNonZeroCount;
    property FillNonZeroCount: SizeInt read GetFillNonZeroCount;
    property InterchangeCount: SizeInt read GetInterchangeCount;
    property MinimumPivotMagnitude: Double read GetMinimumPivotMagnitude;
  end;

  ISparseSingleLUFactor = specialize ISparseLUFactor<Single>;
  ISparseDoubleLUFactor = specialize ISparseLUFactor<Double>;
  ISparseSingleComplexLUFactor =
    specialize ISparseLUFactor<TSingleComplex>;
  ISparseComplexLUFactor = specialize ISparseLUFactor<TComplex>;

  generic TSparseFactorRow<T> = record
    Columns: TSparseSizeIntArray;
    Values: specialize TSparseValueArray<T>;
    Count: SizeInt;
  end;

  generic TSparseFactorRows<T> = array of specialize TSparseFactorRow<T>;

  generic TTridiagonalFactor<T> = class(TInterfacedObject,
    specialize IStructuredDirectFactor<T>)
  private
    type
      TValueArray = specialize TSparseValueArray<T>;
  private
    FSize, FInterchanges: SizeInt;
    FLower, FDiagonal, FUpper, FSecondUpper: TValueArray;
    FPivots: TSparseSizeIntArray;
    FMinimumPivot: Double;
  public
    constructor Create(const Matrix: specialize IStructuredMatrix<T>;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetLowerBandwidth: SizeInt;
    function GetUpperBandwidth: SizeInt;
    function GetPivotingUsed: Boolean;
    function GetInterchangeCount: SizeInt;
    function GetMinimumPivotMagnitude: Double;
    procedure SolveInto(const RightHandSide,
      Destination: specialize IDenseMatrix<T>);
  end;

  generic TBandFactor<T> = class(TInterfacedObject,
    specialize IStructuredDirectFactor<T>)
  private
    type
      TValueArray = specialize TSparseValueArray<T>;
  private
    FSize, FLowerBandwidth, FUpperBandwidth: SizeInt;
    FValues: TValueArray;
    FMinimumPivot: Double;
    function Offset(const Row, Col: SizeInt): SizeInt;
    function GetStored(const Row, Col: SizeInt): T;
    procedure SetStored(const Row, Col: SizeInt; const Value: T);
  public
    constructor Create(const Matrix: specialize IStructuredMatrix<T>;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetLowerBandwidth: SizeInt;
    function GetUpperBandwidth: SizeInt;
    function GetPivotingUsed: Boolean;
    function GetInterchangeCount: SizeInt;
    function GetMinimumPivotMagnitude: Double;
    procedure SolveInto(const RightHandSide,
      Destination: specialize IDenseMatrix<T>);
  end;

  generic TSparseLUFactor<T> = class(TInterfacedObject,
    specialize ISparseLUFactor<T>)
  private
    type
      TValueArray = specialize TSparseValueArray<T>;
      TMatrix = specialize ISparseMatrix<T>;
      TFactorRow = specialize TSparseFactorRow<T>;
      TFactorRows = specialize TSparseFactorRows<T>;
  private
    FSize, FOriginalNonZeros, FFactorNonZeros, FInterchanges: SizeInt;
    FRows: TFactorRows;
    FPermutation: TSparseSizeIntArray;
    FMinimumPivot: Double;
    function FindPosition(const Row, Col: SizeInt;
      out InsertPosition: SizeInt): SizeInt;
    function GetValue(const Row, Col: SizeInt): T;
    procedure SetValue(const Row, Col: SizeInt; const Value: T);
  public
    constructor Create(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double);
    function GetSize: SizeInt;
    function GetScalarKind: TSparseScalarKind;
    function GetOrdering: TSparseOrdering;
    function GetOriginalNonZeroCount: SizeInt;
    function GetFactorNonZeroCount: SizeInt;
    function GetFillNonZeroCount: SizeInt;
    function GetInterchangeCount: SizeInt;
    function GetMinimumPivotMagnitude: Double;
    procedure SolveInto(const RightHandSide,
      Destination: specialize IDenseMatrix<T>);
  end;

  generic TStructuredSolverFactory<T> = class
  public
    class function FactorTridiagonal(
      const Matrix: specialize IStructuredMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize IStructuredDirectFactor<T>; static;
    class function FactorBand(const Matrix: specialize IStructuredMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize IStructuredDirectFactor<T>; static;
    class function FactorSparseLU(const Matrix: specialize ISparseMatrix<T>;
      const PivotTolerance: Double = 1.0e-14):
      specialize ISparseLUFactor<T>; static;
  end;

  TSingleStructuredSolver = specialize TStructuredSolverFactory<Single>;
  TDoubleStructuredSolver = specialize TStructuredSolverFactory<Double>;
  TSingleComplexStructuredSolver =
    specialize TStructuredSolverFactory<TSingleComplex>;
  TComplexStructuredSolver =
    specialize TStructuredSolverFactory<TComplex>;

implementation

constructor TTridiagonalFactor.Create(
  const Matrix: specialize IStructuredMatrix<T>;
  const PivotTolerance: Double);
var
  I: SizeInt;
  FactorValue, Temp: T;
  PivotMagnitude: Double;
begin
  inherited Create;
  if Matrix = nil then
    raise EStructuredSolveError.Create(
      'Tridiagonal factor: matrix must not be nil.');
  if (Matrix.Rows <> Matrix.Cols) or
     (Matrix.Kind <> smTridiagonal) then
    raise EStructuredSolveError.Create(
      'Tridiagonal factor: matrix must be square tridiagonal storage.');
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise EStructuredSolveError.Create(
      'Tridiagonal factor: pivot tolerance must be finite and non-negative.');
  FSize := Matrix.Rows;
  SetLength(FDiagonal, FSize);
  SetLength(FLower, Max(0, FSize - 1));
  SetLength(FUpper, Max(0, FSize - 1));
  SetLength(FSecondUpper, Max(0, FSize - 2));
  SetLength(FPivots, FSize);
  for I := 0 to FSize - 1 do
  begin
    FDiagonal[I] := Matrix[I, I];
    FPivots[I] := I;
    if I < FSize - 1 then
    begin
      FLower[I] := Matrix[I + 1, I];
      FUpper[I] := Matrix[I, I + 1];
    end;
  end;
  FMinimumPivot := Infinity;
  for I := 0 to FSize - 2 do
  begin
    if specialize TLinearScalar<T>.Magnitude(FDiagonal[I]) >=
       specialize TLinearScalar<T>.Magnitude(FLower[I]) then
    begin
      PivotMagnitude :=
        specialize TLinearScalar<T>.Magnitude(FDiagonal[I]);
      if PivotMagnitude <= PivotTolerance then
        raise EStructuredSolveError.CreateFmt(
          'Tridiagonal factor: zero pivot at row %d.', [I]);
      FactorValue := FLower[I] / FDiagonal[I];
      FLower[I] := FactorValue;
      FDiagonal[I + 1] := FDiagonal[I + 1] -
        FactorValue * FUpper[I];
    end
    else
    begin
      PivotMagnitude :=
        specialize TLinearScalar<T>.Magnitude(FLower[I]);
      if PivotMagnitude <= PivotTolerance then
        raise EStructuredSolveError.CreateFmt(
          'Tridiagonal factor: zero pivot at row %d.', [I]);
      FactorValue := FDiagonal[I] / FLower[I];
      FDiagonal[I] := FLower[I];
      FLower[I] := FactorValue;
      Temp := FUpper[I];
      FUpper[I] := FDiagonal[I + 1];
      FDiagonal[I + 1] := Temp - FactorValue * FDiagonal[I + 1];
      if I < FSize - 2 then
      begin
        FSecondUpper[I] := FUpper[I + 1];
        FUpper[I + 1] := -FactorValue * FUpper[I + 1];
      end;
      FPivots[I] := I + 1;
      Inc(FInterchanges);
    end;
    FMinimumPivot := Min(FMinimumPivot, PivotMagnitude);
  end;
  if FSize > 0 then
  begin
    PivotMagnitude :=
      specialize TLinearScalar<T>.Magnitude(FDiagonal[FSize - 1]);
    if PivotMagnitude <= PivotTolerance then
      raise EStructuredSolveError.CreateFmt(
        'Tridiagonal factor: zero pivot at row %d.', [FSize - 1]);
    FMinimumPivot := Min(FMinimumPivot, PivotMagnitude);
  end
  else
    FMinimumPivot := Infinity;
end;

function TTridiagonalFactor.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TTridiagonalFactor.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TTridiagonalFactor.GetLowerBandwidth: SizeInt;
begin
  Result := 1;
end;

function TTridiagonalFactor.GetUpperBandwidth: SizeInt;
begin
  Result := 1;
end;

function TTridiagonalFactor.GetPivotingUsed: Boolean;
begin
  Result := True;
end;

function TTridiagonalFactor.GetInterchangeCount: SizeInt;
begin
  Result := FInterchanges;
end;

function TTridiagonalFactor.GetMinimumPivotMagnitude: Double;
begin
  Result := FMinimumPivot;
end;

procedure TTridiagonalFactor.SolveInto(const RightHandSide,
  Destination: specialize IDenseMatrix<T>);
var
  Work: TValueArray;
  I, J: SizeInt;
  Temp: T;
begin
  if (RightHandSide = nil) or (Destination = nil) then
    raise EStructuredSolveError.Create(
      'Tridiagonal solve: matrices must not be nil.');
  if (RightHandSide.Rows <> FSize) or
     (Destination.Rows <> FSize) or
     (Destination.Cols <> RightHandSide.Cols) then
    raise EStructuredSolveError.Create(
      'Tridiagonal solve: right-hand side and destination shapes do not match.');
  if (RightHandSide.StorageIdentity <> nil) and
     (RightHandSide.StorageIdentity = Destination.StorageIdentity) and
     (RightHandSide <> Destination) then
    raise EStructuredSolveError.Create(
      'Tridiagonal solve: separate overlapping views are not supported.');
  SetLength(Work, FSize);
  for J := 0 to RightHandSide.Cols - 1 do
  begin
    for I := 0 to FSize - 1 do Work[I] := RightHandSide[I, J];
    for I := 0 to FSize - 2 do
      if FPivots[I] = I then
        Work[I + 1] := Work[I + 1] - FLower[I] * Work[I]
      else
      begin
        Temp := Work[I];
        Work[I] := Work[I + 1];
        Work[I + 1] := Temp - FLower[I] * Work[I + 1];
      end;
    if FSize > 0 then
      Work[FSize - 1] := Work[FSize - 1] / FDiagonal[FSize - 1];
    if FSize > 1 then
      Work[FSize - 2] := (Work[FSize - 2] -
        FUpper[FSize - 2] * Work[FSize - 1]) / FDiagonal[FSize - 2];
    for I := FSize - 3 downto 0 do
      Work[I] := (Work[I] - FUpper[I] * Work[I + 1] -
        FSecondUpper[I] * Work[I + 2]) / FDiagonal[I];
    for I := 0 to FSize - 1 do Destination[I, J] := Work[I];
  end;
end;

function TBandFactor.Offset(const Row, Col: SizeInt): SizeInt;
begin
  Result := Row * (FLowerBandwidth + FUpperBandwidth + 1) +
    Col - Row + FLowerBandwidth;
end;

function TBandFactor.GetStored(const Row, Col: SizeInt): T;
begin
  if (Row < 0) or (Row >= FSize) or (Col < 0) or (Col >= FSize) or
     (Col < Row - FLowerBandwidth) or
     (Col > Row + FUpperBandwidth) then
    Exit(specialize TLinearScalar<T>.Zero);
  Result := FValues[Offset(Row, Col)];
end;

procedure TBandFactor.SetStored(
  const Row, Col: SizeInt; const Value: T);
begin
  if (Col < Row - FLowerBandwidth) or
     (Col > Row + FUpperBandwidth) then
  begin
    if specialize TLinearScalar<T>.Magnitude(Value) <> 0.0 then
      raise EStructuredSolveError.Create(
        'Band factor: elimination produced fill outside declared storage.');
    Exit;
  end;
  FValues[Offset(Row, Col)] := Value;
end;

constructor TBandFactor.Create(
  const Matrix: specialize IStructuredMatrix<T>;
  const PivotTolerance: Double);
var
  I, J, K, FirstRow, LastRow, LastCol, Width: SizeInt;
  Pivot, Multiplier: T;
  PivotMagnitude: Double;
begin
  inherited Create;
  if Matrix = nil then
    raise EStructuredSolveError.Create('Band factor: matrix must not be nil.');
  if Matrix.Rows <> Matrix.Cols then
    raise EStructuredSolveError.Create('Band factor: matrix must be square.');
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise EStructuredSolveError.Create(
      'Band factor: pivot tolerance must be finite and non-negative.');
  FSize := Matrix.Rows;
  FLowerBandwidth := Matrix.LowerBandwidth;
  FUpperBandwidth := Matrix.UpperBandwidth;
  Width := FLowerBandwidth + FUpperBandwidth + 1;
  SetLength(FValues, FSize * Width);
  for I := 0 to FSize - 1 do
  begin
    FirstRow := Max(0, I - FLowerBandwidth);
    LastRow := Min(FSize - 1, I + FUpperBandwidth);
    for J := FirstRow to LastRow do SetStored(I, J, Matrix[I, J]);
  end;
  FMinimumPivot := Infinity;
  for K := 0 to FSize - 1 do
  begin
    Pivot := GetStored(K, K);
    PivotMagnitude := specialize TLinearScalar<T>.Magnitude(Pivot);
    if PivotMagnitude <= PivotTolerance then
      raise EStructuredSolveError.CreateFmt(
        'Band factor: zero pivot at row %d; this factor does not pivot.', [K]);
    FMinimumPivot := Min(FMinimumPivot, PivotMagnitude);
    LastRow := Min(FSize - 1, K + FLowerBandwidth);
    LastCol := Min(FSize - 1, K + FUpperBandwidth);
    for I := K + 1 to LastRow do
    begin
      Multiplier := GetStored(I, K) / Pivot;
      SetStored(I, K, Multiplier);
      for J := K + 1 to LastCol do
        if J >= I - FLowerBandwidth then
          SetStored(I, J, GetStored(I, J) -
            Multiplier * GetStored(K, J));
    end;
  end;
end;

function TBandFactor.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TBandFactor.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TBandFactor.GetLowerBandwidth: SizeInt;
begin
  Result := FLowerBandwidth;
end;

function TBandFactor.GetUpperBandwidth: SizeInt;
begin
  Result := FUpperBandwidth;
end;

function TBandFactor.GetPivotingUsed: Boolean;
begin
  Result := False;
end;

function TBandFactor.GetInterchangeCount: SizeInt;
begin
  Result := 0;
end;

function TBandFactor.GetMinimumPivotMagnitude: Double;
begin
  Result := FMinimumPivot;
end;

procedure TBandFactor.SolveInto(const RightHandSide,
  Destination: specialize IDenseMatrix<T>);
var
  Work: TValueArray;
  I, J, K, First, Last: SizeInt;
begin
  if (RightHandSide = nil) or (Destination = nil) then
    raise EStructuredSolveError.Create(
      'Band solve: matrices must not be nil.');
  if (RightHandSide.Rows <> FSize) or
     (Destination.Rows <> FSize) or
     (Destination.Cols <> RightHandSide.Cols) then
    raise EStructuredSolveError.Create(
      'Band solve: right-hand side and destination shapes do not match.');
  if (RightHandSide.StorageIdentity <> nil) and
     (RightHandSide.StorageIdentity = Destination.StorageIdentity) and
     (RightHandSide <> Destination) then
    raise EStructuredSolveError.Create(
      'Band solve: separate overlapping views are not supported.');
  SetLength(Work, FSize);
  for J := 0 to RightHandSide.Cols - 1 do
  begin
    for I := 0 to FSize - 1 do Work[I] := RightHandSide[I, J];
    for I := 0 to FSize - 1 do
    begin
      First := Max(0, I - FLowerBandwidth);
      for K := First to I - 1 do
        Work[I] := Work[I] - GetStored(I, K) * Work[K];
    end;
    for I := FSize - 1 downto 0 do
    begin
      Last := Min(FSize - 1, I + FUpperBandwidth);
      for K := I + 1 to Last do
        Work[I] := Work[I] - GetStored(I, K) * Work[K];
      Work[I] := Work[I] / GetStored(I, I);
    end;
    for I := 0 to FSize - 1 do Destination[I, J] := Work[I];
  end;
end;

function TSparseLUFactor.FindPosition(const Row, Col: SizeInt;
  out InsertPosition: SizeInt): SizeInt;
var
  L, H, M: SizeInt;
begin
  L := 0;
  H := FRows[Row].Count - 1;
  while L <= H do
  begin
    M := L + (H - L) div 2;
    if FRows[Row].Columns[M] = Col then
    begin
      InsertPosition := M;
      Exit(M);
    end;
    if FRows[Row].Columns[M] < Col then L := M + 1
    else H := M - 1;
  end;
  InsertPosition := L;
  Result := -1;
end;

function TSparseLUFactor.GetValue(const Row, Col: SizeInt): T;
var
  Position, InsertPosition: SizeInt;
begin
  Position := FindPosition(Row, Col, InsertPosition);
  if Position < 0 then Result := specialize TLinearScalar<T>.Zero
  else Result := FRows[Row].Values[Position];
end;

procedure TSparseLUFactor.SetValue(
  const Row, Col: SizeInt; const Value: T);
var
  Position, InsertPosition, I, NewCapacity: SizeInt;
begin
  Position := FindPosition(Row, Col, InsertPosition);
  if Position >= 0 then
  begin
    if specialize TLinearScalar<T>.Magnitude(Value) = 0.0 then
    begin
      for I := Position to FRows[Row].Count - 2 do
      begin
        FRows[Row].Columns[I] := FRows[Row].Columns[I + 1];
        FRows[Row].Values[I] := FRows[Row].Values[I + 1];
      end;
      Dec(FRows[Row].Count);
    end
    else
      FRows[Row].Values[Position] := Value;
    Exit;
  end;
  if specialize TLinearScalar<T>.Magnitude(Value) = 0.0 then Exit;
  if FRows[Row].Count = Length(FRows[Row].Columns) then
  begin
    NewCapacity := Max(8, FRows[Row].Count * 2);
    SetLength(FRows[Row].Columns, NewCapacity);
    SetLength(FRows[Row].Values, NewCapacity);
  end;
  for I := FRows[Row].Count downto InsertPosition + 1 do
  begin
    FRows[Row].Columns[I] := FRows[Row].Columns[I - 1];
    FRows[Row].Values[I] := FRows[Row].Values[I - 1];
  end;
  FRows[Row].Columns[InsertPosition] := Col;
  FRows[Row].Values[InsertPosition] := Value;
  Inc(FRows[Row].Count);
end;

constructor TSparseLUFactor.Create(
  const Matrix: specialize ISparseMatrix<T>;
  const PivotTolerance: Double);
var
  CSR: TMatrix;
  I, J, K, P, PivotRow, Position: SizeInt;
  PivotMagnitude, CandidateMagnitude: Double;
  Pivot, Multiplier, NewValue: T;
  TempRow: TFactorRow;
  TempPermutation: SizeInt;
begin
  inherited Create;
  if Matrix = nil then
    raise ESparseDirectSolveError.Create(
      'Sparse LU: matrix must not be nil.');
  if Matrix.Rows <> Matrix.Cols then
    raise ESparseDirectSolveError.Create(
      'Sparse LU: matrix must be square.');
  if IsNan(PivotTolerance) or IsInfinite(PivotTolerance) or
     (PivotTolerance < 0.0) then
    raise ESparseDirectSolveError.Create(
      'Sparse LU: pivot tolerance must be finite and non-negative.');
  if Matrix.Format = sfCSR then CSR := Matrix
  else CSR := specialize TSparseMatrixFactory<T>.Convert(Matrix, sfCSR);
  FSize := CSR.Rows;
  FOriginalNonZeros := CSR.NonZeroCount;
  SetLength(FRows, FSize);
  SetLength(FPermutation, FSize);
  for I := 0 to FSize - 1 do
  begin
    FPermutation[I] := I;
    FRows[I].Count := CSR.GetOuterPointer(I + 1) -
      CSR.GetOuterPointer(I);
    SetLength(FRows[I].Columns, FRows[I].Count);
    SetLength(FRows[I].Values, FRows[I].Count);
    Position := 0;
    for P := CSR.GetOuterPointer(I) to CSR.GetOuterPointer(I + 1) - 1 do
    begin
      FRows[I].Columns[Position] := CSR.GetInnerIndex(P);
      FRows[I].Values[Position] := CSR.GetStoredValue(P);
      Inc(Position);
    end;
  end;
  FMinimumPivot := Infinity;
  for K := 0 to FSize - 1 do
  begin
    PivotRow := K;
    PivotMagnitude := specialize TLinearScalar<T>.Magnitude(GetValue(K, K));
    for I := K + 1 to FSize - 1 do
    begin
      CandidateMagnitude :=
        specialize TLinearScalar<T>.Magnitude(GetValue(I, K));
      if CandidateMagnitude > PivotMagnitude then
      begin
        PivotMagnitude := CandidateMagnitude;
        PivotRow := I;
      end;
    end;
    if PivotMagnitude <= PivotTolerance then
      raise ESparseDirectSolveError.CreateFmt(
        'Sparse LU: singular pivot column %d.', [K]);
    if PivotRow <> K then
    begin
      TempRow := FRows[K];
      FRows[K] := FRows[PivotRow];
      FRows[PivotRow] := TempRow;
      TempPermutation := FPermutation[K];
      FPermutation[K] := FPermutation[PivotRow];
      FPermutation[PivotRow] := TempPermutation;
      Inc(FInterchanges);
    end;
    Pivot := GetValue(K, K);
    FMinimumPivot := Min(FMinimumPivot,
      specialize TLinearScalar<T>.Magnitude(Pivot));
    for I := K + 1 to FSize - 1 do
    begin
      Multiplier := GetValue(I, K);
      if specialize TLinearScalar<T>.Magnitude(Multiplier) = 0.0 then
        Continue;
      Multiplier := Multiplier / Pivot;
      SetValue(I, K, Multiplier);
      for P := 0 to FRows[K].Count - 1 do
      begin
        J := FRows[K].Columns[P];
        if J <= K then Continue;
        NewValue := GetValue(I, J) -
          Multiplier * FRows[K].Values[P];
        SetValue(I, J, NewValue);
      end;
    end;
  end;
  FFactorNonZeros := 0;
  for I := 0 to FSize - 1 do Inc(FFactorNonZeros, FRows[I].Count);
end;

function TSparseLUFactor.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TSparseLUFactor.GetScalarKind: TSparseScalarKind;
begin
  Result := specialize TLinearScalar<T>.Kind;
end;

function TSparseLUFactor.GetOrdering: TSparseOrdering;
begin
  Result := soNatural;
end;

function TSparseLUFactor.GetOriginalNonZeroCount: SizeInt;
begin
  Result := FOriginalNonZeros;
end;

function TSparseLUFactor.GetFactorNonZeroCount: SizeInt;
begin
  Result := FFactorNonZeros;
end;

function TSparseLUFactor.GetFillNonZeroCount: SizeInt;
begin
  Result := Max(0, FFactorNonZeros - FOriginalNonZeros);
end;

function TSparseLUFactor.GetInterchangeCount: SizeInt;
begin
  Result := FInterchanges;
end;

function TSparseLUFactor.GetMinimumPivotMagnitude: Double;
begin
  Result := FMinimumPivot;
end;

procedure TSparseLUFactor.SolveInto(const RightHandSide,
  Destination: specialize IDenseMatrix<T>);
var
  Work: TValueArray;
  I, J, P, Col: SizeInt;
begin
  if (RightHandSide = nil) or (Destination = nil) then
    raise ESparseDirectSolveError.Create(
      'Sparse LU solve: matrices must not be nil.');
  if (RightHandSide.Rows <> FSize) or
     (Destination.Rows <> FSize) or
     (Destination.Cols <> RightHandSide.Cols) then
    raise ESparseDirectSolveError.Create(
      'Sparse LU solve: right-hand side and destination shapes do not match.');
  if (RightHandSide.StorageIdentity <> nil) and
     (RightHandSide.StorageIdentity = Destination.StorageIdentity) and
     (RightHandSide <> Destination) then
    raise ESparseDirectSolveError.Create(
      'Sparse LU solve: separate overlapping views are not supported.');
  SetLength(Work, FSize);
  for J := 0 to RightHandSide.Cols - 1 do
  begin
    for I := 0 to FSize - 1 do
      Work[I] := RightHandSide[FPermutation[I], J];
    for I := 0 to FSize - 1 do
      for P := 0 to FRows[I].Count - 1 do
      begin
        Col := FRows[I].Columns[P];
        if Col >= I then Break;
        Work[I] := Work[I] - FRows[I].Values[P] * Work[Col];
      end;
    for I := FSize - 1 downto 0 do
    begin
      for P := FRows[I].Count - 1 downto 0 do
      begin
        Col := FRows[I].Columns[P];
        if Col <= I then Break;
        Work[I] := Work[I] - FRows[I].Values[P] * Work[Col];
      end;
      Work[I] := Work[I] / GetValue(I, I);
    end;
    for I := 0 to FSize - 1 do Destination[I, J] := Work[I];
  end;
end;

class function TStructuredSolverFactory.FactorTridiagonal(
  const Matrix: specialize IStructuredMatrix<T>;
  const PivotTolerance: Double): specialize IStructuredDirectFactor<T>;
begin
  Result := specialize TTridiagonalFactor<T>.Create(
    Matrix, PivotTolerance);
end;

class function TStructuredSolverFactory.FactorBand(
  const Matrix: specialize IStructuredMatrix<T>;
  const PivotTolerance: Double): specialize IStructuredDirectFactor<T>;
begin
  Result := specialize TBandFactor<T>.Create(Matrix, PivotTolerance);
end;

class function TStructuredSolverFactory.FactorSparseLU(
  const Matrix: specialize ISparseMatrix<T>;
  const PivotTolerance: Double): specialize ISparseLUFactor<T>;
begin
  Result := specialize TSparseLUFactor<T>.Create(Matrix, PivotTolerance);
end;

end.
