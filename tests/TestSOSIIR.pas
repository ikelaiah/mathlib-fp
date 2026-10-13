unit TestSOSIIR;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex,
  EngineeringLib.DSP;

type
  TSOSIIRTest = class(TTestCase)
  published
    procedure TestStabilityDiagnosticsForRealAndComplexPoles;
    procedure TestComplexFrequencyResponseAtReferenceFrequencies;
    procedure TestDesignedResponseMatchesHighPrecisionReference;
    procedure TestResponseValidationRejectsInvalidFrequenciesAndPoles;
    procedure TestStabilityRejectsEmptySections;
    procedure TestButterworthSOSDesignsAndCriticalEdges;
    procedure TestButterworthDesignRejectsInvalidRequests;
    procedure TestChebyshevIIndependentRippleAndPoleReferences;
    procedure TestChebyshevIAllFourResponses;
    procedure TestChebyshevIDesignRejectsInvalidRipple;
    procedure TestAllSupportedOrdersHaveStableEdgeResponses;
    procedure TestStreamingImpulseAndStepReferences;
    procedure TestStreamingStateChunkingCopyAndRestore;
    procedure TestStreamingFailureIsAtomicAndResettable;
  end;

implementation

{$I SOSIIRReference.inc}

procedure TSOSIIRTest.TestStabilityDiagnosticsForRealAndComplexPoles;
var
  Sections: TSOSCoefficients;
  Diagnostics: TSOSStabilityDiagnostics;
begin
  SetLength(Sections, 1);
  Sections[0].B0 := 1.0;
  Sections[0].B1 := 0.0;
  Sections[0].B2 := 0.0;
  Sections[0].A1 := 0.0;
  Sections[0].A2 := 0.25;
  Diagnostics := TDSPKit.AnalyzeSOSStability(Sections);
  AssertTrue('complex pole pair is strictly stable', Diagnostics.IsStable);
  AssertEquals('complex pole radius', 0.5,
    Diagnostics.MaximumPoleRadius, 1E-15);
  AssertEquals('complex pole margin', 0.5,
    Diagnostics.MinimumStabilityMargin, 1E-15);
  AssertEquals('stable result has no unstable section', -1,
    Diagnostics.FirstUnstableSection);

  Sections[0].A1 := -0.5;
  Sections[0].A2 := 0.0;
  Diagnostics := TDSPKit.AnalyzeSOSStability(Sections);
  AssertTrue('first-order real pole is strictly stable', Diagnostics.IsStable);
  AssertEquals('first-order pole radius', 0.5,
    Diagnostics.MaximumPoleRadius, 1E-15);

  Sections[0].A1 := 0.0;
  Sections[0].A2 := 1.21;
  Diagnostics := TDSPKit.AnalyzeSOSStability(Sections);
  AssertFalse('complex poles outside the unit circle are unstable',
    Diagnostics.IsStable);
  AssertEquals('first unstable section is reported', 0,
    Diagnostics.FirstUnstableSection);
  AssertEquals('unstable pole radius', 1.1,
    Diagnostics.MaximumPoleRadius, 1E-14);

  Sections[0].A1 := 0.0;
  Sections[0].A2 := 1.0;
  Diagnostics := TDSPKit.AnalyzeSOSStability(Sections);
  AssertFalse('unit-circle poles are not strictly stable', Diagnostics.IsStable);
  AssertEquals('unit-circle pole radius', 1.0,
    Diagnostics.MaximumPoleRadius, 0.0);
  AssertEquals('unit-circle stability margin is zero', 0.0,
    Diagnostics.MinimumStabilityMargin, 0.0);
end;

procedure TSOSIIRTest.TestComplexFrequencyResponseAtReferenceFrequencies;
var
  Sections: TSOSCoefficients;
  Frequencies: TDoubleArray;
  Response: TSOSFrequencyResponse;
begin
  SetLength(Sections, 1);
  Sections[0].B0 := 0.5;
  Sections[0].B1 := 0.5;
  Sections[0].B2 := 0.0;
  Sections[0].A1 := 0.0;
  Sections[0].A2 := 0.0;
  Frequencies := TDoubleArray.Create(0.0, 250.0, 500.0);

  Response := TDSPKit.EvaluateSOSResponse(Sections, 1000.0, Frequencies);
  AssertEquals('frequency count is retained', 3,
    Length(Response.FrequenciesHz));
  AssertEquals('DC response is unity', 1.0, Response.Values[0].Re, 1E-15);
  AssertEquals('DC response has no imaginary component', 0.0,
    Response.Values[0].Im, 1E-15);
  AssertEquals('quarter-rate real part', 0.5, Response.Values[1].Re, 1E-15);
  AssertEquals('quarter-rate imaginary part', -0.5,
    Response.Values[1].Im, 1E-15);
  AssertEquals('Nyquist response is zero', 0.0,
    Response.Values[2].Magnitude, 1E-15);

  Frequencies[1] := 1.0;
  AssertEquals('response owns the requested frequency values', 250.0,
    Response.FrequenciesHz[1], 0.0);
end;

procedure TSOSIIRTest.TestDesignedResponseMatchesHighPrecisionReference;
var
  Sections: TSOSCoefficients;
  Frequencies: TDoubleArray;
  Response: TSOSFrequencyResponse;
  I: SizeInt;
begin
  Sections := TDSPKit.DesignButterworthSOS(irLowPass, 2, 1000.0, 100.0);
  Frequencies := TDoubleArray.Create(0.0, 50.0, 100.0, 250.0, 500.0);
  Response := TDSPKit.EvaluateSOSResponse(Sections, 1000.0, Frequencies);
  for I := 0 to High(Frequencies) do
  begin
    AssertEquals(Format('high-precision response real part at %.0f Hz',
      [Frequencies[I]]),
      SOSButterworth2LowPassResponseReference[2 * I],
      Response.Values[I].Re, 2E-14);
    AssertEquals(Format('high-precision response imaginary part at %.0f Hz',
      [Frequencies[I]]),
      SOSButterworth2LowPassResponseReference[2 * I + 1],
      Response.Values[I].Im, 2E-14);
  end;
end;

procedure TSOSIIRTest.TestResponseValidationRejectsInvalidFrequenciesAndPoles;
var
  Sections: TSOSCoefficients;
  Failed: Boolean;
begin
  SetLength(Sections, 1);
  Sections[0].B0 := 1.0;
  Sections[0].B1 := 0.0;
  Sections[0].B2 := 0.0;
  Sections[0].A1 := 0.0;
  Sections[0].A2 := 0.0;
  Failed := False;
  try
    TDSPKit.EvaluateSOSResponse(Sections, 1000.0,
      TDoubleArray.Create(NaN));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('non-finite response frequency is rejected', Failed);

  Sections[0].A1 := -2.0;
  Sections[0].A2 := 1.0;
  Failed := False;
  try
    TDSPKit.EvaluateSOSResponse(Sections, 1000.0,
      TDoubleArray.Create(0.0));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('zero frequency-response denominator is rejected', Failed);
end;

procedure TSOSIIRTest.TestStabilityRejectsEmptySections;
var
  Sections: TSOSCoefficients;
  Failed: Boolean;
begin
  Failed := False;
  try
    TDSPKit.AnalyzeSOSStability(nil);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('empty section list is rejected', Failed);

  SetLength(Sections, 1);
  Sections[0].B0 := NaN;
  Failed := False;
  try
    TDSPKit.AnalyzeSOSStability(Sections);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('non-finite section coefficients are rejected', Failed);
end;

procedure TSOSIIRTest.TestButterworthSOSDesignsAndCriticalEdges;
var
  LowPass, HighPass, BandPass, BandStop: TSOSCoefficients;
  Legacy: TBiquadCoefficients;
  Frequencies: TDoubleArray;
  Response: TSOSFrequencyResponse;
  BandCenter: Double;
begin
  LowPass := TDSPKit.DesignButterworthSOS(irLowPass, 2, 1000.0, 100.0);
  Legacy := TDSPKit.DesignButterworthLowPass(0.1);
  AssertEquals('second-order low-pass is one section', 1, Length(LowPass));
  AssertEquals('low-pass B0 agrees with independent bilinear biquad',
    Legacy.B0, LowPass[0].B0, 2E-14);
  AssertEquals('low-pass B1 agrees with independent bilinear biquad',
    Legacy.B1, LowPass[0].B1, 2E-14);
  AssertEquals('low-pass B2 agrees with independent bilinear biquad',
    Legacy.B2, LowPass[0].B2, 2E-14);
  AssertEquals('low-pass A1 agrees with independent bilinear biquad',
    Legacy.A1, LowPass[0].A1, 2E-14);
  AssertEquals('low-pass A2 agrees with independent bilinear biquad',
    Legacy.A2, LowPass[0].A2, 2E-14);
  AssertEquals('Butterworth B0 matches the high-precision fixture',
    SOSButterworth2LowPassReference[0], LowPass[0].B0, 2E-15);
  AssertEquals('Butterworth B1 matches the high-precision fixture',
    SOSButterworth2LowPassReference[1], LowPass[0].B1, 2E-15);
  AssertEquals('Butterworth A1 matches the high-precision fixture',
    SOSButterworth2LowPassReference[3], LowPass[0].A1, 2E-15);
  AssertEquals('Butterworth A2 matches the high-precision fixture',
    SOSButterworth2LowPassReference[4], LowPass[0].A2, 2E-15);

  HighPass := TDSPKit.DesignButterworthSOS(irHighPass, 2, 1000.0, 100.0);
  BandPass := TDSPKit.DesignButterworthSOS(irBandPass, 2,
    1000.0, 100.0, 200.0);
  BandStop := TDSPKit.DesignButterworthSOS(irBandStop, 2,
    1000.0, 100.0, 200.0);
  AssertEquals('second-order high-pass is one section', 1, Length(HighPass));
  AssertEquals('second-order band-pass has two sections', 2,
    Length(BandPass));
  AssertEquals('second-order band-stop has two sections', 2,
    Length(BandStop));
  AssertTrue('designed low-pass sections are stable',
    TDSPKit.AnalyzeSOSStability(LowPass).IsStable);
  AssertTrue('designed high-pass sections are stable',
    TDSPKit.AnalyzeSOSStability(HighPass).IsStable);
  AssertTrue('designed band-pass sections are stable',
    TDSPKit.AnalyzeSOSStability(BandPass).IsStable);
  AssertTrue('designed band-stop sections are stable',
    TDSPKit.AnalyzeSOSStability(BandStop).IsStable);

  Frequencies := TDoubleArray.Create(0.0, 100.0, 200.0, 500.0);
  Response := TDSPKit.EvaluateSOSResponse(LowPass, 1000.0, Frequencies);
  AssertEquals('Butterworth low-pass has unit DC gain', 1.0,
    Response.Values[0].Magnitude, 2E-13);
  AssertEquals('Butterworth low-pass critical edge is minus three dB',
    1.0 / Sqrt(2.0), Response.Values[1].Magnitude, 2E-12);
  AssertTrue('low-pass suppresses Nyquist', Response.Values[3].Magnitude < 1E-8);

  Response := TDSPKit.EvaluateSOSResponse(HighPass, 1000.0, Frequencies);
  AssertEquals('Butterworth high-pass critical edge is minus three dB',
    1.0 / Sqrt(2.0), Response.Values[1].Magnitude, 2E-12);
  AssertEquals('Butterworth high-pass has unit Nyquist gain', 1.0,
    Response.Values[3].Magnitude, 2E-13);

  Response := TDSPKit.EvaluateSOSResponse(BandPass, 1000.0,
    TDoubleArray.Create(100.0, 200.0));
  AssertEquals('band-pass lower critical edge', 1.0 / Sqrt(2.0),
    Response.Values[0].Magnitude, 2E-12);
  AssertEquals('band-pass upper critical edge', 1.0 / Sqrt(2.0),
    Response.Values[1].Magnitude, 2E-12);
  BandCenter := 1000.0 * ArcTan(Sqrt(Tan(Pi * 100.0 / 1000.0) *
    Tan(Pi * 200.0 / 1000.0))) / Pi;
  Response := TDSPKit.EvaluateSOSResponse(BandPass, 1000.0,
    TDoubleArray.Create(BandCenter));
  AssertEquals('band-pass warped center has unit gain', 1.0,
    Response.Values[0].Magnitude, 3E-12);

  Response := TDSPKit.EvaluateSOSResponse(BandStop, 1000.0,
    TDoubleArray.Create(0.0, 100.0, 200.0, BandCenter, 500.0));
  AssertEquals('band-stop retains unit DC gain', 1.0,
    Response.Values[0].Magnitude, 2E-12);
  AssertEquals('band-stop lower critical edge', 1.0 / Sqrt(2.0),
    Response.Values[1].Magnitude, 3E-12);
  AssertEquals('band-stop upper critical edge', 1.0 / Sqrt(2.0),
    Response.Values[2].Magnitude, 3E-12);
  AssertTrue('band-stop center is rejected',
    Response.Values[3].Magnitude < 1E-12);
  AssertEquals('band-stop retains unit Nyquist gain', 1.0,
    Response.Values[4].Magnitude, 2E-12);
end;

procedure TSOSIIRTest.TestButterworthDesignRejectsInvalidRequests;
var
  Failed: Boolean;
begin
  Failed := False;
  try
    TDSPKit.DesignButterworthSOS(irBandPass, 2, 1000.0, 100.0);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('single edge cannot design a band response', Failed);

  Failed := False;
  try
    TDSPKit.DesignButterworthSOS(irLowPass, 13, 1000.0, 100.0);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('prototype order above the bounded maximum is rejected', Failed);

  Failed := False;
  try
    TDSPKit.DesignButterworthSOS(irBandStop, 2, 1000.0, 200.0, 100.0);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('reversed band edges are rejected', Failed);
end;

procedure TSOSIIRTest.TestChebyshevIIndependentRippleAndPoleReferences;
const
  SampleRate = 1000.0;
  Cutoff = 100.0;
  RippleDb = 1.0;
var
  Coefficients: TSOSCoefficients;
  Response: TSOSFrequencyResponse;
  Epsilon, WarpedCutoff, AnalogPole, DigitalPole, ExpectedB0,
    ExpectedA1, EdgeGain, PeakFrequency: Double;
begin
  Epsilon := Sqrt(Exp(RippleDb * Ln(10.0) / 10.0) - 1.0);
  WarpedCutoff := Tan(Pi * Cutoff / SampleRate);
  AnalogPole := WarpedCutoff / Epsilon;
  DigitalPole := (1.0 - AnalogPole) / (1.0 + AnalogPole);
  ExpectedA1 := -DigitalPole;
  ExpectedB0 := (1.0 + ExpectedA1) * 0.5;
  Coefficients := TDSPKit.DesignChebyshevISOS(irLowPass, 1,
    SampleRate, Cutoff, RippleDb);
  AssertEquals('first-order Chebyshev coefficient B0', ExpectedB0,
    Coefficients[0].B0, 2E-13);
  AssertEquals('first-order Chebyshev coefficient B1', ExpectedB0,
    Coefficients[0].B1, 2E-13);
  AssertEquals('first-order Chebyshev coefficient A1', ExpectedA1,
    Coefficients[0].A1, 2E-13);
  AssertEquals('first-order Chebyshev coefficient fixture B0',
    SOSChebyshev1LowPassReference[0], Coefficients[0].B0, 2E-15);
  AssertEquals('first-order Chebyshev coefficient fixture A1',
    SOSChebyshev1LowPassReference[3], Coefficients[0].A1, 2E-15);
  AssertEquals('first-order section has no z^-2 term', 0.0,
    Coefficients[0].A2, 0.0);

  EdgeGain := Exp(-RippleDb * Ln(10.0) / 20.0);
  PeakFrequency := SampleRate * ArcTan(WarpedCutoff / Sqrt(2.0)) / Pi;
  Response := TDSPKit.EvaluateSOSResponse(Coefficients, SampleRate,
    TDoubleArray.Create(0.0, Cutoff, PeakFrequency));
  AssertEquals('odd Chebyshev order has unity at DC', 1.0,
    Response.Values[0].Magnitude, 3E-13);
  AssertEquals('odd Chebyshev order reaches requested edge ripple', EdgeGain,
    Response.Values[1].Magnitude, 3E-12);
  AssertEquals('first-order Chebyshev response is finite in the passband',
    1.0 / Sqrt(1.0 + Sqr(Epsilon) * 0.5),
    Response.Values[2].Magnitude, 3E-12);

  Coefficients := TDSPKit.DesignChebyshevISOS(irLowPass, 2,
    SampleRate, Cutoff, RippleDb);
  Response := TDSPKit.EvaluateSOSResponse(Coefficients, SampleRate,
    TDoubleArray.Create(0.0, Cutoff,
      SampleRate * ArcTan(WarpedCutoff / Sqrt(2.0)) / Pi));
  AssertEquals('even Chebyshev order has specified ripple at DC', EdgeGain,
    Response.Values[0].Magnitude, 3E-12);
  AssertEquals('even Chebyshev order has specified ripple at cutoff', EdgeGain,
    Response.Values[1].Magnitude, 3E-12);
  AssertEquals('even Chebyshev passband ripple peak reaches unity', 1.0,
    Response.Values[2].Magnitude, 4E-12);

  AssertEquals('second-order Chebyshev high-precision fixture B0',
    SOSChebyshev2LowPassReference[0], Coefficients[0].B0, 2E-15);
  AssertEquals('second-order Chebyshev high-precision fixture B1',
    SOSChebyshev2LowPassReference[1], Coefficients[0].B1, 2E-15);
  AssertEquals('second-order Chebyshev high-precision fixture A1',
    SOSChebyshev2LowPassReference[3], Coefficients[0].A1, 2E-15);
  AssertEquals('second-order Chebyshev high-precision fixture A2',
    SOSChebyshev2LowPassReference[4], Coefficients[0].A2, 2E-15);
end;

procedure TSOSIIRTest.TestChebyshevIAllFourResponses;
const
  SampleRate = 2000.0;
  LowCutoff = 150.0;
  HighCutoff = 420.0;
  RippleDb = 0.75;
var
  LowPass, HighPass, BandPass, BandStop: TSOSCoefficients;
  Response: TSOSFrequencyResponse;
  EdgeGain, Center: Double;
begin
  EdgeGain := Exp(-RippleDb * Ln(10.0) / 20.0);
  LowPass := TDSPKit.DesignChebyshevISOS(irLowPass, 3, SampleRate,
    LowCutoff, RippleDb);
  HighPass := TDSPKit.DesignChebyshevISOS(irHighPass, 3, SampleRate,
    LowCutoff, RippleDb);
  BandPass := TDSPKit.DesignChebyshevISOS(irBandPass, 2, SampleRate,
    LowCutoff, HighCutoff, RippleDb);
  BandStop := TDSPKit.DesignChebyshevISOS(irBandStop, 2, SampleRate,
    LowCutoff, HighCutoff, RippleDb);
  AssertTrue('Chebyshev low-pass is stable',
    TDSPKit.AnalyzeSOSStability(LowPass).IsStable);
  AssertTrue('Chebyshev high-pass is stable',
    TDSPKit.AnalyzeSOSStability(HighPass).IsStable);
  AssertTrue('Chebyshev band-pass is stable',
    TDSPKit.AnalyzeSOSStability(BandPass).IsStable);
  AssertTrue('Chebyshev band-stop is stable',
    TDSPKit.AnalyzeSOSStability(BandStop).IsStable);

  Response := TDSPKit.EvaluateSOSResponse(LowPass, SampleRate,
    TDoubleArray.Create(0.0, LowCutoff));
  AssertEquals('odd low-pass is unity at DC', 1.0,
    Response.Values[0].Magnitude, 4E-12);
  AssertEquals('low-pass cutoff is at the specified ripple edge', EdgeGain,
    Response.Values[1].Magnitude, 6E-12);

  Response := TDSPKit.EvaluateSOSResponse(HighPass, SampleRate,
    TDoubleArray.Create(LowCutoff, SampleRate * 0.5));
  AssertEquals('high-pass cutoff is at the specified ripple edge', EdgeGain,
    Response.Values[0].Magnitude, 6E-12);
  AssertEquals('odd high-pass has unity at Nyquist', 1.0,
    Response.Values[1].Magnitude, 4E-12);

  Center := SampleRate * ArcTan(Sqrt(Tan(Pi * LowCutoff / SampleRate) *
    Tan(Pi * HighCutoff / SampleRate))) / Pi;
  Response := TDSPKit.EvaluateSOSResponse(BandPass, SampleRate,
    TDoubleArray.Create(LowCutoff, HighCutoff, Center));
  AssertEquals('band-pass lower edge uses specified ripple', EdgeGain,
    Response.Values[0].Magnitude, 7E-12);
  AssertEquals('band-pass upper edge uses specified ripple', EdgeGain,
    Response.Values[1].Magnitude, 7E-12);
  AssertEquals('even band-pass center has specified ripple minimum', EdgeGain,
    Response.Values[2].Magnitude, 7E-12);

  Response := TDSPKit.EvaluateSOSResponse(BandStop, SampleRate,
    TDoubleArray.Create(0.0, LowCutoff, HighCutoff, Center,
      SampleRate * 0.5));
  AssertEquals('even band-stop DC has specified ripple minimum', EdgeGain,
    Response.Values[0].Magnitude, 7E-12);
  AssertEquals('band-stop lower edge uses specified ripple', EdgeGain,
    Response.Values[1].Magnitude, 7E-12);
  AssertEquals('band-stop upper edge uses specified ripple', EdgeGain,
    Response.Values[2].Magnitude, 7E-12);
  AssertTrue('band-stop center is rejected',
    Response.Values[3].Magnitude < 1E-10);
  AssertEquals('even band-stop high-frequency passband has specified ripple',
    EdgeGain, Response.Values[4].Magnitude, 7E-12);
end;

procedure TSOSIIRTest.TestChebyshevIDesignRejectsInvalidRipple;
var
  Failed: Boolean;
begin
  Failed := False;
  try
    TDSPKit.DesignChebyshevISOS(irLowPass, 2, 1000.0, 100.0, 0.0);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('zero ripple is rejected', Failed);

  Failed := False;
  try
    TDSPKit.DesignChebyshevISOS(irLowPass, 2, 1000.0, 100.0, 12.01);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('ripple above the bounded maximum is rejected', Failed);
end;

procedure TSOSIIRTest.TestAllSupportedOrdersHaveStableEdgeResponses;
const
  SampleRate = 2000.0;
  LowCutoff = 125.0;
  LowBandEdge = 100.0;
  HighBandEdge = 400.0;
  RippleDb = 0.5;
var
  ResponseType: TIIRResponse;
  Order, FamilyIndex: SizeInt;
  Coefficients: TSOSCoefficients;
  Diagnostics: TSOSStabilityDiagnostics;
  Response: TSOSFrequencyResponse;
  ExpectedEdgeGain: Double;
begin
  for FamilyIndex := 0 to 1 do
    for ResponseType := Low(TIIRResponse) to High(TIIRResponse) do
      for Order := 1 to 12 do
      begin
        if ResponseType in [irLowPass, irHighPass] then
          if FamilyIndex = 0 then
            Coefficients := TDSPKit.DesignButterworthSOS(ResponseType, Order,
              SampleRate, LowCutoff)
          else
            Coefficients := TDSPKit.DesignChebyshevISOS(ResponseType, Order,
              SampleRate, LowCutoff, RippleDb)
        else if FamilyIndex = 0 then
          Coefficients := TDSPKit.DesignButterworthSOS(ResponseType, Order,
            SampleRate, LowBandEdge, HighBandEdge)
        else
          Coefficients := TDSPKit.DesignChebyshevISOS(ResponseType, Order,
            SampleRate, LowBandEdge, HighBandEdge, RippleDb);

        Diagnostics := TDSPKit.AnalyzeSOSStability(Coefficients);
        AssertTrue(Format('family %d type %d order %d is stable',
          [FamilyIndex, Ord(ResponseType), Order]), Diagnostics.IsStable);
        AssertTrue(Format('family %d type %d order %d has positive margin',
          [FamilyIndex, Ord(ResponseType), Order]),
          Diagnostics.MinimumStabilityMargin > 0.0);
        if FamilyIndex = 0 then
          ExpectedEdgeGain := 1.0 / Sqrt(2.0)
        else
          ExpectedEdgeGain := Exp(-RippleDb * Ln(10.0) / 20.0);
        if ResponseType in [irLowPass, irHighPass] then
          Response := TDSPKit.EvaluateSOSResponse(Coefficients, SampleRate,
            TDoubleArray.Create(LowCutoff))
        else
          Response := TDSPKit.EvaluateSOSResponse(Coefficients, SampleRate,
            TDoubleArray.Create(LowBandEdge, HighBandEdge));
        AssertEquals(Format('family %d type %d order %d lower edge',
          [FamilyIndex, Ord(ResponseType), Order]), ExpectedEdgeGain,
          Response.Values[0].Magnitude, 2E-9);
        if ResponseType in [irBandPass, irBandStop] then
          AssertEquals(Format('family %d type %d order %d upper edge',
            [FamilyIndex, Ord(ResponseType), Order]), ExpectedEdgeGain,
            Response.Values[1].Magnitude, 2E-9);
      end;
end;

procedure TSOSIIRTest.TestStreamingStateChunkingCopyAndRestore;
var
  Sections: TSOSCoefficients;
  Input, WholeOutput, FirstOutput, SecondOutput, RestoredOutput,
    Snapshot, StateBeforeCopy, StateAfterCopy, EmptyOutput: TDoubleArray;
  WholeFilter, ChunkedFilter, RestoredFilter, CopiedFilter:
    TStreamingSOSFilter;
  I: SizeInt;
begin
  Sections := TDSPKit.DesignButterworthSOS(irBandPass, 4,
    1000.0, 70.0, 230.0);
  SetLength(Input, 64);
  for I := 0 to High(Input) do
    Input[I] := Sin(0.19 * I) + 0.25 * Cos(0.41 * I);

  WholeFilter := TStreamingSOSFilter.Create(Sections);
  WholeOutput := WholeFilter.ProcessBlock(Input);
  ChunkedFilter := TStreamingSOSFilter.Create(Sections);
  FirstOutput := ChunkedFilter.ProcessBlock(Copy(Input, 0, 23));
  Snapshot := ChunkedFilter.State;
  AssertEquals('two state values are retained per section',
    2 * Length(Sections), ChunkedFilter.StateSize);
  AssertEquals('section count is reported', Length(Sections),
    ChunkedFilter.SectionCount);
  AssertEquals('state snapshot is independently allocated',
    ChunkedFilter.StateSize, Length(Snapshot));

  StateBeforeCopy := ChunkedFilter.State;
  EmptyOutput := ChunkedFilter.ProcessBlock(nil);
  StateAfterCopy := ChunkedFilter.State;
  AssertEquals('empty block returns empty output', 0, Length(EmptyOutput));
  for I := 0 to High(StateBeforeCopy) do
    AssertEquals('empty block preserves streaming state', StateBeforeCopy[I],
      StateAfterCopy[I], 0.0);

  RestoredFilter := TStreamingSOSFilter.Create(Sections);
  RestoredFilter.RestoreState(Snapshot);
  SecondOutput := ChunkedFilter.ProcessBlock(Copy(Input, 23,
    Length(Input) - 23));
  RestoredOutput := RestoredFilter.ProcessBlock(Copy(Input, 23,
    Length(Input) - 23));
  for I := 0 to High(FirstOutput) do
    AssertEquals('first chunk matches one-shot output', FirstOutput[I],
      WholeOutput[I], 1E-14);
  for I := 0 to High(SecondOutput) do
  begin
    AssertEquals('second chunk matches one-shot output', SecondOutput[I],
      WholeOutput[Length(FirstOutput) + I], 1E-14);
    AssertEquals('restored state resumes the same stream', SecondOutput[I],
      RestoredOutput[I], 1E-14);
  end;

  CopiedFilter := ChunkedFilter;
  StateBeforeCopy := ChunkedFilter.State;
  CopiedFilter.ProcessBlock(TDoubleArray.Create(1.0, -0.5, 0.25));
  StateAfterCopy := ChunkedFilter.State;
  for I := 0 to High(StateBeforeCopy) do
    AssertEquals('copied record has independent future state',
      StateBeforeCopy[I], StateAfterCopy[I], 0.0);

  Snapshot[0] := Snapshot[0] + 1.0;
  AssertTrue('state accessor returns a copy',
    Abs(ChunkedFilter.State[0] - Snapshot[0]) > 0.5);
  Sections[0].B0 := 99.0;
  AssertTrue('filter owns a coefficient snapshot',
    Abs(ChunkedFilter.Coefficients[0].B0 - Sections[0].B0) > 1.0);
end;

procedure TSOSIIRTest.TestStreamingImpulseAndStepReferences;
var
  Coefficients: TSOSCoefficients;
  Filter: TStreamingSOSFilter;
  Input, Output: TDoubleArray;
  PreviousInput, PreviousOutput, Expected: Double;
  I: SizeInt;
begin
  SetLength(Coefficients, 1);
  Coefficients[0].B0 := SOSChebyshev1LowPassReference[0];
  Coefficients[0].B1 := SOSChebyshev1LowPassReference[1];
  Coefficients[0].B2 := SOSChebyshev1LowPassReference[2];
  Coefficients[0].A1 := SOSChebyshev1LowPassReference[3];
  Coefficients[0].A2 := SOSChebyshev1LowPassReference[4];

  SetLength(Input, 8);
  Input[0] := 1.0;
  Filter := TStreamingSOSFilter.Create(Coefficients);
  Output := Filter.ProcessBlock(Input);
  PreviousInput := 0.0;
  PreviousOutput := 0.0;
  for I := 0 to High(Input) do
  begin
    Expected := Coefficients[0].B0 * Input[I] +
      Coefficients[0].B1 * PreviousInput -
      Coefficients[0].A1 * PreviousOutput;
    AssertEquals(Format('impulse response sample %d', [I]), Expected,
      Output[I], 2E-16);
    PreviousInput := Input[I];
    PreviousOutput := Expected;
  end;

  for I := 0 to High(Input) do Input[I] := 1.0;
  Filter.Reset;
  Output := Filter.ProcessBlock(Input);
  PreviousInput := 0.0;
  PreviousOutput := 0.0;
  for I := 0 to High(Input) do
  begin
    Expected := Coefficients[0].B0 * Input[I] +
      Coefficients[0].B1 * PreviousInput -
      Coefficients[0].A1 * PreviousOutput;
    AssertEquals(Format('step response sample %d', [I]), Expected,
      Output[I], 2E-16);
    PreviousInput := Input[I];
    PreviousOutput := Expected;
  end;
end;

procedure TSOSIIRTest.TestStreamingFailureIsAtomicAndResettable;
var
  Coefficients: TSOSCoefficients;
  Filter, FreshFilter: TStreamingSOSFilter;
  BeforeState, AfterState, Output: TDoubleArray;
  Failed: Boolean;
  I: SizeInt;
begin
  SetLength(Coefficients, 1);
  Coefficients[0].B0 := 2.0;
  Coefficients[0].B1 := 1.0;
  Coefficients[0].B2 := 0.5;
  Coefficients[0].A1 := 0.0;
  Coefficients[0].A2 := 0.0;
  Filter := TStreamingSOSFilter.Create(Coefficients);
  Filter.ProcessBlock(TDoubleArray.Create(1.0));
  BeforeState := Filter.State;

  Failed := False;
  try
    Filter.ProcessBlock(TDoubleArray.Create(1.0, MaxDouble));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('late arithmetic overflow is rejected', Failed);
  AfterState := Filter.State;
  for I := 0 to High(BeforeState) do
    AssertEquals('failed block leaves all state unchanged', BeforeState[I],
      AfterState[I], 0.0);

  Failed := False;
  try
    Filter.ProcessBlock(TDoubleArray.Create(1.0, NaN));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('non-finite block is rejected', Failed);
  AfterState := Filter.State;
  for I := 0 to High(BeforeState) do
    AssertEquals('non-finite block leaves state unchanged', BeforeState[I],
      AfterState[I], 0.0);

  Failed := False;
  try
    Filter.RestoreState(TDoubleArray.Create(3.0));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('wrong state length is rejected', Failed);
  AfterState := Filter.State;
  for I := 0 to High(BeforeState) do
    AssertEquals('bad-length restore preserves state', BeforeState[I],
      AfterState[I], 0.0);
  Failed := False;
  try
    Filter.RestoreState(TDoubleArray.Create(NaN, 0.0));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('non-finite restored state is rejected', Failed);
  AfterState := Filter.State;
  for I := 0 to High(BeforeState) do
    AssertEquals('non-finite restore preserves state', BeforeState[I],
      AfterState[I], 0.0);

  Filter.Reset;
  FreshFilter := TStreamingSOSFilter.Create(Coefficients);
  AssertEquals('reset clears the first delay', 0.0, Filter.State[0], 0.0);
  AssertEquals('reset clears the second delay', 0.0, Filter.State[1], 0.0);
  Output := Filter.ProcessBlock(TDoubleArray.Create(1.0, 2.0, 3.0));
  AfterState := FreshFilter.ProcessBlock(TDoubleArray.Create(1.0, 2.0, 3.0));
  for I := 0 to High(Output) do
    AssertEquals('reset reproduces initial-rest processing', AfterState[I],
      Output[I], 0.0);

  Failed := False;
  Coefficients[0].A2 := 1.2;
  try
    TStreamingSOSFilter.Create(Coefficients);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('streaming construction rejects an unstable section', Failed);
end;

initialization
  RegisterTest(TSOSIIRTest);

end.
