unit EngineeringLib.FluidDynamics;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  TFluidDynamicsKit = class
  public
    const
      GravityAcceleration = 9.80665; // m/s² (standard gravity)
      WaterDensity = 997.0; // kg/m³ at 25°C
      AirDensity = 1.225; // kg/m³ at standard conditions
      DynamicViscosityAir = 1.81E-5; // Pa·s at 25°C
      KinematicViscosityAir = 1.48E-5; // m²/s at 25°C

    { Bernoulli's Principle (for incompressible, inviscid flow along a streamline) }
    // P₁ + ½ρv₁² + ρgh₁ = P₂ + ½ρv₂² + ρgh₂
    // Calculates pressure at point 2 given conditions at point 1 and velocity/height at point 2
    class function BernoulliPressure(
      Density: Double;
      Pressure1: Double;
      Velocity1: Double;
      Height1: Double;
      Velocity2: Double;
      Height2: Double): Double; static;
    // Calculates velocity at point 2 given conditions at point 1 and pressure/height at point 2
    class function BernoulliVelocity(
      Density: Double;
      Pressure1: Double;
      Velocity1: Double;
      Height1: Double;
      Pressure2: Double;
      Height2: Double): Double; static;
    // Calculates height at point 2 given conditions at point 1 and pressure/velocity at point 2
    class function BernoulliHeight(
      Density: Double;
      Pressure1: Double;
      Velocity1: Double;
      Height1: Double;
      Pressure2: Double;
      Velocity2: Double): Double; static;

    { Flow Rate }
    // Rename one of the VolumeFlowRate functions to eliminate duplicate identifier
    class function CalculateVolumeFlowRate(Area: Double; Velocity: Double): Double; static;
    // ṁ = ρ * Q = ρ * A * v (Mass flow rate)
    class function MassFlowRate(Density: Double; Area: Double; Velocity: Double): Double; overload; static;
    class function MassFlowRate(Density: Double; VolumeFlowRate: Double): Double; overload; static;

    { Reynolds Number (characterizes flow regime - laminar vs turbulent) }
    // Re = (ρ * v * L) / μ
    class function ReynoldsNumber(
      Density: Double;
      Velocity: Double;
      CharacteristicLength: Double;
      DynamicViscosity: Double): Double; static;
    // Re = (v * L) / ν (where ν = μ / ρ is kinematic viscosity)
    class function ReynoldsNumberKinematic(
      Velocity: Double;
      CharacteristicLength: Double;
      KinematicViscosity: Double): Double; static;

    { Pipe Flow }
    // Head loss in pipe due to friction (Darcy-Weisbach equation): hf = f * (L/D) * (v²/2g)
    class function FrictionHeadLoss(
      FrictionFactor: Double;
      Length: Double;
      Diameter: Double;
      Velocity: Double): Double; static;
    // Hazen-Williams formula for head loss in water pipes
    class function HazenWilliamsHeadLoss(
      Length: Double;
      Diameter: Double;
      FlowRate: Double;
      CHW: Double): Double; static;
    // Darcy friction factor for laminar flow: f = 64/Re
    class function LaminarFrictionFactor(ReynoldsNumberValue: Double): Double; static;
    // Darcy friction factor for turbulent flow (Colebrook-White equation - iterative)
    class function TurbulentFrictionFactor(
      ReynoldsNumberValue: Double;
      RelativeRoughness: Double;
      Tolerance: Double = 1E-6;
      MaxIterations: Integer = 100): Double; static;
    // Simplified Blasius correlation for smooth pipes: f = 0.316/Re^0.25 (valid for 4000 < Re < 10⁵)
    class function BlasiusFrictionFactor(ReynoldsNumberValue: Double): Double; static;

    { Dimensional Analysis - Non-dimensional numbers }
    // Froude number (ratio of inertial to gravitational forces): Fr = v/sqrt(g*L)
    class function FroudeNumber(Velocity: Double; CharacteristicLength: Double): Double; static;
    // Weber number (ratio of inertial force to surface tension): We = (ρ*v²*L)/σ
    class function WeberNumber(
      Density: Double;
      Velocity: Double;
      CharacteristicLength: Double;
      SurfaceTension: Double): Double; static;
    // Euler number (ratio of pressure forces to inertial forces): Eu = ΔP/(ρ*v²)
    class function EulerNumber(PressureDifference: Double; Density: Double; Velocity: Double): Double; static;
    // Mach number (ratio of flow velocity to speed of sound): Ma = v/c
    class function MachNumber(Velocity: Double; SpeedOfSound: Double): Double; static;
    // Strouhal number (measures oscillating flow mechanisms): St = (f*L)/v
    class function StrouhalNumber(Frequency: Double; CharacteristicLength: Double; Velocity: Double): Double; static;
    // Prandtl number (ratio of momentum diffusivity to thermal diffusivity): Pr = ν/α = (μ*cp)/k
    class function PrandtlNumber(
      DynamicViscosity: Double;
      SpecificHeat: Double;
      ThermalConductivity: Double): Double; static;
    // Nusselt number (ratio of convective to conductive heat transfer): Nu = (h*L)/k
    class function NusseltNumber(
      HeatTransferCoefficient: Double;
      CharacteristicLength: Double;
      ThermalConductivity: Double): Double; static;

    { Aerodynamics }
    // Lift force: L = CL * 0.5 * ρ * v² * A
    class function LiftForce(
      LiftCoefficient: Double;
      Density: Double;
      Velocity: Double;
      ReferenceArea: Double): Double; static;
    // Drag force: D = CD * 0.5 * ρ * v² * A
    class function DragForce(
      DragCoefficient: Double;
      Density: Double;
      Velocity: Double;
      ReferenceArea: Double): Double; static;
    // Dynamic pressure: q = 0.5 * ρ * v²
    class function DynamicPressure(Density: Double; Velocity: Double): Double; static;
    // Stagnation pressure: p0 = p + q
    class function StagnationPressure(StaticPressure: Double; DynamicPressureValue: Double): Double; static;
    // Coefficient of pressure: Cp = (p - p∞)/(0.5*ρ*v²)
    class function PressureCoefficient(
      Pressure: Double;
      FreeStreamPressure: Double;
      FreeStreamDensity: Double;
      FreeStreamVelocity: Double): Double; static;

    { Compressible Flow }
    // Speed of sound in ideal gas: c = sqrt(γ*R*T)
    class function SpeedOfSound(SpecificHeatRatio: Double; GasConstant: Double; Temperature: Double): Double; static;
    // Stagnation temperature ratio: T0/T = 1 + ((γ-1)/2)*M²
    class function StagnationTemperatureRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double; static;
    // Stagnation pressure ratio: p0/p = (1 + ((γ-1)/2)*M²)^(γ/(γ-1))
    class function StagnationPressureRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double; static;
    // Area ratio in isentropic flow: A/A* = (1/M)*[(2/(γ+1))*(1+((γ-1)/2)*M²)]^((γ+1)/(2*(γ-1)))
    class function IsentropicAreaRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double; static;

    { Pumps and Turbines }
    // Pump power: P = ρ*g*Q*H / η
    class function PumpPower(Density: Double; FlowRate: Double; Head: Double; Efficiency: Double): Double; static;
    // Pump head (energy per unit weight): H = (p2-p1)/(ρ*g) + (v2²-v1²)/(2*g) + (z2-z1)
    class function PumpHead(
      PressureDiff: Double;
      Density: Double;
      VelocityDiff: Double;
      HeightDiff: Double): Double; static;
    // Specific speed of pumps: Ns = N*sqrt(Q)/H^(3/4), where N is RPM
    class function PumpSpecificSpeed(RPM: Double; FlowRate: Double; Head: Double): Double; static;
    // Turbine power output: P = η*ρ*g*Q*H
    class function TurbinePower(Efficiency: Double; Density: Double; FlowRate: Double; Head: Double): Double; static;

    { Open Channel Flow }
    // Chezy formula for open channel flow: v = C*sqrt(R*S)
    class function ChezyVelocity(
      ChezyCoefficient: Double;
      HydraulicRadius: Double;
      ChannelSlope: Double): Double; static;
    // Manning equation: v = (1/n)*R^(2/3)*S^(1/2)
    class function ManningVelocity(
      ManningCoefficient: Double;
      HydraulicRadius: Double;
      ChannelSlope: Double): Double; static;
    // Critical depth for rectangular channel: yc = (q²/g)^(1/3)
    class function CriticalDepthRectangular(UnitDischarge: Double): Double; static;
    // Froude number for open channel: Fr = v/sqrt(g*y)
    class function OpenChannelFroudeNumber(Velocity: Double; Depth: Double): Double; static;

    { Fluid Properties (Examples - add more as needed) }
    // Density of water at standard conditions (approx)
    class function DensityWater: Double; static; // kg/m³
    // Dynamic viscosity of water at standard conditions (approx)
    class function DynamicViscosityWater: Double; static; // Pa·s
    // Kinematic viscosity of water at standard conditions (approx)
    class function KinematicViscosityWater: Double; static; // m²/s
  end;

implementation

{ TFluidDynamicsKit }

class function TFluidDynamicsKit.BernoulliPressure(
  Density: Double;
  Pressure1: Double;
  Velocity1: Double;
  Height1: Double;
  Velocity2: Double;
  Height2: Double): Double;
begin
  if Density <= 0 then
    raise Exception.Create('Density must be positive for Bernoulli calculation.');
  Result := Pressure1 + 0.5 * Density * (Power(Velocity1, 2) - Power(Velocity2, 2)) + Density * GravityAcceleration * (Height1 - Height2);
end;

class function TFluidDynamicsKit.BernoulliVelocity(
  Density: Double;
  Pressure1: Double;
  Velocity1: Double;
  Height1: Double;
  Pressure2: Double;
  Height2: Double): Double;
var
  VelocitySquared: Double;
begin
  if Density <= 0 then
    raise Exception.Create('Density must be positive for Bernoulli calculation.');
  VelocitySquared := Power(Velocity1, 2) + 2 * (Pressure1 - Pressure2) / Density + 2 * GravityAcceleration * (Height1 - Height2);
  if VelocitySquared < 0 then
    raise Exception.Create('Cannot calculate velocity: resulting velocity squared is negative (check input values).');
  Result := Sqrt(VelocitySquared);
end;

class function TFluidDynamicsKit.BernoulliHeight(
  Density: Double;
  Pressure1: Double;
  Velocity1: Double;
  Height1: Double;
  Pressure2: Double;
  Velocity2: Double): Double;
begin
  if Density <= 0 then
    raise Exception.Create('Density must be positive for Bernoulli calculation.');
  if GravityAcceleration = 0 then
     raise Exception.Create('Gravity acceleration cannot be zero for height calculation.');
  Result := Height1 + (Pressure1 - Pressure2) / (Density * GravityAcceleration) + (Power(Velocity1, 2) - Power(Velocity2, 2)) / (2 * GravityAcceleration);
end;

class function TFluidDynamicsKit.CalculateVolumeFlowRate(Area: Double; Velocity: Double): Double;
begin
  if Area < 0 then
    raise Exception.Create('Area cannot be negative.');
  Result := Area * Velocity;
end;

class function TFluidDynamicsKit.MassFlowRate(Density: Double; Area: Double; Velocity: Double): Double;
begin
  if Density < 0 then
    raise Exception.Create('Density cannot be negative.');
  Result := Density * CalculateVolumeFlowRate(Area, Velocity);
end;

class function TFluidDynamicsKit.MassFlowRate(Density: Double; VolumeFlowRate: Double): Double;
begin
  if Density < 0 then
    raise Exception.Create('Density cannot be negative.');
  Result := Density * VolumeFlowRate;
end;

class function TFluidDynamicsKit.ReynoldsNumber(
  Density: Double;
  Velocity: Double;
  CharacteristicLength: Double;
  DynamicViscosity: Double): Double;
begin
  if DynamicViscosity <= 0 then
    raise Exception.Create('Dynamic viscosity must be positive for Reynolds number calculation.');
  if Density < 0 then
    raise Exception.Create('Density cannot be negative.');
  Result := (Density * Velocity * CharacteristicLength) / DynamicViscosity;
end;

class function TFluidDynamicsKit.ReynoldsNumberKinematic(
  Velocity: Double;
  CharacteristicLength: Double;
  KinematicViscosity: Double): Double;
begin
  if KinematicViscosity <= 0 then
    raise Exception.Create('Kinematic viscosity must be positive for Reynolds number calculation.');
  Result := (Velocity * CharacteristicLength) / KinematicViscosity;
end;

class function TFluidDynamicsKit.FrictionHeadLoss(
  FrictionFactor: Double;
  Length: Double;
  Diameter: Double;
  Velocity: Double): Double;
begin
  if Diameter <= 0 then
    raise Exception.Create('Diameter must be positive for head loss calculation.');
  if FrictionFactor < 0 then
    raise Exception.Create('Friction factor cannot be negative.');
  
  Result := FrictionFactor * (Length / Diameter) * (Power(Velocity, 2) / (2 * GravityAcceleration));
end;

class function TFluidDynamicsKit.HazenWilliamsHeadLoss(
  Length: Double;
  Diameter: Double;
  FlowRate: Double;
  CHW: Double): Double;
const
  K = 10.67; // Constant for SI units
begin
  if (Diameter <= 0) or (Length <= 0) then
    raise Exception.Create('Diameter and length must be positive for Hazen-Williams calculation.');
  if CHW <= 0 then
    raise Exception.Create('Hazen-Williams coefficient must be positive.');
  if FlowRate < 0 then
    raise Exception.Create('Flow rate cannot be negative.');
  
  // Units: Length (m), Diameter (m), FlowRate (m³/s), Result (m)
  Result := K * (Power(FlowRate, 1.85) / Power(CHW, 1.85)) * (Length / Power(Diameter, 4.87));
end;

class function TFluidDynamicsKit.LaminarFrictionFactor(ReynoldsNumberValue: Double): Double;
begin
  if ReynoldsNumberValue <= 0 then
    raise Exception.Create('Reynolds number must be positive for friction factor calculation.');
  if ReynoldsNumberValue >= 2300 then
    raise Exception.Create('Laminar friction factor applies only for Reynolds numbers below 2300.');
  
  Result := 64 / ReynoldsNumberValue;
end;

class function TFluidDynamicsKit.TurbulentFrictionFactor(
  ReynoldsNumberValue: Double;
  RelativeRoughness: Double;
  Tolerance: Double;
  MaxIterations: Integer): Double;
var
  f_old, f_new: Double;
  i: Integer;
begin
  if ReynoldsNumberValue <= 0 then
    raise Exception.Create('Reynolds number must be positive for friction factor calculation.');
  if RelativeRoughness < 0 then
    raise Exception.Create('Relative roughness cannot be negative.');
  if ReynoldsNumberValue < 4000 then
    raise Exception.Create('Turbulent friction factor applies only for Reynolds numbers above 4000.');
  
  // Initial guess using Haaland equation
  f_old := Power(1 / (-1.8 * Log10(Power(RelativeRoughness / 3.7, 1.11) + 6.9 / ReynoldsNumberValue)), 2);
  
  // Colebrook-White equation (iterative solution)
  for i := 1 to MaxIterations do
  begin
    f_new := Power(1 / (-2 * Log10(RelativeRoughness / 3.7 + 2.51 / (ReynoldsNumberValue * Sqrt(f_old)))), 2);
    if Abs(f_new - f_old) < Tolerance then
    begin
      Result := f_new;
      Exit;
    end;
    f_old := f_new;
  end;
  
  // If max iterations reached, return the last calculated value
  raise Exception.Create('Maximum iterations reached in friction factor calculation.');
  Result := f_old;
end;

class function TFluidDynamicsKit.BlasiusFrictionFactor(ReynoldsNumberValue: Double): Double;
begin
  if (ReynoldsNumberValue < 4000) or (ReynoldsNumberValue > 100000) then
    raise Exception.Create('Blasius equation is valid for Reynolds numbers between 4000 and 100000.');
  
  Result := 0.316 / Power(ReynoldsNumberValue, 0.25);
end;

class function TFluidDynamicsKit.FroudeNumber(Velocity: Double; CharacteristicLength: Double): Double;
begin
  if CharacteristicLength <= 0 then
    raise Exception.Create('Characteristic length must be positive for Froude number calculation.');
  
  Result := Velocity / Sqrt(GravityAcceleration * CharacteristicLength);
end;

class function TFluidDynamicsKit.WeberNumber(
  Density: Double;
  Velocity: Double;
  CharacteristicLength: Double;
  SurfaceTension: Double): Double;
begin
  if (Density < 0) or (CharacteristicLength <= 0) or (SurfaceTension <= 0) then
    raise Exception.Create('Density cannot be negative; characteristic length and surface tension must be positive.');
  
  Result := (Density * Power(Velocity, 2) * CharacteristicLength) / SurfaceTension;
end;

class function TFluidDynamicsKit.EulerNumber(PressureDifference: Double; Density: Double; Velocity: Double): Double;
begin
  if Density <= 0 then
    raise Exception.Create('Density must be positive for Euler number calculation.');
  if Velocity = 0 then
    raise Exception.Create('Velocity cannot be zero for Euler number calculation.');
  
  Result := PressureDifference / (Density * Power(Velocity, 2));
end;

class function TFluidDynamicsKit.MachNumber(Velocity: Double; SpeedOfSound: Double): Double;
begin
  if SpeedOfSound <= 0 then
    raise Exception.Create('Speed of sound must be positive for Mach number calculation.');
  
  Result := Velocity / SpeedOfSound;
end;

class function TFluidDynamicsKit.StrouhalNumber(
  Frequency: Double;
  CharacteristicLength: Double;
  Velocity: Double): Double;
begin
  if (CharacteristicLength <= 0) or (Velocity = 0) then
    raise Exception.Create('Characteristic length must be positive and velocity non-zero for Strouhal number.');
  
  Result := (Frequency * CharacteristicLength) / Velocity;
end;

class function TFluidDynamicsKit.PrandtlNumber(
  DynamicViscosity: Double;
  SpecificHeat: Double;
  ThermalConductivity: Double): Double;
begin
  if (DynamicViscosity < 0) or (SpecificHeat <= 0) or (ThermalConductivity <= 0) then
    raise Exception.Create('Dynamic viscosity cannot be negative; specific heat and thermal conductivity must be positive.');
  
  Result := (DynamicViscosity * SpecificHeat) / ThermalConductivity;
end;

class function TFluidDynamicsKit.NusseltNumber(
  HeatTransferCoefficient: Double;
  CharacteristicLength: Double;
  ThermalConductivity: Double): Double;
begin
  if (HeatTransferCoefficient <= 0) or (CharacteristicLength <= 0) or (ThermalConductivity <= 0) then
    raise Exception.Create('Heat transfer coefficient, characteristic length, and thermal conductivity must be positive.');
  
  Result := (HeatTransferCoefficient * CharacteristicLength) / ThermalConductivity;
end;

class function TFluidDynamicsKit.LiftForce(
  LiftCoefficient: Double;
  Density: Double;
  Velocity: Double;
  ReferenceArea: Double): Double;
begin
  if (Density < 0) or (ReferenceArea < 0) then
    raise Exception.Create('Density and reference area cannot be negative.');
  
  Result := LiftCoefficient * 0.5 * Density * Power(Velocity, 2) * ReferenceArea;
end;

class function TFluidDynamicsKit.DragForce(
  DragCoefficient: Double;
  Density: Double;
  Velocity: Double;
  ReferenceArea: Double): Double;
begin
  if (Density < 0) or (ReferenceArea < 0) then
    raise Exception.Create('Density and reference area cannot be negative.');
  
  Result := DragCoefficient * 0.5 * Density * Power(Velocity, 2) * ReferenceArea;
end;

class function TFluidDynamicsKit.DynamicPressure(Density: Double; Velocity: Double): Double;
begin
  if Density < 0 then
    raise Exception.Create('Density cannot be negative.');
  
  Result := 0.5 * Density * Power(Velocity, 2);
end;

class function TFluidDynamicsKit.StagnationPressure(StaticPressure: Double; DynamicPressureValue: Double): Double;
begin
  Result := StaticPressure + DynamicPressureValue;
end;

class function TFluidDynamicsKit.PressureCoefficient(
  Pressure: Double;
  FreeStreamPressure: Double;
  FreeStreamDensity: Double;
  FreeStreamVelocity: Double): Double;
var
  DynPressure: Double; // Changed from DynamicPressure to DynPressure to avoid conflict
begin
  if FreeStreamDensity <= 0 then
    raise Exception.Create('Free stream density must be positive.');
  if FreeStreamVelocity = 0 then
    raise Exception.Create('Free stream velocity cannot be zero for pressure coefficient calculation.');
  
  DynPressure := 0.5 * FreeStreamDensity * Power(FreeStreamVelocity, 2);
  Result := (Pressure - FreeStreamPressure) / DynPressure;
end;

class function TFluidDynamicsKit.SpeedOfSound(
  SpecificHeatRatio: Double;
  GasConstant: Double;
  Temperature: Double): Double;
begin
  if (SpecificHeatRatio <= 1) or (GasConstant <= 0) or (Temperature <= 0) then
    raise Exception.Create('Specific heat ratio must be > 1; gas constant and temperature must be positive.');
  
  Result := Sqrt(SpecificHeatRatio * GasConstant * Temperature);
end;

class function TFluidDynamicsKit.StagnationTemperatureRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double;
begin
  if (MachNumberValue < 0) or (SpecificHeatRatio <= 1) then
    raise Exception.Create('Mach number cannot be negative; specific heat ratio must be > 1.');
  
  Result := 1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumberValue, 2);
end;

class function TFluidDynamicsKit.StagnationPressureRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double;
begin
  if (MachNumberValue < 0) or (SpecificHeatRatio <= 1) then
    raise Exception.Create('Mach number cannot be negative; specific heat ratio must be > 1.');
  
  Result := Power(1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumberValue, 2), SpecificHeatRatio / (SpecificHeatRatio - 1));
end;

class function TFluidDynamicsKit.IsentropicAreaRatio(MachNumberValue: Double; SpecificHeatRatio: Double): Double;
var
  Term1, Term2: Double;
begin
  if (MachNumberValue <= 0) or (SpecificHeatRatio <= 1) then
    raise Exception.Create('Mach number must be positive; specific heat ratio must be > 1.');
  
  Term1 := 1 / MachNumberValue;
  Term2 := Power((2 / (SpecificHeatRatio + 1)) * (1 + ((SpecificHeatRatio - 1) / 2) * Power(MachNumberValue, 2)), 
                 (SpecificHeatRatio + 1) / (2 * (SpecificHeatRatio - 1)));
  Result := Term1 * Term2;
end;

class function TFluidDynamicsKit.PumpPower(Density: Double; FlowRate: Double; Head: Double; Efficiency: Double): Double;
begin
  if (Density <= 0) or (Head < 0) or (Efficiency <= 0) or (Efficiency > 1) then
    raise Exception.Create('Density and efficiency must be positive; efficiency must be between 0 and 1.');
  
  Result := Density * GravityAcceleration * FlowRate * Head / Efficiency;
end;

class function TFluidDynamicsKit.PumpHead(
  PressureDiff: Double;
  Density: Double;
  VelocityDiff: Double;
  HeightDiff: Double): Double;
begin
  if Density <= 0 then
    raise Exception.Create('Density must be positive for pump head calculation.');
  
  Result := PressureDiff / (Density * GravityAcceleration) + 
            Power(VelocityDiff, 2) / (2 * GravityAcceleration) + HeightDiff;
end;

class function TFluidDynamicsKit.PumpSpecificSpeed(RPM: Double; FlowRate: Double; Head: Double): Double;
begin
  if (RPM <= 0) or (FlowRate <= 0) or (Head <= 0) then
    raise Exception.Create('RPM, flow rate, and head must be positive for specific speed calculation.');
  
  Result := RPM * Sqrt(FlowRate) / Power(Head, 0.75);
end;

class function TFluidDynamicsKit.TurbinePower(
  Efficiency: Double;
  Density: Double;
  FlowRate: Double;
  Head: Double): Double;
begin
  if (Efficiency <= 0) or (Efficiency > 1) or (Density <= 0) or (Head < 0) then
    raise Exception.Create('Efficiency must be between 0 and 1; density must be positive.');
  
  Result := Efficiency * Density * GravityAcceleration * FlowRate * Head;
end;

class function TFluidDynamicsKit.ChezyVelocity(
  ChezyCoefficient: Double;
  HydraulicRadius: Double;
  ChannelSlope: Double): Double;
begin
  if (ChezyCoefficient <= 0) or (HydraulicRadius <= 0) or (ChannelSlope <= 0) then
    raise Exception.Create('Chezy coefficient, hydraulic radius, and channel slope must be positive.');
  
  Result := ChezyCoefficient * Sqrt(HydraulicRadius * ChannelSlope);
end;

class function TFluidDynamicsKit.ManningVelocity(
  ManningCoefficient: Double;
  HydraulicRadius: Double;
  ChannelSlope: Double): Double;
begin
  if (ManningCoefficient <= 0) or (HydraulicRadius <= 0) or (ChannelSlope <= 0) then
    raise Exception.Create('Manning coefficient, hydraulic radius, and channel slope must be positive.');
  
  Result := (1 / ManningCoefficient) * Power(HydraulicRadius, 2/3) * Power(ChannelSlope, 1/2);
end;

class function TFluidDynamicsKit.CriticalDepthRectangular(UnitDischarge: Double): Double;
begin
  if UnitDischarge <= 0 then
    raise Exception.Create('Unit discharge must be positive for critical depth calculation.');
  
  Result := Power(UnitDischarge * UnitDischarge / GravityAcceleration, 1/3);
end;

class function TFluidDynamicsKit.OpenChannelFroudeNumber(Velocity: Double; Depth: Double): Double;
begin
  if Depth <= 0 then
    raise Exception.Create('Depth must be positive for open channel Froude number calculation.');
  
  Result := Velocity / Sqrt(GravityAcceleration * Depth);
end;

class function TFluidDynamicsKit.DensityWater: Double;
begin
  Result := 997.0; // kg/m³ at 25°C
end;

class function TFluidDynamicsKit.DynamicViscosityWater: Double;
begin
  Result := 8.90E-4; // Pa·s at 25°C
end;

class function TFluidDynamicsKit.KinematicViscosityWater: Double;
begin
  Result := DynamicViscosityWater / DensityWater; // m²/s
end;

end.
