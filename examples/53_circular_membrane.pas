program CircularMembrane;

{$mode objfpc}{$H+}{$J-}

uses
  MathBase.SpecialFunctions, NumericsLib.Numerics;

function SecondOrderMode(X: Double): Double;
begin
  Result := BesselJ(2, X);
end;

const
  Radius = 0.25; { metres }
  ExpectedFirstRoot = 5.135622301840683;
var
  Root, Wavenumber, RimAmplitude: Double;
begin
  { The first positive J2 zero lies between 5 and 6. For a fixed circular
    rim, the radial factor J2(k*r) must vanish at the membrane radius. }
  Root := TNumericsKit.Bisection(@SecondOrderMode, 5.0, 6.0, 1E-13);
  Wavenumber := Root / Radius;
  RimAmplitude := SecondOrderMode(Wavenumber * Radius);
  if (Abs(Root - ExpectedFirstRoot) > 2E-12) or
    (Abs(RimAmplitude) > 2E-12) then
    Halt(1);
  Writeln('first positive J2 zero = ', Root:0:9);
  Writeln('radial wavenumber (1/m) = ', Wavenumber:0:9);
  Writeln('circular membrane: success');
end.
