program elliptic_integrals;

{ A bounded real Double Legendre elliptic integral example for 2.1. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  M, Phi, CompleteK, CompleteE, IncompleteF, IncompleteE: Double;
begin
  M := 0.5;
  Phi := 1.0;
  CompleteK := CompleteEllipticK(M);
  CompleteE := CompleteEllipticE(M);
  IncompleteF := IncompleteEllipticF(Phi, M);
  IncompleteE := IncompleteEllipticE(Phi, M);

  Writeln('K(0.5) = ', CompleteK:0:9);
  Writeln('E(0.5) = ', CompleteE:0:9);
  Writeln('F(1, 0.5) = ', IncompleteF:0:9);
  Writeln('E(1, 0.5) = ', IncompleteE:0:9);
  if (Abs(IncompleteEllipticF(Pi / 2, M) - CompleteK) > 5E-12) or
    (Abs(IncompleteEllipticE(Pi / 2, M) - CompleteE) > 5E-12) then
    Halt(1);
  Writeln('elliptic integrals: success');
end.
