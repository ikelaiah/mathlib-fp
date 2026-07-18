unit TestEngineeringLib_FluidDynamics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  EngineeringLib.Common, EngineeringLib.FluidDynamics;

type

  { TTestFluidDynamicsKit }

  TTestFluidDynamicsKit = class(TTestCase)
  private
    // Add helper methods for exception testing
    procedure BernoulliPressureTest;
    procedure BernoulliVelocityTest;
    procedure ReynoldsNumberTest;
    procedure ReynoldsNumberKinematicTest;
    procedure LaminarFrictionFactorTest;
    procedure TurbulentFrictionFactorTest;
    procedure ZeroTurbulentToleranceTest;
    procedure ZeroTurbulentIterationsTest;
    procedure BlasiusFrictionFactorLowTest;
    procedure BlasiusFrictionFactorHighTest;
    procedure ZeroDiameterHeadLossTest;
    procedure ZeroDiameterHazenWilliamsTest;
    procedure ZeroCHWCoefficientTest;
    procedure ZeroLengthFroudeNumberTest;
    procedure ZeroSurfaceTensionWeberNumberTest;
    procedure ZeroDensityEulerNumberTest;
    procedure ZeroVelocityEulerNumberTest;
    procedure ZeroSpeedOfSoundMachNumberTest;
    procedure GammaEqualsOneSpeedOfSoundTest;
    procedure ZeroMachNumberAreaRatioTest;
    procedure ZeroEfficiencyPumpPowerTest;
    procedure NegativeFlowPumpPowerTest;
    procedure NegativeFlowTurbinePowerTest;
    procedure ZeroRPMSpecificSpeedTest;
    procedure ZeroFlowRateSpecificSpeedTest;
    procedure ZeroHeadSpecificSpeedTest;
    procedure ZeroChezyCoeffientTest;
    procedure ZeroDepthFroudeNumberTest;
  published
    // Original tests
    procedure Test01_BernoulliPressure;
    procedure Test02_BernoulliVelocity;
    procedure Test03_BernoulliHeight;
    procedure Test04_VolumeFlowRate;
    procedure Test05_MassFlowRate;
    procedure Test06_ReynoldsNumber;
    procedure Test07_ReynoldsNumberKinematic;
    procedure Test08_FluidProperties;
    procedure Test09_EdgeCases;
    
    // Tests for pipe flow
    procedure Test10_FrictionHeadLoss;
    procedure Test11_HazenWilliamsHeadLoss;
    procedure Test12_LaminarFrictionFactor;
    procedure Test13_TurbulentFrictionFactor;
    procedure Test14_BlasiusFrictionFactor;
    
    // Tests for dimensional analysis
    procedure Test15_FroudeNumber;
    procedure Test16_WeberNumber;
    procedure Test17_EulerNumber;
    procedure Test18_MachNumber;
    procedure Test19_StrouhalNumber;
    procedure Test20_PrandtlNumber;
    procedure Test21_NusseltNumber;
    
    // Tests for aerodynamics
    procedure Test22_LiftForce;
    procedure Test23_DragForce;
    procedure Test24_DynamicPressure;
    procedure Test25_StagnationPressure;
    procedure Test26_PressureCoefficient;
    
    // Tests for compressible flow
    procedure Test27_SpeedOfSound;
    procedure Test28_StagnationTemperatureRatio;
    procedure Test29_StagnationPressureRatio;
    procedure Test30_IsentropicAreaRatio;
    
    // Tests for pumps and turbines
    procedure Test31_PumpPower;
    procedure Test32_PumpHead;
    procedure Test33_PumpSpecificSpeed;
    procedure Test34_TurbinePower;
    
    // Tests for open channel flow
    procedure Test35_ChezyVelocity;
    procedure Test36_ManningVelocity;
    procedure Test37_CriticalDepthRectangular;
    procedure Test38_OpenChannelFroudeNumber;
    
    // Tests for edge cases in new functions
    procedure Test39_NewFunctionsEdgeCases;
    procedure Test40_TurbulentSolverValidation;
    procedure Test41_BlasiusBoundaryValues;
    procedure Test42_PowerFlowValidation;
  end;

implementation

const
  Tolerance = 1E-9;
  DensityWater = 997.0; // kg/m³
  Gravity = 9.80665; // m/s²

procedure TTestFluidDynamicsKit.BernoulliPressureTest;
begin
  TFluidDynamicsKit.BernoulliPressure(0.0, 101325.0, 1.0, 1.0, 1.0, 1.0);
end;

procedure TTestFluidDynamicsKit.BernoulliVelocityTest;
begin
  TFluidDynamicsKit.BernoulliVelocity(DensityWater, 101325.0, 1.0, 1.0, 101325.0 + 1E6, 1.0);
end;

procedure TTestFluidDynamicsKit.ReynoldsNumberTest;
begin
  TFluidDynamicsKit.ReynoldsNumber(DensityWater, 1.0, 0.1, 0.0);
end;

procedure TTestFluidDynamicsKit.ReynoldsNumberKinematicTest;
begin
  TFluidDynamicsKit.ReynoldsNumberKinematic(1.0, 0.1, 0.0);
end;

procedure TTestFluidDynamicsKit.LaminarFrictionFactorTest;
begin
  TFluidDynamicsKit.LaminarFrictionFactor(2500.0);
end;

procedure TTestFluidDynamicsKit.TurbulentFrictionFactorTest;
begin
  TFluidDynamicsKit.TurbulentFrictionFactor(3000.0, 0.0001);
end;

procedure TTestFluidDynamicsKit.ZeroTurbulentToleranceTest;
begin
  TFluidDynamicsKit.TurbulentFrictionFactor(100000.0, 0.0001, 0.0, 100);
end;

procedure TTestFluidDynamicsKit.ZeroTurbulentIterationsTest;
begin
  TFluidDynamicsKit.TurbulentFrictionFactor(100000.0, 0.0001, 1E-6, 0);
end;

procedure TTestFluidDynamicsKit.BlasiusFrictionFactorLowTest;
begin
  TFluidDynamicsKit.BlasiusFrictionFactor(3000.0);
end;

procedure TTestFluidDynamicsKit.BlasiusFrictionFactorHighTest;
begin
  TFluidDynamicsKit.BlasiusFrictionFactor(150000.0);
end;

procedure TTestFluidDynamicsKit.ZeroDiameterHeadLossTest;
begin
  TFluidDynamicsKit.FrictionHeadLoss(0.02, 100.0, 0.0, 2.0);
end;

procedure TTestFluidDynamicsKit.ZeroDiameterHazenWilliamsTest;
begin
  TFluidDynamicsKit.HazenWilliamsHeadLoss(100.0, 0.0, 0.01, 100.0);
end;

procedure TTestFluidDynamicsKit.ZeroCHWCoefficientTest;
begin
  TFluidDynamicsKit.HazenWilliamsHeadLoss(100.0, 0.1, 0.01, 0.0);
end;

procedure TTestFluidDynamicsKit.ZeroLengthFroudeNumberTest;
begin
  TFluidDynamicsKit.FroudeNumber(5.0, 0.0);
end;

procedure TTestFluidDynamicsKit.ZeroSurfaceTensionWeberNumberTest;
begin
  TFluidDynamicsKit.WeberNumber(997.0, 10.0, 0.05, 0.0);
end;

procedure TTestFluidDynamicsKit.ZeroDensityEulerNumberTest;
begin
  TFluidDynamicsKit.EulerNumber(5000.0, 0.0, 2.0);
end;

procedure TTestFluidDynamicsKit.ZeroVelocityEulerNumberTest;
begin
  TFluidDynamicsKit.EulerNumber(5000.0, 997.0, 0.0);
end;

procedure TTestFluidDynamicsKit.ZeroSpeedOfSoundMachNumberTest;
begin
  TFluidDynamicsKit.MachNumber(340.0, 0.0);
end;

procedure TTestFluidDynamicsKit.GammaEqualsOneSpeedOfSoundTest;
begin
  TFluidDynamicsKit.SpeedOfSound(1.0, 287.0, 293.15);
end;

procedure TTestFluidDynamicsKit.ZeroMachNumberAreaRatioTest;
begin
  TFluidDynamicsKit.IsentropicAreaRatio(0.0, 1.4);
end;

procedure TTestFluidDynamicsKit.ZeroEfficiencyPumpPowerTest;
begin
  TFluidDynamicsKit.PumpPower(997.0, 0.05, 10.0, 0.0);
end;

procedure TTestFluidDynamicsKit.NegativeFlowPumpPowerTest;
begin
  TFluidDynamicsKit.PumpPower(DensityWater, -0.1, 10.0, 0.8);
end;

procedure TTestFluidDynamicsKit.NegativeFlowTurbinePowerTest;
begin
  TFluidDynamicsKit.TurbinePower(0.8, DensityWater, -0.1, 10.0);
end;

procedure TTestFluidDynamicsKit.ZeroRPMSpecificSpeedTest;
begin
  TFluidDynamicsKit.PumpSpecificSpeed(0.0, 0.1, 20.0);
end;

procedure TTestFluidDynamicsKit.ZeroFlowRateSpecificSpeedTest;
begin
  TFluidDynamicsKit.PumpSpecificSpeed(1450.0, 0.0, 20.0);
end;

procedure TTestFluidDynamicsKit.ZeroHeadSpecificSpeedTest;
begin
  TFluidDynamicsKit.PumpSpecificSpeed(1450.0, 0.1, 0.0);
end;

procedure TTestFluidDynamicsKit.ZeroChezyCoeffientTest;
begin
  TFluidDynamicsKit.ChezyVelocity(0.0, 1.0, 0.001);
end;

procedure TTestFluidDynamicsKit.ZeroDepthFroudeNumberTest;
begin
  TFluidDynamicsKit.OpenChannelFroudeNumber(5.0, 0.0);
end;

procedure TTestFluidDynamicsKit.Test01_BernoulliPressure;
var
  rho, P1, v1, h1, v2, h2, ExpectedP2: Double;
begin
  rho := DensityWater;
  P1 := 101325.0; // Pa
  v1 := 2.0; // m/s
  h1 := 10.0; // m
  v2 := 5.0; // m/s
  h2 := 5.0; // m
  ExpectedP2 := P1 + 0.5 * rho * (Sqr(v1) - Sqr(v2)) + rho * Gravity * (h1 - h2);
  AssertEquals('Bernoulli Pressure', ExpectedP2, TFluidDynamicsKit.BernoulliPressure(rho, P1, v1, h1, v2, h2), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test02_BernoulliVelocity;
var
  rho, P1, v1, h1, P2, h2, ExpectedV2: Double;
begin
  rho := DensityWater;
  P1 := 110000.0; // Pa
  v1 := 1.0; // m/s
  h1 := 2.0; // m
  P2 := 101325.0; // Pa
  h2 := 1.0; // m
  ExpectedV2 := Sqrt(Sqr(v1) + 2 * (P1 - P2) / rho + 2 * Gravity * (h1 - h2));
  AssertEquals('Bernoulli Velocity', ExpectedV2, TFluidDynamicsKit.BernoulliVelocity(rho, P1, v1, h1, P2, h2), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test03_BernoulliHeight;
var
  rho, P1, v1, h1, P2, v2, ExpectedH2: Double;
begin
  rho := DensityWater;
  P1 := 101325.0; // Pa
  v1 := 5.0; // m/s
  h1 := 10.0; // m
  P2 := 110000.0; // Pa
  v2 := 2.0; // m/s
  ExpectedH2 := h1 + (P1 - P2) / (rho * Gravity) + (Sqr(v1) - Sqr(v2)) / (2 * Gravity);
  AssertEquals('Bernoulli Height', ExpectedH2, TFluidDynamicsKit.BernoulliHeight(rho, P1, v1, h1, P2, v2), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test04_VolumeFlowRate;
var
  A, v: Double;
begin
  A := 0.01; // m²
  v := 5.0; // m/s
  AssertEquals('Volume Flow Rate', 0.05, TFluidDynamicsKit.CalculateVolumeFlowRate(A, v), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test05_MassFlowRate;
var
  rho, A, v, Q: Double;
begin
  rho := DensityWater;
  A := 0.01; // m²
  v := 5.0; // m/s
  Q := 0.05; // m³/s
  AssertEquals('Mass Flow Rate (rho, A, v)', rho * A * v, TFluidDynamicsKit.MassFlowRate(rho, A, v), Tolerance);
  AssertEquals('Mass Flow Rate (rho, Q)', rho * Q, TFluidDynamicsKit.MassFlowRate(rho, Q), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test06_ReynoldsNumber;
var
  rho, v, L, mu: Double;
begin
  rho := DensityWater;
  v := 1.0; // m/s
  L := 0.1; // m (characteristic length, e.g., pipe diameter)
  mu := 8.90E-4; // Pa·s (dynamic viscosity of water at 25°C)
  AssertEquals('Reynolds Number', (rho * v * L) / mu, TFluidDynamicsKit.ReynoldsNumber(rho, v, L, mu), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test07_ReynoldsNumberKinematic;
var
  v, L, nu: Double;
begin
  v := 1.0; // m/s
  L := 0.1; // m
  nu := 8.90E-4 / DensityWater; // m²/s (kinematic viscosity)
  AssertEquals('Reynolds Number Kinematic', (v * L) / nu, TFluidDynamicsKit.ReynoldsNumberKinematic(v, L, nu), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test08_FluidProperties;
begin
  AssertEquals('Density Water', 997.0, TFluidDynamicsKit.DensityWater, Tolerance);
  AssertEquals('Dynamic Viscosity Water', 8.90E-4, TFluidDynamicsKit.DynamicViscosityWater, Tolerance);
  AssertEquals('Kinematic Viscosity Water', 8.90E-4 / 997.0, TFluidDynamicsKit.KinematicViscosityWater, Tolerance);
end;

procedure TTestFluidDynamicsKit.Test09_EdgeCases;
begin
  // Test zero density - using a temporary method to avoid array parameter issue
  AssertException('Bernoulli zero density', EFluidDynamicsError, @BernoulliPressureTest);
                  
  // Test negative velocity squared result in BernoulliVelocity
  AssertException('Bernoulli negative velocity sq', EFluidDynamicsError, @BernoulliVelocityTest);
                  
  // Test zero viscosity
  AssertException('Reynolds zero dynamic viscosity', EFluidDynamicsError, @ReynoldsNumberTest);
                  
  AssertException('Reynolds zero kinematic viscosity', EFluidDynamicsError, @ReynoldsNumberKinematicTest);
                  
  // Test zero area flow rate
  AssertEquals('Volume Flow Rate zero area', 0.0, TFluidDynamicsKit.CalculateVolumeFlowRate(0.0, 5.0), Tolerance);
  // Test zero velocity flow rate
  AssertEquals('Volume Flow Rate zero velocity', 0.0, TFluidDynamicsKit.CalculateVolumeFlowRate(0.1, 0.0), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test12_LaminarFrictionFactor;
var
  Re: Double;
begin
  Re := 1000.0;
  AssertEquals('Laminar Friction Factor', 64.0/Re, TFluidDynamicsKit.LaminarFrictionFactor(Re), Tolerance);
  // Test edge case - Reynolds number too high
  AssertException('Laminar friction factor above Re=2300', EFluidDynamicsError, @LaminarFrictionFactorTest);
end;

procedure TTestFluidDynamicsKit.Test13_TurbulentFrictionFactor;
var
  Re, RelRough: Double;
  f: Double;
begin
  Re := 10000.0;
  RelRough := 0.0001; // Relative roughness (ε/D)
  // Compare against Haaland equation approximation for this test
  f := Power(1 / (-1.8 * Log10(Power(RelRough / 3.7, 1.11) + 6.9 / Re)), 2);
  AssertEquals('Turbulent Friction Factor', f, TFluidDynamicsKit.TurbulentFrictionFactor(Re, RelRough), 1E-4);
  // Test edge case - Reynolds number too low
  AssertException('Turbulent friction factor below Re=4000', EFluidDynamicsError, @TurbulentFrictionFactorTest);
end;

procedure TTestFluidDynamicsKit.Test14_BlasiusFrictionFactor;
var
  Re: Double;
begin
  Re := 10000.0;
  AssertEquals('Blasius Friction Factor', 0.316/Power(Re, 0.25), TFluidDynamicsKit.BlasiusFrictionFactor(Re), Tolerance);
  // Test edge cases outside valid range
  AssertException('Blasius friction factor below Re=4000', EFluidDynamicsError, @BlasiusFrictionFactorLowTest);
  AssertException('Blasius friction factor above Re=100000', EFluidDynamicsError, @BlasiusFrictionFactorHighTest);
end;

procedure TTestFluidDynamicsKit.Test10_FrictionHeadLoss;
var
  f, L, D, v: Double;
  ExpectedHeadLoss: Double;
begin
  f := 0.02; // Darcy friction factor
  L := 100.0; // m
  D := 0.1; // m
  v := 2.0; // m/s
  ExpectedHeadLoss := f * (L/D) * (Sqr(v)/(2*Gravity));
  AssertEquals('Friction Head Loss', ExpectedHeadLoss, TFluidDynamicsKit.FrictionHeadLoss(f, L, D, v), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test11_HazenWilliamsHeadLoss;
var
  L, D, Q, C_HW: Double;
  ExpectedHeadLoss: Double;
  K: Double;
begin
  L := 100.0; // m
  D := 0.1; // m
  Q := 0.01; // m³/s
  C_HW := 100.0; // Hazen-Williams coefficient for cast iron
  K := 10.67; // Constant for SI units
  ExpectedHeadLoss := K * (Power(Q, 1.85) / Power(C_HW, 1.85)) * (L / Power(D, 4.87));
  AssertEquals('Hazen-Williams Head Loss', ExpectedHeadLoss, TFluidDynamicsKit.HazenWilliamsHeadLoss(L, D, Q, C_HW), 1E-6);
end;

procedure TTestFluidDynamicsKit.Test15_FroudeNumber;
var
  v, L: Double;
begin
  v := 5.0; // m/s
  L := 2.0; // m (characteristic length)
  AssertEquals('Froude Number', v/Sqrt(Gravity*L), TFluidDynamicsKit.FroudeNumber(v, L), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test16_WeberNumber;
var
  rho, v, L, sigma: Double;
begin
  rho := DensityWater; // kg/m³
  v := 10.0; // m/s
  L := 0.05; // m (characteristic length)
  sigma := 0.073; // N/m (surface tension of water at 20°C)
  AssertEquals('Weber Number', (rho*Sqr(v)*L)/sigma, TFluidDynamicsKit.WeberNumber(rho, v, L, sigma), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test17_EulerNumber;
var
  dP, rho, v: Double;
begin
  dP := 5000.0; // Pa (pressure difference)
  rho := DensityWater; // kg/m³
  v := 2.0; // m/s
  AssertEquals('Euler Number', dP/(rho*Sqr(v)), TFluidDynamicsKit.EulerNumber(dP, rho, v), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test18_MachNumber;
var
  v, c: Double;
begin
  v := 340.0; // m/s
  c := 343.0; // m/s (speed of sound in air at 20°C)
  AssertEquals('Mach Number', v/c, TFluidDynamicsKit.MachNumber(v, c), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test19_StrouhalNumber;
var
  f, L, v: Double;
begin
  f := 10.0; // Hz
  L := 0.1; // m
  v := 5.0; // m/s
  AssertEquals('Strouhal Number', (f*L)/v, TFluidDynamicsKit.StrouhalNumber(f, L, v), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test20_PrandtlNumber;
var
  mu, cp, k: Double;
begin
  mu := 8.90E-4; // Pa·s (dynamic viscosity)
  cp := 4184.0; // J/(kg·K) (specific heat capacity)
  k := 0.6; // W/(m·K) (thermal conductivity)
  AssertEquals('Prandtl Number', (mu*cp)/k, TFluidDynamicsKit.PrandtlNumber(mu, cp, k), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test21_NusseltNumber;
var
  h, L, k: Double;
begin
  h := 100.0; // W/(m²·K) (heat transfer coefficient)
  L := 0.1; // m
  k := 0.6; // W/(m·K) (thermal conductivity)
  AssertEquals('Nusselt Number', (h*L)/k, TFluidDynamicsKit.NusseltNumber(h, L, k), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test22_LiftForce;
var
  CL, rho, v, A: Double;
begin
  CL := 0.5; // Lift coefficient
  rho := 1.225; // kg/m³ (air density)
  v := 100.0; // m/s
  A := 20.0; // m² (reference area)
  AssertEquals('Lift Force', CL*0.5*rho*Sqr(v)*A, TFluidDynamicsKit.LiftForce(CL, rho, v, A), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test23_DragForce;
var
  CD, rho, v, A: Double;
begin
  CD := 0.3; // Drag coefficient
  rho := 1.225; // kg/m³ (air density)
  v := 100.0; // m/s
  A := 2.0; // m² (frontal area)
  AssertEquals('Drag Force', CD*0.5*rho*Sqr(v)*A, TFluidDynamicsKit.DragForce(CD, rho, v, A), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test24_DynamicPressure;
var
  rho, v: Double;
begin
  rho := 1.225; // kg/m³
  v := 100.0; // m/s
  AssertEquals('Dynamic Pressure', 0.5*rho*Sqr(v), TFluidDynamicsKit.DynamicPressure(rho, v), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test25_StagnationPressure;
var
  p, q: Double;
begin
  p := 101325.0; // Pa (static pressure)
  q := 5000.0; // Pa (dynamic pressure)
  AssertEquals('Stagnation Pressure', p+q, TFluidDynamicsKit.StagnationPressure(p, q), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test26_PressureCoefficient;
var
  p, pInf, rhoInf, vInf, q: Double;
begin
  p := 105000.0; // Pa (pressure at point)
  pInf := 101325.0; // Pa (freestream pressure)
  rhoInf := 1.225; // kg/m³ (freestream density)
  vInf := 100.0; // m/s (freestream velocity)
  q := 0.5 * rhoInf * Sqr(vInf);
  AssertEquals('Pressure Coefficient', (p-pInf)/q, TFluidDynamicsKit.PressureCoefficient(p, pInf, rhoInf, vInf), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test27_SpeedOfSound;
var
  gamma, R, T: Double;
begin
  gamma := 1.4; // Specific heat ratio for air
  R := 287.0; // J/(kg·K) (specific gas constant for air)
  T := 293.15; // K (20°C)
  AssertEquals('Speed of Sound', Sqrt(gamma*R*T), TFluidDynamicsKit.SpeedOfSound(gamma, R, T), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test28_StagnationTemperatureRatio;
var
  M, gamma: Double;
begin
  M := 0.8; // Mach number
  gamma := 1.4; // Specific heat ratio
  AssertEquals('Stagnation Temperature Ratio', 1 + ((gamma-1)/2)*Sqr(M), TFluidDynamicsKit.StagnationTemperatureRatio(M, gamma), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test29_StagnationPressureRatio;
var
  M, gamma: Double;
  expectedRatio: Double;
begin
  M := 0.8; // Mach number
  gamma := 1.4; // Specific heat ratio
  expectedRatio := Power(1 + ((gamma-1)/2)*Sqr(M), gamma/(gamma-1));
  AssertEquals('Stagnation Pressure Ratio', expectedRatio, TFluidDynamicsKit.StagnationPressureRatio(M, gamma), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test30_IsentropicAreaRatio;
var
  M, gamma: Double;
  term1, term2, expectedRatio: Double;
begin
  M := 2.0; // Mach number
  gamma := 1.4; // Specific heat ratio
  term1 := 1/M;
  term2 := Power((2/(gamma+1))*(1+((gamma-1)/2)*Sqr(M)), (gamma+1)/(2*(gamma-1)));
  expectedRatio := term1 * term2;
  AssertEquals('Isentropic Area Ratio', expectedRatio, TFluidDynamicsKit.IsentropicAreaRatio(M, gamma), 1E-6);
end;

procedure TTestFluidDynamicsKit.Test31_PumpPower;
var
  rho, Q, H, eta: Double;
begin
  rho := DensityWater; // kg/m³
  Q := 0.05; // m³/s
  H := 10.0; // m
  eta := 0.75; // Efficiency
  AssertEquals('Pump Power', (rho*Gravity*Q*H)/eta, TFluidDynamicsKit.PumpPower(rho, Q, H, eta), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test32_PumpHead;
var
  dP, rho, v1, v2, dh: Double;
  expectedHead: Double;
begin
  dP := 200000.0; // Pa (pressure difference)
  rho := DensityWater; // kg/m³
  v1 := 1.0; // m/s (inlet velocity)
  v2 := 4.0; // m/s (outlet velocity)
  dh := 5.0; // m (height difference)
  expectedHead := dP/(rho*Gravity) + (Sqr(v2)-Sqr(v1))/(2*Gravity) + dh;
  AssertEquals('Pump Head', expectedHead,
    TFluidDynamicsKit.PumpHead(dP, rho, v1, v2, dh), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test33_PumpSpecificSpeed;
var
  rpm, Q, H: Double;
begin
  rpm := 1450.0; // RPM
  Q := 0.1; // m³/s
  H := 20.0; // m
  AssertEquals('Pump Specific Speed', rpm*Sqrt(Q)/Power(H, 0.75), TFluidDynamicsKit.PumpSpecificSpeed(rpm, Q, H), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test34_TurbinePower;
var
  eta, rho, Q, H: Double;
begin
  eta := 0.85; // Efficiency
  rho := DensityWater; // kg/m³
  Q := 10.0; // m³/s
  H := 50.0; // m
  AssertEquals('Turbine Power', eta*rho*Gravity*Q*H, TFluidDynamicsKit.TurbinePower(eta, rho, Q, H), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test35_ChezyVelocity;
var
  C, R, S: Double;
begin
  C := 50.0; // Chezy coefficient
  R := 1.0; // m (hydraulic radius)
  S := 0.001; // Channel slope
  AssertEquals('Chezy Velocity', C*Sqrt(R*S), TFluidDynamicsKit.ChezyVelocity(C, R, S), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test36_ManningVelocity;
var
  n, R, S: Double;
begin
  n := 0.015; // Manning coefficient
  R := 1.0; // m (hydraulic radius)
  S := 0.001; // Channel slope
  AssertEquals('Manning Velocity', (1/n)*Power(R, 2/3)*Power(S, 1/2), TFluidDynamicsKit.ManningVelocity(n, R, S), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test37_CriticalDepthRectangular;
var
  q: Double; // Unit discharge (m³/s per meter width)
begin
  q := 2.0; // m²/s
  AssertEquals('Critical Depth Rectangular', Power(Sqr(q)/Gravity, 1/3), TFluidDynamicsKit.CriticalDepthRectangular(q), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test38_OpenChannelFroudeNumber;
var
  v, y: Double;
begin
  v := 5.0; // m/s
  y := 2.0; // m (depth)
  AssertEquals('Open Channel Froude Number', v/Sqrt(Gravity*y), TFluidDynamicsKit.OpenChannelFroudeNumber(v, y), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test39_NewFunctionsEdgeCases;
begin
  // Pipe flow edge cases
  AssertException('Zero diameter head loss', EFluidDynamicsError, @ZeroDiameterHeadLossTest);
  AssertException('Zero diameter Hazen-Williams', EFluidDynamicsError, @ZeroDiameterHazenWilliamsTest);
  AssertException('Zero C_HW coefficient', EFluidDynamicsError, @ZeroCHWCoefficientTest);
  
  // Dimensional analysis edge cases
  AssertException('Zero length Froude number', EFluidDynamicsError, @ZeroLengthFroudeNumberTest);
  AssertException('Zero surface tension Weber number', EFluidDynamicsError, @ZeroSurfaceTensionWeberNumberTest);
  AssertException('Zero density Euler number', EFluidDynamicsError, @ZeroDensityEulerNumberTest);
  AssertException('Zero velocity Euler number', EFluidDynamicsError, @ZeroVelocityEulerNumberTest);
  AssertException('Zero speed of sound Mach number', EFluidDynamicsError, @ZeroSpeedOfSoundMachNumberTest);
  
  // Compressible flow edge cases
  AssertException('Gamma equals 1 speed of sound', EFluidDynamicsError, @GammaEqualsOneSpeedOfSoundTest);
  AssertException('Zero Mach number area ratio', EFluidDynamicsError, @ZeroMachNumberAreaRatioTest);
  
  // Pumps and turbines edge cases
  AssertException('Zero efficiency pump power', EFluidDynamicsError, @ZeroEfficiencyPumpPowerTest);
  AssertException('Zero RPM specific speed', EFluidDynamicsError, @ZeroRPMSpecificSpeedTest);
  AssertException('Zero flow rate specific speed', EFluidDynamicsError, @ZeroFlowRateSpecificSpeedTest);
  AssertException('Zero head specific speed', EFluidDynamicsError, @ZeroHeadSpecificSpeedTest);
  
  // Open channel flow edge cases
  AssertException('Zero Chezy coefficient', EFluidDynamicsError, @ZeroChezyCoeffientTest);
  AssertException('Zero depth Froude number', EFluidDynamicsError, @ZeroDepthFroudeNumberTest);
end;

procedure TTestFluidDynamicsKit.Test40_TurbulentSolverValidation;
begin
  AssertException('Turbulent friction factor rejects zero tolerance',
    EFluidDynamicsError, @ZeroTurbulentToleranceTest);
  AssertException('Turbulent friction factor rejects zero iterations',
    EFluidDynamicsError, @ZeroTurbulentIterationsTest);
end;

procedure TTestFluidDynamicsKit.Test41_BlasiusBoundaryValues;
begin
  AssertEquals('Blasius accepts Re=4000', 0.316/Power(4000.0, 0.25),
    TFluidDynamicsKit.BlasiusFrictionFactor(4000.0), Tolerance);
  AssertEquals('Blasius accepts Re=100000', 0.316/Power(100000.0, 0.25),
    TFluidDynamicsKit.BlasiusFrictionFactor(100000.0), Tolerance);
end;

procedure TTestFluidDynamicsKit.Test42_PowerFlowValidation;
begin
  AssertException('Pump power rejects negative flow rate',
    EFluidDynamicsError, @NegativeFlowPumpPowerTest);
  AssertException('Turbine power rejects negative flow rate',
    EFluidDynamicsError, @NegativeFlowTurbinePowerTest);
end;

initialization
  RegisterTest(TTestFluidDynamicsKit);
end.
