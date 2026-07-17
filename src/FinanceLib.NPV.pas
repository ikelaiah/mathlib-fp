unit FinanceLib.NPV;

{-----------------------------------------------------------------------------
 FinanceLib.NPV

 Focused entry point for NPV and IRR functionality implemented by
 FinanceLib.Interest. This unit intentionally contains aliases rather than a
 second copy of the financial formulas.

 Intended methods on TNPVKit:
   NetPresentValue        — NPV of a cash-flow series
   InternalRateOfReturn   — IRR (bracketed bisection)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  MathBase.SharedTypes,
  FinanceLib.Interest;

{ TNPVKit is a type alias, so it has the same methods as TFinanceKit.
  TNPVCashFlows makes the required array type directly nameable by callers
  that import only this focused unit. }
type
  TNPVKit       = TFinanceKit;
  ENPVError     = EFinanceError;
  TNPVCashFlows = TDoubleArray;

implementation

end.
