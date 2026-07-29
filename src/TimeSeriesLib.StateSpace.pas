unit TimeSeriesLib.StateSpace;

{-----------------------------------------------------------------------------
 TimeSeriesLib.StateSpace

 Scalar linear-Gaussian Kalman filtering with explicit, bounded state.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes;

type
  EStateSpaceError = class(Exception);

  TScalarKalmanConfiguration = record
    Transition: Double;
    Observation: Double;
    ProcessVariance: Double;
    MeasurementVariance: Double;
    class function Create(const ATransition, AObservation,
      AProcessVariance, AMeasurementVariance: Double):
      TScalarKalmanConfiguration; static;
  end;

  TKalmanSeriesResult = record
    Estimates: TDoubleArray;
    Variances: TDoubleArray;
    Innovations: TDoubleArray;
    InnovationVariances: TDoubleArray;
    LogLikelihood: Double;
  end;

  TKalmanForecast = record
    Means: TDoubleArray;
    Variances: TDoubleArray;
  end;

  TScalarKalmanFilter = record
  private
    FConfiguration: TScalarKalmanConfiguration;
    FEstimate: Double;
    FCovariance: Double;
    procedure PredictInPlace;
    procedure UpdateInPlace(const Measurement: Double;
      out Innovation, InnovationVariance: Double);
  public
    class function Create(const Configuration: TScalarKalmanConfiguration;
      const InitialEstimate, InitialVariance: Double):
      TScalarKalmanFilter; static;
    procedure Reset(const InitialEstimate, InitialVariance: Double);
    procedure Predict;
    procedure Update(const Measurement: Double);
    function Process(const Measurements: TDoubleArray):
      TKalmanSeriesResult;
    function Forecast(const StepCount: SizeInt): TKalmanForecast;
    property Estimate: Double read FEstimate;
    property Variance: Double read FCovariance;
    property Configuration: TScalarKalmanConfiguration read FConfiguration;
  end;

implementation

const
  STATE_SPACE_PI: Double = 3.141592653589793238462643383279502884;

procedure RequireFinite(const Value: Double; const Name, Operation: string);
begin
  if IsNan(Value) or IsInfinite(Value) then
    raise EStateSpaceError.CreateFmt('%s: %s must be finite.',
      [Operation, Name]);
end;

procedure ValidateConfiguration(
  const Configuration: TScalarKalmanConfiguration);
begin
  RequireFinite(Configuration.Transition, 'Transition',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.Observation, 'Observation',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.ProcessVariance, 'ProcessVariance',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.MeasurementVariance, 'MeasurementVariance',
    'TScalarKalmanConfiguration');
  if Configuration.Observation = 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: Observation must be non-zero.');
  if Configuration.ProcessVariance < 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: ProcessVariance must be non-negative.');
  if Configuration.MeasurementVariance <= 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: MeasurementVariance must be positive.');
end;

class function TScalarKalmanConfiguration.Create(const ATransition,
  AObservation, AProcessVariance, AMeasurementVariance: Double):
  TScalarKalmanConfiguration;
begin
  Result.Transition := ATransition;
  Result.Observation := AObservation;
  Result.ProcessVariance := AProcessVariance;
  Result.MeasurementVariance := AMeasurementVariance;
  ValidateConfiguration(Result);
end;

class function TScalarKalmanFilter.Create(
  const Configuration: TScalarKalmanConfiguration;
  const InitialEstimate, InitialVariance: Double): TScalarKalmanFilter;
begin
  ValidateConfiguration(Configuration);
  Result.FConfiguration := Configuration;
  Result.Reset(InitialEstimate, InitialVariance);
end;

procedure TScalarKalmanFilter.Reset(const InitialEstimate,
  InitialVariance: Double);
begin
  ValidateConfiguration(FConfiguration);
  RequireFinite(InitialEstimate, 'InitialEstimate',
    'TScalarKalmanFilter.Reset');
  RequireFinite(InitialVariance, 'InitialVariance',
    'TScalarKalmanFilter.Reset');
  if InitialVariance < 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Reset: InitialVariance must be non-negative.');
  FEstimate := InitialEstimate;
  FCovariance := InitialVariance;
end;

procedure TScalarKalmanFilter.PredictInPlace;
begin
  FEstimate := FConfiguration.Transition * FEstimate;
  FCovariance := Sqr(FConfiguration.Transition) * FCovariance +
    FConfiguration.ProcessVariance;
  if IsNan(FEstimate) or IsInfinite(FEstimate) or
     IsNan(FCovariance) or IsInfinite(FCovariance) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Predict: numerical overflow.');
end;

procedure TScalarKalmanFilter.UpdateInPlace(const Measurement: Double;
  out Innovation, InnovationVariance: Double);
var
  Gain, OneMinusGainObservation: Double;
begin
  Innovation := Measurement - FConfiguration.Observation * FEstimate;
  InnovationVariance := Sqr(FConfiguration.Observation) * FCovariance +
    FConfiguration.MeasurementVariance;
  if IsNan(InnovationVariance) or IsInfinite(InnovationVariance) or
     (InnovationVariance <= 0.0) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Update: innovation variance must remain finite and positive.');
  Gain := FCovariance * FConfiguration.Observation / InnovationVariance;
  FEstimate := FEstimate + Gain * Innovation;
  { Joseph scalar form preserves non-negative covariance under rounding. }
  OneMinusGainObservation := 1.0 - Gain * FConfiguration.Observation;
  FCovariance := Sqr(OneMinusGainObservation) * FCovariance +
    Sqr(Gain) * FConfiguration.MeasurementVariance;
  if IsNan(FEstimate) or IsInfinite(FEstimate) or
     IsNan(FCovariance) or IsInfinite(FCovariance) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Update: numerical overflow.');
end;

procedure TScalarKalmanFilter.Predict;
var
  Work: TScalarKalmanFilter;
begin
  Work := Self;
  Work.PredictInPlace;
  Self := Work;
end;

procedure TScalarKalmanFilter.Update(const Measurement: Double);
var
  Work: TScalarKalmanFilter;
  Innovation, InnovationVariance: Double;
begin
  RequireFinite(Measurement, 'Measurement', 'TScalarKalmanFilter.Update');
  Work := Self;
  Work.UpdateInPlace(Measurement, Innovation, InnovationVariance);
  Self := Work;
end;

function TScalarKalmanFilter.Process(const Measurements: TDoubleArray):
  TKalmanSeriesResult;
var
  Work: TScalarKalmanFilter;
  I: SizeInt;
  Innovation, InnovationVariance, Contribution, NewLogLikelihood: Double;
begin
  Result.Estimates := nil;
  Result.Variances := nil;
  Result.Innovations := nil;
  Result.InnovationVariances := nil;
  Result.LogLikelihood := 0.0;
  for I := 0 to High(Measurements) do
    RequireFinite(Measurements[I], Format('Measurements[%d]', [I]),
      'TScalarKalmanFilter.Process');
  SetLength(Result.Estimates, Length(Measurements));
  SetLength(Result.Variances, Length(Measurements));
  SetLength(Result.Innovations, Length(Measurements));
  SetLength(Result.InnovationVariances, Length(Measurements));
  Work := Self;
  for I := 0 to High(Measurements) do
  begin
    Work.PredictInPlace;
    Work.UpdateInPlace(Measurements[I], Innovation, InnovationVariance);
    Result.Estimates[I] := Work.FEstimate;
    Result.Variances[I] := Work.FCovariance;
    Result.Innovations[I] := Innovation;
    Result.InnovationVariances[I] := InnovationVariance;
    Contribution := -0.5 *
      (Ln(2.0 * STATE_SPACE_PI * InnovationVariance) +
       Sqr(Innovation) / InnovationVariance);
    NewLogLikelihood := Result.LogLikelihood + Contribution;
    if IsNan(NewLogLikelihood) or IsInfinite(NewLogLikelihood) then
      raise EStateSpaceError.CreateFmt(
        'TScalarKalmanFilter.Process: log-likelihood overflow at sample %d.',
        [I]);
    Result.LogLikelihood := NewLogLikelihood;
  end;
  Self := Work;
end;

function TScalarKalmanFilter.Forecast(const StepCount: SizeInt):
  TKalmanForecast;
var
  Work: TScalarKalmanFilter;
  I: SizeInt;
begin
  Result.Means := nil;
  Result.Variances := nil;
  if StepCount < 0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Forecast: StepCount must be non-negative.');
  SetLength(Result.Means, StepCount);
  SetLength(Result.Variances, StepCount);
  Work := Self;
  for I := 0 to StepCount - 1 do
  begin
    Work.PredictInPlace;
    Result.Means[I] := FConfiguration.Observation * Work.FEstimate;
    Result.Variances[I] := Sqr(FConfiguration.Observation) *
      Work.FCovariance + FConfiguration.MeasurementVariance;
    if IsNan(Result.Means[I]) or IsInfinite(Result.Means[I]) or
       IsNan(Result.Variances[I]) or IsInfinite(Result.Variances[I]) then
      raise EStateSpaceError.CreateFmt(
        'TScalarKalmanFilter.Forecast: numerical overflow at step %d.', [I]);
  end;
end;

end.
