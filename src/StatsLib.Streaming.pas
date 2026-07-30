unit StatsLib.Streaming;

{-----------------------------------------------------------------------------
 StatsLib.Streaming

 Constant-memory, weighted, online, and mergeable descriptive statistics.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math;

type
  EStreamingStatsError = class(Exception);

  TNonFinitePolicy = (nfpReject, nfpIgnore);

  TOnlineStatistics = record
  private
    FCount: QWord;
    FWeightSum: Double;
    FWeightSquareSum: Double;
    FMean: Double;
    FM2: Double;
    FMinimum: Double;
    FMaximum: Double;
    FPolicy: TNonFinitePolicy;
    function GetMean: Double;
    function GetMinimum: Double;
    function GetMaximum: Double;
    function GetPopulationVariance: Double;
    function GetSampleVariance: Double;
  public
    class function Create(
      const NonFinitePolicy: TNonFinitePolicy = nfpReject):
      TOnlineStatistics; static;
    procedure Clear;
    procedure Add(const Value: Double);
    procedure AddWeighted(const Value, Weight: Double);
    procedure Merge(const Other: TOnlineStatistics);
    function PopulationStandardDeviation: Double;
    function SampleStandardDeviation: Double;
    property Count: QWord read FCount;
    property WeightSum: Double read FWeightSum;
    property Mean: Double read GetMean;
    property Minimum: Double read GetMinimum;
    property Maximum: Double read GetMaximum;
    property PopulationVariance: Double read GetPopulationVariance;
    property SampleVariance: Double read GetSampleVariance;
    property NonFinitePolicy: TNonFinitePolicy read FPolicy;
  end;

implementation

procedure RequireObservation(const Value, Weight: Double;
  const Policy: TNonFinitePolicy; out Ignore: Boolean);
begin
  Ignore := False;
  if IsNan(Weight) or IsInfinite(Weight) or (Weight <= 0.0) then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.AddWeighted: Weight must be finite and positive.');
  if IsNan(Value) or IsInfinite(Value) then
  begin
    if Policy = nfpIgnore then
      Ignore := True
    else
      raise EStreamingStatsError.Create(
        'TOnlineStatistics.AddWeighted: Value must be finite under nfpReject.');
  end;
end;

class function TOnlineStatistics.Create(
  const NonFinitePolicy: TNonFinitePolicy): TOnlineStatistics;
begin
  Result.FPolicy := NonFinitePolicy;
  Result.Clear;
end;

procedure TOnlineStatistics.Clear;
begin
  FCount := 0;
  FWeightSum := 0.0;
  FWeightSquareSum := 0.0;
  FMean := 0.0;
  FM2 := 0.0;
  FMinimum := 0.0;
  FMaximum := 0.0;
end;

procedure TOnlineStatistics.Add(const Value: Double);
begin
  AddWeighted(Value, 1.0);
end;

procedure TOnlineStatistics.AddWeighted(const Value, Weight: Double);
var
  Ignore: Boolean;
  WeightSquare, NewWeight, NewWeightSquareSum: Double;
  Delta, Adjustment, NewMean, NewM2: Double;
begin
  RequireObservation(Value, Weight, FPolicy, Ignore);
  if Ignore then
    Exit;
  if FCount = High(QWord) then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.AddWeighted: observation count overflow.');
  if FWeightSum > MaxDouble - Weight then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.AddWeighted: accumulated weight overflow.');
  if Weight > Sqrt(MaxDouble) then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.AddWeighted: squared weight would overflow.');
  WeightSquare := Weight * Weight;
  if FWeightSquareSum > MaxDouble - WeightSquare then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.AddWeighted: squared-weight sum would overflow.');

  NewWeight := FWeightSum + Weight;
  NewWeightSquareSum := FWeightSquareSum + WeightSquare;
  if FCount = 0 then
  begin
    NewMean := Value;
    NewM2 := 0.0;
  end
  else
  begin
    try
      Delta := Value - FMean;
      Adjustment := Delta * (Weight / NewWeight);
      NewMean := FMean + Adjustment;
      NewM2 := FM2 + FWeightSum * Delta * Adjustment;
    except
      on EMathError do
        raise EStreamingStatsError.Create(
          'TOnlineStatistics.AddWeighted: accumulated moments overflow.');
    end;
    if IsNan(NewMean) or IsInfinite(NewMean) or IsNan(NewM2) or
      IsInfinite(NewM2) then
      raise EStreamingStatsError.Create(
        'TOnlineStatistics.AddWeighted: accumulated moments overflow.');
  end;
  FMean := NewMean;
  FM2 := NewM2;
  if FCount = 0 then
  begin
    FMinimum := Value;
    FMaximum := Value;
  end
  else
  begin
    if Value < FMinimum then
      FMinimum := Value;
    if Value > FMaximum then
      FMaximum := Value;
  end;
  Inc(FCount);
  FWeightSum := NewWeight;
  FWeightSquareSum := NewWeightSquareSum;
end;

procedure TOnlineStatistics.Merge(const Other: TOnlineStatistics);
var
  NewWeight, NewWeightSquareSum, Delta, CrossTerm, NewMean, NewM2: Double;
begin
  if FPolicy <> Other.FPolicy then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Merge: non-finite policies must match.');
  if Other.FCount = 0 then
    Exit;
  if FCount = 0 then
  begin
    Self := Other;
    Exit;
  end;
  if FCount > High(QWord) - Other.FCount then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Merge: observation count overflow.');
  if FWeightSum > MaxDouble - Other.FWeightSum then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Merge: accumulated weight overflow.');
  if FWeightSquareSum > MaxDouble - Other.FWeightSquareSum then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Merge: squared-weight sum overflow.');

  NewWeight := FWeightSum + Other.FWeightSum;
  NewWeightSquareSum := FWeightSquareSum + Other.FWeightSquareSum;
  try
    Delta := Other.FMean - FMean;
    CrossTerm := Delta * Delta * FWeightSum * Other.FWeightSum / NewWeight;
    NewMean := FMean + Delta * (Other.FWeightSum / NewWeight);
    NewM2 := FM2 + Other.FM2 + CrossTerm;
  except
    on EMathError do
      raise EStreamingStatsError.Create(
        'TOnlineStatistics.Merge: merged moments overflow.');
  end;
  if IsNan(CrossTerm) or IsInfinite(CrossTerm) or IsNan(NewMean) or
    IsInfinite(NewMean) or IsNan(NewM2) or IsInfinite(NewM2) then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Merge: merged moments overflow.');
  FMean := NewMean;
  FM2 := NewM2;
  FWeightSum := NewWeight;
  FWeightSquareSum := NewWeightSquareSum;
  FCount := FCount + Other.FCount;
  if Other.FMinimum < FMinimum then
    FMinimum := Other.FMinimum;
  if Other.FMaximum > FMaximum then
    FMaximum := Other.FMaximum;
end;

function TOnlineStatistics.GetMean: Double;
begin
  if FCount = 0 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Mean: at least one observation is required.');
  Result := FMean;
end;

function TOnlineStatistics.GetMinimum: Double;
begin
  if FCount = 0 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Minimum: at least one observation is required.');
  Result := FMinimum;
end;

function TOnlineStatistics.GetMaximum: Double;
begin
  if FCount = 0 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.Maximum: at least one observation is required.');
  Result := FMaximum;
end;

function TOnlineStatistics.GetPopulationVariance: Double;
begin
  if FCount = 0 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.PopulationVariance: at least one observation is required.');
  Result := Max(0.0, FM2 / FWeightSum);
end;

function TOnlineStatistics.GetSampleVariance: Double;
var
  Denominator: Double;
begin
  if FCount < 2 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.SampleVariance: at least two observations are required.');
  Denominator := FWeightSum - FWeightSquareSum / FWeightSum;
  if Denominator <= 0.0 then
    raise EStreamingStatsError.Create(
      'TOnlineStatistics.SampleVariance: effective sample size must exceed one.');
  Result := Max(0.0, FM2 / Denominator);
end;

function TOnlineStatistics.PopulationStandardDeviation: Double;
begin
  Result := Sqrt(PopulationVariance);
end;

function TOnlineStatistics.SampleStandardDeviation: Double;
begin
  Result := Sqrt(SampleVariance);
end;

end.
