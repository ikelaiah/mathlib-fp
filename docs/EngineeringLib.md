# EngineeringLib

Engineering mathematics library covering fluid dynamics, thermodynamics, signal processing, and comprehensive unit conversion for Free Pascal.

Depends on: **MathBase**

## Units

| Unit | File | Class |
|------|------|-------|
| `EngineeringLib.FluidDynamics` | [EngineeringLib.FluidDynamics.pas](EngineeringLib.FluidDynamics.pas) | `TFluidDynamicsKit` — core implementation |
| `EngineeringLib.Thermodynamics` | [EngineeringLib.Thermodynamics.pas](EngineeringLib.Thermodynamics.pas) | `TThermodynamicsKit` |
| `EngineeringLib.Signal` | [EngineeringLib.Signal.pas](EngineeringLib.Signal.pas) | `TSignalKit` |
| `EngineeringLib.UnitConversion` | [EngineeringLib.UnitConversion.pas](EngineeringLib.UnitConversion.pas) | `TUnitConversionKit` |
| `EngineeringLib.Velocity` | [EngineeringLib.Velocity.pas](EngineeringLib.Velocity.pas) | Alias → `TVelocityKit = TFluidDynamicsKit` |
| `EngineeringLib.Pressure` | [EngineeringLib.Pressure.pas](EngineeringLib.Pressure.pas) | Alias → `TPressureKit = TFluidDynamicsKit` |

---

## EngineeringLib.FluidDynamics — `TFluidDynamicsKit`

### Built-in Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `GravityAcceleration` | 9.80665 m/s² | Standard gravity |
| `WaterDensity` | 997.0 kg/m³ | Water at 25 °C |
| `AirDensity` | 1.225 kg/m³ | Air at standard conditions |
| `DynamicViscosityAir` | 1.81 × 10⁻⁵ Pa·s | Air at 25 °C |
| `KinematicViscosityAir` | 1.48 × 10⁻⁵ m²/s | Air at 25 °C |

### Bernoulli's Principle

Bernoulli equation for incompressible, inviscid flow: P₁ + ½ρv₁² + ρgh₁ = P₂ + ½ρv₂² + ρgh₂

```pascal
class function BernoulliPressure(Density, Pressure1, Velocity1, Height1, Velocity2, Height2: Double): Double;
class function BernoulliVelocity(Density, Pressure1, Velocity1, Height1, Pressure2, Height2: Double): Double;
class function BernoulliHeight(Density, Pressure1, Velocity1, Height1, Pressure2, Velocity2: Double): Double;
```

### Flow Rate

```pascal
class function CalculateVolumeFlowRate(Area, Velocity: Double): Double;              // Q = A·v
class function MassFlowRate(Density, Area, Velocity: Double): Double; overload;     // ṁ = ρ·A·v
class function MassFlowRate(Density, VolumeFlowRate: Double): Double; overload;     // ṁ = ρ·Q
```

### Reynolds Number

```pascal
class function ReynoldsNumber(Density, Velocity, CharacteristicLength, DynamicViscosity: Double): Double;
class function ReynoldsNumberKinematic(Velocity, CharacteristicLength, KinematicViscosity: Double): Double;
```

### Pipe Flow

| Method | Description |
|--------|-------------|
| `FrictionHeadLoss(f, L, D, v)` | Darcy-Weisbach: hf = f·(L/D)·(v²/2g) |
| `HazenWilliamsHeadLoss(L, D, Q, CHW)` | Hazen-Williams formula for water pipes |
| `LaminarFrictionFactor(Re)` | f = 64/Re (laminar flow) |
| `TurbulentFrictionFactor(Re, ε/D [, Tol, MaxIter])` | Colebrook-White equation (iterative) |
| `BlasiusFrictionFactor(Re)` | f = 0.316/Re^0.25 (smooth pipes, 4000 < Re < 10⁵) |

### Dimensionless Numbers

| Method | Formula | Significance |
|--------|---------|-------------|
| `FroudeNumber(v, L)` | Fr = v/√(g·L) | Inertial vs gravitational forces |
| `WeberNumber(ρ, v, L, σ)` | We = ρv²L/σ | Inertial vs surface tension |
| `EulerNumber(ΔP, ρ, v)` | Eu = ΔP/(ρv²) | Pressure vs inertial forces |
| `MachNumber(v, c)` | Ma = v/c | Flow vs speed of sound |
| `StrouhalNumber(f, L, v)` | St = fL/v | Oscillating flow |
| `PrandtlNumber(μ, cp, k)` | Pr = μcp/k | Momentum vs thermal diffusivity |
| `NusseltNumber(h, L, k)` | Nu = hL/k | Convective vs conductive heat transfer |

### Aerodynamics

```pascal
class function LiftForce(CL, Density, Velocity, ReferenceArea: Double): Double;
class function DragForce(CD, Density, Velocity, ReferenceArea: Double): Double;
class function DynamicPressure(Density, Velocity: Double): Double;          // q = ½ρv²
class function StagnationPressure(StaticPressure, DynamicPressure: Double): Double;
class function PressureCoefficient(P, P_inf, Rho_inf, V_inf: Double): Double;
```

### Compressible Flow

```pascal
class function SpeedOfSound(SpecificHeatRatio, GasConstant, Temperature: Double): Double; // c = √(γRT)
class function StagnationTemperatureRatio(MachNumber, SpecificHeatRatio: Double): Double;
class function StagnationPressureRatio(MachNumber, SpecificHeatRatio: Double): Double;
class function IsentropicAreaRatio(MachNumber, SpecificHeatRatio: Double): Double;
```

### Pumps and Turbines

```pascal
class function PumpPower(Density, FlowRate, Head, Efficiency: Double): Double;    // P = ρgQH/η
class function PumpHead(PressureDiff, Density, VelocityDiff, HeightDiff: Double): Double;
class function PumpSpecificSpeed(RPM, FlowRate, Head: Double): Double;             // Ns = N√Q/H^(3/4)
class function TurbinePower(Efficiency, Density, FlowRate, Head: Double): Double;  // P = η·ρgQH
```

### Open Channel Flow

```pascal
class function ChezyVelocity(C, R, S: Double): Double;         // v = C·√(R·S)
class function ManningVelocity(n, R, S: Double): Double;        // v = (1/n)·R^(2/3)·S^(1/2)
class function CriticalDepthRectangular(UnitDischarge: Double): Double;  // yc = (q²/g)^(1/3)
class function OpenChannelFroudeNumber(Velocity, Depth: Double): Double;
```

### Fluid Properties

```pascal
class function DensityWater: Double;           // ≈ 997 kg/m³ at 25 °C
class function DynamicViscosityWater: Double;  // Pa·s at 25 °C
class function KinematicViscosityWater: Double; // m²/s at 25 °C
```

---

## EngineeringLib.Thermodynamics — `TThermodynamicsKit`

### Built-in Constants

| Constant | Value |
|----------|-------|
| `BoltzmannConstant` | 1.380649 × 10⁻²³ J/K |
| `StefanBoltzmannConstant` | 5.670374419 × 10⁻⁸ W/(m²·K⁴) |
| `IdealGasConstant` | 8.314462618 J/(mol·K) |
| `AvogadroConstant` | 6.02214076 × 10²³ mol⁻¹ |
| `StandardAtmosphere` | 101325 Pa |
| `StandardTempK` | 273.15 K (= 0 °C) |

### Heat Transfer

| Method | Formula | Description |
|--------|---------|-------------|
| `HeatConductionRate(k, A, ΔT, d)` | Q = k·A·ΔT/d | Fourier's law (conduction) |
| `HeatConvectionRate(h, A, ΔT)` | Q = h·A·ΔT | Newton's law of cooling |
| `HeatRadiationRate(ε, A, T_s, T_sur)` | Q = ε·σ·A·(T_s⁴ − T_sur⁴) | Stefan-Boltzmann radiation; temperatures in K |
| `HeatEnergyChange(m, c, ΔT)` | Q = m·c·ΔT | Sensible heat |

### Entropy

```pascal
class function EntropyChangeReversible(HeatTransfer, AbsoluteTempK: Double): Double;     // ΔS = Q/T
class function EntropyChangeHeating(Mass, Cp, T_initial, T_final: Double): Double;       // ΔS = m·c·ln(T2/T1)
class function EntropyChangeIsothermalExpansion(Moles, V_initial, V_final: Double): Double; // ΔS = nR·ln(V2/V1)
```

### Ideal Gas Law (PV = nRT)

```pascal
class function IdealGasPressure(Moles, Volume, AbsoluteTempK: Double): Double;
class function IdealGasVolume(Moles, Pressure, AbsoluteTempK: Double): Double;
class function IdealGasTemperature(Pressure, Volume, Moles: Double): Double;
class function IdealGasMoles(Pressure, Volume, AbsoluteTempK: Double): Double;
```

### Phase Transitions

```pascal
class function HeatOfFusion(Mass, LatentHeatOfFusion: Double): Double;         // Q = m·Lf
class function HeatOfVaporization(Mass, LatentHeatOfVaporization: Double): Double; // Q = m·Lv
```

### Efficiency

```pascal
class function CarnotEfficiency(HotTempK, ColdTempK: Double): Double;          // η = 1 − T_c/T_h
class function ThermalEfficiency(WorkOutput, HeatInput: Double): Double;        // η = W/Q_in
class function CoefficientOfPerformanceRefrigeration(Q_cold, WorkInput: Double): Double;
class function CoefficientOfPerformanceHeatPump(Q_hot, WorkInput: Double): Double;
```

### Thermodynamic Cycles

| Method | Description |
|--------|-------------|
| `OttoCycleEfficiency(r, γ)` | η = 1 − 1/r^(γ−1); spark-ignition |
| `DieselCycleEfficiency(r, α, γ)` | Diesel cycle; r = compression ratio, α = cutoff ratio |
| `BraytonCycleEfficiency(r, γ)` | η = 1 − 1/r^((γ−1)/γ); gas turbine |
| `RankineCycleEfficiency(W_turbine, W_pump, Q_in)` | Steam power cycle |

### Adiabatic Process

```pascal
class function AdiabaticPressure(P1, V1, V2, γ: Double): Double;        // P1·V1^γ = P2·V2^γ
class function AdiabaticVolume(P1, V1, P2, γ: Double): Double;
class function AdiabaticTemperature(T1, V1, V2, γ: Double): Double;     // T1·V1^(γ−1) = T2·V2^(γ−1)
class function AdiabaticTemperatureFromPressure(T1, P1, P2, γ: Double): Double;
```

### Compressible Flow (Isentropic)

```pascal
class function CriticalPressureRatio(SpecificHeatRatio: Double): Double;
class function MachNumberFromPressureRatio(PressureRatio, SpecificHeatRatio: Double): Double;
class function IsentropicTemperatureRatio(MachNumber, SpecificHeatRatio: Double): Double;
class function IsentropicPressureRatio(MachNumber, SpecificHeatRatio: Double): Double;
class function IsentropicDensityRatio(MachNumber, SpecificHeatRatio: Double): Double;
```

### Psychrometrics

```pascal
class function RelativeHumidity(ActualVaporPressure, SaturatedVaporPressure: Double): Double;
class function SaturatedVaporPressure(TemperatureC: Double): Double;  // Antoine equation
class function HumidityRatio(VaporPressure, AtmosphericPressure: Double): Double;
class function DewPointTemperature(TemperatureC, RelativeHumidityPercent: Double): Double;
class function MoistAirEnthalpy(TemperatureC, HumidityRatioValue: Double): Double;
```

### Unit Conversion Helpers

```pascal
class function CelsiusToKelvin(TempC: Double): Double;
class function KelvinToCelsius(TempK: Double): Double;
class function BarToPascal(Bar: Double): Double;
class function PascalToBar(Pascal: Double): Double;
```

---

## EngineeringLib.Signal — `TSignalKit`

### Filtering

```pascal
class function MovingAverage(const InputSignal: TDoubleArray; WindowSize: Integer): TDoubleArray;
```

Sliding-window simple moving average. Elements before the first full window are filled with the first valid average.

### Window Functions

```pascal
type TWindowType = (wtRectangular, wtHamming, wtHann, wtBlackman);

class function GenerateWindow(WindowType: TWindowType; Size: Integer): TDoubleArray;
class function ApplyWindow(const InputSignal, Window: TDoubleArray): TDoubleArray;
```

### Spectral Analysis

```pascal
class procedure CalculateFFT(const InputSignal: TDoubleArray;
  out RealPart, ImaginaryPart: TDoubleArray);
class procedure CalculateFFTMagnitudePhase(const InputSignal: TDoubleArray;
  out Magnitude, Phase: TDoubleArray);
```

> **Note:** FFT stubs are included as placeholders for future expansion. A full FFT implementation requires a dedicated algorithm or external library.

### Signal Properties

```pascal
class function SignalPower(const InputSignal: TDoubleArray): Double;   // Mean of squared samples
class function SignalEnergy(const InputSignal: TDoubleArray): Double;  // Sum of squared samples
class function RootMeanSquare(const InputSignal: TDoubleArray): Double;
```

---

## EngineeringLib.UnitConversion — `TUnitConversionKit`

### Supported Quantity Types

`TUnitType`: Length, Mass, Time, Temperature, Force, Energy, Power, Pressure, Velocity, Area, Volume, Angle, Density, ElectricalCurrent, ElectricalPotential, Frequency.

### Conversion Methods

| Method | Enum Type |
|--------|-----------|
| `ConvertLength(Value, FromUnit, ToUnit)` | `TLengthUnit` |
| `ConvertMass(Value, FromUnit, ToUnit)` | `TMassUnit` |
| `ConvertTime(Value, FromUnit, ToUnit)` | `TTimeUnit` |
| `ConvertTemperature(Value, FromUnit, ToUnit)` | `TTemperatureUnit` |
| `ConvertForce(Value, FromUnit, ToUnit)` | `TForceUnit` |
| `ConvertEnergy(Value, FromUnit, ToUnit)` | `TEnergyUnit` |
| `ConvertPower(Value, FromUnit, ToUnit)` | `TPowerUnit` |
| `ConvertPressure(Value, FromUnit, ToUnit)` | `TPressureUnit` |
| `ConvertVelocity(Value, FromUnit, ToUnit)` | `TVelocityUnit` |
| `ConvertArea(Value, FromUnit, ToUnit)` | `TAreaUnit` |
| `ConvertVolume(Value, FromUnit, ToUnit)` | `TVolumeUnit` |
| `ConvertAngle(Value, FromUnit, ToUnit)` | `TAngleUnit` |
| `ConvertDensity(Value, FromUnit, ToUnit)` | `TDensityUnit` |
| `ConvertElectricalCurrent(Value, FromUnit, ToUnit)` | `TElectricalCurrentUnit` |
| `ConvertElectricalPotential(Value, FromUnit, ToUnit)` | `TElectricalPotentialUnit` |
| `ConvertFrequency(Value, FromUnit, ToUnit)` | `TFrequencyUnit` |

### Selected Unit Enumerations

**Length** (`TLengthUnit`): `luMeter`, `luKilometer`, `luCentimeter`, `luMillimeter`, `luMicrometer`, `luNanometer`, `luMile`, `luYard`, `luFoot`, `luInch`, `luNauticalMile`, `luAngstrom`, `luLightYear`

**Temperature** (`TTemperatureUnit`): `tpKelvin`, `tpCelsius`, `tpFahrenheit`, `tpRankine`, `tpReaumur`

**Pressure** (`TPressureUnit`): `prPascal`, `prKilopascal`, `prBar`, `prAtmosphere`, `prTorr`, `prPSI`

**Angle** (`TAngleUnit`): `anDegree`, `anRadian`, `anGradian`, `anMinuteOfArc`, `anSecondOfArc`, `anRevolution`

---

## Quick Start

```pascal
uses EngineeringLib.FluidDynamics, EngineeringLib.Thermodynamics, EngineeringLib.UnitConversion;

var
  Re, Efficiency, LengthInFeet: Double;
begin
  // Reynolds number for water flow in a pipe
  Re := TFluidDynamicsKit.ReynoldsNumber(997, 2.0, 0.05, 1.0e-3);
  Writeln('Re = ', Re:0:0);   // ≈ 99700 (turbulent)

  // Carnot efficiency between 500 K and 300 K
  Efficiency := TThermodynamicsKit.CarnotEfficiency(500, 300);
  Writeln('Carnot η = ', Efficiency:0:4);  // 0.4000

  // Convert 1 metre to feet
  LengthInFeet := TUnitConversionKit.ConvertLength(1.0, luMeter, luFoot);
  Writeln('1 m = ', LengthInFeet:0:4, ' ft');  // ≈ 3.2808
end.
```

## Unit Aliases

```pascal
// EngineeringLib.Velocity:
TVelocityKit = TFluidDynamicsKit;

// EngineeringLib.Pressure:
TPressureKit = TFluidDynamicsKit;
```

Add these focused units to your `uses` clause when your code is specifically about velocity or pressure calculations.
