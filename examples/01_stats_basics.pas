program StatsBasics;

{-----------------------------------------------------------------------------
  01_stats_basics.pas

  Demonstrates the usual first steps with a dataset: create a TDoubleArray,
  summarise it, inspect individual measures, compare two series, and estimate
  a reproducible bootstrap confidence interval.

  Build (FPC command line):
    mkdir lib
    fpc -Fu../src -FUlib 01_stats_basics.pas

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  MathBase.SharedTypes,   // TDoubleArray
  StatsLib.Stats;         // TStatsKit, TDescriptiveStats

var
  Data: TDoubleArray;
  S: TDescriptiveStats;
  X, Y: TDoubleArray;
  CI: TDoublePair;

begin
  // ── 1. Build a dataset ──────────────────────────────────────────────────
  // Daily temperatures (°C) over one week
  Data := TDoubleArray.Create(18.2, 21.5, 19.8, 23.1, 20.0, 17.6, 22.4);

  // ── 2. Describe prints a formatted summary in one call ──────────────────
  S := TStatsKit.Describe(Data);
  WriteLn('=== Descriptive Statistics ===');
  WriteLn(S.ToString);

  // ── 3. Individual measures ──────────────────────────────────────────────
  WriteLn('--- Individual measures ---');
  WriteLn(Format('Mean       : %.4f', [TStatsKit.Mean(Data)]));
  WriteLn(Format('Median     : %.4f', [TStatsKit.Median(Data)]));
  WriteLn(Format('Std Dev    : %.4f', [TStatsKit.StandardDeviation(Data)]));
  WriteLn(Format('Skewness   : %.4f', [TStatsKit.Skewness(Data)]));
  WriteLn(Format('Kurtosis   : %.4f', [TStatsKit.Kurtosis(Data)]));
  WriteLn(Format('CV (%%)     : %.2f', [TStatsKit.CoefficientOfVariation(Data)]));
  WriteLn;

  // ── 4. Percentiles ──────────────────────────────────────────────────────
  WriteLn('--- Percentiles ---');
  WriteLn(Format('10th pct   : %.4f', [TStatsKit.Percentile(Data, 10)]));
  WriteLn(Format('25th pct   : %.4f', [TStatsKit.Percentile(Data, 25)]));
  WriteLn(Format('75th pct   : %.4f', [TStatsKit.Percentile(Data, 75)]));
  WriteLn(Format('90th pct   : %.4f', [TStatsKit.Percentile(Data, 90)]));
  WriteLn;

  // ── 5. Correlation between two series ───────────────────────────────────
  X := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0);  // day index
  Y := Data;                                                        // temperature

  WriteLn('--- Correlation (day index vs temperature) ---');
  WriteLn(Format('Pearson r  : %.4f', [TStatsKit.PearsonCorrelation(X, Y)]));
  WriteLn(Format('Spearman r : %.4f', [TStatsKit.SpearmanCorrelation(X, Y)]));
  WriteLn;

  // ── 6. Bootstrap 95 %% confidence interval for the mean ─────────────────
  // The final argument is a fixed seed. It makes this teaching example
  // repeatable and does not change Pascal's process-wide random state.
  CI := TStatsKit.BootstrapConfidenceInterval(Data, 0.05, 1000, 2026);
  WriteLn('--- 95%% Bootstrap CI for the mean ---');
  WriteLn(Format('Lower : %.4f', [CI.Lower]));
  WriteLn(Format('Upper : %.4f', [CI.Upper]));
  WriteLn;

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
