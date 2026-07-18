unit StatsLib.Stats;

{-----------------------------------------------------------------------------
 StatsLib.Stats

 The core statistical analysis unit for mathlib-fp
 
 This unit provides:
 - Descriptive statistics (mean, median, variance, stddev, skewness, kurtosis, etc.)
 - Percentiles, quartiles, and interquartile range
 - Correlation and covariance (Pearson, Spearman)
 - Z-scores and data standardization
 - Robust statistics (MAD, Huber M-estimator)
 - Non-parametric tests (Sign Test, Wilcoxon Signed-Rank, Mann-Whitney U, Kendall Tau)
 - Hypothesis testing (t-test)
 - Normality tests (Kolmogorov-Smirnov, Shapiro-Wilk)
 - Effect size measures (Cohen's d, Hedges' g)
 - Bootstrap methods (mean estimation, confidence intervals)
 
 Design principles:
 - Static class methods for easy access to functions
 - Uses TDoubleArray from MathBase.SharedTypes for data input
 - Provides TDescriptiveStats record for comprehensive summary output
 - Includes basic error handling for invalid inputs (e.g., empty arrays)
 - StandardDeviation and TDescriptiveStats.StdDev use the population (n)
   denominator; SampleStandardDeviation uses the sample (n-1) denominator
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, Math, MathBase.SharedTypes, MathBase.Precision, Generics.Collections;

type
  { Exception class for statistical operations }
  EStatsError = class(Exception);

  { Record to hold common descriptive statistics calculated from a dataset. }
  TDescriptiveStats = record
    N: Integer;       // Number of observations in the dataset.
    Mean: Double;     // Arithmetic mean (average) of the dataset.
    Median: Double;   // Median (middle value) of the sorted dataset.
    Mode: Double;     // Mode (most frequent value) of the dataset. Returns the first mode found if multimodal.
    Q1: Double;       // First quartile (25th percentile) of the dataset.
    Q3: Double;       // Third quartile (75th percentile) of the dataset.
    Min: Double;      // Minimum value in the dataset.
    Max: Double;      // Maximum value in the dataset.
    Range: Double;    // Difference between the maximum and minimum values.
    IQR: Double;      // Interquartile Range (Q3 - Q1).
    Variance: Double; // Sample variance (using n-1 denominator) of the dataset.
    StdDev: Double;   // Population standard deviation (using n denominator) of the dataset.
    Skewness: Double; // Skewness measure of the dataset's distribution asymmetry.
    Kurtosis: Double; // Sample excess kurtosis (peakedness) of the dataset's distribution.
    SEM: Double;      // Standard Error of the Mean (SEM), estimating the standard deviation of the sample mean.
    CV: Double;       // Coefficient of Variation (CV), the ratio of standard deviation to the mean, expressed as a percentage.
    function ToString: string;     // Formats and returns a human-readable, vertical summary of the statistics
    function ToStringWide: string; // Formats and returns a human-readable, table-like summary of the statistics
  end;

  { Provides a collection of static methods for statistical calculations. }
  TStatsKit = class
  private
    {
      @description Swaps the values of two Double variables. Internal helper.

      @usage Used internally by sorting and ranking algorithms.

      @param A The first Double variable.
      @param B The second Double variable.

      @warning None

      @example (Internal Use)
      var
        Val1, Val2: Double;
      begin
        Val1 := 1.0;
        Val2 := 2.0;
        TStatsKit.Exchange(Val1, Val2);
        // Val1 is now 2.0, Val2 is now 1.0
      end;
    }
    class procedure Exchange(var A, B: Double); static;

    {
      @description Swaps the values of two Integer variables. Internal helper.

      @usage Used internally by ranking algorithms.

      @param A The first Integer variable.
      @param B The second Integer variable.

      @warning None

      @example (Internal Use)
      var
        Idx1, Idx2: Integer;
      begin
        Idx1 := 1;
        Idx2 := 2;
        TStatsKit.ExchangeInt(Idx1, Idx2);
        // Idx1 is now 2, Idx2 is now 1
      end;
    }
    class procedure ExchangeInt(var A, B: Integer); static;

    {
      @description Creates a random sample with replacement from the given data array.

      @usage Useful for bootstrap methods where resampling is needed.

      @param Data The source array to sample from.

      @returns A new array of the same size as Data, containing elements randomly drawn from Data with replacement.

      @warning Uses the caller-managed global random generator. It never calls
      Randomize internally.

      @example
      var
        OriginalData: TDoubleArray;
        Sample: TDoubleArray;
      begin
        Randomize; // Seed the random number generator
        SetLength(OriginalData, 5);
        OriginalData[0] := 1.1; OriginalData[1] := 2.2; OriginalData[2] := 3.3;
        OriginalData[3] := 4.4; OriginalData[4] := 5.5;
        Sample := TStatsKit.RandomSample(OriginalData);
        // Sample will contain 5 elements randomly chosen from OriginalData
      end;
    }
    class function RandomSample(const Data: TDoubleArray): TDoubleArray; static;
  public
    { Basic statistics }

    {
      @description Calculates the arithmetic mean (average) of the values in the array.

      @usage Use to find the central tendency of a dataset.

      @param Data An array of Double values.

      @returns The arithmetic mean of the data.

      @references https://en.wikipedia.org/wiki/Arithmetic_mean

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        Avg: Double;
      begin
        SetLength(MyData, 3);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0;
        Avg := TStatsKit.Mean(MyData);
        // Avg will be 2.0
      end;
    }
    class function Mean(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the median (middle value) of the values in the array.

      @usage Use to find the central value of a dataset, robust to outliers.

      @param Data An array of Double values. The array is copied and sorted internally.

      @returns The median value. If the array has an even number of elements, it's the average of the two middle values.

      @references https://en.wikipedia.org/wiki/Median

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData1, MyData2: TDoubleArray;
        Med1, Med2: Double;
      begin
        SetLength(MyData1, 3); // Odd number of elements
        MyData1[0] := 3.0; MyData1[1] := 1.0; MyData1[2] := 2.0;
        Med1 := TStatsKit.Median(MyData1);
        // Med1 will be 2.0

        SetLength(MyData2, 4); // Even number of elements
        MyData2[0] := 4.0; MyData2[1] := 1.0; MyData2[2] := 3.0; MyData2[3] := 2.0;
        Med2 := TStatsKit.Median(MyData2);
        // Med2 will be 2.5 (average of 2.0 and 3.0)
      end;
    }
    class function Median(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the mode (most frequent value) of the values in the array.

      @usage Use to find the most common value in a dataset.

      @param Data An array of Double values. The array is copied and sorted internally.

      @returns The mode value. If multiple modes exist (multimodal), returns the first one encountered after sorting.

      @references https://en.wikipedia.org/wiki/Mode_(statistics)

      @warning Raises EStatsError if the input array is empty. If the dataset is multimodal, only one mode is returned.

      @example
      var
        MyData: TDoubleArray;
        ModeVal: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 2.0; MyData[3] := 3.0; MyData[4] := 2.0;
        ModeVal := TStatsKit.Mode(MyData);
        // ModeVal will be 2.0
      end;
    }
    class function Mode(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the range (difference between maximum and minimum values) of the array.

      @usage Use to get a simple measure of the spread of the data.

      @param Data An array of Double values. The array is copied and sorted internally.

      @returns The difference between the maximum and minimum values.

      @references https://en.wikipedia.org/wiki/Range_(statistics)

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        Rng: Double;
      begin
        SetLength(MyData, 4);
        MyData[0] := 5.0; MyData[1] := 1.0; MyData[2] := 10.0; MyData[3] := 3.0;
        Rng := TStatsKit.Range(MyData);
        // Rng will be 9.0 (10.0 - 1.0)
      end;
    }
    class function Range(const Data: TDoubleArray): Double; static;

    { Variance and standard deviation }

    {
      @description Calculates the sample variance of the values in the array.

      @usage Use to measure the dispersion of data points around the mean (uses n-1 denominator).

      @param Data An array of Double values.

      @returns The sample variance.

      @references https://en.wikipedia.org/wiki/Variance#Sample_variance

      @warning Raises EStatsError if the array has less than 2 values.

      @example
      var
        MyData: TDoubleArray;
        VarVal: Double;
      begin
        SetLength(MyData, 4);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0;
        VarVal := TStatsKit.Variance(MyData);
        // VarVal will be approximately 1.6667
      end;
    }
    class function Variance(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the population standard deviation of the values in the array.

      @usage Use to measure the amount of variation or dispersion of a set of values for the entire population (uses n denominator).

      @param Data An array of Double values.

      @returns The population standard deviation (square root of population variance).

      @references https://en.wikipedia.org/wiki/Standard_deviation#Population_standard_deviation_of_finite_population

      @warning Raises EStatsError if the array has less than 2 values. Note this calculates *population* StdDev. Use SampleStandardDeviation for sample StdDev.

      @example
      var
        MyData: TDoubleArray;
        StdDevVal: Double;
      begin
        SetLength(MyData, 4);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0;
        StdDevVal := TStatsKit.StandardDeviation(MyData);
        // StdDevVal will be approximately 1.1180 (sqrt(1.25))
      end;
    }
    class function StandardDeviation(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the sample variance of the values in the array.

      @usage Use to estimate the variance of a population based on a sample (uses n-1 denominator). Identical to Variance function.

      @param Data An array of Double values.

      @returns The sample variance.

      @references https://en.wikipedia.org/wiki/Variance#Sample_variance

      @warning Raises EStatsError if the array has less than 2 values.

      @example
      var
        MyData: TDoubleArray;
        SampleVarVal: Double;
      begin
        SetLength(MyData, 4);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0;
        SampleVarVal := TStatsKit.SampleVariance(MyData);
        // SampleVarVal will be approximately 1.6667
      end;
    }
    class function SampleVariance(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the sample standard deviation of the values in the array.

      @usage Use to estimate the standard deviation of a population based on a sample (uses n-1 denominator for variance calculation).

      @param Data An array of Double values.

      @returns The sample standard deviation (square root of sample variance).

      @references https://en.wikipedia.org/wiki/Standard_deviation#Sample_standard_deviation

      @warning Raises EStatsError if the array has less than 2 values.

      @example
      var
        MyData: TDoubleArray;
        SampleStdDevVal: Double;
      begin
        SetLength(MyData, 4);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0;
        SampleStdDevVal := TStatsKit.SampleStandardDeviation(MyData);
        // SampleStdDevVal will be approximately 1.2910 (sqrt(1.6667))
      end;
    }
    class function SampleStandardDeviation(const Data: TDoubleArray): Double; static;

    { Distribution measures }

    {
      @description Calculates the sample skewness of the dataset.

      @usage Use to measure the asymmetry of the probability distribution of a real-valued random variable about its mean.

      @param Data An array of Double values. Uses population standard deviation in calculation.

      @returns The sample skewness value. Positive indicates tail on the right, negative indicates tail on the left. 0 indicates symmetry.

      @references https://en.wikipedia.org/wiki/Skewness

      @warning Raises EStatsError if the array has less than 3 values. Uses population standard deviation (n denominator).

      @example
      var
        MyData: TDoubleArray;
        Skew: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0; MyData[4] := 10.0; // Skewed right
        Skew := TStatsKit.Skewness(MyData);
        // Skew will be a positive value (approximately 1.05)
      end;
    }
    class function Skewness(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the sample excess kurtosis of the dataset.

      @usage Use to measure the "tailedness" or "peakedness" of the probability distribution relative to a normal distribution (excess kurtosis = kurtosis - 3).

      @param Data An array of Double values. Uses sample standard deviation (n-1) in calculation.

      @returns The sample excess kurtosis value. Positive indicates a more peaked distribution (leptokurtic), negative indicates a flatter distribution (platykurtic).

      @references https://en.wikipedia.org/wiki/Kurtosis#Sample_kurtosis

      @warning Raises EStatsError if the array has less than 4 values. Uses sample standard deviation.

      @example
      var
        MyData: TDoubleArray;
        Kurt: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0; MyData[4] := 5.0;
        Kurt := TStatsKit.Kurtosis(MyData);
        // Kurt will be a value indicating the distribution's peakedness relative to normal
      end;
    }
    class function Kurtosis(const Data: TDoubleArray): Double; static;

    { Percentiles and quartiles }

    {
      @description Calculates the P-th percentile of the dataset using linear interpolation between closest ranks.

      @usage Use to find the value below which a given percentage P of observations fall.

      @param Data An array of Double values. The array is copied and sorted internally.
      @param P The percentile to calculate (0 <= P <= 100).

      @returns The value corresponding to the P-th percentile.

      @references Method R-7 (Excel, R default) - https://en.wikipedia.org/wiki/Percentile#Calculation_methods

      @warning Raises EStatsError if P is outside the [0, 100] range or if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        P90: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 10;
        P90 := TStatsKit.Percentile(MyData, 90);
        // P90 will be 9.1
      end;
    }
    class function Percentile(const Data: TDoubleArray; const P: Double): Double; static;

    {
      @description Calculates the first quartile (25th percentile) of the dataset.

      @usage A convenience function equivalent to Percentile(Data, 25).

      @param Data An array of Double values.

      @returns The first quartile (Q1) value.

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        Q1Val: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 10;
        Q1Val := TStatsKit.Quartile1(MyData);
        // Q1Val will be 3.25
      end;
    }
    class function Quartile1(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the third quartile (75th percentile) of the dataset.

      @usage A convenience function equivalent to Percentile(Data, 75).

      @param Data An array of Double values.

      @returns The third quartile (Q3) value.

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        Q3Val: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 10;
        Q3Val := TStatsKit.Quartile3(MyData);
        // Q3Val will be 7.75
      end;
    }
    class function Quartile3(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the interquartile range (IQR), the difference between the third and first quartiles.

      @usage Use to measure statistical dispersion, being the range of the middle 50% of the data. Robust to outliers.

      @param Data An array of Double values.

      @returns The interquartile range (Q3 - Q1).

      @references https://en.wikipedia.org/wiki/Interquartile_range

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        IQRVal: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 10;
        IQRVal := TStatsKit.InterquartileRange(MyData);
        // IQRVal will be 4.5 (7.75 - 3.25)
      end;
    }
    class function InterquartileRange(const Data: TDoubleArray): Double; static;

    { Correlation and covariance }

    {
      @description Calculates the Pearson product-moment correlation coefficient between two arrays.

      @usage Use to measure the linear correlation between two continuous variables. Assumes data is normally distributed.

      @param X The first array of Double values.
      @param Y The second array of Double values. Must have the same length as X.

      @returns The Pearson correlation coefficient, ranging from -1 (perfect negative correlation) to +1 (perfect positive correlation). 0 indicates no linear correlation.

      @references https://en.wikipedia.org/wiki/Pearson_correlation_coefficient

      @warning Raises EStatsError if arrays have different lengths or less than 2 values. Returns 0 if variance of either X or Y is zero.

      @example
      var
        DataX, DataY: TDoubleArray;
        PearsonR: Double;
      begin
        SetLength(DataX, 5); SetLength(DataY, 5);
        DataX[0] := 1; DataX[1] := 2; DataX[2] := 3; DataX[3] := 4; DataX[4] := 5;
        DataY[0] := 2; DataY[1] := 4; DataY[2] := 5; DataY[3] := 4; DataY[4] := 5;
        PearsonR := TStatsKit.PearsonCorrelation(DataX, DataY);
        // PearsonR will be approximately 0.82
      end;
    }
    class function PearsonCorrelation(const X, Y: TDoubleArray): Double; static;

    {
      @description Calculates the Spearman rank correlation coefficient between two arrays.

      @usage Use to measure the strength and direction of association between two ranked variables (non-parametric). Assesses how well the relationship between two variables can be described using a monotonic function.

      @param X The first array of Double values.
      @param Y The second array of Double values. Must have the same length as X.

      @returns The Spearman correlation coefficient, ranging from -1 to +1.

      @references https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient

      @warning Raises EStatsError if arrays have different lengths or less than 2 values. Handles ties by assigning average ranks.

      @example
      var
        DataX, DataY: TDoubleArray;
        SpearmanRho: Double;
      begin
        SetLength(DataX, 5); SetLength(DataY, 5);
        DataX[0] := 1; DataX[1] := 2; DataX[2] := 3; DataX[3] := 4; DataX[4] := 5;
        DataY[0] := 5; DataY[1] := 6; DataY[2] := 7; DataY[3] := 8; DataY[4] := 7; // Non-linear relationship
        SpearmanRho := TStatsKit.SpearmanCorrelation(DataX, DataY);
        // SpearmanRho will be approximately 0.82 (measures monotonic relationship)
      end;
    }
    class function SpearmanCorrelation(const X, Y: TDoubleArray): Double; static;

    {
      @description Calculates the sample covariance between two arrays.

      @usage Use to measure the joint variability of two random variables. Positive covariance indicates variables tend to move in the same direction, negative indicates opposite directions.

      @param X The first array of Double values.
      @param Y The second array of Double values. Must have the same length as X.

      @returns The sample covariance (uses n-1 denominator).

      @references https://en.wikipedia.org/wiki/Covariance#Sample_covariance

      @warning Raises EStatsError if arrays have different lengths or less than 2 elements.

      @example
      var
        DataX, DataY: TDoubleArray;
        Cov: Double;
      begin
        SetLength(DataX, 5); SetLength(DataY, 5);
        DataX[0] := 1; DataX[1] := 2; DataX[2] := 3; DataX[3] := 4; DataX[4] := 5;
        DataY[0] := 2; DataY[1] := 4; DataY[2] := 5; DataY[3] := 4; DataY[4] := 5;
        Cov := TStatsKit.Covariance(DataX, DataY);
        // Cov will be 1.25
      end;
    }
    class function Covariance(const X, Y: TDoubleArray): Double; static;

    { Z-score and normalization }

    {
      @description Calculates the Z-score (standard score) of a value given the mean and standard deviation of its distribution.

      @usage Use to determine how many standard deviations a value is from the mean. Useful for comparing values from different distributions or identifying outliers.

      @param Value The value for which to calculate the Z-score.
      @param AMean The mean of the distribution.
      @param StdDev The standard deviation of the distribution.

      @returns The Z-score of the value.

      @references https://en.wikipedia.org/wiki/Standard_score

      @warning Raises EStatsError if StdDev is zero.

      @example
      var
        MyValue, MeanVal, StdDevVal, Z: Double;
      begin
        MyValue := 75.0;
        MeanVal := 60.0;
        StdDevVal := 10.0;
        Z := TStatsKit.ZScore(MyValue, MeanVal, StdDevVal);
        // Z will be 1.5
      end;
    }
    class function ZScore(const Value, AMean, StdDev: Double): Double; static;

    {
      @description Standardizes the values in an array by converting them to Z-scores (in-place).

      @usage Use to transform data to have a mean of 0 and a standard deviation of 1.

      @param Data The array of Double values to standardize. The array is modified directly. Uses population standard deviation for the transformation.

      @warning Raises EStatsError if the standard deviation of the data is zero. Modifies the input array Data.

      @example
      var
        MyData: TDoubleArray;
        I: Integer;
      begin
        SetLength(MyData, 4);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0;
        TStatsKit.Standardize(MyData);
        // MyData now contains Z-scores: approx [-1.34, -0.45, 0.45, 1.34]
        for I := 0 to High(MyData) do WriteLn(MyData[I]:0:2);
      end;
    }
    class procedure Standardize(var Data: TDoubleArray); static;

    { Helper functions }

    {
      @description Calculates the sum of all values in the array.

      @usage A basic building block for many other statistical calculations.

      @param Data An array of Double values.

      @returns The sum of the elements. Returns 0 for an empty array.

      @warning None

      @example
      var
        MyData: TDoubleArray;
        Total: Double;
      begin
        SetLength(MyData, 3);
        MyData[0] := 1.5; MyData[1] := 2.5; MyData[2] := 3.0;
        Total := TStatsKit.Sum(MyData);
        // Total will be 7.0
      end;
    }
    class function Sum(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the sum of the squares of all values in the array.

      @usage Used in calculations like variance and standard deviation.

      @param Data An array of Double values.

      @returns The sum of the squares of the elements. Returns 0 for an empty array.

      @warning None

      @example
      var
        MyData: TDoubleArray;
        SumSq: Double;
      begin
        SetLength(MyData, 3);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0;
        SumSq := TStatsKit.SumOfSquares(MyData);
        // SumSq will be 14.0 (1*1 + 2*2 + 3*3)
      end;
    }
    class function SumOfSquares(const Data: TDoubleArray): Double; static;

    {
      @description Sorts the elements of the array in ascending order (in-place).

      @usage Used internally by median, percentile, and other rank-based calculations. Can also be used externally if a sorted array is needed.

      @param Data The array of Double values to sort. The array is modified directly.

      @warning Modifies the input array Data. Uses a stable O(n log n) merge sort; NaN values, if present, are placed last.

      @example
      var
        MyData: TDoubleArray;
        I: Integer;
      begin
        SetLength(MyData, 4);
        MyData[0] := 3.0; MyData[1] := 1.0; MyData[2] := 4.0; MyData[3] := 2.0;
        TStatsKit.Sort(MyData);
        // MyData is now [1.0, 2.0, 3.0, 4.0]
        for I := 0 to High(MyData) do WriteLn(MyData[I]:0:1);
      end;
    }
    class procedure Sort(var Data: TDoubleArray); static;

    { Descriptive Statistics }

    {
      @description Calculates a comprehensive set of descriptive statistics for the dataset.

      @usage Use to get a quick summary of a dataset's central tendency, dispersion, and shape.

      @param Data An array of Double values.

      @returns A TDescriptiveStats record populated with calculated statistics (N, Mean, Median, Mode, Q1, Q3, Min, Max, Range, IQR, Variance, StdDev, Skewness, Kurtosis, SEM, CV).

      @warning Raises EStatsError if the input array is empty. Raises errors from underlying functions if data size requirements are not met (e.g., <2 for Variance, <3 for Skewness, <4 for Kurtosis).

      @example
      var
        MyData: TDoubleArray;
        Stats: TDescriptiveStats;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 10;
        Stats := TStatsKit.Describe(MyData);
        WriteLn('Mean: ', Stats.Mean:0:2); // Output: Mean: 4.00
        WriteLn('Median: ', Stats.Median:0:2); // Output: Median: 3.00
        WriteLn(Stats.ToString); // Output full summary
      end;
    }
    class function Describe(const Data: TDoubleArray): TDescriptiveStats; static;

    { Additional Basic Statistics }

    {
      @description Calculates the geometric mean of the values in the array.

      @usage Use for datasets where values are multiplied together or represent rates of change. Suitable for positive numbers only.

      @param Data An array of Double values.

      @returns The geometric mean.

      @references https://en.wikipedia.org/wiki/Geometric_mean

      @warning Raises EStatsError if the input array is empty or contains non-positive (<= 0) values. Can be susceptible to floating-point underflow/overflow for very small/large numbers or long arrays.

      @example
      var
        MyData: TDoubleArray;
        GeoMean: Double;
      begin
        SetLength(MyData, 3);
        MyData[0] := 2.0; MyData[1] := 4.0; MyData[2] := 8.0;
        GeoMean := TStatsKit.GeometricMean(MyData);
        // GeoMean will be 4.0 (cuberoot(2*4*8))
      end;
    }
    class function GeometricMean(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the harmonic mean of the values in the array.

      @usage Use for datasets involving rates or ratios, such as speeds. Suitable for positive numbers only.

      @param Data An array of Double values.

      @returns The harmonic mean.

      @references https://en.wikipedia.org/wiki/Harmonic_mean

      @warning Raises EStatsError if the input array is empty, contains non-positive (<= 0) values, or if the sum of reciprocals is zero. Sensitive to small values.

      @example
      var
        MyData: TDoubleArray;
        HarmMean: Double;
      begin
        SetLength(MyData, 3);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 4.0;
        HarmMean := TStatsKit.HarmonicMean(MyData);
        // HarmMean will be approximately 1.714 (3 / (1/1 + 1/2 + 1/4))
      end;
    }
    class function HarmonicMean(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the trimmed mean (truncated mean) of the dataset.

      @usage Use as a robust measure of central tendency, less sensitive to outliers than the arithmetic mean. Removes a specified percentage of data from both ends before calculating the mean.

      @param Data An array of Double values. The array is copied and sorted internally.
      @param Percent The percentage of data to remove from *each* end (0 <= Percent < 50). For example, Percent = 10 removes the lowest 10% and highest 10%.

      @returns The mean of the remaining data after trimming.

      @references https://en.wikipedia.org/wiki/Truncated_mean

      @warning Raises EStatsError if Percent is outside [0, 50) or if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        TrimMean: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 100; // Outlier
        TrimMean := TStatsKit.TrimmedMean(MyData, 10); // Remove 1 lowest (1) and 1 highest (100)
        // TrimMean will be 5.0 (mean of 2,3,4,5,6,7,8,9)
      end;
    }
    class function TrimmedMean(const Data: TDoubleArray; const Percent: Double): Double; static;

    {
      @description Calculates the Winsorized mean of the dataset.

      @usage Use as a robust measure of central tendency. Instead of removing outliers, it replaces the specified percentage of lowest values with the lowest remaining value, and the highest values with the highest remaining value.

      @param Data An array of Double values. The array is copied and sorted internally.
      @param Percent The percentage of data to Winsorize from *each* end (0 <= Percent < 50).

      @returns The mean of the Winsorized data.

      @references https://en.wikipedia.org/wiki/Winsorizing#Winsorized_mean

      @warning Raises EStatsError if Percent is outside [0, 50) or if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        WinsorMean: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 100; // Outlier
        WinsorMean := TStatsKit.WinsorizedMean(MyData, 10); // Replace 1 (with 2) and 100 (with 9)
        // WinsorMean will be 5.3 (mean of [2,2,3,4,5,6,7,8,9,9])
      end;
    }
    class function WinsorizedMean(const Data: TDoubleArray; const Percent: Double): Double; static;

    { Non-parametric Statistics }

    {
      @description Calculates the Median Absolute Deviation (MAD) of the dataset.

      @usage Use as a robust measure of the variability of a univariate sample of quantitative data. It is the median of the absolute deviations from the data's median.

      @param Data An array of Double values.

      @returns The Median Absolute Deviation (MAD).

      @references https://en.wikipedia.org/wiki/Median_absolute_deviation

      @warning Raises EStatsError if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        MADVal: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0; MyData[4] := 100.0; // Outlier
        MADVal := TStatsKit.MedianAbsoluteDeviation(MyData);
        // Median is 3. Deviations: |-2, -1, 0, 1, 97|. Absolute Deviations: [2, 1, 0, 1, 97]. Sorted: [0, 1, 1, 2, 97]. Median is 1.
        // MADVal will be 1.0
      end;
    }
    class function MedianAbsoluteDeviation(const Data: TDoubleArray): Double; static;

    {
      @description Performs a simple Sign Test on paired data.

      @usage Use to test the hypothesis that the difference between paired observations (X[i] - Y[i]) has zero median. Non-parametric alternative to paired t-test when normality is not assumed.

      @param X The first array of paired Double values.
      @param Y The second array of paired Double values. Must have the same length as X.

      @returns The proportion of positive differences (X[i] > Y[i]) among pairs where X[i] != Y[i]. (Note: This is not a p-value).

      @references https://en.wikipedia.org/wiki/Sign_test

      @warning Raises EStatsError if arrays have different lengths or if there are no pairs with non-zero differences. The return value is the proportion, not a p-value. A full sign test involves comparing this to a binomial distribution.

      @example
      var
        DataX, DataY: TDoubleArray;
        SignProp: Double;
      begin
        SetLength(DataX, 5); SetLength(DataY, 5);
        DataX[0] := 10; DataX[1] := 12; DataX[2] := 8; DataX[3] := 15; DataX[4] := 9;
        DataY[0] := 9;  DataY[1] := 10; DataY[2] := 10; DataY[3] := 12; DataY[4] := 9; // 3 positive, 1 negative, 1 zero difference
        SignProp := TStatsKit.SignTest(DataX, DataY);
        // NPos = 3, NNeg = 1. N = 4.
        // SignProp will be 0.75 (3 / 4)
      end;
    }
    class function SignTest(const X, Y: TDoubleArray): Double; static;

    {
      @description Performs the Wilcoxon Signed-Rank test on paired data.

      @usage Use as a non-parametric alternative to the paired t-test to compare two related samples or repeated measurements on a single sample to assess whether their population mean ranks differ.

      @param X The first array of paired Double values.
      @param Y The second array of paired Double values. Must have the same length as X.

      @returns The sum of the ranks corresponding to the positive differences (W+ statistic). (Note: This is not a p-value).

      @references https://en.wikipedia.org/wiki/Wilcoxon_signed-rank_test

      @warning Raises EStatsError if arrays have different lengths or if there are no pairs with non-zero differences. Returns the W+ test statistic, not a p-value. A full test involves comparing W+ to critical values or calculating a p-value.

      @example
      var
        DataX, DataY: TDoubleArray;
        WStat: Double;
      begin
        SetLength(DataX, 6); SetLength(DataY, 6);
        DataX[0] := 125; DataY[0] := 110; // Diff = 15
        DataX[1] := 115; DataY[1] := 122; // Diff = -7
        DataX[2] := 130; DataY[2] := 125; // Diff = 5
        DataX[3] := 140; DataY[3] := 120; // Diff = 20
        DataX[4] := 140; DataY[4] := 140; // Diff = 0
        DataX[5] := 115; DataY[5] := 136; // Diff = -21
        WStat := TStatsKit.WilcoxonSignedRank(DataX, DataY);
        // Diffs: [15, -7, 5, 20, -21]. Abs Diffs: [15, 7, 5, 20, 21]. Ranks: [3, 2, 1, 4, 5]
        // Positive diffs: 15 (Rank 3), 5 (Rank 1), 20 (Rank 4). Sum of ranks = 3 + 1 + 4 = 8.
        // WStat will be 8.0
      end;
    }
    class function WilcoxonSignedRank(const X, Y: TDoubleArray): Double; static;

    {
      @description Calculates Kendall's rank correlation coefficient (Tau-a).

      @usage Use as a non-parametric measure of the strength and direction of association between two ranked variables. Measures ordinal association. This implementation calculates Tau-a (no correction for ties).

      @param X The first array of Double values.
      @param Y The second array of Double values. Must have the same length as X.

      @returns Kendall's Tau-a correlation coefficient, ranging from -1 to +1.

      @references https://en.wikipedia.org/wiki/Kendall_rank_correlation_coefficient (Tau-a)

      @warning Raises EStatsError if arrays have different lengths. This implementation is Tau-a, which doesn't adjust for ties. For datasets with many ties, Tau-b or Tau-c might be more appropriate (not implemented here). The formula used assumes no ties for the denominator.

      @example
      var
        DataX, DataY: TDoubleArray;
        KendallTauVal: Double;
      begin
        SetLength(DataX, 5); SetLength(DataY, 5);
        DataX[0] := 1; DataX[1] := 2; DataX[2] := 3; DataX[3] := 4; DataX[4] := 5;
        DataY[0] := 2; DataY[1] := 1; DataY[2] := 4; DataY[3] := 3; DataY[4] := 5;
        KendallTauVal := TStatsKit.KendallTau(DataX, DataY);
        // Concordant Pairs: (1,3), (1,4), (1,5), (2,3), (2,4), (2,5), (3,4), (3,5), (4,5) -> 8 (ignoring (2,1), (4,3))
        // Discordant Pairs: (2,1), (4,3) -> 2
        // KendallTauVal will be (8 - 2) / sqrt((8+2)*(8+2)) = 6 / sqrt(100) = 0.6
      end;
    }
    class function KendallTau(const X, Y: TDoubleArray): Double; static;

    { Hypothesis Testing }

    {
      @description Performs an independent two-sample Student's t-test assuming equal variances.

      @usage Use to determine if there is a significant difference between the means of two independent groups. Assumes data in both groups are approximately normally distributed and have equal variances.

      @param X The array of Double values for the first group.
      @param Y The array of Double values for the second group.
      @param TPValue Output parameter: The calculated two-tailed p-value.

      @returns The calculated t-statistic.

      @references https://en.wikipedia.org/wiki/Student%27s_t-test#Independent_two-sample_t-test

      @warning Raises EStatsError if either group has less than 2 values, if pooled variance is non-positive, or if standard error is zero. Assumes equal variances (use Welch's t-test if variances are unequal - not implemented here). Assumes normality. P-value is calculated using MathBase.Precision.StudentT.

      @example
      var
        GroupX, GroupY: TDoubleArray;
        TStat, PVal: Double;
      begin
        SetLength(GroupX, 5); SetLength(GroupY, 6);
        GroupX[0] := 20; GroupX[1] := 22; GroupX[2] := 19; GroupX[3] := 21; GroupX[4] := 18; // Mean=20
        GroupY[0] := 24; GroupY[1] := 25; GroupY[2] := 23; GroupY[3] := 26; GroupY[4] := 27; GroupY[5] := 25; // Mean=25
        TStat := TStatsKit.TTest(GroupX, GroupY, PVal);
        WriteLn('T-Statistic: ', TStat:0:3);
        WriteLn('P-Value: ', PVal:0:3);
        // TStat will be approx -5.145
        // PVal will be approx 0.001
      end;
    }
    class function TTest(const X, Y: TDoubleArray; out TPValue: Double): Double; static;

    {
      @description Performs the Mann-Whitney U test (also known as Wilcoxon rank-sum test).

      @usage Use as a non-parametric test to determine if there is a difference between two independent groups when the data is not normally distributed. Tests if a randomly selected value from group X is likely to be less than or greater than a randomly selected value from group Y.

      @param X The array of Double values for the first group.
      @param Y The array of Double values for the second group.
      @param UPValue Output parameter: The calculated two-tailed p-value. Small samples without ties use the exact distribution; tied or larger samples use a tie-corrected normal approximation with continuity correction.

      @returns The calculated Mann-Whitney U statistic (the minimum of U1 and U2).

      @references https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test

      @warning Raises EStatsError if either group has less than 2 values or contains a non-finite value. Handles ties by assigning average ranks.

      @example
      var
        GroupX, GroupY: TDoubleArray;
        UStat, PValApprox: Double;
      begin
        SetLength(GroupX, 5); SetLength(GroupY, 6);
        GroupX[0] := 3; GroupX[1] := 5; GroupX[2] := 1; GroupX[3] := 8; GroupX[4] := 7;
        GroupY[0] := 6; GroupY[1] := 2; GroupY[2] := 4; GroupY[3] := 9; GroupY[4] := 10; GroupY[5] := 11;
        UStat := TStatsKit.MannWhitneyU(GroupX, GroupY, PValApprox);
        WriteLn('U Statistic: ', UStat:0:1);
        WriteLn('P-Value: ', PValApprox:0:3);
        // UStat will be 8.0
      end;
    }
    class function MannWhitneyU(const X, Y: TDoubleArray; out UPValue: Double): Double; static;

    {
      @description Computes the one-sample Kolmogorov-Smirnov distance from a normal CDF whose mean and standard deviation are estimated from the sample.

      @usage Use to test the null hypothesis that the data comes from a normally distributed population, when the mean and standard deviation are estimated from the sample.

      @param Data An array of Double values.
      @param KSPValue Output parameter: An asymptotic two-sided p-value approximation.

      @returns The calculated Kolmogorov-Smirnov D statistic.

      @references https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test, https://en.wikipedia.org/wiki/Lilliefors_test

      @warning Raises EStatsError if the array has less than 5 values, contains non-finite data, or has zero variance. Because parameters are fitted, the returned standard K-S asymptotic p-value is diagnostic rather than a calibrated Lilliefors p-value.

      @example
      var
        MyData: TDoubleArray;
        KSStat, KSStatOut: Double;
      begin
        SetLength(MyData, 10);
        // Fill MyData with values, e.g., normally distributed data
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        KSStat := TStatsKit.KolmogorovSmirnovTest(MyData, KSStatOut);
        WriteLn('K-S Statistic: ', KSStat:0:4);
        // KSStat is D; KSStatOut is the approximate p-value.
      end;
    }
    class function KolmogorovSmirnovTest(const Data: TDoubleArray; out KSPValue: Double): Double; static;

    { Distribution Tests }

    {
      @description Tests whether normality is rejected using the approximate K-S p-value.

      @usage Returns true when the approximate p-value is at least Alpha.

      @param Data An array of Double values.
      @param Alpha The significance level in the open interval (0, 1), default 0.05.

      @returns True when normality is not rejected at Alpha, false otherwise.

      @warning This is a convenience diagnostic; see KolmogorovSmirnovTest regarding fitted-parameter p-value calibration.

      @example
      var
        MyData: TDoubleArray;
        IsNorm: Boolean;
      begin
        SetLength(MyData, 10);
        // Fill MyData with values...
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        IsNorm := TStatsKit.IsNormal(MyData); // Uses Alpha = 0.05 default
        WriteLn('Data likely normal (based on K-S test comparison): ', IsNorm);
        // Result depends on the K-S statistic and the potentially inverted comparison logic.
      end;
    }
    class function IsNormal(const Data: TDoubleArray; const Alpha: Double = 0.05): Boolean; static;

    {
      @description Performs the Shapiro-Wilk test for normality.

      @usage Use as a powerful test to determine if a sample likely came from a normally distributed population. Generally preferred over K-S test for normality testing, especially for smaller samples.

      @param Data An array of finite Double values. Sample size must be between 3 and 5000.
      @param WPValue Output parameter: The calculated approximate p-value.

      @returns The calculated Shapiro-Wilk W statistic.

      @references https://en.wikipedia.org/wiki/Shapiro%E2%80%93Wilk_test

      @warning Raises EStatsError for sample sizes outside [3, 5000], non-finite values, or zero variance. P-values use Royston's approximation and are always clamped to [0, 1].

      @example
      var
        MyData: TDoubleArray;
        WStat, PValApprox: Double;
      begin
        SetLength(MyData, 10);
        // Fill MyData with values, e.g., normally distributed data
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        WStat := TStatsKit.ShapiroWilkTest(MyData, PValApprox);
        WriteLn('Shapiro-Wilk W: ', WStat:0:4);
        WriteLn('Approx P-Value: ', PValApprox:0:4);
        // WStat near 1 and PValApprox > alpha (e.g., 0.05) suggest normality.
      end;
    }
    class function ShapiroWilkTest(const Data: TDoubleArray; out WPValue: Double): Double; static;

    { Effect Size Measures }

    {
      @description Calculates Cohen's d effect size for two independent groups.

      @usage Use to measure the standardized difference between two means using the pooled sample standard deviation.

      @param X The array of Double values for the first group.
      @param Y The array of Double values for the second group.

      @returns Cohen's d statistic. Common interpretations: 0.2 (small), 0.5 (medium), 0.8 (large effect).

      @references https://en.wikipedia.org/wiki/Effect_size#Cohen's_d

      @warning Raises EStatsError if either group has less than 2 values or the pooled sample variance is zero. Assumes equal variances.

      @example
      var
        GroupX, GroupY: TDoubleArray;
        DVal: Double;
      begin
        SetLength(GroupX, 5); SetLength(GroupY, 6);
        GroupX[0] := 20; GroupX[1] := 22; GroupX[2] := 19; GroupX[3] := 21; GroupX[4] := 18; // Mean=20, PopSD=1.41
        GroupY[0] := 24; GroupY[1] := 25; GroupY[2] := 23; GroupY[3] := 26; GroupY[4] := 27; GroupY[5] := 25; // Mean=25, PopSD=1.29
        DVal := TStatsKit.CohensD(GroupX, GroupY);
        WriteLn('Cohen''s d: ', DVal:0:3);
        // DVal will be approximately -3.71
      end;
    }
    class function CohensD(const X, Y: TDoubleArray): Double; static;

    {
      @description Calculates Hedges' g effect size for two independent groups.

      @usage Use as an alternative to Cohen's d, providing a correction for bias, especially in small samples.

      @param X The array of Double values for the first group.
      @param Y The array of Double values for the second group.

      @returns Hedges' g statistic.

      @references https://en.wikipedia.org/wiki/Effect_size#Hedges'_g

      @warning Raises EStatsError if either group has less than 2 values (via CohensD). Calculation relies on CohensD result.

      @example
      var
        GroupX, GroupY: TDoubleArray;
        GVal: Double;
      begin
        SetLength(GroupX, 5); SetLength(GroupY, 6);
        GroupX[0] := 20; GroupX[1] := 22; GroupX[2] := 19; GroupX[3] := 21; GroupX[4] := 18;
        GroupY[0] := 24; GroupY[1] := 25; GroupY[2] := 23; GroupY[3] := 26; GroupY[4] := 27; GroupY[5] := 25;
        GVal := TStatsKit.HedgesG(GroupX, GroupY);
        WriteLn('Hedges'' g: ', GVal:0:3);
        // GVal will be Cohen's d multiplied by a correction factor slightly less than 1. Approx -3.57
      end;
    }
    class function HedgesG(const X, Y: TDoubleArray): Double; static;

    { Additional Measures }

    {
      @description Calculates the Standard Error of the Mean (SEM).

      @usage Use to estimate the standard deviation of the sample mean based on the sample standard deviation and sample size. Measures the precision of the sample mean as an estimate of the population mean.

      @param Data An array of Double values.

      @returns The Standard Error of the Mean (SEM).

      @references https://en.wikipedia.org/wiki/Standard_error#Standard_error_of_the_mean

      @warning Raises EStatsError if the array has less than 2 values. Uses sample standard deviation (n-1 denominator).

      @example
      var
        MyData: TDoubleArray;
        SEMVal: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        // SampleStdDev approx 0.45
        SEMVal := TStatsKit.StandardErrorOfMean(MyData);
        WriteLn('SEM: ', SEMVal:0:4);
        // SEMVal will be approx 0.142 (0.45 / sqrt(10))
      end;
    }
    class function StandardErrorOfMean(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the Coefficient of Variation (CV).

      @usage Use to measure the relative variability of data, expressed as a percentage of the mean. Useful for comparing variability between datasets with different means.

      @param Data An array of Double values. Uses population standard deviation.

      @returns The Coefficient of Variation (CV) as a percentage.

      @references https://en.wikipedia.org/wiki/Coefficient_of_variation

      @warning Raises EStatsError if the input array is empty or if the mean is zero. Uses population standard deviation (n denominator).

      @example
      var
        MyData: TDoubleArray;
        CVVal: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 10; MyData[1] := 11; MyData[2] := 12; MyData[3] := 13; MyData[4] := 14; // Mean=12, PopStdDev=1.414
        CVVal := TStatsKit.CoefficientOfVariation(MyData);
        WriteLn('CV: ', CVVal:0:2, '%');
        // CVVal will be approx 11.79% ( (1.414 / 12) * 100 )
      end;
    }
    class function CoefficientOfVariation(const Data: TDoubleArray): Double; static;

    {
      @description Calculates the Q-th quantile of the dataset using linear interpolation.

      @usage Use to find the value below which a given fraction Q of observations fall. Equivalent to Percentile(Data, Q * 100).

      @param Data An array of Double values. The array is copied and sorted internally.
      @param Q The quantile to calculate (0 <= Q <= 1).

      @returns The value corresponding to the Q-th quantile.

      @references Method R-7 (Excel, R default) - https://en.wikipedia.org/wiki/Quantile#Estimating_quantiles_from_a_sample

      @warning Raises EStatsError if Q is outside the [0, 1] range or if the input array is empty.

      @example
      var
        MyData: TDoubleArray;
        QVal: Double;
      begin
        SetLength(MyData, 10);
        MyData[0] := 1; MyData[1] := 2; MyData[2] := 3; MyData[3] := 4; MyData[4] := 5;
        MyData[5] := 6; MyData[6] := 7; MyData[7] := 8; MyData[8] := 9; MyData[9] := 10;
        QVal := TStatsKit.Quantile(MyData, 0.90); // 90th percentile
        // QVal will be 9.1
      end;
    }
    class function Quantile(const Data: TDoubleArray; const Q: Double): Double; static;

    { Robust Statistics }

    {
      @description Calculates a robust estimate of the standard deviation using the Median Absolute Deviation (MAD).

      @usage Use as a robust alternative to standard deviation when data may contain outliers. Assumes underlying data is approximately normal for the scaling factor to be accurate.

      @param Data An array of Double values.

      @returns The robust standard deviation estimate (MAD * 1.4826).

      @references https://en.wikipedia.org/wiki/Median_absolute_deviation#Relation_to_standard_deviation

      @warning Raises EStatsError if the input array is empty (via MedianAbsoluteDeviation). The scaling factor 1.4826 assumes normality; the estimate may be less accurate for non-normal distributions.

      @example
      var
        MyData: TDoubleArray;
        RobStdDev: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0; MyData[4] := 100.0; // Outlier
        // MAD is 1.0
        RobStdDev := TStatsKit.RobustStandardDeviation(MyData);
        WriteLn('Robust StdDev: ', RobStdDev:0:4);
        // RobStdDev will be 1.4826 (1.0 * 1.4826)
      end;
    }
    class function RobustStandardDeviation(const Data: TDoubleArray): Double; static;

    {
      @description Calculates Huber's M-estimator for robust location estimation.

      @usage Use as a robust estimate of the central tendency, less sensitive to outliers than the mean. It's a weighted mean where outliers receive lower weights.

      @param Data An array of Double values.
      @param K Tuning constant (default 1.5). Controls the trade-off between efficiency at the normal distribution and robustness against outliers. Common values are 1.345 or 1.5.

      @returns Huber's M-estimate of location.

      @references https://en.wikipedia.org/wiki/M-estimator#Huber's_M-estimator_of_location

      @warning Raises EStatsError if the input array is empty. Returns the median if MAD is zero. The choice of K affects the result.

      @example
      var
        MyData: TDoubleArray;
        HuberEst: Double;
      begin
        SetLength(MyData, 5);
        MyData[0] := 1.0; MyData[1] := 2.0; MyData[2] := 3.0; MyData[3] := 4.0; MyData[4] := 100.0; // Outlier
        // Median = 3.0, MAD = 1.0, K = 1.5
        // Weights: 1, 1, 1, 1, (1.5*1)/|100-3| = 1.5/97 approx 0.015
        HuberEst := TStatsKit.HuberM(MyData, 1.5);
        WriteLn('Huber M-Estimate (k=1.5): ', HuberEst:0:4);
        // HuberEst will be closer to the median than the mean. Approx 2.85
      end;
    }
    class function HuberM(const Data: TDoubleArray; const K: Double = 1.5): Double; static;

    { Bootstrap Methods }

    {
      @description Generates bootstrap samples of the mean.

      @usage Use to estimate the sampling distribution of the mean by repeatedly resampling with replacement from the original data and calculating the mean for each sample.

      @param Data The original array of Double values.
      @param Iterations The number of bootstrap samples to generate.

      @returns An array containing the means calculated from each bootstrap sample.

      @warning The unseeded overload uses caller-managed global random state;
      call Randomize once in the application if nondeterministic samples are
      wanted. The Seed overload uses local reproducible state and does not
      change RandSeed. More iterations generally produce a stabler estimate.

      @example
      var
        MyData, BootMeans: TDoubleArray;
        I: Integer;
      begin
        Randomize;
        SetLength(MyData, 10);
        // Fill MyData with values...
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        BootMeans := TStatsKit.BootstrapMean(MyData, 1000);
        // BootMeans now contains 1000 mean values from bootstrap samples
        WriteLn('First 5 bootstrap means:');
        for I := 0 to 4 do WriteLn(BootMeans[I]:0:4);
        // Calculate stats on BootMeans, e.g., TStatsKit.Mean(BootMeans)
      end;
    }
    class function BootstrapMean(const Data: TDoubleArray;
      const Iterations: Integer): TDoubleArray; static; overload;
    class function BootstrapMean(const Data: TDoubleArray;
      const Iterations: Integer; const Seed: LongWord): TDoubleArray; static; overload;

    {
      @description Calculates a bootstrap percentile confidence interval for the mean.

      @usage Use to estimate a confidence interval for the population mean using bootstrap resampling, without assuming normality.

      @param Data The original array of Double values.
      @param Alpha The significance level (e.g., 0.05 for a 95% CI). Default is 0.05.
      @param Iterations The number of bootstrap samples to generate. Default is 1000.

      @returns A TDoublePair record where Lower is the lower bound and Upper is the upper bound of the confidence interval.

      @references https://en.wikipedia.org/wiki/Bootstrapping_(statistics)#Bootstrap_percentile_interval

      @warning The compatibility overload uses caller-managed global random
      state. The Seed overload is locally reproducible and does not change
      RandSeed. Accuracy depends on the number of iterations; invalid input is
      rejected by BootstrapMean and Percentile.

      @example
      var
        MyData: TDoubleArray;
        CI: TDoublePair;
      begin
        Randomize;
        SetLength(MyData, 20);
        // Fill MyData with values...
        MyData[0] := 10.1; MyData[1] := 9.8; MyData[2] := 10.3; MyData[3] := 11.0; MyData[4] := 9.5;
        MyData[5] := 10.0; MyData[6] := 10.2; MyData[7] := 9.9; MyData[8] := 10.5; MyData[9] := 9.7;
        MyData[10] := 10.1; MyData[11] := 9.8; MyData[12] := 10.3; MyData[13] := 11.0; MyData[14] := 9.5;
        MyData[15] := 10.0; MyData[16] := 10.2; MyData[17] := 9.9; MyData[18] := 10.5; MyData[19] := 9.7;

        CI := TStatsKit.BootstrapConfidenceInterval(MyData, 0.05, 2000); // 95% CI, 2000 iterations
        WriteLn('95% Bootstrap CI for Mean: [', CI.Lower:0:4, ', ', CI.Upper:0:4, ']');
      end;
    }
    class function BootstrapConfidenceInterval(
      const Data: TDoubleArray;
      const Alpha: Double = 0.05;
      const Iterations: Integer = 1000): TDoublePair; static; overload;
    class function BootstrapConfidenceInterval(
      const Data: TDoubleArray;
      const Alpha: Double;
      const Iterations: Integer;
      const Seed: LongWord): TDoublePair; static; overload;
  end;

implementation

type
  TIndexedValue = record
    Value: Double;
    Index: Integer;
  end;
  TIndexedValueArray = array of TIndexedValue;

  TMannWhitneyItem = record
    Value: Double;
    Group: Integer;
    Rank: Double;
  end;
  TMannWhitneyItemArray = array of TMannWhitneyItem;

function DoubleComesFirst(const A, B: Double): Boolean; inline;
begin
  if IsNan(A) then
    Result := IsNan(B)
  else if IsNan(B) then
    Result := True
  else
    Result := A <= B;
end;

procedure MergeSortDoubles(var Data: TDoubleArray);
var
  Work: TDoubleArray;

  procedure SortRange(const Left, Right: Integer);
  var
    Middle, I, J, K: Integer;
  begin
    if Left >= Right then Exit;
    Middle := Left + (Right - Left) div 2;
    SortRange(Left, Middle);
    SortRange(Middle + 1, Right);
    I := Left;
    J := Middle + 1;
    K := Left;
    while (I <= Middle) and (J <= Right) do
    begin
      if DoubleComesFirst(Data[I], Data[J]) then
      begin
        Work[K] := Data[I];
        Inc(I);
      end
      else
      begin
        Work[K] := Data[J];
        Inc(J);
      end;
      Inc(K);
    end;
    while I <= Middle do begin Work[K] := Data[I]; Inc(I); Inc(K); end;
    while J <= Right do begin Work[K] := Data[J]; Inc(J); Inc(K); end;
    for K := Left to Right do Data[K] := Work[K];
  end;

begin
  if Length(Data) < 2 then Exit;
  SetLength(Work, Length(Data));
  SortRange(0, High(Data));
end;

procedure MergeSortIndexed(var Data: TIndexedValueArray);
var
  Work: TIndexedValueArray;

  procedure SortRange(const Left, Right: Integer);
  var
    Middle, I, J, K: Integer;
  begin
    if Left >= Right then Exit;
    Middle := Left + (Right - Left) div 2;
    SortRange(Left, Middle);
    SortRange(Middle + 1, Right);
    I := Left; J := Middle + 1; K := Left;
    while (I <= Middle) and (J <= Right) do
    begin
      if DoubleComesFirst(Data[I].Value, Data[J].Value) then
      begin Work[K] := Data[I]; Inc(I); end
      else begin Work[K] := Data[J]; Inc(J); end;
      Inc(K);
    end;
    while I <= Middle do begin Work[K] := Data[I]; Inc(I); Inc(K); end;
    while J <= Right do begin Work[K] := Data[J]; Inc(J); Inc(K); end;
    for K := Left to Right do Data[K] := Work[K];
  end;

begin
  if Length(Data) < 2 then Exit;
  SetLength(Work, Length(Data));
  SortRange(0, High(Data));
end;

procedure MergeSortMannWhitney(var Data: TMannWhitneyItemArray);
var
  Work: TMannWhitneyItemArray;

  procedure SortRange(const Left, Right: Integer);
  var
    Middle, I, J, K: Integer;
  begin
    if Left >= Right then Exit;
    Middle := Left + (Right - Left) div 2;
    SortRange(Left, Middle);
    SortRange(Middle + 1, Right);
    I := Left; J := Middle + 1; K := Left;
    while (I <= Middle) and (J <= Right) do
    begin
      if DoubleComesFirst(Data[I].Value, Data[J].Value) then
      begin Work[K] := Data[I]; Inc(I); end
      else begin Work[K] := Data[J]; Inc(J); end;
      Inc(K);
    end;
    while I <= Middle do begin Work[K] := Data[I]; Inc(I); Inc(K); end;
    while J <= Right do begin Work[K] := Data[J]; Inc(J); Inc(K); end;
    for K := Left to Right do Data[K] := Work[K];
  end;

begin
  if Length(Data) < 2 then Exit;
  SetLength(Work, Length(Data));
  SortRange(0, High(Data));
end;

function InverseStandardNormal(const P: Double): Double;
const
  A1 = -3.969683028665376E+01; A2 = 2.209460984245205E+02;
  A3 = -2.759285104469687E+02; A4 = 1.383577518672690E+02;
  A5 = -3.066479806614716E+01; A6 = 2.506628277459239E+00;
  B1 = -5.447609879822406E+01; B2 = 1.615858368580409E+02;
  B3 = -1.556989798598866E+02; B4 = 6.680131188771972E+01;
  B5 = -1.328068155288572E+01;
  C1 = -7.784894002430293E-03; C2 = -3.223964580411365E-01;
  C3 = -2.400758277161838E+00; C4 = -2.549732539343734E+00;
  C5 = 4.374664141464968E+00; C6 = 2.938163982698783E+00;
  D1 = 7.784695709041462E-03; D2 = 3.224671290700398E-01;
  D3 = 2.445134137142996E+00; D4 = 3.754408661907416E+00;
  PLow = 0.02425;
var
  Q, R: Double;
begin
  if (P <= 0.0) or (P >= 1.0) then
    raise EStatsError.Create('Normal quantile requires probability in (0, 1)');
  if P < PLow then
  begin
    Q := Sqrt(-2.0 * Ln(P));
    Result := (((((C1*Q+C2)*Q+C3)*Q+C4)*Q+C5)*Q+C6) /
      ((((D1*Q+D2)*Q+D3)*Q+D4)*Q+1.0);
  end
  else if P > 1.0 - PLow then
  begin
    Q := Sqrt(-2.0 * Ln(1.0 - P));
    Result := -(((((C1*Q+C2)*Q+C3)*Q+C4)*Q+C5)*Q+C6) /
      ((((D1*Q+D2)*Q+D3)*Q+D4)*Q+1.0);
  end
  else
  begin
    Q := P - 0.5;
    R := Q * Q;
    Result := (((((A1*R+A2)*R+A3)*R+A4)*R+A5)*R+A6)*Q /
      (((((B1*R+B2)*R+B3)*R+B4)*R+B5)*R+1.0);
  end;
end;

function Polynomial(const Coefficients: array of Double;
  const X: Double): Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := High(Coefficients) downto 0 do
    Result := Result * X + Coefficients[I];
end;

procedure RequireFiniteData(const Data: TDoubleArray; const Name: string);
var
  I: Integer;
begin
  for I := 0 to High(Data) do
    if IsNan(Data[I]) or IsInfinite(Data[I]) then
      raise EStatsError.CreateFmt('%s contains a non-finite value at index %d',
        [Name, I]);
end;

{ TStatsKit }

class procedure TStatsKit.Exchange(var A, B: Double);
var
  Temp: Double;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

class procedure TStatsKit.ExchangeInt(var A, B: Integer);
var
  Temp: Integer;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

class function TStatsKit.Mean(const Data: TDoubleArray): Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate mean of empty array');
    
  Result := Sum(Data) / Length(Data);
end;

class function TStatsKit.Median(const Data: TDoubleArray): Double;
var
  SortedData: TDoubleArray;
  Middle: Integer;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate median of empty array');
    
  // Copy and sort the data
  SortedData := Copy(Data);
  Sort(SortedData);
  
  // Find the median
  Middle := Length(SortedData) div 2;
  if Length(SortedData) mod 2 = 0 then
    Result := (SortedData[Middle - 1] + SortedData[Middle]) / 2
  else
    Result := SortedData[Middle];
end;

class function TStatsKit.Mode(const Data: TDoubleArray): Double;
var
  SortedData: TDoubleArray;
  I, MaxCount, CurrentCount: Integer;
  CurrentValue: Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate mode of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  Result := SortedData[0];
  MaxCount := 1;
  CurrentCount := 1;
  CurrentValue := SortedData[0];
  
  for I := 1 to High(SortedData) do
  begin
    if SortedData[I] = CurrentValue then
      Inc(CurrentCount)
    else
    begin
      if CurrentCount > MaxCount then
      begin
        MaxCount := CurrentCount;
        Result := CurrentValue;
      end;
      CurrentCount := 1;
      CurrentValue := SortedData[I];
    end;
  end;
  
  if CurrentCount > MaxCount then
    Result := CurrentValue;
end;

class function TStatsKit.Range(const Data: TDoubleArray): Double;
var
  SortedData: TDoubleArray;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate range of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  Result := SortedData[High(SortedData)] - SortedData[0];
end;

class function TStatsKit.Variance(const Data: TDoubleArray): Double;
var
  M, SumSq: Double;
  I, N: Integer;
begin
  N := Length(Data);
  if N < 2 then
    raise EStatsError.Create('Cannot calculate variance with less than 2 values');
    
  M := Mean(Data);
  SumSq := 0;
  for I := 0 to High(Data) do
    SumSq := SumSq + Sqr(Data[I] - M);
    
  Result := SumSq / (N - 1);  // Sample variance (n-1)
end;

class function TStatsKit.StandardDeviation(const Data: TDoubleArray): Double;
var
  M, S2: Double;
  I: Integer;
begin
  if Length(Data) < 2 then
    raise EStatsError.Create('Cannot calculate standard deviation with less than 2 values');
    
  M := Mean(Data);
  S2 := 0;
  
  for I := 0 to High(Data) do
    S2 := S2 + Sqr(Data[I] - M);
    
  Result := Sqrt(S2 / Length(Data));  // Population standard deviation (using n)
end;

class function TStatsKit.SampleVariance(const Data: TDoubleArray): Double;
var
  M, SumSq: Double;
  I, N: Integer;
begin
  N := Length(Data);
  if N < 2 then
    raise EStatsError.Create('Cannot calculate sample variance with less than 2 values');
    
  M := Mean(Data);
  SumSq := 0;
  for I := 0 to High(Data) do
    SumSq := SumSq + Sqr(Data[I] - M);
  Result := SumSq / (N - 1);
end;

class function TStatsKit.SampleStandardDeviation(const Data: TDoubleArray): Double;
begin
  Result := Sqrt(SampleVariance(Data));
end;

class function TStatsKit.Skewness(const Data: TDoubleArray): Double;
var
  M, S: Double;
  I: Integer;
  N: Integer;
  Total: Double;
begin
  N := Length(Data);
  if N < 3 then
    raise EStatsError.Create('Cannot calculate skewness with less than 3 values');
    
  M := Mean(Data);
  S := StandardDeviation(Data);
  
  Total := 0;
  for I := 0 to High(Data) do
    Total := Total + Power((Data[I] - M) / S, 3);
    
  Result := Total / N;
end;

class function TStatsKit.Kurtosis(const Data: TDoubleArray): Double;
var
  M, S: Double;
  I: Integer;
  N: Integer;
  Total: Double;
begin
  N := Length(Data);
  if N < 4 then
    raise EStatsError.Create('Cannot calculate kurtosis with less than 4 values');
    
  M := Mean(Data);
  S := SampleStandardDeviation(Data);
  
  Total := 0;
  for I := 0 to High(Data) do
    Total := Total + Power((Data[I] - M) / S, 4);
    
  // Adjusted formula for sample excess kurtosis
  Result := (N * (N + 1) * Total / ((N - 1) * (N - 2) * (N - 3))) - (3 * Sqr(N - 1) / ((N - 2) * (N - 3)));
end;

class function TStatsKit.Percentile(const Data: TDoubleArray; const P: Double): Double;
var
  SortedData: TDoubleArray;
  N: Integer;
  Position: Double;
  Index: Integer;
  Fraction: Double;
begin
  if (P < 0) or (P > 100) then
    raise EStatsError.Create('Percentile must be between 0 and 100');
    
  N := Length(Data);
  if N = 0 then
    raise EStatsError.Create('Cannot calculate percentile of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  Position := (P / 100) * (N - 1);
  Index := Trunc(Position);
  Fraction := Frac(Position);
  
  if Index = High(SortedData) then
    Result := SortedData[Index]
  else
    Result := SortedData[Index] + Fraction * (SortedData[Index + 1] - SortedData[Index]);
end;

class function TStatsKit.Quartile1(const Data: TDoubleArray): Double;
begin
  Result := Percentile(Data, 25);
end;

class function TStatsKit.Quartile3(const Data: TDoubleArray): Double;
begin
  Result := Percentile(Data, 75);
end;

class function TStatsKit.InterquartileRange(const Data: TDoubleArray): Double;
begin
  Result := Quartile3(Data) - Quartile1(Data);
end;

class function TStatsKit.PearsonCorrelation(const X, Y: TDoubleArray): Double;
var
  N: Integer;
  MeanX, MeanY, SumXY, SumX2, SumY2: Double;
  I: Integer;
begin
  N := Length(X);
  if N <> Length(Y) then
    raise EStatsError.Create('Arrays must have equal length for Pearson correlation');
  if N < 2 then
    raise EStatsError.Create('Cannot calculate correlation with less than 2 values');
    
  MeanX := Mean(X);
  MeanY := Mean(Y);
  
  SumXY := 0;
  SumX2 := 0;
  SumY2 := 0;
  
  for I := 0 to N - 1 do
  begin
    SumXY := SumXY + (X[I] - MeanX) * (Y[I] - MeanY);
    SumX2 := SumX2 + Sqr(X[I] - MeanX);
    SumY2 := SumY2 + Sqr(Y[I] - MeanY);
  end;
  
  if (SumX2 = 0) or (SumY2 = 0) then
    Result := 0
  else
    Result := SumXY / Sqrt(SumX2 * SumY2);
end;

class function TStatsKit.SpearmanCorrelation(const X, Y: TDoubleArray): Double;
var
  N: Integer;
  RankX, RankY: TDoubleArray;

  function GetRanks(const Data: TDoubleArray): TDoubleArray;
  var
    I, J, TieCount: Integer;
    Sorted: TIndexedValueArray;
    TieRankSum: Double;
    AverageRank: Double; // Added for clarity in tie handling
  begin
    Result := nil;
    SetLength(Sorted, Length(Data));
    SetLength(Result, Length(Data));

    // Initialize indices and copy data
    for I := 0 to High(Data) do
    begin
      Sorted[I].Index := I;
      Sorted[I].Value := Data[I];
    end;
    MergeSortIndexed(Sorted);

    // Assign ranks, handling ties (restored original logic)
    I := 0;
    while I <= High(Data) do
    begin
      TieCount := 1;
      TieRankSum := I + 1;

      // Count ties (original condition)
      while (I < High(Data)) and (Sorted[I].Value = Sorted[I + 1].Value) do
      begin
        Inc(I);
        Inc(TieCount);
        TieRankSum := TieRankSum + I + 1;
      end;

      // Assign average rank for ties (restored original logic)
      if TieCount > 1 then
      begin
        AverageRank := TieRankSum / TieCount; // Calculate average rank
        for J := I - TieCount + 1 to I do
          Result[Sorted[J].Index] := AverageRank;
      end
      else
        Result[Sorted[I].Index] := I + 1; // Assign rank if no tie

      Inc(I);
    end;
  end;

begin
  N := Length(X);
  if N <> Length(Y) then
    raise EStatsError.Create('Arrays must have equal length for Spearman correlation');
  if N < 2 then
    raise EStatsError.Create('Cannot calculate correlation with less than 2 values');
  RequireFiniteData(X, 'X');
  RequireFiniteData(Y, 'Y');

  // Get ranks for both arrays
  RankX := GetRanks(X);
  RankY := GetRanks(Y);

  // Calculate Pearson correlation of ranks
  Result := PearsonCorrelation(RankX, RankY);
end;

class function TStatsKit.Covariance(const X, Y: TDoubleArray): Double;
var
  N: Integer;
  MeanX, MeanY: Double;
  I: Integer;
  Total: Double;
begin
  N := Length(X);
  if (N <> Length(Y)) or (N < 2) then
    raise EStatsError.Create('Arrays must have equal length and at least 2 elements');
    
  MeanX := Mean(X);
  MeanY := Mean(Y);
  
  Total := 0;
  for I := 0 to High(X) do
    Total := Total + (X[I] - MeanX) * (Y[I] - MeanY);
    
  Result := Total / (N - 1);
end;

class function TStatsKit.ZScore(const Value, AMean, StdDev: Double): Double;
begin
  if StdDev = 0 then
    raise EStatsError.Create('Standard deviation cannot be zero');
  Result := (Value - AMean) / StdDev;
end;

class procedure TStatsKit.Standardize(var Data: TDoubleArray);
var
  M, S: Double;
  I: Integer;
begin
  M := Mean(Data);
  S := StandardDeviation(Data);
  
  if S = 0 then
    raise EStatsError.Create('Cannot standardize data with zero standard deviation');
    
  for I := 0 to High(Data) do
    Data[I] := ZScore(Data[I], M, S);
end;

class function TStatsKit.Sum(const Data: TDoubleArray): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Data) do
    Result := Result + Data[I];
end;

class function TStatsKit.SumOfSquares(const Data: TDoubleArray): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Data) do
    Result := Result + Sqr(Data[I]);
end;

class procedure TStatsKit.Sort(var Data: TDoubleArray);
begin
  MergeSortDoubles(Data);
end;

class function TStatsKit.Describe(const Data: TDoubleArray): TDescriptiveStats;
var
  SortedData: TDoubleArray;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate descriptive statistics of empty array');

  Result.N := Length(Data);
  Result.Mean := Mean(Data);
  Result.Median := Median(Data);
  Result.Mode := Mode(Data);
  Result.Q1 := Quartile1(Data);
  Result.Q3 := Quartile3(Data);
  
  // Calculate Min and Max
  SortedData := Copy(Data);
  Sort(SortedData);
  Result.Min := SortedData[0];
  Result.Max := SortedData[High(SortedData)];
  
  Result.Range := Range(Data);
  Result.IQR := InterquartileRange(Data);
  Result.Variance := Variance(Data);
  Result.StdDev := StandardDeviation(Data);
  Result.Skewness := Skewness(Data);
  Result.Kurtosis := Kurtosis(Data);
  Result.SEM := StandardErrorOfMean(Data);
  Result.CV := CoefficientOfVariation(Data);
end;

class function TStatsKit.GeometricMean(const Data: TDoubleArray): Double;
var
  I: Integer;
  LogSum: Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate geometric mean of empty array');
    
  for I := 0 to High(Data) do
    if Data[I] <= 0 then
      raise EStatsError.Create('Geometric mean requires positive values');
      
  LogSum := 0;
  for I := 0 to High(Data) do
    LogSum := LogSum + Ln(Data[I]);
    
  Result := Exp(LogSum / Length(Data));
end;

class function TStatsKit.HarmonicMean(const Data: TDoubleArray): Double;
var
  I: Integer;
  ReciprocalSum: Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate harmonic mean of empty array');
    
  ReciprocalSum := 0;
  for I := 0 to High(Data) do
  begin
    if Data[I] <= 0 then
      raise EStatsError.Create('Harmonic mean requires positive values');
    ReciprocalSum := ReciprocalSum + 1 / Data[I];  // Simple division
  end;
  
  if ReciprocalSum = 0 then
    raise EStatsError.Create('Cannot calculate harmonic mean when sum of reciprocals is zero');
    
  Result := Length(Data) / ReciprocalSum;  // Simple division
end;

class function TStatsKit.TrimmedMean(const Data: TDoubleArray; const Percent: Double): Double;
var
  SortedData: TDoubleArray;
  TrimCount, StartIdx, EndIdx: Integer;
  I: Integer;
  TrimmedSum: Double;
begin
  if (Percent < 0) or (Percent >= 50) then
    raise EStatsError.Create('Trim percentage must be between 0 and 50');
    
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate trimmed mean of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  TrimCount := Floor(Length(Data) * (Percent / 100));  // Calculate number to trim from each end
  StartIdx := TrimCount;
  EndIdx := Length(Data) - TrimCount - 1;
  
  TrimmedSum := 0;
  for I := StartIdx to EndIdx do
    TrimmedSum := TrimmedSum + SortedData[I];
    
  Result := TrimmedSum / (EndIdx - StartIdx + 1);
end;

class function TStatsKit.WinsorizedMean(const Data: TDoubleArray; const Percent: Double): Double;
var
  SortedData: TDoubleArray;
  WinsorCount: Integer;
  I: Integer;
  WinsorizedSum: Double;
begin
  if (Percent < 0) or (Percent >= 50) then
    raise EStatsError.Create('Winsorization percentage must be between 0 and 50');
    
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate Winsorized mean of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  WinsorCount := Round(Length(Data) * (Percent / 100));
  
  // Replace values with Winsorized values
  for I := 0 to WinsorCount - 1 do
    SortedData[I] := SortedData[WinsorCount];
    
  for I := Length(SortedData) - WinsorCount to High(SortedData) do
    SortedData[I] := SortedData[Length(SortedData) - WinsorCount - 1];
    
  WinsorizedSum := 0;
  for I := 0 to High(SortedData) do
    WinsorizedSum := WinsorizedSum + SortedData[I];
    
  Result := WinsorizedSum / Length(SortedData);
end;

class function TStatsKit.StandardErrorOfMean(const Data: TDoubleArray): Double;
begin
  if Length(Data) < 2 then
    raise EStatsError.Create('Cannot calculate SEM with less than 2 values');
    
  Result := SampleStandardDeviation(Data) / Sqrt(Length(Data));
end;

class function TStatsKit.CoefficientOfVariation(const Data: TDoubleArray): Double;
var
  M, S: Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate CV of empty array');
    
  M := Mean(Data);
  if M = 0 then
    raise EStatsError.Create('Cannot calculate CV when mean is zero');
    
  S := StandardDeviation(Data);
  Result := (S / Abs(M)) * 100;  // Simple percentage calculation
end;

class function TStatsKit.MedianAbsoluteDeviation(const Data: TDoubleArray): Double;
var
  M: Double;
  Deviations: TDoubleArray;
  I: Integer;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate MAD of empty array');
    
  M := Median(Data);
  SetLength(Deviations, Length(Data));  // Initialize the array
  
  for I := 0 to High(Data) do
    Deviations[I] := Abs(Data[I] - M);
    
  Result := Median(Deviations);
end;

class function TStatsKit.RobustStandardDeviation(const Data: TDoubleArray): Double;
begin
  // MAD * 1.4826 is a robust estimator of standard deviation for normal distributions
  Result := MedianAbsoluteDeviation(Data) * 1.4826;
end;

class function TStatsKit.HuberM(const Data: TDoubleArray; const K: Double = 1.5): Double;
var
  M, MAD: Double;
  I: Integer;
  WeightedSum, WeightSum: Double;
  Weight: Double;
begin
  if Length(Data) = 0 then
    raise EStatsError.Create('Cannot calculate Huber M-estimator of empty array');
    
  M := Median(Data);
  MAD := MedianAbsoluteDeviation(Data);
  
  if MAD = 0 then
    Exit(M);  // If MAD is 0, return median
    
  WeightedSum := 0;
  WeightSum := 0;
  
  for I := 0 to High(Data) do
  begin
    if Abs(Data[I] - M) <= K * MAD then
      Weight := 1
    else
      Weight := (K * MAD) / Abs(Data[I] - M);
      
    WeightedSum := WeightedSum + Weight * Data[I];
    WeightSum := WeightSum + Weight;
  end;
  
  Result := WeightedSum / WeightSum;
end;

class function TStatsKit.BootstrapMean(const Data: TDoubleArray; const Iterations: Integer): TDoubleArray;
var
  I: Integer;
  Sample: TDoubleArray;
begin
  Result := nil;
  if Length(Data) = 0 then
    raise EStatsError.Create('BootstrapMean requires non-empty data');
  if Iterations <= 0 then
    raise EStatsError.Create('BootstrapMean requires Iterations > 0');
  SetLength(Result, Iterations);
  for I := 0 to Iterations - 1 do
  begin
    Sample := RandomSample(Data);
    Result[I] := Mean(Sample);
  end;
end;

class function TStatsKit.BootstrapMean(const Data: TDoubleArray;
  const Iterations: Integer; const Seed: LongWord): TDoubleArray;
var
  I, J, Index: Integer;
  State: LongWord;
  Sample: TDoubleArray;
begin
  Result := nil;
  if Length(Data) = 0 then
    raise EStatsError.Create('BootstrapMean requires non-empty data');
  if Iterations <= 0 then
    raise EStatsError.Create('BootstrapMean requires Iterations > 0');
  State := Seed;
  SetLength(Result, Iterations);
  SetLength(Sample, Length(Data));
  for I := 0 to Iterations - 1 do
  begin
    for J := 0 to High(Sample) do
    begin
      State := LongWord((QWord(State) * 1664525 + 1013904223) and $FFFFFFFF);
      Index := State mod LongWord(Length(Data));
      Sample[J] := Data[Index];
    end;
    Result[I] := Mean(Sample);
  end;
end;

class function TStatsKit.BootstrapConfidenceInterval(
  const Data: TDoubleArray;
  const Alpha: Double = 0.05;
  const Iterations: Integer = 1000): TDoublePair;
var
  Means: TDoubleArray;
begin
  if (Alpha <= 0) or (Alpha >= 1) or IsNan(Alpha) or IsInfinite(Alpha) then
    raise EStatsError.Create('BootstrapConfidenceInterval requires Alpha in (0, 1)');
  Means := BootstrapMean(Data, Iterations);
  Sort(Means);
  
  Result.Lower := Percentile(Means, (Alpha / 2) * 100);
  Result.Upper := Percentile(Means, (1 - (Alpha / 2)) * 100);
end;

class function TStatsKit.BootstrapConfidenceInterval(
  const Data: TDoubleArray;
  const Alpha: Double;
  const Iterations: Integer;
  const Seed: LongWord): TDoublePair;
var
  Means: TDoubleArray;
begin
  if (Alpha <= 0) or (Alpha >= 1) or IsNan(Alpha) or IsInfinite(Alpha) then
    raise EStatsError.Create('BootstrapConfidenceInterval requires Alpha in (0, 1)');
  Means := BootstrapMean(Data, Iterations, Seed);
  Sort(Means);
  Result.Lower := Percentile(Means, (Alpha / 2) * 100);
  Result.Upper := Percentile(Means, (1 - (Alpha / 2)) * 100);
end;

class function TStatsKit.RandomSample(const Data: TDoubleArray): TDoubleArray;
var
  I: Integer;
begin
  Result := nil;
  if Length(Data) = 0 then
    raise EStatsError.Create('RandomSample requires non-empty data');
  SetLength(Result, Length(Data));
  for I := 0 to High(Data) do
    Result[I] := Data[Random(Length(Data))];
end;

class function TStatsKit.TTest(const X, Y: TDoubleArray; out TPValue: Double): Double;
var
  MeanX, MeanY, VarX, VarY: Double;
  NX, NY: Integer;
  PooledVar, SE: Double;
  DF: Integer;
begin
  if (Length(X) < 2) or (Length(Y) < 2) then
    raise EStatsError.Create('T-test requires at least 2 values in each group');
    
  NX := Length(X);
  NY := Length(Y);
  MeanX := Mean(X);
  MeanY := Mean(Y);
  VarX := Variance(X);
  VarY := Variance(Y);
  
  // Pooled variance
  PooledVar := ((NX - 1) * VarX + (NY - 1) * VarY) / (NX + NY - 2);
  
  if PooledVar <= 0 then
    raise EStatsError.Create('Invalid pooled variance for T-test calculation');
    
  SE := Sqrt(PooledVar * (1.0/NX + 1.0/NY));
  
  if SE = 0 then
    raise EStatsError.Create('Cannot calculate T-statistic with zero standard error');
    
  Result := (MeanX - MeanY) / SE;
  
  // Degrees of freedom
  DF := NX + NY - 2;
  
  // Calculate p-value using Student's t-distribution
  TPValue := 2.0 * (1.0 - StudentT(DF, Abs(Result)));
  
  // Ensure p-value is between 0 and 1
  if TPValue < 0 then
    TPValue := 0
  else if TPValue > 1 then
    TPValue := 1;
end;

class function TStatsKit.MannWhitneyU(const X, Y: TDoubleArray; out UPValue: Double): Double;
var
  NX, NY, N, I, J, RankIndex, Chosen, RankSumIndex: Integer;
  RankSum: Double;
  AllData: TMannWhitneyItemArray;
  U1, U2: Double;
  TieCount: Integer;
  TieSum, TieCorrectionSum: Double;
  AverageRank: Double;
  ExpectedMean: Double;
  DistVariance: Double;
  Z: Double;
  HasTies: Boolean;
  Counts: array of array of Extended;
  TotalCount, TailCount: Extended;
  MinRankSum, MaxRankSum, TargetRankSum, MaxChosen: Integer;
begin
  NX := Length(X);
  NY := Length(Y);
  if (NX < 2) or (NY < 2) then
    raise EStatsError.Create('Mann-Whitney U test requires at least 2 values in each group');
  RequireFiniteData(X, 'X');
  RequireFiniteData(Y, 'Y');
  N := NX + NY;
    
  // Initialize managed type
  SetLength(AllData, NX + NY);
  
  // Combine data and assign groups
  for I := 0 to NX - 1 do
  begin
    AllData[I].Value := X[I];
    AllData[I].Group := 1;
    AllData[I].Rank := 0;  // Initialize rank
  end;
  for I := 0 to NY - 1 do
  begin
    AllData[NX + I].Value := Y[I];
    AllData[NX + I].Group := 2;
    AllData[NX + I].Rank := 0;  // Initialize rank
  end;
  
  MergeSortMannWhitney(AllData);

  // Assign ranks (handling ties)
  I := 0;
  HasTies := False;
  TieCorrectionSum := 0.0;
  while I <= High(AllData) do
  begin
    TieCount := 1;
    TieSum := I + 1;
    
    while (I < High(AllData)) and (AllData[I + 1].Value = AllData[I].Value) do
    begin
      Inc(I);
      Inc(TieCount);
      TieSum := TieSum + I + 1;
    end;
    
    AverageRank := TieSum / TieCount;
    if TieCount > 1 then
    begin
      HasTies := True;
      TieCorrectionSum := TieCorrectionSum + Sqr(TieCount) * TieCount - TieCount;
    end;
    for J := I - TieCount + 1 to I do
      AllData[J].Rank := AverageRank;
      
    Inc(I);
  end;
  
  // Calculate rank sum for positive differences
  RankSum := 0;
  for I := 0 to High(AllData) do
    if AllData[I].Group = 1 then
      RankSum := RankSum + AllData[I].Rank;
      
  U1 := RankSum - (NX * (NX + 1)) / 2;
  U2 := NX * NY - U1;
  
  Result := Min(U1, U2);

  { Exact two-sided distribution for small untied samples. Counts[c,s] is
    the number of ways to choose c ranks whose sum is s. }
  if (not HasTies) and (N <= 50) then
  begin
    MinRankSum := NX * (NX + 1) div 2;
    MaxRankSum := NX * (2 * N - NX + 1) div 2;
    TargetRankSum := MinRankSum + Round(Result);
    SetLength(Counts, NX + 1);
    for Chosen := 0 to NX do
      SetLength(Counts[Chosen], MaxRankSum + 1);
    Counts[0][0] := 1.0;
    for RankIndex := 1 to N do
    begin
      MaxChosen := Min(RankIndex, NX);
      for Chosen := MaxChosen downto 1 do
        for RankSumIndex := MaxRankSum downto RankIndex do
          Counts[Chosen][RankSumIndex] := Counts[Chosen][RankSumIndex] +
            Counts[Chosen - 1][RankSumIndex - RankIndex];
    end;
    TotalCount := 0.0;
    TailCount := 0.0;
    for RankSumIndex := MinRankSum to MaxRankSum do
    begin
      TotalCount := TotalCount + Counts[NX][RankSumIndex];
      if RankSumIndex <= TargetRankSum then
        TailCount := TailCount + Counts[NX][RankSumIndex];
    end;
    UPValue := Min(1.0, Double(2.0 * TailCount / TotalCount));
  end
  else
  begin
    ExpectedMean := NX * NY / 2.0;
    DistVariance := (NX * NY / 12.0) *
      ((N + 1.0) - TieCorrectionSum / (N * (N - 1.0)));
    if DistVariance <= 0.0 then
      raise EStatsError.Create('Mann-Whitney U variance is zero');
    Z := (Abs(U1 - ExpectedMean) - 0.5) / Sqrt(DistVariance);
    if Z < 0.0 then Z := 0.0;
    UPValue := 2.0 * (1.0 - NormalCDF(Z));
    UPValue := Max(0.0, Min(1.0, UPValue));
  end;
end;

class function TStatsKit.KolmogorovSmirnovTest(const Data: TDoubleArray; out KSPValue: Double): Double;
var
  N, I, K: Integer;
  MaxDiff, MeanValue, StdDevValue: Double;
  SortedData: TDoubleArray;
  ExpectedCDF: Double;
  DPlus, DMinus, Lambda, Term, SeriesSum: Double;
begin
  N := Length(Data);
  if N < 5 then
    raise EStatsError.Create('K-S test requires at least 5 values');
  RequireFiniteData(Data, 'Data');
  MeanValue := Mean(Data);
  StdDevValue := StandardDeviation(Data);
  if StdDevValue = 0.0 then
    raise EStatsError.Create('K-S normality test requires non-constant data');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  MaxDiff := 0;
  for I := 0 to High(SortedData) do
  begin
    ExpectedCDF := NormalCDF((SortedData[I] - MeanValue) / StdDevValue);
    DPlus := (I + 1.0) / N - ExpectedCDF;
    DMinus := ExpectedCDF - I / N;
    MaxDiff := Max(MaxDiff, Max(DPlus, DMinus));
  end;
  
  Result := MaxDiff;

  Lambda := (Sqrt(N) + 0.12 + 0.11 / Sqrt(N)) * MaxDiff;
  SeriesSum := 0.0;
  for K := 1 to 100 do
  begin
    Term := 2.0 * Exp(-2.0 * Sqr(K * Lambda));
    if Odd(K) then
      SeriesSum := SeriesSum + Term
    else
      SeriesSum := SeriesSum - Term;
    if Term < 1E-15 then Break;
  end;
  KSPValue := Max(0.0, Min(1.0, SeriesSum));
end;

class function TStatsKit.IsNormal(const Data: TDoubleArray; const Alpha: Double): Boolean;
var
  KSPValue: Double;
begin
  if IsNan(Alpha) or IsInfinite(Alpha) or (Alpha <= 0.0) or (Alpha >= 1.0) then
    raise EStatsError.Create('Alpha must be in the open interval (0, 1)');
  KolmogorovSmirnovTest(Data, KSPValue);
  Result := KSPValue >= Alpha;
end;

class function TStatsKit.ShapiroWilkTest(const Data: TDoubleArray; out WPValue: Double): Double;
var
  N, I: Integer;
  SortedData: TDoubleArray;
  DataMean, S2, B, W, SumM2, ScaleFactor, RSN, A1, A2: Double;
  Y, Mu, Sigma, Z: Double;
  Weights: array of Double;
const
  C1: array[0..5] of Double =
    (0.0, 0.221157, -0.147981, -2.07119, 4.434685, -2.706056);
  C2: array[0..5] of Double =
    (0.0, 0.042981, -0.293762, -1.752461, 5.682633, -3.582633);
  C3: array[0..3] of Double = (0.5440, -0.39978, 0.025054, -0.0006714);
  C4: array[0..3] of Double = (1.3822, -0.77857, 0.062767, -0.0020322);
  C5: array[0..3] of Double = (-1.5861, -0.31082, -0.083751, 0.0038915);
  C6: array[0..2] of Double = (-0.4803, -0.082676, 0.0030302);
  G: array[0..1] of Double = (-2.273, 0.459);
begin
  N := Length(Data);
  if (N < 3) or (N > 5000) then
    raise EStatsError.Create('Shapiro-Wilk test requires 3-5000 values');
  RequireFiniteData(Data, 'Data');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  { Expected normal order statistics with Royston's endpoint corrections. }
  SetLength(Weights, N div 2);
  SumM2 := 0.0;
  for I := 0 to High(Weights) do
  begin
    Weights[I] := InverseStandardNormal((I + 1.0 - 0.375) / (N + 0.25));
    SumM2 := SumM2 + 2.0 * Sqr(Weights[I]);
  end;
  ScaleFactor := Sqrt(SumM2);
  RSN := 1.0 / Sqrt(N);
  A1 := Polynomial(C1, RSN) - Weights[0] / ScaleFactor;
  if N > 5 then
  begin
    A2 := Polynomial(C2, RSN) - Weights[1] / ScaleFactor;
    ScaleFactor := Sqrt((SumM2 - 2.0 * Sqr(Weights[0]) -
      2.0 * Sqr(Weights[1])) / (1.0 - 2.0 * Sqr(A1) - 2.0 * Sqr(A2)));
    Weights[1] := A2;
  end
  else
    ScaleFactor := Sqrt((SumM2 - 2.0 * Sqr(Weights[0])) /
      (1.0 - 2.0 * Sqr(A1)));
  Weights[0] := A1;
  for I := 2 - Ord(N <= 5) to High(Weights) do
    Weights[I] := -Weights[I] / ScaleFactor;
  
  DataMean := Mean(SortedData);
  S2 := 0;
  for I := 0 to High(SortedData) do
    S2 := S2 + Sqr(SortedData[I] - DataMean);
    
  // Calculate B using weights
  B := 0;
  for I := 0 to (N div 2) - 1 do
    B := B + Weights[I] * (SortedData[N - 1 - I] - SortedData[I]);
  
  B := Sqr(B);
  if S2 = 0 then
    raise EStatsError.Create('Shapiro-Wilk test requires non-constant data');
  W := B / S2;
    
  Result := Max(0, Min(1, W));  // Ensure W is between 0 and 1
  
  if Result >= 1.0 - 1E-15 then
    WPValue := 1
  else if N = 3 then
    WPValue := (6.0 / Pi) * (ArcSin(Sqrt(Result)) - Pi / 3.0)
  else
  begin
    Y := Ln(1.0 - Result);
    if N <= 11 then
    begin
      Z := Polynomial(G, N);
      if Y >= Z then
        WPValue := 0.0
      else
      begin
        Y := -Ln(Z - Y);
        Mu := Polynomial(C3, N);
        Sigma := Exp(Polynomial(C4, N));
        WPValue := 1.0 - NormalCDF((Y - Mu) / Sigma);
      end;
    end
    else
    begin
      Z := Ln(N);
      Mu := Polynomial(C5, Z);
      Sigma := Exp(Polynomial(C6, Z));
      WPValue := 1.0 - NormalCDF((Y - Mu) / Sigma);
    end;
  end;
  WPValue := Max(0.0, Min(1.0, WPValue));
end;

class function TStatsKit.CohensD(const X, Y: TDoubleArray): Double;
var
  MeanX, MeanY, PooledVariance, PooledSD: Double;
begin
  if (Length(X) < 2) or (Length(Y) < 2) then
    raise EStatsError.Create('Cohen''s d requires at least 2 values in each group');
    
  MeanX := Mean(X);
  MeanY := Mean(Y);
  RequireFiniteData(X, 'X');
  RequireFiniteData(Y, 'Y');
  PooledVariance := ((Length(X) - 1) * Variance(X) +
    (Length(Y) - 1) * Variance(Y)) / (Length(X) + Length(Y) - 2);
  if PooledVariance <= 0.0 then
    raise EStatsError.Create('Cohen''s d requires non-zero pooled variance');
  PooledSD := Sqrt(PooledVariance);
                   
  Result := (MeanX - MeanY) / PooledSD;
end;

class function TStatsKit.HedgesG(const X, Y: TDoubleArray): Double;
var
  D: Double;
  CorrectionFactor: Double;
begin
  D := CohensD(X, Y);
  
  // Small sample size correction factor
  CorrectionFactor := 1 - (3 / (4 * (Length(X) + Length(Y) - 2) - 1));
  Result := D * CorrectionFactor;
end;

class function TStatsKit.SignTest(const X, Y: TDoubleArray): Double;
var
  I, NPos, NNeg, N: Integer;
begin
  if Length(X) <> Length(Y) then
    raise EStatsError.Create('Sign test requires equal length arrays');
    
  NPos := 0;
  NNeg := 0;
  
  for I := 0 to High(X) do
  begin
    if X[I] > Y[I] then
      Inc(NPos)
    else if X[I] < Y[I] then
      Inc(NNeg);
  end;
  
  N := NPos + NNeg;
  if N = 0 then
    raise EStatsError.Create('Sign test requires at least one non-zero difference');
    
  // Return proportion of positive differences
  Result := NPos / N;
end;

class function TStatsKit.WilcoxonSignedRank(const X, Y: TDoubleArray): Double;
var
  I, J, N: Integer;
  Differences: array of record
    Value: Double;
    AbsValue: Double;
    Rank: Double;
  end;
  RankSum: Double;
  TieCount: Integer;
  TieSum: Double;
  AverageRank: Double;
  TempValue: Double;
  TempAbsValue: Double;
  TempRank: Double;
begin
  if Length(X) <> Length(Y) then
    raise EStatsError.Create('Wilcoxon test requires equal length arrays');
    
  // Calculate differences and absolute values
  N := 0;
  SetLength(Differences, Length(X));
  for I := 0 to High(X) do
  begin
    if X[I] <> Y[I] then
    begin
      Differences[N].Value := X[I] - Y[I];
      Differences[N].AbsValue := Abs(Differences[N].Value);
      Differences[N].Rank := 0;  // Initialize rank
      Inc(N);
    end;
  end;
  SetLength(Differences, N);
  
  if N = 0 then
    raise EStatsError.Create('Wilcoxon test requires at least one non-zero difference');
    
  // Sort by absolute value
  for I := 0 to N - 2 do
    for J := I + 1 to N - 1 do
      if Differences[J].AbsValue < Differences[I].AbsValue then
      begin
        // Store temporary values
        TempValue := Differences[I].Value;
        TempAbsValue := Differences[I].AbsValue;
        TempRank := Differences[I].Rank;
        
        // Copy J to I
        Differences[I].Value := Differences[J].Value;
        Differences[I].AbsValue := Differences[J].AbsValue;
        Differences[I].Rank := Differences[J].Rank;
        
        // Copy temp to J
        Differences[J].Value := TempValue;
        Differences[J].AbsValue := TempAbsValue;
        Differences[J].Rank := TempRank;
      end;
      
  // Assign ranks (handling ties)
  I := 0;
  while I < N do
  begin
    TieCount := 1;
    TieSum := I + 1;
    
    while (I < N - 1) and (Differences[I + 1].AbsValue = Differences[I].AbsValue) do
    begin
      Inc(I);
      Inc(TieCount);
      TieSum := TieSum + I + 1;
    end;
    
    AverageRank := TieSum / TieCount;
    for J := I - TieCount + 1 to I do
      Differences[J].Rank := AverageRank;
      
    Inc(I);
  end;
  
  // Calculate rank sum for positive differences
  RankSum := 0;
  for I := 0 to N - 1 do
    if Differences[I].Value > 0 then
      RankSum := RankSum + Differences[I].Rank;
      
  Result := RankSum;
end;

class function TStatsKit.KendallTau(const X, Y: TDoubleArray): Double;
var
  I, J: Integer;
  Concordant, Discordant: Integer;
begin
  if Length(X) <> Length(Y) then
    raise EStatsError.Create('Kendall''s tau requires equal length arrays');
    
  Concordant := 0;
  Discordant := 0;
  
  for I := 0 to High(X) - 1 do
    for J := I + 1 to High(X) do
    begin
      if ((X[I] < X[J]) and (Y[I] < Y[J])) or
         ((X[I] > X[J]) and (Y[I] > Y[J])) then
        Inc(Concordant)
      else if ((X[I] < X[J]) and (Y[I] > Y[J])) or
              ((X[I] > X[J]) and (Y[I] < Y[J])) then
        Inc(Discordant);
    end;
    
  if (Concordant = 0) and (Discordant = 0) then
    Result := 0
  else
    Result := (Concordant - Discordant) / Sqrt((Concordant + Discordant) * (Concordant + Discordant));
end;

class function TStatsKit.Quantile(const Data: TDoubleArray; const Q: Double): Double;
var
  SortedData: TDoubleArray;
  N: Integer;
  Position: Double;
  Index: Integer;
  Fraction: Double;
begin
  if (Q < 0) or (Q > 1) then
    raise EStatsError.Create('Quantile must be between 0 and 1');
    
  N := Length(Data);
  if N = 0 then
    raise EStatsError.Create('Cannot calculate quantile of empty array');
    
  SortedData := Copy(Data);
  Sort(SortedData);
  
  Position := Q * (N - 1);
  Index := Trunc(Position);
  Fraction := Frac(Position);
  
  if Index = High(SortedData) then
    Result := SortedData[Index]
  else
    Result := SortedData[Index] + Fraction * (SortedData[Index + 1] - SortedData[Index]);
end;

{ TDescriptiveStats }

function TDescriptiveStats.ToString: string;
begin
  Result := 'Descriptive Statistics' + LineEnding +
            '======================' + LineEnding +
            Format('N: %d', [N]) + LineEnding +
            'Central Tendency:' + LineEnding +
            Format('  Mean: %.6f', [Mean]) + LineEnding +
            Format('  Median: %.6f', [Median]) + LineEnding +
            Format('  Mode: %.6f', [Mode]) + LineEnding +
            'Dispersion:' + LineEnding +
            Format('  Range: %.6f', [Range]) + LineEnding +
            Format('  Variance: %.6f', [Variance]) + LineEnding +
            Format('  StdDev: %.6f', [StdDev]) + LineEnding +
            Format('  SEM: %.6f', [SEM]) + LineEnding +
            Format('  CV: %.2f%%', [CV]) + LineEnding +
            'Distribution Shape:' + LineEnding +
            Format('  Skewness: %.6f', [Skewness]) + LineEnding +
            Format('  Kurtosis: %.6f', [Kurtosis]) + LineEnding +
            'Quartiles:' + LineEnding +
            Format('  Min (0%%): %.6f', [Min]) + LineEnding +
            Format('  Q1 (25%%): %.6f', [Q1]) + LineEnding +
            Format('  Q2 (50%%): %.6f', [Median]) + LineEnding +
            Format('  Q3 (75%%): %.6f', [Q3]) + LineEnding +
            Format('  Max (100%%): %.6f', [Max]) + LineEnding +
            Format('  IQR: %.6f', [IQR]);
end;

function TDescriptiveStats.ToStringWide: string;
const
  // Column widths for alignment
  COL_WIDTH = 12;
  
  function PadCenter(const S: string; Width: Integer): string;
  var
    PadLeft, PadRight: Integer;
  begin
    if Length(S) >= Width then
      Result := S
    else
    begin
      PadLeft := (Width - Length(S)) div 2;
      PadRight := Width - Length(S) - PadLeft;
      Result := StringOfChar(' ', PadLeft) + S + StringOfChar(' ', PadRight);
    end;
  end;
  
  function FormatValue(const Value: Double): string;
  begin
    Result := PadCenter(Format('%.4f', [Value]), COL_WIDTH);
  end;
  
begin
  Result := 'Descriptive Statistics' + LineEnding +
            '===================' + LineEnding +
            'N' + StringOfChar(' ', COL_WIDTH - 1) + '|' +
            PadCenter('Mean', COL_WIDTH) + '|' +
            PadCenter('Median', COL_WIDTH) + '|' +
            PadCenter('StdDev', COL_WIDTH) + '|' +
            PadCenter('SEM', COL_WIDTH) + '|' +
            PadCenter('CV(%)', COL_WIDTH) + LineEnding +
            StringOfChar('-', 6 * COL_WIDTH + 5) + LineEnding +
            PadCenter(Format('%d', [N]), COL_WIDTH) + '|' +
            FormatValue(Mean) + '|' +
            FormatValue(Median) + '|' +
            FormatValue(StdDev) + '|' +
            FormatValue(SEM) + '|' +
            FormatValue(CV) + LineEnding + LineEnding +
            
            'Shape' + StringOfChar(' ', COL_WIDTH - 5) + '|' +
            PadCenter('Skewness', COL_WIDTH) + '|' +
            PadCenter('Kurtosis', COL_WIDTH) + '|' +
            PadCenter('Range', COL_WIDTH) + '|' +
            PadCenter('IQR', COL_WIDTH) + LineEnding +
            StringOfChar('-', 5 * COL_WIDTH + 4) + LineEnding +
            StringOfChar(' ', COL_WIDTH) + '|' +
            FormatValue(Skewness) + '|' +
            FormatValue(Kurtosis) + '|' +
            FormatValue(Range) + '|' +
            FormatValue(IQR) + LineEnding + LineEnding +
            
            'Quantiles' + StringOfChar(' ', COL_WIDTH - 9) + '|' +
            PadCenter('Min', COL_WIDTH) + '|' +
            PadCenter('Q1', COL_WIDTH) + '|' +
            PadCenter('Q2', COL_WIDTH) + '|' +
            PadCenter('Q3', COL_WIDTH) + '|' +
            PadCenter('Max', COL_WIDTH) + LineEnding +
            StringOfChar('-', 6 * COL_WIDTH + 5) + LineEnding +
            StringOfChar(' ', COL_WIDTH) + '|' +
            FormatValue(Min) + '|' +
            FormatValue(Q1) + '|' +
            FormatValue(Median) + '|' +
            FormatValue(Q3) + '|' +
            FormatValue(Max);
end;

end. 
