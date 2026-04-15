# StatsLib

Statistical analysis library for Free Pascal covering descriptive statistics, hypothesis testing, correlation, normality tests, robust methods, bootstrap, and non-parametric tests.

Depends on: **MathBase**

## Units

| Unit | File | Class |
|------|------|-------|
| `StatsLib.Stats` | [StatsLib.Stats.pas](StatsLib.Stats.pas) | `TStatsKit` |

---

## Core Types

### Exception

```pascal
EStatsError = class(Exception);
```

Raised on empty input arrays, insufficient data for a given calculation, or invalid parameter values.

### TDescriptiveStats Record

A single call to `TStatsKit.Describe(Data)` populates all fields:

| Field | Type | Description |
|-------|------|-------------|
| `N` | `Integer` | Number of observations |
| `Mean` | `Double` | Arithmetic mean |
| `Median` | `Double` | Middle value of sorted data |
| `Mode` | `Double` | Most frequent value (first mode if multimodal) |
| `Q1` | `Double` | First quartile (25th percentile) |
| `Q3` | `Double` | Third quartile (75th percentile) |
| `Min` | `Double` | Minimum value |
| `Max` | `Double` | Maximum value |
| `Range` | `Double` | Max − Min |
| `IQR` | `Double` | Q3 − Q1 |
| `Variance` | `Double` | Sample variance (n − 1 denominator) |
| `StdDev` | `Double` | Population standard deviation (n denominator) |
| `Skewness` | `Double` | Distribution asymmetry; positive = right tail |
| `Kurtosis` | `Double` | Sample excess kurtosis; 0 for normal |
| `SEM` | `Double` | Standard error of the mean |
| `CV` | `Double` | Coefficient of variation (%) |

```pascal
function TDescriptiveStats.ToString: string;     // Vertical summary
function TDescriptiveStats.ToStringWide: string; // Table-like summary
```

---

## TStatsKit — Static Methods

All methods are `class ... static` — no instance required. Input data is always `TDoubleArray`.

### Descriptive Statistics

| Method | Min N | Description |
|--------|-------|-------------|
| `Mean(Data)` | 1 | Arithmetic mean |
| `Median(Data)` | 1 | Middle value; average of two middles for even N |
| `Mode(Data)` | 1 | Most frequent value |
| `Range(Data)` | 1 | Max − Min |
| `Describe(Data)` | 1 | Full `TDescriptiveStats` record |

```pascal
var Data: TDoubleArray;
    Stats: TDescriptiveStats;
begin
  Data := TDoubleArray.Create(1, 2, 3, 4, 5);
  Stats := TStatsKit.Describe(Data);
  Writeln(Stats.ToString);
end.
```

### Variance and Standard Deviation

| Method | Denominator | Min N |
|--------|-------------|-------|
| `Variance(Data)` | n − 1 | 2 |
| `SampleVariance(Data)` | n − 1 | 2 | (alias of `Variance`) |
| `StandardDeviation(Data)` | **n** (population) | 2 |
| `SampleStandardDeviation(Data)` | n − 1 | 2 |

### Distribution Measures

```pascal
class function Skewness(const Data: TDoubleArray): Double;  // Requires N >= 3
class function Kurtosis(const Data: TDoubleArray): Double;  // Sample excess kurtosis; N >= 4
class function SEM(const Data: TDoubleArray): Double;       // StdDev / √N
class function CV(const Data: TDoubleArray): Double;        // (StdDev / Mean) * 100
```

### Percentiles and Quartiles

```pascal
class function Percentile(const Data: TDoubleArray; const P: Double): Double; // 0 <= P <= 100; method R-7
class function Quartile1(const Data: TDoubleArray): Double;   // Percentile(Data, 25)
class function Quartile3(const Data: TDoubleArray): Double;   // Percentile(Data, 75)
class function IQR(const Data: TDoubleArray): Double;         // Q3 − Q1
```

Percentile uses linear interpolation (Excel/R default, method R-7).

### Correlation and Covariance

```pascal
class function PearsonCorrelation(const X, Y: TDoubleArray): Double;  // r ∈ [−1, 1]
class function SpearmanCorrelation(const X, Y: TDoubleArray): Double; // ρ ∈ [−1, 1]
class function Covariance(const X, Y: TDoubleArray): Double;          // Sample covariance
class function CovarianceMatrix(const Data: array of TDoubleArray): TMatrixResult; // N × N matrix
```

### Standardisation

```pascal
class function ZScores(const Data: TDoubleArray): TDoubleArray;         // (xi − mean) / stddev
class function Standardize(const Data: TDoubleArray): TDoubleArray;     // Alias of ZScores
class function Normalize(const Data: TDoubleArray): TDoubleArray;       // Scale to [0, 1]
```

### Hypothesis Testing

#### One-Sample and Two-Sample t-Tests

```pascal
class function OneSampleTTest(const Data: TDoubleArray; HypothesisedMean: Double): Double;
class function TwoSampleTTest(const Data1, Data2: TDoubleArray): Double;  // Independent samples
class function PairedTTest(const Data1, Data2: TDoubleArray): Double;
```

Returns the t-statistic. Use `MathBase.Precision.StudentT` to obtain the p-value.

### Normality Tests

```pascal
class function KolmogorovSmirnovTest(const Data: TDoubleArray): Double;  // KS statistic
class function ShapiroWilkTest(const Data: TDoubleArray): Double;        // W statistic
```

Higher W (closer to 1) indicates normality.

### Non-Parametric Tests

| Method | Description |
|--------|-------------|
| `SignTest(Data, HypothesisedMedian)` | Sign test statistic |
| `WilcoxonSignedRank(Data1, Data2)` | Wilcoxon signed-rank W statistic |
| `MannWhitneyU(Data1, Data2)` | Mann-Whitney U statistic |
| `KendallTau(X, Y)` | Kendall's τ correlation |

### Robust Statistics

```pascal
class function MedianAbsoluteDeviation(const Data: TDoubleArray): Double;  // MAD
class function HuberMEstimator(const Data: TDoubleArray; k: Double = 1.345): Double;
```

MAD and the Huber M-estimator are resistant to outliers.

### Effect Size

```pascal
class function CohenD(const Data1, Data2: TDoubleArray): Double;    // Cohen's d
class function HedgesG(const Data1, Data2: TDoubleArray): Double;   // Hedges' g (bias-corrected)
```

Interpretation: 0.2 = small, 0.5 = medium, 0.8 = large.

### Bootstrap Methods

```pascal
class function BootstrapMean(const Data: TDoubleArray; Iterations: Integer = 1000): Double;
class function BootstrapCI(const Data: TDoubleArray; Confidence: Double = 0.95;
  Iterations: Integer = 1000): TDoublePair;
```

`TDoublePair` (from `MathBase.SharedTypes`) holds `Lower` and `Upper` confidence bounds.

> Call `Randomize` before using bootstrap methods to seed the random generator.

---

## Quick Start

```pascal
uses StatsLib.Stats, MathBase.SharedTypes;

var
  Data1, Data2: TDoubleArray;
  Stats: TDescriptiveStats;
  CI: TDoublePair;
  r: Double;
begin
  Data1 := TDoubleArray.Create(2.1, 3.5, 2.8, 4.2, 3.0, 3.7, 2.5, 4.1);
  Data2 := TDoubleArray.Create(3.0, 4.1, 3.5, 5.0, 3.8, 4.5, 3.2, 5.1);

  Stats := TStatsKit.Describe(Data1);
  Writeln(Stats.ToStringWide);

  r := TStatsKit.PearsonCorrelation(Data1, Data2);
  Writeln('r = ', r:0:4);

  Randomize;
  CI := TStatsKit.BootstrapCI(Data1, 0.95, 2000);
  Writeln('95% CI: [', CI.Lower:0:4, ', ', CI.Upper:0:4, ']');
end.
```

---

## Design Notes

- `Variance` and `SampleVariance` both use the **n − 1** (Bessel-corrected) denominator.
- `StandardDeviation` uses the **n** (population) denominator; use `SampleStandardDeviation` for the n − 1 version.
- `Skewness` uses the population standard deviation; `Kurtosis` uses the sample standard deviation.
- Percentile uses **method R-7** (linear interpolation), matching Excel's `PERCENTILE` and R's default.
- Bootstrap results depend on the random seed — call `Randomize` for non-deterministic runs.
- `EStatsError` is raised for empty arrays, arrays too small for a given statistic, or out-of-range parameters.
