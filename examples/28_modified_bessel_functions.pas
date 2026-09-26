program modified_bessel_functions;

{ A bounded real Double modified Bessel I/K example for the 2.1 development line. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  X, Wronskian: Double;
begin
  X := 1.0;
  Writeln('I0(1) = ', ModifiedBesselI0(X):0:9);
  Writeln('I1(1) = ', ModifiedBesselI1(X):0:9);
  Writeln('K0(1) = ', ModifiedBesselK0(X):0:9);
  Writeln('K1(1) = ', ModifiedBesselK1(X):0:9);

  Wronskian := ModifiedBesselI0(X) * ModifiedBesselK1(X) +
    ModifiedBesselI1(X) * ModifiedBesselK0(X);
  Writeln('Wronskian residual = ', Abs(Wronskian - 1.0 / X):0:12);
  if Abs(Wronskian - 1.0 / X) > 5E-12 then
    Halt(1);
  Writeln('modified bessel functions: success');
end.
