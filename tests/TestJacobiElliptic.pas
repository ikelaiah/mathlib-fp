unit TestJacobiElliptic;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestJacobiElliptic = class(TTestCase)
  published
    procedure TestElementaryLimits;
    procedure TestDLMFExampleAndIdentities;
    procedure TestIndependentReferences;
    procedure TestQuarterPeriods;
    procedure TestDomainsAndNonFiniteInputs;
  end;

implementation

{$I JacobiEllipticReference.inc}

procedure TTestJacobiElliptic.TestElementaryLimits;
const
  U = 0.7;
begin
  AssertEquals('sn(u,0)=sin(u)', Sin(U), JacobiEllipticSN(U, 0.0), 2E-15);
  AssertEquals('cn(u,0)=cos(u)', Cos(U), JacobiEllipticCN(U, 0.0), 2E-15);
  AssertEquals('dn(u,0)=1', 1.0, JacobiEllipticDN(U, 0.0), 0.0);
  AssertEquals('sn(u,1)=tanh(u)', Tanh(U), JacobiEllipticSN(U, 1.0), 2E-15);
  AssertEquals('cn(u,1)=sech(u)', 1.0 / Cosh(U), JacobiEllipticCN(U, 1.0), 2E-15);
  AssertEquals('dn(u,1)=sech(u)', 1.0 / Cosh(U), JacobiEllipticDN(U, 1.0), 2E-15);
end;

procedure TTestJacobiElliptic.TestDLMFExampleAndIdentities;
var
  SNValue, CNValue, DNValue: Double;
begin
  SNValue := JacobiEllipticSN(0.8, Sqr(0.65));
  CNValue := JacobiEllipticCN(0.8, Sqr(0.65));
  DNValue := JacobiEllipticDN(0.8, Sqr(0.65));
  AssertEquals('DLMF sn example', 0.6950642165, SNValue, 5E-10);
  AssertEquals('DLMF cn example', 0.7189476580, CNValue, 5E-10);
  AssertEquals('DLMF dn example', 0.8921234349, DNValue, 5E-10);
  AssertEquals('sn^2+cn^2=1', 1.0, Sqr(SNValue) + Sqr(CNValue), 2E-14);
  AssertEquals('m sn^2+dn^2=1', 1.0,
    Sqr(0.65 * SNValue) + Sqr(DNValue), 2E-14);
  AssertEquals('sn is odd', -SNValue,
    JacobiEllipticSN(-0.8, Sqr(0.65)), 2E-14);
  AssertEquals('cn is even', CNValue,
    JacobiEllipticCN(-0.8, Sqr(0.65)), 2E-14);
  AssertEquals('dn is even', DNValue,
    JacobiEllipticDN(-0.8, Sqr(0.65)), 2E-14);
end;

procedure TTestJacobiElliptic.TestDomainsAndNonFiniteInputs;
var
  M, SNValue, CNValue, DNValue: Double;
begin
  AssertEquals('argument lower boundary is accepted', Sin(-100.0),
    JacobiEllipticSN(-100.0, 0.0), 0.0);
  AssertEquals('argument upper boundary is accepted', Sin(100.0),
    JacobiEllipticSN(100.0, 0.0), 0.0);
  AssertEquals('m=1 large argument sn limit', 1.0,
    JacobiEllipticSN(100.0, 1.0), 0.0);
  AssertEquals('m=1 large argument sech limit', 0.0,
    JacobiEllipticCN(100.0, 1.0), 1E-43);
  M := 1.0 - 2.2204460492503131E-16;
  SNValue := JacobiEllipticSN(10.0, M);
  CNValue := JacobiEllipticCN(10.0, M);
  DNValue := JacobiEllipticDN(10.0, M);
  AssertTrue('near-one parameter returns finite sn', not IsNan(SNValue));
  AssertTrue('near-one parameter returns finite cn', not IsNan(CNValue));
  AssertTrue('near-one parameter returns finite dn', not IsNan(DNValue));
  AssertEquals('near-one sn/cn identity', 1.0,
    Sqr(SNValue) + Sqr(CNValue), 2E-14);
  AssertEquals('near-one sn/dn identity', 1.0,
    M * Sqr(SNValue) + Sqr(DNValue), 2E-14);
  AssertTrue('argument below range', IsNan(JacobiEllipticSN(-100.01, 0.5)));
  AssertTrue('argument above range', IsNan(JacobiEllipticCN(100.01, 0.5)));
  AssertTrue('parameter below range', IsNan(JacobiEllipticDN(0.5, -0.01)));
  AssertTrue('parameter above range', IsNan(JacobiEllipticSN(0.5, 1.01)));
  AssertTrue('NaN argument', IsNan(JacobiEllipticSN(NaN, 0.5)));
  AssertTrue('infinite argument', IsNan(JacobiEllipticSN(Infinity, 0.5)));
  AssertTrue('NaN parameter', IsNan(JacobiEllipticDN(0.5, NaN)));
  AssertTrue('infinite parameter', IsNan(JacobiEllipticCN(0.5, Infinity)));
end;

procedure TTestJacobiElliptic.TestQuarterPeriods;
const
  Parameters: array[0..2] of Double = (0.1, 0.5, 0.9999);
var
  I: Integer;
  U, M, SNValue, CNValue, DNValue: Double;
begin
  for I := Low(Parameters) to High(Parameters) do
  begin
    M := Parameters[I];
    U := CompleteEllipticK(M);
    SNValue := JacobiEllipticSN(U, M);
    CNValue := JacobiEllipticCN(U, M);
    DNValue := JacobiEllipticDN(U, M);
    if IsNan(SNValue) or IsNan(CNValue) or IsNan(DNValue) then
      Fail('Jacobi functions rejected quarter period for M=' + FloatToStr(M));
    AssertEquals('sn(K,m)=1', 1.0, JacobiEllipticSN(U, M), 5E-14);
    AssertEquals('cn(K,m)=0', 0.0, JacobiEllipticCN(U, M), 5E-14);
    AssertEquals('dn(K,m)=sqrt(1-m)', Sqrt(1.0 - M),
      JacobiEllipticDN(U, M), 5E-14);
  end;
end;

procedure TTestJacobiElliptic.TestIndependentReferences;
var
  I: Integer;
  Tolerance: Double;
begin
  for I := 0 to JacobiEllipticReferenceCount - 1 do
  begin
    Tolerance := Max(5E-13,
      5E-12 * Abs(JacobiEllipticReferences[I].SN));
    AssertEquals('sn reference ' + IntToStr(I),
      JacobiEllipticReferences[I].SN,
      JacobiEllipticSN(JacobiEllipticReferences[I].U,
        JacobiEllipticReferences[I].M), Tolerance);
    Tolerance := Max(5E-13,
      5E-12 * Abs(JacobiEllipticReferences[I].CN));
    AssertEquals('cn reference ' + IntToStr(I),
      JacobiEllipticReferences[I].CN,
      JacobiEllipticCN(JacobiEllipticReferences[I].U,
        JacobiEllipticReferences[I].M), Tolerance);
    Tolerance := Max(5E-13,
      5E-12 * Abs(JacobiEllipticReferences[I].DN));
    AssertEquals('dn reference ' + IntToStr(I),
      JacobiEllipticReferences[I].DN,
      JacobiEllipticDN(JacobiEllipticReferences[I].U,
        JacobiEllipticReferences[I].M), Tolerance);
  end;
end;

initialization
  RegisterTest(TTestJacobiElliptic);

end.
