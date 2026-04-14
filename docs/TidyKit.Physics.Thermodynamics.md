# pascal-mathlibs Physics: Thermodynamics Library

The `pascal-mathlibs.Physics.Thermodynamics` module provides comprehensive functionality for thermodynamic calculations, including heat transfer, entropy, ideal gas law, phase transitions, efficiency metrics, thermodynamic cycles, and psychrometrics.

## Overview

`TThermodynamicsKit` is a static class providing a wide range of thermodynamic calculations commonly used in engineering applications. The library includes physical constants and numerous methods for specialized thermodynamic calculations.

## Constants

The library provides the following physical constants:

```pascal
const
  BoltzmannConstant = 1.380649E-23; // J/K
  StefanBoltzmannConstant = 5.670374419E-8; // W/(m²·K⁴)
  IdealGasConstant = 8.314462618; // J/(mol·K)
  AvogadroConstant = 6.02214076E23; // mol⁻¹
  StandardAtmosphere = 101325; // Pa
  StandardTempK = 273.15; // 0°C in K
```

## Heat Transfer

Calculate heat transfer rates through different mechanisms:

```pascal
// Heat conduction rate: Q = k * A * (T_hot - T_cold) / d
conductionRate := TThermodynamicsKit.HeatConductionRate(
  thermalConductivity, // W/(m·K)
  area,                // m²
  tempDifference,      // K
  thickness            // m
);

// Heat convection rate: Q = h * A * (T_surface - T_fluid)
convectionRate := TThermodynamicsKit.HeatConvectionRate(
  convectionCoefficient, // W/(m²·K)
  area,                  // m²
  tempDifference         // K
);

// Heat radiation rate: Q = ε * σ * A * (T_surface⁴ - T_surroundings⁴)
radiationRate := TThermodynamicsKit.HeatRadiationRate(
  emissivity,          // Dimensionless (0-1)
  area,                // m²
  surfaceTempK,        // K
  surroundingsTempK    // K
);

// Heat energy change: Q = m * c * ΔT
heatEnergy := TThermodynamicsKit.HeatEnergyChange(
  mass,                // kg
  specificHeatCapacity,// J/(kg·K)
  tempChange           // K
);
```

## Entropy

Calculate entropy changes in different processes:

```pascal
// Entropy change in a reversible process: ΔS = Q / T
entropyChange1 := TThermodynamicsKit.EntropyChangeReversible(
  heatTransfer,        // J
  absoluteTempK        // K
);

// Entropy change during heating: ΔS = m * c * ln(T_final / T_initial)
entropyChange2 := TThermodynamicsKit.EntropyChangeHeating(
  mass,                // kg
  specificHeatCapacity,// J/(kg·K)
  initialTempK,        // K
  finalTempK           // K
);

// Entropy change during isothermal expansion: ΔS = n * R * ln(V_final / V_initial)
entropyChange3 := TThermodynamicsKit.EntropyChangeIsothermalExpansion(
  moles,               // mol
  initialVolume,       // m³
  finalVolume          // m³
);
```

## Ideal Gas Law

Calculate properties of an ideal gas (P·V = n·R·T):

```pascal
// Calculate pressure: P = n·R·T / V
pressure := TThermodynamicsKit.IdealGasPressure(
  moles,               // mol
  volume,              // m³
  absoluteTempK        // K
);

// Calculate volume: V = n·R·T / P
volume := TThermodynamicsKit.IdealGasVolume(
  moles,               // mol
  pressure,            // Pa
  absoluteTempK        // K
);

// Calculate temperature: T = P·V / (n·R)
temperature := TThermodynamicsKit.IdealGasTemperature(
  pressure,            // Pa
  volume,              // m³
  moles                // mol
);

// Calculate number of moles: n = P·V / (R·T)
moles := TThermodynamicsKit.IdealGasMoles(
  pressure,            // Pa
  volume,              // m³
  absoluteTempK        // K
);
```

## Phase Transitions

Calculate heat required for phase changes:

```pascal
// Heat required for melting/freezing: Q = m * L
fusionHeat := TThermodynamicsKit.HeatOfFusion(
  mass,                // kg
  latentHeatOfFusion   // J/kg
);

// Heat required for vaporization/condensation: Q = m * L
vaporizationHeat := TThermodynamicsKit.HeatOfVaporization(
  mass,                // kg
  latentHeatOfVaporization // J/kg
);
```

## Efficiency Metrics

Calculate various efficiency metrics:

```pascal
// Carnot efficiency: η = 1 - (T_cold / T_hot)
carnotEfficiency := TThermodynamicsKit.CarnotEfficiency(
  hotTempK,            // K
  coldTempK            // K
);

// Thermal efficiency: η = Work_out / Heat_in
thermalEfficiency := TThermodynamicsKit.ThermalEfficiency(
  workOutput,          // J
  heatInput            // J
);

// Coefficient of Performance (refrigeration): COP = Q_cold / Work_in
copRefrigeration := TThermodynamicsKit.CoefficientOfPerformanceRefrigeration(
  coldHeatExtracted,   // J
  workInput            // J
);

// Coefficient of Performance (heat pump): COP = Q_hot / Work_in
copHeatPump := TThermodynamicsKit.CoefficientOfPerformanceHeatPump(
  hotHeatDelivered,    // J
  workInput            // J
);
```

## Thermodynamic Cycles

Calculate efficiency of various thermodynamic cycles:

```pascal
// Otto cycle efficiency (ideal spark-ignition engine): η = 1 - (1/r^(γ-1))
ottoEfficiency := TThermodynamicsKit.OttoCycleEfficiency(
  compressionRatio,    // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Diesel cycle efficiency (ideal compression-ignition engine)
dieselEfficiency := TThermodynamicsKit.DieselCycleEfficiency(
  compressionRatio,    // Dimensionless
  cutoffRatio,         // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Brayton cycle efficiency (ideal gas turbine engine): η = 1 - (1/r^((γ-1)/γ))
braytonEfficiency := TThermodynamicsKit.BraytonCycleEfficiency(
  pressureRatio,       // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Rankine cycle efficiency: η = (W_turbine - W_pump) / Q_in
rankineEfficiency := TThermodynamicsKit.RankineCycleEfficiency(
  turbineWorkOutput,   // J
  pumpWorkInput,       // J
  heatInput            // J
);
```

## Adiabatic Processes

Calculate properties in adiabatic processes (PV^γ = constant):

```pascal
// Calculate final pressure: P2 = P1 * (V1/V2)^γ
finalPressure := TThermodynamicsKit.AdiabaticPressure(
  initialPressure,     // Pa
  initialVolume,       // m³
  finalVolume,         // m³
  specificHeatRatio    // Dimensionless (γ)
);

// Calculate final volume: V2 = V1 * (P1/P2)^(1/γ)
finalVolume := TThermodynamicsKit.AdiabaticVolume(
  initialPressure,     // Pa
  initialVolume,       // m³
  finalPressure,       // Pa
  specificHeatRatio    // Dimensionless (γ)
);

// Calculate final temperature: T2 = T1 * (V1/V2)^(γ-1)
finalTemperature1 := TThermodynamicsKit.AdiabaticTemperature(
  initialTemp,         // K
  initialVolume,       // m³
  finalVolume,         // m³
  specificHeatRatio    // Dimensionless (γ)
);

// Calculate final temperature: T2 = T1 * (P2/P1)^((γ-1)/γ)
finalTemperature2 := TThermodynamicsKit.AdiabaticTemperatureFromPressure(
  initialTemp,         // K
  initialPressure,     // Pa
  finalPressure,       // Pa
  specificHeatRatio    // Dimensionless (γ)
);
```

## Compressible Flow

Calculate properties of compressible flow:

```pascal
// Critical pressure ratio for choked flow: p*/p0 = (2/(γ+1))^(γ/(γ-1))
criticalPressureRatio := TThermodynamicsKit.CriticalPressureRatio(
  specificHeatRatio    // Dimensionless (γ)
);

// Calculate Mach number from pressure ratio
machNumber := TThermodynamicsKit.MachNumberFromPressureRatio(
  pressureRatio,       // Dimensionless (p/p0)
  specificHeatRatio    // Dimensionless (γ)
);

// Isentropic temperature ratio: T0/T = 1 + ((γ-1)/2)*M²
tempRatio := TThermodynamicsKit.IsentropicTemperatureRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Isentropic pressure ratio: p/p0 = (1 + ((γ-1)/2)*M²)^(-γ/(γ-1))
pressRatio := TThermodynamicsKit.IsentropicPressureRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Isentropic density ratio: ρ/ρ0 = (1 + ((γ-1)/2)*M²)^(-1/(γ-1))
densityRatio := TThermodynamicsKit.IsentropicDensityRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);
```

## Psychrometrics

Calculate properties of moist air:

```pascal
// Relative humidity: φ = (Pv / Pvs) * 100%
relativeHumidity := TThermodynamicsKit.RelativeHumidity(
  actualVaporPressure, // Pa
  saturatedVaporPressure // Pa
);

// Saturated vapor pressure using Antoine equation
satVaporPressure := TThermodynamicsKit.SaturatedVaporPressure(
  temperatureC         // °C
);

// Humidity ratio: w = 0.622 * (Pv / (P - Pv))
humidityRatio := TThermodynamicsKit.HumidityRatio(
  vaporPressure,       // Pa
  atmosphericPressure  // Pa
);

// Dew point temperature using Magnus formula
dewPointTemp := TThermodynamicsKit.DewPointTemperature(
  temperatureC,        // °C
  relativeHumidityPercent // %
);

// Moist air enthalpy: h = 1.005*t + w*(2501 + 1.82*t) [kJ/kg]
moistAirEnthalpy := TThermodynamicsKit.MoistAirEnthalpy(
  temperatureC,        // °C
  humidityRatioValue   // kg/kg
);
```

## Unit Conversions

Convert between different temperature and pressure units:

```pascal
// Convert from Celsius to Kelvin: T_K = T_C + 273.15
tempKelvin := TThermodynamicsKit.CelsiusToKelvin(
  tempCelsius          // °C
);

// Convert from Kelvin to Celsius: T_C = T_K - 273.15
tempCelsius := TThermodynamicsKit.KelvinToCelsius(
  tempKelvin           // K
);

// Convert from bar to pascal: 1 bar = 10⁵ Pa
pressurePascal := TThermodynamicsKit.BarToPascal(
  pressureBar          // bar
);

// Convert from pascal to bar: 1 Pa = 10⁻⁵ bar
pressureBar := TThermodynamicsKit.PascalToBar(
  pressurePascal       // Pa
);
```

## Error Handling

All methods include appropriate validation and will raise exceptions with descriptive messages when input parameters are invalid. For example:

- Negative or zero values where positive values are required
- Physically impossible situations (like negative Kelvin temperatures)
- Invalid ranges (like relative humidity > 100%)

Always surround calls with try-except blocks when reliability is crucial.

## Examples

### Example 1: Calculate efficiency of a heat engine

```pascal
try
  // Calculate the efficiency of a heat engine operating between two temperatures
  const 
    HotTempC = 500;       // °C
    ColdTempC = 30;       // °C
  
  // Convert to Kelvin for calculations
  var HotTempK := TThermodynamicsKit.CelsiusToKelvin(HotTempC);
  var ColdTempK := TThermodynamicsKit.CelsiusToKelvin(ColdTempC);
  
  // Calculate the Carnot efficiency (maximum theoretical efficiency)
  var CarnotEff := TThermodynamicsKit.CarnotEfficiency(HotTempK, ColdTempK);
  
  // Calculate Otto cycle efficiency (for a spark-ignition engine)
  const CompressionRatio = 10.0;
  const SpecificHeatRatio = 1.4;  // For air
  
  var OttoEff := TThermodynamicsKit.OttoCycleEfficiency(CompressionRatio, SpecificHeatRatio);
  
  WriteLn('Carnot efficiency: ', (CarnotEff * 100):0:2, '%');
  WriteLn('Otto cycle efficiency: ', (OttoEff * 100):0:2, '%');
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```

### Example 2: Calculate properties of moist air

```pascal
try
  // Calculate properties of moist air
  const
    Temperature = 25.0;       // °C
    RelativeHumidity = 60.0;  // %
    AtmosphericPressure = 101325.0; // Pa
  
  // Get saturated vapor pressure at this temperature
  var Pvs := TThermodynamicsKit.SaturatedVaporPressure(Temperature);
  
  // Calculate actual vapor pressure
  var Pv := (RelativeHumidity / 100.0) * Pvs;
  
  // Calculate humidity ratio
  var HumidityRatio := TThermodynamicsKit.HumidityRatio(Pv, AtmosphericPressure);
  
  // Calculate dew point
  var DewPoint := TThermodynamicsKit.DewPointTemperature(Temperature, RelativeHumidity);
  
  // Calculate enthalpy of the moist air
  var Enthalpy := TThermodynamicsKit.MoistAirEnthalpy(Temperature, HumidityRatio);
  
  WriteLn('Saturated vapor pressure: ', Pvs:0:2, ' Pa');
  WriteLn('Actual vapor pressure: ', Pv:0:2, ' Pa');
  WriteLn('Humidity ratio: ', HumidityRatio:0:5, ' kg/kg');
  WriteLn('Dew point: ', DewPoint:0:2, ' °C');
  WriteLn('Moist air enthalpy: ', Enthalpy:0:2, ' kJ/kg');
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```
