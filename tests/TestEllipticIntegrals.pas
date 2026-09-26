unit TestEllipticIntegrals;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SpecialFunctions;

type
  TTestEllipticIntegrals = class(TTestCase)
  private
    procedure CheckReference(const LabelText: String;
      const Expected, Actual: Double);
  published
    procedure TestIncompleteReferenceCorpus;
    procedure TestCompleteReferenceCorpus;
    procedure TestSymmetryAndDomains;
    procedure TestSingularEndpoints;
    procedure TestThirdKindReferenceValues;
    procedure TestThirdKindLimitsAndDomains;
  end;

implementation

{$I EllipticReference.inc}
{$I EllipticThirdKindReference.inc}

procedure TTestEllipticIntegrals.CheckReference(const LabelText: String;
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

procedure TTestEllipticIntegrals.TestIncompleteReferenceCorpus;
var
  I: Integer;
begin
  for I := 0 to EllipticReferenceCount - 1 do
  begin
    CheckReference(Format('F(%.17g, %.17g)',
      [EllipticReferences[I].Phi, EllipticReferences[I].M]),
      EllipticReferences[I].F, IncompleteEllipticF(
      EllipticReferences[I].Phi, EllipticReferences[I].M));
    CheckReference(Format('E(%.17g, %.17g)',
      [EllipticReferences[I].Phi, EllipticReferences[I].M]),
      EllipticReferences[I].E, IncompleteEllipticE(
      EllipticReferences[I].Phi, EllipticReferences[I].M));
  end;
end;

procedure TTestEllipticIntegrals.TestCompleteReferenceCorpus;
var
  I: Integer;
begin
  for I := 0 to EllipticCompleteCount - 1 do
  begin
    CheckReference(Format('K(%.17g)', [EllipticCompleteReferences[I].M]),
      EllipticCompleteReferences[I].K,
      CompleteEllipticK(EllipticCompleteReferences[I].M));
    CheckReference(Format('E(%.17g)', [EllipticCompleteReferences[I].M]),
      EllipticCompleteReferences[I].E,
      CompleteEllipticE(EllipticCompleteReferences[I].M));
  end;
end;

procedure TTestEllipticIntegrals.TestSymmetryAndDomains;
const
  Amplitudes: array[0..4] of Double = (0.1, 0.7, 1.2, 1.5, Pi / 2);
var
  I: Integer;
  Phi: Double;
begin
  for I := Low(Amplitudes) to High(Amplitudes) do
  begin
    Phi := Amplitudes[I];
    CheckReference('F odd symmetry', -IncompleteEllipticF(Phi, 0.37),
      IncompleteEllipticF(-Phi, 0.37));
    CheckReference('E odd symmetry', -IncompleteEllipticE(Phi, 0.37),
      IncompleteEllipticE(-Phi, 0.37));
  end;
  AssertTrue('K negative parameter', IsNan(CompleteEllipticK(-0.01)));
  AssertTrue('E parameter above one', IsNan(CompleteEllipticE(1.01)));
  AssertTrue('F amplitude outside principal interval',
    IsNan(IncompleteEllipticF(Pi / 2 + 1E-6, 0.2)));
  AssertTrue('E NaN parameter', IsNan(IncompleteEllipticE(0.2, NaN)));
  AssertTrue('F infinite amplitude', IsNan(IncompleteEllipticF(Infinity, 0.2)));
  AssertTrue('F NaN amplitude', IsNan(IncompleteEllipticF(NaN, 0.2)));
  AssertTrue('K infinite parameter', IsNan(CompleteEllipticK(Infinity)));
end;

procedure TTestEllipticIntegrals.TestSingularEndpoints;
var
  FValue: Double;
begin
  AssertEquals('K(0)', Pi / 2, CompleteEllipticK(0.0), 0.0);
  AssertEquals('E(0)', Pi / 2, CompleteEllipticE(0.0), 0.0);
  AssertEquals('F(phi, 0)', 0.75, IncompleteEllipticF(0.75, 0.0), 0.0);
  AssertEquals('E(phi, 0)', 0.75, IncompleteEllipticE(0.75, 0.0), 0.0);
  AssertTrue('K(1) positive infinity', IsInfinite(CompleteEllipticK(1.0)) and
    (CompleteEllipticK(1.0) > 0.0));
  AssertEquals('E(1)', 1.0, CompleteEllipticE(1.0), 0.0);
  AssertEquals('E(pi/2, 1)', 1.0, IncompleteEllipticE(Pi / 2, 1.0), 0.0);
  AssertEquals('E(-pi/2, 1)', -1.0, IncompleteEllipticE(-Pi / 2, 1.0), 0.0);
  AssertTrue('F(pi/2, 1) positive infinity',
    IsInfinite(IncompleteEllipticF(Pi / 2, 1.0)) and
    (IncompleteEllipticF(Pi / 2, 1.0) > 0.0));
  AssertTrue('F(-pi/2, 1) negative infinity',
    IsInfinite(IncompleteEllipticF(-Pi / 2, 1.0)) and
    (IncompleteEllipticF(-Pi / 2, 1.0) < 0.0));
  FValue := IncompleteEllipticF(Pi / 2 - 1E-8, 1.0);
  AssertTrue('F(near endpoint, 1) finite and positive',
    not IsInfinite(FValue) and (FValue > 0.0));
end;

procedure TTestEllipticIntegrals.TestThirdKindReferenceValues;
var
  I: Integer;
begin
  for I := 0 to EllipticThirdKindReferenceCount - 1 do
    CheckReference(Format('Pi(%.17g, %.17g, %.17g)',
      [EllipticThirdKindReferences[I].Phi, EllipticThirdKindReferences[I].N,
      EllipticThirdKindReferences[I].M]), EllipticThirdKindReferences[I].PiValue,
      IncompleteEllipticPi(EllipticThirdKindReferences[I].Phi,
      EllipticThirdKindReferences[I].N, EllipticThirdKindReferences[I].M));
end;

procedure TTestEllipticIntegrals.TestThirdKindLimitsAndDomains;
var
  NearEndpointValue: Double;
begin
  AssertEquals('Pi(phi,0,m)=F(phi,m)', IncompleteEllipticF(0.7, 0.5),
    IncompleteEllipticPi(0.7, 0.0, 0.5), 0.0);
  AssertEquals('Pi(0,n,m)=0', 0.0, IncompleteEllipticPi(0.0, 0.4, 0.6), 0.0);
  AssertEquals('Pi is odd in phi', -IncompleteEllipticPi(1.1, 0.4, 0.6),
    IncompleteEllipticPi(-1.1, 0.4, 0.6), 2E-14);
  AssertEquals('complete Pi uses endpoint amplitude',
    IncompleteEllipticPi(Pi / 2, 0.4, 0.6), CompleteEllipticPi(0.4, 0.6),
    0.0);
  AssertTrue('n above one rejected', IsNan(IncompleteEllipticPi(0.5, 1.01, 0.4)));
  AssertTrue('n below range rejected', IsNan(IncompleteEllipticPi(0.5, -16.01, 0.4)));
  AssertTrue('m above one rejected', IsNan(CompleteEllipticPi(0.2, 1.01)));
  AssertTrue('nonfinite n rejected', IsNan(IncompleteEllipticPi(0.5, Infinity, 0.4)));
  AssertTrue('n=1 endpoint diverges', IsInfinite(IncompleteEllipticPi(Pi / 2, 1.0, 0.4)));
  AssertTrue('m=1 complete diverges', IsInfinite(CompleteEllipticPi(0.4, 1.0)));
  NearEndpointValue := IncompleteEllipticPi(Pi / 2 - 1E-8, 1.0, 0.5);
  AssertTrue('n=1 near-endpoint result remains finite',
    not IsNan(NearEndpointValue) and not IsInfinite(NearEndpointValue) and
    (NearEndpointValue > 0.0));
  NearEndpointValue := CompleteEllipticPi(0.999, 0.99);
  AssertTrue('near-pole complete result remains finite',
    not IsNan(NearEndpointValue) and not IsInfinite(NearEndpointValue) and
    (NearEndpointValue > 0.0));
end;

initialization
  RegisterTest(TTestEllipticIntegrals);

end.
