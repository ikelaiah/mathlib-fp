unit TestEngineeringLib_Aliases;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  EngineeringLib.Velocity, EngineeringLib.Pressure;

type
  TTestEngineeringAliases = class(TTestCase)
  private
    procedure RaiseVelocityError;
    procedure RaisePressureError;
  published
    procedure TestVelocityAliasCalculation;
    procedure TestPressureAliasCalculation;
    procedure TestFocusedExceptionAliases;
  end;

implementation

procedure TTestEngineeringAliases.RaiseVelocityError;
begin
  TVelocityKit.MachNumber(10.0, 0.0);
end;

procedure TTestEngineeringAliases.RaisePressureError;
begin
  TPressureKit.DynamicPressure(-1.0, 10.0);
end;

procedure TTestEngineeringAliases.TestVelocityAliasCalculation;
begin
  AssertEquals('Mach number through velocity alias', 0.5,
    TVelocityKit.MachNumber(170.0, 340.0), 1E-12);
end;

procedure TTestEngineeringAliases.TestPressureAliasCalculation;
begin
  AssertEquals('Dynamic pressure through pressure alias', 6125.0,
    TPressureKit.DynamicPressure(1.225, 100.0), 1E-12);
end;

procedure TTestEngineeringAliases.TestFocusedExceptionAliases;
begin
  AssertException('Velocity alias exposes its exception type', EVelocityError,
    @RaiseVelocityError);
  AssertException('Pressure alias exposes its exception type', EPressureError,
    @RaisePressureError);
end;

initialization
  RegisterTest(TTestEngineeringAliases);

end.
