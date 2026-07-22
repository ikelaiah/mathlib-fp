program TestRunner;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes
  , consoletestrunner
  , TestMathBase
  , TestComplexLib
  , TestAlgebraLib
  , TestFinanceLib
  , TestFinanceAliases
  , TestStatsLib
  , TestEngineeringLib
  , TestEngineeringLib_FluidDynamics
  , TestEngineeringLib_Signal
  , TestEngineeringLib_Thermodynamics
  , TestEngineeringLib_UnitConversion
  , TestEngineeringLib_Aliases
  , TestNumericsLib
  , TestProbabilityLib
  , TestCombinatoricsLib
  , TestOptimizationLib
  , TestTimeSeriesLib
  , TestMLLib
  , TestGeometryLib
  , TestPublicAPI;

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
