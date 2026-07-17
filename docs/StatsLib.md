# StatsLib

Statistical analysis library for Free Pascal covering descriptive statistics, hypothesis testing, correlation, normality tests, robust methods, bootstrap, and non-parametric tests.

Depends on: **MathBase**

## Units

| Unit | File | Class |
|------|------|-------|
| `StatsLib.Stats` | [StatsLib.Stats.pas](../src/StatsLib.Stats.pas) | `TStatsKit` |

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
| `Describe(Data)` | 4 | Full `TDescriptiveStats` record; inherited constraints (such as non-zero spread and mean) also apply |

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
| `SampleVariance(Data)` | n − 1 | 2 (same calculation as `Variance`) |
| `StandardDeviation(Data)` | **n** (population) | 2 |
| `SampleStandardDeviation(Data)` | n − 1 | 2 |

### Distribution Measures and Aggregates

```pascal
class function Skewness(const Data: TDoubleArray): Double;            // N >= 3
class function Kurtosis(const Data: TDoubleArray): Double;            // Sample excess kurtosis; N >= 4
class function StandardErrorOfMean(const Data: TDoubleArray): Double; // SampleStdDev / sqrt(N); N >= 2
class function CoefficientOfVariation(const Data: TDoubleArray): Double; // PopulationStdDev / abs(Mean) * 100
class function GeometricMean(const Data: TDoubleArray): Double;       // Values must be > 0
class function HarmonicMean(const Data: TDoubleArray): Double;        // Values must be non-zero
class function Sum(const Data: TDoubleArray): Double;
class function SumOfSquares(const Data: TDoubleArray): Double;
```

### Percentiles and Quartiles

```pascal
class function Percentile(const Data: TDoubleArray; const P: Double): Double; // 0 <= P <= 100; method R-7
class function Quartile1(const Data: TDoubleArray): Double;   // Percentile(Data, 25)
class function Quartile3(const Data: TDoubleArray): Double;   // Percentile(Data, 75)
class function InterquartileRange(const Data: TDoubleArray): Double; // Q3 − Q1
class function Quantile(const Data: TDoubleArray; const Q: Double): Double; // 0 <= Q <= 1
```

Percentile uses linear interpolation (Excel/R default, method R-7).

### Correlation and Covariance

```pascal
class function PearsonCorrelation(const X, Y: TDoubleArray): Double;  // r ∈ [−1, 1]
class function SpearmanCorrelation(const X, Y: TDoubleArray): Double; // ρ ∈ [−1, 1]
class function Covariance(const X, Y: TDoubleArray): Double;          // Sample covariance
```

### Standardisation

```pascal
class function ZScore(const Value, AMean, StdDev: Double): Double;
class procedure Standardize(var Data: TDoubleArray);
```

`Standardize` modifies `Data` in place using the population standard deviation.
It raises `EStatsError` for constant data. StatsLib does not expose a min-max
normalisation routine.

### Hypothesis Testing

```pascal
class function TTest(const X, Y: TDoubleArray; out TPValue: Double): Double;
```

`TTest` is an independent two-sample, equal-variance (pooled) t-test. It returns
the t-statistic and writes the two-sided p-value to `TPValue`; each group needs
at least two observations. There are no one-sample or paired t-test entry points.

### Normality Tests

```pascal
class function KolmogorovSmirnovTest(const Data: TDoubleArray; out KSPValue: Double): Double;
class function IsNormal(const Data: TDoubleArray; const Alpha: Double = 0.05): Boolean;
class function ShapiroWilkTest(const Data: TDoubleArray; out WPValue: Double): Double;
```

These are lightweight approximations. `KolmogorovSmirnovTest` requires at least
five values and currently writes the D statistic (not a calibrated p-value) to
`KSPValue`. `ShapiroWilkTest` accepts 3 through 50 values and returns an
approximate W and heuristic `WPValue`. Do not use `IsNormal` or these approximate
p-values for publication-grade inference without independent validation.

### Non-Parametric Tests

| Method | Description |
|--------|-------------|
| `SignTest(X, Y)` | Proportion of non-tied pairs for which `X[i] > Y[i]` |
| `WilcoxonSignedRank(Data1, Data2)` | Wilcoxon signed-rank W statistic |
| `MannWhitneyU(Data1, Data2, out PValue)` | Smaller Mann-Whitney U and a normal-approximation p-value only when both groups have more than 10 values; otherwise p-value is 1 |
| `KendallTau(X, Y)` | Kendall's τ correlation |

### Robust Statistics

```pascal
class function MedianAbsoluteDeviation(const Data: TDoubleArray): Double;  // MAD
class function RobustStandardDeviation(const Data: TDoubleArray): Double;  // 1.4826 * MAD
class function HuberM(const Data: TDoubleArray; K: Double = 1.5): Double;
class function TrimmedMean(const Data: TDoubleArray; Percent: Double): Double;
class function WinsorizedMean(const Data: TDoubleArray; Percent: Double): Double;
```

MAD and the Huber M-estimator are resistant to outliers.

### Effect Size

```pascal
class function CohensD(const Data1, Data2: TDoubleArray): Double;   // Cohen's d
class function HedgesG(const Data1, Data2: TDoubleArray): Double;   // Hedges' g (bias-corrected)
```

Interpretation: 0.2 = small, 0.5 = medium, 0.8 = large.

### Bootstrap Methods

```pascal
class function BootstrapMean(const Data: TDoubleArray;
  Iterations: Integer): TDoubleArray; overload;
class function BootstrapMean(const Data: TDoubleArray;
  Iterations: Integer; Seed: LongWord): TDoubleArray; overload;

class function BootstrapConfidenceInterval(const Data: TDoubleArray;
  Alpha: Double = 0.05; Iterations: Integer = 1000): TDoublePair; overload;
class function BootstrapConfidenceInterval(const Data: TDoubleArray;
  Alpha: Double; Iterations: Integer; Seed: LongWord): TDoublePair; overload;

class function RandomSample(const Data: TDoubleArray): TDoubleArray;
```

`BootstrapMean` returns one resampled mean per iteration. `TDoublePair` (from
`MathBase.SharedTypes`) holds the lower and upper confidence bounds.

The compatibility overloads use caller-managed global random state and never
call `Randomize`. The seeded overloads use local state, are reproducible, and
do not change the process-wide `RandSeed`.

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

  CI := TStatsKit.BootstrapConfidenceInterval(Data1, 0.05, 2000, 2026);
  Writeln('95% CI: [', CI.Lower:0:4, ', ', CI.Upper:0:4, ']');
end.
```

---

## Design Notes

- `Variance` and `SampleVariance` both use the **n − 1** (Bessel-corrected) denominator.
- `StandardDeviation` uses the **n** (population) denominator; use `SampleStandardDeviation` for the n − 1 version.
- `Skewness` uses the population standard deviation; `Kurtosis` uses the sample standard deviation.
- Percentile uses **method R-7** (linear interpolation), matching Excel's `PERCENTILE` and R's default.
- `Sum`, `SumOfSquares`, and `Sort` accept empty arrays; the sums return zero and sorting is a no-op. `Sort` modifies its argument in place.
- The normality-test implementations are approximations; in particular, the K-S out parameter is the statistic rather than a p-value.
- Prefer the seeded bootstrap overloads for reproducible tests and analyses. Use `Randomize` once in the application only when intentionally using the global-RNG overloads.
- `EStatsError` is raised for empty arrays, arrays too small for a given statistic, or out-of-range parameters.
