program UnitConversion;

{-----------------------------------------------------------------------------
  05_unit_conversion.pas

  Demonstrates physical unit conversions using EngineeringLib.
  This is the gentlest entry point into EngineeringLib — no physics
  knowledge required. Each ConvertXxx call takes a value, a typed source-unit
  enum, and a typed destination-unit enum, which prevents mixing dimensions.

  Build (FPC command line):
    mkdir lib
    fpc -Fu../src -FUlib 05_unit_conversion.pas

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  EngineeringLib.UnitConversion;  // TUnitConversionKit + all unit enums

begin
  // The pattern is the same in every section:
  //   ConvertDimension(Value, FromUnit, ToUnit)
  // Unit enum names are listed in docs/EngineeringLib.md.
  WriteLn('=== Length ===');
  WriteLn(Format('  1 mile         = %.4f km',      [TUnitConversionKit.ConvertLength(1, luMile, luKilometer)]));
  WriteLn(Format('  100 m          = %.4f ft',       [TUnitConversionKit.ConvertLength(100, luMeter, luFoot)]));
  WriteLn(Format('  6 ft           = %.4f m',        [TUnitConversionKit.ConvertLength(6, luFoot, luMeter)]));
  WriteLn(Format('  1 nautical mi  = %.2f m',        [TUnitConversionKit.ConvertLength(1, luNauticalMile, luMeter)]));
  WriteLn;

  WriteLn('=== Mass ===');
  WriteLn(Format('  70 kg          = %.4f lb',       [TUnitConversionKit.ConvertMass(70, muKilogram, muPound)]));
  WriteLn(Format('  1 tonne        = %.2f kg',        [TUnitConversionKit.ConvertMass(1, muTonne, muKilogram)]));
  WriteLn(Format('  16 oz          = %.4f lb',        [TUnitConversionKit.ConvertMass(16, muOunce, muPound)]));
  WriteLn;

  WriteLn('=== Temperature ===');
  WriteLn(Format('  100 C          = %.4f F',         [TUnitConversionKit.ConvertTemperature(100, tpCelsius, tpFahrenheit)]));
  WriteLn(Format('  212 F          = %.4f C',         [TUnitConversionKit.ConvertTemperature(212, tpFahrenheit, tpCelsius)]));
  WriteLn(Format('  0 C            = %.4f K',         [TUnitConversionKit.ConvertTemperature(0, tpCelsius, tpKelvin)]));
  WriteLn(Format('  300 K          = %.4f C',         [TUnitConversionKit.ConvertTemperature(300, tpKelvin, tpCelsius)]));
  WriteLn;

  WriteLn('=== Velocity ===');
  WriteLn(Format('  100 km/h       = %.4f mph',       [TUnitConversionKit.ConvertVelocity(100, vuKilometerPerHour, vuMilePerHour)]));
  WriteLn(Format('  1 m/s          = %.4f km/h',      [TUnitConversionKit.ConvertVelocity(1, vuMeterPerSecond, vuKilometerPerHour)]));
  WriteLn(Format('  30 knots       = %.4f km/h',      [TUnitConversionKit.ConvertVelocity(30, vuKnot, vuKilometerPerHour)]));
  WriteLn;

  WriteLn('=== Pressure ===');
  WriteLn(Format('  1 atm          = %.4f kPa',       [TUnitConversionKit.ConvertPressure(1, prAtmosphere, prKilopascal)]));
  WriteLn(Format('  1 bar          = %.4f atm',       [TUnitConversionKit.ConvertPressure(1, prBar, prAtmosphere)]));
  WriteLn(Format('  14.696 psi     = %.4f atm',       [TUnitConversionKit.ConvertPressure(14.696, prPSI, prAtmosphere)]));
  WriteLn;

  WriteLn('=== Energy ===');
  WriteLn(Format('  1 kWh          = %.0f J',          [TUnitConversionKit.ConvertEnergy(1, euKilowattHour, euJoule)]));
  WriteLn(Format('  1 kcal         = %.4f kJ',         [TUnitConversionKit.ConvertEnergy(1, euKilocalorie, euKilojoule)]));
  WriteLn(Format('  1 BTU          = %.4f J',          [TUnitConversionKit.ConvertEnergy(1, euBTU, euJoule)]));
  WriteLn;

  WriteLn('=== Power ===');
  WriteLn(Format('  1 hp           = %.4f W',          [TUnitConversionKit.ConvertPower(1, puHorsepower, puWatt)]));
  WriteLn(Format('  1 kW           = %.4f hp',         [TUnitConversionKit.ConvertPower(1, puKilowatt, puHorsepower)]));
  WriteLn;

  WriteLn('=== Area ===');
  WriteLn(Format('  1 acre         = %.4f m²',         [TUnitConversionKit.ConvertArea(1, auAcre, auSquareMeter)]));
  WriteLn(Format('  1 km²          = %.4f acres',      [TUnitConversionKit.ConvertArea(1, auSquareKilometer, auAcre)]));
  WriteLn;

  WriteLn('=== Volume ===');
  WriteLn(Format('  1 US gallon    = %.4f L',           [TUnitConversionKit.ConvertVolume(1, voGallonUS, voLiter)]));
  WriteLn(Format('  1 L            = %.4f fl oz (US)',  [TUnitConversionKit.ConvertVolume(1, voLiter, voFluidOunceUS)]));
  WriteLn;

  WriteLn('=== Angle ===');
  WriteLn(Format('  180 deg        = %.6f rad',         [TUnitConversionKit.ConvertAngle(180, anDegree, anRadian)]));
  WriteLn(Format('  Pi rad         = %.4f deg',         [TUnitConversionKit.ConvertAngle(3.14159265, anRadian, anDegree)]));
  WriteLn;

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
