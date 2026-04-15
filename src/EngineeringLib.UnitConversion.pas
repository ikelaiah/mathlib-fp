unit EngineeringLib.UnitConversion;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  { Unit types }
  TUnitType = (utLength, utMass, utTime, utTemperature, utForce, utEnergy,
               utPower, utPressure, utVelocity, utArea, utVolume, utAngle,
               utDensity, utElectricalCurrent, utElectricalPotential, utFrequency);

  { Specific units }
  TLengthUnit = (luMeter, luKilometer, luCentimeter, luMillimeter, luMicrometer,
                 luNanometer, luMile, luYard, luFoot, luInch, luNauticalMile, luAngstrom, luLightYear);

  TMassUnit = (muKilogram, muGram, muMilligram, muMicrogram, muTonne, muPound,
               muOunce, muStone, muUSton, muImperialTon);

  TTimeUnit = (tuSecond, tuMinute, tuHour, tuDay, tuWeek, tuMonth, tuYear,
               tuMillisecond, tuMicrosecond, tuNanosecond);

  TTemperatureUnit = (tpKelvin, tpCelsius, tpFahrenheit, tpRankine, tpReaumur);

  TForceUnit = (fuNewton, fuKilonewton, fuPoundForce, fuDyne, fuKilogramForce);

  TEnergyUnit = (euJoule, euKilojoule, euCalorie, euKilocalorie, euWattHour,
                 euKilowattHour, euElectronvolt, euBTU, euTherm, euFootPound);

  TPowerUnit = (puWatt, puKilowatt, puMegawatt, puHorsepower, puBTUPerHour);

  TPressureUnit = (prPascal, prKilopascal, prBar, prAtmosphere, prTorr, prPSI);

  TVelocityUnit = (vuMeterPerSecond, vuKilometerPerHour, vuMilePerHour, vuFootPerSecond,
                   vuKnot);

  TAreaUnit = (auSquareMeter, auSquareKilometer, auHectare, auAre, auSquareMile,
               auAcre, auSquareYard, auSquareFoot, auSquareInch);

  TVolumeUnit = (voLiter, voCubicMeter, voMilliliter, voCubicCentimeter,
                voGallonUS, voGallonUK, voFluidOunceUS, voFluidOunceUK,
                voCubicFoot, voCubicInch);

  TAngleUnit = (anDegree, anRadian, anGradian, anMinuteOfArc, anSecondOfArc, anRevolution);

  TDensityUnit = (deKilogramPerCubicMeter, deGramPerCubicCentimeter,
                  dePoundPerCubicFoot, dePoundPerCubicInch);

  TElectricalCurrentUnit = (ecAmpere, ecMilliampere, ecMicroampere);

  TElectricalPotentialUnit = (epVolt, epKilovolt, epMillivolt, epMicrovolt);

  TFrequencyUnit = (frHertz, frKilohertz, frMegahertz, frGigahertz, frCyclePerSecond);

{ Unit Conversion Class }
type
  TStringArray = array of string;

  TUnitConversionKit = class
  public
    { Length conversions }
    class function ConvertLength(Value: Double; FromUnit, ToUnit: TLengthUnit): Double; static;

    { Mass conversions }
    class function ConvertMass(Value: Double; FromUnit, ToUnit: TMassUnit): Double; static;

    { Time conversions }
    class function ConvertTime(Value: Double; FromUnit, ToUnit: TTimeUnit): Double; static;

    { Temperature conversions }
    class function ConvertTemperature(Value: Double; FromUnit, ToUnit: TTemperatureUnit): Double; static;

    { Force conversions }
    class function ConvertForce(Value: Double; FromUnit, ToUnit: TForceUnit): Double; static;

    { Energy conversions }
    class function ConvertEnergy(Value: Double; FromUnit, ToUnit: TEnergyUnit): Double; static;

    { Power conversions }
    class function ConvertPower(Value: Double; FromUnit, ToUnit: TPowerUnit): Double; static;

    { Pressure conversions }
    class function ConvertPressure(Value: Double; FromUnit, ToUnit: TPressureUnit): Double; static;

    { Velocity conversions }
    class function ConvertVelocity(Value: Double; FromUnit, ToUnit: TVelocityUnit): Double; static;

    { Area conversions }
    class function ConvertArea(Value: Double; FromUnit, ToUnit: TAreaUnit): Double; static;

    { Volume conversions }
    class function ConvertVolume(Value: Double; FromUnit, ToUnit: TVolumeUnit): Double; static;

    { Angle conversions }
    class function ConvertAngle(Value: Double; FromUnit, ToUnit: TAngleUnit): Double; static;

    { Density conversions }
    class function ConvertDensity(Value: Double; FromUnit, ToUnit: TDensityUnit): Double; static;

    { Electrical current conversions }
    class function ConvertElectricalCurrent(Value: Double; FromUnit, ToUnit: TElectricalCurrentUnit): Double; static;

    { Electrical potential conversions }
    class function ConvertElectricalPotential(Value: Double; FromUnit, ToUnit: TElectricalPotentialUnit): Double; static;

    { Frequency conversions }
    class function ConvertFrequency(Value: Double; FromUnit, ToUnit: TFrequencyUnit): Double; static;

    { Get unit name as string }
    class function GetLengthUnitName(Unit_: TLengthUnit): string; static;
    class function GetMassUnitName(Unit_: TMassUnit): string; static;
    class function GetTimeUnitName(Unit_: TTimeUnit): string; static;
    class function GetTemperatureUnitName(Unit_: TTemperatureUnit): string; static;
    class function GetForceUnitName(Unit_: TForceUnit): string; static;
    class function GetEnergyUnitName(Unit_: TEnergyUnit): string; static;
    class function GetPowerUnitName(Unit_: TPowerUnit): string; static;
    class function GetPressureUnitName(Unit_: TPressureUnit): string; static;
    class function GetVelocityUnitName(Unit_: TVelocityUnit): string; static;
    class function GetAreaUnitName(Unit_: TAreaUnit): string; static;
    class function GetVolumeUnitName(Unit_: TVolumeUnit): string; static;
    class function GetAngleUnitName(Unit_: TAngleUnit): string; static;
    class function GetDensityUnitName(Unit_: TDensityUnit): string; static;
    class function GetElectricalCurrentUnitName(Unit_: TElectricalCurrentUnit): string; static;
    class function GetElectricalPotentialUnitName(Unit_: TElectricalPotentialUnit): string; static;
    class function GetFrequencyUnitName(Unit_: TFrequencyUnit): string; static;

    { Helper functions }
    class function FormatWithUnit(Value: Double; AUnitName: string; Decimals: Integer = 2): string; static;

    { Advanced formatting functions }
    class function FormatWithScientificNotation(Value: Double; AUnitName: string; 
      SignificantDigits: Integer = 3): string; static;
    class function RoundToSignificantDigits(Value: Double; SignificantDigits: Integer): Double; static;

    { String-based unit conversion functions }
    class function TryConvertByUnitName(Value: Double; FromAUnitName, ToAUnitName: string; 
      out ConvertedValue: Double): Boolean; static;
    class function GetUnitTypeFromUnitName(AUnitName: string): TUnitType; static;

    { Helper functions for unit name parsing }
    class function TryGetLengthUnitFromName(AUnitName: string; out Unit_: TLengthUnit): Boolean; static;
    class function TryGetMassUnitFromName(AUnitName: string; out Unit_: TMassUnit): Boolean; static;
    class function TryGetTimeUnitFromName(AUnitName: string; out Unit_: TTimeUnit): Boolean; static;
    class function TryGetTemperatureUnitFromName(AUnitName: string; out Unit_: TTemperatureUnit): Boolean; static;
    class function TryGetForceUnitFromName(AUnitName: string; out Unit_: TForceUnit): Boolean; static;
    class function TryGetEnergyUnitFromName(AUnitName: string; out Unit_: TEnergyUnit): Boolean; static;
    class function TryGetPowerUnitFromName(AUnitName: string; out Unit_: TPowerUnit): Boolean; static;
    class function TryGetPressureUnitFromName(AUnitName: string; out Unit_: TPressureUnit): Boolean; static;
    class function TryGetVelocityUnitFromName(AUnitName: string; out Unit_: TVelocityUnit): Boolean; static;
    class function TryGetAreaUnitFromName(AUnitName: string; out Unit_: TAreaUnit): Boolean; static;
    class function TryGetVolumeUnitFromName(AUnitName: string; out Unit_: TVolumeUnit): Boolean; static;
    class function TryGetAngleUnitFromName(AUnitName: string; out Unit_: TAngleUnit): Boolean; static;
    class function TryGetDensityUnitFromName(AUnitName: string; out Unit_: TDensityUnit): Boolean; static;
    class function TryGetElectricalCurrentUnitFromName(AUnitName: string; out Unit_: TElectricalCurrentUnit): Boolean; static;
    class function TryGetElectricalPotentialUnitFromName(AUnitName: string; out Unit_: TElectricalPotentialUnit): Boolean; static;
    class function TryGetFrequencyUnitFromName(AUnitName: string; out Unit_: TFrequencyUnit): Boolean; static;

    { String parsing functions }
    class function TryParseValueWithUnit(const ValueStr: string; out Value: Double; 
      out AUnitName: string): Boolean; static;
    class function TryParseAndConvert(const ValueStr, ToAUnitName: string; 
      out ConvertedValue: Double): Boolean; static;

    { Unit compatibility checking }
    class function AreUnitsCompatible(UnitType1, UnitType2: TUnitType): Boolean; static;
    class function AreUnitNamesCompatible(AUnitName1, AUnitName2: string): Boolean; static;

    { Unit enumeration functions }
    class function GetAllUnitsOfType(UnitType: TUnitType): TStringArray; static;
    class function GetAllUnitTypes: TStringArray; static;

    { Base unit functions }
    class function GetBaseUnit(UnitType: TUnitType): string; static;

    { Common conversion shortcuts }
    class function MilesToKilometers(Miles: Double): Double; static;
    class function KilometersToMiles(Kilometers: Double): Double; static;
    class function PoundsToKilograms(Pounds: Double): Double; static;
    class function KilogramsToPounds(Kilograms: Double): Double; static;
    class function CelsiusToFahrenheit(Celsius: Double): Double; static;
    class function FahrenheitToCelsius(Fahrenheit: Double): Double; static;
  end;

implementation

{ TUnitConversionKit }

class function TUnitConversionKit.ConvertLength(Value: Double; FromUnit, ToUnit: TLengthUnit): Double;
const
  // Conversion factors to meters
  ToMeterFactors: array[TLengthUnit] of Double = (
    1.0,            // luMeter
    1000.0,         // luKilometer
    0.01,           // luCentimeter
    0.001,          // luMillimeter
    1E-6,           // luMicrometer
    1E-9,           // luNanometer
    1609.344,       // luMile
    0.9144,         // luYard
    0.3048,         // luFoot
    0.0254,         // luInch
    1852.0,         // luNauticalMile
    1E-10,          // luAngstrom
    9.4607E15       // luLightYear
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to meters first, then to target unit
  Result := Value * ToMeterFactors[FromUnit] / ToMeterFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertMass(Value: Double; FromUnit, ToUnit: TMassUnit): Double;
const
  // Conversion factors to kilograms
  ToKilogramFactors: array[TMassUnit] of Double = (
    1.0,            // muKilogram
    0.001,          // muGram
    1E-6,           // muMilligram
    1E-9,           // muMicrogram
    1000.0,         // muTonne
    0.45359237,     // muPound
    0.028349523125, // muOunce
    6.35029318,     // muStone
    907.18474,      // muUSton
    1016.0469088    // muImperialTon
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to kilograms first, then to target unit
  Result := Value * ToKilogramFactors[FromUnit] / ToKilogramFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertTime(Value: Double; FromUnit, ToUnit: TTimeUnit): Double;
const
  // Conversion factors to seconds
  ToSecondFactors: array[TTimeUnit] of Double = (
    1.0,            // tuSecond
    60.0,           // tuMinute
    3600.0,         // tuHour
    86400.0,        // tuDay
    604800.0,       // tuWeek
    2628000.0,      // tuMonth (average 30.4167 days)
    31536000.0,     // tuYear (365 days)
    0.001,          // tuMillisecond
    1E-6,           // tuMicrosecond
    1E-9            // tuNanosecond
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to seconds first, then to target unit
  Result := Value * ToSecondFactors[FromUnit] / ToSecondFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertTemperature(Value: Double; FromUnit, ToUnit: TTemperatureUnit): Double;
var
  KelvinValue: Double;
begin
  if FromUnit = ToUnit then Exit(Value);

  // First convert to Kelvin as intermediate
  case FromUnit of
    tpKelvin: KelvinValue := Value;
    tpCelsius: KelvinValue := Value + 273.15;
    tpFahrenheit: KelvinValue := (Value - 32) * 5/9 + 273.15;
    tpRankine: KelvinValue := Value * 5/9;
    tpReaumur: KelvinValue := Value * 1.25 + 273.15;
  else
    raise Exception.Create('Unknown source temperature unit');
  end;

  // Then convert from Kelvin to target unit
  case ToUnit of
    tpKelvin: Result := KelvinValue;
    tpCelsius: Result := KelvinValue - 273.15;
    tpFahrenheit: Result := (KelvinValue - 273.15) * 9/5 + 32;
    tpRankine: Result := KelvinValue * 9/5;
    tpReaumur: Result := (KelvinValue - 273.15) * 0.8;
  else
    raise Exception.Create('Unknown target temperature unit');
  end;
end;

class function TUnitConversionKit.ConvertForce(Value: Double; FromUnit, ToUnit: TForceUnit): Double;
const
  // Conversion factors to newtons
  ToNewtonFactors: array[TForceUnit] of Double = (
    1.0,            // fuNewton
    1000.0,         // fuKilonewton
    4.4482216152605, // fuPoundForce
    1E-5,           // fuDyne
    9.80665         // fuKilogramForce
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to newtons first, then to target unit
  Result := Value * ToNewtonFactors[FromUnit] / ToNewtonFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertEnergy(Value: Double; FromUnit, ToUnit: TEnergyUnit): Double;
const
  // Conversion factors to joules
  ToJouleFactors: array[TEnergyUnit] of Double = (
    1.0,              // euJoule
    1000.0,           // euKilojoule
    4.184,            // euCalorie (thermochemical)
    4184.0,           // euKilocalorie
    3600.0,           // euWattHour
    3.6E6,            // euKilowattHour
    1.602176634E-19,  // euElectronvolt
    1055.05585262,    // euBTU (ISO)
    1.05505585262E8,  // euTherm (US)
    1.3558179483314   // euFootPound
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to joules first, then to target unit
  Result := Value * ToJouleFactors[FromUnit] / ToJouleFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertPower(Value: Double; FromUnit, ToUnit: TPowerUnit): Double;
const
  // Conversion factors to watts
  ToWattFactors: array[TPowerUnit] of Double = (
    1.0,              // puWatt
    1000.0,           // puKilowatt
    1E6,              // puMegawatt
    745.699872,       // puHorsepower (mechanical)
    0.29307107        // puBTUPerHour
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to watts first, then to target unit
  Result := Value * ToWattFactors[FromUnit] / ToWattFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertPressure(Value: Double; FromUnit, ToUnit: TPressureUnit): Double;
const
  // Conversion factors to pascals
  ToPascalFactors: array[TPressureUnit] of Double = (
    1.0,              // prPascal
    1000.0,           // prKilopascal
    1E5,              // prBar
    101325.0,         // prAtmosphere (standard)
    133.322368421,    // prTorr (mmHg at 0°C)
    6894.75729        // prPSI (Pound per square inch)
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to pascals first, then to target unit
  Result := Value * ToPascalFactors[FromUnit] / ToPascalFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertVelocity(Value: Double; FromUnit, ToUnit: TVelocityUnit): Double;
const
  // Conversion factors to meters per second
  ToMpsFactors: array[TVelocityUnit] of Double = (
    1.0,              // vuMeterPerSecond
    1000.0 / 3600.0,  // vuKilometerPerHour
    1609.344 / 3600.0,// vuMilePerHour
    0.3048,           // vuFootPerSecond
    1852.0 / 3600.0   // vuKnot (nautical mile per hour)
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to meters per second first, then to target unit
  Result := Value * ToMpsFactors[FromUnit] / ToMpsFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertArea(Value: Double; FromUnit, ToUnit: TAreaUnit): Double;
const
  // Conversion factors to square meters
  ToSquareMeterFactors: array[TAreaUnit] of Double = (
    1.0,              // auSquareMeter
    1E6,              // auSquareKilometer
    10000.0,          // auHectare
    100.0,            // auAre
    2589988.110336,   // auSquareMile
    4046.8564224,     // auAcre
    0.83612736,       // auSquareYard
    0.09290304,       // auSquareFoot
    0.00064516        // auSquareInch
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to square meters first, then to target unit
  Result := Value * ToSquareMeterFactors[FromUnit] / ToSquareMeterFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertVolume(Value: Double; FromUnit, ToUnit: TVolumeUnit): Double;
const
  // Conversion factors to cubic meters
  ToCubicMeterFactors: array[TVolumeUnit] of Double = (
    0.001,            // voLiter
    1.0,              // voCubicMeter
    1E-6,             // voMilliliter
    1E-6,             // voCubicCentimeter (same as mL)
    0.003785411784,   // voGallonUS
    0.00454609,       // voGallonUK
    2.95735295625E-5, // voFluidOunceUS
    2.84130625E-5,    // voFluidOunceUK
    0.028316846592,   // voCubicFoot
    1.6387064E-5      // voCubicInch
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to cubic meters first, then to target unit
  Result := Value * ToCubicMeterFactors[FromUnit] / ToCubicMeterFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertAngle(Value: Double; FromUnit, ToUnit: TAngleUnit): Double;
const
  // Conversion factors to radians
  ToRadianFactors: array[TAngleUnit] of Double = (
    Pi / 180.0,         // anDegree
    1.0,                // anRadian
    Pi / 200.0,         // anGradian
    Pi / (180.0 * 60.0),// anMinuteOfArc
    Pi / (180.0 * 3600.0),// anSecondOfArc
    2.0 * Pi            // anRevolution
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to radians first, then to target unit
  Result := Value * ToRadianFactors[FromUnit] / ToRadianFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertDensity(Value: Double; FromUnit, ToUnit: TDensityUnit): Double;
const
  // Conversion factors to kg/m³
  ToKgPerCubicMeterFactors: array[TDensityUnit] of Double = (
    1.0,                // deKilogramPerCubicMeter
    1000.0,             // deGramPerCubicCentimeter
    16.01846337396,     // dePoundPerCubicFoot
    27679.9047102       // dePoundPerCubicInch
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to kg/m³ first, then to target unit
  Result := Value * ToKgPerCubicMeterFactors[FromUnit] / ToKgPerCubicMeterFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertElectricalCurrent(Value: Double; FromUnit, ToUnit: TElectricalCurrentUnit): Double;
const
  // Conversion factors to amperes
  ToAmpereFactors: array[TElectricalCurrentUnit] of Double = (
    1.0,                // ecAmpere
    1E-3,               // ecMilliampere
    1E-6                // ecMicroampere
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to amperes first, then to target unit
  Result := Value * ToAmpereFactors[FromUnit] / ToAmpereFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertElectricalPotential(Value: Double; FromUnit, ToUnit: TElectricalPotentialUnit): Double;
const
  // Conversion factors to volts
  ToVoltFactors: array[TElectricalPotentialUnit] of Double = (
    1.0,                // epVolt
    1000.0,             // epKilovolt
    1E-3,               // epMillivolt
    1E-6                // epMicrovolt
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to volts first, then to target unit
  Result := Value * ToVoltFactors[FromUnit] / ToVoltFactors[ToUnit];
end;

class function TUnitConversionKit.ConvertFrequency(Value: Double; FromUnit, ToUnit: TFrequencyUnit): Double;
const
  // Conversion factors to hertz
  ToHertzFactors: array[TFrequencyUnit] of Double = (
    1.0,                // frHertz
    1000.0,             // frKilohertz
    1E6,                // frMegahertz
    1E9,                // frGigahertz
    1.0                 // frCyclePerSecond (same as Hz)
  );
begin
  if FromUnit = ToUnit then Exit(Value);
  // Convert to hertz first, then to target unit
  Result := Value * ToHertzFactors[FromUnit] / ToHertzFactors[ToUnit];
end;

class function TUnitConversionKit.GetLengthUnitName(Unit_: TLengthUnit): string;
const
  UnitNames: array[TLengthUnit] of string = (
    'm', 'km', 'cm', 'mm', 'μm', 'nm', 'mi', 'yd', 'ft', 'in', 'nmi', 'Å', 'ly'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetMassUnitName(Unit_: TMassUnit): string;
const
  UnitNames: array[TMassUnit] of string = (
    'kg', 'g', 'mg', 'μg', 't', 'lb', 'oz', 'st', 'US ton', 'imp ton'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetTimeUnitName(Unit_: TTimeUnit): string;
const
  UnitNames: array[TTimeUnit] of string = (
    's', 'min', 'h', 'd', 'wk', 'mo', 'yr', 'ms', 'μs', 'ns'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetTemperatureUnitName(Unit_: TTemperatureUnit): string;
const
  UnitNames: array[TTemperatureUnit] of string = (
    'K', '°C', '°F', '°R', '°Ré'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetForceUnitName(Unit_: TForceUnit): string;
const
  UnitNames: array[TForceUnit] of string = (
    'N', 'kN', 'lbf', 'dyn', 'kgf'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetEnergyUnitName(Unit_: TEnergyUnit): string;
const
  UnitNames: array[TEnergyUnit] of string = (
    'J', 'kJ', 'cal', 'kcal', 'Wh', 'kWh', 'eV', 'BTU', 'therm', 'ft⋅lb'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetPowerUnitName(Unit_: TPowerUnit): string;
const
  UnitNames: array[TPowerUnit] of string = (
    'W', 'kW', 'MW', 'hp', 'BTU/h'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetPressureUnitName(Unit_: TPressureUnit): string;
const
  UnitNames: array[TPressureUnit] of string = (
    'Pa', 'kPa', 'bar', 'atm', 'Torr', 'psi'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetVelocityUnitName(Unit_: TVelocityUnit): string;
const
  UnitNames: array[TVelocityUnit] of string = (
    'm/s', 'km/h', 'mph', 'ft/s', 'kt'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetAreaUnitName(Unit_: TAreaUnit): string;
const
  UnitNames: array[TAreaUnit] of string = (
    'm²', 'km²', 'ha', 'a', 'mi²', 'acre', 'yd²', 'ft²', 'in²'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetVolumeUnitName(Unit_: TVolumeUnit): string;
const
  UnitNames: array[TVolumeUnit] of string = (
    'L', 'm³', 'mL', 'cm³', 'gal (US)', 'gal (UK)', 'fl oz (US)', 'fl oz (UK)', 'ft³', 'in³'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetAngleUnitName(Unit_: TAngleUnit): string;
const
  UnitNames: array[TAngleUnit] of string = (
    '°', 'rad', 'grad', '′', '″', 'rev'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetDensityUnitName(Unit_: TDensityUnit): string;
const
  UnitNames: array[TDensityUnit] of string = (
    'kg/m³', 'g/cm³', 'lb/ft³', 'lb/in³'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetElectricalCurrentUnitName(Unit_: TElectricalCurrentUnit): string;
const
  UnitNames: array[TElectricalCurrentUnit] of string = (
    'A', 'mA', 'μA'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetElectricalPotentialUnitName(Unit_: TElectricalPotentialUnit): string;
const
  UnitNames: array[TElectricalPotentialUnit] of string = (
    'V', 'kV', 'mV', 'μV'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.GetFrequencyUnitName(Unit_: TFrequencyUnit): string;
const
  UnitNames: array[TFrequencyUnit] of string = (
    'Hz', 'kHz', 'MHz', 'GHz', 'cps'
  );
begin
  Result := UnitNames[Unit_];
end;

class function TUnitConversionKit.FormatWithUnit(Value: Double; AUnitName: string; Decimals: Integer): string;
begin
  Result := Format('%.*f %s', [Decimals, Value, AUnitName]);
end;

class function TUnitConversionKit.FormatWithScientificNotation(Value: Double; AUnitName: string;
  SignificantDigits: Integer): string;
var
  Exponent: Integer;
  Mantissa: Double;
begin
  if Value = 0 then
    Result := '0 ' + AUnitName
  else
  begin
    Exponent := Floor(Log10(Abs(Value)));
    Mantissa := Value / Power(10, Exponent);
    Mantissa := RoundToSignificantDigits(Mantissa, SignificantDigits);
    
    // Adjust if rounding caused mantissa to equal 10
    if Abs(Mantissa) >= 10 then
    begin
      Mantissa := Mantissa / 10;
      Inc(Exponent);
    end;
    
    Result := Format('%.*f × 10^%d %s', [SignificantDigits-1, Mantissa, Exponent, AUnitName]);
  end;
end;

class function TUnitConversionKit.RoundToSignificantDigits(Value: Double; SignificantDigits: Integer): Double;
var
  Factor: Double;
begin
  if Value = 0 then
    Result := 0
  else
  begin
    Factor := Power(10, SignificantDigits - 1 - Floor(Log10(Abs(Value))));
    Result := Round(Value * Factor) / Factor;
  end;
end;

class function TUnitConversionKit.TryConvertByUnitName(Value: Double; FromAUnitName, ToAUnitName: string;
  out ConvertedValue: Double): Boolean;
var
  UnitType: TUnitType;
  FromLengthUnit, ToLengthUnit: TLengthUnit;
  FromMassUnit, ToMassUnit: TMassUnit;
  FromTimeUnit, ToTimeUnit: TTimeUnit;
  FromTemperatureUnit, ToTemperatureUnit: TTemperatureUnit;
  FromForceUnit, ToForceUnit: TForceUnit;
  FromEnergyUnit, ToEnergyUnit: TEnergyUnit;
  FromPowerUnit, ToPowerUnit: TPowerUnit;
  FromPressureUnit, ToPressureUnit: TPressureUnit;
  FromVelocityUnit, ToVelocityUnit: TVelocityUnit;
  FromAreaUnit, ToAreaUnit: TAreaUnit;
  FromVolumeUnit, ToVolumeUnit: TVolumeUnit;
  FromAngleUnit, ToAngleUnit: TAngleUnit;
  FromDensityUnit, ToDensityUnit: TDensityUnit;
  FromElectricalCurrentUnit, ToElectricalCurrentUnit: TElectricalCurrentUnit;
  FromElectricalPotentialUnit, ToElectricalPotentialUnit: TElectricalPotentialUnit;
  FromFrequencyUnit, ToFrequencyUnit: TFrequencyUnit;
begin
  Result := False;
  ConvertedValue := Value;
  
  if not AreUnitNamesCompatible(FromAUnitName, ToAUnitName) then
    Exit;
    
  UnitType := GetUnitTypeFromUnitName(FromAUnitName);
  
  case UnitType of
    utLength:
      begin
        if TryGetLengthUnitFromName(FromAUnitName, FromLengthUnit) and
           TryGetLengthUnitFromName(ToAUnitName, ToLengthUnit) then
        begin
          ConvertedValue := ConvertLength(Value, FromLengthUnit, ToLengthUnit);
          Result := True;
        end;
      end;
    utMass:
      begin
        if TryGetMassUnitFromName(FromAUnitName, FromMassUnit) and
           TryGetMassUnitFromName(ToAUnitName, ToMassUnit) then
        begin
          ConvertedValue := ConvertMass(Value, FromMassUnit, ToMassUnit);
          Result := True;
        end;
      end;
    utTime:
      begin
        if TryGetTimeUnitFromName(FromAUnitName, FromTimeUnit) and
           TryGetTimeUnitFromName(ToAUnitName, ToTimeUnit) then
        begin
          ConvertedValue := ConvertTime(Value, FromTimeUnit, ToTimeUnit);
          Result := True;
        end;
      end;
    utTemperature:
      begin
        if TryGetTemperatureUnitFromName(FromAUnitName, FromTemperatureUnit) and
           TryGetTemperatureUnitFromName(ToAUnitName, ToTemperatureUnit) then
        begin
          ConvertedValue := ConvertTemperature(Value, FromTemperatureUnit, ToTemperatureUnit);
          Result := True;
        end;
      end;
    utForce:
      begin
        if TryGetForceUnitFromName(FromAUnitName, FromForceUnit) and
           TryGetForceUnitFromName(ToAUnitName, ToForceUnit) then
        begin
          ConvertedValue := ConvertForce(Value, FromForceUnit, ToForceUnit);
          Result := True;
        end;
      end;
    utEnergy:
      begin
        if TryGetEnergyUnitFromName(FromAUnitName, FromEnergyUnit) and
           TryGetEnergyUnitFromName(ToAUnitName, ToEnergyUnit) then
        begin
          ConvertedValue := ConvertEnergy(Value, FromEnergyUnit, ToEnergyUnit);
          Result := True;
        end;
      end;
    utPower:
      begin
        if TryGetPowerUnitFromName(FromAUnitName, FromPowerUnit) and
           TryGetPowerUnitFromName(ToAUnitName, ToPowerUnit) then
        begin
          ConvertedValue := ConvertPower(Value, FromPowerUnit, ToPowerUnit);
          Result := True;
        end;
      end;
    utPressure:
      begin
        if TryGetPressureUnitFromName(FromAUnitName, FromPressureUnit) and
           TryGetPressureUnitFromName(ToAUnitName, ToPressureUnit) then
        begin
          ConvertedValue := ConvertPressure(Value, FromPressureUnit, ToPressureUnit);
          Result := True;
        end;
      end;
    utVelocity:
      begin
        if TryGetVelocityUnitFromName(FromAUnitName, FromVelocityUnit) and
           TryGetVelocityUnitFromName(ToAUnitName, ToVelocityUnit) then
        begin
          ConvertedValue := ConvertVelocity(Value, FromVelocityUnit, ToVelocityUnit);
          Result := True;
        end;
      end;
    utArea:
      begin
        if TryGetAreaUnitFromName(FromAUnitName, FromAreaUnit) and
           TryGetAreaUnitFromName(ToAUnitName, ToAreaUnit) then
        begin
          ConvertedValue := ConvertArea(Value, FromAreaUnit, ToAreaUnit);
          Result := True;
        end;
      end;
    utVolume:
      begin
        if TryGetVolumeUnitFromName(FromAUnitName, FromVolumeUnit) and
           TryGetVolumeUnitFromName(ToAUnitName, ToVolumeUnit) then
        begin
          ConvertedValue := ConvertVolume(Value, FromVolumeUnit, ToVolumeUnit);
          Result := True;
        end;
      end;
    utAngle:
      begin
        if TryGetAngleUnitFromName(FromAUnitName, FromAngleUnit) and
           TryGetAngleUnitFromName(ToAUnitName, ToAngleUnit) then
        begin
          ConvertedValue := ConvertAngle(Value, FromAngleUnit, ToAngleUnit);
          Result := True;
        end;
      end;
    utDensity:
      begin
        if TryGetDensityUnitFromName(FromAUnitName, FromDensityUnit) and
           TryGetDensityUnitFromName(ToAUnitName, ToDensityUnit) then
        begin
          ConvertedValue := ConvertDensity(Value, FromDensityUnit, ToDensityUnit);
          Result := True;
        end;
      end;
    utElectricalCurrent:
      begin
        if TryGetElectricalCurrentUnitFromName(FromAUnitName, FromElectricalCurrentUnit) and
           TryGetElectricalCurrentUnitFromName(ToAUnitName, ToElectricalCurrentUnit) then
        begin
          ConvertedValue := ConvertElectricalCurrent(Value, FromElectricalCurrentUnit, ToElectricalCurrentUnit);
          Result := True;
        end;
      end;
    utElectricalPotential:
      begin
        if TryGetElectricalPotentialUnitFromName(FromAUnitName, FromElectricalPotentialUnit) and
           TryGetElectricalPotentialUnitFromName(ToAUnitName, ToElectricalPotentialUnit) then
        begin
          ConvertedValue := ConvertElectricalPotential(Value, FromElectricalPotentialUnit, ToElectricalPotentialUnit);
          Result := True;
        end;
      end;
    utFrequency:
      begin
        if TryGetFrequencyUnitFromName(FromAUnitName, FromFrequencyUnit) and
           TryGetFrequencyUnitFromName(ToAUnitName, ToFrequencyUnit) then
        begin
          ConvertedValue := ConvertFrequency(Value, FromFrequencyUnit, ToFrequencyUnit);
          Result := True;
        end;
      end;
  end;
end;

class function TUnitConversionKit.GetUnitTypeFromUnitName(AUnitName: string): TUnitType;
begin
  // Length units
  if (AUnitName = 'm') or (AUnitName = 'km') or (AUnitName = 'cm') or (AUnitName = 'mm') or
     (AUnitName = 'μm') or (AUnitName = 'nm') or (AUnitName = 'mi') or (AUnitName = 'yd') or
     (AUnitName = 'ft') or (AUnitName = 'in') or (AUnitName = 'nmi') or (AUnitName = 'Å') or
     (AUnitName = 'ly') then
    Result := utLength
  // Mass units
  else if (AUnitName = 'kg') or (AUnitName = 'g') or (AUnitName = 'mg') or (AUnitName = 'μg') or
          (AUnitName = 't') or (AUnitName = 'lb') or (AUnitName = 'oz') or (AUnitName = 'st') or
          (AUnitName = 'US ton') or (AUnitName = 'imp ton') then
    Result := utMass
  // Time units
  else if (AUnitName = 's') or (AUnitName = 'min') or (AUnitName = 'h') or (AUnitName = 'd') or
          (AUnitName = 'wk') or (AUnitName = 'mo') or (AUnitName = 'yr') or (AUnitName = 'ms') or
          (AUnitName = 'μs') or (AUnitName = 'ns') then
    Result := utTime
  // Temperature units
  else if (AUnitName = 'K') or (AUnitName = '°C') or (AUnitName = '°F') or (AUnitName = '°R') or
          (AUnitName = '°Ré') then
    Result := utTemperature
  // Force units
  else if (AUnitName = 'N') or (AUnitName = 'kN') or (AUnitName = 'lbf') or (AUnitName = 'dyn') or
          (AUnitName = 'kgf') then
    Result := utForce
  // Energy units
  else if (AUnitName = 'J') or (AUnitName = 'kJ') or (AUnitName = 'cal') or (AUnitName = 'kcal') or
          (AUnitName = 'Wh') or (AUnitName = 'kWh') or (AUnitName = 'eV') or (AUnitName = 'BTU') or
          (AUnitName = 'therm') or (AUnitName = 'ft⋅lb') then
    Result := utEnergy
  // Power units
  else if (AUnitName = 'W') or (AUnitName = 'kW') or (AUnitName = 'MW') or (AUnitName = 'hp') or
          (AUnitName = 'BTU/h') then
    Result := utPower
  // Pressure units
  else if (AUnitName = 'Pa') or (AUnitName = 'kPa') or (AUnitName = 'bar') or (AUnitName = 'atm') or
          (AUnitName = 'Torr') or (AUnitName = 'psi') then
    Result := utPressure
  // Velocity units
  else if (AUnitName = 'm/s') or (AUnitName = 'km/h') or (AUnitName = 'mph') or (AUnitName = 'ft/s') or
          (AUnitName = 'kt') then
    Result := utVelocity
  // Area units
  else if (AUnitName = 'm²') or (AUnitName = 'km²') or (AUnitName = 'ha') or (AUnitName = 'a') or
          (AUnitName = 'mi²') or (AUnitName = 'acre') or (AUnitName = 'yd²') or (AUnitName = 'ft²') or
          (AUnitName = 'in²') then
    Result := utArea
  // Volume units
  else if (AUnitName = 'L') or (AUnitName = 'm³') or (AUnitName = 'mL') or (AUnitName = 'cm³') or
          (AUnitName = 'gal (US)') or (AUnitName = 'gal (UK)') or (AUnitName = 'fl oz (US)') or
          (AUnitName = 'fl oz (UK)') or (AUnitName = 'ft³') or (AUnitName = 'in³') then
    Result := utVolume
  // Angle units
  else if (AUnitName = '°') or (AUnitName = 'rad') or (AUnitName = 'grad') or (AUnitName = '′') or
          (AUnitName = '″') or (AUnitName = 'rev') then
    Result := utAngle
  // Density units
  else if (AUnitName = 'kg/m³') or (AUnitName = 'g/cm³') or (AUnitName = 'lb/ft³') or
          (AUnitName = 'lb/in³') then
    Result := utDensity
  // Electrical current units
  else if (AUnitName = 'A') or (AUnitName = 'mA') or (AUnitName = 'μA') then
    Result := utElectricalCurrent
  // Electrical potential units
  else if (AUnitName = 'V') or (AUnitName = 'kV') or (AUnitName = 'mV') or (AUnitName = 'μV') then
    Result := utElectricalPotential
  // Frequency units
  else if (AUnitName = 'Hz') or (AUnitName = 'kHz') or (AUnitName = 'MHz') or (AUnitName = 'GHz') or
          (AUnitName = 'cps') then
    Result := utFrequency
  else
    Result := utLength; // Default to length if unknown
end;

// Helper methods to get enum values from unit names
class function TUnitConversionKit.TryGetLengthUnitFromName(AUnitName: string; out Unit_: TLengthUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'm' then
    Unit_ := luMeter
  else if AUnitName = 'km' then
    Unit_ := luKilometer
  else if AUnitName = 'cm' then
    Unit_ := luCentimeter
  else if AUnitName = 'mm' then
    Unit_ := luMillimeter
  else if AUnitName = 'μm' then
    Unit_ := luMicrometer
  else if AUnitName = 'nm' then
    Unit_ := luNanometer
  else if AUnitName = 'mi' then
    Unit_ := luMile
  else if AUnitName = 'yd' then
    Unit_ := luYard
  else if AUnitName = 'ft' then
    Unit_ := luFoot
  else if AUnitName = 'in' then
    Unit_ := luInch
  else if AUnitName = 'nmi' then
    Unit_ := luNauticalMile
  else if AUnitName = 'Å' then
    Unit_ := luAngstrom
  else if AUnitName = 'ly' then
    Unit_ := luLightYear
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetMassUnitFromName(AUnitName: string; out Unit_: TMassUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'kg' then
    Unit_ := muKilogram
  else if AUnitName = 'g' then
    Unit_ := muGram
  else if AUnitName = 'mg' then
    Unit_ := muMilligram
  else if AUnitName = 'μg' then
    Unit_ := muMicrogram
  else if AUnitName = 't' then
    Unit_ := muTonne
  else if AUnitName = 'lb' then
    Unit_ := muPound
  else if AUnitName = 'oz' then
    Unit_ := muOunce
  else if AUnitName = 'st' then
    Unit_ := muStone
  else if AUnitName = 'US ton' then
    Unit_ := muUSton
  else if AUnitName = 'imp ton' then
    Unit_ := muImperialTon
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetTimeUnitFromName(AUnitName: string; out Unit_: TTimeUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 's' then
    Unit_ := tuSecond
  else if AUnitName = 'min' then
    Unit_ := tuMinute
  else if AUnitName = 'h' then
    Unit_ := tuHour
  else if AUnitName = 'd' then
    Unit_ := tuDay
  else if AUnitName = 'wk' then
    Unit_ := tuWeek
  else if AUnitName = 'mo' then
    Unit_ := tuMonth
  else if AUnitName = 'yr' then
    Unit_ := tuYear
  else if AUnitName = 'ms' then
    Unit_ := tuMillisecond
  else if AUnitName = 'μs' then
    Unit_ := tuMicrosecond
  else if AUnitName = 'ns' then
    Unit_ := tuNanosecond
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetTemperatureUnitFromName(AUnitName: string; out Unit_: TTemperatureUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'K' then
    Unit_ := tpKelvin
  else if AUnitName = '°C' then
    Unit_ := tpCelsius
  else if AUnitName = '°F' then
    Unit_ := tpFahrenheit
  else if AUnitName = '°R' then
    Unit_ := tpRankine
  else if AUnitName = '°Ré' then
    Unit_ := tpReaumur
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetForceUnitFromName(AUnitName: string; out Unit_: TForceUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'N' then
    Unit_ := fuNewton
  else if AUnitName = 'kN' then
    Unit_ := fuKilonewton
  else if AUnitName = 'lbf' then
    Unit_ := fuPoundForce
  else if AUnitName = 'dyn' then
    Unit_ := fuDyne
  else if AUnitName = 'kgf' then
    Unit_ := fuKilogramForce
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetEnergyUnitFromName(AUnitName: string; out Unit_: TEnergyUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'J' then
    Unit_ := euJoule
  else if AUnitName = 'kJ' then
    Unit_ := euKilojoule
  else if AUnitName = 'cal' then
    Unit_ := euCalorie
  else if AUnitName = 'kcal' then
    Unit_ := euKilocalorie
  else if AUnitName = 'Wh' then
    Unit_ := euWattHour
  else if AUnitName = 'kWh' then
    Unit_ := euKilowattHour
  else if AUnitName = 'eV' then
    Unit_ := euElectronvolt
  else if AUnitName = 'BTU' then
    Unit_ := euBTU
  else if AUnitName = 'therm' then
    Unit_ := euTherm
  else if AUnitName = 'ft⋅lb' then
    Unit_ := euFootPound
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetPowerUnitFromName(AUnitName: string; out Unit_: TPowerUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'W' then
    Unit_ := puWatt
  else if AUnitName = 'kW' then
    Unit_ := puKilowatt
  else if AUnitName = 'MW' then
    Unit_ := puMegawatt
  else if AUnitName = 'hp' then
    Unit_ := puHorsepower
  else if AUnitName = 'BTU/h' then
    Unit_ := puBTUPerHour
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetPressureUnitFromName(AUnitName: string; out Unit_: TPressureUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'Pa' then
    Unit_ := prPascal
  else if AUnitName = 'kPa' then
    Unit_ := prKilopascal
  else if AUnitName = 'bar' then
    Unit_ := prBar
  else if AUnitName = 'atm' then
    Unit_ := prAtmosphere
  else if AUnitName = 'Torr' then
    Unit_ := prTorr
  else if AUnitName = 'psi' then
    Unit_ := prPSI
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetVelocityUnitFromName(AUnitName: string; out Unit_: TVelocityUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'm/s' then
    Unit_ := vuMeterPerSecond
  else if AUnitName = 'km/h' then
    Unit_ := vuKilometerPerHour
  else if AUnitName = 'mph' then
    Unit_ := vuMilePerHour
  else if AUnitName = 'ft/s' then
    Unit_ := vuFootPerSecond
  else if AUnitName = 'kt' then
    Unit_ := vuKnot
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetAreaUnitFromName(AUnitName: string; out Unit_: TAreaUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'm²' then
    Unit_ := auSquareMeter
  else if AUnitName = 'km²' then
    Unit_ := auSquareKilometer
  else if AUnitName = 'ha' then
    Unit_ := auHectare
  else if AUnitName = 'a' then
    Unit_ := auAre
  else if AUnitName = 'mi²' then
    Unit_ := auSquareMile
  else if AUnitName = 'acre' then
    Unit_ := auAcre
  else if AUnitName = 'yd²' then
    Unit_ := auSquareYard
  else if AUnitName = 'ft²' then
    Unit_ := auSquareFoot
  else if AUnitName = 'in²' then
    Unit_ := auSquareInch
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetVolumeUnitFromName(AUnitName: string; out Unit_: TVolumeUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'L' then
    Unit_ := voLiter
  else if AUnitName = 'm³' then
    Unit_ := voCubicMeter
  else if AUnitName = 'mL' then
    Unit_ := voMilliliter
  else if AUnitName = 'cm³' then
    Unit_ := voCubicCentimeter
  else if AUnitName = 'gal (US)' then
    Unit_ := voGallonUS
  else if AUnitName = 'gal (UK)' then
    Unit_ := voGallonUK
  else if AUnitName = 'fl oz (US)' then
    Unit_ := voFluidOunceUS
  else if AUnitName = 'fl oz (UK)' then
    Unit_ := voFluidOunceUK
  else if AUnitName = 'ft³' then
    Unit_ := voCubicFoot
  else if AUnitName = 'in³' then
    Unit_ := voCubicInch
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetAngleUnitFromName(AUnitName: string; out Unit_: TAngleUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = '°' then
    Unit_ := anDegree
  else if AUnitName = 'rad' then
    Unit_ := anRadian
  else if AUnitName = 'grad' then
    Unit_ := anGradian
  else if AUnitName = '′' then
    Unit_ := anMinuteOfArc
  else if AUnitName = '″' then
    Unit_ := anSecondOfArc
  else if AUnitName = 'rev' then
    Unit_ := anRevolution
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetDensityUnitFromName(AUnitName: string; out Unit_: TDensityUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'kg/m³' then
    Unit_ := deKilogramPerCubicMeter
  else if AUnitName = 'g/cm³' then
    Unit_ := deGramPerCubicCentimeter
  else if AUnitName = 'lb/ft³' then
    Unit_ := dePoundPerCubicFoot
  else if AUnitName = 'lb/in³' then
    Unit_ := dePoundPerCubicInch
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetElectricalCurrentUnitFromName(AUnitName: string; out Unit_: TElectricalCurrentUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'A' then
    Unit_ := ecAmpere
  else if AUnitName = 'mA' then
    Unit_ := ecMilliampere
  else if AUnitName = 'μA' then
    Unit_ := ecMicroampere
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetElectricalPotentialUnitFromName(AUnitName: string; out Unit_: TElectricalPotentialUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'V' then
    Unit_ := epVolt
  else if AUnitName = 'kV' then
    Unit_ := epKilovolt
  else if AUnitName = 'mV' then
    Unit_ := epMillivolt
  else if AUnitName = 'μV' then
    Unit_ := epMicrovolt
  else
    Result := False;
end;

class function TUnitConversionKit.TryGetFrequencyUnitFromName(AUnitName: string; out Unit_: TFrequencyUnit): Boolean;
begin
  Result := True;
  
  if AUnitName = 'Hz' then
    Unit_ := frHertz
  else if AUnitName = 'kHz' then
    Unit_ := frKilohertz
  else if AUnitName = 'MHz' then
    Unit_ := frMegahertz
  else if AUnitName = 'GHz' then
    Unit_ := frGigahertz
  else if AUnitName = 'cps' then
    Unit_ := frCyclePerSecond
  else
    Result := False;
end;

class function TUnitConversionKit.TryParseValueWithUnit(const ValueStr: string; out Value: Double;
  out AUnitName: string): Boolean;
var
  S: string;
  StartPos: Integer;
begin
  Result := False;
  S := Trim(ValueStr);
  
  // Find where the number ends and unit begins
  StartPos := 1;
  while (StartPos <= Length(S)) and 
        ((S[StartPos] in ['0'..'9', '.', '-', '+', 'e', 'E']) or 
         ((S[StartPos] = 'e') and (StartPos < Length(S)) and (S[StartPos+1] in ['+', '-']))) do
    Inc(StartPos);
    
  if StartPos > 1 then
  begin
    if not TryStrToFloat(Trim(Copy(S, 1, StartPos-1)), Value) then
      Exit;
      
    AUnitName := Trim(Copy(S, StartPos, Length(S)));
    Result := AUnitName <> '';
  end;
end;

class function TUnitConversionKit.TryParseAndConvert(const ValueStr, ToAUnitName: string;
  out ConvertedValue: Double): Boolean;
var
  Value: Double;
  FromAUnitName: string;
begin
  Result := False;
  ConvertedValue := 0;
  
  if TryParseValueWithUnit(ValueStr, Value, FromAUnitName) then
    Result := TryConvertByUnitName(Value, FromAUnitName, ToAUnitName, ConvertedValue);
end;

class function TUnitConversionKit.AreUnitsCompatible(UnitType1, UnitType2: TUnitType): Boolean;
begin
  Result := UnitType1 = UnitType2;
end;

class function TUnitConversionKit.AreUnitNamesCompatible(AUnitName1, AUnitName2: string): Boolean;
var
  UnitType1, UnitType2: TUnitType;
begin
  UnitType1 := GetUnitTypeFromUnitName(AUnitName1);
  UnitType2 := GetUnitTypeFromUnitName(AUnitName2);
  Result := AreUnitsCompatible(UnitType1, UnitType2);
end;

class function TUnitConversionKit.GetAllUnitsOfType(UnitType: TUnitType): TStringArray;
var
  I: Integer;
begin
  case UnitType of
    utLength:
      begin
        SetLength(Result, Ord(High(TLengthUnit)) + 1);
        for I := Ord(Low(TLengthUnit)) to Ord(High(TLengthUnit)) do
          Result[I] := GetLengthUnitName(TLengthUnit(I));
      end;
    utMass:
      begin
        SetLength(Result, Ord(High(TMassUnit)) + 1);
        for I := Ord(Low(TMassUnit)) to Ord(High(TMassUnit)) do
          Result[I] := GetMassUnitName(TMassUnit(I));
      end;
    utTime:
      begin
        SetLength(Result, Ord(High(TTimeUnit)) + 1);
        for I := Ord(Low(TTimeUnit)) to Ord(High(TTimeUnit)) do
          Result[I] := GetTimeUnitName(TTimeUnit(I));
      end;
    utTemperature:
      begin
        SetLength(Result, Ord(High(TTemperatureUnit)) + 1);
        for I := Ord(Low(TTemperatureUnit)) to Ord(High(TTemperatureUnit)) do
          Result[I] := GetTemperatureUnitName(TTemperatureUnit(I));
      end;
    utForce:
      begin
        SetLength(Result, Ord(High(TForceUnit)) + 1);
        for I := Ord(Low(TForceUnit)) to Ord(High(TForceUnit)) do
          Result[I] := GetForceUnitName(TForceUnit(I));
      end;
    utEnergy:
      begin
        SetLength(Result, Ord(High(TEnergyUnit)) + 1);
        for I := Ord(Low(TEnergyUnit)) to Ord(High(TEnergyUnit)) do
          Result[I] := GetEnergyUnitName(TEnergyUnit(I));
      end;
    utPower:
      begin
        SetLength(Result, Ord(High(TPowerUnit)) + 1);
        for I := Ord(Low(TPowerUnit)) to Ord(High(TPowerUnit)) do
          Result[I] := GetPowerUnitName(TPowerUnit(I));
      end;
    utPressure:
      begin
        SetLength(Result, Ord(High(TPressureUnit)) + 1);
        for I := Ord(Low(TPressureUnit)) to Ord(High(TPressureUnit)) do
          Result[I] := GetPressureUnitName(TPressureUnit(I));
      end;
    utVelocity:
      begin
        SetLength(Result, Ord(High(TVelocityUnit)) + 1);
        for I := Ord(Low(TVelocityUnit)) to Ord(High(TVelocityUnit)) do
          Result[I] := GetVelocityUnitName(TVelocityUnit(I));
      end;
    utArea:
      begin
        SetLength(Result, Ord(High(TAreaUnit)) + 1);
        for I := Ord(Low(TAreaUnit)) to Ord(High(TAreaUnit)) do
          Result[I] := GetAreaUnitName(TAreaUnit(I));
      end;
    utVolume:
      begin
        SetLength(Result, Ord(High(TVolumeUnit)) + 1);
        for I := Ord(Low(TVolumeUnit)) to Ord(High(TVolumeUnit)) do
          Result[I] := GetVolumeUnitName(TVolumeUnit(I));
      end;
    utAngle:
      begin
        SetLength(Result, Ord(High(TAngleUnit)) + 1);
        for I := Ord(Low(TAngleUnit)) to Ord(High(TAngleUnit)) do
          Result[I] := GetAngleUnitName(TAngleUnit(I));
      end;
    utDensity:
      begin
        SetLength(Result, Ord(High(TDensityUnit)) + 1);
        for I := Ord(Low(TDensityUnit)) to Ord(High(TDensityUnit)) do
          Result[I] := GetDensityUnitName(TDensityUnit(I));
      end;
    utElectricalCurrent:
      begin
        SetLength(Result, Ord(High(TElectricalCurrentUnit)) + 1);
        for I := Ord(Low(TElectricalCurrentUnit)) to Ord(High(TElectricalCurrentUnit)) do
          Result[I] := GetElectricalCurrentUnitName(TElectricalCurrentUnit(I));
      end;
    utElectricalPotential:
      begin
        SetLength(Result, Ord(High(TElectricalPotentialUnit)) + 1);
        for I := Ord(Low(TElectricalPotentialUnit)) to Ord(High(TElectricalPotentialUnit)) do
          Result[I] := GetElectricalPotentialUnitName(TElectricalPotentialUnit(I));
      end;
    utFrequency:
      begin
        SetLength(Result, Ord(High(TFrequencyUnit)) + 1);
        for I := Ord(Low(TFrequencyUnit)) to Ord(High(TFrequencyUnit)) do
          Result[I] := GetFrequencyUnitName(TFrequencyUnit(I));
      end;
    else
      SetLength(Result, 0);
  end;
end;

class function TUnitConversionKit.GetAllUnitTypes: TStringArray;
begin
  SetLength(Result, Ord(High(TUnitType)) + 1);
  Result[Ord(utLength)] := 'Length';
  Result[Ord(utMass)] := 'Mass';
  Result[Ord(utTime)] := 'Time';
  Result[Ord(utTemperature)] := 'Temperature';
  Result[Ord(utForce)] := 'Force';
  Result[Ord(utEnergy)] := 'Energy';
  Result[Ord(utPower)] := 'Power';
  Result[Ord(utPressure)] := 'Pressure';
  Result[Ord(utVelocity)] := 'Velocity';
  Result[Ord(utArea)] := 'Area';
  Result[Ord(utVolume)] := 'Volume';
  Result[Ord(utAngle)] := 'Angle';
  Result[Ord(utDensity)] := 'Density';
  Result[Ord(utElectricalCurrent)] := 'Electrical Current';
  Result[Ord(utElectricalPotential)] := 'Electrical Potential';
  Result[Ord(utFrequency)] := 'Frequency';
end;

class function TUnitConversionKit.GetBaseUnit(UnitType: TUnitType): string;
begin
  case UnitType of
    utLength: Result := GetLengthUnitName(luMeter);
    utMass: Result := GetMassUnitName(muKilogram);
    utTime: Result := GetTimeUnitName(tuSecond);
    utTemperature: Result := GetTemperatureUnitName(tpKelvin);
    utForce: Result := GetForceUnitName(fuNewton);
    utEnergy: Result := GetEnergyUnitName(euJoule);
    utPower: Result := GetPowerUnitName(puWatt);
    utPressure: Result := GetPressureUnitName(prPascal);
    utVelocity: Result := GetVelocityUnitName(vuMeterPerSecond);
    utArea: Result := GetAreaUnitName(auSquareMeter);
    utVolume: Result := GetVolumeUnitName(voCubicMeter);
    utAngle: Result := GetAngleUnitName(anRadian);
    utDensity: Result := GetDensityUnitName(deKilogramPerCubicMeter);
    utElectricalCurrent: Result := GetElectricalCurrentUnitName(ecAmpere);
    utElectricalPotential: Result := GetElectricalPotentialUnitName(epVolt);
    utFrequency: Result := GetFrequencyUnitName(frHertz);
    else Result := '';
  end;
end;

class function TUnitConversionKit.MilesToKilometers(Miles: Double): Double;
begin
  Result := ConvertLength(Miles, luMile, luKilometer);
end;

class function TUnitConversionKit.KilometersToMiles(Kilometers: Double): Double;
begin
  Result := ConvertLength(Kilometers, luKilometer, luMile);
end;

class function TUnitConversionKit.PoundsToKilograms(Pounds: Double): Double;
begin
  Result := ConvertMass(Pounds, muPound, muKilogram);
end;

class function TUnitConversionKit.KilogramsToPounds(Kilograms: Double): Double;
begin
  Result := ConvertMass(Kilograms, muKilogram, muPound);
end;

class function TUnitConversionKit.CelsiusToFahrenheit(Celsius: Double): Double;
begin
  Result := ConvertTemperature(Celsius, tpCelsius, tpFahrenheit);
end;

class function TUnitConversionKit.FahrenheitToCelsius(Fahrenheit: Double): Double;
begin
  Result := ConvertTemperature(Fahrenheit, tpFahrenheit, tpCelsius);
end;

end.
