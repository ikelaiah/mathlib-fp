# 📈 pascal-mathlibs.Stats: Statistical Analysis Library

The `TStatsKit` class provides comprehensive statistical calculations using Double precision. This module is part of the [pascal-mathlibs.Math](pascal-mathlibs.Math.md) library.

## Table of Contents
- [Basic Statistics](#basic-statistics)
- [Variance and Standard Deviation](#variance-and-standard-deviation)
- [Distribution Measures](#distribution-measures)
- [Correlation and Covariance](#correlation-and-covariance)
- [Z-scores and Standardization](#z-scores-and-standardization)
- [Additional Means](#additional-means)
- [Descriptive Statistics](#descriptive-statistics)
- [Robust Statistics](#robust-statistics)
- [Hypothesis Testing](#hypothesis-testing)
- [Effect Size Measures](#effect-size-measures)
- [Non-parametric Tests](#non-parametric-tests)
- [Bootstrap Methods](#bootstrap-methods)
- [Error Handling](#error-handling)
- [Precision Notes](#precision-notes)

## Basic Statistics

```pascal
uses pascal-mathlibs.Math.Stats;

// Basic statistics
Mean := TStatsKit.Mean(Data);                    // Arithmetic mean
Median := TStatsKit.Median(Data);                // Median value
Mode := TStatsKit.Mode(Data);                    // Most frequent value
Range := TStatsKit.Range(Data);                  // Range (max - min)
```

## Variance and Standard Deviation

```pascal
// Variance and standard deviation
Variance := TStatsKit.Variance(Data);                 // Population variance (n)
StdDev := TStatsKit.StandardDeviation(Data);     // Population std dev (n)
SVar := TStatsKit.SampleVariance(Data);          // Sample variance (n-1)
SStdDev := TStatsKit.SampleStandardDeviation(Data); // Sample std dev (n-1)
```

## Distribution Measures

```pascal
// Distribution measures
Skew := TStatsKit.Skewness(Data);               // Distribution skewness
Kurt := TStatsKit.Kurtosis(Data);               // Distribution kurtosis
P50 := TStatsKit.Percentile(Data, 50);          // 50th percentile
Q1 := TStatsKit.Quartile1(Data);                // First quartile
Q3 := TStatsKit.Quartile3(Data);                // Third quartile
IQR := TStatsKit.InterquartileRange(Data);      // Interquartile range
```

## Correlation and Covariance

```pascal
// Correlation and covariance
PCorr := TStatsKit.PearsonCorrelation(X, Y);    // Pearson correlation
SCorr := TStatsKit.SpearmanCorrelation(X, Y);   // Spearman correlation
Cov := TStatsKit.Covariance(X, Y);              // Sample covariance
```

## Z-scores and Standardization

```pascal
// Z-scores and standardization
TStatsKit.Standardize(Data);                    // Convert to z-scores
Z := TStatsKit.ZScore(Value, Mean, StdDev);     // Calculate z-score
```

## Additional Means

```pascal
// Additional means
GMean := TStatsKit.GeometricMean(Data);         // Geometric mean
HMean := TStatsKit.HarmonicMean(Data);          // Harmonic mean
TMean := TStatsKit.TrimmedMean(Data, 20);       // 20% trimmed mean
WMean := TStatsKit.WinsorizedMean(Data, 20);    // 20% winsorized mean
```

## Descriptive Statistics

```pascal
// Descriptive statistics
Stats := TStatsKit.Describe(Data);              // Get all descriptive stats
SEM := TStatsKit.StandardErrorOfMean(Data);     // Standard error of mean
CV := TStatsKit.CoefficientOfVariation(Data);   // Coefficient of variation
```

## Robust Statistics

```pascal
// Robust statistics
MAD := TStatsKit.MedianAbsoluteDeviation(Data); // Median absolute deviation
RSD := TStatsKit.RobustStandardDeviation(Data); // Robust standard deviation
HM := TStatsKit.HuberM(Data, 1.5);             // Huber M-estimator
```

## Hypothesis Testing

```pascal
// Hypothesis testing
TTest := TStatsKit.TTest(X, Y, TPValue);        // Independent t-test
UTest := TStatsKit.MannWhitneyU(X, Y, UPValue); // Mann-Whitney U test
KS := TStatsKit.KolmogorovSmirnovTest(Data, KSPValue); // K-S test
SW := TStatsKit.ShapiroWilkTest(Data, WPValue); // Shapiro-Wilk test
```

## Effect Size Measures

```pascal
// Effect size measures
D := TStatsKit.CohensD(X, Y);                   // Cohen's d
G := TStatsKit.HedgesG(X, Y);                   // Hedges' g
```

## Non-parametric Tests

```pascal
// Non-parametric tests
Sign := TStatsKit.SignTest(X, Y);               // Sign test
W := TStatsKit.WilcoxonSignedRank(X, Y);        // Wilcoxon signed-rank
Tau := TStatsKit.KendallTau(X, Y);              // Kendall's tau
```

## Bootstrap Methods

```pascal
// Bootstrap methods
CI := TStatsKit.BootstrapConfidenceInterval(Data); // Bootstrap CI
```

## Error Handling

The `TStatsKit` class includes comprehensive error checking:

```pascal
try
  Mean := TStatsKit.Mean(Data);
except
  on E: EStatsError do
    // Handle statistics-specific errors (e.g., empty datasets)
end;
```

Common errors include:
- Empty datasets
- Insufficient data points for certain statistics
- Non-positive values for geometric mean
- Division by zero in various calculations
- Invalid parameter values

## Precision Notes

- Basic statistics (mean, median, etc.) maintain full Double precision
- Standard deviation and variance use full precision for intermediate calculations
- Correlation and covariance maintain precision to avoid cumulative errors
- Z-scores and standardization preserve full Double precision

### Best Practices
1. Use population statistics (StandardDeviation, Variance) when working with complete populations
2. Use sample statistics (SampleStandardDeviation, SampleVariance) when working with samples
3. For robust statistics, consider using MedianAbsoluteDeviation or RobustStandardDeviation
4. Use bootstrap methods for non-parametric confidence intervals
5. Check distribution normality with ShapiroWilkTest before using parametric tests

## Examples

### Basic Statistical Analysis

```pascal
var
  Data: TDoubleArray;
  Stats: TDescriptiveStats;
begin
  // Create sample data
  Data := TDoubleArray.Create(1.2, 2.3, 3.4, 4.5, 5.6);
  
  // Get basic statistics
  WriteLn('Mean: ', TStatsKit.Mean(Data):0:2);
  WriteLn('Median: ', TStatsKit.Median(Data):0:2);
  WriteLn('Std Dev: ', TStatsKit.StandardDeviation(Data):0:2);
  
  // Get comprehensive statistics
  Stats := TStatsKit.Describe(Data);
  WriteLn('Count: ', Stats.Count);
  WriteLn('Min: ', Stats.Min:0:2);
  WriteLn('Max: ', Stats.Max:0:2);
  WriteLn('Range: ', Stats.Range:0:2);
  WriteLn('Variance: ', Stats.Variance:0:2);
  WriteLn('Skewness: ', Stats.Skewness:0:2);
  WriteLn('Kurtosis: ', Stats.Kurtosis:0:2);
end;
```

### Hypothesis Testing

```pascal
var
  Group1, Group2: TDoubleArray;
  PValue: Double;
begin
  // Create two sample groups
  Group1 := TDoubleArray.Create(56, 75, 45, 71, 61, 64, 58);
  Group2 := TDoubleArray.Create(84, 87, 78, 80, 76, 79);
  
  // Perform t-test
  TStatsKit.TTest(Group1, Group2, PValue);
  
  WriteLn('T-test p-value: ', PValue:0:4);
  if PValue < 0.05 then
    WriteLn('Groups are significantly different')
  else
    WriteLn('No significant difference detected');
    
  // Check effect size
  WriteLn('Cohen''s d: ', TStatsKit.CohensD(Group1, Group2):0:2);
end;
``` 