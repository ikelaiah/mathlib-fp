program example07_probability;

{-----------------------------------------------------------------------------
 Example 07 — ProbabilityLib Walkthrough

 This example is written for someone who is new to probability distributions.
 Each section introduces one distribution, explains what it models, and shows
 the five standard calls: PDF/PMF, CDF, Survival, Mean, Variance.

 Compile:  fpc -Fu../src -FUlib 07_probability.lpr
 Run:      ./07_probability  (Linux/macOS)
           07_probability.exe  (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  ProbabilityLib.Distributions;

{ Small helper — print a labelled double value }
procedure Show(const Label_: String; const Value: Double);
begin
  WriteLn(Format('  %-40s %10.6f', [Label_, Value]));
end;

procedure PrintSeparator;
begin
  WriteLn(StringOfChar('-', 55));
end;

{ ============================================================
  SECTION 1 — Normal Distribution
  The classic "bell curve". Used everywhere: heights, test
  scores, measurement errors.
============================================================ }
procedure DemoNormal;
begin
  WriteLn;
  WriteLn('=== NORMAL DISTRIBUTION ===');
  WriteLn('Parameters: Mu=170 cm (mean height), Sigma=10 cm');
  PrintSeparator;

  Show('PDF at x=170 (the peak)',
    TProbabilityKit.NormalPDF(170, 170, 10));

  Show('CDF at x=180 — P(height <= 180)',
    TProbabilityKit.NormalCDF(180, 170, 10));

  Show('Survival at x=190 — P(height > 190)',
    TProbabilityKit.NormalSurvival(190, 170, 10));

  Show('Mean (= Mu)',
    TProbabilityKit.NormalMean(170, 10));

  Show('Variance (= Sigma^2)',
    TProbabilityKit.NormalVariance(170, 10));

  WriteLn;
  WriteLn('  Standard Normal (Mu=0, Sigma=1) key values:');
  Show('  P(Z <= 1.645)  [90% one-tail]',
    TProbabilityKit.NormalCDF(1.645, 0, 1));
  Show('  P(Z <= 1.960)  [95% one-tail]',
    TProbabilityKit.NormalCDF(1.960, 0, 1));
  Show('  P(Z <= 2.576)  [99% one-tail]',
    TProbabilityKit.NormalCDF(2.576, 0, 1));
end;

{ ============================================================
  SECTION 2 — Exponential Distribution
  Models the WAITING TIME between random events.
  E.g. time between customer arrivals, radioactive decay.
============================================================ }
procedure DemoExponential;
begin
  WriteLn;
  WriteLn('=== EXPONENTIAL DISTRIBUTION ===');
  WriteLn('Scenario: a call centre receives 3 calls per minute on average.');
  WriteLn('Lambda = 3 (rate), so the average gap = 1/3 minute ≈ 20 seconds.');
  PrintSeparator;

  Show('PDF at t=0.5 min',
    TProbabilityKit.ExponentialPDF(0.5, 3));

  Show('CDF at t=0.5 — P(wait <= 0.5 min)',
    TProbabilityKit.ExponentialCDF(0.5, 3));

  Show('Survival at t=1 — P(wait > 1 min)',
    TProbabilityKit.ExponentialSurvival(1, 3));

  Show('Mean waiting time (minutes)',
    TProbabilityKit.ExponentialMean(3));

  Show('Variance',
    TProbabilityKit.ExponentialVariance(3));
end;

{ ============================================================
  SECTION 3 — Student's t Distribution
  Like the Normal but with heavier tails. Use it when your
  sample is small (n < 30) and you do not know the true
  population variance.
============================================================ }
procedure DemoStudentT;
var
  T_stat: Double;
  P_two_tail: Double;
begin
  WriteLn;
  WriteLn('=== STUDENT''S T DISTRIBUTION ===');
  WriteLn('Scenario: paired t-test on 11 subjects → DF = 10, t = 2.228');
  WriteLn('Is this significant at 5% (two-tailed)?');
  PrintSeparator;

  T_stat     := 2.228;
  P_two_tail := TProbabilityKit.StudentTTwoTail(T_stat, 10);

  Show('t-statistic',                    T_stat);
  Show('Two-tailed p-value',             P_two_tail);
  Show('CDF at t=2.228 (one-tail)',      TProbabilityKit.StudentTCDF(T_stat, 10));
  Show('Survival at t=2.228',           TProbabilityKit.StudentTSurvival(T_stat, 10));
  Show('Mean (= 0 for all DF > 1)',     TProbabilityKit.StudentTMean(10));
  Show('Variance (DF=10)',              TProbabilityKit.StudentTVariance(10));

  WriteLn;
  if P_two_tail < 0.05 then
    WriteLn('  → Significant at 5%! (p < 0.05)')
  else
    WriteLn('  → Not significant at 5%.');
end;

{ ============================================================
  SECTION 4 — Chi-Squared Distribution
  Used in goodness-of-fit tests and tests of independence.
  The p-value IS the Survival function.
============================================================ }
procedure DemoChiSquared;
var
  Chi_stat: Double;
  P_value: Double;
begin
  WriteLn;
  WriteLn('=== CHI-SQUARED DISTRIBUTION ===');
  WriteLn('Scenario: χ² = 5.99 with DF = 2 (e.g. a 2-df contingency table).');
  PrintSeparator;

  Chi_stat := 5.991;  { ≈ 95th percentile of χ²(2) }
  P_value  := TProbabilityKit.ChiSquaredSurvival(Chi_stat, 2);

  Show('χ² statistic',     Chi_stat);
  Show('p-value (Survival)', P_value);
  Show('CDF',               TProbabilityKit.ChiSquaredCDF(Chi_stat, 2));
  Show('Mean (= DF)',        TProbabilityKit.ChiSquaredMean(2));
  Show('Variance (= 2*DF)', TProbabilityKit.ChiSquaredVariance(2));

  WriteLn;
  if P_value < 0.05 then
    WriteLn('  → Reject H0 at 5% significance.')
  else
    WriteLn('  → Cannot reject H0.');
end;

{ ============================================================
  SECTION 5 — Weibull Distribution
  The standard model for component lifetimes and reliability.
  Shape K controls whether the failure rate increases or
  decreases over time.
============================================================ }
procedure DemoWeibull;
begin
  WriteLn;
  WriteLn('=== WEIBULL DISTRIBUTION ===');
  WriteLn('Scenario: a motor''s lifetime ~ Weibull(K=2, Lambda=5000 hours).');
  WriteLn('K=2 means the failure rate INCREASES with age (wear-out).');
  PrintSeparator;

  Show('PDF at 3000 h',
    TProbabilityKit.WeibullPDF(3000, 2, 5000));

  Show('CDF at 3000 h — P(failed by 3000 h)',
    TProbabilityKit.WeibullCDF(3000, 2, 5000));

  Show('Survival at 3000 h — P(still running)',
    TProbabilityKit.WeibullSurvival(3000, 2, 5000));

  Show('Mean lifetime (hours)',
    TProbabilityKit.WeibullMean(2, 5000));

  Show('Variance',
    TProbabilityKit.WeibullVariance(2, 5000));
end;

{ ============================================================
  SECTION 6 — Binomial Distribution (DISCRETE)
  Counts successes in N independent yes/no trials.
============================================================ }
procedure DemoBinomial;
begin
  WriteLn;
  WriteLn('=== BINOMIAL DISTRIBUTION ===');
  WriteLn('Scenario: 20 items, each has a 5% chance of being defective.');
  WriteLn('How many defects will we see?');
  PrintSeparator;

  Show('P(exactly 0 defects)',
    TProbabilityKit.BinomialPMF(0, 20, 0.05));

  Show('P(exactly 1 defect)',
    TProbabilityKit.BinomialPMF(1, 20, 0.05));

  Show('P(at most 2 defects) = CDF(2)',
    TProbabilityKit.BinomialCDF(2, 20, 0.05));

  Show('P(more than 2 defects) = Survival(2)',
    TProbabilityKit.BinomialSurvival(2, 20, 0.05));

  Show('Expected number of defects (Mean)',
    TProbabilityKit.BinomialMean(20, 0.05));

  Show('Variance',
    TProbabilityKit.BinomialVariance(20, 0.05));
end;

{ ============================================================
  SECTION 7 — Poisson Distribution (DISCRETE)
  Counts events in a fixed time window.
============================================================ }
procedure DemoPoisson;
begin
  WriteLn;
  WriteLn('=== POISSON DISTRIBUTION ===');
  WriteLn('Scenario: a website receives an average of 4.5 visits/minute.');
  WriteLn('Lambda = 4.5');
  PrintSeparator;

  Show('P(exactly 3 visits in 1 min)',
    TProbabilityKit.PoissonPMF(3, 4.5));

  Show('P(at most 5 visits)',
    TProbabilityKit.PoissonCDF(5, 4.5));

  Show('P(more than 7 visits)',
    TProbabilityKit.PoissonSurvival(7, 4.5));

  Show('Mean (= Lambda)',
    TProbabilityKit.PoissonMean(4.5));

  Show('Variance (= Lambda)',
    TProbabilityKit.PoissonVariance(4.5));
end;

{ ============================================================
  SECTION 8 — Hypergeometric (DISCRETE)
  Sampling WITHOUT replacement — use when the population
  is small and you are drawing a significant fraction of it.
============================================================ }
procedure DemoHypergeometric;
begin
  WriteLn;
  WriteLn('=== HYPERGEOMETRIC DISTRIBUTION ===');
  WriteLn('Scenario: a box has 50 items, 10 are defective.');
  WriteLn('You draw 8 at random WITHOUT replacement.');
  WriteLn('N=50, K=10, n=8');
  PrintSeparator;

  Show('P(exactly 2 defective in sample)',
    TProbabilityKit.HypergeometricPMF(2, 50, 10, 8));

  Show('P(at most 3 defective)',
    TProbabilityKit.HypergeometricCDF(3, 50, 10, 8));

  Show('Expected defectives in sample (Mean)',
    TProbabilityKit.HypergeometricMean(50, 10, 8));

  Show('Variance',
    TProbabilityKit.HypergeometricVariance(50, 10, 8));
end;

{ ============================================================
  SECTION 9 — Using ADecimals for rounded output
  All functions accept an optional last parameter ADecimals.
  Pass -1 (default) for full precision, or an integer for
  rounding.
============================================================ }
procedure DemoRounding;
begin
  WriteLn;
  WriteLn('=== OPTIONAL ROUNDING ===');
  PrintSeparator;

  WriteLn(Format('  Full precision : %.10f',
    [TProbabilityKit.NormalCDF(1.96, 0, 1)]));

  WriteLn(Format('  4 decimal places: %.4f',
    [TProbabilityKit.NormalCDF(1.96, 0, 1, 4)]));

  WriteLn(Format('  2 decimal places: %.2f',
    [TProbabilityKit.NormalCDF(1.96, 0, 1, 2)]));
end;

{ ============================================================
  SECTION 10 — Error handling
============================================================ }
procedure DemoErrors;
begin
  WriteLn;
  WriteLn('=== ERROR HANDLING ===');
  PrintSeparator;
  WriteLn('  Calling NormalCDF with Sigma = 0 (invalid)...');
  try
    TProbabilityKit.NormalCDF(1.96, 0, 0);
  except
    on E: EProbabilityError do
      WriteLn('  Caught EProbabilityError: ', E.Message);
  end;

  WriteLn('  Calling BinomialPMF with P = 1.5 (invalid)...');
  try
    TProbabilityKit.BinomialPMF(3, 10, 1.5);
  except
    on E: EProbabilityError do
      WriteLn('  Caught EProbabilityError: ', E.Message);
  end;
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp  —  ProbabilityLib Example');
  WriteLn('======================================');

  DemoNormal;
  DemoExponential;
  DemoStudentT;
  DemoChiSquared;
  DemoWeibull;
  DemoBinomial;
  DemoPoisson;
  DemoHypergeometric;
  DemoRounding;
  DemoErrors;

  WriteLn;
  WriteLn('Done. All calls completed successfully.');
  WriteLn;
end.
