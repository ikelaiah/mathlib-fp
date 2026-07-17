unit FinanceLib.NPV;

{-----------------------------------------------------------------------------
 FinanceLib.NPV

 Re-exports NPV / capital-budgeting functionality from FinanceLib.Interest.

 Relevant methods on TFinanceKit:
   NetPresentValue        — NPV of a cash-flow series
   InternalRateOfReturn   — IRR (secant method)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  FinanceLib.Interest;

{ Re-export the main class and exception under NPV-oriented aliases. }
type
  TNPVKit    = TFinanceKit;
  ENPVError  = EFinanceError;

implementation

end.
