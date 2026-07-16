unit TestEngineeringLib_Thermodynamics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  EngineeringLib.Common, EngineeringLib.Thermodynamics;

type

  { TTestThermodynamicsKit }

  TTestThermodynamicsKit = class(TTestCase)
  private
    // Helper methods for exception testing
    procedure ZeroThicknessHeatConductionTest;
    procedure ZeroTempEntropyTest;
    procedure ZeroWorkInputCOPRefrigerationTest;
    procedure ZeroWorkInputCOPHeatPumpTest;
    procedure LowCompressionRatioOttoTest;
    procedure LowGammaOttoTest;
    procedure LowCompressionRatioDieselTest;
    procedure LowCutoffRatioDieselTest;
    procedure LowGammaDieselTest;
    procedure LowPressureRatioBraytonTest;
    procedure LowGammaBraytonTest;
    procedure ZeroHeatInputRankineTest;
    procedure NegativeTempKelvinTest;
    procedure ZeroVaporPressureRHTest;
    procedure ZeroRHDewPointTest;
    procedure HighRHDewPointTest;
    procedure NegativeHumidityRatioTest;
  published
    // Original tests with renamed numbering scheme
    procedure Test01_HeatConductionRate;
    procedure Test02_HeatConvectionRate;
    procedure Test03_HeatRadiationRate;
    procedure Test04_HeatEnergyChange;
    procedure Test05_EntropyChangeReversible;
    procedure Test06_EntropyChangeHeating;
    procedure Test07_EntropyChangeIsothermalExpansion;
    procedure Test08_IdealGasPressure;
    procedure Test09_IdealGasVolume;
    procedure Test10_IdealGasTemperature;
    procedure Test11_IdealGasMoles;
    procedure Test12_HeatOfFusion;
    procedure Test13_HeatOfVaporization;
    procedure Test14_CarnotEfficiency;
    procedure Test15_ThermalEfficiency;
    procedure Test16_OriginalEdgeCases;
    
    // Tests for additional efficiency metrics
    procedure Test17_CoefficientOfPerformanceRefrigeration;
    procedure Test18_CoefficientOfPerformanceHeatPump;
    
    // Tests for thermodynamic cycles
    procedure Test19_OttoCycleEfficiency;
    procedure Test20_DieselCycleEfficiency;
    procedure Test21_BraytonCycleEfficiency;
    procedure Test22_RankineCycleEfficiency;
    
    // Tests for adiabatic processes
    procedure Test23_AdiabaticPressure;
    procedure Test24_AdiabaticVolume;
    procedure Test25_AdiabaticTemperature;
    procedure Test26_AdiabaticTemperatureFromPressure;
    
    // Tests for compressible flow
    procedure Test27_CriticalPressureRatio;
    procedure Test28_MachNumberFromPressureRatio;
    procedure Test29_IsentropicTemperatureRatio;
    procedure Test30_IsentropicPressureRatio;
    procedure Test31_IsentropicDensityRatio;
    
    // Tests for psychrometrics
    procedure Test32_RelativeHumidity;
    procedure Test33_SaturatedVaporPressure;
    procedure Test34_HumidityRatio;
    procedure Test35_DewPointTemperature;
    procedure Test36_MoistAirEnthalpy;
    
    // Tests for unit conversions
    procedure Test37_CelsiusToKelvin;
    procedure Test38_KelvinToCelsius;
    procedure Test39_BarToPascal;
    procedure Test40_PascalToBar;
    
    // Tests for edge cases in new functions
    procedure Test41_NewFunctionsEdgeCases;
  end;

implementation

const
  Tolerance = 1E-9;

// Helper methods for exception testing
procedure TTestThermodynamicsKit.ZeroThicknessHeatConductionTest;
begin
  TThermodynamicsKit.HeatConductionRate(0.5, 2.0, 10.0, 0.0);
end;

procedure TTestThermodynamicsKit.ZeroTempEntropyTest;
begin
  TThermodynamicsKit.EntropyChangeReversible(1000.0, 0.0);
end;

procedure TTestThermodynamicsKit.ZeroWorkInputCOPRefrigerationTest;
begin
  TThermodynamicsKit.CoefficientOfPerformanceRefrigeration(5000.0, 0.0);
end;

procedure TTestThermodynamicsKit.ZeroWorkInputCOPHeatPumpTest;
begin
  TThermodynamicsKit.CoefficientOfPerformanceHeatPump(6000.0, 0.0);
end;

procedure TTestThermodynamicsKit.LowCompressionRatioOttoTest;
begin
  TThermodynamicsKit.OttoCycleEfficiency(1.0, 1.4);
end;

procedure TTestThermodynamicsKit.LowGammaOttoTest;
begin
  TThermodynamicsKit.OttoCycleEfficiency(8.0, 1.0);
end;

procedure TTestThermodynamicsKit.LowCompressionRatioDieselTest;
begin
  TThermodynamicsKit.DieselCycleEfficiency(1.0, 2.0, 1.4);
end;

procedure TTestThermodynamicsKit.LowCutoffRatioDieselTest;
begin
  TThermodynamicsKit.DieselCycleEfficiency(16.0, 1.0, 1.4);
end;

procedure TTestThermodynamicsKit.LowGammaDieselTest;
begin
  TThermodynamicsKit.DieselCycleEfficiency(16.0, 2.0, 1.0);
end;

procedure TTestThermodynamicsKit.LowPressureRatioBraytonTest;
begin
  TThermodynamicsKit.BraytonCycleEfficiency(1.0, 1.4);
end;

procedure TTestThermodynamicsKit.LowGammaBraytonTest;
begin
  TThermodynamicsKit.BraytonCycleEfficiency(10.0, 1.0);
end;

procedure TTestThermodynamicsKit.ZeroHeatInputRankineTest;
begin
  TThermodynamicsKit.RankineCycleEfficiency(1000.0, 100.0, 0.0);
end;

procedure TTestThermodynamicsKit.NegativeTempKelvinTest;
begin
  TThermodynamicsKit.KelvinToCelsius(-1.0);
end;

procedure TTestThermodynamicsKit.ZeroVaporPressureRHTest;
begin
  TThermodynamicsKit.RelativeHumidity(1000.0, 0.0);
end;

procedure TTestThermodynamicsKit.ZeroRHDewPointTest;
begin
  TThermodynamicsKit.DewPointTemperature(25.0, 0.0);
end;

procedure TTestThermodynamicsKit.HighRHDewPointTest;
begin
  TThermodynamicsKit.DewPointTemperature(25.0, 101.0);
end;

procedure TTestThermodynamicsKit.NegativeHumidityRatioTest;
begin
  TThermodynamicsKit.MoistAirEnthalpy(25.0, -0.01);
end;

// Original test procedures

procedure TTestThermodynamicsKit.Test01_HeatConductionRate;
var
  k, A, dT, d: Double;
begin
  k := 0.5; // W/(m·K)
  A := 2.0; // m²
  dT := 10.0; // K
  d := 0.1; // m
  AssertEquals('Heat Conduction Rate', 100.0, TThermodynamicsKit.HeatConductionRate(k, A, dT, d), Tolerance);
end;

procedure TTestThermodynamicsKit.Test02_HeatConvectionRate;
var
  h, A, dT: Double;
begin
  h := 50.0; // W/(m²·K) (convection coefficient)
  A := 2.0; // m²
  dT := 10.0; // K
  AssertEquals('Heat Convection Rate', h*A*dT, TThermodynamicsKit.HeatConvectionRate(h, A, dT), Tolerance);
end;

procedure TTestThermodynamicsKit.Test03_HeatRadiationRate;
var
  e, A, T1, T2: Double;
begin
  e := 0.9; // emissivity (dimensionless)
  A := 2.0; // m²
  T1 := 373.15; // K (100°C)
  T2 := 293.15; // K (20°C)
  AssertEquals('Heat Radiation Rate', e*TThermodynamicsKit.StefanBoltzmannConstant*A*(Power(T1, 4)-Power(T2, 4)), 
               TThermodynamicsKit.HeatRadiationRate(e, A, T1, T2), Tolerance);
end;

procedure TTestThermodynamicsKit.Test04_HeatEnergyChange;
var
  m, c, dT: Double;
begin
  m := 5.0; // kg
  c := 4200.0; // J/(kg·K) (specific heat capacity of water)
  dT := 10.0; // K
  AssertEquals('Heat Energy Change', m*c*dT, TThermodynamicsKit.HeatEnergyChange(m, c, dT), Tolerance);
end;

procedure TTestThermodynamicsKit.Test05_EntropyChangeReversible;
var
  Q, T: Double;
begin
  Q := 1000.0; // J
  T := 300.0; // K
  AssertEquals('Entropy Change Reversible', Q/T, TThermodynamicsKit.EntropyChangeReversible(Q, T), Tolerance);
end;

procedure TTestThermodynamicsKit.Test06_EntropyChangeHeating;
var
  m, c, T1, T2: Double;
begin
  m := 1.0; // kg
  c := 4200.0; // J/(kg·K)
  T1 := 293.15; // K (20°C)
  T2 := 373.15; // K (100°C)
  AssertEquals('Entropy Change Heating', m*c*Ln(T2/T1), TThermodynamicsKit.EntropyChangeHeating(m, c, T1, T2), Tolerance);
end;

procedure TTestThermodynamicsKit.Test07_EntropyChangeIsothermalExpansion;
var
  n, V1, V2: Double;
begin
  n := 1.0; // moles
  V1 := 0.01; // m³
  V2 := 0.02; // m³
  AssertEquals('Entropy Change Isothermal Expansion', n*TThermodynamicsKit.IdealGasConstant*Ln(V2/V1), 
               TThermodynamicsKit.EntropyChangeIsothermalExpansion(n, V1, V2), Tolerance);
end;

procedure TTestThermodynamicsKit.Test08_IdealGasPressure;
var
  n, V, T: Double;
begin
  n := 1.0; // moles
  V := 0.024; // m³
  T := 293.15; // K
  AssertEquals('Ideal Gas Pressure', n*TThermodynamicsKit.IdealGasConstant*T/V, 
               TThermodynamicsKit.IdealGasPressure(n, V, T), Tolerance);
end;

procedure TTestThermodynamicsKit.Test09_IdealGasVolume;
var
  n, P, T: Double;
begin
  n := 1.0; // moles
  P := 101325.0; // Pa
  T := 293.15; // K
  AssertEquals('Ideal Gas Volume', n*TThermodynamicsKit.IdealGasConstant*T/P, 
               TThermodynamicsKit.IdealGasVolume(n, P, T), Tolerance);
end;

procedure TTestThermodynamicsKit.Test10_IdealGasTemperature;
var
  P, V, n: Double;
begin
  P := 101325.0; // Pa
  V := 0.0224; // m³
  n := 1.0; // moles
  AssertEquals('Ideal Gas Temperature', P*V/(n*TThermodynamicsKit.IdealGasConstant), 
               TThermodynamicsKit.IdealGasTemperature(P, V, n), Tolerance);
end;

procedure TTestThermodynamicsKit.Test11_IdealGasMoles;
var
  P, V, T: Double;
begin
  P := 101325.0; // Pa
  V := 0.0224; // m³
  T := 293.15; // K
  AssertEquals('Ideal Gas Moles', P*V/(TThermodynamicsKit.IdealGasConstant*T), 
               TThermodynamicsKit.IdealGasMoles(P, V, T), Tolerance);
end;

procedure TTestThermodynamicsKit.Test12_HeatOfFusion;
var
  m, L: Double;
begin
  m := 1.0; // kg
  L := 334000.0; // J/kg (latent heat of fusion for water)
  AssertEquals('Heat of Fusion', m*L, TThermodynamicsKit.HeatOfFusion(m, L), Tolerance);
end;

procedure TTestThermodynamicsKit.Test13_HeatOfVaporization;
var
  m, L: Double;
begin
  m := 1.0; // kg
  L := 2264000.0; // J/kg (latent heat of vaporization for water)
  AssertEquals('Heat of Vaporization', m*L, TThermodynamicsKit.HeatOfVaporization(m, L), Tolerance);
end;

procedure TTestThermodynamicsKit.Test14_CarnotEfficiency;
var
  T_hot, T_cold: Double;
begin
  T_hot := 500.0; // K
  T_cold := 300.0; // K
  AssertEquals('Carnot Efficiency', 1.0-T_cold/T_hot, TThermodynamicsKit.CarnotEfficiency(T_hot, T_cold), Tolerance);
end;

procedure TTestThermodynamicsKit.Test15_ThermalEfficiency;
var
  Work, Heat: Double;
begin
  Work := 3000.0; // J
  Heat := 10000.0; // J
  AssertEquals('Thermal Efficiency', Work/Heat, TThermodynamicsKit.ThermalEfficiency(Work, Heat), Tolerance);
end;

procedure TTestThermodynamicsKit.Test16_OriginalEdgeCases;
begin
  // Test zero thickness conduction
  AssertException('Conduction zero thickness', EThermodynamicsError, @ZeroThicknessHeatConductionTest);
  // Test zero absolute temperature entropy
  AssertException('Entropy zero temp', EThermodynamicsError, @ZeroTempEntropyTest);
end;

// Tests for additional efficiency metrics
procedure TTestThermodynamicsKit.Test17_CoefficientOfPerformanceRefrigeration;
var
  Q_cold, W_in: Double;
begin
  Q_cold := 5000.0; // J (heat extracted from cold reservoir)
  W_in := 1000.0; // J (work input)
  AssertEquals('COP Refrigeration', Q_cold/W_in, TThermodynamicsKit.CoefficientOfPerformanceRefrigeration(Q_cold, W_in), Tolerance);
  // Edge case: zero work input
  AssertException('COP zero work input', EThermodynamicsError, @ZeroWorkInputCOPRefrigerationTest);
end;

procedure TTestThermodynamicsKit.Test18_CoefficientOfPerformanceHeatPump;
var
  Q_hot, W_in: Double;
begin
  Q_hot := 6000.0; // J (heat delivered to hot reservoir)
  W_in := 1000.0; // J (work input)
  AssertEquals('COP Heat Pump', Q_hot/W_in, TThermodynamicsKit.CoefficientOfPerformanceHeatPump(Q_hot, W_in), Tolerance);
  // Edge case: zero work input
  AssertException('COP HP zero work input', EThermodynamicsError, @ZeroWorkInputCOPHeatPumpTest);
end;

// Tests for thermodynamic cycles
procedure TTestThermodynamicsKit.Test19_OttoCycleEfficiency;
var
  r, gamma: Double;
begin
  r := 8.0; // Compression ratio
  gamma := 1.4; // Specific heat ratio for air
  AssertEquals('Otto Cycle Efficiency', 1.0 - Power(1.0/r, gamma-1), TThermodynamicsKit.OttoCycleEfficiency(r, gamma), Tolerance);
  // Edge cases
  AssertException('Otto r <= 1', EThermodynamicsError, @LowCompressionRatioOttoTest);
  AssertException('Otto gamma <= 1', EThermodynamicsError, @LowGammaOttoTest);
end;

procedure TTestThermodynamicsKit.Test20_DieselCycleEfficiency;
var
  r, alpha, gamma: Double;
  expected: Double;
begin
  r := 16.0; // Compression ratio
  alpha := 2.0; // Cutoff ratio
  gamma := 1.4; // Specific heat ratio
  expected := 1.0 - (1.0/Power(r, gamma-1)) * (Power(alpha, gamma) - 1) / (gamma * (alpha - 1));
  AssertEquals('Diesel Cycle Efficiency', expected, TThermodynamicsKit.DieselCycleEfficiency(r, alpha, gamma), Tolerance);
  // Edge cases
  AssertException('Diesel r <= 1', EThermodynamicsError, @LowCompressionRatioDieselTest);
  AssertException('Diesel alpha <= 1', EThermodynamicsError, @LowCutoffRatioDieselTest);
  AssertException('Diesel gamma <= 1', EThermodynamicsError, @LowGammaDieselTest);
end;

procedure TTestThermodynamicsKit.Test21_BraytonCycleEfficiency;
var
  r, gamma: Double;
begin
  r := 10.0; // Pressure ratio
  gamma := 1.4; // Specific heat ratio
  AssertEquals('Brayton Cycle Efficiency', 1.0 - 1.0/Power(r, (gamma-1)/gamma), TThermodynamicsKit.BraytonCycleEfficiency(r, gamma), Tolerance);
  // Edge cases
  AssertException('Brayton r <= 1', EThermodynamicsError, @LowPressureRatioBraytonTest);
  AssertException('Brayton gamma <= 1', EThermodynamicsError, @LowGammaBraytonTest);
end;

procedure TTestThermodynamicsKit.Test22_RankineCycleEfficiency;
var
  W_turbine, W_pump, Q_in: Double;
begin
  W_turbine := 1000.0; // J
  W_pump := 100.0; // J
  Q_in := 3000.0; // J
  AssertEquals('Rankine Cycle Efficiency', (W_turbine - W_pump)/Q_in, TThermodynamicsKit.RankineCycleEfficiency(W_turbine, W_pump, Q_in), Tolerance);
  // Edge case: zero heat input
  AssertException('Rankine zero heat input', EThermodynamicsError, @ZeroHeatInputRankineTest);
end;

procedure TTestThermodynamicsKit.Test23_AdiabaticPressure;
var
  P1, V1, V2, gamma: Double;
begin
  P1 := 100000.0; // Pa
  V1 := 0.01; // m³
  V2 := 0.005; // m³
  gamma := 1.4; // specific heat ratio
  AssertEquals('Adiabatic Pressure', P1*Power(V1/V2, gamma), 
               TThermodynamicsKit.AdiabaticPressure(P1, V1, V2, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test24_AdiabaticVolume;
var
  P1, V1, P2, gamma: Double;
begin
  P1 := 100000.0; // Pa
  V1 := 0.01; // m³
  P2 := 200000.0; // Pa
  gamma := 1.4; // specific heat ratio
  AssertEquals('Adiabatic Volume', V1*Power(P1/P2, 1/gamma), 
               TThermodynamicsKit.AdiabaticVolume(P1, V1, P2, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test25_AdiabaticTemperature;
var
  T1, V1, V2, gamma: Double;
begin
  T1 := 300.0; // K
  V1 := 0.01; // m³
  V2 := 0.005; // m³
  gamma := 1.4; // specific heat ratio
  AssertEquals('Adiabatic Temperature', T1*Power(V1/V2, gamma-1), 
               TThermodynamicsKit.AdiabaticTemperature(T1, V1, V2, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test26_AdiabaticTemperatureFromPressure;
var
  T1, P1, P2, gamma: Double;
begin
  T1 := 300.0; // K
  P1 := 100000.0; // Pa
  P2 := 200000.0; // Pa
  gamma := 1.4; // specific heat ratio
  AssertEquals('Adiabatic Temperature From Pressure', T1*Power(P2/P1, (gamma-1)/gamma), 
               TThermodynamicsKit.AdiabaticTemperatureFromPressure(T1, P1, P2, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test27_CriticalPressureRatio;
var
  gamma: Double;
  expected: Double;
begin
  gamma := 1.4; // specific heat ratio for air
  expected := Power(2/(gamma+1), gamma/(gamma-1));
  AssertEquals('Critical Pressure Ratio', expected, TThermodynamicsKit.CriticalPressureRatio(gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test28_MachNumberFromPressureRatio;
var
  PR, gamma: Double;
  expected: Double;
  exponent: Double;
begin
  PR := 0.5; // pressure ratio
  gamma := 1.4; // specific heat ratio
  exponent := (gamma-1)/gamma;
  expected := Sqrt(2/(gamma-1) * (Power(1/PR, exponent) - 1));
  AssertEquals('Mach Number From Pressure Ratio', expected, 
               TThermodynamicsKit.MachNumberFromPressureRatio(PR, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test29_IsentropicTemperatureRatio;
var
  M, gamma: Double;
begin
  M := 0.8; // Mach number
  gamma := 1.4; // specific heat ratio
  AssertEquals('Isentropic Temperature Ratio', 1 + ((gamma-1)/2)*Sqr(M), 
               TThermodynamicsKit.IsentropicTemperatureRatio(M, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test30_IsentropicPressureRatio;
var
  M, gamma: Double;
  expected: Double;
begin
  M := 0.8; // Mach number
  gamma := 1.4; // specific heat ratio
  expected := Power(1 + ((gamma-1)/2)*Sqr(M), -gamma/(gamma-1));
  AssertEquals('Isentropic Pressure Ratio', expected, 
               TThermodynamicsKit.IsentropicPressureRatio(M, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test31_IsentropicDensityRatio;
var
  M, gamma: Double;
  expected: Double;
begin
  M := 0.8; // Mach number
  gamma := 1.4; // specific heat ratio
  expected := Power(1 + ((gamma-1)/2)*Sqr(M), -1/(gamma-1));
  AssertEquals('Isentropic Density Ratio', expected, 
               TThermodynamicsKit.IsentropicDensityRatio(M, gamma), Tolerance);
end;

procedure TTestThermodynamicsKit.Test32_RelativeHumidity;
var
  Pv, Pvs: Double;
begin
  Pv := 1000.0; // Pa (vapor pressure)
  Pvs := 2000.0; // Pa (saturated vapor pressure)
  AssertEquals('Relative Humidity', (Pv/Pvs)*100, TThermodynamicsKit.RelativeHumidity(Pv, Pvs), Tolerance);
end;

procedure TTestThermodynamicsKit.Test33_SaturatedVaporPressure;
var
  T: Double;
  A, B, C: Double;
  expected: Double;
begin
  T := 25.0; // °C
  // Antoine equation constants for water
  A := 8.07131;
  B := 1730.63;
  C := 233.426;
  expected := Power(10, A - (B / (T + C))) * 133.322; // mmHg to Pa
  AssertEquals('Saturated Vapor Pressure', expected, TThermodynamicsKit.SaturatedVaporPressure(T), Tolerance);
end;

procedure TTestThermodynamicsKit.Test34_HumidityRatio;
var
  Pv, P: Double;
begin
  Pv := 2000.0; // Pa (vapor pressure)
  P := 101325.0; // Pa (atmospheric pressure)
  AssertEquals('Humidity Ratio', 0.622 * (Pv / (P - Pv)), TThermodynamicsKit.HumidityRatio(Pv, P), Tolerance);
end;

procedure TTestThermodynamicsKit.Test35_DewPointTemperature;
var
  T, RH: Double;
  A, B: Double;
  alpha, expected: Double;
begin
  T := 25.0; // °C
  RH := 50.0; // %
  // Magnus formula constants
  A := 17.27;
  B := 237.7;
  alpha := Ln(RH / 100) + (A * T) / (B + T);
  expected := (B * alpha) / (A - alpha);
  AssertEquals('Dew Point Temperature', expected, TThermodynamicsKit.DewPointTemperature(T, RH), Tolerance);
end;

procedure TTestThermodynamicsKit.Test36_MoistAirEnthalpy;
var
  T, w: Double;
begin
  T := 25.0; // °C
  w := 0.01; // kg/kg (humidity ratio)
  AssertEquals('Moist Air Enthalpy', 1.005 * T + w * (2501 + 1.82 * T), 
               TThermodynamicsKit.MoistAirEnthalpy(T, w), Tolerance);
end;

procedure TTestThermodynamicsKit.Test37_CelsiusToKelvin;
begin
  AssertEquals('Celsius to Kelvin', 273.15, TThermodynamicsKit.CelsiusToKelvin(0.0), Tolerance);
  AssertEquals('Celsius to Kelvin', 373.15, TThermodynamicsKit.CelsiusToKelvin(100.0), Tolerance);
end;

procedure TTestThermodynamicsKit.Test38_KelvinToCelsius;
begin
  AssertEquals('Kelvin to Celsius', 25.0, TThermodynamicsKit.KelvinToCelsius(298.15), Tolerance);
  AssertEquals('Kelvin to Celsius (freezing)', 0.0, TThermodynamicsKit.KelvinToCelsius(273.15), Tolerance);
  AssertEquals('Kelvin to Celsius (boiling)', 100.0, TThermodynamicsKit.KelvinToCelsius(373.15), Tolerance);
  // Edge case
  AssertException('Kelvin to Celsius negative temperature', EThermodynamicsError, @NegativeTempKelvinTest);
end;

procedure TTestThermodynamicsKit.Test39_BarToPascal;
begin
  AssertEquals('Bar to Pascal', 100000.0, TThermodynamicsKit.BarToPascal(1.0), Tolerance);
  AssertEquals('Bar to Pascal (1 atm)', 101325.0, TThermodynamicsKit.BarToPascal(1.01325), Tolerance);
end;

procedure TTestThermodynamicsKit.Test40_PascalToBar;
begin
  AssertEquals('Pascal to Bar', 1.0, TThermodynamicsKit.PascalToBar(100000.0), Tolerance);
  AssertEquals('Pascal to Bar (1 atm)', 1.01325, TThermodynamicsKit.PascalToBar(101325.0), Tolerance);
end;

procedure TTestThermodynamicsKit.Test41_NewFunctionsEdgeCases;
begin
  // Psychrometrics edge cases
  AssertException('Dew point zero RH', EThermodynamicsError, @ZeroRHDewPointTest);
  AssertException('Dew point RH > 100%', EThermodynamicsError, @HighRHDewPointTest);
  
  // Thermodynamic cycles edge cases
  AssertException('Otto cycle compression ratio = 1', EThermodynamicsError, @LowCompressionRatioOttoTest);
  AssertException('Otto cycle gamma = 1', EThermodynamicsError, @LowGammaOttoTest);
  AssertException('Diesel cycle compression ratio = 1', EThermodynamicsError, @LowCompressionRatioDieselTest);
  AssertException('Diesel cycle cutoff ratio = 1', EThermodynamicsError, @LowCutoffRatioDieselTest);
  AssertException('Diesel cycle gamma = 1', EThermodynamicsError, @LowGammaDieselTest);
  AssertException('Brayton cycle pressure ratio = 1', EThermodynamicsError, @LowPressureRatioBraytonTest);
  AssertException('Brayton cycle gamma = 1', EThermodynamicsError, @LowGammaBraytonTest);
  AssertException('Rankine cycle zero heat input', EThermodynamicsError, @ZeroHeatInputRankineTest);
  
  // Unit conversion edge cases
  AssertException('Kelvin negative temperature', EThermodynamicsError, @NegativeTempKelvinTest);
end;

initialization
  RegisterTest(TTestThermodynamicsKit);
end.
