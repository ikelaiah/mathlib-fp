unit TestExponentialIntegrals;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestExponentialIntegrals = class(TTestCase)
  private
    procedure CheckReference(const LabelText: String;
      const Expected, Actual: Double);
  published
    procedure TestEiReferenceCorpus;
    procedure TestE1ReferenceCorpus;
    procedure TestEiE1Relation;
    procedure TestDomainsAndPoles;
  end;

implementation

{$I ExponentialIntegralReference.inc}

procedure TTestExponentialIntegrals.CheckReference(const LabelText: String;
  const Expected, Actual: Double);
const
  AbsoluteBudget = 5E-13;
  RelativeBudget = 5E-12;
var
  Allowed: Double;
begin
  Allowed := Max(AbsoluteBudget, RelativeBudget * Abs(Expected));
  AssertTrue(LabelText + Format(': expected %.17g, got %.17g', [Expected, Actual]),
    not IsNan(Actual) and (Abs(Expected - Actual) <= Allowed));
end;

procedure TTestExponentialIntegrals.TestEiReferenceCorpus;
var
  I: Integer;
begin
  for I := 0 to EiReferenceCount - 1 do
    CheckReference(Format('Ei(%.17g)', [EiReferences[I].X]),
      EiReferences[I].Value, ExponentialIntegralEi(EiReferences[I].X));
end;

procedure TTestExponentialIntegrals.TestE1ReferenceCorpus;
var
  I: Integer;
begin
  for I := 0 to E1ReferenceCount - 1 do
    CheckReference(Format('E1(%.17g)', [E1References[I].X]),
      E1References[I].Value, ExponentialIntegralE1(E1References[I].X));
end;

procedure TTestExponentialIntegrals.TestEiE1Relation;
const
  Points: array[0..6] of Double = (1E-12, 0.1, 0.5, 1.0, 2.0, 10.0, 100.0);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    CheckReference('Ei(-x)=-E1(x)', -ExponentialIntegralE1(Points[I]),
      ExponentialIntegralEi(-Points[I]));
end;

procedure TTestExponentialIntegrals.TestDomainsAndPoles;
begin
  AssertTrue('Ei(+0) is negative infinity',
    IsInfinite(ExponentialIntegralEi(0.0)) and
    (ExponentialIntegralEi(0.0) < 0.0));
  AssertTrue('Ei(-0) is negative infinity',
    IsInfinite(ExponentialIntegralEi(-0.0)) and
    (ExponentialIntegralEi(-0.0) < 0.0));
  AssertTrue('E1(0) is positive infinity',
    IsInfinite(ExponentialIntegralE1(0.0)) and
    (ExponentialIntegralE1(0.0) > 0.0));
  AssertTrue('Ei below validated range',
    IsNan(ExponentialIntegralEi(-100.01)));
  AssertTrue('Ei above validated range',
    IsNan(ExponentialIntegralEi(100.01)));
  AssertTrue('E1 negative real branch is unsupported',
    IsNan(ExponentialIntegralE1(-0.1)));
  AssertTrue('Ei NaN', IsNan(ExponentialIntegralEi(NaN)));
  AssertTrue('E1 positive infinity', IsNan(ExponentialIntegralE1(Infinity)));
  AssertTrue('E1 negative infinity', IsNan(ExponentialIntegralE1(-Infinity)));
end;

initialization
  RegisterTest(TTestExponentialIntegrals);

end.
