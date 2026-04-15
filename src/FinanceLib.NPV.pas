unit FinanceLib.NPV;

{-----------------------------------------------------------------------------
 FinanceLib.NPV

 Re-exports NPV / capital-budgeting functionality from FinanceLib.Interest.

 Relevant methods on TFinanceKit:
   NetPresentValue        — NPV of a cash-flow series
   InternalRateOfReturn   — IRR (secant method)
   ModifiedIRR            — MIRR
   XNPV                   — NPV with irregular date-based cash flows
   XIRR                   — IRR with irregular date-based cash flows
   Payback                — simple payback period
   ModifiedPayback        — discounted payback period
   NPVProfile             — NPV at a range of discount rates
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
