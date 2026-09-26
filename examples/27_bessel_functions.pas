program bessel_functions;

{ A bounded real Double Bessel J/Y example for the 2.1 development line. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  X, Wronskian: Double;
begin
  X := 1.0;
  Writeln('J0(1) = ', BesselJ0(X):0:9);
  Writeln('J1(1) = ', BesselJ1(X):0:9);
  Writeln('Y0(1) = ', BesselY0(X):0:9);
  Writeln('Y1(1) = ', BesselY1(X):0:9);

  Wronskian := BesselJ1(X) * BesselY0(X) -
    BesselJ0(X) * BesselY1(X);
  Writeln('Wronskian residual = ', Abs(Wronskian - 2.0 / (Pi * X)):0:12);
  if Abs(Wronskian - 2.0 / (Pi * X)) > 5E-12 then
    Halt(1);
  Writeln('bessel functions: success');
end.
