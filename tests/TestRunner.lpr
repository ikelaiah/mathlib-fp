program TestRunner;

{$mode objfpc}{$H+}{$J-}

uses
  Classes
  , consoletestrunner
  , TestMathBase
  , TestAlgebraLib
  , TestFinanceLib
  , TestStatsLib
  , TestEngineeringLib
  , TestEngineeringLib_FluidDynamics
  , TestEngineeringLib_Signal
  , TestEngineeringLib_Thermodynamics
  , TestEngineeringLib_UnitConversion
  , TestNumericsLib
  , TestProbabilityLib;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
  // override the protected methods of TTestRunner to customize its behavior
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'mathlib-fp Test Runner';
  Application.Run;
  Application.Free;
end.
