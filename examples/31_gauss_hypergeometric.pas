program gauss_hypergeometric;

{ Bounded real Gauss 2F1 series and its terminating-polynomial case for 2.1. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  LogIdentity, PolynomialValue: Double;
begin
  LogIdentity := GaussHypergeometric2F1(1.0, 1.0, 2.0, 0.5);
  PolynomialValue := GaussHypergeometric2F1(-2.0, 3.0, 4.0, 0.5);

  Writeln('2F1(1, 1; 2; 0.5) = ', LogIdentity:0:9);
  Writeln('2F1(-2, 3; 4; 0.5) = ', PolynomialValue:0:9);
  Writeln('2F1(1, 1; 2; -0.75) = ',
    GaussHypergeometric2F1(1.0, 1.0, 2.0, -0.75):0:9);
  if (Abs(LogIdentity - (-Ln(0.5) / 0.5)) > 5E-13) or
    (Abs(PolynomialValue - 0.4) > 5E-13) then
    Halt(1);
  Writeln('Gauss hypergeometric example: success');
end.
