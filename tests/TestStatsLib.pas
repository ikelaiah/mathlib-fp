unit TestStatsLib;

{-----------------------------------------------------------------------------
 TestStatsLib

 Extracts the TTestCaseStats suite from TestMathBase for focused stats testing.
 Include this unit (or TestMathBase for everything) in your TestRunner.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  MathBase.SharedTypes,
  MathBase.Precision,
  StatsLib.Stats;

type
  { Forward to the stats test suite defined in TestMathBase }
  TTestStatsLib = class(TTestCase)
  published
    procedure TestSeededBootstrapIsDeterministic;
    procedure TestSeededBootstrapDoesNotChangeGlobalRandomState;
    procedure TestBootstrapRejectsInvalidInputs;
    procedure TestMannWhitneyExactSeparatedSamples;
    procedure TestShapiroWilkReferenceProperties;
    procedure TestKolmogorovSmirnovReturnsPValue;
    procedure TestSortLargeArrayProperties;
    procedure TestCohensDUsesPooledSampleVariance;
  end;

implementation

procedure TTestStatsLib.TestSeededBootstrapIsDeterministic;
var
  Data, A, B: TDoubleArray;
  I: Integer;
  CIA, CIB: TDoublePair;
begin
  Data := TDoubleArray.Create(1, 2, 4, 8, 16);
  A := TStatsKit.BootstrapMean(Data, 50, 123456);
  B := TStatsKit.BootstrapMean(Data, 50, 123456);
  AssertEquals('bootstrap result length', Length(A), Length(B));
  for I := 0 to High(A) do
    AssertEquals('same seed must reproduce each mean', A[I], B[I], 0.0);

  CIA := TStatsKit.BootstrapConfidenceInterval(Data, 0.05, 100, 98765);
  CIB := TStatsKit.BootstrapConfidenceInterval(Data, 0.05, 100, 98765);
  AssertEquals('seeded CI lower', CIA.Lower, CIB.Lower, 0.0);
  AssertEquals('seeded CI upper', CIA.Upper, CIB.Upper, 0.0);
end;

procedure TTestStatsLib.TestMannWhitneyExactSeparatedSamples;
var
  X, Y: TDoubleArray;
  U, P: Double;
begin
  X := TDoubleArray.Create(1, 2, 3, 4, 5);
  Y := TDoubleArray.Create(6, 7, 8, 9, 10);
  U := TStatsKit.MannWhitneyU(X, Y, P);
  AssertEquals('fully separated U', 0.0, U, 0.0);
  AssertEquals('exact two-sided p', 0.00793650793650794, P, 1E-14);
end;

procedure TTestStatsLib.TestShapiroWilkReferenceProperties;
var
  NormalScores, Skewed: TDoubleArray;
  WNormal, WSkewed, PNormal, PSkewed: Double;
  I: Integer;
begin
  NormalScores := TDoubleArray.Create(-1.2815515655, -0.8416212336,
    -0.5244005127, -0.2533471031, 0.0, 0.2533471031,
    0.5244005127, 0.8416212336, 1.2815515655);
  SetLength(Skewed, 20);
  for I := 0 to High(Skewed) do Skewed[I] := Exp(I / 3.0);
  WNormal := TStatsKit.ShapiroWilkTest(NormalScores, PNormal);
  WSkewed := TStatsKit.ShapiroWilkTest(Skewed, PSkewed);
  AssertTrue('normal-score W is near one', WNormal > 0.98);
  AssertTrue('normal-score p is bounded', (PNormal >= 0) and (PNormal <= 1));
  AssertTrue('skewed p is bounded', (PSkewed >= 0) and (PSkewed <= 1));
  AssertTrue('skew is detected', (WSkewed < WNormal) and (PSkewed < 0.01));
end;

procedure TTestStatsLib.TestKolmogorovSmirnovReturnsPValue;
var
  Data: TDoubleArray;
  D, P: Double;
begin
  Data := TDoubleArray.Create(-1.2815515655, -0.8416212336,
    -0.5244005127, -0.2533471031, 0.0, 0.2533471031,
    0.5244005127, 0.8416212336, 1.2815515655);
  D := TStatsKit.KolmogorovSmirnovTest(Data, P);
  { Reference recomputed with a full-precision standard normal CDF. }
  AssertEquals('reference D', 0.0845331803957453, D, 2E-14);
  AssertTrue('p is probability', (P >= 0.0) and (P <= 1.0));
  AssertTrue('normal scores are not rejected', TStatsKit.IsNormal(Data, 0.05));
end;

procedure TTestStatsLib.TestSortLargeArrayProperties;
var
  Data: TDoubleArray;
  I: Integer;
  SumBefore, SumAfter: Double;
begin
  SetLength(Data, 20000);
  SumBefore := 0.0;
  for I := 0 to High(Data) do
  begin
    Data[I] := ((High(Data) - I) mod 997) - 498;
    SumBefore := SumBefore + Data[I];
  end;
  TStatsKit.Sort(Data);
  SumAfter := 0.0;
  for I := 0 to High(Data) do
  begin
    if I > 0 then AssertTrue('sort order', Data[I - 1] <= Data[I]);
    SumAfter := SumAfter + Data[I];
  end;
  AssertEquals('sort preserves values by checksum', SumBefore, SumAfter, 0.0);
end;

procedure TTestStatsLib.TestCohensDUsesPooledSampleVariance;
var
  X, Y: TDoubleArray;
begin
  X := TDoubleArray.Create(1, 2, 3);
  Y := TDoubleArray.Create(2, 3, 4);
  AssertEquals('pooled sample SD is one', -1.0, TStatsKit.CohensD(X, Y), 1E-14);
end;

procedure TTestStatsLib.TestSeededBootstrapDoesNotChangeGlobalRandomState;
var
  Data: TDoubleArray;
  ExpectedNext, ActualNext: Double;
begin
  Data := TDoubleArray.Create(1, 2, 3);
  RandSeed := 424242;
  ExpectedNext := Random;
  RandSeed := 424242;
  TStatsKit.BootstrapMean(Data, 10, 99);
  ActualNext := Random;
  AssertEquals('seeded bootstrap must not mutate RandSeed',
    ExpectedNext, ActualNext, 0.0);
end;

procedure TTestStatsLib.TestBootstrapRejectsInvalidInputs;
var
  Data: TDoubleArray;
begin
  Data := nil;
  try
    TStatsKit.BootstrapMean(Data, 10, 1);
    Fail('empty bootstrap data must raise EStatsError');
  except
    on E: EStatsError do { expected };
  end;

  Data := TDoubleArray.Create(1, 2, 3);
  try
    TStatsKit.BootstrapConfidenceInterval(Data, 1.0, 10, 1);
    Fail('invalid alpha must raise EStatsError');
  except
    on E: EStatsError do { expected };
  end;
end;

initialization
  RegisterTest(TTestStatsLib);

end.
