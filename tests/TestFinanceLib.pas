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
  end;

implementation

end.
