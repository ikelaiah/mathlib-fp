program jacobi_elliptic_functions;

{ Bounded real Jacobi sn/cn/dn with the parameter convention for 2.1. }

{$mode objfpc}{$H+}{$J-}

uses
  Math, MathBase.SpecialFunctions;

var
  U, M, SNValue, CNValue, DNValue, IdentityResidual: Double;
begin
  U := 0.8;
  M := Sqr(0.65);
  SNValue := JacobiEllipticSN(U, M);
  CNValue := JacobiEllipticCN(U, M);
  DNValue := JacobiEllipticDN(U, M);
  IdentityResidual := Abs(Sqr(SNValue) + Sqr(CNValue) - 1.0);

  Writeln('sn(0.8, 0.4225) = ', SNValue:0:10);
  Writeln('cn(0.8, 0.4225) = ', CNValue:0:10);
  Writeln('dn(0.8, 0.4225) = ', DNValue:0:10);
  Writeln('sn^2 + cn^2 residual = ', IdentityResidual:0:12);
  Writeln('sn(0.8, 1) = ', JacobiEllipticSN(U, 1.0):0:10);
  if (Abs(SNValue - 0.6950642164711176) > 5E-13) or
    (Abs(CNValue - 0.7189476580262267) > 5E-13) or
    (IdentityResidual > 5E-13) then
    Halt(1);
  Writeln('Jacobi elliptic example: success');
end.
