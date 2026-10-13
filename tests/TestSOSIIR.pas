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
    procedure TestStabilityRejectsEmptySections;
  end;

implementation

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

procedure TSOSIIRTest.TestStabilityRejectsEmptySections;
var
  Failed: Boolean;
begin
  Failed := False;
  try
    TDSPKit.AnalyzeSOSStability(nil);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('empty section list is rejected', Failed);
end;

initialization
  RegisterTest(TSOSIIRTest);

end.
