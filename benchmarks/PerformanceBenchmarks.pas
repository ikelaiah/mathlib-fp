unit PerformanceBenchmarks;

{ Canonical v1.9.5 benchmark rows. Timings use the portable millisecond timer;
  warm batches are deliberately long enough to avoid interpreting sub-tick
  observations as precise per-call measurements. }

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils;

procedure WritePerformanceRow(const Identifier, Domain, Scale, ScalarKind,
  Shape: string; const ColdMilliseconds, WarmMilliseconds: QWord;
  const WarmIterations, Allocations: SizeInt; const RetainedBytes: QWord;
  const WorkingElements, DenseShapeElements: QWord; const Checksum,
  Tolerance: Double; const Setup: string);
procedure RunV195PerformanceBenchmarks;

implementation

uses
  Math,
  MathBase.SharedTypes,
  MathBase.Complex,
  StatsLib.Streaming,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels,
  EngineeringLib.Signal,
  EngineeringLib.DSP,
  NumericsLib.Modelling,
  MLLib.Analysis;

function RetainedHeapDelta(const Baseline: QWord): QWord;
var
  Current: QWord;
begin
  Current := GetHeapStatus.TotalAllocated;
  if Current >= Baseline then
    Result := Current - Baseline
  else
    Result := 0;
end;

procedure WritePerformanceRow(const Identifier, Domain, Scale, ScalarKind,
  Shape: string; const ColdMilliseconds, WarmMilliseconds: QWord;
  const WarmIterations, Allocations: SizeInt; const RetainedBytes: QWord;
  const WorkingElements, DenseShapeElements: QWord; const Checksum,
  Tolerance: Double; const Setup: string);
begin
  Writeln('PERF|id=', Identifier,
    '|domain=', Domain,
    '|scale=', Scale,
    '|scalar=', ScalarKind,
    '|shape=', Shape,
    '|cold_ms=', ColdMilliseconds,
    '|warm_ms=', WarmMilliseconds,
    '|warm_iterations=', WarmIterations,
    '|allocations=', Allocations,
    '|retained_bytes=', RetainedBytes,
    '|working_elements=', WorkingElements,
    '|dense_shape_elements=', DenseShapeElements,
    '|checksum=', Checksum:0:12,
    '|tolerance=', Tolerance,
    '|setup=', Setup);
end;

function SineIntegrand(X: Double): Double;
begin
  Result := Sin(X);
end;

function PlaneIntegrand(const X: TDoubleArray): Double;
begin
  Result := X[0] + X[1];
end;

procedure FillDensePair(const A, B: IDenseDoubleMatrix);
var
  I, J: SizeInt;
begin
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      A[I, J] := Sin((I + 1) * 0.01 + (J + 1) * 0.03);
  for I := 0 to B.Rows - 1 do
    for J := 0 to B.Cols - 1 do
      B[I, J] := Cos((I + 1) * 0.02 - (J + 1) * 0.01);
end;

procedure BenchmarkDenseSmall;
const
  N = 16;
  WarmIterations = 5000;
var
  A, B, Destination: IDenseDoubleMatrix;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
  Checksum: Double;
begin
  A := TDenseDoubleMatrix.Zeros(N, N);
  B := TDenseDoubleMatrix.Zeros(N, N);
  Destination := TDenseDoubleMatrix.Zeros(N, N);
  FillDensePair(A, B);
  Started := GetTickCount64;
  MultiplyInto(A, B, Destination);
  ColdMilliseconds := GetTickCount64 - Started;
  MultiplyInto(A, B, Destination);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    MultiplyInto(A, B, Destination);
  WarmMilliseconds := GetTickCount64 - Started;
  Checksum := Destination[0, 0] + Destination[N - 1, N - 1];
  WritePerformanceRow('dense-gemm-small-portable', 'dense', 'small',
    'double', '16x16x16', ColdMilliseconds, WarmMilliseconds,
    WarmIterations, 0, RetainedHeapDelta(HeapBaseline), 3 * N * N, N * N,
    Checksum, 1.0E-12, 'prepared_inputs_destination');
end;

procedure BenchmarkDenseLarge;
const
  RowsA = 127;
  Inner = 129;
  ColsB = 65;
  WarmIterations = 5;
var
  A, B, PortableDestination, AutomaticDestination: IDenseDoubleMatrix;
  Started, ColdPortable, ColdAutomatic, WarmPortable, WarmAutomatic,
    HeapBaseline: QWord;
  Iteration: SizeInt;
  Checksum: Double;
begin
  A := TDenseDoubleMatrix.Zeros(RowsA, Inner);
  B := TDenseDoubleMatrix.Zeros(Inner, ColsB);
  PortableDestination := TDenseDoubleMatrix.Zeros(RowsA, ColsB);
  AutomaticDestination := TDenseDoubleMatrix.Zeros(RowsA, ColsB);
  FillDensePair(A, B);

  Started := GetTickCount64;
  MultiplyInto(A, B, PortableDestination);
  ColdPortable := GetTickCount64 - Started;
  MultiplyInto(A, B, PortableDestination);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    MultiplyInto(A, B, PortableDestination);
  WarmPortable := GetTickCount64 - Started;
  Checksum := PortableDestination[0, 0] +
    PortableDestination[RowsA - 1, ColsB - 1];
  WritePerformanceRow('dense-gemm-large-portable', 'dense', 'large',
    'double', '127x129x65', ColdPortable, WarmPortable, WarmIterations, 0,
    RetainedHeapDelta(HeapBaseline),
    RowsA * Inner + Inner * ColsB + RowsA * ColsB, RowsA * ColsB,
    Checksum, 1.0E-12, 'prepared_inputs_destination');

  Started := GetTickCount64;
  MultiplyAutoInto(A, B, AutomaticDestination);
  ColdAutomatic := GetTickCount64 - Started;
  MultiplyAutoInto(A, B, AutomaticDestination);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    MultiplyAutoInto(A, B, AutomaticDestination);
  WarmAutomatic := GetTickCount64 - Started;
  if Abs(AutomaticDestination[0, 0] - PortableDestination[0, 0]) > 1.0E-12 then
    Halt(20);
  WritePerformanceRow('dense-gemm-large-auto', 'dense', 'large', 'double',
    '127x129x65', ColdAutomatic, WarmAutomatic, WarmIterations, 0,
    RetainedHeapDelta(HeapBaseline),
    RowsA * Inner + Inner * ColsB + RowsA * ColsB, RowsA * ColsB,
    AutomaticDestination[0, 0] +
      AutomaticDestination[RowsA - 1, ColsB - 1],
    1.0E-12, 'prepared_inputs_destination');
end;

procedure FillFFTInput(var Values: TComplexArray);
var
  I: SizeInt;
begin
  for I := 0 to High(Values) do
    Values[I] := TComplex.Create(Sin(I * 0.01), Cos(I * 0.03));
end;

procedure BenchmarkDSPSmall;
const
  WarmIterations = 100000;
var
  A, B, ResultValues: TDoubleArray;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
  Checksum: Double;
begin
  A := TDoubleArray.Create(1, 2, 3, 4, 5, 6, 7, 8);
  B := TDoubleArray.Create(0.25, 0.5, 0.25);
  Started := GetTickCount64;
  ResultValues := TDSPKit.Convolve(A, B, cmDirect);
  ColdMilliseconds := GetTickCount64 - Started;
  ResultValues := TDSPKit.Convolve(A, B, cmDirect);
  ResultValues := nil;
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    ResultValues := TDSPKit.Convolve(A, B, cmDirect);
  WarmMilliseconds := GetTickCount64 - Started;
  Checksum := ResultValues[4];
  ResultValues := nil;
  WritePerformanceRow('dsp-convolution-small-direct', 'dsp', 'small',
    'double', '8x3', ColdMilliseconds, WarmMilliseconds, WarmIterations,
    WarmIterations, RetainedHeapDelta(HeapBaseline), 10, 0, Checksum,
    1.0E-12, 'prepared_signals_allocating_result');
end;

procedure BenchmarkDSPLarge;
const
  N = 65536;
  WarmIterations = 5;
var
  InputValues, Work, Candidate: TComplexArray;
  Started, ColdBaseline, ColdCandidate, WarmBaseline, WarmCandidate,
    HeapBaseline: QWord;
  Iteration: SizeInt;
  BaselineChecksum, CandidateChecksum: Double;
begin
  SetLength(InputValues, N);
  FillFFTInput(InputValues);

  Started := GetTickCount64;
  Work := Copy(InputValues);
  TSignalKit.FFT(Work);
  ColdBaseline := GetTickCount64 - Started;
  Work := Copy(InputValues);
  TSignalKit.FFT(Work);
  Work := nil;
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
  begin
    Work := Copy(InputValues);
    TSignalKit.FFT(Work);
  end;
  WarmBaseline := GetTickCount64 - Started;
  BaselineChecksum := Work[1].Magnitude;
  Work := nil;
  WritePerformanceRow('dsp-fft-large-baseline', 'dsp', 'large', 'double_complex',
    '65536', ColdBaseline, WarmBaseline, WarmIterations, WarmIterations,
    RetainedHeapDelta(HeapBaseline), N, 0, BaselineChecksum, 2.0E-8,
    'prepared_input_copy_plus_in_place_fft');

  Started := GetTickCount64;
  Candidate := TDSPKit.Transform(InputValues);
  ColdCandidate := GetTickCount64 - Started;
  Candidate := TDSPKit.Transform(InputValues);
  Candidate := nil;
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    Candidate := TDSPKit.Transform(InputValues);
  WarmCandidate := GetTickCount64 - Started;
  CandidateChecksum := Candidate[1].Magnitude;
  if Abs(CandidateChecksum - BaselineChecksum) > 2.0E-8 then
    Halt(21);
  Candidate := nil;
  WritePerformanceRow('dsp-fft-large-candidate', 'dsp', 'large',
    'double_complex', '65536', ColdCandidate, WarmCandidate, WarmIterations,
    WarmIterations, RetainedHeapDelta(HeapBaseline), N, 0,
    CandidateChecksum, 2.0E-8, 'prepared_input_allocating_transform');
end;

procedure BenchmarkModellingSmall;
const
  WarmIterations = 100000;
var
  Integration: TIntegrationResult;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
begin
  Started := GetTickCount64;
  Integration := TModellingKit.IntegrateAdaptive(@SineIntegrand, 0.0, Pi);
  ColdMilliseconds := GetTickCount64 - Started;
  Integration := TModellingKit.IntegrateAdaptive(@SineIntegrand, 0.0, Pi);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    Integration := TModellingKit.IntegrateAdaptive(@SineIntegrand, 0.0, Pi);
  WarmMilliseconds := GetTickCount64 - Started;
  WritePerformanceRow('modelling-integral-small', 'modelling', 'small',
    'double', 'scalar_interval', ColdMilliseconds, WarmMilliseconds,
    WarmIterations, 0, RetainedHeapDelta(HeapBaseline),
    Integration.Intervals, 0, Integration.Value, 1.0E-10,
    'sin_0_pi_default_tolerances');
end;

procedure BenchmarkModellingLarge;
const
  Samples = 100000;
  WarmIterations = 3;
var
  LowerBounds, UpperBounds: TDoubleArray;
  Integration: TIntegrationResult;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
begin
  LowerBounds := TDoubleArray.Create(0.0, 0.0);
  UpperBounds := TDoubleArray.Create(1.0, 1.0);
  Started := GetTickCount64;
  Integration := TModellingKit.IntegrateQuasiMonteCarlo(@PlaneIntegrand,
    LowerBounds, UpperBounds, Samples, 7);
  ColdMilliseconds := GetTickCount64 - Started;
  Integration := TModellingKit.IntegrateQuasiMonteCarlo(@PlaneIntegrand,
    LowerBounds, UpperBounds, Samples, 7);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    Integration := TModellingKit.IntegrateQuasiMonteCarlo(@PlaneIntegrand,
      LowerBounds, UpperBounds, Samples, 7);
  WarmMilliseconds := GetTickCount64 - Started;
  WritePerformanceRow('modelling-qmc-large', 'modelling', 'large', 'double',
    '2d_100000_samples', ColdMilliseconds, WarmMilliseconds, WarmIterations,
    WarmIterations, RetainedHeapDelta(HeapBaseline), 2, 0,
    Integration.Value, 5.0E-5, 'halton_seed_7_prepared_bounds');
end;

procedure AddStatisticsFixture(var Statistics: TOnlineStatistics;
  const Count: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to Count - 1 do
    Statistics.Add(Sin(I * 0.001) + I * 1.0E-8);
end;

procedure BenchmarkStatisticsSmall;
const
  N = 64;
  WarmIterations = 5000;
var
  Statistics: TOnlineStatistics;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
begin
  Statistics := TOnlineStatistics.Create;
  Started := GetTickCount64;
  AddStatisticsFixture(Statistics, N);
  ColdMilliseconds := GetTickCount64 - Started;
  Statistics := TOnlineStatistics.Create;
  AddStatisticsFixture(Statistics, N);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
  begin
    Statistics := TOnlineStatistics.Create;
    AddStatisticsFixture(Statistics, N);
  end;
  WarmMilliseconds := GetTickCount64 - Started;
  WritePerformanceRow('statistics-online-small', 'statistics', 'small',
    'double', '64_values', ColdMilliseconds, WarmMilliseconds,
    WarmIterations, 0, RetainedHeapDelta(HeapBaseline), 6, 0,
    Statistics.Mean + Statistics.PopulationVariance, 1.0E-12,
    'fresh_record_per_iteration');
end;

procedure BenchmarkStatisticsLarge;
const
  N = 2000000;
  WarmIterations = 3;
var
  Statistics: TOnlineStatistics;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
begin
  Statistics := TOnlineStatistics.Create;
  Started := GetTickCount64;
  AddStatisticsFixture(Statistics, N);
  ColdMilliseconds := GetTickCount64 - Started;
  Statistics := TOnlineStatistics.Create;
  AddStatisticsFixture(Statistics, N);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
  begin
    Statistics := TOnlineStatistics.Create;
    AddStatisticsFixture(Statistics, N);
  end;
  WarmMilliseconds := GetTickCount64 - Started;
  WritePerformanceRow('statistics-online-large', 'statistics', 'large',
    'double', '2000000_values', ColdMilliseconds, WarmMilliseconds,
    WarmIterations, 0, RetainedHeapDelta(HeapBaseline), 6, 0,
    Statistics.Mean + Statistics.PopulationVariance, 1.0E-12,
    'fresh_record_per_iteration');
end;

procedure FillAnalysisData(const Data: IDenseDoubleMatrix);
var
  I, J: SizeInt;
begin
  for I := 0 to Data.Rows - 1 do
    for J := 0 to Data.Cols - 1 do
      Data[I, J] := Sin((I + 1) * (J + 2) * 0.003) +
        0.05 * Cos((I + J + 1) * 0.017);
end;

procedure BenchmarkAnalysis(const Identifier, Scale, Shape: string;
  const Rows, Cols, Components, WarmIterations: SizeInt);
var
  Data: IDenseDoubleMatrix;
  PCAResult: TPCAResult;
  Started, ColdMilliseconds, WarmMilliseconds, HeapBaseline: QWord;
  Iteration: SizeInt;
  Checksum: Double;
begin
  Data := TDenseDoubleMatrix.Zeros(Rows, Cols);
  FillAnalysisData(Data);
  Started := GetTickCount64;
  PCAResult := TAnalysisKit.PCA(Data, Components);
  ColdMilliseconds := GetTickCount64 - Started;
  PCAResult := TAnalysisKit.PCA(Data, Components);
  PCAResult := Default(TPCAResult);
  HeapBaseline := GetHeapStatus.TotalAllocated;
  Started := GetTickCount64;
  for Iteration := 1 to WarmIterations do
    PCAResult := TAnalysisKit.PCA(Data, Components);
  WarmMilliseconds := GetTickCount64 - Started;
  Checksum := PCAResult.ExplainedRatio[0];
  PCAResult := Default(TPCAResult);
  WritePerformanceRow(Identifier, 'data_analysis', Scale, 'double', Shape,
    ColdMilliseconds, WarmMilliseconds, WarmIterations, 6 * WarmIterations,
    RetainedHeapDelta(HeapBaseline),
    Rows * Cols + Rows * Components + Cols * Components, Rows * Cols,
    Checksum, 1.0E-10, 'prepared_dense_input_allocating_pca');
end;

procedure RunV195PerformanceBenchmarks;
begin
  Writeln('mathlib-fp 1.9.5 canonical performance evidence');
  BenchmarkDenseSmall;
  BenchmarkDenseLarge;
  BenchmarkDSPSmall;
  BenchmarkDSPLarge;
  BenchmarkModellingSmall;
  BenchmarkModellingLarge;
  BenchmarkStatisticsSmall;
  BenchmarkStatisticsLarge;
  BenchmarkAnalysis('data-analysis-pca-small', 'small', '32x4_components2',
    32, 4, 2, 500);
  BenchmarkAnalysis('data-analysis-pca-large', 'large',
    '1024x8_components4', 1024, 8, 4, 3);
end;

end.
