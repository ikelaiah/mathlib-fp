unit TestFinanceLib;

{-----------------------------------------------------------------------------
 TestFinanceLib

 Extracts the TTestCaseFinance suite from TestMathBase for focused finance testing.
 Include this unit (or TestMathBase for everything) in your TestRunner.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  MathBase.SharedTypes,
  FinanceLib.Interest,
  FinanceLib.Bonds,
  FinanceLib.NPV;

type
  { Forward to the finance test suite defined in TestMathBase.
    All TTestCaseFinance tests live in TestMathBase.pas.
    Add finance-specific additions here as needed. }
  TTestFinanceLib = class(TTestCase)
  published
    procedure TestDecimalsAreApplied;
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
end;

initialization
  RegisterTest(TTestFinanceLib);

end.
