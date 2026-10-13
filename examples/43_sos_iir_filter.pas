program SOSIIRFilter;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  MathBase.SharedTypes,
  EngineeringLib.DSP;

const
  SampleRateHz = 1000.0;
  CutoffHz = 80.0;
  SampleCount = 1200;
  BlockSize = 128;
  MeasureStart = 200;
  MeasureCount = SampleCount - MeasureStart;

var
  Coefficients: TSOSCoefficients;
  Filter: TStreamingSOSFilter;
  Stability: TSOSStabilityDiagnostics;
  FrequencyResponse: TSOSFrequencyResponse;
  Input, Output, BlockOutput: TDoubleArray;
  Frequencies: TDoubleArray;
  StartIndex, Count, BlockCount, I: SizeInt;
  LowToneAmplitude, HighToneAmplitude, Angle: Double;

function ToneAmplitude(const Values: TDoubleArray; const FrequencyHz: Double):
  Double;
var
  Sample: SizeInt;
  SineSum, CosineSum, SampleAngle: Double;
begin
  SineSum := 0.0;
  CosineSum := 0.0;
  for Sample := MeasureStart to High(Values) do
  begin
    SampleAngle := 2.0 * Pi * FrequencyHz * Sample / SampleRateHz;
    SineSum := SineSum + Values[Sample] * Sin(SampleAngle);
    CosineSum := CosineSum + Values[Sample] * Cos(SampleAngle);
  end;
  Result := 2.0 * Sqrt(Sqr(SineSum) + Sqr(CosineSum)) / MeasureCount;
end;

begin
  Coefficients := TDSPKit.DesignButterworthSOS(irLowPass, 4,
    SampleRateHz, CutoffHz);
  Stability := TDSPKit.AnalyzeSOSStability(Coefficients);
  if not Stability.IsStable then
    raise Exception.Create('Designed SOS sections are not stable.');

  Frequencies := TDoubleArray.Create(0.0, CutoffHz, SampleRateHz * 0.5);
  FrequencyResponse := TDSPKit.EvaluateSOSResponse(Coefficients,
    SampleRateHz, Frequencies);
  if Abs(FrequencyResponse.Values[1].Magnitude - 1.0 / Sqrt(2.0)) > 1E-10 then
    raise Exception.Create('The Butterworth cutoff response is outside its reference.');

  SetLength(Input, SampleCount);
  SetLength(Output, SampleCount);
  for I := 0 to High(Input) do
  begin
    Angle := 2.0 * Pi * I / SampleRateHz;
    Input[I] := 0.7 * Sin(30.0 * Angle) + 0.3 * Sin(300.0 * Angle);
  end;

  Filter := TStreamingSOSFilter.Create(Coefficients);
  StartIndex := 0;
  BlockCount := 0;
  while StartIndex < SampleCount do
  begin
    Count := BlockSize;
    if Count > SampleCount - StartIndex then
      Count := SampleCount - StartIndex;
    BlockOutput := Filter.ProcessBlock(Copy(Input, StartIndex, Count));
    for I := 0 to Count - 1 do
      Output[StartIndex + I] := BlockOutput[I];
    Inc(StartIndex, Count);
    Inc(BlockCount);
  end;

  LowToneAmplitude := Abs(ToneAmplitude(Output, 30.0));
  HighToneAmplitude := Abs(ToneAmplitude(Output, 300.0));
  if Abs(LowToneAmplitude - 0.7) > 0.005 then
    raise Exception.Create('The passband tone was not preserved.');
  if HighToneAmplitude > 0.005 then
    raise Exception.Create('The stopband tone was not sufficiently attenuated.');

  Writeln('filter: Butterworth low-pass, sections = ', Length(Coefficients));
  Writeln('stability: stable, maximum pole radius = ',
    Stability.MaximumPoleRadius:0:6);
  Writeln('response: cutoff gain = ', FrequencyResponse.Values[1].Magnitude:0:6,
    ', Nyquist gain = ', FrequencyResponse.Values[2].Magnitude:0:6);
  Writeln('streaming: ', BlockCount, ' blocks, ', Filter.StateSize,
    ' state values');
  Writeln('tones: 30-Hz amplitude = ', LowToneAmplitude:0:6,
    ', 300-Hz amplitude = ', HighToneAmplitude:0:6);
  Writeln('workflow: success');
end.
