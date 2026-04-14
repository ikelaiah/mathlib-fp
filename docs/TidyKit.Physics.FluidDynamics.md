# pascal-mathlibs Physics: Fluid Dynamics Library

The `pascal-mathlibs.Physics.FluidDynamics` module provides comprehensive functionality for fluid dynamics calculations, including Bernoulli's principle, flow rates, pipe flow analysis, dimensional analysis, aerodynamics, compressible flow, and more.

## Overview

`TFluidDynamicsKit` is a static class providing a wide range of fluid dynamics calculations commonly used in engineering applications. The library includes physical constants, fluid property calculations, and numerous methods for specialized fluid dynamics calculations.

## Constants

The library provides the following constants:

```pascal
const
  GravityAcceleration = 9.80665; // m/s² (standard gravity)
  WaterDensity = 997.0; // kg/m³ at 25°C
  AirDensity = 1.225; // kg/m³ at standard conditions
  DynamicViscosityAir = 1.81E-5; // Pa·s at 25°C
  KinematicViscosityAir = 1.48E-5; // m²/s at 25°C
```

## Basic Fluid Properties

Get standard fluid properties:

```pascal
// Density of water at standard conditions (997.0 kg/m³ at 25°C)
density := TFluidDynamicsKit.DensityWater;

// Dynamic viscosity of water at standard conditions (8.90E-4 Pa·s at 25°C)
dynamicViscosity := TFluidDynamicsKit.DynamicViscosityWater;

// Kinematic viscosity of water at standard conditions (8.90E-7 m²/s at 25°C)
kinematicViscosity := TFluidDynamicsKit.KinematicViscosityWater;
```

## Bernoulli's Principle

Calculate pressure, velocity, or height using Bernoulli's principle for incompressible, inviscid flow along a streamline.

```pascal
// Calculate pressure at point 2 given conditions at point 1 and velocity/height at point 2
pressure2 := TFluidDynamicsKit.BernoulliPressure(
  density,      // kg/m³
  pressure1,    // Pa
  velocity1,    // m/s
  height1,      // m
  velocity2,    // m/s
  height2       // m
);

// Calculate velocity at point 2 given conditions at point 1 and pressure/height at point 2
velocity2 := TFluidDynamicsKit.BernoulliVelocity(
  density,      // kg/m³
  pressure1,    // Pa
  velocity1,    // m/s
  height1,      // m
  pressure2,    // Pa
  height2       // m
);

// Calculate height at point 2 given conditions at point 1 and pressure/velocity at point 2
height2 := TFluidDynamicsKit.BernoulliHeight(
  density,      // kg/m³
  pressure1,    // Pa
  velocity1,    // m/s
  height1,      // m
  pressure2,    // Pa
  velocity2     // m/s
);
```

## Flow Rate Calculations

Calculate volume and mass flow rates:

```pascal
// Calculate volume flow rate (Q = A * v)
volumeFlowRate := TFluidDynamicsKit.CalculateVolumeFlowRate(
  crossSectionalArea,  // m²
  velocity             // m/s
);

// Calculate mass flow rate from density, area, and velocity (ṁ = ρ * A * v)
massFlowRate1 := TFluidDynamicsKit.MassFlowRate(
  density,             // kg/m³
  crossSectionalArea,  // m²
  velocity             // m/s
);

// Calculate mass flow rate from density and volume flow rate (ṁ = ρ * Q)
massFlowRate2 := TFluidDynamicsKit.MassFlowRate(
  density,             // kg/m³
  volumeFlowRate       // m³/s
);
```

## Reynolds Number

Calculate Reynolds number to characterize flow regime (laminar vs. turbulent):

```pascal
// Reynolds number using dynamic viscosity (Re = (ρ * v * L) / μ)
reynoldsNumber1 := TFluidDynamicsKit.ReynoldsNumber(
  density,             // kg/m³
  velocity,            // m/s
  characteristicLength,// m
  dynamicViscosity     // Pa·s
);

// Reynolds number using kinematic viscosity (Re = (v * L) / ν)
reynoldsNumber2 := TFluidDynamicsKit.ReynoldsNumberKinematic(
  velocity,            // m/s
  characteristicLength,// m
  kinematicViscosity   // m²/s
);
```

## Pipe Flow Analysis

Calculate head loss and friction factors for pipe flow:

```pascal
// Head loss in pipe due to friction (Darcy-Weisbach equation: hf = f * (L/D) * (v²/2g))
headLoss := TFluidDynamicsKit.FrictionHeadLoss(
  frictionFactor,      // Dimensionless
  pipeLength,          // m
  pipeDiameter,        // m
  velocity             // m/s
);

// Head loss using Hazen-Williams formula for water pipes
hazenWilliamsHeadLoss := TFluidDynamicsKit.HazenWilliamsHeadLoss(
  pipeLength,          // m
  pipeDiameter,        // m
  flowRate,            // m³/s
  hazenWilliamsCoeff   // Dimensionless
);

// Laminar friction factor (f = 64/Re) - valid for Re < 2300
laminarFrictionFactor := TFluidDynamicsKit.LaminarFrictionFactor(
  reynoldsNumber       // Dimensionless
);

// Turbulent friction factor (Colebrook-White equation) - valid for Re > 4000
turbulentFrictionFactor := TFluidDynamicsKit.TurbulentFrictionFactor(
  reynoldsNumber,      // Dimensionless
  relativeRoughness,   // Dimensionless (ε/D)
  tolerance,           // Optional: convergence tolerance (default 1E-6)
  maxIterations        // Optional: maximum iterations (default 100)
);

// Simplified Blasius correlation for smooth pipes (valid for 4000 < Re < 10⁵)
blasiusFrictionFactor := TFluidDynamicsKit.BlasiusFrictionFactor(
  reynoldsNumber       // Dimensionless
);
```

## Dimensional Analysis

Calculate important dimensionless numbers in fluid dynamics:

```pascal
// Froude number (ratio of inertial to gravitational forces: Fr = v/sqrt(g*L))
froudeNumber := TFluidDynamicsKit.FroudeNumber(
  velocity,            // m/s
  characteristicLength // m
);

// Weber number (ratio of inertial force to surface tension: We = (ρ*v²*L)/σ)
weberNumber := TFluidDynamicsKit.WeberNumber(
  density,             // kg/m³
  velocity,            // m/s
  characteristicLength,// m
  surfaceTension       // N/m
);

// Euler number (ratio of pressure forces to inertial forces: Eu = ΔP/(ρ*v²))
eulerNumber := TFluidDynamicsKit.EulerNumber(
  pressureDifference,  // Pa
  density,             // kg/m³
  velocity             // m/s
);

// Mach number (ratio of flow velocity to speed of sound: Ma = v/c)
machNumber := TFluidDynamicsKit.MachNumber(
  velocity,            // m/s
  speedOfSound         // m/s
);

// Strouhal number (measures oscillating flow mechanisms: St = (f*L)/v)
strouhalNumber := TFluidDynamicsKit.StrouhalNumber(
  frequency,           // Hz
  characteristicLength,// m
  velocity             // m/s
);

// Prandtl number (ratio of momentum diffusivity to thermal diffusivity: Pr = ν/α = (μ*cp)/k)
prandtlNumber := TFluidDynamicsKit.PrandtlNumber(
  dynamicViscosity,    // Pa·s
  specificHeat,        // J/(kg·K)
  thermalConductivity  // W/(m·K)
);

// Nusselt number (ratio of convective to conductive heat transfer: Nu = (h*L)/k)
nusseltNumber := TFluidDynamicsKit.NusseltNumber(
  heatTransferCoeff,   // W/(m²·K)
  characteristicLength,// m
  thermalConductivity  // W/(m·K)
);
```

## Aerodynamics

Calculate aerodynamic forces and pressures:

```pascal
// Lift force: L = CL * 0.5 * ρ * v² * A
liftForce := TFluidDynamicsKit.LiftForce(
  liftCoefficient,     // Dimensionless
  density,             // kg/m³
  velocity,            // m/s
  referenceArea        // m²
);

// Drag force: D = CD * 0.5 * ρ * v² * A
dragForce := TFluidDynamicsKit.DragForce(
  dragCoefficient,     // Dimensionless
  density,             // kg/m³
  velocity,            // m/s
  referenceArea        // m²
);

// Dynamic pressure: q = 0.5 * ρ * v²
dynamicPressure := TFluidDynamicsKit.DynamicPressure(
  density,             // kg/m³
  velocity             // m/s
);

// Stagnation pressure: p0 = p + q
stagnationPressure := TFluidDynamicsKit.StagnationPressure(
  staticPressure,      // Pa
  dynamicPressure      // Pa
);

// Pressure coefficient: Cp = (p - p∞)/(0.5*ρ*v²)
pressureCoefficient := TFluidDynamicsKit.PressureCoefficient(
  pressure,            // Pa
  freeStreamPressure,  // Pa
  freeStreamDensity,   // kg/m³
  freeStreamVelocity   // m/s
);
```

## Compressible Flow

Calculate properties of compressible flow:

```pascal
// Speed of sound in ideal gas: c = sqrt(γ*R*T)
speedOfSound := TFluidDynamicsKit.SpeedOfSound(
  specificHeatRatio,   // Dimensionless (γ)
  gasConstant,         // J/(kg·K) (R)
  temperature          // K
);

// Stagnation temperature ratio: T0/T = 1 + ((γ-1)/2)*M²
stagnationTempRatio := TFluidDynamicsKit.StagnationTemperatureRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Stagnation pressure ratio: p0/p = (1 + ((γ-1)/2)*M²)^(γ/(γ-1))
stagnationPressRatio := TFluidDynamicsKit.StagnationPressureRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);

// Area ratio in isentropic flow: A/A* = (1/M)*[(2/(γ+1))*(1+((γ-1)/2)*M²)]^((γ+1)/(2*(γ-1)))
areaRatio := TFluidDynamicsKit.IsentropicAreaRatio(
  machNumber,          // Dimensionless
  specificHeatRatio    // Dimensionless (γ)
);
```

## Pumps and Turbines

Calculate hydraulic machinery performance:

```pascal
// Pump power: P = ρ*g*Q*H / η
pumpPower := TFluidDynamicsKit.PumpPower(
  density,             // kg/m³
  flowRate,            // m³/s
  head,                // m
  efficiency           // Dimensionless (0-1)
);

// Pump head: H = (p2-p1)/(ρ*g) + (v2²-v1²)/(2*g) + (z2-z1)
pumpHead := TFluidDynamicsKit.PumpHead(
  pressureDiff,        // Pa
  density,             // kg/m³
  velocityDiff,        // m/s
  heightDiff           // m
);

// Specific speed of pumps: Ns = N*sqrt(Q)/H^(3/4)
specificSpeed := TFluidDynamicsKit.PumpSpecificSpeed(
  rpm,                 // RPM
  flowRate,            // m³/s
  head                 // m
);

// Turbine power output: P = η*ρ*g*Q*H
turbinePower := TFluidDynamicsKit.TurbinePower(
  efficiency,          // Dimensionless (0-1)
  density,             // kg/m³
  flowRate,            // m³/s
  head                 // m
);
```

## Open Channel Flow

Calculate properties of open channel flow:

```pascal
// Chezy formula for open channel flow velocity: v = C*sqrt(R*S)
chezyVelocity := TFluidDynamicsKit.ChezyVelocity(
  chezyCoefficient,    // Dimensionless
  hydraulicRadius,     // m
  channelSlope         // Dimensionless (m/m)
);

// Manning equation for velocity: v = (1/n)*R^(2/3)*S^(1/2)
manningVelocity := TFluidDynamicsKit.ManningVelocity(
  manningCoefficient,  // Dimensionless
  hydraulicRadius,     // m
  channelSlope         // Dimensionless (m/m)
);

// Critical depth for rectangular channel: yc = (q²/g)^(1/3)
criticalDepth := TFluidDynamicsKit.CriticalDepthRectangular(
  unitDischarge        // m²/s (discharge per unit width)
);

// Froude number for open channel flow: Fr = v/sqrt(g*y)
channelFroudeNumber := TFluidDynamicsKit.OpenChannelFroudeNumber(
  velocity,            // m/s
  waterDepth           // m
);
```

## Error Handling

All methods include appropriate validation and will raise exceptions with descriptive messages when input parameters are invalid. For example:

- Negative or zero values where positive values are required
- Invalid range for Reynolds number in friction factor calculations
- Division by zero situations
- Physical impossibilities (like negative velocities from Bernoulli's equation)

Always surround calls with try-except blocks when reliability is crucial.

## Examples

### Example 1: Calculate pipe head loss

```pascal
try
  // Calculate head loss in a water pipe
  const 
    PipeDiameter = 0.05;    // m
    PipeLength = 100;       // m
    FlowVelocity = 2;       // m/s
    RelativeRoughness = 0.0002; // Dimensionless
  
  // Get Reynolds number
  var ReynoldsNum := TFluidDynamicsKit.ReynoldsNumber(
    TFluidDynamicsKit.DensityWater,
    FlowVelocity,
    PipeDiameter,
    TFluidDynamicsKit.DynamicViscosityWater
  );
  
  // Get appropriate friction factor based on flow regime
  var FrictionFactor: Double;
  if ReynoldsNum < 2300 then
    FrictionFactor := TFluidDynamicsKit.LaminarFrictionFactor(ReynoldsNum)
  else
    FrictionFactor := TFluidDynamicsKit.TurbulentFrictionFactor(ReynoldsNum, RelativeRoughness);
  
  // Calculate head loss
  var HeadLoss := TFluidDynamicsKit.FrictionHeadLoss(
    FrictionFactor,
    PipeLength,
    PipeDiameter,
    FlowVelocity
  );
  
  WriteLn('Head loss: ', HeadLoss:0:2, ' m');
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```

### Example 2: Aerodynamic forces on an airfoil

```pascal
try
  // Calculate lift and drag forces on an airfoil
  const
    AirDensity = 1.225;       // kg/m³
    Velocity = 100;           // m/s
    WingArea = 20;            // m²
    LiftCoefficient = 0.5;    // Dimensionless
    DragCoefficient = 0.03;   // Dimensionless
  
  var LiftForce := TFluidDynamicsKit.LiftForce(
    LiftCoefficient,
    AirDensity,
    Velocity,
    WingArea
  );
  
  var DragForce := TFluidDynamicsKit.DragForce(
    DragCoefficient,
    AirDensity,
    Velocity,
    WingArea
  );
  
  WriteLn('Lift force: ', LiftForce:0:2, ' N');
  WriteLn('Drag force: ', DragForce:0:2, ' N');
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```
