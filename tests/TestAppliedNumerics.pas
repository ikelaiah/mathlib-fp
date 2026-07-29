unit TestAppliedNumerics;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, MathBase.Complex, MathBase.Random,
  MathBase.Interchange,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels,
  EngineeringLib.Signal, EngineeringLib.DSP,
  StatsLib.Streaming, MLLib.Analysis, TimeSeriesLib.StateSpace;

type
  TAppliedNumericsTest = class(TTestCase)
  published
    procedure TestLocalRandomStateAndSplit;
    procedure TestLocalRandomDoesNotTouchGlobalState;
    procedure TestOnlineStatisticsAndMerge;
    procedure TestWeightedAndNonFinitePolicies;
    procedure TestArbitraryFFTReferenceAndRoundTrip;
    procedure TestFFT2DAndSinglePrecision;
    procedure TestConvolutionCorrelationAndResampling;
    procedure TestStreamingFiltersBoundedState;
    procedure TestSpectralWorkflows;
    procedure TestInvariantAndOpenInterchange;
    procedure TestBinaryRoundTripsAndRandomState;
    procedure TestBinaryRejectsCorruptAndOversizedInput;
    procedure TestTypedPCAAndKMeansPlusPlus;
    procedure TestValidationLDAAndKDTree;
    procedure TestScalarKalmanStateAndForecast;
    procedure TestPortableBlockedKernelOracle;
  end;

implementation

procedure TAppliedNumericsTest.TestLocalRandomStateAndSplit;
const
  ReferenceSequence: array[0..4] of QWord = (
    QWord(15127205273500847298),
    QWord(16265768176396019016),
    QWord(1514321867679316104),
    QWord(9853693475100939714),
    QWord(16001046604883718113)
  );
var
  A, B, Child, Reference: TLocalRandom;
  Saved: TRandomState;
  I: Integer;
  Expected: QWord;
begin
  Reference := TLocalRandom.Seeded(123456789);
  for I := 0 to High(ReferenceSequence) do
    AssertTrue('xoshiro256** reference vector changed',
      Reference.NextUInt64 = ReferenceSequence[I]);

  A := TLocalRandom.Seeded(123456789);
  B := TLocalRandom.Seeded(123456789);
  for I := 1 to 16 do
    AssertTrue('equal seeds reproduce UInt64 sequence',
      A.NextUInt64 = B.NextUInt64);

  Saved := A.GetState;
  Expected := A.NextUInt64;
  A.SetState(Saved);
  AssertTrue('restored state reproduces next value',
    Expected = A.NextUInt64);

  Child := A.Split;
  AssertFalse('jumped parent and child streams diverge immediately',
    A.NextUInt64 = Child.NextUInt64);
  for I := 1 to 100 do
    AssertTrue('bounded integer result',
      Child.NextInteger(7) < 7);
end;

procedure TAppliedNumericsTest.TestLocalRandomDoesNotTouchGlobalState;
var
  Local: TLocalRandom;
  BeforeValue, AfterValue: Integer;
begin
  RandSeed := 24680;
  BeforeValue := Random(1000000);
  RandSeed := 24680;
  Local := TLocalRandom.Seeded(42);
  Local.NextUInt64;
  Local.NextNormal;
  AfterValue := Random(1000000);
  AssertEquals('local RNG leaves RTL global state unchanged',
    BeforeValue, AfterValue);
end;

procedure TAppliedNumericsTest.TestOnlineStatisticsAndMerge;
var
  Whole, Left, Right: TOnlineStatistics;
  I: Integer;
begin
  Whole := TOnlineStatistics.Create;
  Left := TOnlineStatistics.Create;
  Right := TOnlineStatistics.Create;
  for I := 1 to 10 do
  begin
    Whole.Add(I);
    if I <= 4 then
      Left.Add(I)
    else
      Right.Add(I);
  end;
  Left.Merge(Right);

  AssertEquals('count', QWord(10), Whole.Count);
  AssertEquals('mean', 5.5, Whole.Mean, 1E-15);
  AssertEquals('population variance', 8.25,
    Whole.PopulationVariance, 1E-14);
  AssertEquals('sample variance', 9.166666666666666,
    Whole.SampleVariance, 1E-14);
  AssertEquals('merged mean', Whole.Mean, Left.Mean, 1E-15);
  AssertEquals('merged M2-derived variance', Whole.SampleVariance,
    Left.SampleVariance, 1E-14);
  AssertEquals('minimum', 1.0, Left.Minimum, 0.0);
  AssertEquals('maximum', 10.0, Left.Maximum, 0.0);
end;

procedure TAppliedNumericsTest.TestWeightedAndNonFinitePolicies;
var
  Weighted, Ignoring, Overflowing: TOnlineStatistics;
  Failed: Boolean;
begin
  Weighted := TOnlineStatistics.Create;
  Weighted.AddWeighted(10.0, 1.0);
  Weighted.AddWeighted(20.0, 3.0);
  AssertEquals('weighted mean', 17.5, Weighted.Mean, 1E-15);
  AssertEquals('weight sum', 4.0, Weighted.WeightSum, 0.0);

  Ignoring := TOnlineStatistics.Create(nfpIgnore);
  Ignoring.Add(2.0);
  Ignoring.Add(NaN);
  Ignoring.Add(Infinity);
  AssertEquals('ignored non-finite values do not change count',
    QWord(1), Ignoring.Count);

  Failed := False;
  try
    Weighted.Add(NaN);
  except
    on EStreamingStatsError do Failed := True;
  end;
  AssertTrue('reject policy names non-finite input', Failed);

  Overflowing := TOnlineStatistics.Create;
  Overflowing.AddWeighted(1.0, 1E154);
  Failed := False;
  try
    Overflowing.AddWeighted(2.0, 1E154);
  except
    on EStreamingStatsError do Failed := True;
  end;
  AssertTrue('weight-square accumulation overflow is rejected', Failed);
  AssertEquals('overflow failure leaves count unchanged',
    QWord(1), Overflowing.Count);
  AssertEquals('overflow failure leaves mean unchanged',
    1.0, Overflowing.Mean, 0.0);

  Overflowing := TOnlineStatistics.Create;
  Overflowing.Add(MaxDouble);
  Failed := False;
  try
    Overflowing.Add(-MaxDouble);
  except
    on EStreamingStatsError do Failed := True;
  end;
  AssertTrue('moment arithmetic overflow uses the typed error', Failed);
  AssertEquals('moment overflow leaves count unchanged',
    QWord(1), Overflowing.Count);
  AssertEquals('moment overflow leaves mean unchanged',
    MaxDouble, Overflowing.Mean, 0.0);
end;

procedure TAppliedNumericsTest.TestArbitraryFFTReferenceAndRoundTrip;
var
  Input, Fast, Reference, RoundTrip: TComplexArray;
  I: Integer;
begin
  SetLength(Input, 7);
  for I := 0 to High(Input) do
    Input[I] := TComplex.Create(Sin(I * 0.3), Cos(I * 0.17));
  Fast := TDSPKit.Transform(Input);
  Reference := TDSPKit.DFTReference(Input);
  for I := 0 to High(Input) do
  begin
    AssertEquals('Bluestein/reference real', Reference[I].Re,
      Fast[I].Re, 2E-12);
    AssertEquals('Bluestein/reference imaginary', Reference[I].Im,
      Fast[I].Im, 2E-12);
  end;
  RoundTrip := TDSPKit.DFTReference(Fast, True);
  for I := 0 to High(Input) do
  begin
    AssertEquals('reference DFT round trip real', Input[I].Re,
      RoundTrip[I].Re, 2E-12);
    AssertEquals('reference DFT round trip imaginary', Input[I].Im,
      RoundTrip[I].Im, 2E-12);
  end;
  RoundTrip := TDSPKit.Transform(Fast, True);
  for I := 0 to High(Input) do
  begin
    AssertEquals('arbitrary FFT round trip real', Input[I].Re,
      RoundTrip[I].Re, 2E-12);
    AssertEquals('arbitrary FFT round trip imaginary', Input[I].Im,
      RoundTrip[I].Im, 2E-12);
  end;
end;

procedure TAppliedNumericsTest.TestFFT2DAndSinglePrecision;
var
  Input, Spectrum, RoundTrip: IDenseComplexMatrix;
  SingleInput, SingleSpectrum, SingleRoundTrip: TSingleComplexArray;
  Row, Column, I: Integer;
begin
  Input := TDenseComplexMatrix.Zeros(3, 5);
  for Row := 0 to Input.Rows - 1 do
    for Column := 0 to Input.Cols - 1 do
      Input[Row, Column] := TComplex.Create(Row * 10 + Column, Row - Column);
  Spectrum := TDSPKit.Transform2D(Input);
  RoundTrip := TDSPKit.Transform2D(Spectrum, True);
  for Row := 0 to Input.Rows - 1 do
    for Column := 0 to Input.Cols - 1 do
    begin
      AssertEquals('2-D round trip real', Input[Row, Column].Re,
        RoundTrip[Row, Column].Re, 2E-11);
      AssertEquals('2-D round trip imaginary', Input[Row, Column].Im,
        RoundTrip[Row, Column].Im, 2E-11);
    end;

  SetLength(SingleInput, 5);
  for I := 0 to High(SingleInput) do
    SingleInput[I] := TSingleComplex.Create(I + 0.25, 0.5 - I);
  SingleSpectrum := TDSPKit.Transform(SingleInput);
  SingleRoundTrip := TDSPKit.Transform(SingleSpectrum, True);
  for I := 0 to High(SingleInput) do
  begin
    AssertEquals('single real round trip', SingleInput[I].Re,
      SingleRoundTrip[I].Re, 2E-5);
    AssertEquals('single imaginary round trip', SingleInput[I].Im,
      SingleRoundTrip[I].Im, 2E-5);
  end;
end;

procedure TAppliedNumericsTest.TestConvolutionCorrelationAndResampling;
var
  A, B, DirectValue, FFTValue, Correlation, Resampled: TDoubleArray;
  I: Integer;
begin
  A := TDoubleArray.Create(1, 2, 3, 4, 5);
  B := TDoubleArray.Create(2, -1, 0.5);
  DirectValue := TDSPKit.Convolve(A, B, cmDirect);
  FFTValue := TDSPKit.Convolve(A, B, cmFFT);
  AssertEquals('linear convolution length', 7, Length(DirectValue));
  for I := 0 to High(DirectValue) do
    AssertEquals('direct and FFT convolution', DirectValue[I],
      FFTValue[I], 1E-12);
  Correlation := TDSPKit.Correlate(
    TDoubleArray.Create(1, 2, 3), TDoubleArray.Create(1, 2), cmDirect);
  AssertEquals('correlation first lag', 2.0, Correlation[0], 0.0);
  AssertEquals('correlation zero lag', 5.0, Correlation[1], 0.0);
  AssertEquals('correlation last lag', 3.0, Correlation[3], 0.0);

  Resampled := TDSPKit.ResampleLinear(TDoubleArray.Create(0, 10), 5);
  AssertEquals('resample first endpoint', 0.0, Resampled[0], 0.0);
  AssertEquals('resample midpoint', 5.0, Resampled[2], 0.0);
  AssertEquals('resample last endpoint', 10.0, Resampled[4], 0.0);
  AssertEquals('rational resample length', 8,
    Length(TDSPKit.ResampleRational(A, 3, 2)));
end;

procedure TAppliedNumericsTest.TestStreamingFiltersBoundedState;
var
  FilterA, FilterB, OverflowFilter: TStreamingFIR;
  Biquad: TStreamingBiquad;
  First, Second, Combined, DirectValue, StepResponse: TDoubleArray;
  Coefficients: TBiquadCoefficients;
  Failed: Boolean;
  I: Integer;
begin
  FilterA := TStreamingFIR.Create(TDoubleArray.Create(0.25, 0.5, 0.25));
  FilterB := FilterA;
  First := FilterA.ProcessBlock(TDoubleArray.Create(1, 2, 3));
  Second := FilterA.ProcessBlock(TDoubleArray.Create(4, 5));
  AssertEquals('bounded state is coefficient length minus one',
    2, FilterA.StateSize);
  AssertEquals('copied state evolves independently', 0.0,
    FilterB.History[0], 0.0);
  SetLength(Combined, Length(First) + Length(Second));
  for I := 0 to High(First) do
    Combined[I] := First[I];
  for I := 0 to High(Second) do
    Combined[Length(First) + I] := Second[I];
  DirectValue := TDSPKit.Convolve(TDoubleArray.Create(1, 2, 3, 4, 5),
    TDoubleArray.Create(0.25, 0.5, 0.25), cmDirect);
  for I := 0 to High(Combined) do
    AssertEquals('chunked FIR agrees with causal direct prefix',
      DirectValue[I], Combined[I], 1E-15);

  OverflowFilter := TStreamingFIR.Create(
    TDoubleArray.Create(MaxDouble, 1.0));
  Failed := False;
  try
    OverflowFilter.ProcessBlock(TDoubleArray.Create(2.0));
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('FIR numerical overflow is rejected', Failed);
  AssertEquals('failed FIR block leaves history unchanged',
    0.0, OverflowFilter.History[0], 0.0);

  Coefficients := TDSPKit.DesignButterworthLowPass(0.1);
  Biquad := TStreamingBiquad.Create(Coefficients);
  SetLength(Combined, 64);
  for I := 0 to High(Combined) do Combined[I] := 1.0;
  StepResponse := Biquad.ProcessBlock(Combined);
  AssertTrue('Butterworth response remains finite',
    not IsNan(StepResponse[High(StepResponse)]) and
    not IsInfinite(StepResponse[High(StepResponse)]));
  AssertEquals('Butterworth low-pass converges to unit DC gain',
    1.0, StepResponse[High(StepResponse)], 2E-4);
end;

procedure TAppliedNumericsTest.TestSpectralWorkflows;
const
  N = 96;
  Frequency = 12.0;
var
  Signal, Shifted: TDoubleArray;
  Estimate: TSpectralEstimate;
  Cross: TCrossSpectralEstimate;
  STFT: IDenseComplexMatrix;
  Analytic: TComplexArray;
  I, Peak: Integer;
  Failed: Boolean;
begin
  SetLength(Signal, N);
  SetLength(Shifted, N);
  for I := 0 to N - 1 do
  begin
    Signal[I] := Sin(2 * Pi * Frequency * I / N);
    Shifted[I] := Sin(2 * Pi * Frequency * I / N + 0.4);
  end;
  Estimate := TDSPKit.Welch(Signal, 24, 12, N);
  Peak := 1;
  for I := 2 to High(Estimate.Power) do
    if Estimate.Power[I] > Estimate.Power[Peak] then Peak := I;
  AssertEquals('Welch peak frequency', Frequency,
    Estimate.Frequencies[Peak], 1E-12);

  STFT := TDSPKit.ShortTimeFourierTransform(Signal, 24, 12);
  AssertEquals('STFT frames', 7, STFT.Rows);
  AssertEquals('STFT bins', 24, STFT.Cols);
  Analytic := TDSPKit.AnalyticSignal(Signal);
  AssertEquals('analytic signal preserves sample count', N, Length(Analytic));
  AssertEquals('analytic real part reproduces input', Signal[17],
    Analytic[17].Re, 2E-12);

  Cross := TDSPKit.CrossSpectrum(Signal, Shifted, 24, 12, N);
  Peak := 1;
  for I := 2 to High(Cross.Coherence) do
    if Cross.CrossPower[I].Magnitude > Cross.CrossPower[Peak].Magnitude then
      Peak := I;
  AssertTrue('coherent sinusoids have near-unit coherence',
    Cross.Coherence[Peak] > 0.99);

  Failed := False;
  try
    TDSPKit.Periodogram(TDoubleArray.Create(1.0, 2.0), 1.0, wtHann);
  except
    on EDSPError do Failed := True;
  end;
  AssertTrue('zero-energy window is rejected', Failed);
end;

procedure TAppliedNumericsTest.TestInvariantAndOpenInterchange;
var
  VectorValue, ParsedVector: TDoubleArray;
  ComplexValue: TComplex;
  MatrixValue, ParsedMatrix: IDenseDoubleMatrix;
  Stream: TMemoryStream;
  Text: string;
  I: Integer;
begin
  ComplexValue := ParseComplexInvariant(
    ComplexToInvariant(TComplex.Create(-1.25, 2.5)));
  AssertEquals('complex invariant real', -1.25, ComplexValue.Re, 0.0);
  AssertEquals('complex invariant imaginary', 2.5, ComplexValue.Im, 0.0);
  VectorValue := TDoubleArray.Create(1.25, -2.5, 3E-100);
  ParsedVector := ParseDoubleVectorInvariant(
    DoubleVectorToInvariant(VectorValue));
  for I := 0 to High(VectorValue) do
    AssertEquals('vector text round trip', VectorValue[I],
      ParsedVector[I], 0.0);

  MatrixValue := TDenseDoubleMatrix.FromValues(2, 3,
    [1.0, 2.5, -3.0, 4E20, 5E-20, 6.0]);
  ParsedMatrix := ParseDenseMatrixInvariant(
    DenseMatrixToInvariant(MatrixValue));
  AssertEquals('matrix text shape rows', 2, ParsedMatrix.Rows);
  AssertEquals('matrix text value', MatrixValue[1, 1],
    ParsedMatrix[1, 1], 0.0);

  Stream := TMemoryStream.Create;
  try
    WriteDelimitedMatrix(Stream, MatrixValue, ';');
    Stream.Position := 0;
    ParsedMatrix := ReadDelimitedMatrix(Stream, ';');
    AssertEquals('delimited value', -3.0, ParsedMatrix[0, 2], 0.0);
    Stream.Clear;
    WriteMatrixMarket(Stream, MatrixValue);
    Stream.Position := 0;
    ParsedMatrix := ReadMatrixMarketDouble(Stream);
    AssertEquals('Matrix Market column-major round trip',
      4E20, ParsedMatrix[1, 0], 0.0);
    Text := Summarize(ParsedMatrix, 1, 2);
    AssertTrue('summary includes shape metadata',
      Pos('shape=2x3', Text) > 0);
  finally
    Stream.Free;
  end;
end;

procedure TAppliedNumericsTest.TestBinaryRoundTripsAndRandomState;
var
  Stream: TMemoryStream;
  MatrixValue, MatrixRoundTrip: IDenseDoubleMatrix;
  ComplexValues, ComplexRoundTrip: TComplexArray;
  RandomA, RandomB: TLocalRandom;
  State: TRandomState;
  I: Integer;
begin
  Stream := TMemoryStream.Create;
  try
    MatrixValue := TDenseDoubleMatrix.FromValues(2, 2,
      [1.0, -2.0, 3.5, 4E100]);
    SaveBinary(Stream, MatrixValue);
    Stream.Position := 0;
    MatrixRoundTrip := LoadDoubleMatrixBinary(Stream);
    AssertEquals('binary matrix rows', 2, MatrixRoundTrip.Rows);
    AssertEquals('binary matrix exact value', 4E100,
      MatrixRoundTrip[1, 1], 0.0);

    Stream.Clear;
    ComplexValues := TComplexArray.Create(
      TComplex.Create(1.5, -2.25), TComplex.Create(3E-80, 4E80));
    SaveBinary(Stream, ComplexValues);
    Stream.Position := 0;
    ComplexRoundTrip := LoadComplexVectorBinary(Stream);
    for I := 0 to High(ComplexValues) do
    begin
      AssertEquals('binary complex real', ComplexValues[I].Re,
        ComplexRoundTrip[I].Re, 0.0);
      AssertEquals('binary complex imaginary', ComplexValues[I].Im,
        ComplexRoundTrip[I].Im, 0.0);
    end;

    RandomA := TLocalRandom.Seeded(987654321);
    RandomA.NextUInt64;
    State := RandomA.GetState;
    Stream.Clear;
    SaveRandomStateBinary(Stream, State);
    Stream.Position := 0;
    RandomB.SetState(LoadRandomStateBinary(Stream));
    AssertTrue('serialized RNG state reproduces next value',
      RandomA.NextUInt64 = RandomB.NextUInt64);
  finally
    Stream.Free;
  end;
end;

procedure TAppliedNumericsTest.TestBinaryRejectsCorruptAndOversizedInput;
var
  Stream: TMemoryStream;
  Value: Byte;
  InvalidState: TRandomState;
  Failed: Boolean;
begin
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, TDoubleArray.Create(1.0, 2.0, 3.0));
    Stream.Position := Stream.Size - 1;
    Stream.ReadBuffer(Value, 1);
    Value := Value xor $01;
    Stream.Position := Stream.Size - 1;
    Stream.WriteBuffer(Value, 1);
    Stream.Position := 0;
    Failed := False;
    try
      LoadDoubleVectorBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('checksum rejects corrupt payload', Failed);

    Stream.Clear;
    SaveBinary(Stream, TDoubleArray.Create(1.0));
    { Header byte 19 is the high byte of the little-endian row count. }
    Value := $7F;
    Stream.Position := 19;
    Stream.WriteBuffer(Value, 1);
    Stream.Position := 0;
    Failed := False;
    try
      LoadDoubleVectorBinary(Stream, 10);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('declared oversized input is rejected before payload use',
      Failed);

    Stream.Clear;
    SaveBinary(Stream, TDoubleArray.Create(1.0));
    Value := $7F;
    Stream.Position := 8;
    Stream.WriteBuffer(Value, 1);
    Stream.Position := 0;
    Failed := False;
    try
      LoadDoubleVectorBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('incompatible version is rejected before result creation',
      Failed);

    Stream.Clear;
    SaveBinary(Stream, TDoubleArray.Create(1.0));
    Value := 1;
    Stream.Position := 11;
    Stream.WriteBuffer(Value, 1);
    Stream.Position := 0;
    Failed := False;
    try
      LoadDoubleVectorBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('nonzero reserved header is rejected', Failed);

    Stream.Clear;
    SaveBinary(Stream, TDoubleArray.Create(1.0, 2.0));
    Stream.Size := Stream.Size - 3;
    Stream.Position := 0;
    Failed := False;
    try
      LoadDoubleVectorBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('truncated payload is rejected before result creation',
      Failed);

    FillChar(InvalidState, SizeOf(InvalidState), 0);
    Stream.Clear;
    Failed := False;
    try
      SaveRandomStateBinary(Stream, InvalidState);
    except
      on ERandomStateError do Failed := True;
    end;
    AssertTrue('invalid all-zero random state is not persisted', Failed);
    AssertEquals('invalid state leaves stream unchanged',
      Int64(0), Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TAppliedNumericsTest.TestTypedPCAAndKMeansPlusPlus;
var
  Data: IDenseDoubleMatrix;
  PCAResult: MLLib.Analysis.TPCAResult;
  ClustersA, ClustersB: TKMeansPlusPlusResult;
  I: Integer;
begin
  Data := TDenseDoubleMatrix.FromValues(6, 2,
    [1.0, 2.1, 2.0, 4.0, 3.0, 6.1,
     4.0, 7.9, 5.0, 10.2, 6.0, 12.0]);
  PCAResult := TAnalysisKit.PCA(Data, 2);
  AssertEquals('PCA component rows', 2, PCAResult.Components.Rows);
  AssertEquals('PCA score rows', 6, PCAResult.Scores.Rows);
  AssertTrue('correlated fixture is dominated by first component',
    PCAResult.ExplainedRatio[0] > 0.99);
  AssertEquals('complete PCA ratio', 1.0,
    PCAResult.ExplainedRatio[0] + PCAResult.ExplainedRatio[1], 1E-12);

  Data := TDenseDoubleMatrix.FromValues(6, 2,
    [0.0, 0.0, 0.1, -0.1, -0.1, 0.1,
     10.0, 10.0, 10.1, 9.9, 9.9, 10.1]);
  ClustersA := TAnalysisKit.KMeansPlusPlus(Data, 2, 1234);
  ClustersB := TAnalysisKit.KMeansPlusPlus(Data, 2, 1234);
  AssertTrue('k-means++ converges', ClustersA.Converged);
  AssertTrue('separated blobs receive distinct labels',
    ClustersA.Labels[0] <> ClustersA.Labels[3]);
  AssertEquals('first centroid is the first blob mean', 0.0,
    ClustersA.Centroids[ClustersA.Labels[0], 0], 1E-12);
  AssertEquals('second centroid is the second blob mean', 10.0,
    ClustersA.Centroids[ClustersA.Labels[3], 0], 1E-12);
  for I := 0 to High(ClustersA.Labels) do
    AssertEquals('seeded k-means++ is reproducible',
      ClustersA.Labels[I], ClustersB.Labels[I]);
end;

procedure TAppliedNumericsTest.TestValidationLDAAndKDTree;
var
  Data: IDenseDoubleMatrix;
  Labels, Predictions, Seen, Folds: TIntegerArray;
  Split: TValidationSplit;
  Model: TBinaryLDAResult;
  Tree: TKDTree;
  Neighbors: TNeighborResult;
  I: Integer;
begin
  Split := TAnalysisKit.CreateValidationSplit(20, 0.25, 99);
  AssertEquals('validation count', 5, Length(Split.ValidationRows));
  AssertEquals('training count', 15, Length(Split.TrainingRows));
  SetLength(Seen, 20);
  for I := 0 to High(Split.ValidationRows) do
    Inc(Seen[Split.ValidationRows[I]]);
  for I := 0 to High(Split.TrainingRows) do
    Inc(Seen[Split.TrainingRows[I]]);
  for I := 0 to High(Seen) do
    AssertEquals('split covers each row exactly once', 1, Seen[I]);
  Folds := TAnalysisKit.KFoldAssignments(20, 4, 99);
  for I := 0 to High(Folds) do
    AssertTrue('fold assignment is bounded',
      (Folds[I] >= 0) and (Folds[I] < 4));

  Data := TDenseDoubleMatrix.FromValues(6, 2,
    [-2.0, -1.0, -1.5, -2.0, -1.0, -1.0,
      1.0,  1.0,  1.5,  2.0,  2.0,  1.0]);
  Labels := TIntegerArray.Create(0, 0, 0, 1, 1, 1);
  Model := TAnalysisKit.FitBinaryLDA(Data, Labels, 0, 1, 1E-8);
  Predictions := TAnalysisKit.PredictBinaryLDA(Model, Data);
  for I := 0 to High(Labels) do
    AssertEquals('LDA separates training fixture', Labels[I], Predictions[I]);

  Tree := TKDTree.Create(Data);
  try
    Neighbors := Tree.Query(TDoubleArray.Create(1.4, 1.8), 2);
    AssertEquals('nearest point index', 4, Neighbors.Indices[0]);
    AssertEquals('second nearest point index', 3, Neighbors.Indices[1]);
    AssertTrue('neighbour distances are ordered',
      Neighbors.SquaredDistances[0] <= Neighbors.SquaredDistances[1]);
  finally
    Tree.Free;
  end;
end;

procedure TAppliedNumericsTest.TestScalarKalmanStateAndForecast;
var
  Configuration: TScalarKalmanConfiguration;
  FilterValue: TScalarKalmanFilter;
  Series: TKalmanSeriesResult;
  Forecast: TKalmanForecast;
  BeforeEstimate: Double;
  Failed: Boolean;
begin
  Configuration := TScalarKalmanConfiguration.Create(1.0, 1.0, 0.01, 0.25);
  FilterValue := TScalarKalmanFilter.Create(Configuration, 0.0, 1.0);
  Series := FilterValue.Process(TDoubleArray.Create(
    9.5, 10.5, 9.8, 10.2, 10.0, 10.1));
  AssertEquals('Kalman result count', 6, Length(Series.Estimates));
  AssertTrue('filter estimate approaches constant signal',
    Abs(FilterValue.Estimate - 10.0) < 0.6);
  AssertTrue('posterior variance remains non-negative',
    FilterValue.Variance >= 0.0);
  AssertTrue('finite log likelihood',
    not IsNan(Series.LogLikelihood) and
    not IsInfinite(Series.LogLikelihood));

  Forecast := FilterValue.Forecast(4);
  AssertEquals('forecast count', 4, Length(Forecast.Means));
  AssertTrue('forecast uncertainty does not shrink without measurements',
    Forecast.Variances[3] >= Forecast.Variances[0]);
  BeforeEstimate := FilterValue.Estimate;
  Failed := False;
  try
    FilterValue.Process(TDoubleArray.Create(10.0, NaN, 11.0));
  except
    on EStateSpaceError do Failed := True;
  end;
  AssertTrue('non-finite series is rejected', Failed);
  AssertEquals('failed series leaves state unchanged',
    BeforeEstimate, FilterValue.Estimate, 0.0);
end;

procedure TAppliedNumericsTest.TestPortableBlockedKernelOracle;
var
  A, B, PortableValue, BlockedValue, AutomaticValue: IDenseDoubleMatrix;
  ComplexA, ComplexB, ComplexPortable, ComplexBlocked: IDenseComplexMatrix;
  I, J: SizeInt;
  Failed: Boolean;
begin
  A := TDenseDoubleMatrix.Zeros(17, 19);
  B := TDenseDoubleMatrix.Zeros(19, 13);
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      A[I, J] := Sin((I + 1) * (J + 2) * 0.031);
  for I := 0 to B.Rows - 1 do
    for J := 0 to B.Cols - 1 do
      B[I, J] := Cos((I + 3) * (J + 1) * 0.027);
  PortableValue := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
  BlockedValue := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
  AutomaticValue := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
  MultiplyInto(A, B, PortableValue);
  MultiplyBlockedInto(A, B, BlockedValue, 5);
  MultiplyAutoInto(A, B, AutomaticValue);
  for I := 0 to PortableValue.Rows - 1 do
    for J := 0 to PortableValue.Cols - 1 do
    begin
      AssertEquals('blocked/portable exact traversal agreement',
        PortableValue[I, J], BlockedValue[I, J], 0.0);
      AssertEquals('automatic/portable agreement',
        PortableValue[I, J], AutomaticValue[I, J], 0.0);
    end;
  AssertTrue('small deterministic workload uses portable path',
    SelectedMultiplyPath(17, 19, 13) = dmpPortable);
  AssertTrue('large deterministic workload uses blocked path',
    SelectedMultiplyPath(128, 128, 128) = dmpBlocked);

  ComplexA := TDenseComplexMatrix.FromValues(2, 3, [
    TComplex.Create(1, 2), TComplex.Create(3, -1), TComplex.Create(-2, 0.5),
    TComplex.Create(0, 1), TComplex.Create(2, 2), TComplex.Create(1, -3)]);
  ComplexB := TDenseComplexMatrix.FromValues(3, 2, [
    TComplex.Create(2, 0), TComplex.Create(1, 1),
    TComplex.Create(-1, 2), TComplex.Create(0.5, 0),
    TComplex.Create(3, -1), TComplex.Create(2, 2)]);
  ComplexPortable := TDenseComplexMatrix.Zeros(2, 2);
  ComplexBlocked := TDenseComplexMatrix.Zeros(2, 2);
  MultiplyInto(ComplexA, ComplexB, ComplexPortable);
  MultiplyBlockedInto(ComplexA, ComplexB, ComplexBlocked, 2);
  for I := 0 to 1 do
    for J := 0 to 1 do
    begin
      AssertEquals('complex blocked oracle real',
        ComplexPortable[I, J].Re, ComplexBlocked[I, J].Re, 0.0);
      AssertEquals('complex blocked oracle imaginary',
        ComplexPortable[I, J].Im, ComplexBlocked[I, J].Im, 0.0);
    end;

  BlockedValue[0, 0] := 12345.0;
  Failed := False;
  try
    MultiplyBlockedInto(A, B, BlockedValue, 0);
  except
    on EDenseMatrixError do Failed := True;
  end;
  AssertTrue('invalid block size is rejected', Failed);
  AssertEquals('validation failure leaves destination unchanged',
    12345.0, BlockedValue[0, 0], 0.0);
end;

initialization
  RegisterTest(TAppliedNumericsTest);

end.
