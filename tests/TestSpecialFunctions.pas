unit TestSpecialFunctions;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestBessel = class(TTestCase)
  private
    procedure CheckReference(const LabelText: String;
      const Expected, Actual: Double);
  published
    procedure TestJReferenceCorpus;
    procedure TestYReferenceCorpus;
    procedure TestParityAndWronskian;
    procedure TestDomainAndEndpoints;
  end;

implementation

type
  TBesselReference = record
    X, J0, J1, Y0, Y1: Double;
  end;

{$I BesselReference.inc}

procedure TTestBessel.CheckReference(const LabelText: String;
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

procedure TTestBessel.TestJReferenceCorpus;
var
  I: Integer;
  R: TBesselReference;
begin
  for I := 0 to BesselReferenceCount - 1 do
  begin
    R := BesselReferences[I];
    CheckReference(Format('J0(%.17g)', [R.X]), R.J0, BesselJ0(R.X));
    CheckReference(Format('J1(%.17g)', [R.X]), R.J1, BesselJ1(R.X));
  end;
end;

procedure TTestBessel.TestYReferenceCorpus;
var
  I: Integer;
  R: TBesselReference;
begin
  for I := 0 to BesselReferenceCount - 1 do
  begin
    R := BesselReferences[I];
    CheckReference(Format('Y0(%.17g)', [R.X]), R.Y0, BesselY0(R.X));
    CheckReference(Format('Y1(%.17g)', [R.X]), R.Y1, BesselY1(R.X));
  end;
end;

procedure TTestBessel.TestParityAndWronskian;
const
  Points: array[0..5] of Double = (0.5, 1.0, 8.0, 16.0, 30.0, 100.0);
var
  I: Integer;
  X, W: Double;
begin
  for I := Low(Points) to High(Points) do
  begin
    X := Points[I];
    CheckReference('J0 parity', BesselJ0(X), BesselJ0(-X));
    CheckReference('J1 parity', -BesselJ1(X), BesselJ1(-X));
    W := BesselJ1(X) * BesselY0(X) - BesselJ0(X) * BesselY1(X);
    CheckReference('J/Y Wronskian', 2.0 / (Pi * X), W);
  end;
end;

procedure TTestBessel.TestDomainAndEndpoints;
begin
  AssertEquals('J0(0)', 1.0, BesselJ0(0.0), 0.0);
  AssertEquals('J1(0)', 0.0, BesselJ1(0.0), 0.0);
  AssertTrue('Y0(0) pole', IsInfinite(BesselY0(0.0)) and
    (BesselY0(0.0) < 0.0));
  AssertTrue('Y1(0) pole', IsInfinite(BesselY1(0.0)) and
    (BesselY1(0.0) < 0.0));
  AssertTrue('Y1 overflow is negative infinity',
    IsInfinite(BesselY1(1E-310)) and (BesselY1(1E-310) < 0.0));
  AssertTrue('Y0 negative domain', IsNan(BesselY0(-1.0)));
  AssertTrue('Y1 negative domain', IsNan(BesselY1(-1.0)));
  AssertTrue('J0 outside validated range', IsNan(BesselJ0(100.1)));
  AssertTrue('J1 outside validated range', IsNan(BesselJ1(-100.1)));
  AssertTrue('Y0 outside validated range', IsNan(BesselY0(100.1)));
  AssertTrue('Y1 outside validated range', IsNan(BesselY1(100.1)));
  AssertTrue('J0 NaN', IsNan(BesselJ0(NaN)));
  AssertTrue('J1 +Infinity', IsNan(BesselJ1(Infinity)));
  AssertTrue('Y0 NaN', IsNan(BesselY0(NaN)));
  AssertTrue('Y1 +Infinity', IsNan(BesselY1(Infinity)));
end;

initialization
  RegisterTest(TTestBessel);

end.
