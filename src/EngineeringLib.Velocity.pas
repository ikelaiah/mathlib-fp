unit EngineeringLib.Velocity;

{-----------------------------------------------------------------------------
 EngineeringLib.Velocity

 Re-exports velocity and flow-rate functionality from EngineeringLib.FluidDynamics.

 Relevant methods on TFluidDynamicsKit:
   ReynoldsNumber / ReynoldsNumberKinematic  — flow regime classification
   CalculateVolumeFlowRate                   — Q = A * v
   MassFlowRate                              — ṁ = ρ * Q  (overloaded)
   FroudeNumber                              — open-channel regime
   MachNumber                                — compressible flow regime
   StrouhalNumber                            — oscillation frequency
   ChezyVelocity / ManningVelocity           — open-channel mean velocity
   PumpHead / PumpSpecificSpeed              — turbomachinery
   SpeedOfSound                              — ideal gas speed of sound
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  EngineeringLib.FluidDynamics;

type
  TVelocityKit = TFluidDynamicsKit;

implementation

end.
