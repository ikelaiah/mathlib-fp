program LegacySpectralBaseline;

{ Compile this source against the frozen v2.4.0 src tree with FPC 3.2.2
  and -O3. It records equivalent allocating FFT calls plus legacy STFT work. }

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math, Windows,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices, EngineeringLib.DSP;

function ReadCounter: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function ElapsedMilliseconds(const StartCounter, EndCounter: Int64): Double;
var
  Frequency: Int64;
begin
  QueryPerformanceFrequency(Frequency);
  Result := 1000.0 * (EndCounter - StartCounter) / Frequency;
end;

procedure BenchmarkFFT(const N, WarmIterations: SizeInt);
var
  Input, Output: TComplexArray;
  I, Iteration: SizeInt;
  Started, Finished: Int64;
  Checksum, Elapsed: Double;
begin
  SetLength(Input, N);
  for I := 0 to N - 1 do
    Input[I] := TComplex.Create(Sin(0.013 * I) + 0.25 * Cos(0.031 * I),
      Cos(0.017 * I));
  Output := TDSPKit.Transform(Input);
  Started := ReadCounter;
  for Iteration := 1 to WarmIterations do
    Output := TDSPKit.Transform(Input);
  Finished := ReadCounter;
  Elapsed := ElapsedMilliseconds(Started, Finished);
  Checksum := Output[N div 2].Re + Output[N - 1].Im;
  Writeln('BASELINE|id=fft-allocating-n', N,
    '|release=2.4.0|compiler=fpc-3.2.2|flags=-O3|shape=', N,
    '|warm_iterations=', WarmIterations,
    '|warm_ms=', Elapsed:0:6,
    '|checksum=', Checksum:0:12,
    '|setup=prepared_input_allocating_transform');
end;

procedure BenchmarkLegacySTFT(const FrameLength, HopLength,
  WarmIterations: SizeInt);
const
  SampleCount = 65536;
var
  Input: TDoubleArray;
  Output: IDenseComplexMatrix;
  I, Iteration: SizeInt;
  Started, Finished: Int64;
  Checksum, Elapsed: Double;
begin
  SetLength(Input, SampleCount);
  for I := 0 to SampleCount - 1 do
    Input[I] := Sin(0.0013 * I) + 0.25 * Cos(0.0187 * I);
  Output := TDSPKit.ShortTimeFourierTransform(Input, FrameLength, HopLength);
  Started := ReadCounter;
  for Iteration := 1 to WarmIterations do
    Output := TDSPKit.ShortTimeFourierTransform(Input, FrameLength, HopLength);
  Finished := ReadCounter;
  Elapsed := ElapsedMilliseconds(Started, Finished);
  Checksum := Output[Output.Rows div 2, 5].Re +
    Output[Output.Rows div 2, FrameLength - 5].Re;
  Writeln('BASELINE|id=legacy-stft-n', FrameLength, '-h', HopLength,
    '|release=2.4.0|compiler=fpc-3.2.2|flags=-O3|shape=', SampleCount, '_',
    FrameLength, '_', HopLength,
    '|warm_iterations=', WarmIterations,
    '|warm_ms=', Elapsed:0:6,
    '|checksum=', Checksum:0:12,
    '|output_shape=', Output.Rows, 'x', Output.Cols,
    '|setup=prepared_input_allocating_complete_frames');
end;

begin
  DefaultFormatSettings.DecimalSeparator := '.';
  BenchmarkFFT(64, 5000);
  BenchmarkFFT(4096, 20);
  BenchmarkFFT(65536, 5);
  BenchmarkFFT(1009, 50);
  BenchmarkFFT(10007, 10);
  BenchmarkLegacySTFT(256, 128, 3);
  BenchmarkLegacySTFT(255, 85, 3);
end.
