# pascal-mathlibs.Engineering.UnitConversion

pascal-mathlibs's `UnitConversion` module provides comprehensive unit conversion capabilities across multiple physical dimensions, making it easy to convert between different measurement units in engineering and scientific applications.

## Overview

The `TUnitConversionKit` class offers a versatile set of tools for unit conversion, with support for 16 different physical quantities including length, mass, temperature, pressure, and more. It provides both direct conversions between defined unit types and string-based conversions for more flexible use.

## Features

- Conversion between units for 16 different physical quantities
- String-based unit conversion using unit names
- Scientific notation formatting
- Unit compatibility checking
- Base unit identification
- Common conversion shortcuts

## Getting Started

To use the unit conversion library, add the `pascal-mathlibs.Engineering.UnitConversion` unit to your uses clause:

```pascal
uses
  pascal-mathlibs.Engineering.UnitConversion;
```

Then you can access all conversion methods through the `TUnitConversionKit` class:

```pascal
// Convert 5 kilometers to miles
var
  Miles: Double;
begin
  Miles := TUnitConversionKit.ConvertLength(5, luKilometer, luMile);
  // or use the shortcut method:
  Miles := TUnitConversionKit.KilometersToMiles(5);
end;
```

## Working with Units

### Available Physical Quantities

The library supports conversion between units in the following physical dimensions:

- Length
- Mass
- Time
- Temperature
- Force
- Energy
- Power
- Pressure
- Velocity
- Area
- Volume
- Angle
- Density
- Electrical Current
- Electrical Potential
- Frequency

### Converting Between Units

Each physical quantity has its own conversion method in the format `ConvertXXX`:

```pascal
// Convert 100 degrees Celsius to Fahrenheit
var
  TempF: Double;
begin
  TempF := TUnitConversionKit.ConvertTemperature(100, tpCelsius, tpFahrenheit);
  // Result: TempF = 212.0
end;

// Convert 1 atmosphere to kilopascals
var 
  Pressure: Double;
begin
  Pressure := TUnitConversionKit.ConvertPressure(1, prAtmosphere, prKilopascal);
  // Result: Pressure = 101.325
end;
```

### Common Conversion Shortcuts

For frequently used conversions, the library provides convenient shortcut methods:

```pascal
var
  Kilograms: Double;
  Fahrenheit: Double;
begin
  Kilograms := TUnitConversionKit.PoundsToKilograms(10);
  Fahrenheit := TUnitConversionKit.CelsiusToFahrenheit(25);
end;
```

Available shortcuts:
- `MilesToKilometers`
- `KilometersToMiles`
- `PoundsToKilograms`
- `KilogramsToPounds`
- `CelsiusToFahrenheit`
- `FahrenheitToCelsius`

### Significant Digits and Rounding

When presenting numerical results, controlling the precision is important. TUnitConversionKit provides functions for rounding values to a specific number of significant digits:

```pascal
var
  RoundedValue: Double;
begin
  // Round 123.456 to 3 significant digits
  RoundedValue := TUnitConversionKit.RoundToSignificantDigits(123.456, 3);
  // Result: 123.0
  
  // Round 0.0123456 to 3 significant digits
  RoundedValue := TUnitConversionKit.RoundToSignificantDigits(0.0123456, 3);
  // Result: 0.0123
end;
```

This is particularly useful when working with physical measurements where a specific number of significant digits is required based on the precision of measurement instruments.

## String-Based Unit Conversion

The library also supports converting between units using their string names:

```pascal
var
  Result: Double;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryConvertByUnitName(10, 'km', 'mi', Result);
  if Success then
    WriteLn('10 kilometers = ', Result:0:2, ' miles');
end;
```

### Parsing Values with Units

You can parse a string that contains both a value and a unit:

```pascal
var
  Value: Double;
  UnitName: string;
begin
  if TUnitConversionKit.TryParseValueWithUnit('25.4 mm', Value, UnitName) then
    WriteLn('Parsed value: ', Value, ' ', UnitName);
end;
```

### Parse and Convert in One Step

You can also parse a string with a value and unit, and convert it to another unit in one step:

```pascal
var
  ConvertedValue: Double;
begin
  if TUnitConversionKit.TryParseAndConvert('100 °C', '°F', ConvertedValue) then
    WriteLn('100 °C = ', ConvertedValue:0:1, ' °F');
end;
```

## Formatting with Units

### Basic Formatting

Format a value with its unit name:

```pascal
var
  FormattedValue: string;
begin
  FormattedValue := TUnitConversionKit.FormatWithUnit(1.23456, 'm', 2);
  // Result: "1.23 m"
end;
```

### Scientific Notation

Format a value using scientific notation:

```pascal
var
  FormattedValue: string;
begin
  FormattedValue := TUnitConversionKit.FormatWithScientificNotation(1.23456e6, 'W', 3);
  // Result: "1.23 × 10^6 W"
end;
```

## Unit Information

### Getting All Units of a Type

Get all available units for a specific physical quantity:

```pascal
var
  LengthUnits: TStringArray;
  I: Integer;
begin
  LengthUnits := TUnitConversionKit.GetAllUnitsOfType(utLength);
  WriteLn('Available length units:');
  for I := 0 to High(LengthUnits) do
    WriteLn('- ', LengthUnits[I]);
end;
```

### Getting the Base Unit

Get the base unit (SI unit) for a physical quantity:

```pascal
var
  BaseUnit: string;
begin
  BaseUnit := TUnitConversionKit.GetBaseUnit(utLength);
  // Result: "m" (meter)
end;
```

### Checking Unit Compatibility

Check if two units are compatible (i.e., they measure the same physical quantity):

```pascal
var
  IsCompatible: Boolean;
begin
  IsCompatible := TUnitConversionKit.AreUnitNamesCompatible('m', 'ft');
  // Result: True (both are length units)
  
  IsCompatible := TUnitConversionKit.AreUnitNamesCompatible('m', 'kg');
  // Result: False (length is incompatible with mass)
end;
```

## Error Handling

Most standard conversion functions (like `ConvertLength`, `ConvertMass`) perform direct calculations and do not report errors. However, string-based functions provide error feedback:

- `TryConvertByUnitName`: Returns False if units are incompatible or not recognized
- `TryParseValueWithUnit`: Returns False if the input string cannot be parsed
- `TryParseAndConvert`: Returns False if parsing fails or units are incompatible

Always check the Boolean result when using these functions:

```pascal
var
  Result: Double;
  Success: Boolean;
begin
  Success := TUnitConversionKit.TryParseAndConvert('100 K', '°C', Result);
  if Success then
    WriteLn('Converted value: ', Result:0:2, ' °C')
  else
    WriteLn('Conversion failed!');
end;
```

## Complete Unit List

Below is a complete list of all supported units by physical quantity:

### Length Units (TLengthUnit)
- `luMeter` (m)
- `luKilometer` (km)
- `luCentimeter` (cm)
- `luMillimeter` (mm)
- `luMicrometer` (μm)
- `luNanometer` (nm)
- `luMile` (mi)
- `luYard` (yd)
- `luFoot` (ft)
- `luInch` (in)
- `luNauticalMile` (nmi)
- `luAngstrom` (Å)
- `luLightYear` (ly)

### Mass Units (TMassUnit)
- `muKilogram` (kg)
- `muGram` (g)
- `muMilligram` (mg)
- `muMicrogram` (μg)
- `muTonne` (t)
- `muPound` (lb)
- `muOunce` (oz)
- `muStone` (st)
- `muUSton` (US ton)
- `muImperialTon` (imp ton)

### Temperature Units (TTemperatureUnit)
- `tpKelvin` (K)
- `tpCelsius` (°C)
- `tpFahrenheit` (°F)
- `tpRankine` (°R)
- `tpReaumur` (°Ré)

### Time Units (TTimeUnit)
- `tuSecond` (s)
- `tuMinute` (min)
- `tuHour` (h)
- `tuDay` (d)
- `tuWeek` (wk)
- `tuMonth` (mo)
- `tuYear` (yr)
- `tuMillisecond` (ms)
- `tuMicrosecond` (μs)
- `tuNanosecond` (ns)

### Force Units (TForceUnit)
- `fuNewton` (N)
- `fuKilonewton` (kN)
- `fuPoundForce` (lbf)
- `fuDyne` (dyn)
- `fuKilogramForce` (kgf)

### Energy Units (TEnergyUnit)
- `euJoule` (J)
- `euKilojoule` (kJ)
- `euCalorie` (cal)
- `euKilocalorie` (kcal)
- `euWattHour` (Wh)
- `euKilowattHour` (kWh)
- `euElectronvolt` (eV)
- `euBTU` (BTU)
- `euTherm` (therm)
- `euFootPound` (ft⋅lb)

### Power Units (TPowerUnit)
- `puWatt` (W)
- `puKilowatt` (kW)
- `puMegawatt` (MW)
- `puHorsepower` (hp)
- `puBTUPerHour` (BTU/h)

### Pressure Units (TPressureUnit)
- `prPascal` (Pa)
- `prKilopascal` (kPa)
- `prBar` (bar)
- `prAtmosphere` (atm)
- `prTorr` (Torr)
- `prPSI` (psi)

### Velocity Units (TVelocityUnit)
- `vuMeterPerSecond` (m/s)
- `vuKilometerPerHour` (km/h)
- `vuMilePerHour` (mph)
- `vuFootPerSecond` (ft/s)
- `vuKnot` (kt)

### Area Units (TAreaUnit)
- `auSquareMeter` (m²)
- `auSquareKilometer` (km²)
- `auHectare` (ha)
- `auAre` (a)
- `auSquareMile` (mi²)
- `auAcre` (acre)
- `auSquareYard` (yd²)
- `auSquareFoot` (ft²)
- `auSquareInch` (in²)

### Volume Units (TVolumeUnit)
- `voLiter` (L)
- `voCubicMeter` (m³)
- `voMilliliter` (mL)
- `voCubicCentimeter` (cm³)
- `voGallonUS` (gal (US))
- `voGallonUK` (gal (UK))
- `voFluidOunceUS` (fl oz (US))
- `voFluidOunceUK` (fl oz (UK))
- `voCubicFoot` (ft³)
- `voCubicInch` (in³)

### Angle Units (TAngleUnit)
- `anDegree` (°)
- `anRadian` (rad)
- `anGradian` (grad)
- `anMinuteOfArc` (′)
- `anSecondOfArc` (″)
- `anRevolution` (rev)

### Density Units (TDensityUnit)
- `deKilogramPerCubicMeter` (kg/m³)
- `deGramPerCubicCentimeter` (g/cm³)
- `dePoundPerCubicFoot` (lb/ft³)
- `dePoundPerCubicInch` (lb/in³)

### Electrical Current Units (TElectricalCurrentUnit)
- `ecAmpere` (A)
- `ecMilliampere` (mA)
- `ecMicroampere` (μA)

### Electrical Potential Units (TElectricalPotentialUnit)
- `epVolt` (V)
- `epKilovolt` (kV)
- `epMillivolt` (mV)
- `epMicrovolt` (μV)

### Frequency Units (TFrequencyUnit)
- `frHertz` (Hz)
- `frKilohertz` (kHz)
- `frMegahertz` (MHz)
- `frGigahertz` (GHz)
- `frCyclePerSecond` (cps)

## Performance Considerations

For high-performance applications requiring numerous conversions:

1. Use the direct enum-based methods (`ConvertLength`, etc.) rather than string-based methods when possible
2. Cache the results of `GetAllUnitsOfType` rather than calling it repeatedly
3. For temperature conversions (which involve more calculation steps), consider caching results when converting many values between the same units

## Example Applications

### Engineering Calculations

```pascal
var
  Force, Mass, Acceleration: Double;
begin
  // F = m * a
  Mass := 50; // kg
  Acceleration := 9.81; // m/s²
  
  // Calculate force in Newtons
  Force := Mass * Acceleration;
  
  // Convert to pound-force
  WriteLn('Force: ', TUnitConversionKit.FormatWithUnit(Force, 'N'));
  WriteLn('Force: ', TUnitConversionKit.FormatWithUnit(
    TUnitConversionKit.ConvertForce(Force, fuNewton, fuPoundForce), 'lbf'));
end;
```

### Temperature Converter App

```pascal
var
  TempC, TempF, TempK: Double;
begin
  Write('Enter temperature in Celsius: ');
  ReadLn(TempC);
  
  TempF := TUnitConversionKit.CelsiusToFahrenheit(TempC);
  TempK := TUnitConversionKit.ConvertTemperature(TempC, tpCelsius, tpKelvin);
  
  WriteLn(TUnitConversionKit.FormatWithUnit(TempC, '°C'), ' = ');
  WriteLn('  ', TUnitConversionKit.FormatWithUnit(TempF, '°F'));
  WriteLn('  ', TUnitConversionKit.FormatWithUnit(TempK, 'K'));
end;
```

### Scientific Data Processing

```pascal
var
  Frequency: Double;
  FormattedValue: string;
begin
  Frequency := 2.45e9; // 2.45 GHz
  
  // Format with scientific notation
  FormattedValue := TUnitConversionKit.FormatWithScientificNotation(Frequency, 'Hz', 3);
  WriteLn('Frequency: ', FormattedValue);
  
  // Convert to MHz
  Frequency := TUnitConversionKit.ConvertFrequency(Frequency, frHertz, frMegahertz);
  WriteLn('Frequency: ', Frequency:0:0, ' MHz');
end;
```

## Implementation Details

### Unit Conversion Strategy

The library uses a two-step conversion strategy for most unit types:

1. Convert from the source unit to a base unit (e.g., meters for length)
2. Convert from the base unit to the target unit

This approach simplifies the implementation by requiring only N conversion factors for N units, rather than N² direct conversions between all possible unit pairs.

### Special Case: Temperature

Unlike other unit types, temperature units don't have simple scaling relationships. Converting between temperature scales requires both multiplication/division and addition/subtraction. The library handles this by:

1. First converting the input value to Kelvin (the base unit)
2. Then converting from Kelvin to the target unit

### Working with Unicode Characters

Some unit symbols use Unicode characters (e.g., μ, °, ²). When displaying these in console applications or environments with limited Unicode support, you might need to use alternative representations.

## Future Extensions

The unit conversion framework is designed to be extensible. If you need to add support for additional unit types or specific units:

1. Add new unit types to the `TUnitType` enumeration
2. Create a new unit-specific enumeration (e.g., `TNewUnitType`)
3. Add conversion factors and implement the `ConvertNewUnitType` method
4. Add name conversion with `GetNewUnitTypeName` and `TryGetNewUnitTypeFromName`
5. Update the string-based methods to support the new unit type

## Conclusion

The pascal-mathlibs Unit Conversion library provides a comprehensive solution for handling unit conversions in engineering and scientific applications. With support for 16 physical quantities and numerous units for each, it covers most needs for technical calculations while providing both enum-based and string-based interfaces for flexibility.
