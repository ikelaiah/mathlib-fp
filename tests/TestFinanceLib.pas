unit TestFinanceLib;

{-----------------------------------------------------------------------------
 TestFinanceLib

 Adds FinanceLib regression and validation tests beyond the calculation cases
 in TestMathBase.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  MathBase.SharedTypes,
  FinanceLib.Interest;

type
  { Regression and contract coverage for FinanceLib.Interest. }
  TTestFinanceLib = class(TTestCase)
  published
    procedure TestDecimalsAreApplied;
    procedure TestNPVRoundsFinalResult;
    procedure TestIRRDocumentedCashFlows;
    procedure TestIRRPositiveAndNegativeRates;
    procedure TestIRRRejectsInvalidCashFlows;
    procedure TestAmortizationHonoursDecimals;
    procedure TestPeriodValidation;
    procedure TestRatioDenominatorsAreValidated;
  end;

implementation

procedure TTestFinanceLib.TestDecimalsAreApplied;
begin
  AssertEquals('ROI rounded to two decimals', 2.33,
    TFinanceKit.ReturnOnInvestment(10, 3, 2), 0.0);
  AssertEquals('ROE rounded to three decimals', 0.333,
    TFinanceKit.ReturnOnEquity(1, 3, 3), 0.0);
  AssertEquals('straight-line depreciation rounded', 2.33,
    TFinanceKit.StraightLineDepreciation(10, 3, 3, 2), 0.0);
  AssertEquals('CAPM rounded', 0.116,
    TFinanceKit.CAPM(0.03, 1.2345, 0.10, 3), 0.0);
  AssertEquals('zero-rate present value rounded', 1.24,
    TFinanceKit.PresentValue(1.236, 0, 1, 2), 0.0);
end;

procedure TTestFinanceLib.TestNPVRoundsFinalResult;
var
  CashFlows: TDoubleArray;
begin
  CashFlows := TDoubleArray.Create(0.6, 0.6);
  AssertEquals('NPV rounds after summing discounted cash flows', 1.0,
    TFinanceKit.NetPresentValue(0, CashFlows, 0, 0), 0.0);
end;

procedure TTestFinanceLib.TestIRRDocumentedCashFlows;
var
  CashFlows: TDoubleArray;
begin
  CashFlows := TDoubleArray.Create(20000, 25000, 30000, 35000, 40000);
  AssertEquals('documented NPV', 10124.7431,
    TFinanceKit.NetPresentValue(100000, CashFlows, 0.10, 4), 0.0);
  AssertEquals('documented IRR', 0.1345,
    TFinanceKit.InternalRateOfReturn(100000, CashFlows, 4), 0.0);
end;

procedure TTestFinanceLib.TestIRRPositiveAndNegativeRates;
var
  CashFlows: TDoubleArray;
begin
  CashFlows := TDoubleArray.Create(120);
  AssertEquals('20 percent IRR', 0.2,
    TFinanceKit.InternalRateOfReturn(100, CashFlows, 4), 0.0);

  CashFlows := TDoubleArray.Create(90);
  AssertEquals('negative 10 percent IRR', -0.1,
    TFinanceKit.InternalRateOfReturn(100, CashFlows, 4), 0.0);
end;

procedure TTestFinanceLib.TestIRRRejectsInvalidCashFlows;
var
  CashFlows: TDoubleArray;
begin
  CashFlows := nil;
  try
    TFinanceKit.InternalRateOfReturn(100, CashFlows);
    Fail('empty cash flows must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;

  CashFlows := TDoubleArray.Create(120);
  try
    TFinanceKit.InternalRateOfReturn(0, CashFlows);
    Fail('non-positive initial investment must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;

  CashFlows := TDoubleArray.Create(-10, -20);
  try
    TFinanceKit.InternalRateOfReturn(100, CashFlows);
    Fail('cash flows without an inflow must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
end;

procedure TTestFinanceLib.TestAmortizationHonoursDecimals;
var
  Schedule: TFinanceKit.TAmortizationArray;
begin
  Schedule := TFinanceKit.AmortizationSchedule(1000, 0.01, 3, 2);
  AssertEquals('schedule length', 3, Length(Schedule));
  AssertEquals('payment uses requested decimals', 340.02,
    Schedule[0].Payment, 0.0);
  AssertEquals('interest uses requested decimals', 10.0,
    Schedule[0].Interest, 0.0);
  AssertEquals('principal uses requested decimals', 330.02,
    Schedule[0].Principal, 0.0);
end;

procedure TTestFinanceLib.TestPeriodValidation;
begin
  try
    TFinanceKit.FutureValue(100, 0.1, -1);
    Fail('negative future-value periods must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.CompoundInterest(100, 0.1, -1);
    Fail('negative compound-interest periods must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
end;

procedure TTestFinanceLib.TestRatioDenominatorsAreValidated;
begin
  try
    TFinanceKit.ReturnOnInvestment(1, 0);
    Fail('zero investment cost must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.ReturnOnEquity(1, 0);
    Fail('zero equity must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.StraightLineDepreciation(10, 1, 0);
    Fail('zero asset life must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.WorkingCapitalRatios(100, 100, 10, 10, 100);
    Fail('zero working capital must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.LeverageRatios(10, 100, 90, 5, 0);
    Fail('zero interest expense must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.RiskMetrics(0.1, 0.02, 0.08, 1, 0, 0.07, 0.05);
    Fail('zero portfolio standard deviation must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.RiskMetrics(0.1, 0.02, 0.08, 0, 0.15, 0.07, 0.05);
    Fail('zero beta must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.RiskMetrics(0.1, 0.02, 0.08, 1, 0.15, 0.07, 0);
    Fail('zero tracking error must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.OperatingLeverage(5000, 50, 30, 100000);
    Fail('zero EBIT must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
  try
    TFinanceKit.ProfitabilityRatios(100, 50, 10, 5, 20, 20);
    Fail('zero capital employed must raise EFinanceError');
  except
    on E: EFinanceError do { expected };
  end;
end;

initialization
  RegisterTest(TTestFinanceLib);

end.
