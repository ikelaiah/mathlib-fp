program sensor_pipeline;

{ ----------------------------------------------------------------------------
  mathlib-fp 1.9.8 representative workflow 1 — sensor pipeline

  A realistic multi-domain data flow: load a small bundled local CSV fixture,
  validate it, smooth and analyse it with DSP, summarise it with statistics,
  flag anomalies and fit a trend with time-series analysis, exercise a
  diagnostic (non-finite) rejection path, and export a deterministic report.

  Domains exercised: MathBase (shared arrays, binary interchange),
  EngineeringLib (FIR + Welch DSP), StatsLib (streaming + descriptive
  statistics), TimeSeriesLib (smoothing, anomaly detection, linear trend).

  Run from the repository root (or the extracted release archive root) so the
  bundled fixture resolves as examples/data/sensor_readings.csv. The export is
  written to workflow-exports/sensor_report.txt relative to the working
  directory.

  Compile:  fpc -Fusrc -FUlib examples/24_sensor_pipeline.pas
  Run:      ./24_sensor_pipeline
--------------------------------------------------------------------------- }

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes, MathBase.Interchange,
  EngineeringLib.Signal, EngineeringLib.DSP,
  StatsLib.Streaming, StatsLib.Stats,
  TimeSeriesLib.TimeSeries;

const
  FixturePath = 'examples/data/sensor_readings.csv';
  SampleRate = 16.0;
  ExportPath = 'workflow-exports/sensor_report.txt';

function F6(const Value: Double): string;
begin
  Str(Value:0:6, Result);
end;

procedure SaveText(const FileName, Content: string);
var
  Output: Text;
begin
  ForceDirectories(ExtractFilePath(FileName));
  Assign(Output, FileName);
  Rewrite(Output);
  Write(Output, Content);
  Close(Output);
end;

{ Return the number of non-finite readings in Values. }
function CountNonFinite(const Values: TDoubleArray): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Values) do
    if IsNan(Values[I]) or IsInfinite(Values[I]) then
      Inc(Result);
end;

var
  Rows: TStringList;
  Raw, Smoothed, Spiked, MovingAvg, Exponential, ExportVector: TDoubleArray;
  Coefficients: TDoubleArray;
  Spectrum: TSpectralEstimate;
  RawStats, SmoothStats: TOnlineStatistics;
  Anomalies: TIntegerArray;
  Trend: TLinearTrend;
  Stream: TMemoryStream;
  Report: string;
  RawCount, Rejected, I: Integer;
  Invalid: Boolean;
begin
  { 1. Loading + validation ------------------------------------------------
    The CSV holds one finite reading per line. Every value is validated for a
    finite, in-range measurement before it is accepted. }
  Rows := TStringList.Create;
  try
    Rows.LoadFromFile(FixturePath);
    SetLength(Raw, Rows.Count);
    RawCount := 0;
    Rejected := 0;
    for I := 0 to Rows.Count - 1 do
    begin
      if Trim(Rows[I]) = '' then
        Continue;
      Invalid := False;
      try
        Raw[RawCount] := StrToFloat(Trim(Rows[I]));
      except
        on E: EConvertError do
          Invalid := True;
      end;
      if (not Invalid) and (IsNan(Raw[RawCount]) or IsInfinite(Raw[RawCount])
          or (Raw[RawCount] < 0.0) or (Raw[RawCount] > 100.0)) then
        Invalid := True;
      if Invalid then
        Inc(Rejected)
      else
        Inc(RawCount);
    end;
    SetLength(Raw, RawCount);
  finally
    Rows.Free;
  end;

  Writeln('raw count: ', RawCount);
  Writeln('raw mean: ', F6(TStatsKit.Mean(Raw)));
  Writeln('raw sample stddev: ', F6(TStatsKit.SampleStandardDeviation(Raw)));

  { 2. Validation diagnostic ------------------------------------------------
    Inject a non-finite reading and prove the validation rejects it. }
  Spiked := Copy(Raw);
  Spiked[5] := NaN;
  Writeln('diagnostic: rejected ', CountNonFinite(Spiked),
    ' non-finite reading');

  { 3. DSP / signal processing ----------------------------------------------
    A windowed-sinc low-pass FIR smooths the series, and Welch's method
    estimates its power spectrum at a fixed segment size. }
  Coefficients := TSignalKit.DesignFIRLowPass(0.1, 8, wtHamming);
  Smoothed := TSignalKit.ApplyFIRFilter(Raw, Coefficients);
  Spectrum := TDSPKit.Welch(Raw, 16, 8, SampleRate);

  { 4. Statistics ------------------------------------------------------------
    Streaming statistics over the raw and smoothed series. }
  RawStats := TOnlineStatistics.Create;
  SmoothStats := TOnlineStatistics.Create;
  for I := 0 to High(Raw) do
    RawStats.Add(Raw[I]);
  for I := 0 to High(Smoothed) do
    SmoothStats.Add(Smoothed[I]);
  Writeln('streaming mean: ', F6(RawStats.Mean));
  Writeln('smoothed mean: ', F6(SmoothStats.Mean));
  Writeln('welch bins: ', Length(Spectrum.Power));

  { 5. Time-series analysis --------------------------------------------------
    Two smoothing paths, a seeded anomaly detector, and a linear trend. }
  MovingAvg := TTimeSeriesKit.SimpleMovingAverage(Raw, 5);
  Exponential := TTimeSeriesKit.ExponentialSmoothing(Raw, 0.3);
  Spiked := Copy(Raw);
  Spiked[20] := Spiked[20] + 50.0;
  Anomalies := TTimeSeriesKit.ZScoreAnomalies(Spiked, 3.0);
  Trend := TTimeSeriesKit.LinearTrend(Raw);
  Writeln('anomaly count: ', Length(Anomalies));
  Writeln('trend slope: ', F6(Trend.Slope));
  Writeln('last moving average: ', F6(MovingAvg[High(MovingAvg)]));

  { 6. Persistence / export --------------------------------------------------
    Round-trip the raw series through versioned binary interchange, then write
    a deterministic human-readable report. }
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, Raw);
    Stream.Position := 0;
    ExportVector := LoadDoubleVectorBinary(Stream, 1000);
  finally
    Stream.Free;
  end;

  Report :=
    'mathlib-fp sensor pipeline report' + sLineBreak +
    'raw count: ' + IntToStr(RawCount) + sLineBreak +
    'raw mean: ' + F6(TStatsKit.Mean(Raw)) + sLineBreak +
    'smoothed mean: ' + F6(SmoothStats.Mean) + sLineBreak +
    'anomaly count: ' + IntToStr(Length(Anomalies)) + sLineBreak +
    'trend slope: ' + F6(Trend.Slope) + sLineBreak +
    'round-trip length: ' + IntToStr(Length(ExportVector)) + sLineBreak;
  SaveText(ExportPath, Report);
  Writeln('exported: ', ExportPath, ' (', Length(Report), ' bytes)');

  Writeln('sensor pipeline: success');
end.
