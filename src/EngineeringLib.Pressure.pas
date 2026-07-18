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
   StagnationPressureRatio                                 — compressible flow
   EulerNumber / WeberNumber                               — dimensionless groups
   PumpPower                                               — hydraulic power
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  EngineeringLib.Common, EngineeringLib.FluidDynamics;

type
  { Focused exception name for callers that import only this unit. }
  EPressureError = EngineeringLib.Common.EFluidDynamicsError;
  TPressureKit = TFluidDynamicsKit;

implementation

end.
