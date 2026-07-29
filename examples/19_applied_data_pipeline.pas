program AppliedDataPipeline;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  AlgebraLib.DenseMatrices,
  EngineeringLib.DSP,
  StatsLib.Streaming,
  NumericsLib.Modelling,
  MLLib.Analysis,
  TimeSeriesLib.StateSpace;

const
  SampleCount = 128;
  SampleRate = 128.0;

var
  Signal, FrequencyAxis, PowerValues: TDoubleArray;
  Spectrum: TSpectralEstimate;
  PowerSummary: TOnlineStatistics;
  Fit: TFitResult;
  Features: IDenseDoubleMatrix;
  Components: TPCAResult;
  Clusters: TKMeansPlusPlusResult;
  KalmanConfig: TScalarKalmanConfiguration;
  FilterState: TScalarKalmanFilter;
  Filtered: TKalmanSeriesResult;
  I, FeatureRows: Integer;
begin
  SetLength(Signal, SampleCount);
  for I := 0 to SampleCount - 1 do
    Signal[I] := Sin(2 * Pi * 12 * I / SampleRate) +
      0.35 * Sin(2 * Pi * 28 * I / SampleRate) +
      0.02 * ((I * 37) mod 11 - 5);

  Spectrum := TDSPKit.Welch(Signal, 32, 16, SampleRate);
  PowerSummary := TOnlineStatistics.Create;
  for I := 0 to High(Spectrum.Power) do
    PowerSummary.Add(Spectrum.Power[I]);

  FrequencyAxis := Copy(Spectrum.Frequencies);
  PowerValues := Copy(Spectrum.Power);
  Fit := TModellingKit.FitPolynomial(FrequencyAxis, PowerValues, 2, nil);

  FeatureRows := Length(Spectrum.Power);
  Features := TDenseDoubleMatrix.Zeros(FeatureRows, 2);
  for I := 0 to FeatureRows - 1 do
  begin
    Features[I, 0] := Spectrum.Frequencies[I] / (SampleRate * 0.5);
    Features[I, 1] := Ln(Spectrum.Power[I] + 1E-12);
  end;
  Components := TAnalysisKit.PCA(Features, 2);
  Clusters := TAnalysisKit.KMeansPlusPlus(Components.Scores, 2, 20260730);

  KalmanConfig := TScalarKalmanConfiguration.Create(1.0, 1.0, 0.005, 0.08);
  FilterState := TScalarKalmanFilter.Create(KalmanConfig, Signal[0], 1.0);
  Filtered := FilterState.Process(Signal);

  Writeln('Welch bins: ', Length(Spectrum.Power));
  Writeln('Mean spectral power: ', PowerSummary.Mean:0:6);
  Writeln('Quadratic fit R^2: ', Fit.RSquared:0:6);
  Writeln('First PCA explained ratio: ',
    Components.ExplainedRatio[0]:0:6);
  Writeln('k-means++ converged: ', Clusters.Converged,
    ' in ', Clusters.Iterations, ' iterations');
  Writeln('Final filtered sample: ',
    Filtered.Estimates[High(Filtered.Estimates)]:0:6);
end.
