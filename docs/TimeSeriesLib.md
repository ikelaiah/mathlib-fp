# TimeSeriesLib Reference

`TimeSeriesLib.TimeSeries` — time series analysis for Free Pascal.

---

## Quick Start

```pascal
uses TimeSeriesLib.TimeSeries;

// Smooth a noisy series with a 5-point moving average
smooth := TTimeSeriesKit.SimpleMovingAverage(prices, 5);

// Fit and forecast an ARIMA(1,1,0) model
model  := TTimeSeriesKit.ARIMAFit(sales, 1, 1, 0);
fcast  := TTimeSeriesKit.ARIMAForecast(model, sales, 12);  // 12 steps ahead

// Detect anomalies more than 3 standard deviations from the mean
idx := TTimeSeriesKit.ZScoreAnomalies(readings, 3.0);

// Find the dominant seasonal period
period := TTimeSeriesKit.PeriodogramPeak(Y);
```

All methods are **class static** — no `Create`/`Free` needed.

---

## Result Records

```pascal
TDecomposition = record
  Trend:    TDoubleArray;   { smoothed trend }
  Seasonal: TDoubleArray;   { repeating seasonal component }
  Residual: TDoubleArray;   { remainder }
  DecompType: TDecompType;
end;

TARIMAModel = record
  ARCoeffs: TDoubleArray;   { phi_1 .. phi_p }
  MACoeffs: TDoubleArray;   { theta_1 .. theta_q }
  D:        Integer;         { integration order }
  Mu:       Double;          { mean of differenced series }
  Sigma2:   Double;          { innovation variance }
  P, Q:     Integer;
end;

TLinearTrend = record
  Intercept: Double;
  Slope:     Double;
  RSquared:  Double;
end;

TADFResult = record
  Statistic:    Double;
  Crit1Pct:     Double;   { MacKinnon 1% critical value }
  Crit5Pct:     Double;   { MacKinnon 5% critical value }
  Crit10Pct:    Double;   { MacKinnon 10% critical value }
  IsStationary: Boolean;  { True if Statistic < Crit5Pct }
end;

TCUSUMResult = record
  CUSUMValues: TDoubleArray;
  ChangePoint: Integer;   { -1 if not detected }
  Detected:    Boolean;
end;
```

---

## Smoothing & Filtering

### SimpleMovingAverage

```pascal
smooth := TTimeSeriesKit.SimpleMovingAverage(Y, Window);
```

Centred moving average. Each output point is the mean of `Window` surrounding values. Edge points use whatever data is available (no padding). Output is the same length as input.

**When to use:** removing short-term noise while preserving long-term trend.

### WeightedMovingAverage

```pascal
smooth := TTimeSeriesKit.WeightedMovingAverage(Y, Window);
```

Like SMA but assigns linearly increasing weights to more recent values (weight ∝ position). Reacts faster to recent changes than SMA.

### ExponentialSmoothing

```pascal
smooth := TTimeSeriesKit.ExponentialSmoothing(Y, Alpha);
smooth := TTimeSeriesKit.ExponentialSmoothing(Y, Alpha, InitValue);
```

S_t = Alpha × Y_t + (1 − Alpha) × S_{t−1}

- **Alpha near 0:** heavy smoothing, slow response
- **Alpha near 1:** tracks data closely (Alpha=1 is identity)
- `InitValue`: seed value for S_0 (defaults to Y[0])

### DoubleExponentialSmoothing (Holt's Method)

```pascal
smooth := TTimeSeriesKit.DoubleExponentialSmoothing(Y, Alpha, Beta);
```

Tracks **level** and **trend** separately. Good for data with a linear trend but no seasonality.

- `Alpha`: level smoothing (0..1)
- `Beta`: trend smoothing (0..1)

### TripleExponentialSmoothing (Holt-Winters)

```pascal
smooth := TTimeSeriesKit.TripleExponentialSmoothing(Y, Alpha, Beta, Gamma, Period);
smooth := TTimeSeriesKit.TripleExponentialSmoothing(Y, Alpha, Beta, Gamma, Period, dtMultiplicative);
```

Handles data with both **trend** and **seasonality**.

- `Alpha`: level smoothing
- `Beta`: trend smoothing
- `Gamma`: seasonal smoothing
- `Period`: seasonal cycle length (e.g. 12 for monthly, 7 for daily-with-weekly-cycle)
- `DType`: `dtAdditive` (default) or `dtMultiplicative`

### HoltWintersForecast

```pascal
fcast := TTimeSeriesKit.HoltWintersForecast(Y, Alpha, Beta, Gamma, Period, H);
```

Projects H steps ahead using the Holt-Winters state at the end of Y. Returns array of length H.
Pass `Period >= 2`, at least two full seasons, `H >= 1`, and smoothing
parameters in `(0,1]`. `TripleExponentialSmoothing` validates these controls;
`HoltWintersForecast` does not currently validate all of them.

---

## Decomposition

### Decompose

```pascal
D := TTimeSeriesKit.Decompose(Y, Period);
D := TTimeSeriesKit.Decompose(Y, Period, dtMultiplicative);
```

Classical decomposition:
1. Trend = centred moving average of width `Period`
2. Seasonal indices = average detrended values per cycle position
3. Residual = Y − Trend − Seasonal (additive) or Y / (Trend × Seasonal) (multiplicative)

Edge values in Trend are NaN (cannot centre the window at the boundaries).
Residual calculation substitutes the observed value for an undefined edge
trend. Pass `Period >= 2` and at least two complete periods; period validity is
otherwise a caller requirement.

---

## Differencing & Stationarity

### Difference

```pascal
d1 := TTimeSeriesKit.Difference(Y, 1);   // first differences:  Y[t] - Y[t-1]
d2 := TTimeSeriesKit.Difference(Y, 2);   // second differences: Diff(Diff(Y))
```

Output length = N − d. Used to convert a non-stationary series to stationary before fitting ARIMA.

### Undifference

```pascal
orig := TTimeSeriesKit.Undifference(DiffY, InitVals, D);
```

Inverts differencing. `InitVals` must contain at least the first `D` values of
the original series (needed to reconstruct the integration constants). Extra
values are ignored.

### AugmentedDickeyFuller

```pascal
adf := TTimeSeriesKit.AugmentedDickeyFuller(Y);
adf := TTimeSeriesKit.AugmentedDickeyFuller(Y, Lags);
```

Tests whether the series has a **unit root** (non-stationary).

- H₀: series has a unit root → non-stationary
- H₁: series is stationary
- Reject H₀ when `adf.Statistic < adf.Crit5Pct`
- `adf.IsStationary` = True means you can reject H₀ at the 5% level

**Rule of thumb:** if `IsStationary = False`, apply one round of differencing and test again.

---

## Autocorrelation

### ACF

```pascal
acf := TTimeSeriesKit.ACF(Y, MaxLag);
// acf[0] = 1.0, acf[k] = autocorrelation at lag k
```

Use the ACF plot to identify the **MA order q**: ACF cuts off sharply after lag q.

### PACF

```pascal
pacf := TTimeSeriesKit.PACF(Y, MaxLag);
// pacf[0] = 1.0, pacf[k] = partial autocorrelation at lag k
```

Computed via Yule-Walker equations. Use to identify the **AR order p**: PACF cuts off after lag p.

### LjungBox

```pascal
Q := TTimeSeriesKit.LjungBox(Y, MaxLag);
```

Tests whether the first `MaxLag` autocorrelations are jointly zero.  
Compare to chi-squared critical value with `MaxLag` degrees of freedom.  
**Rule of thumb:** Q > 3.84 (χ² df=1, 5%) → series is not white noise.

---

## ARIMA Models

### Model Order Selection Cheat Sheet

| Pattern | Likely model |
|---|---|
| ACF decays, PACF cuts off at lag p | AR(p) |
| ACF cuts off at lag q, PACF decays | MA(q) |
| Both decay | ARMA(p,q) |
| ADF non-stationary | Difference once → try again |

### ARFit

```pascal
model := TTimeSeriesKit.ARFit(Y, P);
// model.ARCoeffs[0..P-1] = phi coefficients
```

Fits AR(p) via Yule-Walker equations. Fast and exact for pure AR series.

### ARForecast

```pascal
fcast := TTimeSeriesKit.ARForecast(model, History, H);
```

Recursive H-step forecast from the last P values of History.

### MAFit

```pascal
model := TTimeSeriesKit.MAFit(Y, Q);
```

Fits MA(q) via the innovations algorithm. Returns theta coefficients and innovation variance.

### ARIMAFit

```pascal
model := TTimeSeriesKit.ARIMAFit(Y, P, D, Q);
```

Full ARIMA(p,d,q) fit:
1. Differences Y by order D
2. Fits AR(p) to differenced series
3. Fits MA(q) to AR residuals

### ARIMAForecast

```pascal
fcast := TTimeSeriesKit.ARIMAForecast(model, OriginalY, H);
```

Forecasts H steps ahead and undifferences the result back to original scale.
Historical AR residuals are reconstructed to seed the MA terms; unknown future
innovations are set to zero, as in the standard conditional-mean forecast.
Integrated models retain the last required difference states and return exactly
`H` forecasts on the original scale for any supported `D`.

---

## Change-point & Anomaly Detection

### CUSUMDetect

```pascal
R := TTimeSeriesKit.CUSUMDetect(Y);
R := TTimeSeriesKit.CUSUMDetect(Y, Threshold, Target);
```

Accumulates deviations from `Target` (defaults to sample mean).  
`ChangePoint` = first index where |CUSUM| exceeds `Threshold × StdDev`.  
Set `Threshold = 0` to return the CUSUM series without detection.

### ZScoreAnomalies

```pascal
idx := TTimeSeriesKit.ZScoreAnomalies(Y);
idx := TTimeSeriesKit.ZScoreAnomalies(Y, Threshold);  // default 3.0
```

Returns indices of points more than `Threshold` standard deviations from the series mean.

### RollingZScore

```pascal
idx := TTimeSeriesKit.RollingZScore(Y, Window);
idx := TTimeSeriesKit.RollingZScore(Y, Window, Threshold);
```

Like ZScoreAnomalies but computed within a rolling window. Catches **local** anomalies that a global z-score would miss (e.g. a spike in an otherwise flat segment of a trending series).

---

## Trend & Seasonality Utilities

### LinearTrend

```pascal
T := TTimeSeriesKit.LinearTrend(Y);
// T.Intercept, T.Slope, T.RSquared
```

OLS fit of y = a + b×t (t = 0, 1, ..., N−1).

### DetrendLinear

```pascal
residuals := TTimeSeriesKit.DetrendLinear(Y);
```

Subtracts the fitted linear trend. OLS residuals always sum to zero.

### SeasonalStrength

```pascal
strength := TTimeSeriesKit.SeasonalStrength(Decomp);
```

= max(0, 1 − Var(Residual) / Var(Seasonal + Residual))

- Near 1.0 → strong, dominant seasonality
- Near 0.0 → little to no seasonality

### PeriodogramPeak

```pascal
period := TTimeSeriesKit.PeriodogramPeak(Y);
period := TTimeSeriesKit.PeriodogramPeak(Y, MinPeriod, MaxPeriod);
```

FFT-based dominant period detection. Returns the period (in samples) of the
largest spectral peak, excluding the DC component. Non-power-of-two inputs are
zero-padded to `NPow`, and period conversion uses that FFT length, so the same
frequency-bin mapping applies to every input length.

### Periodogram

```pascal
psd := TTimeSeriesKit.Periodogram(Y);
// psd[k] = power at frequency k/NPow, where NPow is the next power of two
```

One-sided power spectrum. The input is zero-padded to `NPow`, the next power of
two. Returned bin `k` therefore corresponds to `k / NPow`, not `k / N`; the
result contains `NPow div 2 + 1` bins, including DC and Nyquist.

---

## Error Handling

`ETimeSeriesError` is raised by the relevant methods for:

- empty input in SMA, WMA, and exponential smoothing
- insufficient observations for Holt smoothing, decomposition, ADF, ACF, AR,
  CUSUM, or linear trend
- invalid smoothing parameters in exponential, double, and triple smoothing
- invalid positive window/order/horizon controls where explicitly checked
- `ACF` with `MaxLag >= N`
- `Difference` with `D < 0` or an order too large for the series
- `Undifference` with fewer than `D` initial values
- non-finite observations or coefficients in model fitting and forecasting
- incompatible AR/MA/ARIMA orders, history lengths, or non-positive horizons
- invalid period bounds or series too short to contain a searchable FFT bin

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`, `TIntegerArray`

No other external libraries required.
