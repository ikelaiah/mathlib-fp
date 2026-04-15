program FluidDynamics;

{-----------------------------------------------------------------------------
  06_fluid_dynamics.lpr

  Demonstrates fluid-mechanics calculations using EngineeringLib.
  Covers Reynolds number, Bernoulli's equation, pipe friction, and
  basic aerodynamics — with unit conversions mixed in for context.

  Build (FPC command line):
    fpc -Fu../src 06_fluid_dynamics.lpr

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  EngineeringLib.FluidDynamics,   // TFluidDynamicsKit
  EngineeringLib.UnitConversion;  // TUnitConversionKit

var
  Re: Double;
  P2, V2: Double;
  HeadLoss, FrictionFactor: Double;
  Fr, Ma, We: Double;
  Lift, Drag, DynP: Double;
  FlowRate, MassFlow: Double;
  SpeedKmh: Double;

begin
  // ── Scenario A: Water flowing through a pipe ─────────────────────────
  // A 50 mm diameter pipe carries water (ρ=997 kg/m³, μ=1×10⁻³ Pa·s)
  // at 2 m/s.

  Re := TFluidDynamicsKit.ReynoldsNumber(
    TFluidDynamicsKit.WaterDensity,   // density  [kg/m³]
    2.0,                              // velocity [m/s]
    0.05,                             // pipe diameter [m]
    1.0e-3                            // dynamic viscosity [Pa·s]
  );

  WriteLn('=== Pipe Flow (water, D=50mm, v=2 m/s) ===');
  WriteLn(Format('  Reynolds number  : %.0f', [Re]));
  if Re < 2300 then
    WriteLn('  Flow regime      : Laminar')
  else if Re < 4000 then
    WriteLn('  Flow regime      : Transitional')
  else
    WriteLn('  Flow regime      : Turbulent');

  // Volume and mass flow rates
  FlowRate := TFluidDynamicsKit.CalculateVolumeFlowRate(
    Pi * Sqr(0.025),  // cross-sectional area = π r²  [m²]
    2.0               // velocity [m/s]
  );
  MassFlow := TFluidDynamicsKit.MassFlowRate(TFluidDynamicsKit.WaterDensity, FlowRate);
  WriteLn(Format('  Volume flow rate : %.6f m³/s  (= %.2f L/s)',
    [FlowRate, FlowRate * 1000]));
  WriteLn(Format('  Mass flow rate   : %.4f kg/s', [MassFlow]));
  WriteLn;

  // ── Scenario B: Bernoulli — pipe narrows from D=100mm to D=50mm ───────
  // Inlet: P1=200 kPa, v1=1 m/s, h1=0 m
  // Outlet is at same height (h2=0). What is the outlet pressure?
  P2 := TFluidDynamicsKit.BernoulliPressure(
    TFluidDynamicsKit.WaterDensity,
    200000.0,  // P1 [Pa]
    1.0,       // v1 [m/s]
    0.0,       // h1 [m]
    4.0,       // v2 [m/s]  — by continuity, A1*v1 = A2*v2 → v2 = 4*v1
    0.0        // h2 [m]
  );
  WriteLn('=== Bernoulli: pipe contraction (h1=h2=0) ===');
  WriteLn(Format('  Inlet  P1 = 200.00 kPa  v1 = 1.0 m/s', []));
  WriteLn(Format('  Outlet P2 = %.2f kPa  v2 = 4.0 m/s', [P2 / 1000]));
  WriteLn;

  // ── Scenario C: Darcy-Weisbach head loss in 10 m of pipe ─────────────
  // Turbulent flow: use Colebrook-White friction factor
  // Relative roughness for commercial steel ε/D ≈ 0.046/50 = 0.00092
  FrictionFactor := TFluidDynamicsKit.TurbulentFrictionFactor(Re, 0.00092);
  HeadLoss := TFluidDynamicsKit.FrictionHeadLoss(
    FrictionFactor,
    10.0,   // pipe length [m]
    0.05,   // diameter   [m]
    2.0     // velocity   [m/s]
  );
  WriteLn('=== Darcy-Weisbach Head Loss (L=10m, steel pipe) ===');
  WriteLn(Format('  Colebrook-White f : %.5f', [FrictionFactor]));
  WriteLn(Format('  Head loss hf      : %.4f m', [HeadLoss]));
  WriteLn;

  // ── Scenario D: Dimensionless numbers for an open channel ────────────
  // Water flowing at 3 m/s in a channel of hydraulic depth 0.8 m.
  Fr := TFluidDynamicsKit.FroudeNumber(3.0, 0.8);
  WriteLn('=== Open Channel: Froude Number ===');
  WriteLn(Format('  v=3 m/s, L=0.8 m  → Fr = %.4f', [Fr]));
  if Fr < 1 then
    WriteLn('  Flow regime: Sub-critical (tranquil)')
  else
    WriteLn('  Flow regime: Super-critical (rapid)');
  WriteLn;

  // ── Scenario E: Aerodynamics — car at highway speed ──────────────────
  // A sedan: CD=0.30, CL=0.15, frontal area=2.2 m², speed=110 km/h
  SpeedKmh := 110.0;
  V2 := TUnitConversionKit.ConvertVelocity(SpeedKmh, vuKilometerPerHour, vuMeterPerSecond);
  Ma := TFluidDynamicsKit.MachNumber(V2, 343.0);  // speed of sound 343 m/s
  DynP := TFluidDynamicsKit.DynamicPressure(TFluidDynamicsKit.AirDensity, V2);
  Drag := TFluidDynamicsKit.DragForce(0.30, TFluidDynamicsKit.AirDensity, V2, 2.2);
  Lift := TFluidDynamicsKit.LiftForce(0.15, TFluidDynamicsKit.AirDensity, V2, 2.2);

  WriteLn(Format('=== Aerodynamics: sedan at %.0f km/h (%.2f m/s) ===', [SpeedKmh, V2]));
  WriteLn(Format('  Mach number      : %.4f', [Ma]));
  WriteLn(Format('  Dynamic pressure : %.2f Pa', [DynP]));
  WriteLn(Format('  Aerodynamic drag : %.2f N', [Drag]));
  WriteLn(Format('  Aerodynamic lift : %.2f N', [Lift]));
  WriteLn;

  // ── Scenario F: Prandtl and Nusselt numbers for air ─────────────────
  // Air at standard conditions: μ=1.81e-5 Pa·s, cp=1005 J/kg·K, k=0.026 W/m·K
  // Forced convection over a flat plate: h=25 W/m²·K, L=0.5 m
  WriteLn('=== Heat Transfer Dimensionless Numbers (air) ===');
  WriteLn(Format('  Prandtl Pr  : %.4f', [
    TFluidDynamicsKit.PrandtlNumber(1.81e-5, 1005.0, 0.026)]));
  WriteLn(Format('  Nusselt Nu  : %.4f', [
    TFluidDynamicsKit.NusseltNumber(25.0, 0.5, 0.026)]));
  WriteLn;

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
