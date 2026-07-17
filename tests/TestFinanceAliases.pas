unit TestFinanceAliases;

{-----------------------------------------------------------------------------
 TestFinanceAliases

 Verifies that the focused FinanceLib.Bonds and FinanceLib.NPV entry units
 expose the documented aliases without requiring callers to import the core
 FinanceLib.Interest or MathBase.SharedTypes units directly.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  FinanceLib.Bonds,
  FinanceLib.NPV;

type
  TTestFinanceAliases = class(TTestCase)
  published
    procedure TestBondEntryAliases;
    procedure TestNPVEntryAliases;
  end;

implementation

procedure TTestFinanceAliases.TestBondEntryAliases;
var
  Payment: TBondPayment;
  Schedule: TBondSchedule;
begin
  AssertEquals('bond price through focused entry unit', 1119.7278,
    TBondKit.BondPrice(1000, 0.06, 0.045, 2, 10, 4), 0.0);

  Schedule := TBondKit.AmortizationSchedule(1000, 0.01, 3, 2);
  AssertEquals('bond schedule length', 3, Length(Schedule));
  Payment := Schedule[0];
  AssertEquals('named payment alias', 340.02, Payment.Payment, 0.0);

  try
    TBondKit.BondPrice(1000, 0.05, 0.04, 0, 10);
    Fail('invalid payment frequency must raise EBondError');
  except
    on E: EBondError do { expected };
  end;
end;

procedure TTestFinanceAliases.TestNPVEntryAliases;
var
  CashFlows: TNPVCashFlows;
begin
  CashFlows := TNPVCashFlows.Create(120);
  AssertEquals('IRR through focused entry unit', 0.2,
    TNPVKit.InternalRateOfReturn(100, CashFlows, 4), 0.0);

  CashFlows := nil;
  try
    TNPVKit.InternalRateOfReturn(100, CashFlows);
    Fail('empty cash flows must raise ENPVError');
  except
    on E: ENPVError do { expected };
  end;
end;

initialization
  RegisterTest(TTestFinanceAliases);

end.
