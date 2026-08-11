program AliasPackageBoundary;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils,
  EngineeringLib.Common, EngineeringLib.FluidDynamics,
  EngineeringLib.Pressure, EngineeringLib.Velocity;

type
  TCanonicalKitClass = class of TFluidDynamicsKit;
  TPressureKitClass = class of TPressureKit;
  TVelocityKitClass = class of TVelocityKit;

procedure Require(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create('alias package boundary: ' + MessageText);
end;

procedure RaisePressureError;
begin
  TPressureKit.DynamicPressure(-1.0, 1.0);
end;

procedure RaiseVelocityError;
begin
  TVelocityKit.MachNumber(1.0, 0.0);
end;

var
  Canonical: TCanonicalKitClass;
  Pressure: TPressureKitClass;
  Velocity: TVelocityKitClass;
  PressureCaught, VelocityCaught: Boolean;
begin
  Pressure := TPressureKit;
  Velocity := TVelocityKit;
  Canonical := Pressure;
  Require(Canonical = TFluidDynamicsKit, 'TPressureKit type identity changed');
  Canonical := Velocity;
  Require(Canonical = TFluidDynamicsKit, 'TVelocityKit type identity changed');
  Require(Abs(TPressureKit.DynamicPressure(1.225, 100.0) -
    TFluidDynamicsKit.DynamicPressure(1.225, 100.0)) <= 1.0E-12,
    'pressure numerical behavior differs');
  Require(Abs(TVelocityKit.MachNumber(170.0, 340.0) -
    TFluidDynamicsKit.MachNumber(170.0, 340.0)) <= 1.0E-12,
    'velocity numerical behavior differs');

  PressureCaught := False;
  try
    RaisePressureError;
  except
    on EFluidDynamicsError do
      PressureCaught := True;
  end;
  VelocityCaught := False;
  try
    RaiseVelocityError;
  except
    on EFluidDynamicsError do
      VelocityCaught := True;
  end;
  Require(PressureCaught and VelocityCaught,
    'focused aliases no longer raise the canonical exception class');

  WriteLn('alias package boundary: success');
end.
