unit TimeSeriesLib.TimeSeries;

{-----------------------------------------------------------------------------
 TimeSeriesLib.TimeSeries

 Time series analysis for Free Pascal.
 No external dependencies — only MathBase and the RTL.

 What this library gives you
 ---------------------------
 Smoothing & Filtering
   SimpleMovingAverage    — equal-weight rolling window
   WeightedMovingAverage  — linearly-weighted rolling window
   ExponentialSmoothing   — simple EMA (alpha parameter)
   DoubleExponentialSmoothing (Holt's method) — level + trend
   TripleExponentialSmoothing (Holt-Winters)  — level + trend + seasonality

 Decomposition
   Decompose              — additive/multiplicative trend+seasonal+residual

 Differencing & Stationarity
   Difference             — d-th order differencing
   Undifference           — invert differencing given initial values
   AugmentedDickeyFuller  — unit root test statistic (ADF test)

 Autocorrelation
   ACF                    — autocorrelation function up to MaxLag
   PACF                   — partial autocorrelation (Yule-Walker equations)
   LjungBox               — Ljung-Box Q test for white noise

 ARIMA models
   ARFit                  — fit AR(p) model via Yule-Walker
   ARForecast             — forecast from AR coefficients
   MAFit                  — fit MA(q) model via method-of-moments
   ARIMAFit               — fit ARIMA(p,d,q) model
   ARIMAForecast          — h-step ahead forecast from ARIMA model

 Change-point & Anomaly Detection
   CUSUMDetect            — cumulative sum control chart
   ZScoreAnomalies        — flag points > threshold standard deviations from mean
   RollingZScore          — rolling z-score anomaly detection

 Trend & Seasonality Utilities
   LinearTrend            — fit y = a + b*t by OLS; return slope + intercept
   DetrendLinear          — subtract the fitted linear trend
   SeasonalStrength       — max(0, 1 - var(residual)/var(seasonal+residual))
   PeriodogramPeak        — dominant-period estimate from FFT power spectrum

 Result records
   TDecomposition         — Trend, Seasonal, Residual arrays
   TARIMAModel            — AR/MA coefficients, d, sigma²
   TLinearTrend           — Intercept, Slope, RSquared
   TADFResult             — Statistic, CriticalValues, IsStationary

 All methods are static on TTimeSeriesKit — no object creation needed.
 Raises ETimeSeriesError for invalid inputs.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

type
  { Raised for invalid time series inputs }
  ETimeSeriesError = class(Exception);

  { Additive or multiplicative decomposition type }
  TDecompType = (dtAdditive, dtMultiplicative);

  { Result of Decompose }
  TDecomposition = record
    Trend:    TDoubleArray;  { smoothed trend component }
    Seasonal: TDoubleArray;  { repeating seasonal component }
    Residual: TDoubleArray;  { remainder = observed - trend - seasonal (additive) }
    DecompType: TDecompType;
  end;

  { Fitted linear trend }
  TLinearTrend = record
    Intercept: Double;  { a in y = a + b*t }
    Slope:     Double;  { b (units per time step) }
    RSquared:  Double;  { coefficient of determination }
  end;

  { ARIMA(p,d,q) model }
  TARIMAModel = record
    ARCoeffs: TDoubleArray;  { phi_1 .. phi_p }
    MACoeffs: TDoubleArray;  { theta_1 .. theta_q }
    D:        Integer;        { integration order }
    Mu:       Double;         { mean of the differenced series }
    Sigma2:   Double;         { innovation variance }
    P:        Integer;        { AR order }
    Q:        Integer;        { MA order }
  end;

  { Augmented Dickey-Fuller test result }
  TADFResult = record
    Statistic:     Double;        { ADF test statistic }
    Crit1Pct:      Double;        { critical value at 1% }
    Crit5Pct:      Double;        { critical value at 5% }
    Crit10Pct:     Double;        { critical value at 10% }
    IsStationary:  Boolean;       { True if statistic < Crit5Pct (reject unit root) }
  end;

  { CUSUM change-point result }
  TCUSUMResult = record
    CUSUMValues:    TDoubleArray;  { cumulative sum series }
    ChangePoint:    Integer;       { index of detected change (-1 if none) }
    Detected:       Boolean;
  end;

  { TTimeSeriesKit — all methods are class static }
  TTimeSeriesKit = class
  private
    { Compute sample mean of array slice [Start..Stop] }
    class function SliceMean(const Y: TDoubleArray; Start, Stop: Integer): Double; static;

    { Compute sample variance of array slice }
    class function SliceVar(const Y: TDoubleArray; Start, Stop: Integer): Double; static;

    { Sort a double array (insertion sort — used for small windows) }
    class procedure InsertionSort(var A: TDoubleArray); static;

    { Solve an N×N linear system Ax = b via Gaussian elimination with
      partial pivoting. Returns False if singular. }
    class function SolveLinear(
      const A: array of TDoubleArray;
      const B: TDoubleArray;
      out X: TDoubleArray): Boolean; static;

  public

    { =======================================================================
      SMOOTHING & FILTERING
    ======================================================================= }

    { Simple Moving Average: each output point is the mean of the
      surrounding Window values (centred where possible).
      Output has the same length as the input; edge points use
      available data only (no padding).

      Example: SMA of daily stock prices with a 5-day window
        smooth := TTimeSeriesKit.SimpleMovingAverage(prices, 5); }
    class function SimpleMovingAverage(const Y: TDoubleArray; Window: Integer): TDoubleArray; static;

    { Weighted Moving Average: like SMA but more recent values
      receive linearly larger weights (weight_i = i+1 for i=0..Window-1).
      Reacts faster than SMA to recent changes. }
    class function WeightedMovingAverage(const Y: TDoubleArray; Window: Integer): TDoubleArray; static;

    { Exponential Smoothing (single / simple EMA).
      S_t = Alpha * Y_t + (1-Alpha) * S_(t-1)
      Alpha in (0,1]: small Alpha → heavy smoothing; large Alpha → tracks data closely.
      InitValue: starting value for S_0 (default = Y[0] if not supplied). }
    class function ExponentialSmoothing(
      const Y: TDoubleArray;
      Alpha: Double;
      InitValue: Double = NaN): TDoubleArray; static;

    { Holt's Double Exponential Smoothing (additive trend).
      Tracks LEVEL and TREND separately.
      Alpha: level smoothing (0..1)
      Beta:  trend smoothing (0..1)
      Returns smoothed series same length as Y.

      Good for data with a trend but no seasonality. }
    class function DoubleExponentialSmoothing(const Y: TDoubleArray; Alpha, Beta: Double): TDoubleArray; static;

    { Holt-Winters Triple Exponential Smoothing.
      Handles data with TREND and SEASONALITY.
      Alpha:  level smoothing
      Beta:   trend smoothing
      Gamma:  seasonal smoothing
      Period: length of the seasonal cycle (e.g. 12 for monthly, 4 for quarterly)
      DType:  dtAdditive or dtMultiplicative seasonality

      Returns smoothed in-sample fitted values, same length as Y.
      Use HoltWintersForecast to project forward. }
    class function TripleExponentialSmoothing(
      const Y: TDoubleArray;
      Alpha, Beta, Gamma: Double;
      Period: Integer;
      DType: TDecompType = dtAdditive): TDoubleArray; static;

    { Holt-Winters h-step ahead forecast.
      Uses the state (level L, trend B, seasonals S[]) at the end of Y
      to project H steps into the future.
      Returns array of length H. }
    class function HoltWintersForecast(
      const Y: TDoubleArray;
      Alpha, Beta, Gamma: Double;
      Period, H: Integer;
      DType: TDecompType = dtAdditive): TDoubleArray; static;

    { =======================================================================
      DECOMPOSITION
    ======================================================================= }

    { Classical additive or multiplicative decomposition.
      1. Estimates trend by centred moving average of width Period.
      2. Computes seasonal indices by averaging de-trended values per cycle position.
      3. Residual = observed − trend − seasonal (additive) or observed/(trend*seasonal).

      Period: seasonal cycle length (e.g. 12 for monthly data). }
    class function Decompose(
      const Y: TDoubleArray;
      Period: Integer;
      DType: TDecompType = dtAdditive): TDecomposition; static;

    { =======================================================================
      DIFFERENCING & STATIONARITY
    ======================================================================= }

    { d-th order differencing.
      Difference(Y, 1) = [Y[1]-Y[0], Y[2]-Y[1], ...]  (length N-1)
      Difference(Y, 2) = second differences             (length N-2)
      Used to make a non-stationary series stationary before ARIMA fitting. }
    class function Difference(const Y: TDoubleArray; D: Integer = 1): TDoubleArray; static;

    { Invert differencing given the original first D values (initial conditions).
      Undifference(Diff1, [Y[0]], 1) reconstructs the original series.
      InitVals must have at least D elements; extra values are ignored. }
    class function Undifference(
      const DiffY: TDoubleArray;
      const InitVals: TDoubleArray;
      D: Integer = 1): TDoubleArray; static;

    { Augmented Dickey-Fuller (ADF) unit-root test.
      Tests H0: series has a unit root (non-stationary) against
            H1: series is stationary.
      Lags: number of lagged differences to include (0 = simple DF test).
      Critical values are MacKinnon (1994) approximations for n → ∞.
      Reject H0 (series IS stationary) when Statistic < CritValue. }
    class function AugmentedDickeyFuller(const Y: TDoubleArray; Lags: Integer = 1): TADFResult; static;

    { =======================================================================
      AUTOCORRELATION
    ======================================================================= }

    { ACF: autocorrelation at lags 0, 1, ..., MaxLag.
      ACF[0] is always 1.0.
      Use to identify the MA order q: ACF cuts off after lag q. }
    class function ACF(const Y: TDoubleArray; MaxLag: Integer): TDoubleArray; static;

    { PACF: partial autocorrelation at lags 0, 1, ..., MaxLag.
      PACF[0] is always 1.0.
      Use to identify the AR order p: PACF cuts off after lag p.
      Computed via Yule-Walker equations. }
    class function PACF(const Y: TDoubleArray; MaxLag: Integer): TDoubleArray; static;

    { Ljung-Box Q test for white noise.
      Tests whether the first MaxLag autocorrelations are jointly zero.
      Returns the Q statistic; compare to chi-squared critical value with
      MaxLag degrees of freedom.
      Rule of thumb: Q > 3.84 (chi2 df=1, 5%) → not white noise. }
    class function LjungBox(const Y: TDoubleArray; MaxLag: Integer): Double; static;

    { =======================================================================
      ARIMA MODELS
    ======================================================================= }

    { Fit AR(p) model via Yule-Walker equations.
      Returns coefficients phi[1..p] and innovation variance Sigma2.
      The AR(p) model: Y_t = phi_1 Y_(t-1) + ... + phi_p Y_(t-p) + e_t }
    class function ARFit(const Y: TDoubleArray; P: Integer): TARIMAModel; static;

    { h-step forecast from AR coefficients.
      Simulates the AR recursion forward H steps from the end of History.
      History should be the original (or differenced) series. Model dimensions,
      finite inputs, and the forecast horizon are validated. }
    class function ARForecast(const Model: TARIMAModel; const History: TDoubleArray; H: Integer): TDoubleArray; static;

    { Fit MA(q) model using innovations algorithm (approximate).
      Returns theta[1..q] and Sigma2. }
    class function MAFit(const Y: TDoubleArray; Q: Integer): TARIMAModel; static;

    { Fit ARIMA(p,d,q) model.
      1. Differences Y by order D to obtain a stationary series Z.
      2. Fits AR(p) to the differenced series to get phi coefficients.
      3. Computes residuals and fits MA(q) to them for theta coefficients.
      Returns a TARIMAModel with all fitted parameters. }
    class function ARIMAFit(const Y: TDoubleArray; P, D, Q: Integer): TARIMAModel; static;

    { H-step ahead ARIMA forecast.
      Reconstructs in-sample innovations, includes the known MA innovations in
      early forecasts, assumes future innovations are zero, and integrates each
      differencing order from the last observed state.
      Returns array of length H. }
    class function ARIMAForecast(
      const Model: TARIMAModel;
      const OriginalY: TDoubleArray;
      H: Integer): TDoubleArray; static;

    { =======================================================================
      CHANGE-POINT & ANOMALY DETECTION
    ======================================================================= }

    { CUSUM (cumulative sum) control chart for mean-shift detection.
      Accumulates deviations from the target mean (defaults to sample mean).
      ChangePoint = first index where |CUSUM| > Threshold * StdDev.
      Set Threshold to 0 to disable detection and just return the CUSUM series. }
    class function CUSUMDetect(
      const Y: TDoubleArray;
      Threshold: Double = 4.0;
      Target: Double = NaN): TCUSUMResult; static;

    { Return indices where |Z-score| > Threshold (default 3.0 sigma).
      A value is anomalous if it is more than Threshold standard deviations
      from the series mean. }
    class function ZScoreAnomalies(const Y: TDoubleArray; Threshold: Double = 3.0): TIntegerArray; static;

    { Rolling Z-score: compute z-score within a rolling window of width Window.
      Points where |rolling z| > Threshold are flagged as anomalies.
      Returns the anomaly indices. }
    class function RollingZScore(
      const Y: TDoubleArray;
      Window: Integer;
      Threshold: Double = 3.0): TIntegerArray; static;

    { =======================================================================
      TREND & SEASONALITY UTILITIES
    ======================================================================= }

    { Fit a linear trend y_t = a + b*t by OLS (t = 0, 1, ..., N-1).
      Returns intercept, slope, and R². }
    class function LinearTrend(const Y: TDoubleArray): TLinearTrend; static;

    { Remove the fitted linear trend from Y.
      Returns the detrended residuals (same length as Y). }
    class function DetrendLinear(const Y: TDoubleArray): TDoubleArray; static;

    { Seasonal strength metric from a decomposition.
      = max(0, 1 - Var(Residual) / Var(Seasonal + Residual))
      Values near 1 indicate strong seasonality; near 0 means weak. }
    class function SeasonalStrength(const Decomp: TDecomposition): Double; static;

    { Find the dominant period in Y using an FFT power spectrum.
      Returns the period (in samples) corresponding to the largest spectral peak,
      excluding the DC component (lag 0).
      MinPeriod / MaxPeriod: search range (default 2 .. N/2). Frequency-bin
      conversion uses the actual zero-padded FFT length. }
    class function PeriodogramPeak(
      const Y: TDoubleArray;
      MinPeriod: Integer = 2;
      MaxPeriod: Integer = 0): Integer; static;

    { Compute a one-sided power spectrum of Y after zero-padding to NPow, the
      next power of two. Returns NPow/2+1 bins; bin k has frequency k/NPow. }
    class function Periodogram(const Y: TDoubleArray): TDoubleArray; static;

  end;

implementation

procedure RequireFiniteSeries(const Y: TDoubleArray; const Operation: string);
var
  I: Integer;
begin
  for I := 0 to High(Y) do
    if IsNan(Y[I]) or IsInfinite(Y[I]) then
      raise ETimeSeriesError.CreateFmt('%s: non-finite value at index %d',
        [Operation, I]);
end;

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.SliceMean(const Y: TDoubleArray; Start, Stop: Integer): Double;
var I: Integer; S: Double;
begin
  S := 0;
  for I := Start to Stop do S := S + Y[I];
  Result := S / (Stop - Start + 1);
end;

class function TTimeSeriesKit.SliceVar(const Y: TDoubleArray; Start, Stop: Integer): Double;
var I: Integer; M, S: Double;
begin
  M := SliceMean(Y, Start, Stop);
  S := 0;
  for I := Start to Stop do S := S + Sqr(Y[I] - M);
  Result := S / (Stop - Start);  { unbiased (n-1) }
end;

class procedure TTimeSeriesKit.InsertionSort(var A: TDoubleArray);
var I, J: Integer; K: Double;
begin
  for I := 1 to High(A) do
  begin
    K := A[I]; J := I - 1;
    while (J >= 0) and (A[J] > K) do
    begin A[J+1] := A[J]; Dec(J); end;
    A[J+1] := K;
  end;
end;

class function TTimeSeriesKit.SolveLinear(
  const A: array of TDoubleArray;
  const B: TDoubleArray;
  out X: TDoubleArray): Boolean;
{ Gaussian elimination with partial pivoting. Modifies local copies. }
var
  N, I, J, K, MaxRow: Integer;
  MaxVal, Factor, Tmp: Double;
  Aug: array of TDoubleArray;
begin
  N := Length(B);
  SetLength(Aug, N);
  for I := 0 to N-1 do
  begin
    SetLength(Aug[I], N+1);
    for J := 0 to N-1 do Aug[I][J] := A[I][J];
    Aug[I][N] := B[I];
  end;

  for K := 0 to N-1 do
  begin
    { Partial pivot }
    MaxVal := Abs(Aug[K][K]); MaxRow := K;
    for I := K+1 to N-1 do
      if Abs(Aug[I][K]) > MaxVal then begin MaxVal := Abs(Aug[I][K]); MaxRow := I; end;
    if MaxRow <> K then
    begin
      Tmp := 0; { swap rows }
      for J := 0 to N do
      begin Tmp := Aug[K][J]; Aug[K][J] := Aug[MaxRow][J]; Aug[MaxRow][J] := Tmp; end;
    end;
    if Abs(Aug[K][K]) < 1E-14 then begin Result := False; Exit; end;
    for I := K+1 to N-1 do
    begin
      Factor := Aug[I][K] / Aug[K][K];
      for J := K to N do Aug[I][J] := Aug[I][J] - Factor * Aug[K][J];
    end;
  end;

  SetLength(X, N);
  for I := N-1 downto 0 do
  begin
    X[I] := Aug[I][N];
    for J := I+1 to N-1 do X[I] := X[I] - Aug[I][J] * X[J];
    X[I] := X[I] / Aug[I][I];
  end;
  Result := True;
end;

{ ---------------------------------------------------------------------------
  SMOOTHING
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.SimpleMovingAverage(const Y: TDoubleArray; Window: Integer): TDoubleArray;
{ Centred SMA; edges use available data. }
var
  N, I, J, Lo, Hi: Integer;
  S: Double;
begin
  N := Length(Y);
  if N = 0 then raise ETimeSeriesError.Create('SimpleMovingAverage: empty series');
  if Window < 1 then raise ETimeSeriesError.Create('SimpleMovingAverage: Window must be >= 1');
  Result := nil;
  SetLength(Result, N);
  for I := 0 to N-1 do
  begin
    Lo := Max(0, I - Window div 2);
    Hi := Min(N-1, I + (Window-1) div 2);
    S  := 0;
    for J := Lo to Hi do S := S + Y[J];
    Result[I] := S / (Hi - Lo + 1);
  end;
end;

class function TTimeSeriesKit.WeightedMovingAverage(const Y: TDoubleArray; Window: Integer): TDoubleArray;
{ Trailing WMA: weight of position i within window = i+1 (most recent = Window) }
var
  N, I, J: Integer;
  WSum, VSum: Double;
begin
  N := Length(Y);
  if N = 0 then raise ETimeSeriesError.Create('WeightedMovingAverage: empty series');
  if Window < 1 then raise ETimeSeriesError.Create('WeightedMovingAverage: Window must be >= 1');
  Result := nil;
  SetLength(Result, N);
  for I := 0 to N-1 do
  begin
    WSum := 0; VSum := 0;
    { Weff = number of values in this window; J=0 is most recent, weight = Weff-J }
    for J := 0 to Min(Window-1, I) do
    begin
      WSum := WSum + (Min(Window, I + 1) - J);
      VSum := VSum + (Min(Window, I + 1) - J) * Y[I - J];
    end;
    Result[I] := VSum / WSum;
  end;
end;

class function TTimeSeriesKit.ExponentialSmoothing(
  const Y: TDoubleArray;
  Alpha: Double;
  InitValue: Double): TDoubleArray;
{ S_t = Alpha Y_t + (1-Alpha) S_(t-1) }
var
  N, I: Integer;
  S: Double;
begin
  N := Length(Y);
  if N = 0 then raise ETimeSeriesError.Create('ExponentialSmoothing: empty series');
  if (Alpha <= 0) or (Alpha > 1) then
    raise ETimeSeriesError.Create('ExponentialSmoothing: Alpha must be in (0,1]');
  Result := nil;
  SetLength(Result, N);
  S := IfThen(IsNan(InitValue), Y[0], InitValue);
  for I := 0 to N-1 do
  begin
    S         := Alpha * Y[I] + (1 - Alpha) * S;
    Result[I] := S;
  end;
end;

class function TTimeSeriesKit.DoubleExponentialSmoothing(const Y: TDoubleArray; Alpha, Beta: Double): TDoubleArray;
{ Holt's method: tracks level L and trend B.
  L_t = Alpha Y_t + (1-Alpha) (L_(t-1) + B_(t-1))
  B_t = Beta (L_t - L_(t-1)) + (1-Beta) B_(t-1)
  Fitted = L_(t-1) + B_(t-1) }
var
  N, I: Integer;
  L, B, LPrev: Double;
begin
  N := Length(Y);
  if N < 2 then raise ETimeSeriesError.Create('DoubleExponentialSmoothing: need at least 2 points');
  if (Alpha <= 0) or (Alpha > 1) then raise ETimeSeriesError.Create('Alpha must be in (0,1]');
  if (Beta  <= 0) or (Beta  > 1) then raise ETimeSeriesError.Create('Beta must be in (0,1]');
  Result := nil;
  SetLength(Result, N);
  L := Y[0];
  B := Y[1] - Y[0];  { initial trend estimate }
  Result[0] := L;
  for I := 1 to N-1 do
  begin
    LPrev     := L;
    L         := Alpha * Y[I] + (1 - Alpha) * (L + B);
    B         := Beta  * (L - LPrev) + (1 - Beta) * B;
    Result[I] := L;
  end;
end;

class function TTimeSeriesKit.TripleExponentialSmoothing(
  const Y: TDoubleArray;
  Alpha, Beta, Gamma: Double;
  Period: Integer;
  DType: TDecompType): TDoubleArray;
{ Holt-Winters: level L, trend B, seasonal S[0..Period-1] }
var
  N, I, K: Integer;
  L, LPrev, B, Seas: Double;
  SArr: TDoubleArray;
begin
  N := Length(Y);
  if N < 2 * Period then raise ETimeSeriesError.Create(
    'TripleExponentialSmoothing: need at least 2 full seasons');
  if Period < 2 then raise ETimeSeriesError.Create('Period must be >= 2');
  if (Alpha <= 0) or (Alpha > 1) then raise ETimeSeriesError.Create('Alpha must be in (0,1]');
  if (Beta  <= 0) or (Beta  > 1) then raise ETimeSeriesError.Create('Beta must be in (0,1]');
  if (Gamma <= 0) or (Gamma > 1) then raise ETimeSeriesError.Create('Gamma must be in (0,1]');

  { Initialise seasonal indices from first two seasons }
  SetLength(SArr, Period);
  for K := 0 to Period-1 do
  begin
    if DType = dtAdditive then
      SArr[K] := 0.5 * ((Y[K] - SliceMean(Y, 0, Period-1)) +
                        (Y[K + Period] - SliceMean(Y, Period, 2*Period-1)))
    else
      SArr[K] := 0.5 * (Y[K] / SliceMean(Y, 0, Period-1) +
                        Y[K + Period] / SliceMean(Y, Period, 2*Period-1));
  end;

  L := SliceMean(Y, 0, Period-1);
  B := (SliceMean(Y, Period, 2*Period-1) - L) / Period;

  Result := nil;
  SetLength(Result, N);
  for I := 0 to N-1 do
  begin
    K     := I mod Period;
    LPrev := L;
    Seas  := SArr[K];

    if DType = dtAdditive then
    begin
      L        := Alpha * (Y[I] - Seas) + (1-Alpha) * (L + B);
      B        := Beta  * (L - LPrev)   + (1-Beta)  * B;
      SArr[K]  := Gamma * (Y[I] - L)    + (1-Gamma) * Seas;
      Result[I]:= L + B + SArr[K];
    end
    else
    begin
      L        := Alpha * (Y[I] / Seas)  + (1-Alpha) * (L + B);
      B        := Beta  * (L - LPrev)    + (1-Beta)  * B;
      SArr[K]  := Gamma * (Y[I] / L)     + (1-Gamma) * Seas;
      Result[I]:= (L + B) * SArr[K];
    end;
  end;
end;

class function TTimeSeriesKit.HoltWintersForecast(
  const Y: TDoubleArray;
  Alpha, Beta, Gamma: Double;
  Period, H: Integer;
  DType: TDecompType): TDoubleArray;
{ Run the Holt-Winters update loop to get final state, then project H steps }
var
  N, I, K: Integer;
  L, LPrev, B, Seas: Double;
  SArr: TDoubleArray;
begin
  N := Length(Y);
  if N < 2 * Period then raise ETimeSeriesError.Create(
    'HoltWintersForecast: need at least 2 full seasons');
  if H < 1 then raise ETimeSeriesError.Create('H must be >= 1');

  SetLength(SArr, Period);
  for K := 0 to Period-1 do
  begin
    if DType = dtAdditive then
      SArr[K] := 0.5 * ((Y[K] - SliceMean(Y, 0, Period-1)) +
                        (Y[K+Period] - SliceMean(Y, Period, 2*Period-1)))
    else
      SArr[K] := 0.5 * (Y[K] / SliceMean(Y, 0, Period-1) +
                        Y[K+Period] / SliceMean(Y, Period, 2*Period-1));
  end;

  L := SliceMean(Y, 0, Period-1);
  B := (SliceMean(Y, Period, 2*Period-1) - L) / Period;

  { Run update loop over all of Y }
  for I := 0 to N-1 do
  begin
    K     := I mod Period;
    LPrev := L;
    Seas  := SArr[K];
    if DType = dtAdditive then
    begin
      L       := Alpha * (Y[I] - Seas) + (1-Alpha) * (L + B);
      B       := Beta  * (L - LPrev)   + (1-Beta)  * B;
      SArr[K] := Gamma * (Y[I] - L)    + (1-Gamma) * Seas;
    end
    else
    begin
      L       := Alpha * (Y[I] / Seas)  + (1-Alpha) * (L + B);
      B       := Beta  * (L - LPrev)    + (1-Beta)  * B;
      SArr[K] := Gamma * (Y[I] / L)     + (1-Gamma) * Seas;
    end;
  end;

  { Project H steps ahead }
  Result := nil;
  SetLength(Result, H);
  for I := 1 to H do
  begin
    K := (N - 1 + I) mod Period;
    if DType = dtAdditive then
      Result[I-1] := L + I * B + SArr[K]
    else
      Result[I-1] := (L + I * B) * SArr[K];
  end;
end;

{ ---------------------------------------------------------------------------
  DECOMPOSITION
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.Decompose(const Y: TDoubleArray; Period: Integer; DType: TDecompType): TDecomposition;
{ Classical decomposition:
  1. Trend via centred moving average of width Period.
  2. Seasonal = average of (Y/Trend or Y-Trend) per cycle position.
  3. Residual = remainder. }
var
  N, I, K: Integer;
  Half: Integer;
  SeasonSum: TDoubleArray;
  SeasonCount: TIntegerArray;
  TrendVal, SeasonAdj: Double;
begin
  N    := Length(Y);
  Half := Period div 2;
  if N < 2 * Period then raise ETimeSeriesError.Create(
    'Decompose: series too short for given Period');

  Result.DecompType := DType;
  SetLength(Result.Trend,    N);
  SetLength(Result.Seasonal, N);
  SetLength(Result.Residual, N);
  SetLength(SeasonSum,   Period);
  SetLength(SeasonCount, Period);

  { Step 1: trend by centred moving average }
  for I := 0 to N-1 do
  begin
    if (I >= Half) and (I < N - Half) then
      Result.Trend[I] := SliceMean(Y, I - Half, I + Half)
    else
      Result.Trend[I] := NaN;  { edge: undefined }
  end;

  { Step 2: seasonal indices — accumulate de-trended values per position }
  for I := 0 to N-1 do
  begin
    if IsNan(Result.Trend[I]) then Continue;
    K := I mod Period;
    if DType = dtAdditive then
      SeasonSum[K] := SeasonSum[K] + (Y[I] - Result.Trend[I])
    else
    begin
      if Abs(Result.Trend[I]) > 1E-12 then
        SeasonSum[K] := SeasonSum[K] + (Y[I] / Result.Trend[I]);
    end;
    Inc(SeasonCount[K]);
  end;

  { Normalise seasonal indices }
  for K := 0 to Period-1 do
    if SeasonCount[K] > 0 then SeasonSum[K] := SeasonSum[K] / SeasonCount[K];

  { Assign and fill edges }
  for I := 0 to N-1 do
    Result.Seasonal[I] := SeasonSum[I mod Period];

  { Step 3: residual }
  for I := 0 to N-1 do
  begin
    TrendVal := Result.Trend[I];
    if IsNan(TrendVal) then TrendVal := Y[I];  { fallback at edges }
    SeasonAdj := Result.Seasonal[I];
    if DType = dtAdditive then
      Result.Residual[I] := Y[I] - TrendVal - SeasonAdj
    else
    begin
      if Abs(TrendVal * SeasonAdj) > 1E-12 then
        Result.Residual[I] := Y[I] / (TrendVal * SeasonAdj)
      else
        Result.Residual[I] := 1.0;
    end;
  end;
end;

{ ---------------------------------------------------------------------------
  DIFFERENCING
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.Difference(const Y: TDoubleArray; D: Integer): TDoubleArray;
var I, Ord: Integer; Cur: TDoubleArray;
begin
  if D < 0 then raise ETimeSeriesError.Create('Difference: D must be >= 0');
  Result := nil;
  Cur := Y;
  for Ord := 1 to D do
  begin
    if Length(Cur) < 2 then raise ETimeSeriesError.Create(
      'Difference: series too short for requested order');
    SetLength(Result, Length(Cur) - 1);
    for I := 0 to High(Result) do
      Result[I] := Cur[I+1] - Cur[I];
    Cur := Result;
  end;
  if D = 0 then Result := Cur;
end;

class function TTimeSeriesKit.Undifference(
  const DiffY: TDoubleArray;
  const InitVals: TDoubleArray;
  D: Integer): TDoubleArray;
{ Reconstruct by cumulative summation, D times.
  InitVals[0..D-1] = the first D values of the original series.
  We pre-compute the successive differences of InitVals to obtain the
  seed for each integration pass (innermost first). }
var
  I, Ord: Integer;
  Cur, Seeds: TDoubleArray;
begin
  if D = 0 then begin Result := DiffY; Exit; end;
  if Length(InitVals) < D then raise ETimeSeriesError.Create(
    'Undifference: InitVals must have at least D elements');

  { Seeds[k] = k-th order difference of InitVals at position 0.
    Seeds[0] = InitVals[0], Seeds[1] = InitVals[1]-InitVals[0], etc. }
  SetLength(Seeds, D);
  Seeds := Copy(InitVals, 0, D);
  for Ord := 1 to D - 1 do
    for I := D - 1 downto Ord do
      Seeds[I] := Seeds[I] - Seeds[I - 1];

  { Integrate D times, innermost (highest-order) pass first }
  Cur := DiffY;
  for Ord := D downto 1 do
  begin
    SetLength(Result, Length(Cur) + 1);
    Result[0] := Seeds[Ord - 1];
    for I := 1 to High(Result) do
      Result[I] := Result[I-1] + Cur[I-1];
    Cur := Result;
  end;
end;

{ ---------------------------------------------------------------------------
  AUGMENTED DICKEY-FULLER
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.AugmentedDickeyFuller(const Y: TDoubleArray; Lags: Integer): TADFResult;
{ Regression: ΔY_t = alpha + beta Y_(t-1) + sum(gamma_j ΔY_(t-j)) + e_t
  Test statistic = beta / SE(beta).  MacKinnon (1994) critical values. }
var
  N, NReg, I, J, K, NCol: Integer;
  DY: TDoubleArray;
  XMat: array of TDoubleArray;
  XTX, XTX2, XTX3: array of TDoubleArray;
  YVec, Coeff, Resid, XTX_diag, XTY, Ident, InvCol: TDoubleArray;
  YLag, Beta, SumSq, SE, Sigma2: Double;
  OK: Boolean;
begin
  N := Length(Y);
  if N < Lags + 3 then raise ETimeSeriesError.Create('ADF: series too short');

  { Build first differences }
  SetLength(DY, N-1);
  for I := 0 to N-2 do DY[I] := Y[I+1] - Y[I];

  { Number of regression observations (skip first Lags+1 due to lags) }
  NReg := N - Lags - 1;

  { Build design matrix: [1, Y_(t-1), ΔY_(t-1), ..., ΔY_(t-Lags)] }
  SetLength(XMat, NReg);
  SetLength(YVec, NReg);
  for I := 0 to NReg-1 do
  begin
    K := I + Lags;  { offset into DY }
    SetLength(XMat[I], Lags + 2);
    XMat[I][0] := 1;               { intercept }
    XMat[I][1] := Y[K];            { Y_(t-1), the level lag }
    for J := 1 to Lags do
      XMat[I][J+1] := DY[K - J];   { lagged differences }
    YVec[I] := DY[K];              { ΔY_t }
  end;

  { OLS: inverse(X'X) X'Y via normal equations — build X'X and X'Y }
  NCol := Lags + 2;
  SetLength(XTX, NCol);
  SetLength(XTY, NCol);
  for I := 0 to NCol-1 do
  begin
    SetLength(XTX[I], NCol);
    XTY[I] := 0;
  end;
  for K := 0 to NReg-1 do
    for I := 0 to NCol-1 do
    begin
      XTY[I] := XTY[I] + XMat[K][I] * YVec[K];
      for J := 0 to NCol-1 do
        XTX[I][J] := XTX[I][J] + XMat[K][I] * XMat[K][J];
    end;
  OK := SolveLinear(XTX, XTY, Coeff);

  if not OK then
  begin
    Result.Statistic    := 0;
    Result.IsStationary := False;
    Exit;
  end;

  { Residuals and sigma^2 }
  SumSq := 0;
  SetLength(Resid, NReg);
  for I := 0 to NReg-1 do
  begin
    Resid[I] := YVec[I];
    for J := 0 to Lags+1 do Resid[I] := Resid[I] - XMat[I][J] * Coeff[J];
    SumSq := SumSq + Sqr(Resid[I]);
  end;
  Sigma2 := SumSq / (NReg - Lags - 2);

  { SE of beta (coefficient index 1) = sqrt(Sigma2 times inverse(X'X)[1,1]) }
  { We need diagonal (1,1) of inverse(X'X). Solve X'X e_1 = e_1. }
  SetLength(Ident, NCol);
  Ident[1] := 1;  { pick column 1 }
  SetLength(XTX2, NCol);
  for I := 0 to NCol-1 do
  begin
    SetLength(XTX2[I], NCol);
    for J := 0 to NReg-1 do
      for K := 0 to NCol-1 do
        XTX2[I][K] := XTX2[I][K] + XMat[J][I] * XMat[J][K];
  end;
  { Rebuild X'X cleanly }
  SetLength(XTX3, NCol);
  for I := 0 to NCol-1 do SetLength(XTX3[I], NCol);
  for K := 0 to NReg-1 do
    for I := 0 to NCol-1 do
      for J := 0 to NCol-1 do
        XTX3[I][J] := XTX3[I][J] + XMat[K][I] * XMat[K][J];
  SolveLinear(XTX3, Ident, InvCol);
  SE := Sqrt(Abs(Sigma2 * InvCol[1]));

  Beta := Coeff[1];
  if SE > 1E-14 then Result.Statistic := Beta / SE else Result.Statistic := 0;

  { MacKinnon (1994) asymptotic critical values for no-trend regression }
  Result.Crit1Pct  := -3.43;
  Result.Crit5Pct  := -2.86;
  Result.Crit10Pct := -2.57;
  Result.IsStationary := Result.Statistic < Result.Crit5Pct;
end;

{ ---------------------------------------------------------------------------
  AUTOCORRELATION
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.ACF(const Y: TDoubleArray; MaxLag: Integer): TDoubleArray;
{ r_k = Cov(Y_t, Y_(t-k)) / Var(Y) }
var
  N, I, K: Integer;
  Mu, VarY, Cov: Double;
begin
  N := Length(Y);
  if N < 2 then raise ETimeSeriesError.Create('ACF: need at least 2 observations');
  if MaxLag >= N then raise ETimeSeriesError.Create('ACF: MaxLag must be < Length(Y)');

  Mu   := SliceMean(Y, 0, N-1);
  VarY := SliceVar(Y, 0, N-1) * (N - 1);  { unnormalised: sum of squared devs }

  Result := nil;
  SetLength(Result, MaxLag + 1);
  Result[0] := 1.0;
  for K := 1 to MaxLag do
  begin
    Cov := 0;
    for I := K to N-1 do
      Cov := Cov + (Y[I] - Mu) * (Y[I-K] - Mu);
    if VarY > 1E-15 then Result[K] := Cov / VarY else Result[K] := 0;
  end;
end;

class function TTimeSeriesKit.PACF(const Y: TDoubleArray; MaxLag: Integer): TDoubleArray;
{ Yule-Walker equations solved iteratively (Durbin-Levinson) }
var
  N, K, I, J: Integer;
  AcfVals: TDoubleArray;
  Phi, PhiNew: TDoubleArray;
  Num, Den, PhiKK: Double;
begin
  N := Length(Y);
  if MaxLag >= N then MaxLag := N - 1;
  AcfVals := ACF(Y, MaxLag);

  Result := nil;
  SetLength(Result, MaxLag + 1);
  Result[0] := 1.0;
  if MaxLag < 1 then Exit;

  { Durbin-Levinson recursion }
  SetLength(Phi, MaxLag + 1);
  Phi[1]    := AcfVals[1];
  Result[1] := AcfVals[1];

  for K := 2 to MaxLag do
  begin
    Num := AcfVals[K];
    Den := 1.0;
    for J := 1 to K-1 do
    begin
      Num := Num - Phi[J] * AcfVals[K-J];
      Den := Den - Phi[J] * AcfVals[J];
    end;
    PhiKK := IfThen(Abs(Den) > 1E-15, Num / Den, 0);
    Result[K] := PhiKK;
    SetLength(PhiNew, K + 1);
    for J := 1 to K-1 do PhiNew[J] := Phi[J] - PhiKK * Phi[K-J];
    PhiNew[K] := PhiKK;
    for J := 1 to K do Phi[J] := PhiNew[J];
  end;
end;

class function TTimeSeriesKit.LjungBox(const Y: TDoubleArray; MaxLag: Integer): Double;
{ Q = N (N+2) sum(k=1..MaxLag) r_k^2 / (N-k) }
var
  N, K: Integer;
  AcfVals: TDoubleArray;
begin
  N       := Length(Y);
  AcfVals := ACF(Y, MaxLag);
  Result  := 0;
  for K := 1 to MaxLag do
    Result := Result + Sqr(AcfVals[K]) / (N - K);
  Result := N * (N + 2) * Result;
end;

{ ---------------------------------------------------------------------------
  ARIMA
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.ARFit(const Y: TDoubleArray; P: Integer): TARIMAModel;
{ Yule-Walker: solve Toeplitz system R*phi = r using ACF }
var
  N, I, J: Integer;
  AcfVals: TDoubleArray;
  R: array of TDoubleArray;
  RVec, Phi: TDoubleArray;
  Mu, ResSum, Sigma2: Double;
begin
  N := Length(Y);
  if P < 1 then raise ETimeSeriesError.Create('ARFit: P must be >= 1');
  if N <= P then raise ETimeSeriesError.Create('ARFit: series too short for P');

  Mu      := SliceMean(Y, 0, N-1);
  AcfVals := ACF(Y, P);

  { Build Toeplitz matrix R[i][j] = AcfVals[|i-j|] }
  SetLength(R, P);
  SetLength(RVec, P);
  for I := 0 to P-1 do
  begin
    SetLength(R[I], P);
    RVec[I] := AcfVals[I+1];
    for J := 0 to P-1 do R[I][J] := AcfVals[Abs(I-J)];
  end;

  SolveLinear(R, RVec, Phi);

  { Compute innovation variance: Sigma^2 = Var(Y) * (1 - sum phi_i * r_i) }
  Sigma2 := SliceVar(Y, 0, N-1);
  ResSum := 0;
  for I := 0 to P-1 do ResSum := ResSum + Phi[I] * AcfVals[I+1];
  Sigma2 := Sigma2 * (1 - ResSum);

  Result.P        := P;
  Result.Q        := 0;
  Result.D        := 0;
  Result.Mu       := Mu;
  Result.Sigma2   := Max(Sigma2, 0);
  Result.ARCoeffs := Phi;
  SetLength(Result.MACoeffs, 0);
end;

class function TTimeSeriesKit.ARForecast(
  const Model: TARIMAModel;
  const History: TDoubleArray;
  H: Integer): TDoubleArray;
{ Recursively apply AR recursion: Y_hat_t = mu + phi_1 (Y_(t-1)-mu) + ... }
var
  N, I, J, P: Integer;
  Buf: TDoubleArray;
begin
  N := Length(History);
  P := Model.P;
  if H < 1 then raise ETimeSeriesError.Create('ARForecast: H must be >= 1');
  if P < 0 then raise ETimeSeriesError.Create('ARForecast: model P must be >= 0');
  if Length(Model.ARCoeffs) <> P then raise ETimeSeriesError.Create(
    'ARForecast: AR coefficient count does not match model P');
  if N < P then raise ETimeSeriesError.Create('ARForecast: history is shorter than model P');
  if IsNan(Model.Mu) or IsInfinite(Model.Mu) then raise ETimeSeriesError.Create(
    'ARForecast: model mean must be finite');
  RequireFiniteSeries(History, 'ARForecast');
  RequireFiniteSeries(Model.ARCoeffs, 'ARForecast coefficients');

  { Extend History buffer to hold forecasts }
  SetLength(Buf, N + H);
  for I := 0 to N-1 do Buf[I] := History[I];

  for I := 0 to H-1 do
  begin
    Buf[N+I] := Model.Mu;
    for J := 0 to P-1 do
      if N + I - J - 1 >= 0 then
        Buf[N+I] := Buf[N+I] + Model.ARCoeffs[J] * (Buf[N+I-J-1] - Model.Mu);
  end;

  Result := nil;
  SetLength(Result, H);
  for I := 0 to H-1 do Result[I] := Buf[N+I];
end;

class function TTimeSeriesKit.MAFit(const Y: TDoubleArray; Q: Integer): TARIMAModel;
{ Approximate MA(q) via innovations algorithm on the ACF.
  theta[1..q] approximated from ACF using the Durbin relations. }
var
  N, I, J: Integer;
  AcfVals: TDoubleArray;
  Theta: TDoubleArray;
  V: array of Double;
  ThetaMat: array of TDoubleArray;
  Sum: Double;
begin
  N       := Length(Y);
  if Q < 1 then raise ETimeSeriesError.Create('MAFit: Q must be >= 1');
  if N <= Q then raise ETimeSeriesError.Create('MAFit: series must be longer than Q');
  RequireFiniteSeries(Y, 'MAFit');
  AcfVals := ACF(Y, Q);

  { Innovations algorithm (simplified): theta_(k,k) = acf[k] / v_(k-1) }
  SetLength(Theta, Q);
  SetLength(V, Q+1);
  SetLength(ThetaMat, Q+1);
  for I := 0 to Q do SetLength(ThetaMat[I], Q+1);

  V[0] := SliceVar(Y, 0, N-1);
  for I := 1 to Q do
  begin
    Sum := AcfVals[I] * (N-1) / (N-0) * V[0]; { approximate cov }
    for J := 1 to I-1 do
      Sum := Sum - ThetaMat[I][I-J] * ThetaMat[J][J] * V[I-J];
    if Abs(V[I-1]) < 1E-15 then
      raise ETimeSeriesError.Create('MAFit: innovations variance became zero');
    ThetaMat[I][I] := Sum / V[I-1];
    V[I] := V[I-1] * (1 - ThetaMat[I][I] * ThetaMat[I][I]);
    if V[I] < 0 then V[I] := 0;
    for J := 1 to I-1 do
      ThetaMat[I][J] := ThetaMat[I-1][J] - ThetaMat[I][I] * ThetaMat[I-1][I-J];
    Theta[I-1] := ThetaMat[I][I];
  end;

  Result.P        := 0;
  Result.Q        := Q;
  Result.D        := 0;
  Result.Mu       := SliceMean(Y, 0, N-1);
  Result.Sigma2   := V[Q];
  Result.MACoeffs := Theta;
  SetLength(Result.ARCoeffs, 0);
end;

class function TTimeSeriesKit.ARIMAFit(const Y: TDoubleArray; P, D, Q: Integer): TARIMAModel;
var
  Z: TDoubleArray;
  ARMod, MAMod: TARIMAModel;
  N, I, J: Integer;
  Resid: TDoubleArray;
begin
  if (P < 0) or (D < 0) or (Q < 0) then
    raise ETimeSeriesError.Create('ARIMAFit: P, D, and Q must be >= 0');
  if Length(Y) <= D + Max(P, Q) then
    raise ETimeSeriesError.Create('ARIMAFit: series is too short for requested orders');
  RequireFiniteSeries(Y, 'ARIMAFit');

  { Step 1: difference D times }
  Z := Difference(Y, D);

  { Step 2: fit AR(p) to differenced series }
  if P > 0 then ARMod := ARFit(Z, P)
  else
  begin
    ARMod.P := 0; ARMod.Q := 0; ARMod.D := D;
    ARMod.Mu := SliceMean(Z, 0, High(Z));
    ARMod.Sigma2 := SliceVar(Z, 0, High(Z));
    SetLength(ARMod.ARCoeffs, 0);
    SetLength(ARMod.MACoeffs, 0);
  end;

  { Step 3: compute AR residuals }
  N := Length(Z);
  SetLength(Resid, N);
  for I := 0 to N-1 do
  begin
    Resid[I] := Z[I] - ARMod.Mu;
    for J := 0 to P-1 do
      if I-J-1 >= 0 then
        Resid[I] := Resid[I] - ARMod.ARCoeffs[J] * (Z[I-J-1] - ARMod.Mu);
  end;

  { Step 4: fit MA(q) to residuals }
  if Q > 0 then MAMod := MAFit(Resid, Q)
  else
  begin
    SetLength(MAMod.MACoeffs, 0);
  end;

  Result.P        := P;
  Result.Q        := Q;
  Result.D        := D;
  Result.Mu       := ARMod.Mu;
  Result.Sigma2   := ARMod.Sigma2;
  Result.ARCoeffs := ARMod.ARCoeffs;
  if Q > 0 then Result.MACoeffs := MAMod.MACoeffs
  else SetLength(Result.MACoeffs, 0);
end;

class function TTimeSeriesKit.ARIMAForecast(
  const Model: TARIMAModel;
  const OriginalY: TDoubleArray;
  H: Integer): TDoubleArray;
var
  Z, ZFcast, Buffer, Residual, States, Current: TDoubleArray;
  I, J, D, N, P, Q, TimeIndex, ResidualIndex, Ord: Integer;
  Prediction, Value: Double;
begin
  D := Model.D;
  N := Length(OriginalY);
  P := Model.P;
  Q := Model.Q;
  if H < 1 then raise ETimeSeriesError.Create('ARIMAForecast: H must be >= 1');
  if (P < 0) or (Q < 0) or (D < 0) then raise ETimeSeriesError.Create(
    'ARIMAForecast: model orders must be >= 0');
  if Length(Model.ARCoeffs) <> P then raise ETimeSeriesError.Create(
    'ARIMAForecast: AR coefficient count does not match model P');
  if Length(Model.MACoeffs) <> Q then raise ETimeSeriesError.Create(
    'ARIMAForecast: MA coefficient count does not match model Q');
  if N <= D then raise ETimeSeriesError.Create(
    'ARIMAForecast: series is too short for differencing order');
  if IsNan(Model.Mu) or IsInfinite(Model.Mu) then raise ETimeSeriesError.Create(
    'ARIMAForecast: model mean must be finite');
  RequireFiniteSeries(OriginalY, 'ARIMAForecast');
  RequireFiniteSeries(Model.ARCoeffs, 'ARIMAForecast AR coefficients');
  RequireFiniteSeries(Model.MACoeffs, 'ARIMAForecast MA coefficients');

  Z := Difference(OriginalY, D);
  if Length(Z) < P then raise ETimeSeriesError.Create(
    'ARIMAForecast: differenced history is shorter than model P');

  { Recover the innovations under the supplied ARMA model. }
  SetLength(Buffer, Length(Z) + H);
  SetLength(Residual, Length(Z) + H);
  for I := 0 to High(Z) do Buffer[I] := Z[I];
  for I := 0 to High(Z) do
  begin
    Prediction := Model.Mu;
    for J := 0 to P - 1 do
      if I - J - 1 >= 0 then
        Prediction := Prediction + Model.ARCoeffs[J] *
          (Buffer[I - J - 1] - Model.Mu);
    for J := 0 to Q - 1 do
      if I - J - 1 >= 0 then
        Prediction := Prediction + Model.MACoeffs[J] * Residual[I - J - 1];
    Residual[I] := Buffer[I] - Prediction;
  end;

  SetLength(ZFcast, H);
  for I := 0 to H - 1 do
  begin
    TimeIndex := Length(Z) + I;
    Prediction := Model.Mu;
    for J := 0 to P - 1 do
      if TimeIndex - J - 1 >= 0 then
        Prediction := Prediction + Model.ARCoeffs[J] *
          (Buffer[TimeIndex - J - 1] - Model.Mu);
    for J := 0 to Q - 1 do
    begin
      ResidualIndex := TimeIndex - J - 1;
      if (ResidualIndex >= 0) and (ResidualIndex < Length(Z)) then
        Prediction := Prediction + Model.MACoeffs[J] * Residual[ResidualIndex];
    end;
    Buffer[TimeIndex] := Prediction;
    Residual[TimeIndex] := 0.0;
    ZFcast[I] := Prediction;
  end;

  if D = 0 then
    Exit(ZFcast);

  { States[k] is the last observed value at differencing order k. }
  SetLength(States, D);
  Current := Copy(OriginalY);
  for Ord := 0 to D - 1 do
  begin
    States[Ord] := Current[High(Current)];
    Current := Difference(Current, 1);
  end;
  SetLength(Result, H);
  for I := 0 to H - 1 do
  begin
    Value := ZFcast[I];
    for Ord := D - 1 downto 0 do
    begin
      States[Ord] := States[Ord] + Value;
      Value := States[Ord];
    end;
    Result[I] := Value;
  end;
end;

{ ---------------------------------------------------------------------------
  CHANGE-POINT & ANOMALY DETECTION
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.CUSUMDetect(const Y: TDoubleArray; Threshold: Double; Target: Double): TCUSUMResult;
var
  N, I: Integer;
  Mu, StdDev, CS, Sum, SumSq: Double;
begin
  Result := Default(TCUSUMResult);
  N := Length(Y);
  if N < 2 then raise ETimeSeriesError.Create('CUSUMDetect: need at least 2 points');

  Sum := 0; SumSq := 0;
  for I := 0 to N-1 do begin Sum := Sum + Y[I]; SumSq := SumSq + Y[I]*Y[I]; end;
  Mu     := IfThen(IsNan(Target), Sum / N, Target);
  StdDev := Sqrt(Max(0, SumSq/N - Sqr(Sum/N)));
  if StdDev < 1E-12 then StdDev := 1;

  SetLength(Result.CUSUMValues, N);
  CS := 0;
  Result.ChangePoint := -1;
  Result.Detected    := False;

  for I := 0 to N-1 do
  begin
    CS := CS + (Y[I] - Mu);
    Result.CUSUMValues[I] := CS;
    if (not Result.Detected) and (Threshold > 0) and
       (Abs(CS) > Threshold * StdDev) then
    begin
      Result.ChangePoint := I;
      Result.Detected    := True;
    end;
  end;
end;

class function TTimeSeriesKit.ZScoreAnomalies(const Y: TDoubleArray; Threshold: Double): TIntegerArray;
var
  N, I, Count: Integer;
  Mu, StdDev, Sum, SumSq: Double;
begin
  Result := nil;
  N := Length(Y);
  Sum := 0; SumSq := 0;
  for I := 0 to N-1 do begin Sum := Sum + Y[I]; SumSq := SumSq + Y[I]*Y[I]; end;
  Mu     := Sum / N;
  StdDev := Sqrt(Max(0, SumSq/N - Sqr(Mu)));
  if StdDev < 1E-12 then begin SetLength(Result, 0); Exit; end;

  Count := 0;
  SetLength(Result, N);
  for I := 0 to N-1 do
    if Abs((Y[I] - Mu) / StdDev) > Threshold then
    begin
      Result[Count] := I;
      Inc(Count);
    end;
  SetLength(Result, Count);
end;

class function TTimeSeriesKit.RollingZScore(const Y: TDoubleArray; Window: Integer; Threshold: Double): TIntegerArray;
var
  N, I, Lo, Count, J, WN: Integer;
  Mu, StdDev, Sum, SumSq: Double;
begin
  Result := nil;
  N := Length(Y);
  if Window < 2 then raise ETimeSeriesError.Create('RollingZScore: Window must be >= 2');
  Count := 0;
  SetLength(Result, N);
  for I := 0 to N-1 do
  begin
    Lo  := Max(0, I - Window + 1);
    Sum := 0; SumSq := 0;
    for J := Lo to I do begin Sum := Sum+Y[J]; SumSq := SumSq+Y[J]*Y[J]; end;
    WN := I - Lo + 1;
    if WN < 2 then Continue;
    Mu     := Sum / WN;
    StdDev := Sqrt(Max(0, SumSq/WN - Sqr(Mu)));
    if StdDev < 1E-12 then Continue;
    if Abs((Y[I] - Mu) / StdDev) > Threshold then
    begin
      Result[Count] := I;
      Inc(Count);
    end;
  end;
  SetLength(Result, Count);
end;

{ ---------------------------------------------------------------------------
  TREND & SEASONALITY UTILITIES
--------------------------------------------------------------------------- }

class function TTimeSeriesKit.LinearTrend(const Y: TDoubleArray): TLinearTrend;
{ OLS: Y = a + b*t,  t = 0..N-1 }
var
  N, I: Integer;
  SumT, SumY, SumTY, SumT2, TBar, YBar, SST, SSR, Denom: Double;
begin
  N := Length(Y);
  if N < 2 then raise ETimeSeriesError.Create('LinearTrend: need at least 2 points');
  SumT := 0; SumY := 0; SumTY := 0; SumT2 := 0;
  for I := 0 to N-1 do
  begin
    SumT  := SumT  + I;
    SumY  := SumY  + Y[I];
    SumTY := SumTY + I * Y[I];
    SumT2 := SumT2 + I * I;
  end;
  TBar := SumT / N;
  YBar := SumY / N;
  Denom := SumT2 - N * TBar * TBar;
  if Abs(Denom) < 1E-14 then
  begin
    Result.Slope     := 0;
    Result.Intercept := YBar;
    Result.RSquared  := 0;
    Exit;
  end;
  Result.Slope     := (SumTY - N * TBar * YBar) / Denom;
  Result.Intercept := YBar - Result.Slope * TBar;

  SST := 0; SSR := 0;
  for I := 0 to N-1 do
  begin
    SST := SST + Sqr(Y[I] - YBar);
    SSR := SSR + Sqr(Y[I] - (Result.Intercept + Result.Slope * I));
  end;
  if SST > 1E-14 then Result.RSquared := 1 - SSR/SST else Result.RSquared := 0;
end;

class function TTimeSeriesKit.DetrendLinear(const Y: TDoubleArray): TDoubleArray;
var
  T: TLinearTrend;
  I: Integer;
begin
  T := LinearTrend(Y);
  Result := nil;
  SetLength(Result, Length(Y));
  for I := 0 to High(Y) do
    Result[I] := Y[I] - (T.Intercept + T.Slope * I);
end;

class function TTimeSeriesKit.SeasonalStrength(const Decomp: TDecomposition): Double;
{ F_S = max(0, 1 - Var(R) / Var(S+R)) }
var
  N, I: Integer;
  SR: TDoubleArray;
  VarR, VarSR: Double;
begin
  N := Length(Decomp.Residual);
  if N < 2 then Exit(0);
  SetLength(SR, N);
  for I := 0 to N-1 do SR[I] := Decomp.Seasonal[I] + Decomp.Residual[I];
  VarR  := SliceVar(Decomp.Residual, 0, N-1);
  VarSR := SliceVar(SR, 0, N-1);
  if VarSR < 1E-15 then Exit(0);
  Result := Max(0, 1 - VarR / VarSR);
end;

class function TTimeSeriesKit.Periodogram(const Y: TDoubleArray): TDoubleArray;
{ Power spectrum via zero-padded FFT: |X[k]|^2 / NPow, one-sided subset. }
var
  N, NF, I, J, K, NPow, Len: Integer;
  Re, Im: TDoubleArray;
  Angle, WR, WI, Ur, Ui, TR, TI, Tmp: Double;
begin
  N  := Length(Y);
  if N < 2 then raise ETimeSeriesError.Create(
    'Periodogram: at least two observations are required');
  RequireFiniteSeries(Y, 'Periodogram');
  { Pad to power of 2 }
  NPow := 1;
  while NPow < N do NPow := NPow shl 1;
  NF := NPow div 2 + 1;
  SetLength(Re, NPow);
  SetLength(Im, NPow);
  for I := 0 to N-1 do Re[I] := Y[I];

  { Bit-reversal permutation }
  J := 0;
  for I := 1 to NPow-1 do
  begin
    K := NPow shr 1;
    while J >= K do begin J := J - K; K := K shr 1; end;
    J := J + K;
    if I < J then
    begin
      Tmp := Re[I]; Re[I] := Re[J]; Re[J] := Tmp;
      Tmp := Im[I]; Im[I] := Im[J]; Im[J] := Tmp;
    end;
  end;
  { In-place FFT }
  Len := 1;
  while Len < NPow do
  begin
    Len  := Len shl 1;
    Angle := -2 * Pi / Len;
    WR   := Cos(Angle);
    WI   := Sin(Angle);
    I    := 0;
    while I < NPow do
    begin
      Ur := 1; Ui := 0;
      for J := 0 to Len div 2 - 1 do
      begin
        K      := I + J + Len div 2;
        TR     := Ur*Re[K] - Ui*Im[K];
        TI     := Ur*Im[K] + Ui*Re[K];
        Re[K]  := Re[I+J] - TR;  Im[K]  := Im[I+J] - TI;
        Re[I+J] := Re[I+J] + TR; Im[I+J] := Im[I+J] + TI;
        Tmp := Ur*WR - Ui*WI; Ui := Ur*WI + Ui*WR; Ur := Tmp;
      end;
      Inc(I, Len);
    end;
  end;

  Result := nil;
  SetLength(Result, NF);
  for I := 0 to NF-1 do
    Result[I] := (Re[I]*Re[I] + Im[I]*Im[I]) / NPow;
end;

class function TTimeSeriesKit.PeriodogramPeak(const Y: TDoubleArray; MinPeriod, MaxPeriod: Integer): Integer;
{ Find frequency bin k with highest power; period = NPow/k. }
var
  N, NF, NPow, I, KMin, KMax, BestK: Integer;
  Psd: TDoubleArray;
  BestPow: Double;
begin
  N  := Length(Y);
  if N < 4 then raise ETimeSeriesError.Create(
    'PeriodogramPeak: at least four observations are required');
  if MaxPeriod <= 0 then MaxPeriod := N div 2;
  if (MinPeriod < 2) or (MaxPeriod < MinPeriod) or (MaxPeriod > N) then
    raise ETimeSeriesError.Create('PeriodogramPeak: invalid period bounds');

  Psd := Periodogram(Y);
  NF := Length(Psd);
  NPow := 2 * (NF - 1);

  KMin := Max(1, (NPow + MaxPeriod - 1) div MaxPeriod);
  KMax := Min(NF-1, NPow div MinPeriod);
  if KMin > KMax then raise ETimeSeriesError.Create(
    'PeriodogramPeak: period bounds contain no FFT bins');

  BestPow := -1; BestK := KMin;
  for I := KMin to KMax do
    if Psd[I] > BestPow then begin BestPow := Psd[I]; BestK := I; end;

  Result := IfThen(BestK > 0, Round(NPow / BestK), 0);
end;

end.
