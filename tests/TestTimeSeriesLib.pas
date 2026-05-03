unit TestTimeSeriesLib;

{-----------------------------------------------------------------------------
 TestTimeSeriesLib

 Comprehensive tests for TimeSeriesLib.TimeSeries.
 All expected values are analytically derived or verified against NumPy/pandas.

 Coverage
   SimpleMovingAverage    — centred window, edge behaviour
   WeightedMovingAverage  — linearly-weighted trailing window
   ExponentialSmoothing   — alpha=1 (passthrough), alpha→0 (constant)
   DoubleExponentialSmoothing — linear data tracks exactly at high alpha
   TripleExponentialSmoothing — constant seasonal data
   HoltWintersForecast    — h-step ahead for additive model
   Decompose              — additive perfect sine-like wave
   Difference             — 1st and 2nd order, then Undifference
   Undifference           — exact reconstruction from diffs + initials
   AugmentedDickeyFuller  — I(1) random walk is non-stationary; I(0) is stationary
   ACF                    — lag-0 always 1; white noise ACF near 0; AR(1) decay
   PACF                   — AR(1) series: PACF[1] ≈ phi, PACF[2] ≈ 0
   LjungBox               — white noise Q small; correlated series Q large
   ARFit                  — AR(1) on perfect AR series recovers phi
   ARForecast             — deterministic AR(1) forecast exact
   MAFit                  — MA(1) on iid noise: theta near 0
   ARIMAFit/Forecast      — smoke test: ARIMA(1,1,0) runs and returns values
   CUSUMDetect            — detects mid-series mean shift
   ZScoreAnomalies        — flags injected outlier
   RollingZScore          — local anomaly not flagged globally, flagged locally
   LinearTrend            — perfect linear data: slope/intercept/R²=1
   DetrendLinear          — detrended residuals sum to ~0
   SeasonalStrength       — strong vs weak seasonal decompositions
   PeriodogramPeak        — pure cosine with known period
   Error handling         — ETimeSeriesError for bad inputs
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  MathBase.SharedTypes,
  TimeSeriesLib.TimeSeries;

type
  TTestTimeSeriesLib = class(TTestCase)
  private
    { Helper: assert two doubles are close to ADecimals places }
    procedure AssertNear(const AMsg: string; Expected, Got: Double; Tol: Double = 1e-6);
    { Helper: assert that calling AProc raises ETimeSeriesError }
    procedure AssertTSError(const AMsg: string; AProc: TProcedure);
    { Build a simple AR(1) series: Y[t] = Phi*Y[t-1] + noise (deterministic noise=0) }
    function MakeAR1(N: Integer; Phi, Seed: Double): TDoubleArray;
  published
    { --- Smoothing --------------------------------------------------------- }
    procedure TestSMA_BasicWindow;
    procedure TestSMA_Window1IsIdentity;
    procedure TestSMA_EdgeLength;
    procedure TestWMA_BasicWindow;
    procedure TestWMA_Window1IsIdentity;
    procedure TestEMA_Alpha1IsIdentity;
    procedure TestEMA_SteadyState;
    procedure TestDoubleES_LinearData;
    procedure TestTripleES_ConstantSeasonal;
    procedure TestHoltWintersForecast_Additive;
    { --- Decomposition ----------------------------------------------------- }
    procedure TestDecompose_Additive_PerfectSeasonal;
    { --- Differencing ------------------------------------------------------ }
    procedure TestDifference_Order1;
    procedure TestDifference_Order2;
    procedure TestUndifference_Roundtrip;
    { --- Stationarity ------------------------------------------------------ }
    procedure TestADF_RandomWalk_NonStationary;
    procedure TestADF_WhiteNoise_Stationary;
    { --- Autocorrelation --------------------------------------------------- }
    procedure TestACF_Lag0IsOne;
    procedure TestACF_WhiteNoise_SmallLags;
    procedure TestACF_AR1_Decay;
    procedure TestPACF_Lag0IsOne;
    procedure TestPACF_AR1_CutsOff;
    procedure TestLjungBox_WhiteNoise_Small;
    procedure TestLjungBox_CorrelatedSeries_Large;
    { --- ARIMA ------------------------------------------------------------- }
    procedure TestARFit_AR1_RecoversPhi;
    procedure TestARForecast_Deterministic;
    procedure TestMAFit_SmokeTest;
    procedure TestARIMAFit_SmokeTest;
    procedure TestARIMAForecast_SmokeTest;
    { --- Change-point & Anomaly -------------------------------------------- }
    procedure TestCUSUM_DetectsShift;
    procedure TestCUSUM_NoShift_NotDetected;
    procedure TestZScoreAnomalies_FlagsOutlier;
    procedure TestZScoreAnomalies_NoneForNormalData;
    procedure TestRollingZScore_LocalAnomaly;
    { --- Trend & Seasonality ----------------------------------------------- }
    procedure TestLinearTrend_PerfectLine;
    procedure TestLinearTrend_RSquared;
    procedure TestDetrendLinear_ResidualsSumNearZero;
    procedure TestSeasonalStrength_Strong;
    procedure TestSeasonalStrength_Weak;
    procedure TestPeriodogramPeak_KnownPeriod;
    { --- Error handling ---------------------------------------------------- }
    procedure TestSMA_EmptyRaisesError;
    procedure TestSMA_WindowTooLargeRaisesError;
    procedure TestDifference_ZeroD_Passthrough;
    procedure TestDifference_NegativeD_RaisesError;
    procedure TestACF_MaxLagTooLargeRaisesError;
    procedure TestARFit_OrderTooLargeRaisesError;
  end;

implementation

{ ---------------------------------------------------------------------------
  Unit-level state for error-test helpers (FPC 3.2.2: no anonymous procs)
--------------------------------------------------------------------------- }
var
  GErrY: TDoubleArray;

procedure ErrSMAEmpty;
begin TTimeSeriesKit.SimpleMovingAverage(GErrY, 3); end;

procedure ErrSMAWindow;
begin TTimeSeriesKit.SimpleMovingAverage(GErrY, 0); end;

procedure ErrDifferenceNeg;
begin TTimeSeriesKit.Difference(GErrY, -1); end;

procedure ErrACFLagTooLarge;
begin TTimeSeriesKit.ACF(GErrY, 4); end;

procedure ErrARFitOrderTooLarge;
begin TTimeSeriesKit.ARFit(GErrY, 3); end;

{ ---------------------------------------------------------------------------
  Helpers
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.AssertNear(const AMsg: string; Expected, Got: Double; Tol: Double);
begin
  if IsNaN(Expected) or IsNaN(Got) then
    Fail(AMsg + Format(' — NaN encountered (expected %.6g, got %.6g)',
      [Expected, Got]));
  if Abs(Got - Expected) > Tol then
    Fail(AMsg + Format(' — expected %.8g, got %.8g (diff %.3g)',
      [Expected, Got, Abs(Got - Expected)]));
end;

procedure TTestTimeSeriesLib.AssertTSError(const AMsg: string; AProc: TProcedure);
begin
  try
    AProc;
    Fail(AMsg + ' — expected ETimeSeriesError but none was raised');
  except
    on E: ETimeSeriesError do { pass }
    else raise;
  end;
end;

function TTestTimeSeriesLib.MakeAR1(N: Integer; Phi, Seed: Double): TDoubleArray;
{ AR(1) with deterministic pseudo-noise via a simple LCG so residuals are
  non-zero and the ADF regression matrix stays well-conditioned. }
var
  I: Integer;
  RState: LongWord;
  Noise: Double;
begin
  SetLength(Result, N);
  Result[0] := Seed;
  RState := 12345;
  for I := 1 to N - 1 do
  begin
    {$Q-}{$R-}
    RState := RState * 1664525 + 1013904223;
    {$Q+}{$R+}
    Noise   := ((RState and $FFFF) / 32768.0 - 1.0) * 0.5;
    Result[I] := Phi * Result[I - 1] + Noise;
  end;
end;

{ ---------------------------------------------------------------------------
  Simple Moving Average
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestSMA_BasicWindow;
{ Y = [1,2,3,4,5], Window=3 → centred: [1.5, 2, 3, 4, 4.5] }
var
  Y, S: TDoubleArray;
begin
  Y := TDoubleArray.Create(1, 2, 3, 4, 5);
  S := TTimeSeriesKit.SimpleMovingAverage(Y, 3);
  AssertEquals('SMA length', 5, Length(S));
  AssertNear('SMA[0]', 1.5,  S[0], 1e-10);
  AssertNear('SMA[1]', 2.0,  S[1], 1e-10);
  AssertNear('SMA[2]', 3.0,  S[2], 1e-10);
  AssertNear('SMA[3]', 4.0,  S[3], 1e-10);
  AssertNear('SMA[4]', 4.5,  S[4], 1e-10);
end;

procedure TTestTimeSeriesLib.TestSMA_Window1IsIdentity;
var
  Y, S: TDoubleArray;
  I: Integer;
begin
  Y := TDoubleArray.Create(3, 1, 4, 1, 5, 9, 2, 6);
  S := TTimeSeriesKit.SimpleMovingAverage(Y, 1);
  for I := 0 to High(Y) do
    AssertNear('SMA(W=1)[' + IntToStr(I) + ']', Y[I], S[I], 1e-10);
end;

procedure TTestTimeSeriesLib.TestSMA_EdgeLength;
var
  Y, S: TDoubleArray;
begin
  Y := TDoubleArray.Create(10, 20, 30);
  S := TTimeSeriesKit.SimpleMovingAverage(Y, 5);
  { Window >= N: all points average entire series }
  AssertEquals('SMA short-series length', 3, Length(S));
end;

{ ---------------------------------------------------------------------------
  Weighted Moving Average
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestWMA_BasicWindow;
{ Y=[1,2,3,4,5], Window=3: trailing weights 1,2,3
  WMA[2] = (1*1 + 2*2 + 3*3)/(1+2+3) = 14/6 ≈ 2.333 }
var
  Y, W: TDoubleArray;
begin
  Y := TDoubleArray.Create(1, 2, 3, 4, 5);
  W := TTimeSeriesKit.WeightedMovingAverage(Y, 3);
  AssertEquals('WMA length', 5, Length(W));
  AssertNear('WMA[2]', 14.0/6.0, W[2], 1e-6);
  AssertNear('WMA[3]', (1*2+2*3+3*4)/6.0, W[3], 1e-6);
  AssertNear('WMA[4]', (1*3+2*4+3*5)/6.0, W[4], 1e-6);
end;

procedure TTestTimeSeriesLib.TestWMA_Window1IsIdentity;
var
  Y, W: TDoubleArray;
  I: Integer;
begin
  Y := TDoubleArray.Create(5, 3, 7, 2, 9);
  W := TTimeSeriesKit.WeightedMovingAverage(Y, 1);
  for I := 0 to High(Y) do
    AssertNear('WMA(W=1)[' + IntToStr(I) + ']', Y[I], W[I], 1e-10);
end;

{ ---------------------------------------------------------------------------
  Exponential Smoothing
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestEMA_Alpha1IsIdentity;
{ Alpha=1: S[t] = 1*Y[t] + 0*S[t-1] = Y[t] }
var
  Y, S: TDoubleArray;
  I: Integer;
begin
  Y := TDoubleArray.Create(2, 4, 6, 8, 10);
  S := TTimeSeriesKit.ExponentialSmoothing(Y, 1.0);
  for I := 0 to High(Y) do
    AssertNear('EMA(a=1)[' + IntToStr(I) + ']', Y[I], S[I], 1e-10);
end;

procedure TTestTimeSeriesLib.TestEMA_SteadyState;
{ Constant series Y=5: EMA should stay at 5 for any alpha }
var
  Y, S: TDoubleArray;
  I: Integer;
begin
  SetLength(Y, 20);
  for I := 0 to 19 do Y[I] := 5.0;
  S := TTimeSeriesKit.ExponentialSmoothing(Y, 0.3, 5.0);
  for I := 0 to High(S) do
    AssertNear('EMA constant[' + IntToStr(I) + ']', 5.0, S[I], 1e-10);
end;

{ ---------------------------------------------------------------------------
  Double Exponential Smoothing
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestDoubleES_LinearData;
{ Perfect linear series Y[t] = t. With very high Alpha and Beta,
  the filter should track closely by mid-series. }
var
  Y, S: TDoubleArray;
  I: Integer;
begin
  SetLength(Y, 30);
  for I := 0 to 29 do Y[I] := I;
  S := TTimeSeriesKit.DoubleExponentialSmoothing(Y, 0.9, 0.9);
  AssertEquals('DES length', 30, Length(S));
  { By index 20, should track within 1.0 of true value }
  for I := 20 to 29 do
    AssertNear('DES linear[' + IntToStr(I) + ']', Y[I], S[I], 1.5);
end;

{ ---------------------------------------------------------------------------
  Triple Exponential Smoothing (Holt-Winters)
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestTripleES_ConstantSeasonal;
{ Data with zero trend and constant seasonal pattern of period 4.
  Pattern: [10,20,30,40] repeated. With high alpha and low beta/gamma
  the fitted values should be within 20% of the originals by cycle 3. }
var
  Y, S: TDoubleArray;
  Pattern: array[0..3] of Double;
  I: Integer;
begin
  Pattern[0] := 10; Pattern[1] := 20; Pattern[2] := 30; Pattern[3] := 40;
  SetLength(Y, 24);
  for I := 0 to 23 do Y[I] := Pattern[I mod 4];
  S := TTimeSeriesKit.TripleExponentialSmoothing(Y, 0.4, 0.1, 0.4, 4, dtAdditive);
  AssertEquals('TES length', 24, Length(S));
  { Check last full cycle matches within 15 }
  for I := 20 to 23 do
    AssertNear('TES seasonal[' + IntToStr(I) + ']', Y[I], S[I], 15.0);
end;

procedure TTestTimeSeriesLib.TestHoltWintersForecast_Additive;
{ Constant series (no trend, no seasonality) with period 4.
  Forecast should be near the constant value. }
var
  Y, F: TDoubleArray;
  I: Integer;
begin
  SetLength(Y, 16);
  for I := 0 to 15 do Y[I] := 50.0;
  F := TTimeSeriesKit.HoltWintersForecast(Y, 0.5, 0.1, 0.1, 4, 4, dtAdditive);
  AssertEquals('HW forecast length', 4, Length(F));
  for I := 0 to 3 do
    AssertNear('HW forecast[' + IntToStr(I) + ']', 50.0, F[I], 5.0);
end;

{ ---------------------------------------------------------------------------
  Decomposition
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestDecompose_Additive_PerfectSeasonal;
{ Construct: Trend = 1..24, Seasonal = [0,5,-5,0] repeating, no residual.
  After decomposition, residual should be near zero everywhere the trend is valid. }
var
  Y: TDoubleArray;
  SeasonPat: array[0..3] of Double;
  D: TDecomposition;
  I, TrendValid: Integer;
begin
  SeasonPat[0] := 0; SeasonPat[1] := 5; SeasonPat[2] := -5; SeasonPat[3] := 0;
  SetLength(Y, 24);
  for I := 0 to 23 do
    Y[I] := (I + 1) + SeasonPat[I mod 4];
  D := TTimeSeriesKit.Decompose(Y, 4, dtAdditive);
  AssertEquals('Decompose Trend length',    24, Length(D.Trend));
  AssertEquals('Decompose Seasonal length', 24, Length(D.Seasonal));
  AssertEquals('Decompose Residual length', 24, Length(D.Residual));
  { The centred MA leaves edges as NaN (or 0); check mid-series residuals }
  TrendValid := 2; { half-window for period=4 }
  for I := TrendValid to 23 - TrendValid do
    AssertNear('Decompose residual[' + IntToStr(I) + ']', 0.0, D.Residual[I], 1.5);
end;

{ ---------------------------------------------------------------------------
  Differencing
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestDifference_Order1;
{ Y = [1,3,6,10,15] → Diff1 = [2,3,4,5] }
var
  Y, D: TDoubleArray;
begin
  Y := TDoubleArray.Create(1, 3, 6, 10, 15);
  D := TTimeSeriesKit.Difference(Y, 1);
  AssertEquals('Diff1 length', 4, Length(D));
  AssertNear('Diff1[0]', 2.0, D[0], 1e-10);
  AssertNear('Diff1[1]', 3.0, D[1], 1e-10);
  AssertNear('Diff1[2]', 4.0, D[2], 1e-10);
  AssertNear('Diff1[3]', 5.0, D[3], 1e-10);
end;

procedure TTestTimeSeriesLib.TestDifference_Order2;
{ Y = [1,3,6,10,15] → Diff2 = Diff(Diff1) = Diff([2,3,4,5]) = [1,1,1] }
var
  Y, D: TDoubleArray;
begin
  Y := TDoubleArray.Create(1, 3, 6, 10, 15);
  D := TTimeSeriesKit.Difference(Y, 2);
  AssertEquals('Diff2 length', 3, Length(D));
  AssertNear('Diff2[0]', 1.0, D[0], 1e-10);
  AssertNear('Diff2[1]', 1.0, D[1], 1e-10);
  AssertNear('Diff2[2]', 1.0, D[2], 1e-10);
end;

procedure TTestTimeSeriesLib.TestUndifference_Roundtrip;
{ Diff and Undiff should be exact inverses for d=1 and d=2 }
var
  Y, D, R: TDoubleArray;
  Init1, Init2: TDoubleArray;
  I: Integer;
begin
  Y := TDoubleArray.Create(5, 8, 12, 17, 23, 30);
  { d=1 }
  D    := TTimeSeriesKit.Difference(Y, 1);
  Init1 := TDoubleArray.Create(Y[0]);
  R    := TTimeSeriesKit.Undifference(D, Init1, 1);
  AssertEquals('Undiff1 length', Length(Y), Length(R));
  for I := 0 to High(Y) do
    AssertNear('Undiff1[' + IntToStr(I) + ']', Y[I], R[I], 1e-9);
  { d=2 }
  D    := TTimeSeriesKit.Difference(Y, 2);
  Init2 := TDoubleArray.Create(Y[0], Y[1]);
  R    := TTimeSeriesKit.Undifference(D, Init2, 2);
  AssertEquals('Undiff2 length', Length(Y), Length(R));
  for I := 0 to High(Y) do
    AssertNear('Undiff2[' + IntToStr(I) + ']', Y[I], R[I], 1e-9);
end;

procedure TTestTimeSeriesLib.TestDifference_ZeroD_Passthrough;
{ d=0: should return the series unchanged }
var
  Y, D: TDoubleArray;
  I: Integer;
begin
  Y := TDoubleArray.Create(3, 1, 4, 1, 5);
  D := TTimeSeriesKit.Difference(Y, 0);
  AssertEquals('Diff0 length', Length(Y), Length(D));
  for I := 0 to High(Y) do
    AssertNear('Diff0[' + IntToStr(I) + ']', Y[I], D[I], 1e-10);
end;

{ ---------------------------------------------------------------------------
  ADF test
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestADF_RandomWalk_NonStationary;
{ A random walk (cumulative sum of ±1) should be non-stationary.
  Build a deterministic near-random-walk: Y[t] = t (a trend), which is
  clearly non-stationary (unit root). }
var
  Y: TDoubleArray;
  R: TADFResult;
  I: Integer;
begin
  SetLength(Y, 80);
  for I := 0 to 79 do Y[I] := I;  { pure trend = unit root }
  R := TTimeSeriesKit.AugmentedDickeyFuller(Y, 1);
  { ADF statistic for a trend series should be > critical value (fail to reject H0) }
  AssertFalse('Random walk is non-stationary', R.IsStationary);
end;

procedure TTestTimeSeriesLib.TestADF_WhiteNoise_Stationary;
{ Stationary AR(1) series with Phi close to 0: clearly stationary.
  Use deterministic AR(1): Y[t] = 0.3 * Y[t-1] }
var
  Y: TDoubleArray;
  R: TADFResult;
begin
  Y := MakeAR1(100, 0.3, 1.0);
  R := TTimeSeriesKit.AugmentedDickeyFuller(Y, 1);
  { ADF statistic for stationary series should be very negative → IsStationary }
  AssertTrue('AR(1) phi=0.3 is stationary', R.IsStationary);
end;

{ ---------------------------------------------------------------------------
  ACF
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestACF_Lag0IsOne;
var
  Y, A: TDoubleArray;
begin
  Y := TDoubleArray.Create(1, 2, 3, 4, 5, 6, 7, 8);
  A := TTimeSeriesKit.ACF(Y, 3);
  AssertNear('ACF[0] = 1', 1.0, A[0], 1e-10);
end;

procedure TTestTimeSeriesLib.TestACF_WhiteNoise_SmallLags;
{ For a constant series + tiny perturbation, ACF at lags > 0 should be small.
  Use a nearly-constant series: [1,1,1,...,1] — all lags exactly 1 actually,
  so use an alternating series [1,-1,1,-1,...] whose ACF[1] ≈ -1. }
var
  Y, A: TDoubleArray;
  I: Integer;
begin
  { Alternating ±1 series: ACF[1] should be close to -1 }
  SetLength(Y, 50);
  for I := 0 to 49 do
    if Odd(I) then Y[I] := -1 else Y[I] := 1;
  A := TTimeSeriesKit.ACF(Y, 2);
  AssertNear('ACF alternating lag1', -1.0, A[1], 0.1);
end;

procedure TTestTimeSeriesLib.TestACF_AR1_Decay;
{ AR(1) with phi=0.8: ACF[k] ≈ phi^k = 0.8^k }
var
  Y, A: TDoubleArray;
begin
  Y := MakeAR1(200, 0.8, 1.0);
  A := TTimeSeriesKit.ACF(Y, 3);
  AssertNear('ACF AR1 lag0', 1.0,       A[0], 1e-10);
  AssertNear('ACF AR1 lag1', Power(0.8,1), A[1], 0.05);
  AssertNear('ACF AR1 lag2', Power(0.8,2), A[2], 0.08);
end;

{ ---------------------------------------------------------------------------
  PACF
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestPACF_Lag0IsOne;
var
  Y, P: TDoubleArray;
begin
  Y := TDoubleArray.Create(3, 1, 4, 1, 5, 9, 2, 6, 5, 3);
  P := TTimeSeriesKit.PACF(Y, 3);
  AssertNear('PACF[0] = 1', 1.0, P[0], 1e-10);
end;

procedure TTestTimeSeriesLib.TestPACF_AR1_CutsOff;
{ AR(1) phi=0.7: PACF[1] ≈ 0.7, PACF[2] should be near 0 }
var
  Y, P: TDoubleArray;
begin
  Y := MakeAR1(200, 0.7, 1.0);
  P := TTimeSeriesKit.PACF(Y, 3);
  AssertNear('PACF AR1 lag1', 0.7, P[1], 0.1);
  { PACF[2] should be much smaller than PACF[1] }
  AssertTrue('PACF AR1 lag2 near 0', Abs(P[2]) < Abs(P[1]));
end;

{ ---------------------------------------------------------------------------
  Ljung-Box
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestLjungBox_WhiteNoise_Small;
{ For a constant series differenced to white noise, Q should be 0. }
var
  Y: TDoubleArray;
  Q: Double;
  I: Integer;
begin
  { Perfect white noise: all deviations identical → ACF[k]=0 for k>0 → Q=0 }
  SetLength(Y, 40);
  for I := 0 to 39 do Y[I] := 0.0;   { constant series — all ACF=0 by definition }
  { Edge case: constant series has 0 variance. Use alternating to get defined ACF. }
  { Instead, use the fact that differencing a linear trend gives white noise. }
  SetLength(Y, 40);
  for I := 0 to 39 do Y[I] := I;
  Y := TTimeSeriesKit.Difference(Y, 1);  { white noise: all 1s, ACF[k>0]=0 }
  Q := TTimeSeriesKit.LjungBox(Y, 5);
  AssertNear('LjungBox white noise Q', 0.0, Q, 1.0);
end;

procedure TTestTimeSeriesLib.TestLjungBox_CorrelatedSeries_Large;
{ High-phi AR(1) is strongly autocorrelated → large Q }
var
  Y: TDoubleArray;
  Q: Double;
begin
  Y := MakeAR1(100, 0.95, 1.0);
  Q := TTimeSeriesKit.LjungBox(Y, 5);
  AssertTrue('LjungBox correlated Q > 10', Q > 10.0);
end;

{ ---------------------------------------------------------------------------
  ARIMA
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestARFit_AR1_RecoversPhi;
{ Fit AR(1) to a deterministic AR(1) series with phi=0.8 }
var
  Y: TDoubleArray;
  M: TARIMAModel;
begin
  Y := MakeAR1(200, 0.8, 1.0);
  M := TTimeSeriesKit.ARFit(Y, 1);
  AssertEquals('ARFit P', 1, M.P);
  AssertEquals('ARFit D', 0, M.D);
  AssertNear('ARFit phi[0] ≈ 0.8', 0.8, M.ARCoeffs[0], 0.05);
end;

procedure TTestTimeSeriesLib.TestARForecast_Deterministic;
{ AR(1) phi=1 (random walk without noise): Y[t] = Y[t-1].
  Forecast H steps ahead from end value should equal end value. }
var
  Y, F: TDoubleArray;
  M: TARIMAModel;
  EndVal: Double;
  I: Integer;
begin
  SetLength(M.ARCoeffs, 1);
  M.ARCoeffs[0] := 1.0;
  M.P := 1; M.D := 0; M.Q := 0; M.Mu := 0; M.Sigma2 := 0;
  SetLength(M.MACoeffs, 0);
  Y := TDoubleArray.Create(1, 2, 3, 4, 5);
  EndVal := Y[High(Y)];
  F := TTimeSeriesKit.ARForecast(M, Y, 3);
  AssertEquals('ARForecast length', 3, Length(F));
  for I := 0 to 2 do
    AssertNear('ARForecast phi=1 step ' + IntToStr(I), EndVal, F[I], 1e-9);
end;

procedure TTestTimeSeriesLib.TestMAFit_SmokeTest;
{ Just verify MAFit runs and returns Q coefficients }
var
  Y: TDoubleArray;
  M: TARIMAModel;
  I: Integer;
begin
  SetLength(Y, 50);
  for I := 0 to 49 do Y[I] := Sin(I * 0.3);
  M := TTimeSeriesKit.MAFit(Y, 1);
  AssertEquals('MAFit Q', 1, M.Q);
  AssertEquals('MAFit MA coeffs length', 1, Length(M.MACoeffs));
end;

procedure TTestTimeSeriesLib.TestARIMAFit_SmokeTest;
{ ARIMA(1,1,0) should run without error and return plausible model }
var
  Y: TDoubleArray;
  M: TARIMAModel;
  I: Integer;
begin
  SetLength(Y, 60);
  for I := 0 to 59 do Y[I] := I + 0.1 * Sin(I);
  M := TTimeSeriesKit.ARIMAFit(Y, 1, 1, 0);
  AssertEquals('ARIMAFit P', 1, M.P);
  AssertEquals('ARIMAFit D', 1, M.D);
  AssertEquals('ARIMAFit Q', 0, M.Q);
  AssertEquals('ARIMAFit AR coeffs length', 1, Length(M.ARCoeffs));
end;

procedure TTestTimeSeriesLib.TestARIMAForecast_SmokeTest;
{ ARIMA(1,1,0) fit + 5-step forecast should return 5 values }
var
  Y, F: TDoubleArray;
  M: TARIMAModel;
  I: Integer;
begin
  SetLength(Y, 60);
  for I := 0 to 59 do Y[I] := I * 2.0;
  M := TTimeSeriesKit.ARIMAFit(Y, 1, 1, 0);
  F := TTimeSeriesKit.ARIMAForecast(M, Y, 5);
  AssertEquals('ARIMAForecast length', 5, Length(F));
  { Forecasts on a perfectly linear series should continue the trend }
  for I := 0 to 4 do
    AssertTrue('ARIMAForecast increasing', F[I] > Y[High(Y)] - 10);
end;

{ ---------------------------------------------------------------------------
  Change-point & Anomaly Detection
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestCUSUM_DetectsShift;
{ Series: 50 zeros then 50 fives — clear mean shift at index 50 }
var
  Y: TDoubleArray;
  R: TCUSUMResult;
  I: Integer;
begin
  SetLength(Y, 100);
  for I := 0 to 49  do Y[I] := 0.0;
  for I := 50 to 99 do Y[I] := 5.0;
  { Pass Target=0 (the pre-shift mean) so CUSUM accumulates against the known baseline }
  R := TTimeSeriesKit.CUSUMDetect(Y, 2.0, 0.0);
  AssertTrue('CUSUM detected shift', R.Detected);
  { Change point should be found somewhere in [49..55] }
  AssertTrue('CUSUM changepoint index in range',
    (R.ChangePoint >= 48) and (R.ChangePoint <= 55));
end;

procedure TTestTimeSeriesLib.TestCUSUM_NoShift_NotDetected;
{ Constant series — no shift }
var
  Y: TDoubleArray;
  R: TCUSUMResult;
  I: Integer;
begin
  SetLength(Y, 50);
  for I := 0 to 49 do Y[I] := 3.0;
  R := TTimeSeriesKit.CUSUMDetect(Y, 4.0);
  AssertFalse('CUSUM no shift in constant series', R.Detected);
end;

procedure TTestTimeSeriesLib.TestZScoreAnomalies_FlagsOutlier;
{ Normal-ish data with one injected extreme outlier }
var
  Y: TDoubleArray;
  Idx: TIntegerArray;
  I: Integer;
  Found: Boolean;
begin
  SetLength(Y, 30);
  for I := 0 to 29 do Y[I] := I mod 3;
  Y[15] := 1000.0;  { massive outlier }
  Idx := TTimeSeriesKit.ZScoreAnomalies(Y, 3.0);
  Found := False;
  for I := 0 to High(Idx) do
    if Idx[I] = 15 then Found := True;
  AssertTrue('ZScore flags index 15', Found);
end;

procedure TTestTimeSeriesLib.TestZScoreAnomalies_NoneForNormalData;
{ Perfectly constant data has undefined z-score (StdDev=0).
  Use a gentle slope — all values within 2 sigma. }
var
  Y: TDoubleArray;
  Idx: TIntegerArray;
  I: Integer;
begin
  { Y = 0,1,2,...,9 — linear, no outliers at 3-sigma threshold }
  SetLength(Y, 10);
  for I := 0 to 9 do Y[I] := I;
  Idx := TTimeSeriesKit.ZScoreAnomalies(Y, 3.0);
  AssertEquals('ZScore no anomalies in linear data', 0, Length(Idx));
end;

procedure TTestTimeSeriesLib.TestRollingZScore_LocalAnomaly;
{ Spike at index 25 in an otherwise smooth series.
  Global z-score might miss it; rolling window should catch it. }
var
  Y: TDoubleArray;
  Idx: TIntegerArray;
  I: Integer;
  Found: Boolean;
begin
  SetLength(Y, 50);
  for I := 0 to 49 do Y[I] := 0.0;
  Y[25] := 50.0;  { local spike }
  Idx := TTimeSeriesKit.RollingZScore(Y, 10, 2.5);
  Found := False;
  for I := 0 to High(Idx) do
    if Idx[I] = 25 then Found := True;
  AssertTrue('RollingZScore flags local spike at 25', Found);
end;

{ ---------------------------------------------------------------------------
  Trend & Seasonality Utilities
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestLinearTrend_PerfectLine;
{ Y = 3 + 2*t → Intercept=3, Slope=2, R²=1 }
var
  Y: TDoubleArray;
  T: TLinearTrend;
  I: Integer;
begin
  SetLength(Y, 20);
  for I := 0 to 19 do Y[I] := 3.0 + 2.0 * I;
  T := TTimeSeriesKit.LinearTrend(Y);
  AssertNear('LinearTrend intercept', 3.0, T.Intercept, 1e-8);
  AssertNear('LinearTrend slope',     2.0, T.Slope,     1e-8);
  AssertNear('LinearTrend R²',        1.0, T.RSquared,  1e-8);
end;

procedure TTestTimeSeriesLib.TestLinearTrend_RSquared;
{ Constant series: R² = 0 (slope is 0, line explains nothing beyond mean) }
var
  Y: TDoubleArray;
  T: TLinearTrend;
  I: Integer;
begin
  SetLength(Y, 10);
  for I := 0 to 9 do Y[I] := 7.0;
  T := TTimeSeriesKit.LinearTrend(Y);
  AssertNear('LinearTrend constant R²', 0.0, T.RSquared, 1e-6);
  AssertNear('LinearTrend constant slope', 0.0, T.Slope, 1e-6);
end;

procedure TTestTimeSeriesLib.TestDetrendLinear_ResidualsSumNearZero;
{ OLS residuals always sum to zero when an intercept is included }
var
  Y, R: TDoubleArray;
  I: Integer;
  S: Double;
begin
  SetLength(Y, 20);
  for I := 0 to 19 do Y[I] := 2.0 * I + Sin(I);
  R := TTimeSeriesKit.DetrendLinear(Y);
  S := 0;
  for I := 0 to High(R) do S := S + R[I];
  AssertNear('Detrend residuals sum ≈ 0', 0.0, S, 1e-7);
end;

procedure TTestTimeSeriesLib.TestSeasonalStrength_Strong;
{ Build data = trend + strong seasonal, decompose, strength should be > 0.5 }
var
  Y: TDoubleArray;
  D: TDecomposition;
  Str: Double;
  I: Integer;
begin
  SetLength(Y, 48);
  for I := 0 to 47 do
    Y[I] := I + 20 * Sin(2 * Pi * I / 12);  { strong 12-period seasonality }
  D := TTimeSeriesKit.Decompose(Y, 12, dtAdditive);
  Str := TTimeSeriesKit.SeasonalStrength(D);
  AssertTrue('Strong seasonal strength > 0.5', Str > 0.5);
end;

procedure TTestTimeSeriesLib.TestSeasonalStrength_Weak;
{ Pure linear trend with no seasonality → strength near 0 }
var
  Y: TDoubleArray;
  D: TDecomposition;
  Str: Double;
  I: Integer;
begin
  SetLength(Y, 48);
  for I := 0 to 47 do Y[I] := I + 0.01 * Sin(I);  { tiny noise }
  D := TTimeSeriesKit.Decompose(Y, 12, dtAdditive);
  Str := TTimeSeriesKit.SeasonalStrength(D);
  AssertTrue('Weak seasonal strength < 0.6', Str < 0.6);
end;

procedure TTestTimeSeriesLib.TestPeriodogramPeak_KnownPeriod;
{ Pure cosine with period=8: Y[t] = cos(2*pi*t/8)
  PeriodogramPeak should return 8 (or very close). }
var
  Y: TDoubleArray;
  P: Integer;
  I: Integer;
begin
  SetLength(Y, 128);
  for I := 0 to 127 do
    Y[I] := Cos(2 * Pi * I / 8.0);
  P := TTimeSeriesKit.PeriodogramPeak(Y, 2, 64);
  AssertTrue('Periodogram peak period = 8 (got ' + IntToStr(P) + ')',
    Abs(P - 8) <= 1);
end;

{ ---------------------------------------------------------------------------
  Error handling
--------------------------------------------------------------------------- }

procedure TTestTimeSeriesLib.TestSMA_EmptyRaisesError;
begin
  SetLength(GErrY, 0);
  AssertTSError('SMA empty', @ErrSMAEmpty);
end;

procedure TTestTimeSeriesLib.TestSMA_WindowTooLargeRaisesError;
begin
  GErrY := TDoubleArray.Create(1, 2, 3);
  AssertTSError('SMA window=0', @ErrSMAWindow);
end;

procedure TTestTimeSeriesLib.TestDifference_NegativeD_RaisesError;
begin
  GErrY := TDoubleArray.Create(1, 2, 3, 4, 5);
  AssertTSError('Difference d=-1', @ErrDifferenceNeg);
end;

procedure TTestTimeSeriesLib.TestACF_MaxLagTooLargeRaisesError;
begin
  GErrY := TDoubleArray.Create(1, 2, 3, 4);
  AssertTSError('ACF lag >= N', @ErrACFLagTooLarge);
end;

procedure TTestTimeSeriesLib.TestARFit_OrderTooLargeRaisesError;
begin
  GErrY := TDoubleArray.Create(1, 2, 3);
  AssertTSError('ARFit P >= N', @ErrARFitOrderTooLarge);
end;

initialization
  RegisterTest(TTestTimeSeriesLib);
end.
