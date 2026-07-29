unit MLLib.Analysis;

{-----------------------------------------------------------------------------
 MLLib.Analysis

 Reproducible data-analysis workflows built directly on typed dense matrices.
 Rows are observations and columns are features.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Random,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseSolvers,
  AlgebraLib.DenseDecompositions;

type
  EAnalysisError = class(Exception);

  TPCAResult = record
    Mean: TDoubleArray;
    Components: IDenseDoubleMatrix;
    Scores: IDenseDoubleMatrix;
    SingularValues: TDoubleArray;
    ExplainedVariance: TDoubleArray;
    ExplainedRatio: TDoubleArray;
  end;

  TKMeansPlusPlusResult = record
    Labels: TIntegerArray;
    Centroids: IDenseDoubleMatrix;
    Inertia: Double;
    Iterations: SizeInt;
    Converged: Boolean;
  end;

  TValidationSplit = record
    TrainingRows: TIntegerArray;
    ValidationRows: TIntegerArray;
  end;

  TBinaryLDAResult = record
    Direction: TDoubleArray;
    Threshold: Double;
    NegativeClass: Integer;
    PositiveClass: Integer;
  end;

  TNeighborResult = record
    Indices: TIntegerArray;
    SquaredDistances: TDoubleArray;
  end;

  TAnalysisKit = class
  public
    class function PCA(const Data: IDenseDoubleMatrix;
      const ComponentCount: SizeInt): TPCAResult; static;
    class function KMeansPlusPlus(const Data: IDenseDoubleMatrix;
      const ClusterCount: SizeInt; const Seed: QWord = 42;
      const MaximumIterations: SizeInt = 300;
      const Tolerance: Double = 1E-8): TKMeansPlusPlusResult; static;
    class function CreateValidationSplit(const SampleCount: SizeInt;
      const ValidationFraction: Double; const Seed: QWord = 42):
      TValidationSplit; static;
    class function KFoldAssignments(const SampleCount, FoldCount: SizeInt;
      const Seed: QWord = 42): TIntegerArray; static;
    class function FitBinaryLDA(const Data: IDenseDoubleMatrix;
      const Labels: TIntegerArray; const NegativeClass, PositiveClass: Integer;
      const Ridge: Double = 1E-9): TBinaryLDAResult; static;
    class function PredictBinaryLDA(const Model: TBinaryLDAResult;
      const Data: IDenseDoubleMatrix): TIntegerArray; static;
  end;

  TKDTree = class
  private type
    TKDNode = record
      PointIndex: SizeInt;
      Axis: SizeInt;
      LeftNode: SizeInt;
      RightNode: SizeInt;
    end;
    TKDNodeArray = array of TKDNode;
  private
    FData: IDenseDoubleMatrix;
    FNodes: TKDNodeArray;
    FRoot: SizeInt;
    FNextNode: SizeInt;
    procedure SortIndices(var Indices: TIntegerArray; const LeftIndex,
      RightIndex, Axis: SizeInt);
    function Build(var Indices: TIntegerArray; const LeftIndex,
      RightIndex, Depth: SizeInt): SizeInt;
    procedure InsertCandidate(const Point: TDoubleArray;
      const PointIndex, NeighborCount: SizeInt;
      var ResultValue: TNeighborResult);
    procedure QueryNode(const NodeIndex: SizeInt; const Point: TDoubleArray;
      const NeighborCount: SizeInt; var ResultValue: TNeighborResult);
  public
    constructor Create(const Data: IDenseDoubleMatrix);
    function Query(const Point: TDoubleArray;
      const NeighborCount: SizeInt = 1): TNeighborResult;
    function Count: SizeInt;
    function Dimensions: SizeInt;
  end;

implementation

procedure AddSquaredDifference(var Accumulator: Double;
  const LeftValue, RightValue: Double; const Operation: string);
var
  Difference, Term: Double;
begin
  if LeftValue > 0.0 then
  begin
    if RightValue < 0.0 then
      if LeftValue > MaxDouble + RightValue then
        raise EAnalysisError.Create(Operation +
          ': coordinate difference overflow.');
  end
  else if LeftValue < 0.0 then
  begin
    if RightValue > 0.0 then
      if LeftValue < -MaxDouble + RightValue then
        raise EAnalysisError.Create(Operation +
          ': coordinate difference overflow.');
  end;
  Difference := LeftValue - RightValue;
  if Abs(Difference) > Sqrt(MaxDouble) then
    raise EAnalysisError.Create(Operation +
      ': squared-distance accumulation overflow.');
  Term := Difference * Difference;
  if IsNan(Term) or IsInfinite(Term) or
    (Accumulator > MaxDouble - Term) then
    raise EAnalysisError.Create(Operation +
      ': squared-distance accumulation overflow.');
  Accumulator := Accumulator + Term;
end;

procedure ValidateData(const Data: IDenseDoubleMatrix;
  const Operation: string; const RequireTwoRows: Boolean = False);
var
  RowIndex, ColumnIndex: SizeInt;
begin
  if Data = nil then
    raise EAnalysisError.Create(Operation +
      ': Data matrix handle must not be nil.');
  if (Data.Rows = 0) or (Data.Cols = 0) then
    raise EAnalysisError.Create(Operation +
      ': Data must contain at least one row and one feature.');
  if RequireTwoRows and (Data.Rows < 2) then
    raise EAnalysisError.Create(Operation +
      ': at least two observation rows are required.');
  for RowIndex := 0 to Data.Rows - 1 do
    for ColumnIndex := 0 to Data.Cols - 1 do
      if IsNan(Data[RowIndex, ColumnIndex]) or
         IsInfinite(Data[RowIndex, ColumnIndex]) then
        raise EAnalysisError.CreateFmt(
          '%s: feature [%d,%d] must be finite.',
          [Operation, RowIndex, ColumnIndex]);
end;

function SquaredDistance(const Data: IDenseDoubleMatrix;
  const RowIndex: SizeInt; const Centroids: IDenseDoubleMatrix;
  const CentroidIndex: SizeInt): Double;
var
  ColumnIndex: SizeInt;
begin
  Result := 0.0;
  for ColumnIndex := 0 to Data.Cols - 1 do
    AddSquaredDifference(Result, Data[RowIndex, ColumnIndex],
      Centroids[CentroidIndex, ColumnIndex], 'KMeansPlusPlus');
end;

class function TAnalysisKit.PCA(const Data: IDenseDoubleMatrix;
  const ComponentCount: SizeInt): TPCAResult;
var
  Centered: IDenseDoubleMatrix;
  Factor: IDenseDoubleSVD;
  AllSingularValues: TDoubleArray;
  RowIndex, ColumnIndex, ComponentIndex, Available: SizeInt;
  TotalVariance, ScoreValue: Double;
begin
  Result.Mean := nil;
  Result.Components := nil;
  Result.Scores := nil;
  Result.SingularValues := nil;
  Result.ExplainedVariance := nil;
  Result.ExplainedRatio := nil;
  ValidateData(Data, 'PCA', True);
  Available := Min(Data.Rows, Data.Cols);
  if (ComponentCount <= 0) or (ComponentCount > Available) then
    raise EAnalysisError.CreateFmt(
      'PCA: ComponentCount must be in [1,%d]; got %d.',
      [Available, ComponentCount]);

  SetLength(Result.Mean, Data.Cols);
  for ColumnIndex := 0 to Data.Cols - 1 do
  begin
    for RowIndex := 0 to Data.Rows - 1 do
      Result.Mean[ColumnIndex] := Result.Mean[ColumnIndex] +
        Data[RowIndex, ColumnIndex];
    Result.Mean[ColumnIndex] := Result.Mean[ColumnIndex] / Double(Data.Rows);
  end;
  Centered := TDenseDoubleMatrix.Zeros(Data.Rows, Data.Cols);
  for RowIndex := 0 to Data.Rows - 1 do
    for ColumnIndex := 0 to Data.Cols - 1 do
      Centered[RowIndex, ColumnIndex] := Data[RowIndex, ColumnIndex] -
        Result.Mean[ColumnIndex];

  Factor := FactorSVD(Centered);
  AllSingularValues := Factor.SingularValues;
  TotalVariance := 0.0;
  for ComponentIndex := 0 to High(AllSingularValues) do
    TotalVariance := TotalVariance +
      Sqr(AllSingularValues[ComponentIndex]) / Double(Data.Rows - 1);
  if TotalVariance = 0.0 then
    raise EAnalysisError.Create(
      'PCA: centered data has zero total variance.');

  Result.Components := TDenseDoubleMatrix.Zeros(ComponentCount, Data.Cols);
  Result.Scores := TDenseDoubleMatrix.Zeros(Data.Rows, ComponentCount);
  SetLength(Result.SingularValues, ComponentCount);
  SetLength(Result.ExplainedVariance, ComponentCount);
  SetLength(Result.ExplainedRatio, ComponentCount);
  for ComponentIndex := 0 to ComponentCount - 1 do
  begin
    Result.SingularValues[ComponentIndex] :=
      AllSingularValues[ComponentIndex];
    Result.ExplainedVariance[ComponentIndex] :=
      Sqr(AllSingularValues[ComponentIndex]) / Double(Data.Rows - 1);
    Result.ExplainedRatio[ComponentIndex] :=
      Result.ExplainedVariance[ComponentIndex] / TotalVariance;
    for ColumnIndex := 0 to Data.Cols - 1 do
      Result.Components[ComponentIndex, ColumnIndex] :=
        Factor.V[ColumnIndex, ComponentIndex];
    for RowIndex := 0 to Data.Rows - 1 do
    begin
      ScoreValue := 0.0;
      for ColumnIndex := 0 to Data.Cols - 1 do
        ScoreValue := ScoreValue + Centered[RowIndex, ColumnIndex] *
          Result.Components[ComponentIndex, ColumnIndex];
      Result.Scores[RowIndex, ComponentIndex] := ScoreValue;
    end;
  end;
end;

class function TAnalysisKit.KMeansPlusPlus(const Data: IDenseDoubleMatrix;
  const ClusterCount: SizeInt; const Seed: QWord;
  const MaximumIterations: SizeInt; const Tolerance: Double):
  TKMeansPlusPlusResult;
var
  Generator: TLocalRandom;
  MinimumDistances, NewMinimumDistances: TDoubleArray;
  Counts: TIntegerArray;
  NewCentroids: IDenseDoubleMatrix;
  RowIndex, ColumnIndex, ClusterIndex, ChosenIndex, Iteration,
    BestCluster, FarthestRow: SizeInt;
  Distance, BestDistance, SumDistance, Draw, Running, Shift, MaxShift,
    FarthestDistance: Double;
  LabelsChanged: Boolean;
begin
  Result.Labels := nil;
  Result.Centroids := nil;
  Result.Inertia := 0.0;
  Result.Iterations := 0;
  Result.Converged := False;
  ValidateData(Data, 'KMeansPlusPlus');
  if (ClusterCount <= 0) or (ClusterCount > Data.Rows) then
    raise EAnalysisError.CreateFmt(
      'KMeansPlusPlus: ClusterCount must be in [1,%d]; got %d.',
      [Data.Rows, ClusterCount]);
  if MaximumIterations <= 0 then
    raise EAnalysisError.Create(
      'KMeansPlusPlus: MaximumIterations must be positive.');
  if IsNan(Tolerance) or IsInfinite(Tolerance) or (Tolerance < 0.0) then
    raise EAnalysisError.Create(
      'KMeansPlusPlus: Tolerance must be finite and non-negative.');

  Generator := TLocalRandom.Seeded(Seed);
  Result.Centroids := TDenseDoubleMatrix.Zeros(ClusterCount, Data.Cols);
  SetLength(Result.Labels, Data.Rows);
  SetLength(MinimumDistances, Data.Rows);
  ChosenIndex := Generator.NextInteger(Data.Rows);
  for ColumnIndex := 0 to Data.Cols - 1 do
    Result.Centroids[0, ColumnIndex] := Data[ChosenIndex, ColumnIndex];
  for RowIndex := 0 to Data.Rows - 1 do
    MinimumDistances[RowIndex] := SquaredDistance(
      Data, RowIndex, Result.Centroids, 0);

  for ClusterIndex := 1 to ClusterCount - 1 do
  begin
    SumDistance := 0.0;
    for RowIndex := 0 to Data.Rows - 1 do
    begin
      if SumDistance > MaxDouble - MinimumDistances[RowIndex] then
        raise EAnalysisError.Create(
          'KMeansPlusPlus: initialization distance sum overflow.');
      SumDistance := SumDistance + MinimumDistances[RowIndex];
    end;
    if SumDistance = 0.0 then
    begin
      ChosenIndex := 0;
      while ChosenIndex < ClusterIndex do Inc(ChosenIndex);
      if ChosenIndex >= Data.Rows then ChosenIndex := ClusterIndex mod Data.Rows;
    end
    else
    begin
      Draw := Generator.NextDouble * SumDistance;
      Running := 0.0;
      ChosenIndex := Data.Rows - 1;
      for RowIndex := 0 to Data.Rows - 1 do
      begin
        Running := Running + MinimumDistances[RowIndex];
        if Running >= Draw then
        begin
          ChosenIndex := RowIndex;
          Break;
        end;
      end;
    end;
    for ColumnIndex := 0 to Data.Cols - 1 do
      Result.Centroids[ClusterIndex, ColumnIndex] :=
        Data[ChosenIndex, ColumnIndex];
    NewMinimumDistances := Copy(MinimumDistances);
    for RowIndex := 0 to Data.Rows - 1 do
    begin
      Distance := SquaredDistance(Data, RowIndex, Result.Centroids,
        ClusterIndex);
      if Distance < NewMinimumDistances[RowIndex] then
        NewMinimumDistances[RowIndex] := Distance;
    end;
    MinimumDistances := NewMinimumDistances;
  end;

  for RowIndex := 0 to Data.Rows - 1 do Result.Labels[RowIndex] := -1;
  for Iteration := 1 to MaximumIterations do
  begin
    LabelsChanged := False;
    for RowIndex := 0 to Data.Rows - 1 do
    begin
      BestCluster := 0;
      BestDistance := SquaredDistance(Data, RowIndex, Result.Centroids, 0);
      for ClusterIndex := 1 to ClusterCount - 1 do
      begin
        Distance := SquaredDistance(Data, RowIndex, Result.Centroids,
          ClusterIndex);
        if (Distance < BestDistance) or
           ((Distance = BestDistance) and (ClusterIndex < BestCluster)) then
        begin
          BestDistance := Distance;
          BestCluster := ClusterIndex;
        end;
      end;
      if Result.Labels[RowIndex] <> BestCluster then
      begin
        Result.Labels[RowIndex] := BestCluster;
        LabelsChanged := True;
      end;
      MinimumDistances[RowIndex] := BestDistance;
    end;

    NewCentroids := TDenseDoubleMatrix.Zeros(ClusterCount, Data.Cols);
    Counts := nil;
    SetLength(Counts, ClusterCount);
    for RowIndex := 0 to Data.Rows - 1 do
    begin
      ClusterIndex := Result.Labels[RowIndex];
      Inc(Counts[ClusterIndex]);
      for ColumnIndex := 0 to Data.Cols - 1 do
        NewCentroids[ClusterIndex, ColumnIndex] :=
          NewCentroids[ClusterIndex, ColumnIndex] +
          Data[RowIndex, ColumnIndex];
    end;
    for ClusterIndex := 0 to ClusterCount - 1 do
      if Counts[ClusterIndex] > 0 then
        for ColumnIndex := 0 to Data.Cols - 1 do
          NewCentroids[ClusterIndex, ColumnIndex] :=
            NewCentroids[ClusterIndex, ColumnIndex] / Counts[ClusterIndex]
      else
      begin
        FarthestRow := 0;
        FarthestDistance := MinimumDistances[0];
        for RowIndex := 1 to Data.Rows - 1 do
          if MinimumDistances[RowIndex] > FarthestDistance then
          begin
            FarthestDistance := MinimumDistances[RowIndex];
            FarthestRow := RowIndex;
          end;
        for ColumnIndex := 0 to Data.Cols - 1 do
          NewCentroids[ClusterIndex, ColumnIndex] :=
            Data[FarthestRow, ColumnIndex];
      end;

    MaxShift := 0.0;
    for ClusterIndex := 0 to ClusterCount - 1 do
    begin
      Shift := 0.0;
      for ColumnIndex := 0 to Data.Cols - 1 do
        AddSquaredDifference(Shift,
          NewCentroids[ClusterIndex, ColumnIndex],
          Result.Centroids[ClusterIndex, ColumnIndex],
          'KMeansPlusPlus');
      if Shift > MaxShift then MaxShift := Shift;
    end;
    Result.Centroids := NewCentroids;
    Result.Iterations := Iteration;
    if (not LabelsChanged) or (MaxShift <= Sqr(Tolerance)) then
    begin
      Result.Converged := True;
      Break;
    end;
  end;

  Result.Inertia := 0.0;
  for RowIndex := 0 to Data.Rows - 1 do
    Result.Inertia := Result.Inertia + SquaredDistance(Data, RowIndex,
      Result.Centroids, Result.Labels[RowIndex]);
end;

procedure ShuffleIndices(var Indices: TIntegerArray;
  var Generator: TLocalRandom);
var
  I, J, Temporary: SizeInt;
begin
  for I := High(Indices) downto 1 do
  begin
    J := Generator.NextInteger(I + 1);
    Temporary := Indices[I];
    Indices[I] := Indices[J];
    Indices[J] := Temporary;
  end;
end;

class function TAnalysisKit.CreateValidationSplit(const SampleCount: SizeInt;
  const ValidationFraction: Double; const Seed: QWord): TValidationSplit;
var
  Indices: TIntegerArray;
  Generator: TLocalRandom;
  I, ValidationCount: SizeInt;
begin
  Result.TrainingRows := nil;
  Result.ValidationRows := nil;
  if SampleCount < 2 then
    raise EAnalysisError.Create(
      'CreateValidationSplit: SampleCount must be at least two.');
  if IsNan(ValidationFraction) or IsInfinite(ValidationFraction) or
     (ValidationFraction <= 0.0) or (ValidationFraction >= 1.0) then
    raise EAnalysisError.Create(
      'CreateValidationSplit: ValidationFraction must be finite and in (0,1).');
  ValidationCount := Round(SampleCount * ValidationFraction);
  ValidationCount := Max(1, Min(SampleCount - 1, ValidationCount));
  SetLength(Indices, SampleCount);
  for I := 0 to SampleCount - 1 do Indices[I] := I;
  Generator := TLocalRandom.Seeded(Seed);
  ShuffleIndices(Indices, Generator);
  SetLength(Result.ValidationRows, ValidationCount);
  SetLength(Result.TrainingRows, SampleCount - ValidationCount);
  for I := 0 to ValidationCount - 1 do
    Result.ValidationRows[I] := Indices[I];
  for I := ValidationCount to SampleCount - 1 do
    Result.TrainingRows[I - ValidationCount] := Indices[I];
end;

class function TAnalysisKit.KFoldAssignments(const SampleCount,
  FoldCount: SizeInt; const Seed: QWord): TIntegerArray;
var
  Indices: TIntegerArray;
  Generator: TLocalRandom;
  I: SizeInt;
begin
  Result := nil;
  if SampleCount <= 0 then
    raise EAnalysisError.Create(
      'KFoldAssignments: SampleCount must be positive.');
  if (FoldCount < 2) or (FoldCount > SampleCount) then
    raise EAnalysisError.CreateFmt(
      'KFoldAssignments: FoldCount must be in [2,%d].', [SampleCount]);
  SetLength(Indices, SampleCount);
  SetLength(Result, SampleCount);
  for I := 0 to SampleCount - 1 do Indices[I] := I;
  Generator := TLocalRandom.Seeded(Seed);
  ShuffleIndices(Indices, Generator);
  for I := 0 to SampleCount - 1 do
    Result[Indices[I]] := I mod FoldCount;
end;

class function TAnalysisKit.FitBinaryLDA(const Data: IDenseDoubleMatrix;
  const Labels: TIntegerArray; const NegativeClass, PositiveClass: Integer;
  const Ridge: Double): TBinaryLDAResult;
var
  MeanNegative, MeanPositive: TDoubleArray;
  Scatter, RightHandSide, Solution: IDenseDoubleMatrix;
  RowIndex, I, J, NegativeCount, PositiveCount: SizeInt;
  DifferenceI, DifferenceJ, NormValue, MidpointProjection: Double;
begin
  Result.Direction := nil;
  ValidateData(Data, 'FitBinaryLDA', True);
  NegativeCount := 0;
  PositiveCount := 0;
  if Length(Labels) <> Data.Rows then
    raise EAnalysisError.CreateFmt(
      'FitBinaryLDA: Labels length must equal row count %d; got %d.',
      [Data.Rows, Length(Labels)]);
  if NegativeClass = PositiveClass then
    raise EAnalysisError.Create(
      'FitBinaryLDA: class labels must be distinct.');
  if IsNan(Ridge) or IsInfinite(Ridge) or (Ridge < 0.0) then
    raise EAnalysisError.Create(
      'FitBinaryLDA: Ridge must be finite and non-negative.');
  SetLength(MeanNegative, Data.Cols);
  SetLength(MeanPositive, Data.Cols);
  for RowIndex := 0 to Data.Rows - 1 do
    if Labels[RowIndex] = NegativeClass then
    begin
      Inc(NegativeCount);
      for I := 0 to Data.Cols - 1 do
        MeanNegative[I] := MeanNegative[I] + Data[RowIndex, I];
    end
    else if Labels[RowIndex] = PositiveClass then
    begin
      Inc(PositiveCount);
      for I := 0 to Data.Cols - 1 do
        MeanPositive[I] := MeanPositive[I] + Data[RowIndex, I];
    end
    else
      raise EAnalysisError.CreateFmt(
        'FitBinaryLDA: label at row %d is neither requested class.', [RowIndex]);
  if (NegativeCount = 0) or (PositiveCount = 0) then
    raise EAnalysisError.Create(
      'FitBinaryLDA: both classes require at least one observation.');
  for I := 0 to Data.Cols - 1 do
  begin
    MeanNegative[I] := MeanNegative[I] / NegativeCount;
    MeanPositive[I] := MeanPositive[I] / PositiveCount;
  end;

  Scatter := TDenseDoubleMatrix.Zeros(Data.Cols, Data.Cols);
  for RowIndex := 0 to Data.Rows - 1 do
    for I := 0 to Data.Cols - 1 do
    begin
      if Labels[RowIndex] = NegativeClass then
        DifferenceI := Data[RowIndex, I] - MeanNegative[I]
      else
        DifferenceI := Data[RowIndex, I] - MeanPositive[I];
      for J := 0 to Data.Cols - 1 do
      begin
        if Labels[RowIndex] = NegativeClass then
          DifferenceJ := Data[RowIndex, J] - MeanNegative[J]
        else
          DifferenceJ := Data[RowIndex, J] - MeanPositive[J];
        Scatter[I, J] := Scatter[I, J] + DifferenceI * DifferenceJ;
      end;
    end;
  for I := 0 to Data.Cols - 1 do
    Scatter[I, I] := Scatter[I, I] + Ridge;
  RightHandSide := TDenseDoubleMatrix.Zeros(Data.Cols, 1);
  for I := 0 to Data.Cols - 1 do
    RightHandSide[I, 0] := MeanPositive[I] - MeanNegative[I];
  try
    Solution := Solve(Scatter, RightHandSide);
  except
    on E: EDenseMatrixError do
      raise EAnalysisError.Create('FitBinaryLDA: within-class scatter solve failed: ' +
        E.Message);
  end;
  SetLength(Result.Direction, Data.Cols);
  NormValue := 0.0;
  for I := 0 to Data.Cols - 1 do
    NormValue := NormValue + Sqr(Solution[I, 0]);
  NormValue := Sqrt(NormValue);
  if NormValue = 0.0 then
    raise EAnalysisError.Create(
      'FitBinaryLDA: class means do not define a discriminant direction.');
  MidpointProjection := 0.0;
  for I := 0 to Data.Cols - 1 do
  begin
    Result.Direction[I] := Solution[I, 0] / NormValue;
    MidpointProjection := MidpointProjection +
      0.5 * (MeanNegative[I] + MeanPositive[I]) * Result.Direction[I];
  end;
  Result.Threshold := MidpointProjection;
  Result.NegativeClass := NegativeClass;
  Result.PositiveClass := PositiveClass;
end;

class function TAnalysisKit.PredictBinaryLDA(const Model: TBinaryLDAResult;
  const Data: IDenseDoubleMatrix): TIntegerArray;
var
  RowIndex, ColumnIndex: SizeInt;
  Projection: Double;
begin
  Result := nil;
  ValidateData(Data, 'PredictBinaryLDA');
  if Length(Model.Direction) <> Data.Cols then
    raise EAnalysisError.CreateFmt(
      'PredictBinaryLDA: model has %d features but Data has %d.',
      [Length(Model.Direction), Data.Cols]);
  if IsNan(Model.Threshold) or IsInfinite(Model.Threshold) then
    raise EAnalysisError.Create(
      'PredictBinaryLDA: model threshold must be finite.');
  if Model.NegativeClass = Model.PositiveClass then
    raise EAnalysisError.Create(
      'PredictBinaryLDA: model class labels must be distinct.');
  for ColumnIndex := 0 to High(Model.Direction) do
    if IsNan(Model.Direction[ColumnIndex]) or
      IsInfinite(Model.Direction[ColumnIndex]) then
      raise EAnalysisError.CreateFmt(
        'PredictBinaryLDA: direction component %d must be finite.',
        [ColumnIndex]);
  SetLength(Result, Data.Rows);
  for RowIndex := 0 to Data.Rows - 1 do
  begin
    Projection := 0.0;
    for ColumnIndex := 0 to Data.Cols - 1 do
      Projection := Projection +
        Data[RowIndex, ColumnIndex] * Model.Direction[ColumnIndex];
    if Projection >= Model.Threshold then
      Result[RowIndex] := Model.PositiveClass
    else
      Result[RowIndex] := Model.NegativeClass;
  end;
end;

constructor TKDTree.Create(const Data: IDenseDoubleMatrix);
var
  Indices: TIntegerArray;
  I: SizeInt;
begin
  inherited Create;
  ValidateData(Data, 'TKDTree.Create');
  FData := Data.Clone;
  SetLength(FNodes, Data.Rows);
  SetLength(Indices, Data.Rows);
  for I := 0 to Data.Rows - 1 do Indices[I] := I;
  FNextNode := 0;
  FRoot := Build(Indices, 0, High(Indices), 0);
end;

procedure TKDTree.SortIndices(var Indices: TIntegerArray;
  const LeftIndex, RightIndex, Axis: SizeInt);
var
  I, J, PivotIndex, Temporary: SizeInt;
  PivotValue: Double;
begin
  I := LeftIndex;
  J := RightIndex;
  PivotIndex := Indices[(LeftIndex + RightIndex) div 2];
  PivotValue := FData[PivotIndex, Axis];
  repeat
    while (FData[Indices[I], Axis] < PivotValue) or
      ((FData[Indices[I], Axis] = PivotValue) and
       (Indices[I] < PivotIndex)) do Inc(I);
    while (FData[Indices[J], Axis] > PivotValue) or
      ((FData[Indices[J], Axis] = PivotValue) and
       (Indices[J] > PivotIndex)) do Dec(J);
    if I <= J then
    begin
      Temporary := Indices[I];
      Indices[I] := Indices[J];
      Indices[J] := Temporary;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if LeftIndex < J then SortIndices(Indices, LeftIndex, J, Axis);
  if I < RightIndex then SortIndices(Indices, I, RightIndex, Axis);
end;

function TKDTree.Build(var Indices: TIntegerArray; const LeftIndex,
  RightIndex, Depth: SizeInt): SizeInt;
var
  Middle, Axis, NodeIndex: SizeInt;
begin
  if LeftIndex > RightIndex then Exit(-1);
  Axis := Depth mod FData.Cols;
  SortIndices(Indices, LeftIndex, RightIndex, Axis);
  Middle := (LeftIndex + RightIndex) div 2;
  NodeIndex := FNextNode;
  Inc(FNextNode);
  FNodes[NodeIndex].PointIndex := Indices[Middle];
  FNodes[NodeIndex].Axis := Axis;
  FNodes[NodeIndex].LeftNode := Build(
    Indices, LeftIndex, Middle - 1, Depth + 1);
  FNodes[NodeIndex].RightNode := Build(
    Indices, Middle + 1, RightIndex, Depth + 1);
  Result := NodeIndex;
end;

procedure TKDTree.InsertCandidate(const Point: TDoubleArray;
  const PointIndex, NeighborCount: SizeInt;
  var ResultValue: TNeighborResult);
var
  ColumnIndex, InsertIndex, MoveIndex: SizeInt;
  Distance: Double;
begin
  Distance := 0.0;
  for ColumnIndex := 0 to FData.Cols - 1 do
    AddSquaredDifference(Distance, Point[ColumnIndex],
      FData[PointIndex, ColumnIndex], 'TKDTree.Query');
  InsertIndex := 0;
  while (InsertIndex < NeighborCount) and
    ((ResultValue.Indices[InsertIndex] >= 0) and
     ((ResultValue.SquaredDistances[InsertIndex] < Distance) or
      ((ResultValue.SquaredDistances[InsertIndex] = Distance) and
       (ResultValue.Indices[InsertIndex] < PointIndex)))) do
    Inc(InsertIndex);
  if InsertIndex >= NeighborCount then Exit;
  for MoveIndex := NeighborCount - 1 downto InsertIndex + 1 do
  begin
    ResultValue.Indices[MoveIndex] := ResultValue.Indices[MoveIndex - 1];
    ResultValue.SquaredDistances[MoveIndex] :=
      ResultValue.SquaredDistances[MoveIndex - 1];
  end;
  ResultValue.Indices[InsertIndex] := PointIndex;
  ResultValue.SquaredDistances[InsertIndex] := Distance;
end;

procedure TKDTree.QueryNode(const NodeIndex: SizeInt;
  const Point: TDoubleArray; const NeighborCount: SizeInt;
  var ResultValue: TNeighborResult);
var
  Axis, NearNode, FarNode: SizeInt;
  Difference, AxisDistance, WorstDistance: Double;
begin
  if NodeIndex < 0 then Exit;
  Axis := FNodes[NodeIndex].Axis;
  Difference := Point[Axis] -
    FData[FNodes[NodeIndex].PointIndex, Axis];
  if Difference <= 0.0 then
  begin
    NearNode := FNodes[NodeIndex].LeftNode;
    FarNode := FNodes[NodeIndex].RightNode;
  end
  else
  begin
    NearNode := FNodes[NodeIndex].RightNode;
    FarNode := FNodes[NodeIndex].LeftNode;
  end;
  QueryNode(NearNode, Point, NeighborCount, ResultValue);
  InsertCandidate(Point, FNodes[NodeIndex].PointIndex,
    NeighborCount, ResultValue);
  if ResultValue.Indices[NeighborCount - 1] < 0 then
    WorstDistance := Infinity
  else
    WorstDistance := ResultValue.SquaredDistances[NeighborCount - 1];
  AxisDistance := 0.0;
  AddSquaredDifference(AxisDistance, Point[Axis],
    FData[FNodes[NodeIndex].PointIndex, Axis], 'TKDTree.Query');
  if AxisDistance <= WorstDistance then
    QueryNode(FarNode, Point, NeighborCount, ResultValue);
end;

function TKDTree.Query(const Point: TDoubleArray;
  const NeighborCount: SizeInt): TNeighborResult;
var
  I: SizeInt;
begin
  Result.Indices := nil;
  Result.SquaredDistances := nil;
  if Length(Point) <> FData.Cols then
    raise EAnalysisError.CreateFmt(
      'TKDTree.Query: point has %d features; expected %d.',
      [Length(Point), FData.Cols]);
  for I := 0 to High(Point) do
    if IsNan(Point[I]) or IsInfinite(Point[I]) then
      raise EAnalysisError.CreateFmt(
        'TKDTree.Query: coordinate %d must be finite.', [I]);
  if (NeighborCount <= 0) or (NeighborCount > FData.Rows) then
    raise EAnalysisError.CreateFmt(
      'TKDTree.Query: NeighborCount must be in [1,%d].', [FData.Rows]);
  SetLength(Result.Indices, NeighborCount);
  SetLength(Result.SquaredDistances, NeighborCount);
  for I := 0 to NeighborCount - 1 do
  begin
    Result.Indices[I] := -1;
    Result.SquaredDistances[I] := Infinity;
  end;
  QueryNode(FRoot, Point, NeighborCount, Result);
end;

function TKDTree.Count: SizeInt;
begin
  Result := FData.Rows;
end;

function TKDTree.Dimensions: SizeInt;
begin
  Result := FData.Cols;
end;

end.
