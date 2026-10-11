unit TestSpectralPlans;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, SyncObjs, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices,
  EngineeringLib.Signal, EngineeringLib.DSP;

type
  TSpectralPlanTest = class(TTestCase)
  published
    procedure TestFFTIndependentFixtureAndNormalizations;
    procedure TestSTFTIndependentFixtureAndEditedReconstruction;
    procedure TestFFTPreparedDestinationValidationAndReuse;
    procedure TestPreparedWarmCallsAllocateNothing;
    procedure TestFFTBusyGuardRejectsOverlap;
    procedure TestSTFTBusyGuardRejectsOverlap;
    procedure TestSTFTGeometryWindowsAndRoundTrip;
    procedure TestSTFTViewsSpectralEditsAndAtomicFailures;
    procedure TestSTFTShortSignalAndCoverageRejection;
  end;

implementation

{$I SpectralPlanFixtures.inc}

var
  SavedMemoryManager: TMemoryManager;
  AllocationCounting: Boolean = False;
  CountedAllocationCalls: QWord = 0;

function CountedGetMem(Size: PtrUInt): Pointer;
begin
  if AllocationCounting then Inc(CountedAllocationCalls);
  Result := SavedMemoryManager.Getmem(Size);
end;

function CountedAllocMem(Size: PtrUInt): Pointer;
begin
  if AllocationCounting then Inc(CountedAllocationCalls);
  Result := SavedMemoryManager.AllocMem(Size);
end;

function CountedReAllocMem(var P: Pointer; Size: PtrUInt): Pointer;
begin
  if AllocationCounting then Inc(CountedAllocationCalls);
  Result := SavedMemoryManager.ReAllocMem(P, Size);
end;

procedure StartAllocationCounting;
var
  CountingManager: TMemoryManager;
begin
  GetMemoryManager(SavedMemoryManager);
  CountingManager := SavedMemoryManager;
  CountingManager.Getmem := @CountedGetMem;
  CountingManager.AllocMem := @CountedAllocMem;
  CountingManager.ReAllocMem := @CountedReAllocMem;
  CountedAllocationCalls := 0;
  SetMemoryManager(CountingManager);
  AllocationCounting := True;
end;

procedure StopAllocationCounting;
begin
  AllocationCounting := False;
  SetMemoryManager(SavedMemoryManager);
end;

type
  TFFTOverlapProbe = class(TThread)
  private
    FPlan: TFFTPlan;
    FInput, FDestination: TComplexArray;
    FStartGate: TEvent;
  public
    Completed: Boolean;
    BusyRejected: Boolean;
    constructor Create(const Plan: TFFTPlan; const Input,
      Destination: TComplexArray; const StartGate: TEvent);
  protected
    procedure Execute; override;
  end;

  TSTFTOverlapProbe = class(TThread)
  private
    FPlan: TSTFTPlan;
    FInput: TDoubleArray;
    FDestination: IDenseComplexMatrix;
    FStartGate: TEvent;
  public
    Completed: Boolean;
    BusyRejected: Boolean;
    constructor Create(const Plan: TSTFTPlan; const Input: TDoubleArray;
      const Destination: IDenseComplexMatrix; const StartGate: TEvent);
  protected
    procedure Execute; override;
  end;

constructor TFFTOverlapProbe.Create(const Plan: TFFTPlan;
  const Input, Destination: TComplexArray; const StartGate: TEvent);
begin
  FPlan := Plan;
  FInput := Input;
  FDestination := Destination;
  FStartGate := StartGate;
  Completed := False;
  BusyRejected := False;
  inherited Create(False);
  FreeOnTerminate := False;
end;

procedure TFFTOverlapProbe.Execute;
begin
  FStartGate.WaitFor(High(Cardinal));
  try
    FPlan.ExecuteInto(FInput, FDestination);
    Completed := True;
  except
    on EDSPError do BusyRejected := True;
  end;
end;

constructor TSTFTOverlapProbe.Create(const Plan: TSTFTPlan;
  const Input: TDoubleArray; const Destination: IDenseComplexMatrix;
  const StartGate: TEvent);
begin
  FPlan := Plan;
  FInput := Input;
  FDestination := Destination;
  FStartGate := StartGate;
  Completed := False;
  BusyRejected := False;
  inherited Create(False);
  FreeOnTerminate := False;
end;

procedure TSTFTOverlapProbe.Execute;
begin
  FStartGate.WaitFor(High(Cardinal));
  try
    FPlan.AnalyzeInto(FInput, FDestination);
    Completed := True;
  except
    on EDSPError do BusyRejected := True;
  end;
end;

procedure TSpectralPlanTest.TestFFTIndependentFixtureAndNormalizations;
const
  Lengths: array[0..9] of SizeInt =
    (1, 2, 3, 7, 8, 31, 64, 1009, 10007, 65536);
  Modes: array[0..3] of TFFTNormalization =
    (fnBackward, fnForward, fnUnitary, fnNone);
  Amplitudes: array[0..2] of Double = (1E-6, 1.0, 1E6);
var
  Plan: TFFTPlan;
  Input, Actual, Restored, ReferenceSpectrum: TComplexArray;
  I, J, K, N, WorkspaceLength, PatternIndex, ScaleIndex: SizeInt;
  ExpectedScale, Tolerance, Amplitude, MagnitudeScale: Double;
begin
  SetLength(Input, 7);
  for I := 0 to 6 do
    Input[I] := TComplex.Create(FFTFixture7InputRe[I], FFTFixture7InputIm[I]);
  Plan := TFFTPlan.Create(7);
  try
    Actual := Plan.Execute(Input, False, fnNone);
    for I := 0 to 6 do
    begin
      AssertEquals('7-point high-precision direct DFT real bin',
        FFTFixture7ForwardRe[I], Actual[I].Re, 5E-11);
      AssertEquals('7-point high-precision direct DFT imaginary bin',
        FFTFixture7ForwardIm[I], Actual[I].Im, 5E-11);
    end;
    SetLength(ReferenceSpectrum, 7);
    for I := 0 to 6 do
      ReferenceSpectrum[I] := TComplex.Create(
        FFTFixture7ForwardRe[I], FFTFixture7ForwardIm[I]);
    for I := 0 to High(Modes) do
    begin
      case Modes[I] of
        fnBackward, fnNone: ExpectedScale := 1.0;
        fnForward: ExpectedScale := 1.0 / Double(7);
        fnUnitary: ExpectedScale := 1.0 / Sqrt(Double(7));
      end;
      Actual := Plan.Execute(Input, False, Modes[I]);
      for K := 0 to 6 do
      begin
        AssertEquals('direct DFT forward normalization real bin',
          FFTFixture7ForwardRe[K] * ExpectedScale, Actual[K].Re, 5E-11);
        AssertEquals('direct DFT forward normalization imaginary bin',
          FFTFixture7ForwardIm[K] * ExpectedScale, Actual[K].Im, 5E-11);
      end;

      case Modes[I] of
        fnBackward: ExpectedScale := 1.0;
        fnForward, fnNone: ExpectedScale := 7.0;
        fnUnitary: ExpectedScale := Sqrt(Double(7));
      end;
      Restored := Plan.Execute(ReferenceSpectrum, True, Modes[I]);
      for K := 0 to 6 do
      begin
        AssertEquals('direct DFT inverse normalization real sample',
          TComplex.Create(FFTFixture7InputRe[K], FFTFixture7InputIm[K]).Re *
            ExpectedScale, Restored[K].Re, 5E-11);
        AssertEquals('direct DFT inverse normalization imaginary sample',
          TComplex.Create(FFTFixture7InputRe[K], FFTFixture7InputIm[K]).Im *
            ExpectedScale, Restored[K].Im, 5E-11);
      end;
    end;
    AssertEquals('Bluestein workspace uses next power of two', 16,
      Plan.WorkspaceElements);
  finally
    Plan.Free;
  end;

  for J := 0 to High(Lengths) do
  begin
    N := Lengths[J];
    SetLength(Input, N);
    for I := 0 to N - 1 do
      Input[I] := TComplex.Create(
        Sin(0.13 * I) + 0.25 * Cos(0.031 * I),
        Cos(0.17 * I) - 0.125 * Sin(0.019 * I));
    Plan := TFFTPlan.Create(N);
    try
      AssertEquals('fixed transform length', N, Plan.TransformLength);
      if (N and (N - 1)) = 0 then
      begin
        WorkspaceLength := N;
        AssertTrue('radix-2 retained payload stays under the specified ceiling',
          Plan.RetainedBytes <= 64 * N + 2 * SizeOf(SizeInt) * N);
      end
      else
      begin
        WorkspaceLength := 1;
        while WorkspaceLength < 2 * N - 1 do
          WorkspaceLength := WorkspaceLength shl 1;
        AssertEquals('Bluestein workspace geometry', WorkspaceLength,
          Plan.WorkspaceElements);
        AssertTrue('Bluestein retained payload stays under the specified ceiling',
          Plan.RetainedBytes <= 16 * (6 * WorkspaceLength + 4 * N) +
            SizeOf(SizeInt) * (WorkspaceLength + N));
      end;
      AssertEquals('workspace element diagnostic', WorkspaceLength,
        Plan.WorkspaceElements);

      for I := 0 to High(Modes) do
      begin
        Actual := Plan.Execute(Input, False, Modes[I]);
        Restored := Plan.Execute(Actual, True, Modes[I]);
        if Modes[I] = fnNone then
          ExpectedScale := N
        else
          ExpectedScale := 1.0;
        for K := 0 to High(Input) do
        begin
          Tolerance := 5E-11 * Max(1.0,
            Abs(Input[K].Re * ExpectedScale));
          AssertEquals('FFT forward/inverse real round trip',
            Input[K].Re * ExpectedScale, Restored[K].Re, Tolerance);
          Tolerance := 5E-11 * Max(1.0,
            Abs(Input[K].Im * ExpectedScale));
          AssertEquals(Format(
            'FFT forward/inverse imaginary round trip N=%d mode=%d sample=%d',
            [N, Ord(Modes[I]), K]),
            Input[K].Im * ExpectedScale, Restored[K].Im, Tolerance);
        end;
      end;

      { Include zero, impulse, and deterministic complex data at ordinary
        amplitudes, independently of the normalization sweep above. }
      for PatternIndex := 0 to 2 do
        for ScaleIndex := 0 to High(Amplitudes) do
        begin
          Amplitude := Amplitudes[ScaleIndex];
          for K := 0 to N - 1 do
          begin
            case PatternIndex of
              0: Input[K] := TComplex.Zero;
              1:
                if K = N div 2 then
                  Input[K] := TComplex.Create(Amplitude, -0.5 * Amplitude)
                else
                  Input[K] := TComplex.Zero;
              2:
                Input[K] := TComplex.Create(
                  Amplitude * ((K * 17 mod 23) - 11) / 11.0,
                  Amplitude * ((K * 13 mod 19) - 9) / 9.0);
            end;
          end;
          MagnitudeScale := 1.0;
          for K := 0 to N - 1 do
            MagnitudeScale := Max(MagnitudeScale,
              Sqrt(Sqr(Input[K].Re) + Sqr(Input[K].Im)));
          Actual := Plan.Execute(Input, False, fnBackward);
          Restored := Plan.Execute(Actual, True, fnBackward);
          for K := 0 to N - 1 do
          begin
            Tolerance := 5E-11 * MagnitudeScale;
            AssertEquals('zero/impulse/random real FFT property',
              Input[K].Re, Restored[K].Re, Tolerance);
            Tolerance := 5E-11 * MagnitudeScale;
            AssertEquals('zero/impulse/random imaginary FFT property',
              Input[K].Im, Restored[K].Im, Tolerance);
          end;
        end;
    finally
      Plan.Free;
    end;
  end;
end;

procedure TSpectralPlanTest.TestSTFTIndependentFixtureAndEditedReconstruction;
var
  Plan: TSTFTPlan;
  Input, Output: TDoubleArray;
  Spectrum: IDenseComplexMatrix;
  Frame, Bin, FlatIndex, I: SizeInt;
begin
  Input := TDoubleArray.Create(
    STFTFixture5Input[0], STFTFixture5Input[1], STFTFixture5Input[2],
    STFTFixture5Input[3], STFTFixture5Input[4]);
  Plan := TSTFTPlan.Create(5, 4, 2, wtRectangular);
  try
    Spectrum := Plan.Analyze(Input);
    AssertEquals('independent STFT frame count', 5, Spectrum.Rows);
    AssertEquals('independent STFT full spectrum length', 4, Spectrum.Cols);
    FlatIndex := 0;
    for Frame := 0 to Spectrum.Rows - 1 do
      for Bin := 0 to Spectrum.Cols - 1 do
      begin
        AssertEquals('direct-DFT STFT real frame bin',
          STFTFixture5SpectrumRe[FlatIndex], Spectrum[Frame, Bin].Re, 5E-13);
        AssertEquals('direct-DFT STFT imaginary frame bin',
          STFTFixture5SpectrumIm[FlatIndex], Spectrum[Frame, Bin].Im, 5E-13);
        Inc(FlatIndex);
      end;

    Spectrum[2, 1] := Spectrum[2, 1] + TComplex.Create(0.25, 0.125);
    Spectrum[2, 3] := Spectrum[2, 3] + TComplex.Create(0.25, -0.125);
    Output := Plan.Synthesize(Spectrum);
    for I := 0 to High(Output) do
      AssertEquals('independent inverse-DFT weighted overlap-add fixture',
        STFTFixture5EditedOutput[I], Output[I], 5E-13);
  finally
    Plan.Free;
  end;
end;

procedure TSpectralPlanTest.TestFFTPreparedDestinationValidationAndReuse;
var
  Plan: TFFTPlan;
  Input, Destination, Expected: TComplexArray;
  Failed: Boolean;
  I: SizeInt;
begin
  Input := TComplexArray.Create(
    TComplex.Create(1.0, -0.5), TComplex.Create(2.0, 3.0),
    TComplex.Create(-1.0, 0.25), TComplex.Create(0.5, 2.0));
  Plan := TFFTPlan.Create(4);
  try
    Expected := Plan.Execute(Input, False, fnNone);
    Destination := Input;
    Plan.ExecuteInto(Destination, Destination, False, fnNone);
    for I := 0 to 3 do
      AssertEquals('exact in-place alias matches allocating call',
        Expected[I].Re, Destination[I].Re, 1E-12);

    Destination := TComplexArray.Create(TComplex.Create(7, 8),
      TComplex.Create(9, 10), TComplex.Create(11, 12),
      TComplex.Create(13, 14));
    Failed := False;
    try
      Plan.ExecuteInto(TComplexArray.Create(TComplex.Create(1, 0)),
        Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('wrong input length raises EDSPError', Failed);
    AssertEquals('wrong length leaves destination unchanged', 7.0,
      Destination[0].Re, 0.0);

    Input[0].Re := NaN;
    Failed := False;
    try
      Plan.ExecuteInto(Input, Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('non-finite input raises EDSPError', Failed);
    AssertEquals('non-finite input leaves destination unchanged', 7.0,
      Destination[0].Re, 0.0);
    for I := 0 to High(Input) do
      Input[I] := TComplex.Create(MaxDouble, 0.0);
    Failed := False;
    try
      Plan.ExecuteInto(Input, Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('finite input with overflowing output raises EDSPError', Failed);
    AssertEquals('overflow leaves destination unchanged', 7.0,
      Destination[0].Re, 0.0);

    SetLength(Destination, 3);
    Failed := False;
    try
      Plan.ExecuteInto(Input, Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('wrong prepared destination length raises EDSPError', Failed);
    SetLength(Destination, 4);
    for I := 0 to High(Destination) do
      Destination[I] := TComplex.Create(7.0, 8.0);
    for I := 0 to High(Input) do
      Input[I] := TComplex.Create(I + 1, -I);
    Plan.ExecuteInto(Input, Destination);
    AssertTrue('plan remains reusable after an invalid call',
      Destination[0].IsFinite);
  finally
    Plan.Free;
  end;

  Failed := False;
  try
    Plan := TFFTPlan.Create(0);
    Plan.Free;
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('zero transform length is rejected', Failed);
end;

procedure TSpectralPlanTest.TestPreparedWarmCallsAllocateNothing;
var
  FFT: TFFTPlan;
  PrimeFFT: TFFTPlan;
  STFT: TSTFTPlan;
  Input, Output, PrimeInput, PrimeOutput: TComplexArray;
  Signal, Synthesized: TDoubleArray;
  Spectrum, Destination: IDenseComplexMatrix;
  I: SizeInt;
begin
  SetLength(Input, 64);
  for I := 0 to High(Input) do
    Input[I] := TComplex.Create(Sin(0.17 * I), Cos(0.11 * I));
  SetLength(Output, 64);
  FFT := TFFTPlan.Create(64);
  try
    FFT.ExecuteInto(Input, Output);
    StartAllocationCounting;
    try
      for I := 1 to 5 do
        FFT.ExecuteInto(Input, Output);
    finally
      StopAllocationCounting;
    end;
    AssertEquals('warm FFT Into performs no memory-manager allocations',
      QWord(0), CountedAllocationCalls);
  finally
    FFT.Free;
  end;

  SetLength(PrimeInput, 1009);
  for I := 0 to High(PrimeInput) do
    PrimeInput[I] := TComplex.Create(Sin(0.07 * I), Cos(0.03 * I));
  SetLength(PrimeOutput, Length(PrimeInput));
  PrimeFFT := TFFTPlan.Create(Length(PrimeInput));
  try
    PrimeFFT.ExecuteInto(PrimeInput, PrimeOutput);
    StartAllocationCounting;
    try
      PrimeFFT.ExecuteInto(PrimeInput, PrimeOutput);
    finally
      StopAllocationCounting;
    end;
    AssertEquals('warm Bluestein Into performs no memory-manager allocations',
      QWord(0), CountedAllocationCalls);
  finally
    PrimeFFT.Free;
  end;

  SetLength(Signal, 128);
  for I := 0 to High(Signal) do
    Signal[I] := Sin(0.09 * I) + 0.2 * Cos(0.23 * I);
  STFT := TSTFTPlan.Create(Length(Signal), 63, 21, wtRectangular);
  try
    Spectrum := STFT.Analyze(Signal);
    Destination := TDenseComplexMatrix.Zeros(STFT.FrameCount,
      STFT.FrameLength);
    SetLength(Synthesized, Length(Signal));
    STFT.AnalyzeInto(Signal, Destination);
    STFT.SynthesizeInto(Spectrum, Synthesized);
    StartAllocationCounting;
    try
      STFT.AnalyzeInto(Signal, Destination);
      STFT.SynthesizeInto(Spectrum, Synthesized);
    finally
      StopAllocationCounting;
    end;
    AssertEquals('warm STFT Into analysis and synthesis allocate nothing',
      QWord(0), CountedAllocationCalls);
  finally
    STFT.Free;
  end;
end;

procedure TSpectralPlanTest.TestFFTBusyGuardRejectsOverlap;
const
  N = 262144;
var
  Plan: TFFTPlan;
  Input, MainDestination, WorkerDestination: TComplexArray;
  StartGate: TEvent;
  Worker: TFFTOverlapProbe;
  I: SizeInt;
  MainCompleted, MainRejected: Boolean;
begin
  SetLength(Input, N);
  SetLength(MainDestination, N);
  SetLength(WorkerDestination, N);
  for I := 0 to N - 1 do
    Input[I] := TComplex.Create(1.0 / (I + 1), -0.25 / (I + 1));
  Plan := TFFTPlan.Create(N);
  StartGate := TEvent.Create(nil, True, False, '');
  try
    Worker := TFFTOverlapProbe.Create(Plan, Input, WorkerDestination,
      StartGate);
    try
      StartGate.SetEvent;
      MainCompleted := False;
      MainRejected := False;
      try
        Plan.ExecuteInto(Input, MainDestination);
        MainCompleted := True;
      except
        on EDSPError do MainRejected := True;
      end;
      Worker.WaitFor;
      AssertTrue('one overlapping call completes',
        MainCompleted xor Worker.Completed);
      AssertTrue('one overlapping call is rejected as busy',
        MainRejected xor Worker.BusyRejected);
    finally
      Worker.Free;
    end;
  finally
    StartGate.Free;
    Plan.Free;
  end;
end;

procedure TSpectralPlanTest.TestSTFTBusyGuardRejectsOverlap;
const
  SampleCount = 262144;
  FrameLength = 64;
  HopLength = 32;
var
  Plan: TSTFTPlan;
  Input: TDoubleArray;
  Destination: IDenseComplexMatrix;
  StartGate: TEvent;
  Worker: TSTFTOverlapProbe;
  I: SizeInt;
  MainCompleted, MainRejected: Boolean;
begin
  SetLength(Input, SampleCount);
  for I := 0 to High(Input) do
    Input[I] := 0.0;
  Plan := TSTFTPlan.Create(SampleCount, FrameLength, HopLength,
    wtRectangular);
  Destination := TDenseComplexMatrix.Zeros(Plan.FrameCount, FrameLength);
  StartGate := TEvent.Create(nil, True, False, '');
  try
    Worker := TSTFTOverlapProbe.Create(Plan, Input, Destination, StartGate);
    try
      StartGate.SetEvent;
      MainCompleted := False;
      MainRejected := False;
      try
        Plan.AnalyzeInto(Input, Destination);
        MainCompleted := True;
      except
        on EDSPError do MainRejected := True;
      end;
      Worker.WaitFor;
      AssertTrue('one overlapping STFT call completes',
        MainCompleted xor Worker.Completed);
      AssertTrue('one overlapping STFT call is rejected as busy',
        MainRejected xor Worker.BusyRejected);
    finally
      Worker.Free;
    end;
  finally
    StartGate.Free;
    Plan.Free;
  end;
end;

procedure TSpectralPlanTest.TestSTFTGeometryWindowsAndRoundTrip;
const
  FrameLengths: array[0..3] of SizeInt = (16, 63, 64, 257);
var
  Plan: TSTFTPlan;
  FFT: TFFTPlan;
  Input, Output: TDoubleArray;
  Spectrum: IDenseComplexMatrix;
  I, J, N, Hop, WindowIndex: SizeInt;
  WindowType: TWindowType;
  Bound: Int64;
begin
  SetLength(Input, 37);
  for I := 0 to High(Input) do
    Input[I] := Sin(0.19 * I) + 0.3 * Cos(0.31 * I);
  for WindowIndex := Ord(Low(TWindowType)) to Ord(High(TWindowType)) do
  begin
    WindowType := TWindowType(WindowIndex);
    Plan := TSTFTPlan.Create(Length(Input), 16, 5, WindowType);
    FFT := TFFTPlan.Create(16);
    try
      AssertEquals('sample count metadata', 37, Plan.SampleCount);
      AssertEquals('frame length metadata', 16, Plan.FrameLength);
      AssertEquals('hop metadata', 5, Plan.HopLength);
      AssertEquals('padded framing retains the final partial frame', 12,
        Plan.FrameCount);
      AssertEquals('left padding follows the fixed convention', 15,
        Plan.LeftPadding);
      AssertEquals('right padding covers the tail', 19, Plan.RightPadding);
      Spectrum := Plan.Analyze(Input);
      AssertEquals('spectrum frame rows', 12, Spectrum.Rows);
      AssertEquals('full complex spectrum columns', 16, Spectrum.Cols);
      Output := Plan.Synthesize(Spectrum);
      for I := 0 to High(Input) do
        AssertEquals('STFT reconstructs every original sample', Input[I],
          Output[I], 5E-11 * Max(1.0, Abs(Input[I])));
      Bound := FFT.RetainedBytes + 16 * Plan.FrameCount * Plan.FrameLength +
        8 * (2 * (16 + (Plan.FrameCount - 1) * Plan.HopLength) +
          3 * Plan.FrameLength + Plan.SampleCount);
      AssertTrue('STFT retained payload stays under the published ceiling',
        Plan.RetainedBytes <= Bound);
    finally
      FFT.Free;
      Plan.Free;
    end;
  end;

  { Exercise the specified odd, even, and larger frame geometries with
    impulses at both endpoints so padding and trimming stay visible. }
  SetLength(Input, 73);
  for I := 0 to High(Input) do Input[I] := 0.0;
  Input[0] := 1.0;
  Input[High(Input)] := -0.75;
  for J := 0 to High(FrameLengths) do
  begin
    N := FrameLengths[J];
    Hop := N div 3;
    Plan := TSTFTPlan.Create(Length(Input), N, Hop, wtRectangular);
    try
      Spectrum := Plan.Analyze(Input);
      Output := Plan.Synthesize(Spectrum);
      AssertEquals('boundary impulse geometry preserves sample count',
        Length(Input), Length(Output));
      for I := 0 to High(Input) do
        AssertEquals('first and last impulses survive padded STFT', Input[I],
          Output[I], 5E-11);
    finally
      Plan.Free;
    end;
  end;
end;

procedure TSpectralPlanTest.TestSTFTViewsSpectralEditsAndAtomicFailures;
var
  Plan: TSTFTPlan;
  Input, Destination: TDoubleArray;
  Spectrum, Edited, Backing, View: IDenseComplexMatrix;
  I, J: SizeInt;
  Failed: Boolean;
begin
  SetLength(Input, 37);
  for I := 0 to High(Input) do
    Input[I] := Sin(0.19 * I) + 0.3 * Cos(0.31 * I);
  Plan := TSTFTPlan.Create(Length(Input), 16, 5, wtHann);
  try
    Spectrum := Plan.Analyze(Input);
    Backing := TDenseComplexMatrix.Zeros(Plan.FrameCount + 2,
      Plan.FrameLength + 2);
    View := Backing.View(1, 1, Plan.FrameCount, Plan.FrameLength);
    Plan.AnalyzeInto(Input, View);
    AssertEquals('view element matches allocated analysis',
      Spectrum[4, 7].Re, View[4, 7].Re, 1E-12);
    AssertEquals('view leaves preceding outer element unchanged',
      0.0, Backing[0, 0].Re, 0.0);
    AssertEquals('view leaves trailing outer element unchanged',
      0.0, Backing[Plan.FrameCount + 1, Plan.FrameLength + 1].Re, 0.0);

    SetLength(Destination, Length(Input));
    for I := 0 to High(Destination) do Destination[I] := -987.0;
    Edited := Spectrum.Clone;
    Edited[0, 2] := Edited[0, 2] + TComplex.Create(0.25, 0.125);
    Edited[0, 14] := Edited[0, 14] + TComplex.Create(0.25, -0.125);
    Plan.SynthesizeInto(Edited, Destination);
    AssertTrue('conjugate-pair edits produce a finite reconstructed signal',
      (not IsNan(Destination[0])) and (not IsInfinite(Destination[0])) and
      (not IsNan(Destination[High(Destination)])) and
      (not IsInfinite(Destination[High(Destination)])));

    Edited := Spectrum.Clone;
    Edited[0, 1] := Edited[0, 1] + TComplex.Create(0.5, 0.0);
    for I := 0 to High(Destination) do Destination[I] := -987.0;
    Failed := False;
    try
      Plan.SynthesizeInto(Edited, Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('broken conjugate-pair spectrum raises EDSPError', Failed);
    for I := 0 to High(Destination) do
      AssertEquals('rejected spectrum leaves destination unchanged', -987.0,
        Destination[I], 0.0);

    Edited := Spectrum.Clone;
    Edited[0, 0] := TComplex.Create(Edited[0, 0].Re, NaN);
    Failed := False;
    try
      Plan.SynthesizeInto(Edited, Destination);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('non-finite spectrum raises EDSPError', Failed);
    AssertEquals('non-finite spectrum leaves destination unchanged', -987.0,
      Destination[0], 0.0);

    Edited := Spectrum.Clone;
    Edited[0, 0] := TComplex.Create(Edited[0, 0].Re, 0.0);
    Plan.SynthesizeInto(Edited, Destination);
    for I := 0 to High(Input) do
      AssertEquals('plan recovers after rejected spectra', Input[I],
        Destination[I], 5E-11 * Max(1.0, Abs(Input[I])));

    for J := 0 to High(Input) do Destination[J] := 33.0;
    Input[3] := NaN;
    Failed := False;
    try
      Plan.AnalyzeInto(Input, View);
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('non-finite analysis input raises EDSPError', Failed);
    AssertEquals('failed analysis leaves the matrix view unchanged',
      Spectrum[4, 7].Re, View[4, 7].Re, 1E-12);
  finally
    Plan.Free;
  end;
end;

procedure TSpectralPlanTest.TestSTFTShortSignalAndCoverageRejection;
var
  Plan: TSTFTPlan;
  Input, Output: TDoubleArray;
  Spectrum: IDenseComplexMatrix;
  Failed: Boolean;
  I: SizeInt;
begin
  Input := TDoubleArray.Create(2.5);
  Plan := TSTFTPlan.Create(1, 8, 4, wtRectangular);
  try
    Spectrum := Plan.Analyze(Input);
    Output := Plan.Synthesize(Spectrum);
    AssertEquals('one-sample input is retained through padded framing', 2.5,
      Output[0], 1E-12);
  finally
    Plan.Free;
  end;

  Failed := False;
  try
    Plan := TSTFTPlan.Create(37, 16, 16, wtHann);
    Plan.Free;
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('uncovered Hann boundary is rejected at construction', Failed);

  for I := 0 to 1 do
  begin
    Failed := False;
    try
    Plan := TSTFTPlan.Create(37, 16, 0, wtHann);
      Plan.Free;
    except
      on EDSPError do Failed := True;
    end;
    AssertTrue('invalid sample geometry is rejected', Failed);
  end;
end;

initialization
  RegisterTest(TSpectralPlanTest);

end.
