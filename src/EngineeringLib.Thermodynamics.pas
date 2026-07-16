unit EngineeringLib.Thermodynamics;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, EngineeringLib.Common;

type
  TThermodynamicsKit = class
  public
    const
      // Physical constants
      BoltzmannConstant = 1.380649E-23; // J/K
      StefanBoltzmannConstant = 5.670374419E-8; // W/(m²·K⁴)
      IdealGasConstant = 8.314462618; // J/(mol·K)
      AvogadroConstant = 6.02214076E23; // mol⁻¹
      StandardAtmosphere = 101325; // Pa
      StandardTempK = 273.15; // 0°C in K

    { Heat Transfer }
    // Q = k * A * (T_hot - T_cold) / d
    class function HeatConductionRate(
      ThermalConductivity: Double;
      Area: Double;
      TempDifference: Double;
      Thickness: Double): Double; static;
    // Q = h * A * (T_surface - T_fluid)
    class function HeatConvectionRate(
      ConvectionCoefficient: Double;
      Area: Double;
      TempDifference: Double): Double; static;
    // Q = ε * σ * A * (T_surface⁴ - T_surroundings⁴)
    class function HeatRadiationRate(
      Emissivity: Double;
      Area: Double;
      SurfaceTempK: Double;
      SurroundingsTempK: Double): Double; static;
    // Q = m * c * ΔT
    class function HeatEnergyChange(Mass: Double; SpecificHeatCapacity: Double; TempChange: Double): Double; static;

    { Entropy }
    // ΔS = Q / T (for reversible process at constant T)
    class function EntropyChangeReversible(HeatTransfer: Double; AbsoluteTempK: Double): Double; static;
    // ΔS = m * c * ln(T_final / T_initial)
    class function EntropyChangeHeating(
      Mass: Double;
      SpecificHeatCapacity: Double;
      InitialTempK: Double;
      FinalTempK: Double): Double; static;
    // ΔS = n * R * ln(V_final / V_initial) (for isothermal expansion of ideal gas)
    class function EntropyChangeIsothermalExpansion(
      Moles: Double;
      InitialVolume: Double;
      FinalVolume: Double): Double; static;

    { Ideal Gas Law }
    // P * V = n * R * T
    class function IdealGasPressure(Moles: Double; Volume: Double; AbsoluteTempK: Double): Double; static;
    class function IdealGasVolume(Moles: Double; Pressure: Double; AbsoluteTempK: Double): Double; static;
    class function IdealGasTemperature(Pressure: Double; Volume: Double; Moles: Double): Double; static;
    class function IdealGasMoles(Pressure: Double; Volume: Double; AbsoluteTempK: Double): Double; static;

    { Phase Transitions }
    // Q = m * L
    class function HeatOfFusion(Mass: Double; LatentHeatOfFusion: Double): Double; static;
    class function HeatOfVaporization(Mass: Double; LatentHeatOfVaporization: Double): Double; static;

    { Efficiency }
    // η = 1 - (T_cold / T_hot)
    class function CarnotEfficiency(HotTempK: Double; ColdTempK: Double): Double; static;
    // η = Work_out / Heat_in
    class function ThermalEfficiency(WorkOutput: Double; HeatInput: Double): Double; static;
    // COP = Q_cold / Work_in (for refrigeration)
    class function CoefficientOfPerformanceRefrigeration(ColdHeatExtracted: Double; WorkInput: Double): Double; static;
    // COP = Q_hot / Work_in (for heat pump)
    class function CoefficientOfPerformanceHeatPump(HotHeatDelivered: Double; WorkInput: Double): Double; static;

    { Thermodynamic Cycles }
    // Otto cycle efficiency (ideal spark-ignition engine)
    // η = 1 - (1/r^(γ-1)) where r is the compression ratio
    class function OttoCycleEfficiency(CompressionRatio: Double; SpecificHeatRatio: Double): Double; static;
    // Diesel cycle efficiency (ideal compression-ignition engine)
    // η = 1 - (1/r^(γ-1)) * ((α^γ-1)/(γ*(α-1))) where r is compression ratio, α is cutoff ratio
    class function DieselCycleEfficiency(
      CompressionRatio: Double;
      CutoffRatio: Double;
      SpecificHeatRatio: Double): Double; static;
    // Brayton cycle efficiency (ideal gas turbine engine)
    // η = 1 - (1/r^((γ-1)/γ)) where r is pressure ratio
    class function BraytonCycleEfficiency(PressureRatio: Double; SpecificHeatRatio: Double): Double; static;
    // Rankine cycle calculations
    class function RankineCycleEfficiency(
      TurbineWorkOutput: Double;
      PumpWorkInput: Double;
      HeatInput: Double): Double; static;

    { Adiabatic Process }
    // P1*V1^γ = P2*V2^γ (pressure-volume relation)
    class function AdiabaticPressure(
      InitialPressure, InitialVolume, FinalVolume: Double;
      SpecificHeatRatio: Double): Double; static;
    class function AdiabaticVolume(
      InitialPressure, InitialVolume, FinalPressure: Double;
      SpecificHeatRatio: Double): Double; static;
    // T1*V1^(γ-1) = T2*V2^(γ-1) (temperature-volume relation)
    class function AdiabaticTemperature(
      InitialTemp, InitialVolume, FinalVolume: Double;
      SpecificHeatRatio: Double): Double; static;
    // T2 = T1*(P2/P1)^((γ-1)/γ) (temperature-pressure relation)
    class function AdiabaticTemperatureFromPressure(
      InitialTemp, InitialPressure, FinalPressure: Double;
      SpecificHeatRatio: Double): Double; static;
    
    { Compressible Flow }
    // Critical pressure ratio for choked flow
    class function CriticalPressureRatio(SpecificHeatRatio: Double): Double; static;
    // Mach number from pressure ratio
    class function MachNumberFromPressureRatio(PressureRatio: Double; SpecificHeatRatio: Double): Double; static;
    // Isentropic flow relations
    class function IsentropicTemperatureRatio(MachNumber: Double; SpecificHeatRatio: Double): Double; static;
    class function IsentropicPressureRatio(MachNumber: Double; SpecificHeatRatio: Double): Double; static;
    class function IsentropicDensityRatio(MachNumber: Double; SpecificHeatRatio: Double): Double; static;

    { Psychrometrics }
    // Relative humidity = (Actual vapor pressure / Saturated vapor pressure) * 100%
    class function RelativeHumidity(ActualVaporPressure: Double; SaturatedVaporPressure: Double): Double; static;
    // Saturated vapor pressure calculated using Antoine equation
    class function SaturatedVaporPressure(TemperatureC: Double): Double; static;
    // Humidity ratio (or specific humidity)
    class function HumidityRatio(VaporPressure: Double; AtmosphericPressure: Double): Double; static;
    // Dew point temperature
    class function DewPointTemperature(TemperatureC: Double; RelativeHumidityPercent: Double): Double; static;
    // Enthalpy of moist air
    class function MoistAirEnthalpy(TemperatureC: Double; HumidityRatioValue: Double): Double; static;

    { Unit Conversions }
    class function CelsiusToKelvin(TempC: Double): Double; static;
    class function KelvinToCelsius(TempK: Double): Double; static;
    class function BarToPascal(Bar: Double): Double; static;
    class function PascalToBar(Pascal: Double): Double; static;
  end;

implementation

{ TThermodynamicsKit }

class function TThermodynamicsKit.HeatConductionRate(
  ThermalConductivity: Double;
  Area: Double;
  TempDifference: Double;
  Thickness: Double): Double;
begin
  if Thickness <= 0 then
    raise EThermodynamicsError.Create('Thickness must be positive for heat conduction calculation.');
  Result := ThermalConductivity * Area * TempDifference / Thickness;
end;

class function TThermodynamicsKit.HeatConvectionRate(
  ConvectionCoefficient: Double;
  Area: Double;
  TempDifference: Double): Double;
begin
  Result := ConvectionCoefficient * Area * TempDifference;
end;

class function TThermodynamicsKit.HeatRadiationRate(
  Emissivity: Double;
  Area: Double;
  SurfaceTempK: Double;
  SurroundingsTempK: Double): Double;
begin
  if (Emissivity < 0) or (Emissivity > 1) then
    raise EThermodynamicsError.Create('Emissivity must be between 0 and 1.');
  if (SurfaceTempK < 0) or (SurroundingsTempK < 0) then
    raise EThermodynamicsError.Create('Temperatures must be in Kelvin (non-negative).');
  Result := Emissivity * StefanBoltzmannConstant * Area * (Power(SurfaceTempK, 4) - Power(SurroundingsTempK, 4));
end;

class function TThermodynamicsKit.HeatEnergyChange(
  Mass: Double;
  SpecificHeatCapacity: Double;
  TempChange: Double): Double;
begin
  Result := Mass * SpecificHeatCapacity * TempChange;
end;

class function TThermodynamicsKit.EntropyChangeReversible(HeatTransfer: Double; AbsoluteTempK: Double): Double;
begin
  if AbsoluteTempK <= 0 then
    raise EThermodynamicsError.Create('Absolute temperature must be positive for entropy calculation.');
  Result := HeatTransfer / AbsoluteTempK;
end;

class function TThermodynamicsKit.EntropyChangeHeating(
  Mass: Double;
  SpecificHeatCapacity: Double;
  InitialTempK: Double;
  FinalTempK: Double): Double;
begin
  if (InitialTempK <= 0) or (FinalTempK <= 0) then
    raise EThermodynamicsError.Create('Absolute temperatures must be positive for entropy calculation.');
  Result := Mass * SpecificHeatCapacity * Ln(FinalTempK / InitialTempK);
end;

class function TThermodynamicsKit.EntropyChangeIsothermalExpansion(
  Moles: Double;
  InitialVolume: Double;
  FinalVolume: Double): Double;
begin
  if (InitialVolume <= 0) or (FinalVolume <= 0) then
     raise EThermodynamicsError.Create('Volumes must be positive for entropy calculation.');
  Result := Moles * IdealGasConstant * Ln(FinalVolume / InitialVolume);
end;

class function TThermodynamicsKit.IdealGasPressure(Moles: Double; Volume: Double; AbsoluteTempK: Double): Double;
begin
  if Volume <= 0 then
    raise EThermodynamicsError.Create('Volume must be positive for ideal gas calculation.');
  if AbsoluteTempK < 0 then
    raise EThermodynamicsError.Create('Absolute temperature cannot be negative.');
  Result := Moles * IdealGasConstant * AbsoluteTempK / Volume;
end;

class function TThermodynamicsKit.IdealGasVolume(Moles: Double; Pressure: Double; AbsoluteTempK: Double): Double;
begin
  if Pressure <= 0 then
    raise EThermodynamicsError.Create('Pressure must be positive for ideal gas calculation.');
  if AbsoluteTempK < 0 then
    raise EThermodynamicsError.Create('Absolute temperature cannot be negative.');
  Result := Moles * IdealGasConstant * AbsoluteTempK / Pressure;
end;

class function TThermodynamicsKit.IdealGasTemperature(Pressure: Double; Volume: Double; Moles: Double): Double;
begin
  if Moles <= 0 then
    raise EThermodynamicsError.Create('Number of moles must be positive.');
  if (Pressure <= 0) or (Volume <= 0) then
    raise EThermodynamicsError.Create('Pressure and Volume must be positive.');
  Result := Pressure * Volume / (Moles * IdealGasConstant);
end;

class function TThermodynamicsKit.IdealGasMoles(Pressure: Double; Volume: Double; AbsoluteTempK: Double): Double;
begin
  if AbsoluteTempK <= 0 then
    raise EThermodynamicsError.Create('Absolute temperature must be positive.');
  if (Pressure <= 0) or (Volume <= 0) then
    raise EThermodynamicsError.Create('Pressure and Volume must be positive.');
  Result := Pressure * Volume / (IdealGasConstant * AbsoluteTempK);
end;

class function TThermodynamicsKit.HeatOfFusion(Mass: Double; LatentHeatOfFusion: Double): Double;
begin
  Result := Mass * LatentHeatOfFusion;
end;

class function TThermodynamicsKit.HeatOfVaporization(Mass: Double; LatentHeatOfVaporization: Double): Double;
begin
  Result := Mass * LatentHeatOfVaporization;
end;

class function TThermodynamicsKit.CarnotEfficiency(HotTempK: Double; ColdTempK: Double): Double;
begin
  if (HotTempK <= 0) or (ColdTempK < 0) then
    raise EThermodynamicsError.Create('Absolute temperatures must be positive (Hot > 0, Cold >= 0).');
  if ColdTempK >= HotTempK then
    raise EThermodynamicsError.Create('Hot temperature must be greater than cold temperature for Carnot efficiency.');
  Result := 1.0 - (ColdTempK / HotTempK);
end;

class function TThermodynamicsKit.ThermalEfficiency(WorkOutput: Double; HeatInput: Double): Double;
begin
  if HeatInput <= 0 then
    raise EThermodynamicsError.Create('Heat input must be positive for thermal efficiency calculation.');
  Result := WorkOutput / HeatInput;
end;

class function TThermodynamicsKit.CoefficientOfPerformanceRefrigeration(
  ColdHeatExtracted: Double;
  WorkInput: Double): Double;
begin
  if WorkInput <= 0 then
    raise EThermodynamicsError.Create('Work input must be positive for COP calculation.');
  Result := ColdHeatExtracted / WorkInput;
end;

class function TThermodynamicsKit.CoefficientOfPerformanceHeatPump(HotHeatDelivered: Double; WorkInput: Double): Double;
begin
  if WorkInput <= 0 then
    raise EThermodynamicsError.Create('Work input must be positive for COP calculation.');
  Result := HotHeatDelivered / WorkInput;
end;

class function TThermodynamicsKit.OttoCycleEfficiency(CompressionRatio: Double; SpecificHeatRatio: Double): Double;
begin
  if CompressionRatio <= 1 then
    raise EThermodynamicsError.Create('Compression ratio must be greater than 1.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  Result := 1 - Power(1/CompressionRatio, SpecificHeatRatio - 1);
end;

class function TThermodynamicsKit.DieselCycleEfficiency(
  CompressionRatio: Double;
  CutoffRatio: Double;
  SpecificHeatRatio: Double): Double;
begin
  if CompressionRatio <= 1 then
    raise EThermodynamicsError.Create('Compression ratio must be greater than 1.');
  if CutoffRatio <= 1 then
    raise EThermodynamicsError.Create('Cutoff ratio must be greater than 1.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  Result := 1 - (1/Power(CompressionRatio, SpecificHeatRatio-1)) * 
            (Power(CutoffRatio, SpecificHeatRatio) - 1) / 
            (SpecificHeatRatio * (CutoffRatio - 1));
end;

class function TThermodynamicsKit.BraytonCycleEfficiency(PressureRatio: Double; SpecificHeatRatio: Double): Double;
begin
  if PressureRatio <= 1 then
    raise EThermodynamicsError.Create('Pressure ratio must be greater than 1.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  Result := 1 - 1/Power(PressureRatio, (SpecificHeatRatio-1)/SpecificHeatRatio);
end;

class function TThermodynamicsKit.RankineCycleEfficiency(
  TurbineWorkOutput: Double;
  PumpWorkInput: Double;
  HeatInput: Double): Double;
begin
  if HeatInput <= 0 then
    raise EThermodynamicsError.Create('Heat input must be positive for Rankine cycle calculation.');
  Result := (TurbineWorkOutput - PumpWorkInput) / HeatInput;
end;

class function TThermodynamicsKit.AdiabaticPressure(
  InitialPressure, InitialVolume, FinalVolume: Double;
  SpecificHeatRatio: Double): Double;
begin
  if (InitialPressure <= 0) or (InitialVolume <= 0) or (FinalVolume <= 0) then
    raise EThermodynamicsError.Create('Pressure and volumes must be positive for adiabatic process calculation.');
  Result := InitialPressure * Power(InitialVolume / FinalVolume, SpecificHeatRatio);
end;

class function TThermodynamicsKit.AdiabaticVolume(
  InitialPressure, InitialVolume, FinalPressure: Double;
  SpecificHeatRatio: Double): Double;
begin
  if (InitialPressure <= 0) or (InitialVolume <= 0) or (FinalPressure <= 0) then
    raise EThermodynamicsError.Create('Pressure and volume must be positive for adiabatic process calculation.');
  Result := InitialVolume * Power(InitialPressure / FinalPressure, 1/SpecificHeatRatio);
end;

class function TThermodynamicsKit.AdiabaticTemperature(
  InitialTemp, InitialVolume, FinalVolume: Double;
  SpecificHeatRatio: Double): Double;
begin
  if (InitialTemp <= 0) or (InitialVolume <= 0) or (FinalVolume <= 0) then
    raise EThermodynamicsError.Create('Temperature and volumes must be positive for adiabatic process calculation.');
  Result := InitialTemp * Power(InitialVolume / FinalVolume, SpecificHeatRatio - 1);
end;

class function TThermodynamicsKit.AdiabaticTemperatureFromPressure(
  InitialTemp, InitialPressure, FinalPressure: Double;
  SpecificHeatRatio: Double): Double;
begin
  if (InitialTemp <= 0) or (InitialPressure <= 0) or (FinalPressure <= 0) then
    raise EThermodynamicsError.Create('Temperature and pressures must be positive for adiabatic process calculation.');
  Result := InitialTemp * Power(FinalPressure / InitialPressure, (SpecificHeatRatio - 1) / SpecificHeatRatio);
end;

class function TThermodynamicsKit.CriticalPressureRatio(SpecificHeatRatio: Double): Double;
begin
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  Result := Power(2 / (SpecificHeatRatio + 1), SpecificHeatRatio / (SpecificHeatRatio - 1));
end;

class function TThermodynamicsKit.MachNumberFromPressureRatio(PressureRatio: Double; SpecificHeatRatio: Double): Double;
var
  Exponent: Double;
begin
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  if (PressureRatio <= 0) or (PressureRatio > 1) then
    raise EThermodynamicsError.Create('Pressure ratio must be between 0 and 1.');
  
  Exponent := (SpecificHeatRatio - 1) / SpecificHeatRatio;
  Result := Sqrt(2 / (SpecificHeatRatio - 1) * (Power(1 / PressureRatio, Exponent) - 1));
end;

class function TThermodynamicsKit.IsentropicTemperatureRatio(MachNumber: Double; SpecificHeatRatio: Double): Double;
begin
  if MachNumber < 0 then
    raise EThermodynamicsError.Create('Mach number cannot be negative.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  
  Result := 1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumber, 2);
end;

class function TThermodynamicsKit.IsentropicPressureRatio(MachNumber: Double; SpecificHeatRatio: Double): Double;
begin
  if MachNumber < 0 then
    raise EThermodynamicsError.Create('Mach number cannot be negative.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  
  Result := Power(1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumber, 2), -SpecificHeatRatio / (SpecificHeatRatio - 1));
end;

class function TThermodynamicsKit.IsentropicDensityRatio(MachNumber: Double; SpecificHeatRatio: Double): Double;
begin
  if MachNumber < 0 then
    raise EThermodynamicsError.Create('Mach number cannot be negative.');
  if SpecificHeatRatio <= 1 then
    raise EThermodynamicsError.Create('Specific heat ratio must be greater than 1.');
  
  Result := Power(1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumber, 2), -1 / (SpecificHeatRatio - 1));
end;

class function TThermodynamicsKit.RelativeHumidity(ActualVaporPressure: Double; SaturatedVaporPressure: Double): Double;
begin
  if (ActualVaporPressure < 0) or (SaturatedVaporPressure <= 0) then
    raise EThermodynamicsError.Create('Vapor pressures must be non-negative and saturated vapor pressure must be positive.');
  Result := (ActualVaporPressure / SaturatedVaporPressure) * 100;
end;

class function TThermodynamicsKit.SaturatedVaporPressure(TemperatureC: Double): Double;
const
  A = 8.07131;  // Antoine equation constants for water
  B = 1730.63;  // valid from about 1-100°C
  C = 233.426;
begin
  // Using Antoine equation: log10(P) = A - (B / (T + C)) where P is in mmHg and T is in °C
  if (TemperatureC < 1) or (TemperatureC > 100) then
    raise EThermodynamicsError.Create('Temperature should be between 1-100°C for accurate saturated vapor pressure calculation.');
  
  Result := Power(10, A - (B / (TemperatureC + C))) * 133.322; // Convert mmHg to Pa
end;

class function TThermodynamicsKit.HumidityRatio(VaporPressure: Double; AtmosphericPressure: Double): Double;
begin
  if (VaporPressure < 0) or (AtmosphericPressure <= 0) then
    raise EThermodynamicsError.Create('Vapor pressure must be non-negative and atmospheric pressure must be positive.');
  // w = 0.622 * (Pv / (P - Pv))
  Result := 0.622 * (VaporPressure / (AtmosphericPressure - VaporPressure));
end;

class function TThermodynamicsKit.DewPointTemperature(TemperatureC: Double; RelativeHumidityPercent: Double): Double;
var
  A, B, C: Double; // Magnus formula constants
  Alpha: Double;
begin
  if (RelativeHumidityPercent <= 0) or (RelativeHumidityPercent > 100) then
    raise EThermodynamicsError.Create('Relative humidity must be between 0 and 100%.');
  
  // Magnus formula constants for water vapor
  A := 17.27;
  B := 237.7; // °C
  
  Alpha := Ln(RelativeHumidityPercent / 100) + (A * TemperatureC) / (B + TemperatureC);
  Result := (B * Alpha) / (A - Alpha);
end;

class function TThermodynamicsKit.MoistAirEnthalpy(TemperatureC: Double; HumidityRatioValue: Double): Double;
begin
  if HumidityRatioValue < 0 then
    raise EThermodynamicsError.Create('Humidity ratio cannot be negative.');
  // h = cp,air * t + w * (hfg + cp,vapor * t) where cp,air ≈ 1.005 kJ/(kg·K), cp,vapor ≈ 1.82 kJ/(kg·K), hfg ≈ 2501 kJ/kg
  // Simplified form: h = 1.005 * t + w * (2501 + 1.82 * t) [kJ/kg]
  Result := 1.005 * TemperatureC + HumidityRatioValue * (2501 + 1.82 * TemperatureC);
end;

class function TThermodynamicsKit.CelsiusToKelvin(TempC: Double): Double;
begin
  Result := TempC + 273.15;
end;

class function TThermodynamicsKit.KelvinToCelsius(TempK: Double): Double;
begin
  if TempK < 0 then
    raise EThermodynamicsError.Create('Kelvin temperature cannot be negative.');
  Result := TempK - 273.15;
end;

class function TThermodynamicsKit.BarToPascal(Bar: Double): Double;
begin
  Result := Bar * 100000;
end;

class function TThermodynamicsKit.PascalToBar(Pascal: Double): Double;
begin
  Result := Pascal / 100000;
end;

end.
