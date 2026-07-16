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
