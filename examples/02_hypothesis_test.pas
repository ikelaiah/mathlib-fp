program HypothesisTest;

{-----------------------------------------------------------------------------
  02_hypothesis_test.pas

  Compares two small groups with parametric and non-parametric tests. It shows
  how to read a p-value alongside an effect size; the tests are alternatives
  chosen from study design and assumptions, not a checklist to run blindly.

  Build (FPC command line):
    mkdir lib
    fpc -Fu../src -FUlib 02_hypothesis_test.pas

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  MathBase.SharedTypes,
  StatsLib.Stats;

// Helper for this example's preselected alpha of 0.05. A p-value is evidence
// against a null hypothesis, not the probability that the null is true.
procedure PrintDecision(const TestName: string; const Stat, PValue: Double);
begin
  Write(Format('  %-28s stat = %7.4f   p = %.4f   ', [TestName, Stat, PValue]));
  if PValue < 0.05 then
    WriteLn('=> significant (p < 0.05)')
  else
    WriteLn('=> not significant (p >= 0.05)');
end;

var
  GroupA, GroupB: TDoubleArray;
  TStat, TPValue: Double;
  UStat, UPValue: Double;
  WStat: Double;
  KSStat, KSPValue: Double;
  ShapW, ShapP: Double;
  D, G: Double;

begin
  // ── Scenario ────────────────────────────────────────────────────────────
  // Two groups of exam scores. We want to know if group B performed
  // significantly differently from group A.

  GroupA := TDoubleArray.Create(72, 68, 75, 70, 65, 74, 71, 69, 73, 67);
  GroupB := TDoubleArray.Create(80, 78, 85, 76, 82, 79, 84, 77, 83, 81);

  WriteLn('Group A scores: 72 68 75 70 65 74 71 69 73 67');
  WriteLn('Group B scores: 80 78 85 76 82 79 84 77 83 81');
  WriteLn;

  // ── 1. Normality checks ─────────────────────────────────────────────────
  // These checks can inform method choice, but a non-significant result does
  // not prove normality—especially with a sample this small.
  WriteLn('=== Normality Tests ===');
  ShapW := TStatsKit.ShapiroWilkTest(GroupA, ShapP);
  WriteLn(Format('  Group A  Shapiro-Wilk W = %.4f   p = %.4f', [ShapW, ShapP]));
  ShapW := TStatsKit.ShapiroWilkTest(GroupB, ShapP);
  WriteLn(Format('  Group B  Shapiro-Wilk W = %.4f   p = %.4f', [ShapW, ShapP]));
  WriteLn('  (p > 0.05 suggests data is consistent with normality)');
  WriteLn;

  // ── 2. Two-sample t-test (parametric) ──────────────────────────────────
  WriteLn('=== Two-Sample t-Test ===');
  TStat := TStatsKit.TTest(GroupA, GroupB, TPValue);
  PrintDecision('Independent t-test', TStat, TPValue);
  WriteLn;

  // ── 3. Mann-Whitney U (non-parametric alternative to t-test) ───────────
  WriteLn('=== Mann-Whitney U Test ===');
  UStat := TStatsKit.MannWhitneyU(GroupA, GroupB, UPValue);
  PrintDecision('Mann-Whitney U', UStat, UPValue);
  WriteLn;

  // ── 4. Kolmogorov-Smirnov normality test on Group A ────────────────────
  WriteLn('=== Kolmogorov-Smirnov Test (Group A normality) ===');
  KSStat := TStatsKit.KolmogorovSmirnovTest(GroupA, KSPValue);
  PrintDecision('KS normality', KSStat, KSPValue);
  WriteLn;

  // ── 5. Wilcoxon Signed-Rank (for paired / one-sample problems) ─────────
  // Here we test whether the difference between paired scores is non-zero.
  WriteLn('=== Wilcoxon Signed-Rank Test (paired) ===');
  WStat := TStatsKit.WilcoxonSignedRank(GroupA, GroupB);
  WriteLn(Format('  %-28s W = %7.4f', ['Wilcoxon Signed-Rank', WStat]));
  WriteLn;

  // ── 6. Effect size ──────────────────────────────────────────────────────
  WriteLn('=== Effect Size ===');
  D := TStatsKit.CohensD(GroupA, GroupB);
  G := TStatsKit.HedgesG(GroupA, GroupB);
  WriteLn(Format('  Cohen''s d  = %.4f', [D]));
  WriteLn(Format('  Hedges'' g  = %.4f', [G]));
  WriteLn('  Rough benchmarks for |d|: 0.2 small, 0.5 medium, 0.8 large');
  WriteLn('  Effect size describes magnitude; p-value alone does not.');
  WriteLn;

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
