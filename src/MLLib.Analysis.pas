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

  THierarchicalLinkage = (hlSingle, hlComplete, hlAverage);

  THierarchicalClustering = record
    SampleCount:Integer;
    MergeLeft:TIntegerArray;
    MergeRight:TIntegerArray;
    Distances:TDoubleArray;
    ClusterSizes:TIntegerArray;
  end;

  TStandardizationModel = record
    Means:TDoubleArray;
    Scales:TDoubleArray;
  end;

  TForestTask = (ftClassification, ftRegression);

  TDecisionTreeNode = record
    Feature:Integer;
    Threshold:Double;
    LeftNode:Integer;
    RightNode:Integer;
    Prediction:Double;
    IsLeaf:Boolean;
  end;
  TDecisionTreeNodes = array of TDecisionTreeNode;

  TDecisionTreeModel = record
    Nodes:TDecisionTreeNodes;
  end;
  TDecisionTrees = array of TDecisionTreeModel;

  TDecisionForest = record
    Trees:TDecisionTrees;
    Task:TForestTask;
    ClassCount:Integer;
    FeatureImportances:TDoubleArray;
    OOBScore:Double;
    Seed:QWord;
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
    class function HierarchicalCluster(const Data:IDenseDoubleMatrix;
      const Linkage:THierarchicalLinkage=hlAverage):
      THierarchicalClustering; static;
    class function CutHierarchy(const Model:THierarchicalClustering;
      const ClusterCount:Integer):TIntegerArray; static;
    class function FitStandardization(const TrainingData:IDenseDoubleMatrix):
      TStandardizationModel; static;
    class function TransformStandardized(const Model:TStandardizationModel;
      const Data:IDenseDoubleMatrix):IDenseDoubleMatrix; static;
    class function FitClassificationForest(const Data:IDenseDoubleMatrix;
      const Labels:TIntegerArray; const TreeCount:Integer=32;
      const MaximumDepth:Integer=8; const MinimumLeafSize:Integer=2;
      const Seed:QWord=42):TDecisionForest; static;
    class function FitRegressionForest(const Data:IDenseDoubleMatrix;
      const Targets:TDoubleArray; const TreeCount:Integer=32;
      const MaximumDepth:Integer=8; const MinimumLeafSize:Integer=2;
      const Seed:QWord=42):TDecisionForest; static;
    class function PredictForestClasses(const Model:TDecisionForest;
      const Data:IDenseDoubleMatrix):TIntegerArray; static;
    class function PredictForestValues(const Model:TDecisionForest;
      const Data:IDenseDoubleMatrix):TDoubleArray; static;
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

type
  TClusterMembers = array of TIntegerArray;

function ClusterDistance(const Data:IDenseDoubleMatrix;
  const LeftMembers,RightMembers:TIntegerArray;
  const Linkage:THierarchicalLinkage):Double;
var
  I,J,K:Integer;
  DistanceSquared,DistanceValue,Total:Double;
begin
  if Linkage=hlSingle then Result:=Infinity else Result:=0;
  Total:=0;
  for I:=0 to High(LeftMembers) do
    for J:=0 to High(RightMembers) do
    begin
      DistanceSquared:=0;
      for K:=0 to Data.Cols-1 do
        AddSquaredDifference(DistanceSquared,
          Data[LeftMembers[I],K],Data[RightMembers[J],K],
          'HierarchicalCluster');
      DistanceValue:=Sqrt(DistanceSquared);
      case Linkage of
        hlSingle: Result:=Min(Result,DistanceValue);
        hlComplete: Result:=Max(Result,DistanceValue);
        hlAverage: Total:=Total+DistanceValue;
      end;
    end;
  if Linkage=hlAverage then
    Result:=Total/(Length(LeftMembers)*Length(RightMembers));
end;

class function TAnalysisKit.HierarchicalCluster(
  const Data:IDenseDoubleMatrix;
  const Linkage:THierarchicalLinkage):THierarchicalClustering;
var
  Members:TClusterMembers;
  Active:array of Boolean;
  I,J,K,Step,N,LeftID,RightID,NewID,Offset:Integer;
  DistanceValue,BestDistance:Double;
begin
  Result:=Default(THierarchicalClustering);
  ValidateData(Data,'HierarchicalCluster',True);
  N:=Data.Rows;
  Result.SampleCount:=N;
  SetLength(Result.MergeLeft,N-1);
  SetLength(Result.MergeRight,N-1);
  SetLength(Result.Distances,N-1);
  SetLength(Result.ClusterSizes,N-1);
  SetLength(Members,2*N-1);
  SetLength(Active,2*N-1);
  for I:=0 to N-1 do
  begin
    Members[I]:=TIntegerArray.Create(I);
    Active[I]:=True;
  end;
  for Step:=0 to N-2 do
  begin
    LeftID:=-1; RightID:=-1; BestDistance:=Infinity;
    for I:=0 to N+Step-1 do
      if Active[I] then
        for J:=I+1 to N+Step-1 do
          if Active[J] then
          begin
            DistanceValue:=ClusterDistance(Data,Members[I],Members[J],Linkage);
            if (DistanceValue<BestDistance) or
               ((DistanceValue=BestDistance) and
                ((LeftID<0) or (I<LeftID) or
                 ((I=LeftID) and (J<RightID)))) then
            begin
              BestDistance:=DistanceValue;
              LeftID:=I; RightID:=J;
            end;
          end;
    Result.MergeLeft[Step]:=LeftID;
    Result.MergeRight[Step]:=RightID;
    Result.Distances[Step]:=BestDistance;
    Result.ClusterSizes[Step]:=Length(Members[LeftID])+Length(Members[RightID]);
    NewID:=N+Step;
    SetLength(Members[NewID],Result.ClusterSizes[Step]);
    Offset:=0;
    for K:=0 to High(Members[LeftID]) do
    begin Members[NewID][Offset]:=Members[LeftID][K]; Inc(Offset); end;
    for K:=0 to High(Members[RightID]) do
    begin Members[NewID][Offset]:=Members[RightID][K]; Inc(Offset); end;
    Active[LeftID]:=False; Active[RightID]:=False; Active[NewID]:=True;
  end;
end;

class function TAnalysisKit.CutHierarchy(
  const Model:THierarchicalClustering;
  const ClusterCount:Integer):TIntegerArray;
var
  Members:TClusterMembers;
  OriginalLabels:TIntegerArray;
  I,J,Step,N,NewID,Offset,NextLabel,OldLabel:Integer;
begin
  Result:=nil; N:=Model.SampleCount;
  if (N<2) or (Length(Model.MergeLeft)<>N-1) or
     (Length(Model.MergeRight)<>N-1) or
     (Length(Model.Distances)<>N-1) or
     (Length(Model.ClusterSizes)<>N-1) then
    raise EAnalysisError.Create('CutHierarchy: invalid hierarchy model.');
  if (ClusterCount<1) or (ClusterCount>N) then
    raise EAnalysisError.CreateFmt(
      'CutHierarchy: ClusterCount must be in [1,%d].',[N]);
  SetLength(Members,2*N-1);
  SetLength(Result,N);
  for I:=0 to N-1 do
  begin Members[I]:=TIntegerArray.Create(I); Result[I]:=I; end;
  for Step:=0 to N-2 do
  begin
    if (Model.MergeLeft[Step]<0) or (Model.MergeLeft[Step]>=N+Step) or
       (Model.MergeRight[Step]<0) or (Model.MergeRight[Step]>=N+Step) then
      raise EAnalysisError.Create('CutHierarchy: merge index is invalid.');
    NewID:=N+Step;
    SetLength(Members[NewID],Length(Members[Model.MergeLeft[Step]])+
      Length(Members[Model.MergeRight[Step]]));
    Offset:=0;
    for J:=0 to High(Members[Model.MergeLeft[Step]]) do
    begin
      Members[NewID][Offset]:=Members[Model.MergeLeft[Step]][J]; Inc(Offset);
    end;
    for J:=0 to High(Members[Model.MergeRight[Step]]) do
    begin
      Members[NewID][Offset]:=Members[Model.MergeRight[Step]][J]; Inc(Offset);
    end;
    if Step<N-ClusterCount then
    begin
      OldLabel:=Result[Members[NewID][0]];
      for J:=0 to High(Members[NewID]) do
        Result[Members[NewID][J]]:=OldLabel;
    end;
  end;
  OriginalLabels:=Copy(Result);
  NextLabel:=0;
  for I:=0 to N-1 do
  begin
    OldLabel:=OriginalLabels[I];
    for J:=0 to I-1 do
      if OriginalLabels[J]=OldLabel then
      begin Result[I]:=Result[J]; OldLabel:=-1; Break; end;
    if OldLabel>=0 then
    begin Result[I]:=NextLabel; Inc(NextLabel); end;
  end;
end;

class function TAnalysisKit.FitStandardization(
  const TrainingData:IDenseDoubleMatrix):TStandardizationModel;
var
  I,J:Integer;
  Delta,M2:Double;
begin
  Result:=Default(TStandardizationModel);
  ValidateData(TrainingData,'FitStandardization');
  SetLength(Result.Means,TrainingData.Cols);
  SetLength(Result.Scales,TrainingData.Cols);
  for J:=0 to TrainingData.Cols-1 do
  begin
    M2:=0;
    for I:=0 to TrainingData.Rows-1 do
    begin
      Delta:=TrainingData[I,J]-Result.Means[J];
      Result.Means[J]:=Result.Means[J]+Delta/(I+1);
      M2:=M2+Delta*(TrainingData[I,J]-Result.Means[J]);
    end;
    if TrainingData.Rows>1 then
      Result.Scales[J]:=Sqrt(M2/(TrainingData.Rows-1));
    if Result.Scales[J]=0 then Result.Scales[J]:=1;
  end;
end;

class function TAnalysisKit.TransformStandardized(
  const Model:TStandardizationModel;
  const Data:IDenseDoubleMatrix):IDenseDoubleMatrix;
var I,J:Integer;
begin
  ValidateData(Data,'TransformStandardized');
  if (Length(Model.Means)<>Data.Cols) or
     (Length(Model.Scales)<>Data.Cols) then
    raise EAnalysisError.Create(
      'TransformStandardized: model feature count does not match Data.');
  Result:=TDenseDoubleMatrix.Zeros(Data.Rows,Data.Cols);
  for J:=0 to Data.Cols-1 do
  begin
    if IsNan(Model.Means[J]) or IsInfinite(Model.Means[J]) or
       IsNan(Model.Scales[J]) or IsInfinite(Model.Scales[J]) or
       (Model.Scales[J]<=0) then
      raise EAnalysisError.CreateFmt(
        'TransformStandardized: invalid model scale at feature %d.',[J]);
    for I:=0 to Data.Rows-1 do
      Result[I,J]:=(Data[I,J]-Model.Means[J])/Model.Scales[J];
  end;
end;

function TreePrediction(const Tree:TDecisionTreeModel;
  const Data:IDenseDoubleMatrix; Row:Integer):Double;
var NodeIndex:Integer;
begin
  if Length(Tree.Nodes)=0 then
    raise EAnalysisError.Create('Decision forest: tree is empty.');
  NodeIndex:=0;
  while not Tree.Nodes[NodeIndex].IsLeaf do
    if Data[Row,Tree.Nodes[NodeIndex].Feature]<=
       Tree.Nodes[NodeIndex].Threshold then
      NodeIndex:=Tree.Nodes[NodeIndex].LeftNode
    else
      NodeIndex:=Tree.Nodes[NodeIndex].RightNode;
  Result:=Tree.Nodes[NodeIndex].Prediction;
end;

function BuildForest(const Data:IDenseDoubleMatrix;
  const Labels:TIntegerArray; const Targets:TDoubleArray;
  Task:TForestTask; TreeCount,MaximumDepth,MinimumLeafSize:Integer;
  Seed:QWord):TDecisionForest;
var
  Random:TLocalRandom;
  OOBCounts:TIntegerArray;
  OOBSums:TDoubleArray;
  OOBVotes:array of TIntegerArray;
  TreeIndex,I,J,N,ClassCount,ClassIndex,OOBTotal,Correct:Integer;
  InBag:array of Boolean;
  Bootstrap:TIntegerArray;
  Importance:TDoubleArray;
  Prediction,MeanTarget,SSE,SST,ImportanceTotal:Double;

  function NodePrediction(const Rows:TIntegerArray):Double;
  var
    Counts:TIntegerArray;
    RowIndex,ClassIndex,Best:Integer;
    Sum:Double;
  begin
    if Task=ftRegression then
    begin
      Sum:=0;
      for RowIndex:=0 to High(Rows) do Sum:=Sum+Targets[Rows[RowIndex]];
      Exit(Sum/Length(Rows));
    end;
    SetLength(Counts,ClassCount);
    for RowIndex:=0 to High(Rows) do Inc(Counts[Labels[Rows[RowIndex]]]);
    Best:=0;
    for ClassIndex:=1 to ClassCount-1 do
      if Counts[ClassIndex]>Counts[Best] then Best:=ClassIndex;
    Result:=Best;
  end;

  function Impurity(const Rows:TIntegerArray):Double;
  var
    Counts:TIntegerArray;
    RowIndex,ClassIndex:Integer;
    Sum,MeanValue:Double;
  begin
    if Task=ftRegression then
    begin
      MeanValue:=NodePrediction(Rows); Result:=0;
      for RowIndex:=0 to High(Rows) do
        Result:=Result+Sqr(Targets[Rows[RowIndex]]-MeanValue);
      Exit;
    end;
    SetLength(Counts,ClassCount);
    for RowIndex:=0 to High(Rows) do Inc(Counts[Labels[Rows[RowIndex]]]);
    Sum:=0;
    for ClassIndex:=0 to High(Counts) do
      Sum:=Sum+Sqr(Counts[ClassIndex]/Length(Rows));
    Result:=Length(Rows)*(1-Sum);
  end;

  function BuildNode(const Rows:TIntegerArray; Depth:Integer;
    var Tree:TDecisionTreeModel):Integer;
  var
    Selected:array of Boolean;
    LeftRows,RightRows:TIntegerArray;
    FeatureTrial,Feature,FeatureTrials,Candidate,RowIndex,
      LeftCount,RightCount,NodeIndex:Integer;
    Threshold,BestThreshold,ParentImpurity,SplitImpurity,
      BestImprovement,Improvement:Double;
    BestFeature:Integer;
    Node:TDecisionTreeNode;
  begin
    NodeIndex:=Length(Tree.Nodes);
    SetLength(Tree.Nodes,NodeIndex+1);
    Node:=Default(TDecisionTreeNode);
    Node.Prediction:=NodePrediction(Rows);
    Node.IsLeaf:=True;
    Tree.Nodes[NodeIndex]:=Node;
    if (Depth>=MaximumDepth) or
       (Length(Rows)<2*MinimumLeafSize) then Exit(NodeIndex);
    ParentImpurity:=Impurity(Rows);
    if ParentImpurity<=0 then Exit(NodeIndex);
    FeatureTrials:=Max(1,Round(Sqrt(Data.Cols)));
    SetLength(Selected,Data.Cols);
    BestFeature:=-1; BestThreshold:=0; BestImprovement:=0;
    for FeatureTrial:=1 to FeatureTrials do
    begin
      repeat Feature:=Random.NextInteger(Data.Cols) until not Selected[Feature];
      Selected[Feature]:=True;
      for Candidate:=0 to High(Rows) do
      begin
        Threshold:=Data[Rows[Candidate],Feature];
        LeftCount:=0; RightCount:=0;
        for RowIndex:=0 to High(Rows) do
          if Data[Rows[RowIndex],Feature]<=Threshold then Inc(LeftCount)
          else Inc(RightCount);
        if (LeftCount<MinimumLeafSize) or
           (RightCount<MinimumLeafSize) then Continue;
        SetLength(LeftRows,LeftCount); SetLength(RightRows,RightCount);
        LeftCount:=0; RightCount:=0;
        for RowIndex:=0 to High(Rows) do
          if Data[Rows[RowIndex],Feature]<=Threshold then
          begin LeftRows[LeftCount]:=Rows[RowIndex]; Inc(LeftCount); end
          else
          begin RightRows[RightCount]:=Rows[RowIndex]; Inc(RightCount); end;
        SplitImpurity:=Impurity(LeftRows)+Impurity(RightRows);
        Improvement:=ParentImpurity-SplitImpurity;
        if (Improvement>BestImprovement+1E-15) or
           ((Abs(Improvement-BestImprovement)<=1E-15) and
            (Improvement>0) and
            ((BestFeature<0) or (Feature<BestFeature) or
             ((Feature=BestFeature) and (Threshold<BestThreshold)))) then
        begin
          BestImprovement:=Improvement;
          BestFeature:=Feature;
          BestThreshold:=Threshold;
        end;
      end;
    end;
    if BestFeature<0 then Exit(NodeIndex);
    LeftCount:=0; RightCount:=0;
    for RowIndex:=0 to High(Rows) do
      if Data[Rows[RowIndex],BestFeature]<=BestThreshold then Inc(LeftCount)
      else Inc(RightCount);
    SetLength(LeftRows,LeftCount); SetLength(RightRows,RightCount);
    LeftCount:=0; RightCount:=0;
    for RowIndex:=0 to High(Rows) do
      if Data[Rows[RowIndex],BestFeature]<=BestThreshold then
      begin LeftRows[LeftCount]:=Rows[RowIndex]; Inc(LeftCount); end
      else
      begin RightRows[RightCount]:=Rows[RowIndex]; Inc(RightCount); end;
    Node.IsLeaf:=False;
    Node.Feature:=BestFeature;
    Node.Threshold:=BestThreshold;
    Importance[BestFeature]:=Importance[BestFeature]+BestImprovement;
    Node.LeftNode:=BuildNode(LeftRows,Depth+1,Tree);
    Node.RightNode:=BuildNode(RightRows,Depth+1,Tree);
    Tree.Nodes[NodeIndex]:=Node;
    Result:=NodeIndex;
  end;

begin
  Result:=Default(TDecisionForest);
  ClassCount:=0;
  OOBVotes:=nil;
  ValidateData(Data,'Decision forest',True);
  if (TreeCount<1) or (MaximumDepth<1) or (MinimumLeafSize<1) then
    raise EAnalysisError.Create('Decision forest: invalid training options.');
  N:=Data.Rows;
  if Task=ftClassification then
  begin
    if Length(Labels)<>N then
      raise EAnalysisError.Create(
        'FitClassificationForest: labels length mismatch.');
    for I:=0 to N-1 do
    begin
      if Labels[I]<0 then
        raise EAnalysisError.Create(
          'FitClassificationForest: labels must be non-negative.');
      ClassCount:=Max(ClassCount,Labels[I]+1);
    end;
    if ClassCount<2 then
      raise EAnalysisError.Create(
        'FitClassificationForest: at least two classes are required.');
    SetLength(OOBVotes,N);
    for I:=0 to N-1 do SetLength(OOBVotes[I],ClassCount);
  end
  else
  begin
    if Length(Targets)<>N then
      raise EAnalysisError.Create(
        'FitRegressionForest: targets length mismatch.');
    for I:=0 to N-1 do
      if IsNan(Targets[I]) or IsInfinite(Targets[I]) then
        raise EAnalysisError.CreateFmt(
          'FitRegressionForest: target %d must be finite.',[I]);
  end;
  Result.Task:=Task; Result.ClassCount:=ClassCount;
  Result.Seed:=Seed;
  SetLength(Result.Trees,TreeCount);
  SetLength(Importance,Data.Cols);
  SetLength(OOBCounts,N); SetLength(OOBSums,N);
  Random:=TLocalRandom.Seeded(Seed);
  SetLength(Bootstrap,N); SetLength(InBag,N);
  for TreeIndex:=0 to TreeCount-1 do
  begin
    FillChar(InBag[0],N*SizeOf(Boolean),0);
    for I:=0 to N-1 do
    begin
      Bootstrap[I]:=Random.NextInteger(N);
      InBag[Bootstrap[I]]:=True;
    end;
    BuildNode(Bootstrap,0,Result.Trees[TreeIndex]);
    for I:=0 to N-1 do
      if not InBag[I] then
      begin
        Prediction:=TreePrediction(Result.Trees[TreeIndex],Data,I);
        Inc(OOBCounts[I]);
        if Task=ftClassification then
          Inc(OOBVotes[I][Round(Prediction)])
        else
          OOBSums[I]:=OOBSums[I]+Prediction;
      end;
  end;
  Result.FeatureImportances:=Copy(Importance);
  ImportanceTotal:=0;
  for J:=0 to High(Result.FeatureImportances) do
    ImportanceTotal:=ImportanceTotal+Result.FeatureImportances[J];
  if ImportanceTotal>0 then
    for J:=0 to High(Result.FeatureImportances) do
      Result.FeatureImportances[J]:=
        Result.FeatureImportances[J]/ImportanceTotal;
  OOBTotal:=0;
  if Task=ftClassification then
  begin
    Correct:=0;
    for I:=0 to N-1 do if OOBCounts[I]>0 then
    begin
      Inc(OOBTotal); J:=0;
      for ClassIndex:=1 to High(OOBVotes[I]) do
        if OOBVotes[I][ClassIndex]>OOBVotes[I][J] then J:=ClassIndex;
      if J=Labels[I] then Inc(Correct);
    end;
    if OOBTotal>0 then Result.OOBScore:=Correct/OOBTotal;
  end
  else
  begin
    MeanTarget:=0; OOBTotal:=0;
    for I:=0 to N-1 do if OOBCounts[I]>0 then
    begin MeanTarget:=MeanTarget+Targets[I]; Inc(OOBTotal); end;
    if OOBTotal>0 then MeanTarget:=MeanTarget/OOBTotal;
    SSE:=0; SST:=0;
    for I:=0 to N-1 do if OOBCounts[I]>0 then
    begin
      Prediction:=OOBSums[I]/OOBCounts[I];
      SSE:=SSE+Sqr(Targets[I]-Prediction);
      SST:=SST+Sqr(Targets[I]-MeanTarget);
    end;
    if SST>0 then Result.OOBScore:=1-SSE/SST;
  end;
end;

class function TAnalysisKit.FitClassificationForest(
  const Data:IDenseDoubleMatrix; const Labels:TIntegerArray;
  const TreeCount,MaximumDepth,MinimumLeafSize:Integer;
  const Seed:QWord):TDecisionForest;
begin
  Result:=BuildForest(Data,Labels,nil,ftClassification,TreeCount,
    MaximumDepth,MinimumLeafSize,Seed);
end;

class function TAnalysisKit.FitRegressionForest(
  const Data:IDenseDoubleMatrix; const Targets:TDoubleArray;
  const TreeCount,MaximumDepth,MinimumLeafSize:Integer;
  const Seed:QWord):TDecisionForest;
begin
  Result:=BuildForest(Data,nil,Targets,ftRegression,TreeCount,
    MaximumDepth,MinimumLeafSize,Seed);
end;

procedure ValidateForestPrediction(const Model:TDecisionForest;
  const Data:IDenseDoubleMatrix; Task:TForestTask);
begin
  ValidateData(Data,'Decision forest prediction');
  if Model.Task<>Task then
    raise EAnalysisError.Create('Decision forest prediction: task mismatch.');
  if Length(Model.Trees)=0 then
    raise EAnalysisError.Create('Decision forest prediction: model has no trees.');
  if Length(Model.FeatureImportances)<>Data.Cols then
    raise EAnalysisError.Create(
      'Decision forest prediction: feature count mismatch.');
end;

class function TAnalysisKit.PredictForestClasses(
  const Model:TDecisionForest;
  const Data:IDenseDoubleMatrix):TIntegerArray;
var
  Votes:TIntegerArray;
  I,J,Best:Integer;
begin
  Result:=nil;
  ValidateForestPrediction(Model,Data,ftClassification);
  if Model.ClassCount<2 then
    raise EAnalysisError.Create(
      'PredictForestClasses: invalid class metadata.');
  SetLength(Result,Data.Rows); SetLength(Votes,Model.ClassCount);
  for I:=0 to Data.Rows-1 do
  begin
    FillChar(Votes[0],Length(Votes)*SizeOf(Integer),0);
    for J:=0 to High(Model.Trees) do
      Inc(Votes[Round(TreePrediction(Model.Trees[J],Data,I))]);
    Best:=0;
    for J:=1 to High(Votes) do if Votes[J]>Votes[Best] then Best:=J;
    Result[I]:=Best;
  end;
end;

class function TAnalysisKit.PredictForestValues(
  const Model:TDecisionForest;
  const Data:IDenseDoubleMatrix):TDoubleArray;
var I,J:Integer;
begin
  Result:=nil;
  ValidateForestPrediction(Model,Data,ftRegression);
  SetLength(Result,Data.Rows);
  for I:=0 to Data.Rows-1 do
  begin
    for J:=0 to High(Model.Trees) do
      Result[I]:=Result[I]+TreePrediction(Model.Trees[J],Data,I);
    Result[I]:=Result[I]/Length(Model.Trees);
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
