program exponential_integrals;

{ Bounded real Ei and E1 functions with their real-axis conventions for 2.1. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  EiValue, E1Value, IdentityResidual: Double;
begin
  EiValue := ExponentialIntegralEi(1.0);
  E1Value := ExponentialIntegralE1(1.0);
  IdentityResidual := ExponentialIntegralEi(-1.0) + E1Value;

  Writeln('Ei(1) = ', EiValue:0:9);
  Writeln('E1(1) = ', E1Value:0:9);
  Writeln('Ei(-1) + E1(1) = ', IdentityResidual:0:12);
  if Abs(IdentityResidual) > 5E-13 then
    Halt(1);
  Writeln('exponential integrals: success');
end.
