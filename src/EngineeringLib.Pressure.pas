unit EngineeringLib.Pressure;

{-----------------------------------------------------------------------------
 EngineeringLib.Pressure

 Re-exports pressure-related functionality from EngineeringLib.FluidDynamics.

 Relevant methods on TFluidDynamicsKit:
   BernoulliPressure / BernoulliVelocity / BernoulliHeight — Bernoulli equation
   DynamicPressure / StagnationPressure                    — aerodynamic pressures
   PressureCoefficient                                     — dimensionless pressure
   FrictionHeadLoss / HazenWilliamsHeadLoss               — pipe head loss
   LaminarFrictionFactor / TurbulentFrictionFactor        — Darcy friction factors
   BlasiusFrictionFactor                                   — Blasius approximation
   StagnationPressureRatio / IsentropicPressureRatio       — compressible flow
   EulerNumber / WeberNumber                               — dimensionless groups
   PumpPower                                               — hydraulic power
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  EngineeringLib.FluidDynamics;

type
  TPressureKit = TFluidDynamicsKit;

implementation

end.
