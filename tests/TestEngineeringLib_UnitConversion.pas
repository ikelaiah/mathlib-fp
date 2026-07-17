unit TestEngineeringLib_UnitConversion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, StrUtils,
  EngineeringLib.Common, EngineeringLib.UnitConversion;

type

  { TTestUnitConversionKit }

  TTestUnitConversionKit = class(TTestCase)
  private
    procedure FormatWithNegativeDecimalsTest;
    procedure ScientificNotationWithZeroDigitsTest;
    procedure RoundWithZeroDigitsTest;
  published
    procedure Test01_LengthConversion;
    procedure Test02_MassConversion;
    procedure Test03_TimeConversion;
    procedure Test04_TemperatureConversion;
    procedure Test05_ForceConversion;
    procedure Test06_EnergyConversion;
    procedure Test07_PowerConversion;
    procedure Test08_PressureConversion;
    procedure Test09_VelocityConversion;
    procedure Test10_AreaConversion;
    procedure Test11_VolumeConversion;
    procedure Test12_AngleConversion;
    procedure Test13_DensityConversion;
    procedure Test14_CurrentConversion;
    procedure Test15_PotentialConversion;
    procedure Test16_FrequencyConversion;
    procedure Test17_SameUnitConversion;
    
    // Tests for new functionality
    procedure Test18_FormatWithScientificNotation;
    procedure Test19_RoundToSignificantDigits;
    procedure Test20_TryConvertByUnitName;
    procedure Test21_TryParseValueWithUnit;
    procedure Test22_TryParseAndConvert;
    procedure Test23_UnitCompatibility;
    procedure Test24_GetAllUnitsOfType;
    procedure Test25_GetAllUnitTypes;
    procedure Test26_GetBaseUnit;
    procedure Test27_ConversionShortcuts;
    procedure Test28_TryGetUnitFromName;
    procedure Test29_UnknownUnitNameRaises;
    procedure Test30_FormatWithUnit;
    procedure Test31_AllUnitNameParsers;
    procedure Test32_FormattingValidation;
    procedure Test33_TimeConventions;
  end;

implementation

const
  Tolerance = 1E-6;

procedure TTestUnitConversionKit.FormatWithNegativeDecimalsTest;
begin
  TUnitConversionKit.FormatWithUnit(1.0, 'm', -1);
end;

procedure TTestUnitConversionKit.ScientificNotationWithZeroDigitsTest;
begin
  TUnitConversionKit.FormatWithScientificNotation(1.0, 'm', 0);
end;

procedure TTestUnitConversionKit.RoundWithZeroDigitsTest;
begin
  TUnitConversionKit.RoundToSignificantDigits(1.0, 0);
end;

procedure TTestUnitConversionKit.Test01_LengthConversion;
begin
  AssertEquals('km to m', 1000.0, TUnitConversionKit.ConvertLength(1.0, luKilometer, luMeter), Tolerance);
  AssertEquals('cm to m', 1.0, TUnitConversionKit.ConvertLength(100.0, luCentimeter, luMeter), Tolerance);
  AssertEquals('m to ft', 3.280839895, TUnitConversionKit.ConvertLength(1.0, luMeter, luFoot), Tolerance);
  AssertEquals('mile to mile', 1.0, TUnitConversionKit.ConvertLength(1.0, luMile, luMile), Tolerance);
  AssertEquals('Angstrom to m', 1E-10, TUnitConversionKit.ConvertLength(1.0, luAngstrom, luMeter), Tolerance);
end;

procedure TTestUnitConversionKit.Test02_MassConversion;
begin
  AssertEquals('kg to g', 1000.0, TUnitConversionKit.ConvertMass(1.0, muKilogram, muGram), Tolerance);
  AssertEquals('kg to lb', 2.2046226218, TUnitConversionKit.ConvertMass(1.0, muKilogram, muPound), Tolerance);
  AssertEquals('kg to tonne', 1.0, TUnitConversionKit.ConvertMass(1000.0, muKilogram, muTonne), Tolerance);
  AssertEquals('lb to oz', 16.0, TUnitConversionKit.ConvertMass(1.0, muPound, muOunce), Tolerance);
end;

procedure TTestUnitConversionKit.Test03_TimeConversion;
begin
  AssertEquals('min to s', 60.0, TUnitConversionKit.ConvertTime(1.0, tuMinute, tuSecond), Tolerance);
  AssertEquals('s to h', 1.0, TUnitConversionKit.ConvertTime(3600.0, tuSecond, tuHour), Tolerance);
  AssertEquals('yr to day', 365.0, TUnitConversionKit.ConvertTime(1.0, tuYear, tuDay), Tolerance); // Using 365 days/year
  AssertEquals('s to us', 1E6, TUnitConversionKit.ConvertTime(1.0, tuSecond, tuMicrosecond), Tolerance);
end;

procedure TTestUnitConversionKit.Test04_TemperatureConversion;
begin
  AssertEquals('K to C (freezing)', 0.0, TUnitConversionKit.ConvertTemperature(273.15, tpKelvin, tpCelsius), Tolerance);
  AssertEquals('K to C (boiling)', 100.0, TUnitConversionKit.ConvertTemperature(373.15, tpKelvin, tpCelsius), Tolerance);
  AssertEquals('C to F (freezing)', 32.0, TUnitConversionKit.ConvertTemperature(0.0, tpCelsius, tpFahrenheit), Tolerance);
  AssertEquals('C to F (boiling)', 212.0, TUnitConversionKit.ConvertTemperature(100.0, tpCelsius, tpFahrenheit), Tolerance);
  AssertEquals('F to K (freezing)', 273.15, TUnitConversionKit.ConvertTemperature(32.0, tpFahrenheit, tpKelvin), Tolerance);
  AssertEquals('C to Re (freezing)', 0.0, TUnitConversionKit.ConvertTemperature(0.0, tpCelsius, tpReaumur), Tolerance);
  AssertEquals('C to Re (boiling)', 80.0, TUnitConversionKit.ConvertTemperature(100.0, tpCelsius, tpReaumur), Tolerance);
  AssertEquals('C to R (freezing)', 491.67, TUnitConversionKit.ConvertTemperature(0.0, tpCelsius, tpRankine), Tolerance);
end;

procedure TTestUnitConversionKit.Test05_ForceConversion;
begin
  AssertEquals('kN to N', 1000.0, TUnitConversionKit.ConvertForce(1.0, fuKilonewton, fuNewton), Tolerance);
  AssertEquals('N to lbf', 0.2248089431, TUnitConversionKit.ConvertForce(1.0, fuNewton, fuPoundForce), Tolerance);
  AssertEquals('N to kgf', 1.0, TUnitConversionKit.ConvertForce(9.80665, fuNewton, fuKilogramForce), Tolerance);
end;

procedure TTestUnitConversionKit.Test06_EnergyConversion;
begin
  AssertEquals('kJ to J', 1000.0, TUnitConversionKit.ConvertEnergy(1.0, euKilojoule, euJoule), Tolerance);
  AssertEquals('J to cal', 1.0, TUnitConversionKit.ConvertEnergy(4.184, euJoule, euCalorie), Tolerance);
  AssertEquals('kWh to J', 3.6E6, TUnitConversionKit.ConvertEnergy(1.0, euKilowattHour, euJoule), Tolerance);
  AssertEquals('BTU to J', 1055.05585262, TUnitConversionKit.ConvertEnergy(1.0, euBTU, euJoule), Tolerance);
end;

procedure TTestUnitConversionKit.Test07_PowerConversion;
begin
  AssertEquals('kW to W', 1000.0, TUnitConversionKit.ConvertPower(1.0, puKilowatt, puWatt), Tolerance);
  AssertEquals('kW to hp', 1.34102208884381, TUnitConversionKit.ConvertPower(1.0, puKilowatt, puHorsepower), Tolerance);
  AssertEquals('kW to BTU/h', 3412.14163513308, TUnitConversionKit.ConvertPower(1.0, puKilowatt, puBTUPerHour), Tolerance);
end;

procedure TTestUnitConversionKit.Test08_PressureConversion;
begin
  AssertEquals('kPa to Pa', 1000.0, TUnitConversionKit.ConvertPressure(1.0, prKilopascal, prPascal), Tolerance);
  AssertEquals('Pa to bar', 1.0, TUnitConversionKit.ConvertPressure(100000.0, prPascal, prBar), Tolerance);
  AssertEquals('bar to psi', 14.5037737796859, TUnitConversionKit.ConvertPressure(1.0, prBar, prPSI), Tolerance);
  AssertEquals('Pa to atm', 1.0, TUnitConversionKit.ConvertPressure(101325.0, prPascal, prAtmosphere), Tolerance);
end;

procedure TTestUnitConversionKit.Test09_VelocityConversion;
begin
  AssertEquals('m/s to km/h', 3.59999982833863, TUnitConversionKit.ConvertVelocity(1.0, vuMeterPerSecond, vuKilometerPerHour), Tolerance);
  AssertEquals('m/s to mph', 2.2369362921, TUnitConversionKit.ConvertVelocity(1.0, vuMeterPerSecond, vuMilePerHour), Tolerance);
  AssertEquals('m/s to knot', 1.9438444924, TUnitConversionKit.ConvertVelocity(1.0, vuMeterPerSecond, vuKnot), Tolerance);
end;

procedure TTestUnitConversionKit.Test10_AreaConversion;
begin
  AssertEquals('ha to m²', 10000.0, TUnitConversionKit.ConvertArea(1.0, auHectare, auSquareMeter), Tolerance);
  AssertEquals('ha to acre', 2.4710538147, TUnitConversionKit.ConvertArea(1.0, auHectare, auAcre), Tolerance);
  AssertEquals('m² to ft²', 10.763910417, TUnitConversionKit.ConvertArea(1.0, auSquareMeter, auSquareFoot), Tolerance);
end;

procedure TTestUnitConversionKit.Test11_VolumeConversion;
begin
  AssertEquals('m³ to L', 1000.0, TUnitConversionKit.ConvertVolume(1.0, voCubicMeter, voLiter), Tolerance);
  AssertEquals('L to gal (US)', 0.2641720524, TUnitConversionKit.ConvertVolume(1.0, voLiter, voGallonUS), Tolerance);
  AssertEquals('L to fl oz (US)', 33.814022701843, TUnitConversionKit.ConvertVolume(1.0, voLiter, voFluidOunceUS), Tolerance);
  AssertEquals('m³ to ft³', 35.314666721, TUnitConversionKit.ConvertVolume(1.0, voCubicMeter, voCubicFoot), Tolerance);
end;

procedure TTestUnitConversionKit.Test12_AngleConversion;
begin
  AssertEquals('deg to rad', Pi, TUnitConversionKit.ConvertAngle(180.0, anDegree, anRadian), Tolerance);
  AssertEquals('rad to deg', 180.0, TUnitConversionKit.ConvertAngle(Pi, anRadian, anDegree), Tolerance);
  AssertEquals('deg to grad', 200.0, TUnitConversionKit.ConvertAngle(180.0, anDegree, anGradian), Tolerance);
  AssertEquals('deg to rev', 1.0, TUnitConversionKit.ConvertAngle(360.0, anDegree, anRevolution), Tolerance);
end;

procedure TTestUnitConversionKit.Test13_DensityConversion;
begin
  AssertEquals('g/cm³ to kg/m³', 1000.0, TUnitConversionKit.ConvertDensity(1.0, deGramPerCubicCentimeter, deKilogramPerCubicMeter), Tolerance);
  AssertEquals('g/cm³ to lb/ft³', 62.427960576, TUnitConversionKit.ConvertDensity(1.0, deGramPerCubicCentimeter, dePoundPerCubicFoot), Tolerance);
end;

procedure TTestUnitConversionKit.Test14_CurrentConversion;
begin
  AssertEquals('mA to A', 0.001, TUnitConversionKit.ConvertElectricalCurrent(1.0, ecMilliampere, ecAmpere), Tolerance);
  AssertEquals('A to uA', 1E6, TUnitConversionKit.ConvertElectricalCurrent(1.0, ecAmpere, ecMicroampere), Tolerance);
end;

procedure TTestUnitConversionKit.Test15_PotentialConversion;
begin
  AssertEquals('kV to V', 1000.0, TUnitConversionKit.ConvertElectricalPotential(1.0, epKilovolt, epVolt), Tolerance);
  AssertEquals('mV to V', 1E-3, TUnitConversionKit.ConvertElectricalPotential(1.0, epMillivolt, epVolt), Tolerance);
end;

procedure TTestUnitConversionKit.Test16_FrequencyConversion;
begin
  AssertEquals('kHz to Hz', 1000.0, TUnitConversionKit.ConvertFrequency(1.0, frKilohertz, frHertz), Tolerance);
  AssertEquals('Hz to MHz', 1E-6, TUnitConversionKit.ConvertFrequency(1.0, frHertz, frMegahertz), Tolerance);
  AssertEquals('Hz to cps', 1.0, TUnitConversionKit.ConvertFrequency(1.0, frHertz, frCyclePerSecond), Tolerance);
end;

procedure TTestUnitConversionKit.Test17_SameUnitConversion;
begin
  AssertEquals('Same length unit', 123.45, TUnitConversionKit.ConvertLength(123.45, luMeter, luMeter), Tolerance);
  AssertEquals('Same temperature unit', -50.0, TUnitConversionKit.ConvertTemperature(-50.0, tpCelsius, tpCelsius), Tolerance);
  AssertEquals('Same pressure unit', 1.0, TUnitConversionKit.ConvertPressure(1.0, prAtmosphere, prAtmosphere), Tolerance);
end;

procedure TTestUnitConversionKit.Test18_FormatWithScientificNotation;
var
  Result: string;
begin
  Result := TUnitConversionKit.FormatWithScientificNotation(1234.5678, 'm', 3);
  AssertEquals('Three significant digits', '1.23 × 10^3 m', Result);
  
  Result := TUnitConversionKit.FormatWithScientificNotation(0.0012345, 'V', 4);
  AssertEquals('Four significant digits - small value', '1.234 × 10^-3 V', Result);
  
  Result := TUnitConversionKit.FormatWithScientificNotation(0, 'kg', 2);
  AssertEquals('Zero value', '0 kg', Result);
  
  Result := TUnitConversionKit.FormatWithScientificNotation(9999, 'Hz', 2);
  AssertEquals('Rounding up to next exponent', '1.0 × 10^4 Hz', Result);
end;

procedure TTestUnitConversionKit.Test19_RoundToSignificantDigits;
begin
  AssertEquals('Three digits, regular value', 123, 
    TUnitConversionKit.RoundToSignificantDigits(123.456, 3), Tolerance);
    
  AssertEquals('Two digits, small value', 0.012, 
    TUnitConversionKit.RoundToSignificantDigits(0.01234, 2), Tolerance);
    
  AssertEquals('Four digits, large value', 1235000, 
    TUnitConversionKit.RoundToSignificantDigits(1234567, 4), Tolerance);
    
  AssertEquals('Zero remains zero', 0, 
    TUnitConversionKit.RoundToSignificantDigits(0, 5), Tolerance);
    
  AssertEquals('Round up', 1.2, 
    TUnitConversionKit.RoundToSignificantDigits(1.15, 2), Tolerance);
end;

procedure TTestUnitConversionKit.Test20_TryConvertByUnitName;
var
  Value: Double;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryConvertByUnitName(1.0, 'm', 'km', Value);
  AssertTrue('m to km conversion should succeed', Success);
  AssertEquals('1m = 0.001km', 0.001, Value, Tolerance);
  
  Success := TUnitConversionKit.TryConvertByUnitName(100.0, '°C', '°F', Value);
  AssertTrue('°C to °F conversion should succeed', Success);
  AssertEquals('100°C = 212°F', 212, Value, Tolerance);
  
  Success := TUnitConversionKit.TryConvertByUnitName(1.0, 'kg', 'N', Value);
  AssertFalse('Incompatible units should fail', Success);
  
  Success := TUnitConversionKit.TryConvertByUnitName(10.0, 'unknown', 'm', Value);
  AssertFalse('Unknown unit should fail', Success);
end;

procedure TTestUnitConversionKit.Test21_TryParseValueWithUnit;
var
  Value: Double;
  UnitNameStr: string;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryParseValueWithUnit('123.45 m', Value, UnitNameStr);
  AssertTrue('Valid format should parse successfully', Success);
  AssertEquals('Value part', 123.45, Value, Tolerance);
  AssertEquals('Unit part', 'm', UnitNameStr);
  
  Success := TUnitConversionKit.TryParseValueWithUnit('0.001kg', Value, UnitNameStr);
  AssertTrue('No space should parse successfully', Success);
  AssertEquals('Value part', 0.001, Value, Tolerance);
  AssertEquals('Unit part', 'kg', UnitNameStr);
  
  Success := TUnitConversionKit.TryParseValueWithUnit('-273.15 °C', Value, UnitNameStr);
  AssertTrue('Negative value should parse successfully', Success);
  AssertEquals('Value part', -273.15, Value, Tolerance);
  AssertEquals('Unit part', '°C', UnitNameStr);
  
  Success := TUnitConversionKit.TryParseValueWithUnit('1.5e3 W', Value, UnitNameStr);
  AssertTrue('Scientific notation should parse successfully', Success);
  AssertEquals('Value part', 1500, Value, Tolerance);
  AssertEquals('Unit part', 'W', UnitNameStr);
  
  Success := TUnitConversionKit.TryParseValueWithUnit('invalid', Value, UnitNameStr);
  AssertFalse('Invalid format should fail', Success);
end;

procedure TTestUnitConversionKit.Test22_TryParseAndConvert;
var
  Result: Double;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryParseAndConvert('1000 m', 'km', Result);
  AssertTrue('Valid conversion should succeed', Success);
  AssertEquals('1000m = 1km', 1.0, Result, Tolerance);
  
  Success := TUnitConversionKit.TryParseAndConvert('32°F', '°C', Result);
  AssertTrue('Temperature conversion should succeed', Success);
  AssertEquals('32°F = 0°C', 0.0, Result, Tolerance);
  
  Success := TUnitConversionKit.TryParseAndConvert('100kg', 'N', Result);
  AssertFalse('Incompatible units should fail', Success);
  
  Success := TUnitConversionKit.TryParseAndConvert('invalid', 'm', Result);
  AssertFalse('Invalid format should fail', Success);
end;

procedure TTestUnitConversionKit.Test23_UnitCompatibility;
begin
  AssertTrue('Same unit type should be compatible', 
    TUnitConversionKit.AreUnitsCompatible(utLength, utLength));
    
  AssertFalse('Different unit types should not be compatible', 
    TUnitConversionKit.AreUnitsCompatible(utLength, utMass));
    
  AssertTrue('Compatible unit names', 
    TUnitConversionKit.AreUnitNamesCompatible('m', 'km'));
    
  AssertTrue('Compatible unit names', 
    TUnitConversionKit.AreUnitNamesCompatible('kg', 'g'));
    
  AssertFalse('Incompatible unit names', 
    TUnitConversionKit.AreUnitNamesCompatible('m', 'kg'));
end;

procedure TTestUnitConversionKit.Test24_GetAllUnitsOfType;
var
  Units: TStringArray;
begin
  Units := TUnitConversionKit.GetAllUnitsOfType(utLength);
  AssertTrue('Length units should include meter', IndexStr('m', Units) >= 0);
  AssertTrue('Length units should include kilometer', IndexStr('km', Units) >= 0);
  AssertTrue('Length units should include foot', IndexStr('ft', Units) >= 0);
  AssertEquals('Length units count', Ord(High(TLengthUnit)) + 1, Length(Units));
  
  Units := TUnitConversionKit.GetAllUnitsOfType(utTemperature);
  AssertTrue('Temperature units should include Kelvin', IndexStr('K', Units) >= 0);
  AssertTrue('Temperature units should include Celsius', IndexStr('°C', Units) >= 0);
  AssertEquals('Temperature units count', Ord(High(TTemperatureUnit)) + 1, Length(Units));
end;

procedure TTestUnitConversionKit.Test25_GetAllUnitTypes;
var
  Types: TStringArray;
begin
  Types := TUnitConversionKit.GetAllUnitTypes;
  AssertTrue('Should include Length', IndexStr('Length', Types) >= 0);
  AssertTrue('Should include Mass', IndexStr('Mass', Types) >= 0);
  AssertTrue('Should include Temperature', IndexStr('Temperature', Types) >= 0);
  AssertEquals('Unit types count', Ord(High(TUnitType)) + 1, Length(Types));
end;

procedure TTestUnitConversionKit.Test26_GetBaseUnit;
begin
  AssertEquals('Base unit of Length', 'm', TUnitConversionKit.GetBaseUnit(utLength));
  AssertEquals('Base unit of Mass', 'kg', TUnitConversionKit.GetBaseUnit(utMass));
  AssertEquals('Base unit of Temperature', 'K', TUnitConversionKit.GetBaseUnit(utTemperature));
  AssertEquals('Base unit of Force', 'N', TUnitConversionKit.GetBaseUnit(utForce));
  AssertEquals('Base unit of Energy', 'J', TUnitConversionKit.GetBaseUnit(utEnergy));
end;

procedure TTestUnitConversionKit.Test27_ConversionShortcuts;
begin
  AssertEquals('Miles to kilometers', 1.609344, 
    TUnitConversionKit.MilesToKilometers(1.0), Tolerance);
    
  AssertEquals('Kilometers to miles', 0.6213711922, 
    TUnitConversionKit.KilometersToMiles(1.0), Tolerance);
    
  AssertEquals('Pounds to kilograms', 0.45359237, 
    TUnitConversionKit.PoundsToKilograms(1.0), Tolerance);
    
  AssertEquals('Kilograms to pounds', 2.2046226218, 
    TUnitConversionKit.KilogramsToPounds(1.0), Tolerance);
    
  AssertEquals('Celsius to Fahrenheit', 68.0, 
    TUnitConversionKit.CelsiusToFahrenheit(20.0), Tolerance);
    
  AssertEquals('Fahrenheit to Celsius', 20.0, 
    TUnitConversionKit.FahrenheitToCelsius(68.0), Tolerance);
end;

procedure TTestUnitConversionKit.Test28_TryGetUnitFromName;
var
  LengthUnit: TLengthUnit;
  TempUnit: TTemperatureUnit;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryGetLengthUnitFromName('m', LengthUnit);
  AssertTrue('Valid length unit name should succeed', Success);
  AssertTrue('Should get correct unit enum', LengthUnit = luMeter);
  
  Success := TUnitConversionKit.TryGetLengthUnitFromName('invalid', LengthUnit);
  AssertFalse('Invalid length unit name should fail', Success);
  
  Success := TUnitConversionKit.TryGetTemperatureUnitFromName('°C', TempUnit);
  AssertTrue('Valid temperature unit name should succeed', Success);
  AssertTrue('Should get correct unit enum', TempUnit = tpCelsius);
end;

procedure TTestUnitConversionKit.Test29_UnknownUnitNameRaises;
begin
  try
    TUnitConversionKit.GetUnitTypeFromUnitName('definitely-not-a-unit');
    Fail('unknown unit name must raise EUnitConversionError');
  except
    on E: EUnitConversionError do { expected };
  end;
end;

procedure TTestUnitConversionKit.Test30_FormatWithUnit;
begin
  AssertEquals('Fixed-point value with unit', '12.35 m',
    TUnitConversionKit.FormatWithUnit(12.345, 'm', 2));
  AssertEquals('Zero decimal places', '12 kg',
    TUnitConversionKit.FormatWithUnit(12.0, 'kg', 0));
end;

procedure TTestUnitConversionKit.Test31_AllUnitNameParsers;
var
  LengthUnit: TLengthUnit;
  MassUnit: TMassUnit;
  TimeUnit: TTimeUnit;
  TemperatureUnit: TTemperatureUnit;
  ForceUnit: TForceUnit;
  EnergyUnit: TEnergyUnit;
  PowerUnit: TPowerUnit;
  PressureUnit: TPressureUnit;
  VelocityUnit: TVelocityUnit;
  AreaUnit: TAreaUnit;
  VolumeUnit: TVolumeUnit;
  AngleUnit: TAngleUnit;
  DensityUnit: TDensityUnit;
  CurrentUnit: TElectricalCurrentUnit;
  PotentialUnit: TElectricalPotentialUnit;
  FrequencyUnit: TFrequencyUnit;
begin
  AssertTrue('Length parser', TUnitConversionKit.TryGetLengthUnitFromName('m', LengthUnit));
  AssertTrue('Mass parser', TUnitConversionKit.TryGetMassUnitFromName('kg', MassUnit));
  AssertTrue('Time parser', TUnitConversionKit.TryGetTimeUnitFromName('s', TimeUnit));
  AssertTrue('Temperature parser', TUnitConversionKit.TryGetTemperatureUnitFromName('K', TemperatureUnit));
  AssertTrue('Force parser', TUnitConversionKit.TryGetForceUnitFromName('N', ForceUnit));
  AssertTrue('Energy parser', TUnitConversionKit.TryGetEnergyUnitFromName('J', EnergyUnit));
  AssertTrue('Power parser', TUnitConversionKit.TryGetPowerUnitFromName('W', PowerUnit));
  AssertTrue('Pressure parser', TUnitConversionKit.TryGetPressureUnitFromName('Pa', PressureUnit));
  AssertTrue('Velocity parser', TUnitConversionKit.TryGetVelocityUnitFromName('m/s', VelocityUnit));
  AssertTrue('Area parser', TUnitConversionKit.TryGetAreaUnitFromName('m²', AreaUnit));
  AssertTrue('Volume parser', TUnitConversionKit.TryGetVolumeUnitFromName('L', VolumeUnit));
  AssertTrue('Angle parser', TUnitConversionKit.TryGetAngleUnitFromName('°', AngleUnit));
  AssertTrue('Density parser', TUnitConversionKit.TryGetDensityUnitFromName('kg/m³', DensityUnit));
  AssertTrue('Current parser', TUnitConversionKit.TryGetElectricalCurrentUnitFromName('A', CurrentUnit));
  AssertTrue('Potential parser', TUnitConversionKit.TryGetElectricalPotentialUnitFromName('V', PotentialUnit));
  AssertTrue('Frequency parser', TUnitConversionKit.TryGetFrequencyUnitFromName('Hz', FrequencyUnit));
end;

procedure TTestUnitConversionKit.Test32_FormattingValidation;
begin
  AssertException('Negative decimal places raise EUnitConversionError',
    EUnitConversionError, @FormatWithNegativeDecimalsTest);
  AssertException('Zero significant digits in formatting raise EUnitConversionError',
    EUnitConversionError, @ScientificNotationWithZeroDigitsTest);
  AssertException('Zero significant digits in rounding raise EUnitConversionError',
    EUnitConversionError, @RoundWithZeroDigitsTest);
end;

procedure TTestUnitConversionKit.Test33_TimeConventions;
begin
  AssertEquals('Month uses 365/12 average days', 30.4166666666667,
    TUnitConversionKit.ConvertTime(1.0, tuMonth, tuDay), Tolerance);
  AssertEquals('Year uses 365 days', 365.0,
    TUnitConversionKit.ConvertTime(1.0, tuYear, tuDay), Tolerance);
end;

initialization
  RegisterTest(TTestUnitConversionKit);
end.
