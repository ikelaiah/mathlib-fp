unit TestGaussHypergeometric;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestGaussHypergeometric = class(TTestCase)
  private
    procedure CheckReference(const A, B, C, X, Expected: Double);
  published
    procedure TestReferenceCorpus;
    procedure TestIdentityAndSymmetry;
    procedure TestTerminatingSeries;
    procedure TestDomainAndNonFiniteInputs;
  end;

implementation

{$I HypergeometricReference.inc}

procedure TTestGaussHypergeometric.CheckReference(const A, B, C, X,
  Expected: Double);
const
  AbsoluteBudget = 5E-13;
  RelativeBudget = 5E-12;
var
  Actual, Allowed: Double;
begin
  Actual := GaussHypergeometric2F1(A, B, C, X);
  Allowed := Max(AbsoluteBudget, RelativeBudget * Abs(Expected));
  AssertTrue(Format('2F1(%.17g, %.17g; %.17g; %.17g): expected %.17g, got %.17g',
    [A, B, C, X, Expected, Actual]),
    not IsNan(Actual) and (Abs(Expected - Actual) <= Allowed));
end;

procedure TTestGaussHypergeometric.TestReferenceCorpus;
var
  I: Integer;
begin
  for I := 0 to HypergeometricReferenceCount - 1 do
    CheckReference(HypergeometricReferences[I].A,
      HypergeometricReferences[I].B, HypergeometricReferences[I].C,
      HypergeometricReferences[I].X, HypergeometricReferences[I].Value);
end;

procedure TTestGaussHypergeometric.TestIdentityAndSymmetry;
var
  Value, Expected: Double;
begin
  AssertEquals('F(0,b;c,x) = 1', 1.0,
    GaussHypergeometric2F1(0.0, 3.0, 2.0, 0.75), 0.0);
  Expected := -Ln(0.5) / 0.5;
  Value := GaussHypergeometric2F1(1.0, 1.0, 2.0, 0.5);
  AssertEquals('F(1,1;2;0.5) identity', Expected, Value, 2E-14);
  AssertEquals('symmetry in A and B',
    GaussHypergeometric2F1(1.0, 2.0, 3.0, 0.5),
    GaussHypergeometric2F1(2.0, 1.0, 3.0, 0.5), 2E-14);
end;

procedure TTestGaussHypergeometric.TestTerminatingSeries;
begin
  AssertEquals('terminating polynomial', 0.4,
    GaussHypergeometric2F1(-2.0, 3.0, 4.0, 0.5), 2E-15);
  AssertEquals('X=0', 1.0,
    GaussHypergeometric2F1(4.0, -5.0, 2.0, 0.0), 0.0);
end;

procedure TTestGaussHypergeometric.TestDomainAndNonFiniteInputs;
begin
  AssertTrue('A below range', IsNan(GaussHypergeometric2F1(-16.01, 1, 2, 0.1)));
  AssertTrue('B above range', IsNan(GaussHypergeometric2F1(1, 16.01, 2, 0.1)));
  AssertTrue('C below range', IsNan(GaussHypergeometric2F1(1, 1, 0.49, 0.1)));
  AssertTrue('C above range', IsNan(GaussHypergeometric2F1(1, 1, 32.01, 0.1)));
  AssertTrue('X below range', IsNan(GaussHypergeometric2F1(1, 1, 2, -0.75001)));
  AssertTrue('X above range', IsNan(GaussHypergeometric2F1(1, 1, 2, 0.75001)));
  AssertTrue('NaN parameter', IsNan(GaussHypergeometric2F1(NaN, 1, 2, 0.1)));
  AssertTrue('infinite A', IsNan(GaussHypergeometric2F1(-Infinity, 1, 2, 0.1)));
  AssertTrue('infinite B', IsNan(GaussHypergeometric2F1(1, Infinity, 2, 0.1)));
  AssertTrue('NaN C', IsNan(GaussHypergeometric2F1(1, 1, NaN, 0.1)));
  AssertTrue('infinite argument', IsNan(GaussHypergeometric2F1(1, 1, 2, Infinity)));
  AssertTrue('NaN argument', IsNan(GaussHypergeometric2F1(1, 1, 2, NaN)));
end;

initialization
  RegisterTest(TTestGaussHypergeometric);

end.
