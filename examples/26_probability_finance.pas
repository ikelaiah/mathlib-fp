program probability_finance;

{ ----------------------------------------------------------------------------
  mathlib-fp 1.9.8 representative workflow 3 — reproducible probability and
  finance analysis

  A reproducible data-analysis flow: seed a local random generator, simulate a
  small market/asset return sample, estimate its distribution and run a
  one-sample test, fit a CAPM-style linear model, evaluate a project with NPV
  and IRR, exercise an invalid-probability diagnostic, and export a
  deterministic interpretation.

  Domains exercised: MathBase (shared arrays, local RNG, binary interchange),
  ProbabilityLib (distributions), StatsLib (inference and regression),
  FinanceLib (time value of money and project appraisal).

  Run from the repository root (or the extracted release archive root). The
  export is written to workflow-exports/finance_report.txt relative to the
  working directory.

  Compile:  fpc -Fusrc -FUlib examples/26_probability_finance.pas
  Run:      ./26_probability_finance
--------------------------------------------------------------------------- }

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.SharedTypes, MathBase.Random, MathBase.Interchange,
  MathBase.Iteration,
  ProbabilityLib.Distributions, StatsLib.Inference, FinanceLib.Interest,
  AlgebraLib.DenseMatrices;

const
  SampleCount = 64;
  ExportPath = 'workflow-exports/finance_report.txt';

function F6(const Value: Double): string;
begin
  Str(Value:0:6, Result);
end;

procedure SaveText(const FileName, Content: string);
var
  Output: Text;
begin
  ForceDirectories(ExtractFilePath(FileName));
  Assign(Output, FileName);
  Rewrite(Output);
  Write(Output, Content);
  Close(Output);
end;

var
  Rng: TLocalRandom;
  Market, Asset, CashFlows, ExportVector: TDoubleArray;
  MarketModel, NoiseModel: TNormalDistribution;
  Estimate: TDistributionEstimate;
  TestResult: TInferenceTestResult;
  Design: IDenseDoubleMatrix;
  Regression: TRegressionDiagnostics;
  NPV, IRR, PresentVal, FutureVal: Double;
  Stream: TMemoryStream;
  Report, Decision, Rejected: string;
  I: Integer;
begin
  { 1. Seeded generation ----------------------------------------------------
    A caller-owned local RNG keeps the whole simulation reproducible without
    touching the RTL global generator. }
  Rng := TLocalRandom.Seeded(26081);
  MarketModel := TNormalDistribution.Create(0.0008, 0.02);
  NoiseModel := TNormalDistribution.Create(0.0, 0.01);
  SetLength(Market, SampleCount);
  SetLength(Asset, SampleCount);
  for I := 0 to SampleCount - 1 do
  begin
    Market[I] := MarketModel.Sample(Rng);
    Asset[I] := 0.0005 + 1.3 * Market[I] + NoiseModel.Sample(Rng);
  end;

  { 2. Probability and statistics ------------------------------------------
    Estimate the asset-return distribution and test the mean. }
  Estimate := TInferenceKit.EstimateNormal(Asset);
  Writeln('estimate mean: ', F6(Estimate.Parameters[0]));
  Writeln('estimate stddev: ', F6(Estimate.Parameters[1]));
  Writeln('estimate status: ', IterationStatusName(Estimate.Status));

  TestResult := TInferenceKit.OneSampleT(Asset, 0.0, 0.95);
  Writeln('t statistic: ', F6(TestResult.Statistic));
  Writeln('p value: ', F6(TestResult.PValue));

  { 3. Finance / data analysis ---------------------------------------------
    A CAPM-style regression of asset returns on market returns. }
  Design := TDenseDoubleMatrix.Zeros(SampleCount, 2);
  for I := 0 to SampleCount - 1 do
  begin
    Design[I, 0] := 1.0;
    Design[I, 1] := Market[I];
  end;
  Regression := TInferenceKit.FitOLS(Design, Asset);
  Writeln('regression intercept: ', F6(Regression.Coefficients[0]));
  Writeln('regression beta: ', F6(Regression.Coefficients[1]));
  Writeln('regression R^2: ', F6(Regression.RSquared));

  { 4. Finance --------------------------------------------------------------
    Time value of money and project appraisal. }
  PresentVal := TFinanceKit.PresentValue(100000.0, 0.07, 5);
  FutureVal := TFinanceKit.FutureValue(5000.0, 0.06, 10);
  CashFlows := TDoubleArray.Create(20000.0, 25000.0, 30000.0, 35000.0, 40000.0);
  NPV := TFinanceKit.NetPresentValue(100000.0, CashFlows, 0.10);
  IRR := TFinanceKit.InternalRateOfReturn(100000.0, CashFlows);
  if NPV > 0.0 then
    Decision := 'accept'
  else
    Decision := 'reject';
  Writeln('net present value: ', F6(NPV));
  Writeln('internal rate of return: ', F6(IRR));
  Writeln('present value of future 100000: ', F6(PresentVal));
  Writeln('future value of 5000: ', F6(FutureVal));
  Writeln('decision: ', Decision);

  { 5. Diagnostics ----------------------------------------------------------
    An invalid standard deviation must be rejected by the distribution. }
  Rejected := '';
  try
    TProbabilityKit.NormalCDF(1.96, 0.0, 0.0);
  except
    on E: Exception do
      Rejected := E.ClassName;
  end;
  Writeln('diagnostic: invalid sigma rejected by ', Rejected);

  { 6. Persistence / export -------------------------------------------------
    Round-trip the cash flows through versioned binary interchange and write a
    deterministic interpretation. }
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, CashFlows);
    Stream.Position := 0;
    ExportVector := LoadDoubleVectorBinary(Stream, 1000);
  finally
    Stream.Free;
  end;

  Report :=
    'mathlib-fp finance report' + sLineBreak +
    'estimate mean: ' + F6(Estimate.Parameters[0]) + sLineBreak +
    'estimate stddev: ' + F6(Estimate.Parameters[1]) + sLineBreak +
    'regression beta: ' + F6(Regression.Coefficients[1]) + sLineBreak +
    'net present value: ' + F6(NPV) + sLineBreak +
    'internal rate of return: ' + F6(IRR) + sLineBreak +
    'present value of future 100000: ' + F6(PresentVal) + sLineBreak +
    'future value of 5000: ' + F6(FutureVal) + sLineBreak +
    'decision: ' + Decision + sLineBreak +
    'round-trip cash flows: ' + IntToStr(Length(ExportVector)) + sLineBreak;
  SaveText(ExportPath, Report);
  Writeln('exported: ', ExportPath, ' (', Length(Report), ' bytes)');

  Writeln('probability finance workflow: success');
end.
