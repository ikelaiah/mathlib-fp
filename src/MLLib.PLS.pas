unit MLLib.PLS;

{-----------------------------------------------------------------------------
 MLLib.PLS

 Dense PLS1 regression for one continuous response. The default Fit method
 standardizes predictors, selects a component count with deterministic
 cross-validation, and returns coefficients in the caller's units.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes,
  MLLib.MachineLearning, MLLib.Analysis;

type
  EPLSError = class(Exception);

  TPLSOptions = record
    MaxComponents: SizeInt; { zero: use the measured predictor rank }
    Folds: SizeInt;         { zero: min(5, observations - 1) }
    Seed: LongWord;
    ScalePredictors: Boolean;
    RankTolerance: Double;
    class function Default: TPLSOptions; static;
  end;

  TPLSStatus = (plsConverged, plsMeanOnly);
  TPLSFoldErrors = array of TDoubleArray;

  TPLSModel = record
    Coefficients: TDoubleArray; { one per original predictor }
    Intercept: Double;
    PredictorMeans: TDoubleArray;
    PredictorScales: TDoubleArray;
    PredictorRank: SizeInt;
    SelectedComponents: SizeInt;
    ValidatedComponents: SizeInt;
    CrossValidationFolds: SizeInt;
    CrossValidationSeed: LongWord;
    RMSECV: TDoubleArray; { index 0 is the fold-training-mean baseline }
    FoldRMSECV: TPLSFoldErrors; { supplied-split fits only }
    FoldSampleCounts: TIntegerArray; { scored rows per supplied split }
    CrossValidationSampleCount: SizeInt; { counted row occurrences }
    Status: TPLSStatus;
  end;

  TPLSPredictionModel = record
    Coefficients: TDoubleArray; { original predictor units; no second transform }
    Intercept: Double;
  end;

  TPLSKit = class
  public
    class function ToPredictionModel(const Model: TPLSModel):
      TPLSPredictionModel; static;
    { Fit one continuous response from a row-major predictor matrix. }
    class function Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
      const Y: TDoubleArray): TPLSModel; overload; static;
    class function Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
      const Y: TDoubleArray; const Options: TPLSOptions): TPLSModel;
      overload; static;
    class function Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
      const Y: TDoubleArray; const Splits: TValidationSplits): TPLSModel;
      overload; static;
    class function Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
      const Y: TDoubleArray; const Splits: TValidationSplits;
      const Options: TPLSOptions): TPLSModel; overload; static;
    { Predict from new rows with the same predictor columns and order. }
    class function Predict(const Model: TPLSModel;
      const XNew: MLLib.MachineLearning.TDoubleMatrix): TDoubleArray;
      overload; static;
    class function Predict(const Model: TPLSPredictionModel;
      const XNew: MLLib.MachineLearning.TDoubleMatrix): TDoubleArray;
      overload; static;
  end;

implementation

type
  TPLSMatrix = MLLib.MachineLearning.TDoubleMatrix;
  TPLSVectorList = array of TDoubleArray;
  TPLSInternalFit = record
    Means: TDoubleArray;
    Scales: TDoubleArray;
    ResponseMean: Double;
    ResponseScale: Double;
    Rank: SizeInt;
    Betas: TPLSVectorList; { component 0 is the zero slope / mean baseline }
    ComponentCount: SizeInt;
  end;

  TScaledSquares = record
    Scale: Double;
    SumSquares: Double;
  end;

function IsFiniteValue(const Value: Double): Boolean; inline;
begin
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

procedure RequireFinite(const Value: Double; const Context: String);
begin
  if not IsFiniteValue(Value) then
    raise EPLSError.Create(Context + ': calculation is outside the finite ' +
      'Double range');
end;

function StableNorm(const Values: TDoubleArray): Double;
var
  I: SizeInt;
  ValueScale, SumSquares, AbsValue: Double;
begin
  ValueScale := 0.0;
  SumSquares := 1.0;
  for I := 0 to High(Values) do
  begin
    AbsValue := Abs(Values[I]);
    if AbsValue <> 0.0 then
    begin
      if ValueScale < AbsValue then
      begin
        SumSquares := 1.0 + SumSquares * Sqr(ValueScale / AbsValue);
        ValueScale := AbsValue;
      end
      else
        SumSquares := SumSquares + Sqr(AbsValue / ValueScale);
    end;
  end;
  if ValueScale = 0.0 then
    Exit(0.0);
  Result := ValueScale * Sqrt(SumSquares);
  RequireFinite(Result, 'Vector norm');
end;

function Dot(const A, B: TDoubleArray): Double;
var
  I: SizeInt;
begin
  Result := 0.0;
  for I := 0 to High(A) do
    Result := Result + A[I] * B[I];
  RequireFinite(Result, 'Dot product');
end;

function MatrixColumnNorm(const A: TPLSMatrix; const Column: SizeInt): Double;
var
  I: SizeInt;
  Values: TDoubleArray;
begin
  SetLength(Values, Length(A));
  for I := 0 to High(A) do
    Values[I] := A[I][Column];
  Result := StableNorm(Values);
end;

function MeanOf(const Values: TDoubleArray): Double;
var
  I: SizeInt;
begin
  Result := 0.0;
  for I := 0 to High(Values) do
  begin
    Result := Result + (Values[I] - Result) / (I + 1);
    RequireFinite(Result, 'Centering');
  end;
end;

function SampleScale(const Values: TDoubleArray; const Mean: Double): Double;
var
  I: SizeInt;
  Deviations: TDoubleArray;
begin
  SetLength(Deviations, Length(Values));
  for I := 0 to High(Values) do
  begin
    Deviations[I] := Values[I] - Mean;
    RequireFinite(Deviations[I], 'Centering');
  end;
  if Length(Values) <= 1 then
    Exit(0.0);
  Result := StableNorm(Deviations) / Sqrt(Length(Values) - 1);
  RequireFinite(Result, 'Sample standard deviation');
end;

procedure ValidateData(const X: TPLSMatrix; const Y: TDoubleArray);
var
  I, J, FeatureCount: SizeInt;
begin
  if Length(X) < 3 then
    raise EPLSError.Create('Fit: at least three observations are required');
  if Length(Y) <> Length(X) then
    raise EPLSError.Create('Fit: response length must equal the row count');
  FeatureCount := Length(X[0]);
  if FeatureCount = 0 then
    raise EPLSError.Create('Fit: the design must contain at least one predictor');
  for I := 0 to High(X) do
  begin
    if Length(X[I]) <> FeatureCount then
      raise EPLSError.Create('Fit: design matrix rows must have equal length');
    for J := 0 to FeatureCount - 1 do
      if not IsFiniteValue(X[I][J]) then
        raise EPLSError.Create('Fit: predictors must be finite and contain ' +
          'no missing values');
  end;
  for I := 0 to High(Y) do
    if not IsFiniteValue(Y[I]) then
      raise EPLSError.Create('Fit: response values must be finite and contain ' +
        'no missing values');
end;

procedure ValidateOptions(const Options: TPLSOptions; const ObservationCount:
  SizeInt);
begin
  if Options.MaxComponents < 0 then
    raise EPLSError.Create('Fit: MaxComponents must be zero or positive');
  if (Options.Folds = 1) or (Options.Folds < 0) or
    (Options.Folds > ObservationCount - 1) then
    raise EPLSError.Create('Fit: Folds must be zero or between 2 and N-1');
  if not IsFiniteValue(Options.RankTolerance) or
    (Options.RankTolerance <= 0.0) or (Options.RankTolerance > 0.01) then
    raise EPLSError.Create('Fit: RankTolerance must be finite and in (0, 0.01]');
end;

procedure PrepareData(const X: TPLSMatrix; const Y: TDoubleArray;
  const ScalePredictors: Boolean; out XScaled: TPLSMatrix;
  out YScaled: TDoubleArray; out Means, Scales: TDoubleArray;
  out ResponseMean, ResponseScale: Double);
var
  N, P, I, J: SizeInt;
  Column: TDoubleArray;
begin
  N := Length(X);
  P := Length(X[0]);
  SetLength(Means, P);
  SetLength(Scales, P);
  SetLength(XScaled, N);
  SetLength(Column, N);
  for I := 0 to N - 1 do
    SetLength(XScaled[I], P);
  for J := 0 to P - 1 do
  begin
    for I := 0 to N - 1 do
      Column[I] := X[I][J];
    Means[J] := MeanOf(Column);
    if ScalePredictors then
      Scales[J] := SampleScale(Column, Means[J])
    else
      Scales[J] := 1.0;
    if Scales[J] = 0.0 then
      Scales[J] := 1.0;
    for I := 0 to N - 1 do
    begin
      XScaled[I][J] := (X[I][J] - Means[J]) / Scales[J];
      RequireFinite(XScaled[I][J], 'Predictor scaling');
    end;
  end;

  ResponseMean := MeanOf(Y);
  ResponseScale := SampleScale(Y, ResponseMean);
  if ResponseScale = 0.0 then
    ResponseScale := 1.0;
  SetLength(YScaled, N);
  for I := 0 to N - 1 do
  begin
    YScaled[I] := (Y[I] - ResponseMean) / ResponseScale;
    RequireFinite(YScaled[I], 'Response scaling');
  end;
end;

function MatrixNumericalRank(const A: TPLSMatrix; const Tolerance: Double):
  SizeInt;
var
  N, P, J, I, L, Pass, BasisCount: SizeInt;
  Basis: TPLSVectorList;
  V, Q: TDoubleArray;
  InitialNorm, ResidualNorm, Projection: Double;
begin
  N := Length(A);
  P := Length(A[0]);
  SetLength(Basis, P);
  BasisCount := 0;
  for J := 0 to P - 1 do
  begin
    SetLength(V, N);
    for I := 0 to N - 1 do
      V[I] := A[I][J];
    InitialNorm := StableNorm(V);
    if InitialNorm = 0.0 then
      Continue;
    for Pass := 1 to 2 do
      for I := 0 to BasisCount - 1 do
      begin
        Q := Basis[I];
        Projection := Dot(Q, V);
        for L := 0 to N - 1 do
          V[L] := V[L] - Projection * Q[L];
      end;
    ResidualNorm := StableNorm(V);
    if ResidualNorm <= Tolerance * InitialNorm then
      Continue;
    for I := 0 to N - 1 do
      V[I] := V[I] / ResidualNorm;
    Basis[BasisCount] := Copy(V);
    Inc(BasisCount);
  end;
  Result := BasisCount;
end;

function MatrixFrobeniusNorm(const A: TPLSMatrix): Double;
var
  I, J: SizeInt;
  ValueScale, SumSquares, AbsValue: Double;
begin
  ValueScale := 0.0;
  SumSquares := 1.0;
  for I := 0 to High(A) do
    for J := 0 to High(A[I]) do
    begin
      AbsValue := Abs(A[I][J]);
      if AbsValue <> 0.0 then
      begin
        if ValueScale < AbsValue then
        begin
          SumSquares := 1.0 + SumSquares * Sqr(ValueScale / AbsValue);
          ValueScale := AbsValue;
        end
        else
          SumSquares := SumSquares + Sqr(AbsValue / ValueScale);
      end;
    end;
  if ValueScale = 0.0 then
    Exit(0.0);
  Result := ValueScale * Sqrt(SumSquares);
  RequireFinite(Result, 'Predictor residual norm');
end;

function MatrixVector(const A: TPLSMatrix; const V: TDoubleArray): TDoubleArray;
var
  I, J: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
  begin
    Result[I] := 0.0;
    for J := 0 to High(V) do
      Result[I] := Result[I] + A[I][J] * V[J];
    RequireFinite(Result[I], 'PLS score');
  end;
end;

function CrossProduct(const A: TPLSMatrix; const V: TDoubleArray): TDoubleArray;
var
  I, J: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(A[0]));
  for J := 0 to High(Result) do
  begin
    Result[J] := 0.0;
    for I := 0 to High(A) do
      Result[J] := Result[J] + A[I][J] * V[I];
    RequireFinite(Result[J], 'PLS cross-product');
  end;
end;

function FitComponents(const XScaled: TPLSMatrix; const YScaled: TDoubleArray;
  const MaxComponents: SizeInt; const Tolerance: Double;
  out ComponentCount: SizeInt): TPLSVectorList;
var
  ResidualX: TPLSMatrix;
  ResidualY: TDoubleArray;
  Loadings, Rotations, Scores: TPLSVectorList;
  Covariance, Weight, Score, Loading, Rotation, Beta: TDoubleArray;
  ScoreOrthogonalization: TDoubleArray;
  N, P, K, I, J, Pass: SizeInt;
  WeightNorm, ScoreNormSquared, LoadingY, CrossNorm, XNorm, YNorm,
    Projection, OrthogonalCoefficient, AdjustedProjection: Double;
begin
  Result := nil;
  N := Length(XScaled);
  P := Length(XScaled[0]);
  ResidualX := Copy(XScaled);
  ResidualY := Copy(YScaled);
  SetLength(Loadings, MaxComponents);
  SetLength(Rotations, MaxComponents);
  SetLength(Scores, MaxComponents);
  SetLength(Result, MaxComponents + 1);
  SetLength(Result[0], P);
  ComponentCount := 0;
  if MaxComponents = 0 then
    Exit;

  for K := 0 to MaxComponents - 1 do
  begin
    Covariance := CrossProduct(ResidualX, ResidualY);
    CrossNorm := StableNorm(Covariance);
    XNorm := MatrixFrobeniusNorm(ResidualX);
    YNorm := StableNorm(ResidualY);
    if (XNorm = 0.0) or (YNorm = 0.0) or (CrossNorm = 0.0) or
      (CrossNorm / XNorm / YNorm <= Tolerance) then
      Break;

    WeightNorm := CrossNorm;
    SetLength(Weight, P);
    for J := 0 to P - 1 do
      Weight[J] := Covariance[J] / WeightNorm;
    Score := MatrixVector(ResidualX, Weight);
    SetLength(ScoreOrthogonalization, K);
    for I := 0 to K - 1 do
      ScoreOrthogonalization[I] := 0.0;
    for Pass := 1 to 2 do
      for I := 0 to K - 1 do
      begin
        OrthogonalCoefficient := Dot(Scores[I], Score) /
          Dot(Scores[I], Scores[I]);
        ScoreOrthogonalization[I] :=
          ScoreOrthogonalization[I] + OrthogonalCoefficient;
        for J := 0 to N - 1 do
          Score[J] := Score[J] - OrthogonalCoefficient * Scores[I][J];
      end;
    ScoreNormSquared := Dot(Score, Score);
    if (ScoreNormSquared = 0.0) or not IsFiniteValue(ScoreNormSquared) then
      Break;

    Loading := CrossProduct(ResidualX, Score);
    for J := 0 to P - 1 do
      Loading[J] := Loading[J] / ScoreNormSquared;
    LoadingY := Dot(ResidualY, Score) / ScoreNormSquared;
    RequireFinite(LoadingY, 'Response loading');

    Rotation := Copy(Weight);
    for I := 0 to K - 1 do
    begin
      Projection := Dot(Loadings[I], Weight);
      AdjustedProjection := Projection + ScoreOrthogonalization[I];
      for J := 0 to P - 1 do
        Rotation[J] := Rotation[J] - Rotations[I][J] * AdjustedProjection;
    end;

    Loadings[K] := Loading;
    Rotations[K] := Rotation;
    Scores[K] := Score;
    Beta := Copy(Result[K]);
    for J := 0 to P - 1 do
    begin
      Beta[J] := Beta[J] + LoadingY * Rotation[J];
      RequireFinite(Beta[J], 'PLS coefficient');
    end;
    Result[K + 1] := Beta;

    for I := 0 to N - 1 do
    begin
      for J := 0 to P - 1 do
      begin
        ResidualX[I][J] := ResidualX[I][J] - Score[I] * Loading[J];
        RequireFinite(ResidualX[I][J], 'Predictor deflation');
      end;
      ResidualY[I] := ResidualY[I] - Score[I] * LoadingY;
      RequireFinite(ResidualY[I], 'Response deflation');
    end;
    Inc(ComponentCount);
  end;
  SetLength(Result, ComponentCount + 1);
end;

function InternalFit(const X: TPLSMatrix; const Y: TDoubleArray;
  const ScalePredictors: Boolean; const MaxComponents: SizeInt;
  const Tolerance: Double): TPLSInternalFit;
var
  XScaled: TPLSMatrix;
  YScaled: TDoubleArray;
  EffectiveMax: SizeInt;
begin
  PrepareData(X, Y, ScalePredictors, XScaled, YScaled,
    Result.Means, Result.Scales, Result.ResponseMean, Result.ResponseScale);
  Result.Rank := MatrixNumericalRank(XScaled, Tolerance);
  if MaxComponents < 0 then
    EffectiveMax := Result.Rank
  else
    EffectiveMax := Min(MaxComponents, Result.Rank);
  Result.Betas := FitComponents(XScaled, YScaled,
    EffectiveMax, Tolerance, Result.ComponentCount);
end;

procedure NextRandom(var State: LongWord); inline;
var
  Wide: QWord;
begin
  Wide := QWord(State) * 1664525 + 1013904223;
  State := LongWord(Wide and $FFFFFFFF);
end;

{ FPC 3.2.2 Win64 changes the seeded shuffle at -O3 if this routine is
  optimized, breaking the same-seed fold contract across build modes. }
{$push}
{$optimization off}
function MakeFoldIds(const ObservationCount, FoldCount: SizeInt;
  const Seed: LongWord): TIntegerArray;
var
  Order: TIntegerArray;
  ShuffleIndex, AssignmentIndex, J, Temporary: SizeInt;
  State: LongWord;
begin
  Result := nil;
  SetLength(Order, ObservationCount);
  for AssignmentIndex := 0 to ObservationCount - 1 do
    Order[AssignmentIndex] := AssignmentIndex;
  State := Seed;
  for ShuffleIndex := ObservationCount - 1 downto 1 do
  begin
    NextRandom(State);
    J := SizeInt(QWord(State) mod QWord(ShuffleIndex + 1));
    Temporary := Order[ShuffleIndex];
    Order[ShuffleIndex] := Order[J];
    Order[J] := Temporary;
  end;
  SetLength(Result, ObservationCount);
  for AssignmentIndex := 0 to ObservationCount - 1 do
    Result[Order[AssignmentIndex]] := AssignmentIndex mod FoldCount;
end;
{$pop}

procedure AddScaledSquare(var Accumulator: TScaledSquares; const Value: Double);
var
  AbsValue: Double;
begin
  AbsValue := Abs(Value);
  if AbsValue = 0.0 then
    Exit;
  if Accumulator.Scale < AbsValue then
  begin
    Accumulator.SumSquares := 1.0 + Accumulator.SumSquares *
      Sqr(Accumulator.Scale / AbsValue);
    Accumulator.Scale := AbsValue;
  end
  else
    Accumulator.SumSquares := Accumulator.SumSquares +
      Sqr(AbsValue / Accumulator.Scale);
end;

function ScaledRMSE(const Accumulator: TScaledSquares;
  const Count: SizeInt): Double;
begin
  if (Count = 0) or (Accumulator.Scale = 0.0) then
    Exit(0.0);
  Result := Accumulator.Scale *
    Sqrt(Accumulator.SumSquares / Count);
  RequireFinite(Result, 'Cross-validation RMSE');
end;

function PredictInternal(const Fit: TPLSInternalFit;
  const Component: SizeInt; const XRow: TDoubleArray): Double;
var
  J: SizeInt;
  StandardValue: Double;
begin
  Result := Fit.ResponseMean;
  if Component = 0 then
    Exit;
  for J := 0 to High(XRow) do
  begin
    StandardValue := (XRow[J] - Fit.Means[J]) / Fit.Scales[J];
    RequireFinite(StandardValue, 'Prediction scaling');
    Result := Result + Fit.ResponseScale * Fit.Betas[Component][J] *
      StandardValue;
    RequireFinite(Result, 'Prediction');
  end;
end;

procedure BuildFold(const X: TPLSMatrix; const Y: TDoubleArray;
  const FoldIds: TIntegerArray; const HeldOutFold: SizeInt;
  out TrainX: TPLSMatrix; out TrainY: TDoubleArray;
  out TestRows: TPLSMatrix; out TestY: TDoubleArray);
var
  I, TrainCount, TestCount, TrainIndex, TestIndex: SizeInt;
begin
  TrainCount := 0;
  TestCount := 0;
  for I := 0 to High(FoldIds) do
    if FoldIds[I] = HeldOutFold then Inc(TestCount) else Inc(TrainCount);
  SetLength(TrainX, TrainCount);
  SetLength(TrainY, TrainCount);
  SetLength(TestRows, TestCount);
  SetLength(TestY, TestCount);
  TrainIndex := 0;
  TestIndex := 0;
  for I := 0 to High(FoldIds) do
    if FoldIds[I] = HeldOutFold then
    begin
      TestRows[TestIndex] := Copy(X[I]);
      TestY[TestIndex] := Y[I];
      Inc(TestIndex);
    end
    else
    begin
      TrainX[TrainIndex] := Copy(X[I]);
      TrainY[TrainIndex] := Y[I];
      Inc(TrainIndex);
    end;
end;

class function TPLSOptions.Default: TPLSOptions;
begin
  Result.MaxComponents := 0;
  Result.Folds := 0;
  Result.Seed := 1729;
  Result.ScalePredictors := True;
  Result.RankTolerance := 1E-12;
end;

class function TPLSKit.Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
  const Y: TDoubleArray): TPLSModel;
begin
  Result := Fit(X, Y, TPLSOptions.Default);
end;

class function TPLSKit.Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
  const Y: TDoubleArray; const Options: TPLSOptions): TPLSModel;
var
  FullFit, FoldFit: TPLSInternalFit;
  TrainX, TestX: TPLSMatrix;
  TrainY, TestY: TDoubleArray;
  FoldIds: TIntegerArray;
  CVErrors: array of TScaledSquares;
  CVMax, FoldFitCount, FoldCount, HeldOutFold, I, K, J: SizeInt;
  BestComponent, SelectedComponent, EffectiveMax: SizeInt;
  Prediction, Difference, MinimumError: Double;
begin
  Result.Coefficients := nil;
  Result.PredictorMeans := nil;
  Result.PredictorScales := nil;
  Result.RMSECV := nil;
  Result.FoldRMSECV := nil;
  Result.FoldSampleCounts := nil;
  Result.CrossValidationSampleCount := 0;
  ValidateData(X, Y);
  ValidateOptions(Options, Length(X));
  FullFit := InternalFit(X, Y, Options.ScalePredictors,
    -1, Options.RankTolerance);
  if Options.MaxComponents > FullFit.Rank then
    raise EPLSError.CreateFmt('Fit: MaxComponents (%d) exceeds the measured ' +
      'predictor rank (%d)', [Options.MaxComponents, FullFit.Rank]);
  if Options.MaxComponents = 0 then
    EffectiveMax := FullFit.Rank
  else
    EffectiveMax := Options.MaxComponents;
  FoldCount := Options.Folds;
  if FoldCount = 0 then
    FoldCount := Min(5, Length(X) - 1);
  FoldIds := MakeFoldIds(Length(X), FoldCount, Options.Seed);
  SetLength(CVErrors, EffectiveMax + 1);
  for K := 0 to High(CVErrors) do
  begin
    CVErrors[K].Scale := 0.0;
    CVErrors[K].SumSquares := 0.0;
  end;
  CVMax := EffectiveMax;

  for HeldOutFold := 0 to FoldCount - 1 do
  begin
    BuildFold(X, Y, FoldIds, HeldOutFold, TrainX, TrainY, TestX, TestY);
    FoldFit := InternalFit(TrainX, TrainY, Options.ScalePredictors,
      EffectiveMax, Options.RankTolerance);
    FoldFitCount := FoldFit.ComponentCount;
    if FoldFitCount < CVMax then
      CVMax := FoldFitCount;
    for I := 0 to High(TestX) do
      for K := 0 to FoldFitCount do
      begin
        Prediction := PredictInternal(FoldFit, K, TestX[I]);
        Difference := TestY[I] - Prediction;
        RequireFinite(Difference, 'Cross-validation residual');
        AddScaledSquare(CVErrors[K], Difference);
      end;
  end;

  SetLength(Result.RMSECV, CVMax + 1);
  BestComponent := 0;
  MinimumError := ScaledRMSE(CVErrors[0], Length(X));
  Result.RMSECV[0] := MinimumError;
  for K := 1 to CVMax do
  begin
    Result.RMSECV[K] := ScaledRMSE(CVErrors[K], Length(X));
    if Result.RMSECV[K] < MinimumError then
    begin
      MinimumError := Result.RMSECV[K];
      BestComponent := K;
    end;
  end;

  SelectedComponent := BestComponent;
  if FullFit.ComponentCount < SelectedComponent then
    SelectedComponent := FullFit.ComponentCount;
  Result.Coefficients := Copy(FullFit.Betas[SelectedComponent]);
  for J := 0 to High(Result.Coefficients) do
  begin
    Result.Coefficients[J] := Result.Coefficients[J] *
      FullFit.ResponseScale / FullFit.Scales[J];
    RequireFinite(Result.Coefficients[J], 'Original-scale coefficient');
  end;
  Result.Intercept := FullFit.ResponseMean;
  for J := 0 to High(Result.Coefficients) do
    Result.Intercept := Result.Intercept -
      FullFit.Means[J] * Result.Coefficients[J];
  RequireFinite(Result.Intercept, 'Original-scale intercept');

  Result.PredictorMeans := Copy(FullFit.Means);
  Result.PredictorScales := Copy(FullFit.Scales);
  Result.PredictorRank := FullFit.Rank;
  Result.SelectedComponents := SelectedComponent;
  Result.ValidatedComponents := CVMax;
  Result.CrossValidationFolds := FoldCount;
  Result.CrossValidationSeed := Options.Seed;
  if SelectedComponent = 0 then
    Result.Status := plsMeanOnly
  else
    Result.Status := plsConverged;
end;

procedure BuildValidationRows(const X: TPLSMatrix; const Y: TDoubleArray;
  const Split: TValidationSplit; out TrainX, TestX: TPLSMatrix;
  out TrainY, TestY: TDoubleArray);
var I, Row: SizeInt;
begin
  SetLength(TrainX, Length(Split.TrainingRows));
  SetLength(TrainY, Length(Split.TrainingRows));
  for I := 0 to High(TrainX) do
  begin
    Row := Split.TrainingRows[I];
    TrainX[I] := Copy(X[Row]); TrainY[I] := Y[Row];
  end;
  SetLength(TestX, Length(Split.ValidationRows));
  SetLength(TestY, Length(Split.ValidationRows));
  for I := 0 to High(TestX) do
  begin
    Row := Split.ValidationRows[I];
    TestX[I] := Copy(X[Row]); TestY[I] := Y[Row];
  end;
end;

class function TPLSKit.Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
  const Y: TDoubleArray; const Splits: TValidationSplits): TPLSModel;
begin
  Result := Fit(X, Y, Splits, TPLSOptions.Default);
end;

class function TPLSKit.Fit(const X: MLLib.MachineLearning.TDoubleMatrix;
  const Y: TDoubleArray; const Splits: TValidationSplits;
  const Options: TPLSOptions): TPLSModel;
type TErrorRows = array of TScaledSquares;
var
  FullFit, FoldFit: TPLSInternalFit;
  TrainX, TestX: TPLSMatrix;
  TrainY, TestY: TDoubleArray;
  PooledErrors: TErrorRows;
  FoldErrors: array of TErrorRows;
  EffectiveMax, CVMax, FoldIndex, FoldFitCount, I, K, J,
    BestComponent, SelectedComponent, ScoredCount: SizeInt;
  Prediction, Difference, MinimumError: Double;
begin
  Result.Coefficients := nil;
  Result.PredictorMeans := nil;
  Result.PredictorScales := nil;
  Result.RMSECV := nil;
  Result.FoldRMSECV := nil;
  Result.FoldSampleCounts := nil;
  ValidateData(X, Y);
  ValidateOptions(Options, Length(X));
  if Options.Folds <> 0 then
    raise EPLSError.Create('Fit: Folds must be zero with supplied splits.');
  if Length(Splits) < 2 then
    raise EPLSError.Create('Fit: at least two supplied splits are required.');
  ScoredCount := 0;
  for FoldIndex := 0 to High(Splits) do
  begin
    TAnalysisKit.ValidateSplit(Length(X), Splits[FoldIndex]);
    if Length(Splits[FoldIndex].TrainingRows) < 2 then
      raise EPLSError.Create('Fit: split training set needs at least two rows.');
    if ScoredCount > High(SizeInt) - Length(Splits[FoldIndex].ValidationRows) then
      raise EPLSError.Create('Fit: scored row count overflow.');
    Inc(ScoredCount, Length(Splits[FoldIndex].ValidationRows));
  end;
  FullFit := InternalFit(X, Y, Options.ScalePredictors,
    -1, Options.RankTolerance);
  if Options.MaxComponents > FullFit.Rank then
    raise EPLSError.CreateFmt('Fit: MaxComponents (%d) exceeds the measured ' +
      'predictor rank (%d)', [Options.MaxComponents, FullFit.Rank]);
  if Options.MaxComponents = 0 then EffectiveMax := FullFit.Rank
  else EffectiveMax := Options.MaxComponents;
  CVMax := EffectiveMax;
  SetLength(PooledErrors, EffectiveMax + 1);
  SetLength(FoldErrors, Length(Splits));
  SetLength(Result.FoldSampleCounts, Length(Splits));
  for FoldIndex := 0 to High(Splits) do
  begin
    BuildValidationRows(X, Y, Splits[FoldIndex],
      TrainX, TestX, TrainY, TestY);
    FoldFit := InternalFit(TrainX, TrainY, Options.ScalePredictors,
      EffectiveMax, Options.RankTolerance);
    FoldFitCount := FoldFit.ComponentCount;
    if FoldFitCount < CVMax then CVMax := FoldFitCount;
    Result.FoldSampleCounts[FoldIndex] := Length(TestY);
    SetLength(FoldErrors[FoldIndex], FoldFitCount + 1);
    for I := 0 to High(TestX) do
      for K := 0 to FoldFitCount do
      begin
        Prediction := PredictInternal(FoldFit, K, TestX[I]);
        Difference := TestY[I] - Prediction;
        RequireFinite(Difference, 'Cross-validation residual');
        AddScaledSquare(PooledErrors[K], Difference);
        AddScaledSquare(FoldErrors[FoldIndex][K], Difference);
      end;
  end;
  SetLength(Result.RMSECV, CVMax + 1);
  SetLength(Result.FoldRMSECV, Length(Splits));
  BestComponent := 0;
  MinimumError := ScaledRMSE(PooledErrors[0], ScoredCount);
  for K := 0 to CVMax do
  begin
    Result.RMSECV[K] := ScaledRMSE(PooledErrors[K], ScoredCount);
    if Result.RMSECV[K] < MinimumError then
    begin
      MinimumError := Result.RMSECV[K]; BestComponent := K;
    end;
    for FoldIndex := 0 to High(Splits) do
    begin
      if Length(Result.FoldRMSECV[FoldIndex]) = 0 then
        SetLength(Result.FoldRMSECV[FoldIndex], CVMax + 1);
      Result.FoldRMSECV[FoldIndex][K] :=
        ScaledRMSE(FoldErrors[FoldIndex][K],
          Result.FoldSampleCounts[FoldIndex]);
    end;
  end;
  SelectedComponent := BestComponent;
  Result.Coefficients := Copy(FullFit.Betas[SelectedComponent]);
  for J := 0 to High(Result.Coefficients) do
  begin
    Result.Coefficients[J] := Result.Coefficients[J] *
      FullFit.ResponseScale / FullFit.Scales[J];
    RequireFinite(Result.Coefficients[J], 'Original-scale coefficient');
  end;
  Result.Intercept := FullFit.ResponseMean;
  for J := 0 to High(Result.Coefficients) do
    Result.Intercept := Result.Intercept -
      FullFit.Means[J] * Result.Coefficients[J];
  RequireFinite(Result.Intercept, 'Original-scale intercept');
  Result.PredictorMeans := Copy(FullFit.Means);
  Result.PredictorScales := Copy(FullFit.Scales);
  Result.PredictorRank := FullFit.Rank;
  Result.SelectedComponents := SelectedComponent;
  Result.ValidatedComponents := CVMax;
  Result.CrossValidationFolds := Length(Splits);
  Result.CrossValidationSeed := 0;
  Result.CrossValidationSampleCount := ScoredCount;
  if SelectedComponent = 0 then Result.Status := plsMeanOnly
  else Result.Status := plsConverged;
end;

class function TPLSKit.Predict(const Model: TPLSModel;
  const XNew: MLLib.MachineLearning.TDoubleMatrix): TDoubleArray;
begin Result := Predict(ToPredictionModel(Model), XNew); end;

procedure ValidatePLSPrediction(const Model: TPLSPredictionModel);
var J: SizeInt;
begin
  if Length(Model.Coefficients) = 0 then
    raise EPLSError.Create('Predict: model is uninitialized or invalid');
  if not IsFiniteValue(Model.Intercept) then
    raise EPLSError.Create('Predict: model intercept must be finite');
  for J := 0 to High(Model.Coefficients) do
    if not IsFiniteValue(Model.Coefficients[J]) then
      raise EPLSError.Create('Predict: model coefficients must be finite');
end;

class function TPLSKit.ToPredictionModel(const Model: TPLSModel):
  TPLSPredictionModel;
var J, P: SizeInt;
begin
  P := Length(Model.Coefficients);
  if (P = 0) or (Length(Model.PredictorMeans) <> P) or
    (Length(Model.PredictorScales) <> P) then
    raise EPLSError.Create('Predict: model is uninitialized or invalid');
  for J := 0 to P - 1 do
    if not IsFiniteValue(Model.PredictorMeans[J]) or
      not IsFiniteValue(Model.PredictorScales[J]) or
      (Model.PredictorScales[J] <= 0.0) then
      raise EPLSError.Create('Predict: model parameters must be finite and valid');
  Result.Coefficients := Copy(Model.Coefficients); Result.Intercept := Model.Intercept;
  ValidatePLSPrediction(Result);
end;

class function TPLSKit.Predict(const Model: TPLSPredictionModel;
  const XNew: MLLib.MachineLearning.TDoubleMatrix): TDoubleArray;
var I, J, P: SizeInt; Value: Double;
begin
  Result := nil;
  ValidatePLSPrediction(Model); P := Length(Model.Coefficients);
  if Length(XNew) = 0 then
    raise EPLSError.Create('Predict: at least one observation is required');
  SetLength(Result, Length(XNew));
  for I := 0 to High(XNew) do
  begin
    if Length(XNew[I]) <> P then
      raise EPLSError.Create('Predict: row feature count does not match the model');
    Value := Model.Intercept;
    for J := 0 to P - 1 do
    begin
      if not IsFiniteValue(XNew[I][J]) then
        raise EPLSError.Create('Predict: predictor values must be finite');
      Value := Value + Model.Coefficients[J] * XNew[I][J];
      RequireFinite(Value, 'Prediction');
    end;
    Result[I] := Value;
  end;
end;

end.
