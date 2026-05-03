program example10_timeseries;

{-----------------------------------------------------------------------------
 Example 10 — TimeSeriesLib Walkthrough

 Written for someone new to time series analysis.
 Each section introduces one technique with a plain-English explanation,
 a concrete example, and guidance on when to use it.

 Compile:  fpc example10_timeseries.lpr
 Run:      ./example10_timeseries   (Linux/Mac)
           example10_timeseries.exe (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  TimeSeriesLib.TimeSeries;

procedure Sep; begin WriteLn(StringOfChar('-', 55)); end;

procedure ShowVec(const Lbl: String; const V: TDoubleArray;
  MaxItems: Integer = 8);
var I: Integer;
begin
  Write(Format('  %-28s [', [Lbl]));
  for I := 0 to Min(MaxItems - 1, High(V)) do
  begin
    if I > 0 then Write(', ');
    Write(Format('%.3f', [V[I]]));
  end;
  if Length(V) > MaxItems then Write(', ...');
  WriteLn(']');
end;

{ ============================================================
  Build some sample data for demonstrations
============================================================ }

{ A noisy trending series: Y[t] = 2*t + 10*sin(2*pi*t/12) + noise }
function MakeTrendySeasonal(N: Integer): TDoubleArray;
var I: Integer;
begin
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := 2.0 * I + 10.0 * Sin(2 * Pi * I / 12.0) + (I mod 7) * 0.5;
end;

{ A pure AR(1) series with phi=0.8 (stationary) }
function MakeAR1(N: Integer; Phi: Double): TDoubleArray;
var I: Integer;
begin
  SetLength(Result, N);
  Result[0] := 1.0;
  for I := 1 to N - 1 do
    Result[I] := Phi * Result[I - 1];
end;

{ A series with a clear mean shift at the midpoint }
function MakeShiftSeries(N: Integer): TDoubleArray;
var I: Integer;
begin
  SetLength(Result, N);
  for I := 0 to N - 1 do
    if I < N div 2 then Result[I] := 0.0
    else                 Result[I] := 5.0;
end;

{ ============================================================
  SECTION 1 — Smoothing
============================================================ }
procedure DemoSmoothing;
var Y, SMA, WMA, EMA: TDoubleArray;
begin
  WriteLn;
  WriteLn('=== SMOOTHING ===');
  WriteLn('Raw data has a trend + 12-period seasonal + small noise.');
  WriteLn('Smoothing extracts the underlying signal.');
  Sep;

  Y   := MakeTrendySeasonal(36);
  SMA := TTimeSeriesKit.SimpleMovingAverage(Y, 5);
  WMA := TTimeSeriesKit.WeightedMovingAverage(Y, 5);
  EMA := TTimeSeriesKit.ExponentialSmoothing(Y, 0.3);

  ShowVec('Raw Y (first 8)',  Y,   8);
  ShowVec('SMA window=5',     SMA, 8);
  ShowVec('WMA window=5',     WMA, 8);
  ShowVec('EMA alpha=0.3',    EMA, 8);
  WriteLn;
  WriteLn('  SMA: equal weights, best for steady data.');
  WriteLn('  WMA: recent data weighted more, reacts faster.');
  WriteLn('  EMA: exponential decay; alpha near 1 = raw data.');
end;

{ ============================================================
  SECTION 2 — Holt-Winters (Trend + Seasonality)
============================================================ }
procedure DemoHoltWinters;
var Y, Fitted, Fcast: TDoubleArray;
begin
  WriteLn;
  WriteLn('=== HOLT-WINTERS (TREND + SEASONAL) ===');
  WriteLn('Series = trend + 12-period seasonality.');
  WriteLn('Holt-Winters tracks level, trend and seasonal indices.');
  Sep;

  Y      := MakeTrendySeasonal(48);
  Fitted := TTimeSeriesKit.TripleExponentialSmoothing(Y, 0.3, 0.1, 0.4, 12);
  Fcast  := TTimeSeriesKit.HoltWintersForecast(Y, 0.3, 0.1, 0.4, 12, 6);

  WriteLn(Format('  Last observed value: %.3f', [Y[High(Y)]]));
  ShowVec('6-step forecast', Fcast, 6);
  WriteLn;
  WriteLn('  When to use: monthly sales, electricity demand, anything with');
  WriteLn('  a clear repeating cycle AND an upward or downward trend.');
end;

{ ============================================================
  SECTION 3 — Decomposition
============================================================ }
procedure DemoDecomposition;
var Y: TDoubleArray;
    D: TDecomposition;
    I: Integer;
begin
  WriteLn;
  WriteLn('=== CLASSICAL DECOMPOSITION ===');
  WriteLn('Splits Y into Trend + Seasonal + Residual (additive).');
  Sep;

  Y := MakeTrendySeasonal(48);
  D := TTimeSeriesKit.Decompose(Y, 12, dtAdditive);

  WriteLn('  Trend (mid-series, first 8 valid):');
  Write('    [');
  for I := 6 to 13 do
  begin
    if I > 6 then Write(', ');
    Write(Format('%.1f', [D.Trend[I]]));
  end;
  WriteLn(']');

  WriteLn('  Seasonal indices (one full cycle):');
  Write('    [');
  for I := 0 to 11 do
  begin
    if I > 0 then Write(', ');
    Write(Format('%+.2f', [D.Seasonal[I]]));
  end;
  WriteLn(']');

  WriteLn;
  WriteLn('  Use decomposition to:');
  WriteLn('  - Visualise what is trend vs seasonal vs noise.');
  WriteLn('  - Remove seasonality before forecasting.');
  WriteLn('  - Compute SeasonalStrength to quantify the seasonal signal.');

  WriteLn(Format('  Seasonal strength: %.3f',
    [TTimeSeriesKit.SeasonalStrength(D)]));
end;

{ ============================================================
  SECTION 4 — Differencing & Stationarity (ADF test)
============================================================ }
procedure DemoStationarity;
var Y, D1: TDoubleArray;
    ADF: TADFResult;
begin
  WriteLn;
  WriteLn('=== STATIONARITY & DIFFERENCING ===');
  WriteLn('ARIMA and other models require a stationary series.');
  WriteLn('Use ADF test; if non-stationary, difference once and re-test.');
  Sep;

  { Trending series — clearly non-stationary }
  Y := MakeTrendySeasonal(60);
  ADF := TTimeSeriesKit.AugmentedDickeyFuller(Y, 1);
  WriteLn(Format('  Trending series: ADF stat=%.3f, critical(5%%)=%.3f, stationary=%s',
    [ADF.Statistic, ADF.Crit5Pct, BoolToStr(ADF.IsStationary, True)]));

  { After first differencing }
  D1  := TTimeSeriesKit.Difference(Y, 1);
  ADF := TTimeSeriesKit.AugmentedDickeyFuller(D1, 1);
  WriteLn(Format('  After diff(1):  ADF stat=%.3f, critical(5%%)=%.3f, stationary=%s',
    [ADF.Statistic, ADF.Crit5Pct, BoolToStr(ADF.IsStationary, True)]));

  WriteLn;
  WriteLn('  If ADF.IsStationary = True after d differences, use ARIMA(p,d,q).');
end;

{ ============================================================
  SECTION 5 — ACF & PACF (model order selection)
============================================================ }
procedure DemoACF_PACF;
var
  Y, Acf, Pacf: TDoubleArray;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== ACF & PACF (CHOOSING AR/MA ORDER) ===');
  WriteLn('AR(1) with phi=0.8. ACF decays geometrically; PACF cuts off at lag 1.');
  Sep;

  Y    := MakeAR1(200, 0.8);
  Acf  := TTimeSeriesKit.ACF(Y, 5);
  Pacf := TTimeSeriesKit.PACF(Y, 5);

  WriteLn('  ACF lags 0-5:');
  Write('    [');
  for I := 0 to 5 do
  begin
    if I > 0 then Write(', ');
    Write(Format('%.3f', [Acf[I]]));
  end;
  WriteLn(']');

  WriteLn('  PACF lags 0-5:');
  Write('    [');
  for I := 0 to 5 do
  begin
    if I > 0 then Write(', ');
    Write(Format('%.3f', [Pacf[I]]));
  end;
  WriteLn(']');

  WriteLn;
  WriteLn('  Interpretation guide:');
  WriteLn('  - ACF decays + PACF cuts off at lag p → AR(p)');
  WriteLn('  - ACF cuts off at lag q + PACF decays → MA(q)');
  WriteLn('  - Both decay → ARMA(p,q)');

  WriteLn(Format('  Ljung-Box Q(5) = %.3f  (>3.84 means not white noise)',
    [TTimeSeriesKit.LjungBox(Y, 5)]));
end;

{ ============================================================
  SECTION 6 — ARIMA fitting and forecasting
============================================================ }
procedure DemoARIMA;
var Y, Fcast: TDoubleArray;
    Model: TARIMAModel;
    I: Integer;
begin
  WriteLn;
  WriteLn('=== ARIMA(1,1,0) FIT + FORECAST ===');
  WriteLn('Trending series → difference once → fit AR(1) → undifference forecast.');
  Sep;

  { Build a simple linear trend: Y[t] = 2*t }
  SetLength(Y, 50);
  for I := 0 to 49 do Y[I] := 2.0 * I;

  Model := TTimeSeriesKit.ARIMAFit(Y, 1, 1, 0);
  WriteLn(Format('  AR(1) phi = %.4f  (expected ≈ 1.0 for a near-random-walk diff)',
    [Model.ARCoeffs[0]]));
  WriteLn(Format('  sigma² = %.6f', [Model.Sigma2]));

  Fcast := TTimeSeriesKit.ARIMAForecast(Model, Y, 5);
  WriteLn(Format('  Last observed: %.1f', [Y[High(Y)]]));
  ShowVec('5-step forecast', Fcast, 5);
  WriteLn('  (Should continue the trend, approximately 98, 100, 102, 104, 106)');
end;

{ ============================================================
  SECTION 7 — Change-point & Anomaly Detection
============================================================ }
procedure DemoAnomalyDetection;
var Y: TDoubleArray;
    CR: TCUSUMResult;
    Idx: TIntegerArray;
    I: Integer;
begin
  WriteLn;
  WriteLn('=== CHANGE-POINT & ANOMALY DETECTION ===');
  Sep;

  { --- CUSUM change-point --- }
  WriteLn('  CUSUM: series is 0 for t<50 then jumps to 5 for t>=50.');
  Y := MakeShiftSeries(100);
  CR := TTimeSeriesKit.CUSUMDetect(Y, 2.0);
  if CR.Detected then
    WriteLn(Format('  Change point detected at index %d  (true change at 50)',
      [CR.ChangePoint]))
  else
    WriteLn('  No change point detected.');

  { --- Z-score anomaly: inject outlier --- }
  WriteLn;
  WriteLn('  Z-score: inject outlier at index 30 into flat series.');
  SetLength(Y, 50);
  for I := 0 to 49 do Y[I] := I mod 3;
  Y[30] := 500.0;
  Idx := TTimeSeriesKit.ZScoreAnomalies(Y, 3.0);
  Write('  Anomaly indices: [');
  for I := 0 to High(Idx) do
  begin
    if I > 0 then Write(', ');
    Write(Idx[I]);
  end;
  WriteLn(']');

  { --- Rolling Z-score --- }
  WriteLn;
  WriteLn('  Rolling Z-score (window=10): catches local spikes.');
  SetLength(Y, 60);
  for I := 0 to 59 do Y[I] := 0.0;
  Y[40] := 20.0;
  Idx := TTimeSeriesKit.RollingZScore(Y, 10, 2.5);
  Write('  Rolling anomaly indices: [');
  for I := 0 to High(Idx) do
  begin
    if I > 0 then Write(', ');
    Write(Idx[I]);
  end;
  WriteLn(']');
  WriteLn('  (Should include index 40)');
end;

{ ============================================================
  SECTION 8 — Linear Trend & Detrending
============================================================ }
procedure DemoLinearTrend;
var Y, Detrended: TDoubleArray;
    T: TLinearTrend;
    I: Integer;
begin
  WriteLn;
  WriteLn('=== LINEAR TREND & DETRENDING ===');
  WriteLn('Fit y = a + b*t by OLS; then subtract to get residuals.');
  Sep;

  SetLength(Y, 20);
  for I := 0 to 19 do Y[I] := 3.0 + 2.0 * I + Sin(I);

  T := TTimeSeriesKit.LinearTrend(Y);
  WriteLn(Format('  Fitted:  y = %.3f + %.3f * t   R² = %.4f',
    [T.Intercept, T.Slope, T.RSquared]));
  WriteLn('  (True intercept = 3, slope = 2)');

  Detrended := TTimeSeriesKit.DetrendLinear(Y);
  ShowVec('Detrended residuals', Detrended, 8);
  WriteLn('  Residuals approximate Sin(t) after removing the linear trend.');
end;

{ ============================================================
  SECTION 9 — Periodogram (dominant period detection)
============================================================ }
procedure DemoPeriodogram;
var Y: TDoubleArray;
    Period: Integer;
    I: Integer;
begin
  WriteLn;
  WriteLn('=== PERIODOGRAM (DOMINANT PERIOD) ===');
  WriteLn('Pure cosine with period 8. Periodogram should detect period=8.');
  Sep;

  SetLength(Y, 128);
  for I := 0 to 127 do Y[I] := Cos(2 * Pi * I / 8.0);

  Period := TTimeSeriesKit.PeriodogramPeak(Y, 2, 64);
  WriteLn(Format('  Detected period = %d  (expected: 8)', [Period]));
  WriteLn;
  WriteLn('  Use this to automatically discover seasonality before');
  WriteLn('  setting Period in Holt-Winters or Decompose.');
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp — TimeSeriesLib Example');
  WriteLn('=====================================');

  DemoSmoothing;
  DemoHoltWinters;
  DemoDecomposition;
  DemoStationarity;
  DemoACF_PACF;
  DemoARIMA;
  DemoAnomalyDetection;
  DemoLinearTrend;
  DemoPeriodogram;

  WriteLn;
  WriteLn('Done.');
end.
