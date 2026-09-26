program elliptic_third_kind;

{ Bounded real Legendre third-kind integrals for 2.1. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  IncompleteValue, CompleteValue: Double;
begin
  IncompleteValue := IncompleteEllipticPi(0.7, 0.4, 0.6);
  CompleteValue := CompleteEllipticPi(0.4, 0.6);

  Writeln('Pi(0.7, 0.4, 0.6) = ', IncompleteValue:0:10);
  Writeln('Pi(0.4, 0.6) = ', CompleteValue:0:10);
  Writeln('Pi(0.7, 0, 0.6) = ', IncompleteEllipticPi(0.7, 0.0, 0.6):0:10);
  if (Abs(IncompleteValue - 0.78587863983961159) > 5E-13) or
    (Abs(CompleteValue - 2.5909211565552215) > 5E-13) or
    (Abs(IncompleteEllipticPi(0.7, 0.0, 0.6) -
      IncompleteEllipticF(0.7, 0.6)) > 2E-14) then
    Halt(1);
  Writeln('Elliptic third-kind example: success');
end.
