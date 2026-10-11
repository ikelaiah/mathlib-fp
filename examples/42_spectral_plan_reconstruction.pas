program spectral_plan_reconstruction;

{ Reuse a prepared STFT plan, edit a conjugate-bin pair, then synthesize the
  complete padded signal and report both round-trip and edit residuals. }

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices,
  EngineeringLib.Signal, EngineeringLib.DSP;

const
  SampleCount = 4096;
  FrameLength = 256;
  HopLength = 128;
  EditedBin = 5;

var
  Plan: TSTFTPlan;
  Signal, RoundTrip, EditedSignal: TDoubleArray;
  Spectrum: IDenseComplexMatrix;
  I, Frame, RepeatIndex: SizeInt;
  MaximumSignal, MaximumResidual, Difference, DifferenceSquares: Double;
begin
  SetLength(Signal, SampleCount);
  for I := 0 to SampleCount - 1 do
    Signal[I] := Sin(2.0 * Pi * 5.0 * I / FrameLength) +
      0.4 * Cos(2.0 * Pi * 11.0 * I / FrameLength) +
      0.15 * Sin(2.0 * Pi * 37.0 * I / SampleCount);

  Plan := TSTFTPlan.Create(SampleCount, FrameLength, HopLength, wtHann);
  try
    Spectrum := TDenseComplexMatrix.Zeros(Plan.FrameCount, FrameLength);
    SetLength(RoundTrip, SampleCount);
    SetLength(EditedSignal, SampleCount);

    { Reuse the same plan and pre-sized matrix for repeated analysis calls. }
    for RepeatIndex := 1 to 3 do
      Plan.AnalyzeInto(Signal, Spectrum);
    Plan.SynthesizeInto(Spectrum, RoundTrip);

    MaximumSignal := 0.0;
    MaximumResidual := 0.0;
    for I := 0 to SampleCount - 1 do
    begin
      MaximumSignal := Max(MaximumSignal, Abs(Signal[I]));
      MaximumResidual := Max(MaximumResidual,
        Abs(Signal[I] - RoundTrip[I]));
    end;
    if MaximumResidual > 5E-11 * Max(1.0, MaximumSignal) then
      raise EDSPError.Create('round-trip residual exceeded the example bound');

    { Apply a real gain to both members of one conjugate pair in every frame. }
    for Frame := 0 to Plan.FrameCount - 1 do
    begin
      Spectrum[Frame, EditedBin] :=
        Spectrum[Frame, EditedBin] * 0.75;
      Spectrum[Frame, FrameLength - EditedBin] :=
        Spectrum[Frame, FrameLength - EditedBin] * 0.75;
    end;
    Plan.SynthesizeInto(Spectrum, EditedSignal);

    DifferenceSquares := 0.0;
    for I := 0 to SampleCount - 1 do
    begin
      Difference := EditedSignal[I] - RoundTrip[I];
      DifferenceSquares := DifferenceSquares + Difference * Difference;
    end;
    Difference := Sqrt(DifferenceSquares / SampleCount);
    if Difference <= 1E-6 then
      raise EDSPError.Create('conjugate-bin edit did not change the signal');

    Writeln('STFT frames = ', Plan.FrameCount);
    Writeln('sample count = ', Plan.SampleCount);
    Writeln('maximum round-trip residual = ', MaximumResidual:0:12);
    Writeln('edited RMS change = ', Difference:0:12);
    Writeln('SPECTRAL_PLAN_EXAMPLE_OK');
  finally
    Plan.Free;
  end;
end.
