unit TestModifiedBessel;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestModifiedBessel = class(TTestCase)
  private
    procedure CheckReference(const LabelText: String;
      const Expected, Actual: Double);
  published
    procedure TestReferenceCorpus;
    procedure TestParityAndWronskian;
    procedure TestDomainAndEndpoints;
  end;

implementation

type
  TModifiedBesselReference = record
    X, I0, I1, K0, K1: Double;
  end;

{$I ModifiedBesselReference.inc}

procedure TTestModifiedBessel.CheckReference(const LabelText: String;
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

procedure TTestModifiedBessel.TestReferenceCorpus;
var
  I: Integer;
  R: TModifiedBesselReference;
begin
  for I := 0 to ModifiedBesselReferenceCount - 1 do
  begin
    R := ModifiedBesselReferences[I];
    CheckReference(Format('I0(%.17g)', [R.X]), R.I0, ModifiedBesselI0(R.X));
    CheckReference(Format('I1(%.17g)', [R.X]), R.I1, ModifiedBesselI1(R.X));
    CheckReference(Format('K0(%.17g)', [R.X]), R.K0, ModifiedBesselK0(R.X));
    CheckReference(Format('K1(%.17g)', [R.X]), R.K1, ModifiedBesselK1(R.X));
  end;
end;

procedure TTestModifiedBessel.TestParityAndWronskian;
const
  Points: array[0..7] of Double = (0.1, 0.5, 1.0, 2.0, 8.0, 16.0, 30.0, 100.0);
var
  I: Integer;
  X, W: Double;
begin
  for I := Low(Points) to High(Points) do
  begin
    X := Points[I];
    CheckReference('I0 parity', ModifiedBesselI0(X), ModifiedBesselI0(-X));
    CheckReference('I1 parity', -ModifiedBesselI1(X), ModifiedBesselI1(-X));
    W := ModifiedBesselI0(X) * ModifiedBesselK1(X) +
      ModifiedBesselI1(X) * ModifiedBesselK0(X);
    CheckReference('I/K Wronskian', 1.0 / X, W);
  end;
end;

procedure TTestModifiedBessel.TestDomainAndEndpoints;
begin
  AssertEquals('I0(0)', 1.0, ModifiedBesselI0(0.0), 0.0);
  AssertEquals('I1(0)', 0.0, ModifiedBesselI1(0.0), 0.0);
  AssertTrue('K0(0) pole', IsInfinite(ModifiedBesselK0(0.0)) and
    (ModifiedBesselK0(0.0) > 0.0));
  AssertTrue('K1(0) pole', IsInfinite(ModifiedBesselK1(0.0)) and
    (ModifiedBesselK1(0.0) > 0.0));
  AssertTrue('K1 overflow is positive infinity',
    IsInfinite(ModifiedBesselK1(1E-310)) and
    (ModifiedBesselK1(1E-310) > 0.0));
  AssertTrue('K0 negative domain', IsNan(ModifiedBesselK0(-1.0)));
  AssertTrue('K1 negative domain', IsNan(ModifiedBesselK1(-1.0)));
  AssertTrue('I0 outside validated range', IsNan(ModifiedBesselI0(100.1)));
  AssertTrue('I1 outside validated range', IsNan(ModifiedBesselI1(-100.1)));
  AssertTrue('K0 outside validated range', IsNan(ModifiedBesselK0(100.1)));
  AssertTrue('K1 outside validated range', IsNan(ModifiedBesselK1(100.1)));
  AssertTrue('I0 NaN', IsNan(ModifiedBesselI0(NaN)));
  AssertTrue('I1 +Infinity', IsNan(ModifiedBesselI1(Infinity)));
  AssertTrue('K0 NaN', IsNan(ModifiedBesselK0(NaN)));
  AssertTrue('K1 +Infinity', IsNan(ModifiedBesselK1(Infinity)));
end;

initialization
  RegisterTest(TTestModifiedBessel);

end.
