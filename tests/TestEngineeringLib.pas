unit TestEngineeringLib;

{-----------------------------------------------------------------------------
 TestEngineeringLib

 Umbrella test unit — registers all EngineeringLib sub-test suites.
 Include this unit in your TestRunner program to run all engineering tests.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  TestEngineeringLib_FluidDynamics,
  TestEngineeringLib_Thermodynamics,
  TestEngineeringLib_UnitConversion,
  TestEngineeringLib_Signal,
  TestEngineeringLib_Aliases;

implementation

end.
