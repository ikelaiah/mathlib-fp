unit TestSpecialFunctions;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, TypInfo, fpcunit, testregistry,
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

  TTestSpecialFunctionsIII = class(TTestCase)
  published
    procedure TestIndependentReferences;
    procedure TestDomainsAndPoles;
    procedure TestAiryWronskian;
  end;

implementation

type
  TBesselReference = record
    X, J0, J1, Y0, Y1: Double;
  end;

{$I BesselReference.inc}

type
  TSpecialFunctionKind = (sfDigamma, sfPolygamma, sfZeta, sfLambertW,
    sfJ, sfY, sfI, sfK, sfAi, sfBi, sfAiPrime, sfBiPrime);

  TSpecialFunctionReference = record
    Kind: TSpecialFunctionKind;
    Order: Integer;
    X, Expected: Double;
    InfinitySign: Integer;
  end;

{$I SpecialFunctionsIIIReference.inc}

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

procedure TTestSpecialFunctionsIII.TestIndependentReferences;
var
  R: TSpecialFunctionReference;
  Actual, AbsoluteBudget, RelativeBudget, Allowed: Double;
  LabelText: String;
begin
  for R in SpecialFunctionReferences do
  begin
    AbsoluteBudget := 2E-323;
    RelativeBudget := 2E-12;
    case R.Kind of
      sfDigamma: begin
        Actual := Digamma(R.X);
        AbsoluteBudget := 2E-14;
        RelativeBudget := 2E-13;
      end;
      sfPolygamma: Actual := Polygamma(R.Order, R.X);
      sfZeta: begin
        Actual := RiemannZeta(R.X);
        RelativeBudget := 2E-14;
      end;
      sfLambertW: begin
        Actual := LambertW(R.X, R.Order);
        RelativeBudget := 1E-13;
      end;
      sfJ: begin
        Actual := BesselJ(R.Order, R.X);
        if Abs(R.X) >= R.Order then AbsoluteBudget := 8E-13;
      end;
      sfY: begin
        Actual := BesselY(R.Order, R.X);
        AbsoluteBudget := 8E-13;
        RelativeBudget := 1E-11;
      end;
      sfI: Actual := ModifiedBesselI(R.Order, R.X);
      sfK: begin
        Actual := ModifiedBesselK(R.Order, R.X);
        { The established, unscaled K0/K1 Chebyshev bases lose relative
          precision as their magnitude decays toward the upper endpoint. }
        if (R.X > 2.0) and (R.X < 16.0) then
          RelativeBudget := 2E-10;
      end;
      sfAi: Actual := AiryAi(R.X);
      sfBi: Actual := AiryBi(R.X);
      sfAiPrime: Actual := AiryAiPrime(R.X);
      sfBiPrime: Actual := AiryBiPrime(R.X);
    end;
    if R.Kind >= sfAi then
    begin
      RelativeBudget := 5E-12;
      if R.X <= 0.0 then AbsoluteBudget := 2E-12;
    end;
    LabelText := Format('%s[%d](%.17g)',
      [GetEnumName(TypeInfo(TSpecialFunctionKind), Ord(R.Kind)), R.Order, R.X]);
    if R.InfinitySign <> 0 then
    begin
      AssertTrue(LabelText + ' expected signed infinity', IsInfinite(Actual) and
        ((Actual > 0) = (R.InfinitySign > 0)));
      Continue;
    end;
    AssertFalse(LabelText + ' expected a finite value',
      IsNan(Actual) or IsInfinite(Actual));
    Allowed := Max(AbsoluteBudget, RelativeBudget * Abs(R.Expected));
    AssertTrue(LabelText + Format(': expected %.17g, got %.17g (budget %.4g)',
      [R.Expected, Actual, Allowed]), Abs(Actual - R.Expected) <= Allowed);
  end;
end;

procedure TTestSpecialFunctionsIII.TestDomainsAndPoles;
const
  BranchPoint: Double = -0.36787944117144233;
  MinSubnormal: Double = 4.9406564584124654E-324;
var
  UnderflowValue: Double;
  UnderflowBits: QWord;
begin
  AssertTrue('negative digamma argument', IsNan(Digamma(-1.0)));
  AssertTrue('NaN digamma argument', IsNan(Digamma(NaN)));
  AssertTrue('digamma pole', IsInfinite(Digamma(0.0)) and (Digamma(0.0) < 0));
  AssertEquals('order zero delegates to digamma', Digamma(0.5), Polygamma(0, 0.5), 0.0);
  AssertTrue('signed trigamma pole', IsInfinite(Polygamma(1, 0.0)) and
    (Polygamma(1, 0.0) > 0));
  AssertTrue('signed second derivative pole', IsInfinite(Polygamma(2, 0.0)) and
    (Polygamma(2, 0.0) < 0));
  AssertTrue('negative polygamma order', IsNan(Polygamma(-1, 1.0)));
  AssertTrue('polygamma order bound', IsNan(Polygamma(17, 1.0)));
  AssertTrue('polygamma nonfinite', IsNan(Polygamma(1, Infinity)));
  AssertTrue('zeta pole', IsInfinite(RiemannZeta(1.0)) and (RiemannZeta(1.0) > 0));
  AssertTrue('zeta outside convergent domain', IsNan(RiemannZeta(0.5)));
  AssertTrue('nonfinite zeta argument', IsNan(RiemannZeta(Infinity)));
  AssertEquals('W0 branch point', -1.0, LambertW(BranchPoint, 0), 0.0);
  AssertEquals('W-1 branch point', -1.0, LambertW(BranchPoint, -1), 0.0);
  AssertTrue('below branch point', IsNan(LambertW(-0.36787944117144239, 0)));
  AssertTrue('unsupported Lambert branch', IsNan(LambertW(0.0, 1)));
  AssertTrue('W-1 positive argument', IsNan(LambertW(0.1, -1)));
  AssertTrue('W-1 zero limit', IsInfinite(LambertW(0.0, -1)) and
    (LambertW(0.0, -1) < 0));
  AssertTrue('W0 retains the smallest positive subnormal',
    LambertW(MinSubnormal, 0) = MinSubnormal);
  AssertTrue('unsupported Bessel order', IsNan(BesselJ(33, 1.0)));
  AssertTrue('Bessel argument limit', IsNan(BesselJ(2, 101.0)));
  AssertTrue('invalid Y argument', IsNan(BesselY(2, -1.0)));
  AssertTrue('invalid I order', IsNan(ModifiedBesselI(-1, 1.0)));
  AssertTrue('invalid K argument', IsNan(ModifiedBesselK(2, -1.0)));
  AssertTrue('Y pole', IsInfinite(BesselY(3, 0.0)) and (BesselY(3, 0.0) < 0));
  AssertTrue('K pole', IsInfinite(ModifiedBesselK(3, 0.0)) and
    (ModifiedBesselK(3, 0.0) > 0));
  AssertEquals('J2 underflows at a tiny positive argument', 0.0, BesselJ(2, 1E-200), 0.0);
  AssertTrue('Airy domain limit', IsNan(AiryAi(-100.1)));
  AssertTrue('Airy argument must be finite', IsNan(AiryBiPrime(Infinity)));
  UnderflowValue := AiryAiPrime(120.0);
  Move(UnderflowValue, UnderflowBits, SizeOf(UnderflowBits));
  AssertTrue('Airy underflow preserves derivative sign', UnderflowBits = QWord(1) shl 63);
end;

procedure TTestSpecialFunctionsIII.TestAiryWronskian;
const
  Points: array[0..7] of Double = (-100.0, -12.0, -10.25, -1.0, 0.0, 0.5, 12.0, 50.0);
var
  X: Double;
begin
  for X in Points do
    AssertEquals(Format('Airy Wronskian at %.17g', [X]), 1.0 / Pi,
      AiryAi(X) * AiryBiPrime(X) - AiryAiPrime(X) * AiryBi(X), 8E-13);
end;

initialization
  RegisterTest(TTestBessel);
  RegisterTest(TTestSpecialFunctionsIII);

end.
