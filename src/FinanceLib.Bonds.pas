unit FinanceLib.Bonds;

{-----------------------------------------------------------------------------
 FinanceLib.Bonds

 Focused entry point for bond-related functionality implemented by
 FinanceLib.Interest. This unit intentionally contains aliases rather than a
 second copy of the financial formulas.

 Intended methods on TBondKit:
   BondPrice              — fair price from coupon rate + YTM
   BondYieldToMaturity    — YTM from market price
   ModifiedDuration       — price sensitivity to yield change
   AmortizationSchedule   — loan/bond amortisation table
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  FinanceLib.Interest;

{ TBondKit is a type alias, so it has the same methods as TFinanceKit. The
  TBondPayment and TBondSchedule aliases make the amortization result types
  directly nameable by callers that import only this focused unit. }
type
  TBondKit      = TFinanceKit;
  EBondError    = EFinanceError;
  TBondPayment  = TFinanceKit.TAmortizationPayment;
  TBondSchedule = TFinanceKit.TAmortizationArray;

implementation

end.
