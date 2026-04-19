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

Inverts differencing. `InitVals` must contain the first `D` values of the original series (needed to reconstruct the integration constants).

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

FFT-based dominant period detection. Returns the period (in samples) of the largest spectral peak, excluding the DC component.

### Periodogram

```pascal
psd := TTimeSeriesKit.Periodogram(Y);
// psd[k] = power at frequency k/N, for k = 0..N/2
```

Full power spectral density (one-sided).

---

## Error Handling

`ETimeSeriesError` is raised for:
- Empty input array
- Window or order parameter ≤ 0 (where not meaningful)
- AR/PACF order ≥ N
- ACF MaxLag ≥ N
- Difference D < 0
- Undifference InitVals length ≠ D

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`, `TIntegerArray`
- `MathBase.Precision` — `GammaLn`, `Erf` (used internally)

No other external libraries required.
