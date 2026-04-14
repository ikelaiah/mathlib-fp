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
    { All stats tests are in TTestCaseStats inside TestMathBase.
      Add this unit to pull in StatsLib.Stats-specific tests here,
      or simply use TestMathBase which includes TTestCaseStats directly. }
  end;

implementation

end.
