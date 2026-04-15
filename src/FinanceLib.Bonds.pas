unit FinanceLib.Bonds;

{-----------------------------------------------------------------------------
 FinanceLib.Bonds

 Re-exports bond-related functionality from FinanceLib.Interest.

 Bond methods on TFinanceKit:
   BondPrice              — fair price from coupon rate + YTM
   BondYieldToMaturity    — YTM from market price
   ModifiedDuration       — price sensitivity to yield change
   BondDuration           — Macaulay duration
   BondConvexity          — second-order price sensitivity
   AccruedInterest        — accrued coupon since last payment date
   DirtyPrice             — clean price + accrued interest
   BondSpreadToBenchmark  — yield spread over a benchmark rate
   AmortizationSchedule   — loan/bond amortisation table
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  FinanceLib.Interest;

{ Re-export the main class and exception under Bond-oriented aliases. }
type
  TBondKit    = TFinanceKit;
  EBondError  = EFinanceError;

implementation

end.
