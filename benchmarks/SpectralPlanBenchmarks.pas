unit SpectralPlanBenchmarks;

{$mode objfpc}{$H+}{$J-}

interface

procedure RunV250SpectralPlanBenchmarks;

implementation

uses
  SysUtils, Math,
  {$IFDEF WINDOWS}Windows,{$ELSE}BaseUnix,{$ENDIF}
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices,
  EngineeringLib.Signal, EngineeringLib.DSP;

var
  PreviousMemoryManager: TMemoryManager;
  CountAllocations: Boolean = False;
  AllocationCalls: QWord = 0;

function ReadBenchmarkCounter: Int64;
{$IFDEF WINDOWS}
var
  Counter: Int64;
begin
  QueryPerformanceCounter(Counter);
  Result := Counter;
end;
{$ELSE}
var
  CurrentTime: TTimeVal;
begin
  fpgettimeofday(@CurrentTime, nil);
  Result := Int64(CurrentTime.tv_sec) * 1000000 + CurrentTime.tv_usec;
end;
{$ENDIF}

function CounterDeltaMilliseconds(const Delta: Int64): Double;
{$IFDEF WINDOWS}
var
  Frequency: Int64;
begin
  QueryPerformanceFrequency(Frequency);
  Result := 1000.0 * Delta / Frequency;
end;
{$ELSE}
begin
  Result := Delta / 1000.0;
end;
{$ENDIF}

function CountedGetMem(Size: PtrUInt): Pointer;
begin
  if CountAllocations then Inc(AllocationCalls);
  Result := PreviousMemoryManager.Getmem(Size);
end;

function CountedAllocMem(Size: PtrUInt): Pointer;
begin
  if CountAllocations then Inc(AllocationCalls);
  Result := PreviousMemoryManager.AllocMem(Size);
end;

function CountedReAllocMem(var P: Pointer; Size: PtrUInt): Pointer;
begin
  if CountAllocations then Inc(AllocationCalls);
  Result := PreviousMemoryManager.ReAllocMem(P, Size);
end;

procedure BeginAllocationCount;
var
  Manager: TMemoryManager;
begin
  GetMemoryManager(PreviousMemoryManager);
  Manager := PreviousMemoryManager;
  Manager.Getmem := @CountedGetMem;
  Manager.AllocMem := @CountedAllocMem;
  Manager.ReAllocMem := @CountedReAllocMem;
  AllocationCalls := 0;
  SetMemoryManager(Manager);
  CountAllocations := True;
end;

procedure EndAllocationCount;
begin
  CountAllocations := False;
  SetMemoryManager(PreviousMemoryManager);
end;

procedure WriteSpectralRow(const Identifier, Scale, ScalarKind, Shape,
  Setup: string; const ColdMilliseconds, WarmMilliseconds: Double;
  const WarmIterations: SizeInt; const Allocations: QWord;
  const RetainedBytes, WorkingElements, DenseShapeElements: QWord;
  const Checksum, Tolerance: Double);
begin
  Writeln('PERF|id=', Identifier,
    '|domain=spectral_plans',
    '|scale=', Scale,
    '|scalar=', ScalarKind,
    '|shape=', Shape,
    '|cold_ms=', ColdMilliseconds:0:6,
    '|warm_ms=', WarmMilliseconds:0:6,
    '|warm_iterations=', WarmIterations,
    '|allocations=', Allocations,
    '|retained_bytes=', RetainedBytes,
    '|working_elements=', WorkingElements,
    '|dense_shape_elements=', DenseShapeElements,
    '|checksum=', Checksum:0:12,
    '|tolerance=', Tolerance,
    '|setup=', Setup);
end;

procedure FillComplexInput(var Input: TComplexArray);
var
  I: SizeInt;
begin
  for I := 0 to High(Input) do
    Input[I] := TComplex.Create(Sin(0.013 * I) + 0.25 * Cos(0.031 * I),
      Cos(0.017 * I));
end;

function FFTConstructionMilliseconds(const N, Repetitions: SizeInt): Double;
var
  Plan: TFFTPlan;
  I: SizeInt;
  Started: Int64;
begin
  Started := ReadBenchmarkCounter;
  for I := 1 to Repetitions do
  begin
    Plan := TFFTPlan.Create(N);
    Plan.Free;
  end;
  Result := CounterDeltaMilliseconds(ReadBenchmarkCounter - Started);
end;

procedure BenchmarkFFTPlan(const N, WarmIterations,
  ConstructionRepetitions: SizeInt; const Scale: string);
var
  Plan: TFFTPlan;
  Input, Destination, AllocatedResult: TComplexArray;
  ColdMilliseconds, WarmMilliseconds: Double;
  Started: Int64;
  I: SizeInt;
  Checksum, Tolerance: Double;
  RetainedBytes, WorkingElements: QWord;
  Setup: string;
begin
  SetLength(Input, N);
  SetLength(Destination, N);
  FillComplexInput(Input);
  ColdMilliseconds := FFTConstructionMilliseconds(N,
    ConstructionRepetitions);
  Plan := TFFTPlan.Create(N);
  try
    RetainedBytes := Plan.RetainedBytes;
    WorkingElements := Plan.WorkspaceElements;
    Plan.ExecuteInto(Input, Destination);
    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        Plan.ExecuteInto(Input, Destination);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := Destination[N div 2].Re + Destination[N - 1].Im;
    Tolerance := 5E-11;
    Setup := 'cold_create_destroy_batch_' + IntToStr(ConstructionRepetitions) +
      '_then_reused_destination';
    WriteSpectralRow('spectral-fft-into-n' + IntToStr(N), Scale,
      'double_complex', IntToStr(N), Setup,
      ColdMilliseconds, WarmMilliseconds, WarmIterations, AllocationCalls,
      RetainedBytes, WorkingElements, 0, Checksum, Tolerance);

    AllocatedResult := nil;
    Plan.Execute(Input);
    AllocatedResult := nil;
    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        AllocatedResult := Plan.Execute(Input);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := AllocatedResult[N div 2].Re +
      AllocatedResult[N - 1].Im;
    WriteSpectralRow('spectral-fft-allocating-n' + IntToStr(N), Scale,
      'double_complex', IntToStr(N),
      'cold_create_destroy_batch_' + IntToStr(ConstructionRepetitions) +
        '_then_allocating_result',
      ColdMilliseconds, WarmMilliseconds, WarmIterations, AllocationCalls,
      RetainedBytes, WorkingElements, 0, Checksum, Tolerance);
  finally
    Plan.Free;
  end;
end;

procedure FillRealInput(var Input: TDoubleArray);
var
  I: SizeInt;
begin
  for I := 0 to High(Input) do
    Input[I] := Sin(0.0013 * I) + 0.25 * Cos(0.0187 * I);
end;

function STFTConstructionMilliseconds(const SampleCount, FrameLength,
  HopLength, Repetitions: SizeInt): Double;
var
  Plan: TSTFTPlan;
  I: SizeInt;
  Started: Int64;
begin
  Started := ReadBenchmarkCounter;
  for I := 1 to Repetitions do
  begin
    Plan := TSTFTPlan.Create(SampleCount, FrameLength, HopLength, wtHann);
    Plan.Free;
  end;
  Result := CounterDeltaMilliseconds(ReadBenchmarkCounter - Started);
end;

procedure BenchmarkSTFTPlan(const FrameLength, HopLength,
  WarmIterations, ConstructionRepetitions: SizeInt);
const
  SampleCount = 65536;
var
  Plan: TSTFTPlan;
  Input: TDoubleArray;
  Synthesized, AllocatedSamples: TDoubleArray;
  Spectrum, SpectrumDestination, AllocatedSpectrum: IDenseComplexMatrix;
  ColdMilliseconds, WarmMilliseconds: Double;
  Started: Int64;
  WorkingElements, DenseShapeElements, RetainedBytes: QWord;
  I, MiddleFrame: SizeInt;
  Checksum, Tolerance, MaximumResidual: Double;
  FFTPlan: TFFTPlan;
  Shape, Suffix: string;
begin
  SetLength(Input, SampleCount);
  FillRealInput(Input);
  ColdMilliseconds := STFTConstructionMilliseconds(SampleCount,
    FrameLength, HopLength, ConstructionRepetitions);
  Plan := TSTFTPlan.Create(SampleCount, FrameLength, HopLength, wtHann);
  FFTPlan := TFFTPlan.Create(FrameLength);
  try
    RetainedBytes := Plan.RetainedBytes;
    DenseShapeElements := QWord(Plan.FrameCount) * QWord(FrameLength);
    WorkingElements := 2 * DenseShapeElements +
      QWord(Plan.FrameLength) * 3 + QWord(Plan.SampleCount) * 2 +
      QWord(FrameLength + (Plan.FrameCount - 1) * HopLength) +
      2 * QWord(FFTPlan.WorkspaceElements);
    Shape := '65536_' + IntToStr(FrameLength) + '_' + IntToStr(HopLength);
    Suffix := IntToStr(FrameLength) + '_' + IntToStr(HopLength);
    Spectrum := Plan.Analyze(Input);
    SpectrumDestination := TDenseComplexMatrix.Zeros(Plan.FrameCount,
      Plan.FrameLength);
    SetLength(Synthesized, SampleCount);
    SetLength(AllocatedSamples, 0);
    Plan.AnalyzeInto(Input, SpectrumDestination);
    Plan.SynthesizeInto(Spectrum, Synthesized);
    MaximumResidual := 0.0;
    for I := 0 to SampleCount - 1 do
      if Abs(Input[I] - Synthesized[I]) > MaximumResidual then
        MaximumResidual := Abs(Input[I] - Synthesized[I]);
    if MaximumResidual > 5E-11 then
      Halt(250);
    Tolerance := 5E-11;
    MiddleFrame := Plan.FrameCount div 2;

    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        Plan.AnalyzeInto(Input, SpectrumDestination);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := SpectrumDestination[MiddleFrame, 5].Re +
      SpectrumDestination[MiddleFrame, FrameLength - 5].Re;
    WriteSpectralRow('spectral-stft-analyze-into-' + Suffix, 'large',
      'double', Shape, 'cold_create_destroy_batch_' +
        IntToStr(ConstructionRepetitions) + '_then_reused_matrix', ColdMilliseconds,
      WarmMilliseconds, WarmIterations, AllocationCalls, RetainedBytes,
      WorkingElements, DenseShapeElements, Checksum, Tolerance);

    AllocatedSpectrum := nil;
    Plan.Analyze(Input);
    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        AllocatedSpectrum := Plan.Analyze(Input);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := AllocatedSpectrum[MiddleFrame, 5].Re +
      AllocatedSpectrum[MiddleFrame, FrameLength - 5].Re;
    WriteSpectralRow('spectral-stft-analyze-allocating-' + Suffix, 'large',
      'double', Shape, 'cold_create_destroy_batch_' +
        IntToStr(ConstructionRepetitions) + '_then_allocating_matrix', ColdMilliseconds,
      WarmMilliseconds, WarmIterations, AllocationCalls, RetainedBytes,
      WorkingElements, DenseShapeElements, Checksum, Tolerance);

    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        Plan.SynthesizeInto(Spectrum, Synthesized);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := Synthesized[0] + Synthesized[SampleCount - 1];
    WriteSpectralRow('spectral-stft-synthesize-into-' + Suffix, 'large',
      'double', Shape, 'cold_create_destroy_batch_' +
        IntToStr(ConstructionRepetitions) + '_then_reused_array', ColdMilliseconds,
      WarmMilliseconds, WarmIterations, AllocationCalls, RetainedBytes,
      WorkingElements, DenseShapeElements, Checksum, Tolerance);

    AllocatedSamples := nil;
    Plan.Synthesize(Spectrum);
    BeginAllocationCount;
    try
      Started := ReadBenchmarkCounter;
      for I := 1 to WarmIterations do
        AllocatedSamples := Plan.Synthesize(Spectrum);
      WarmMilliseconds := CounterDeltaMilliseconds(
        ReadBenchmarkCounter - Started);
    finally
      EndAllocationCount;
    end;
    Checksum := AllocatedSamples[0] + AllocatedSamples[SampleCount - 1];
    WriteSpectralRow('spectral-stft-synthesize-allocating-' + Suffix,
      'large', 'double', Shape, 'cold_create_destroy_batch_' +
        IntToStr(ConstructionRepetitions) + '_then_allocating_array',
      ColdMilliseconds, WarmMilliseconds, WarmIterations, AllocationCalls,
      RetainedBytes, WorkingElements, DenseShapeElements, Checksum, Tolerance);
  finally
    FFTPlan.Free;
    Plan.Free;
  end;
end;

procedure RunV250SpectralPlanBenchmarks;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  Writeln('mathlib-fp v2.5.0 reusable spectral-plan evidence');
  BenchmarkFFTPlan(64, 5000, 10000, 'small');
  BenchmarkFFTPlan(4096, 20, 100, 'small');
  BenchmarkFFTPlan(65536, 5, 5, 'large');
  BenchmarkFFTPlan(1009, 50, 100, 'small');
  BenchmarkFFTPlan(10007, 10, 25, 'large');
  BenchmarkSTFTPlan(256, 128, 3, 5);
  BenchmarkSTFTPlan(255, 85, 3, 5);
end;

end.
