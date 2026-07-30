unit EngineeringLib.DSP;

{-----------------------------------------------------------------------------
 EngineeringLib.DSP

 Applied DSP workflows on the project-wide real/complex arrays and typed dense
 matrices. The portable radix-2 and Bluestein paths are deterministic and have
 no global state.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices,
  EngineeringLib.Common, EngineeringLib.Signal;

type
  EDSPError = class(ESignalError);

  TFFTNormalization = (fnBackward, fnForward, fnUnitary, fnNone);
  TConvolutionMethod = (cmAutomatic, cmDirect, cmFFT);
  TComplexBatch = array of TComplexArray;
  TSingleComplexBatch = array of TSingleComplexArray;

  TOverlapAddConvolver = record
  private
    FImpulse: TDoubleArray;
    FTail: TDoubleArray;
    FMethod: TConvolutionMethod;
  public
    class function Create(const Impulse:TDoubleArray;
      const Method:TConvolutionMethod=cmFFT):TOverlapAddConvolver; static;
    function ProcessBlock(const Input:TDoubleArray):TDoubleArray;
    function Flush:TDoubleArray;
    procedure Reset;
    function Impulse:TDoubleArray;
    function Tail:TDoubleArray;
    procedure RestoreTail(const Values:TDoubleArray);
    function StateSize:SizeInt;
  end;

  TOverlapSaveConvolver = record
  private
    FImpulse: TDoubleArray;
    FHistory: TDoubleArray;
    FMethod: TConvolutionMethod;
  public
    class function Create(const Impulse:TDoubleArray;
      const Method:TConvolutionMethod=cmFFT):TOverlapSaveConvolver; static;
    function ProcessBlock(const Input:TDoubleArray):TDoubleArray;
    procedure Reset;
    function Impulse:TDoubleArray;
    function History:TDoubleArray;
    procedure RestoreHistory(const Values:TDoubleArray);
    function StateSize:SizeInt;
  end;

  TWindowMetrics = record
    CoherentGain: Double;
    EquivalentNoiseBandwidth: Double;
    RMSGain: Double;
  end;

  TSpectralEstimate = record
    Frequencies: TDoubleArray;
    Power: TDoubleArray;
  end;

  TCrossSpectralEstimate = record
    Frequencies: TDoubleArray;
    CrossPower: TComplexArray;
    Coherence: TDoubleArray;
  end;

  { Owns a coefficient snapshot and M-1 prior samples. ProcessBlock validates
    the complete block before advancing state. }
  TStreamingFIR = record
  private
    FCoefficients: TDoubleArray;
    FHistory: TDoubleArray;
  public
    class function Create(const Coefficients: TDoubleArray): TStreamingFIR;
      static;
    procedure Reset;
    function ProcessBlock(const Input: TDoubleArray): TDoubleArray;
    function Coefficients: TDoubleArray;
    function History: TDoubleArray;
    procedure RestoreHistory(const Values: TDoubleArray);
    function StateSize: SizeInt;
  end;

  TBiquadCoefficients = record
    B0, B1, B2: Double;
    A1, A2: Double;
  end;

  TStreamingBiquad = record
  private
    FCoefficients: TBiquadCoefficients;
    FZ1, FZ2: Double;
  public
    class function Create(const Coefficients: TBiquadCoefficients):
      TStreamingBiquad; static;
    procedure Reset;
    function ProcessBlock(const Input: TDoubleArray): TDoubleArray;
    property Z1: Double read FZ1;
    property Z2: Double read FZ2;
  end;

  TDSPKit = class
  public
    class function DFTReference(const Input: TComplexArray;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward):
      TComplexArray; static;
    class function Transform(const Input: TComplexArray;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward):
      TComplexArray; overload; static;
    class function Transform(const Input: TSingleComplexArray;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward):
      TSingleComplexArray; overload; static;
    class procedure TransformInto(const Input: TComplexArray;
      var Destination: TComplexArray; const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward); static;
    class function RealTransform(const Input: TDoubleArray;
      const Normalization: TFFTNormalization = fnBackward):
      TComplexArray; overload; static;
    class function RealTransform(const Input: TSingleArray;
      const Normalization: TFFTNormalization = fnBackward):
      TSingleComplexArray; overload; static;
    class function InverseRealTransform(const Input: TComplexArray;
      const Normalization: TFFTNormalization = fnBackward):
      TDoubleArray; static;
    class function Transform2D(const Input: IDenseComplexMatrix;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward):
      IDenseComplexMatrix; static;
    class function TransformBatch(const Input:TComplexBatch;
      const Inverse:Boolean=False;
      const Normalization:TFFTNormalization=fnBackward):TComplexBatch;
      overload; static;
    class function TransformBatch(const Input:TSingleComplexBatch;
      const Inverse:Boolean=False;
      const Normalization:TFFTNormalization=fnBackward):TSingleComplexBatch;
      overload; static;

    class function Convolve(const A, B: TDoubleArray;
      const Method: TConvolutionMethod = cmAutomatic): TDoubleArray; static;
    class function Correlate(const A, B: TDoubleArray;
      const Method: TConvolutionMethod = cmAutomatic): TDoubleArray; static;
    class function SelectedConvolutionMethod(const LengthA, LengthB: SizeInt):
      TConvolutionMethod; static;

    class function ResampleLinear(const Input: TDoubleArray;
      const OutputLength: SizeInt): TDoubleArray; static;
    class function ResampleRational(const Input: TDoubleArray;
      const UpFactor, DownFactor: SizeInt): TDoubleArray; static;

    class function GetWindowMetrics(const Window: TDoubleArray):
      TWindowMetrics; static;
    class function Periodogram(const Input: TDoubleArray;
      const SampleRate: Double = 1.0;
      const WindowType: TWindowType = wtHann): TSpectralEstimate; static;
    class function Welch(const Input: TDoubleArray; const SegmentLength,
      Overlap: SizeInt; const SampleRate: Double = 1.0;
      const WindowType: TWindowType = wtHann): TSpectralEstimate; static;
    class function ShortTimeFourierTransform(const Input: TDoubleArray;
      const FrameLength, HopLength: SizeInt;
      const WindowType: TWindowType = wtHann): IDenseComplexMatrix; static;
    class function AnalyticSignal(const Input: TDoubleArray):
      TComplexArray; static;
    class function CrossSpectrum(const A, B: TDoubleArray;
      const SegmentLength, Overlap: SizeInt;
      const SampleRate: Double = 1.0;
      const WindowType: TWindowType = wtHann): TCrossSpectralEstimate; static;
    class function HaarTransform(const Input:TDoubleArray;
      const Inverse:Boolean=False):TDoubleArray; static;

    class function DesignButterworthLowPass(const NormalizedCutoff: Double):
      TBiquadCoefficients; static;
  end;

implementation

const
  DIRECT_CONVOLUTION_THRESHOLD = 4096;
  DSP_PI: Double = 3.141592653589793238462643383279502884;

procedure RequireFinite(const Values: TDoubleArray; const Operation: string);
var
  I: SizeInt;
begin
  for I := 0 to High(Values) do
    if IsNan(Values[I]) or IsInfinite(Values[I]) then
      raise EDSPError.CreateFmt('%s: sample %d must be finite.',
        [Operation, I]);
end;

procedure RequireFinite(const Values: TComplexArray; const Operation: string);
var
  I: SizeInt;
begin
  for I := 0 to High(Values) do
    if not Values[I].IsFinite then
      raise EDSPError.CreateFmt('%s: sample %d must be finite.',
        [Operation, I]);
end;

function SafeProduct(const LeftValue, RightValue: Double;
  const Operation: string): Double;
begin
  if Abs(RightValue) > 1.0 then
    if Abs(LeftValue) > MaxDouble / Abs(RightValue) then
      raise EDSPError.Create(Operation + ': numerical overflow.');
  Result := LeftValue * RightValue;
end;

function SafeSum(const LeftValue, RightValue: Double;
  const Operation: string): Double;
begin
  if RightValue > 0.0 then
  begin
    if LeftValue > MaxDouble - RightValue then
      raise EDSPError.Create(Operation + ': numerical overflow.');
  end
  else if RightValue < 0.0 then
  begin
    if LeftValue < -MaxDouble - RightValue then
      raise EDSPError.Create(Operation + ': numerical overflow.');
  end;
  Result := LeftValue + RightValue;
end;

function CopyComplexArray(const Values: TComplexArray): TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(Values));
  for I := 0 to High(Values) do
    Result[I] := Values[I];
end;

function ComplexMagnitudeSquared(const Value: TComplex): Double; inline;
begin
  Result := Sqr(Value.Re) + Sqr(Value.Im);
end;

function NextPowerOfTwo(const Minimum: SizeInt): SizeInt;
begin
  if Minimum < 0 then
    raise EDSPError.Create('NextPowerOfTwo: Minimum must be non-negative.');
  Result := 1;
  while Result < Minimum do
  begin
    if Result > High(SizeInt) div 2 then
      raise EDSPError.Create(
        'NextPowerOfTwo: transform workspace dimension overflow.');
    Result := Result shl 1;
  end;
end;

function NormalizationScale(const Count: SizeInt; const Inverse: Boolean;
  const Normalization: TFFTNormalization): Double;
begin
  if Count = 0 then
    Exit(1.0);
  case Normalization of
    fnBackward:
      if Inverse then Result := 1.0 / Double(Count) else Result := 1.0;
    fnForward:
      if Inverse then Result := 1.0 else Result := 1.0 / Double(Count);
    fnUnitary:
      Result := 1.0 / Sqrt(Count);
    fnNone:
      Result := 1.0;
  else
    raise EDSPError.Create('NormalizationScale: unknown normalization mode.');
  end;
end;

procedure ScaleComplex(var Values: TComplexArray; const Factor: Double);
var
  I: SizeInt;
begin
  if Factor = 1.0 then
    Exit;
  for I := 0 to High(Values) do
  begin
    Values[I].Re := Values[I].Re * Factor;
    Values[I].Im := Values[I].Im * Factor;
  end;
end;

procedure Radix2Unscaled(var Values: TComplexArray; const Inverse: Boolean);
var
  N, I, J, Bit, TransformLength, HalfLength, BlockStart: SizeInt;
  Direction, Angle, Cosine, Sine, ProductRe, ProductIm: Double;
  Temporary, EvenValue, OddValue: TComplex;
begin
  N := Length(Values);
  if N <= 1 then
    Exit;
  if (N and (N - 1)) <> 0 then
    raise EDSPError.Create(
      'Radix2Unscaled: transform length must be a power of two.');

  J := 0;
  for I := 1 to N - 1 do
  begin
    Bit := N shr 1;
    while (J and Bit) <> 0 do
    begin
      J := J xor Bit;
      Bit := Bit shr 1;
    end;
    J := J xor Bit;
    if I < J then
    begin
      Temporary := Values[I];
      Values[I] := Values[J];
      Values[J] := Temporary;
    end;
  end;

  if Inverse then Direction := 1.0 else Direction := -1.0;
  TransformLength := 2;
  while TransformLength <= N do
  begin
    HalfLength := TransformLength shr 1;
    BlockStart := 0;
    while BlockStart < N do
    begin
      for J := 0 to HalfLength - 1 do
      begin
        Angle := Direction * 2.0 * DSP_PI * J / TransformLength;
        Cosine := Cos(Angle);
        Sine := Sin(Angle);
        EvenValue := Values[BlockStart + J];
        OddValue := Values[BlockStart + J + HalfLength];
        ProductRe := Cosine * OddValue.Re - Sine * OddValue.Im;
        ProductIm := Cosine * OddValue.Im + Sine * OddValue.Re;
        Values[BlockStart + J] := TComplex.Create(
          EvenValue.Re + ProductRe, EvenValue.Im + ProductIm);
        Values[BlockStart + J + HalfLength] := TComplex.Create(
          EvenValue.Re - ProductRe, EvenValue.Im - ProductIm);
      end;
      Inc(BlockStart, TransformLength);
    end;
    if TransformLength = N then
      Break;
    TransformLength := TransformLength shl 1;
  end;
end;

function BluesteinUnscaled(const Input: TComplexArray;
  const Inverse: Boolean): TComplexArray;
var
  A, B: TComplexArray;
  MinimumWork, WorkLength, N, I: SizeInt;
  Direction, Angle, Cosine, Sine: Double;
  Chirp, Product: TComplex;
begin
  Result := nil;
  N := Length(Input);
  if N = 0 then
    Exit;
  if N > (High(SizeInt) div 2) + 1 then
    raise EDSPError.Create(
      'Transform: input length is too large for Bluestein workspace.');
  MinimumWork := 2 * N - 1;
  WorkLength := NextPowerOfTwo(MinimumWork);
  SetLength(A, WorkLength);
  SetLength(B, WorkLength);
  if Inverse then Direction := 1.0 else Direction := -1.0;

  for I := 0 to N - 1 do
  begin
    Angle := Direction * DSP_PI * Double(I) * Double(I) / N;
    Cosine := Cos(Angle);
    Sine := Sin(Angle);
    Chirp := TComplex.Create(Cosine, Sine);
    A[I] := Input[I] * Chirp;
    B[I] := TComplex.Create(Cosine, -Sine);
    if I > 0 then
      B[WorkLength - I] := B[I];
  end;

  Radix2Unscaled(A, False);
  Radix2Unscaled(B, False);
  for I := 0 to WorkLength - 1 do
    A[I] := A[I] * B[I];
  Radix2Unscaled(A, True);
  ScaleComplex(A, 1.0 / Double(WorkLength));

  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    Angle := Direction * DSP_PI * Double(I) * Double(I) / N;
    Chirp := TComplex.Create(Cos(Angle), Sin(Angle));
    Product := A[I] * Chirp;
    Result[I] := Product;
  end;
end;

class function TDSPKit.DFTReference(const Input: TComplexArray;
  const Inverse: Boolean; const Normalization: TFFTNormalization):
  TComplexArray;
var
  N, K, SampleIndex: SizeInt;
  Direction, Angle, Scale, SumRe, SumIm, Cosine, Sine: Double;
begin
  RequireFinite(Input, 'DFTReference');
  Result := nil;
  N := Length(Input);
  SetLength(Result, N);
  if N = 0 then
    Exit;
  if Inverse then Direction := 1.0 else Direction := -1.0;
  Scale := NormalizationScale(N, Inverse, Normalization);
  for K := 0 to N - 1 do
  begin
    SumRe := 0.0;
    SumIm := 0.0;
    for SampleIndex := 0 to N - 1 do
    begin
      Angle := Direction * 2.0 * DSP_PI * Double(K) * SampleIndex / N;
      Cosine := Cos(Angle);
      Sine := Sin(Angle);
      SumRe := SumRe + Input[SampleIndex].Re * Cosine -
        Input[SampleIndex].Im * Sine;
      SumIm := SumIm + Input[SampleIndex].Re * Sine +
        Input[SampleIndex].Im * Cosine;
    end;
    Result[K] := TComplex.Create(SumRe * Scale, SumIm * Scale);
    if not Result[K].IsFinite then
      raise EDSPError.CreateFmt(
        'DFTReference: numerical overflow at output bin %d.', [K]);
  end;
end;

class function TDSPKit.Transform(const Input: TComplexArray;
  const Inverse: Boolean; const Normalization: TFFTNormalization):
  TComplexArray;
var
  N: SizeInt;
begin
  RequireFinite(Input, 'Transform');
  N := Length(Input);
  if N = 0 then
    Exit(nil);
  if (N and (N - 1)) = 0 then
  begin
    Result := CopyComplexArray(Input);
    Radix2Unscaled(Result, Inverse);
  end
  else
    Result := BluesteinUnscaled(Input, Inverse);
  ScaleComplex(Result, NormalizationScale(N, Inverse, Normalization));
  RequireFinite(Result, 'Transform(result)');
end;

class function TDSPKit.Transform(const Input: TSingleComplexArray;
  const Inverse: Boolean; const Normalization: TFFTNormalization):
  TSingleComplexArray;
var
  Work, Transformed: TComplexArray;
  I: SizeInt;
begin
  Work := nil;
  Result := nil;
  SetLength(Work, Length(Input));
  for I := 0 to High(Input) do
  begin
    if not Input[I].IsFinite then
      raise EDSPError.CreateFmt('Transform(single): sample %d must be finite.',
        [I]);
    Work[I] := TComplex.Create(Input[I].Re, Input[I].Im);
  end;
  Transformed := Transform(Work, Inverse, Normalization);
  SetLength(Result, Length(Transformed));
  for I := 0 to High(Result) do
    Result[I] := TSingleComplex.Create(Transformed[I].Re, Transformed[I].Im);
end;

class procedure TDSPKit.TransformInto(const Input: TComplexArray;
  var Destination: TComplexArray; const Inverse: Boolean;
  const Normalization: TFFTNormalization);
var
  Work: TComplexArray;
begin
  Work := Transform(Input, Inverse, Normalization);
  Destination := Work;
end;

class function TDSPKit.RealTransform(const Input: TDoubleArray;
  const Normalization: TFFTNormalization): TComplexArray;
var
  Work: TComplexArray;
  I: SizeInt;
begin
  RequireFinite(Input, 'RealTransform');
  Work := nil;
  SetLength(Work, Length(Input));
  for I := 0 to High(Input) do
    Work[I] := TComplex.Create(Input[I], 0.0);
  Result := Transform(Work, False, Normalization);
end;

class function TDSPKit.RealTransform(const Input: TSingleArray;
  const Normalization: TFFTNormalization): TSingleComplexArray;
var
  Work: TSingleComplexArray;
  I: SizeInt;
begin
  Work := nil;
  SetLength(Work, Length(Input));
  for I := 0 to High(Input) do
  begin
    if IsNan(Input[I]) or IsInfinite(Input[I]) then
      raise EDSPError.CreateFmt(
        'RealTransform(single): sample %d must be finite.', [I]);
    Work[I] := TSingleComplex.Create(Input[I], 0.0);
  end;
  Result := Transform(Work, False, Normalization);
end;

class function TDSPKit.InverseRealTransform(const Input: TComplexArray;
  const Normalization: TFFTNormalization): TDoubleArray;
var
  Work: TComplexArray;
  I: SizeInt;
begin
  Work := Transform(Input, True, Normalization);
  Result := nil;
  SetLength(Result, Length(Work));
  for I := 0 to High(Work) do
    Result[I] := Work[I].Re;
end;

class function TDSPKit.Transform2D(const Input: IDenseComplexMatrix;
  const Inverse: Boolean; const Normalization: TFFTNormalization):
  IDenseComplexMatrix;
var
  RowValues, ColumnValues, Transformed: TComplexArray;
  RowIndex, ColumnIndex: SizeInt;
begin
  if Input = nil then
    raise EDSPError.Create('Transform2D: Input matrix handle must not be nil.');
  Result := Input.Clone;
  if (Input.Rows = 0) or (Input.Cols = 0) then
    Exit;

  SetLength(RowValues, Input.Cols);
  for RowIndex := 0 to Input.Rows - 1 do
  begin
    for ColumnIndex := 0 to Input.Cols - 1 do
      RowValues[ColumnIndex] := Result[RowIndex, ColumnIndex];
    Transformed := Transform(RowValues, Inverse, Normalization);
    for ColumnIndex := 0 to Input.Cols - 1 do
      Result[RowIndex, ColumnIndex] := Transformed[ColumnIndex];
  end;

  SetLength(ColumnValues, Input.Rows);
  for ColumnIndex := 0 to Input.Cols - 1 do
  begin
    for RowIndex := 0 to Input.Rows - 1 do
      ColumnValues[RowIndex] := Result[RowIndex, ColumnIndex];
    Transformed := Transform(ColumnValues, Inverse, Normalization);
    for RowIndex := 0 to Input.Rows - 1 do
      Result[RowIndex, ColumnIndex] := Transformed[RowIndex];
  end;
end;

class function TDSPKit.TransformBatch(const Input:TComplexBatch;
  const Inverse:Boolean; const Normalization:TFFTNormalization):TComplexBatch;
var
  I:SizeInt;
begin
  Result:=nil;
  SetLength(Result,Length(Input));
  for I:=0 to High(Input) do
    Result[I]:=Transform(Input[I],Inverse,Normalization);
end;

class function TDSPKit.TransformBatch(const Input:TSingleComplexBatch;
  const Inverse:Boolean;
  const Normalization:TFFTNormalization):TSingleComplexBatch;
var
  I:SizeInt;
begin
  Result:=nil;
  SetLength(Result,Length(Input));
  for I:=0 to High(Input) do
    Result[I]:=Transform(Input[I],Inverse,Normalization);
end;

class function TDSPKit.SelectedConvolutionMethod(const LengthA,
  LengthB: SizeInt): TConvolutionMethod;
begin
  if (LengthA < 0) or (LengthB < 0) then
    raise EDSPError.Create(
      'SelectedConvolutionMethod: lengths must be non-negative.');
  if (LengthA = 0) or (LengthB = 0) or
     (LengthA <= DIRECT_CONVOLUTION_THRESHOLD div LengthB) then
    Result := cmDirect
  else
    Result := cmFFT;
end;

function DirectConvolution(const A, B: TDoubleArray): TDoubleArray;
var
  I, J, OutputLength: SizeInt;
begin
  Result := nil;
  if (Length(A) = 0) or (Length(B) = 0) then
    Exit;
  if Length(A) > High(SizeInt) - Length(B) + 1 then
    raise EDSPError.Create('Convolve: output length overflow.');
  OutputLength := Length(A) + Length(B) - 1;
  SetLength(Result, OutputLength);
  for I := 0 to High(A) do
    for J := 0 to High(B) do
    begin
      Result[I + J] := SafeSum(Result[I + J],
        SafeProduct(A[I], B[J], 'Convolve'), 'Convolve');
    end;
end;

class function TDSPKit.Convolve(const A, B: TDoubleArray;
  const Method: TConvolutionMethod): TDoubleArray;
var
  ActualMethod: TConvolutionMethod;
  WorkLength, OutputLength, I: SizeInt;
  SpectrumA, SpectrumB: TComplexArray;
begin
  RequireFinite(A, 'Convolve(A)');
  RequireFinite(B, 'Convolve(B)');
  if (Length(A) = 0) or (Length(B) = 0) then
    Exit(nil);
  if Length(A) > High(SizeInt) - Length(B) + 1 then
    raise EDSPError.Create('Convolve: output length overflow.');
  OutputLength := Length(A) + Length(B) - 1;
  if Method = cmAutomatic then
    ActualMethod := SelectedConvolutionMethod(Length(A), Length(B))
  else
    ActualMethod := Method;
  if ActualMethod = cmDirect then
    Exit(DirectConvolution(A, B));

  WorkLength := NextPowerOfTwo(OutputLength);
  SetLength(SpectrumA, WorkLength);
  SetLength(SpectrumB, WorkLength);
  for I := 0 to High(A) do SpectrumA[I].Re := A[I];
  for I := 0 to High(B) do SpectrumB[I].Re := B[I];
  SpectrumA := Transform(SpectrumA);
  SpectrumB := Transform(SpectrumB);
  for I := 0 to WorkLength - 1 do
    SpectrumA[I] := SpectrumA[I] * SpectrumB[I];
  SpectrumA := Transform(SpectrumA, True);
  SetLength(Result, OutputLength);
  for I := 0 to OutputLength - 1 do
    Result[I] := SpectrumA[I].Re;
end;

class function TDSPKit.Correlate(const A, B: TDoubleArray;
  const Method: TConvolutionMethod): TDoubleArray;
var
  Reversed: TDoubleArray;
  I: SizeInt;
begin
  Reversed := nil;
  SetLength(Reversed, Length(B));
  for I := 0 to High(B) do
    Reversed[I] := B[High(B) - I];
  Result := Convolve(A, Reversed, Method);
end;

class function TOverlapAddConvolver.Create(const Impulse:TDoubleArray;
  const Method:TConvolutionMethod):TOverlapAddConvolver;
begin
  Result:=Default(TOverlapAddConvolver);
  RequireFinite(Impulse,'TOverlapAddConvolver.Create');
  if Length(Impulse)=0 then
    raise EDSPError.Create(
      'TOverlapAddConvolver.Create: impulse must not be empty.');
  Result.FImpulse:=Copy(Impulse);
  SetLength(Result.FTail,Length(Impulse)-1);
  Result.FMethod:=Method;
end;

function TOverlapAddConvolver.ProcessBlock(
  const Input:TDoubleArray):TDoubleArray;
var
  Work,NewTail:TDoubleArray;
  I,SourceIndex:SizeInt;
begin
  if Length(FImpulse)=0 then
    raise EDSPError.Create(
      'TOverlapAddConvolver.ProcessBlock: convolver is not initialized.');
  RequireFinite(Input,'TOverlapAddConvolver.ProcessBlock');
  if Length(Input)=0 then Exit(nil);
  Work:=TDSPKit.Convolve(Input,FImpulse,FMethod);
  SetLength(Result,Length(Input));
  for I:=0 to High(Result) do
  begin
    Result[I]:=Work[I];
    if I<Length(FTail) then
      Result[I]:=SafeSum(Result[I],FTail[I],
        'TOverlapAddConvolver.ProcessBlock');
  end;
  SetLength(NewTail,Length(FImpulse)-1);
  for I:=0 to High(NewTail) do
  begin
    SourceIndex:=Length(Input)+I;
    if SourceIndex<Length(Work) then NewTail[I]:=Work[SourceIndex];
    if SourceIndex<Length(FTail) then
      NewTail[I]:=SafeSum(NewTail[I],FTail[SourceIndex],
        'TOverlapAddConvolver.ProcessBlock');
  end;
  FTail:=NewTail;
end;

function TOverlapAddConvolver.Flush:TDoubleArray;
begin
  if Length(FImpulse)=0 then
    raise EDSPError.Create(
      'TOverlapAddConvolver.Flush: convolver is not initialized.');
  Result:=Copy(FTail);
  Reset;
end;

procedure TOverlapAddConvolver.Reset;
begin
  SetLength(FTail,Length(FImpulse)-1);
end;

function TOverlapAddConvolver.Impulse:TDoubleArray;
begin Result:=Copy(FImpulse); end;

function TOverlapAddConvolver.Tail:TDoubleArray;
begin Result:=Copy(FTail); end;

procedure TOverlapAddConvolver.RestoreTail(const Values:TDoubleArray);
begin
  if Length(FImpulse)=0 then
    raise EDSPError.Create(
      'TOverlapAddConvolver.RestoreTail: convolver is not initialized.');
  RequireFinite(Values,'TOverlapAddConvolver.RestoreTail');
  if Length(Values)<>Length(FTail) then
    raise EDSPError.CreateFmt(
      'TOverlapAddConvolver.RestoreTail: expected %d samples; got %d.',
      [Length(FTail),Length(Values)]);
  FTail:=Copy(Values);
end;

function TOverlapAddConvolver.StateSize:SizeInt;
begin Result:=Length(FTail); end;

class function TOverlapSaveConvolver.Create(const Impulse:TDoubleArray;
  const Method:TConvolutionMethod):TOverlapSaveConvolver;
begin
  Result:=Default(TOverlapSaveConvolver);
  RequireFinite(Impulse,'TOverlapSaveConvolver.Create');
  if Length(Impulse)=0 then
    raise EDSPError.Create(
      'TOverlapSaveConvolver.Create: impulse must not be empty.');
  Result.FImpulse:=Copy(Impulse);
  SetLength(Result.FHistory,Length(Impulse)-1);
  Result.FMethod:=Method;
end;

function TOverlapSaveConvolver.ProcessBlock(
  const Input:TDoubleArray):TDoubleArray;
var
  Combined,Work,NewHistory:TDoubleArray;
  I,Offset:SizeInt;
begin
  if Length(FImpulse)=0 then
    raise EDSPError.Create(
      'TOverlapSaveConvolver.ProcessBlock: convolver is not initialized.');
  RequireFinite(Input,'TOverlapSaveConvolver.ProcessBlock');
  if Length(Input)=0 then Exit(nil);
  Offset:=Length(FHistory);
  SetLength(Combined,Offset+Length(Input));
  for I:=0 to High(FHistory) do Combined[I]:=FHistory[I];
  for I:=0 to High(Input) do Combined[Offset+I]:=Input[I];
  Work:=TDSPKit.Convolve(Combined,FImpulse,FMethod);
  SetLength(Result,Length(Input));
  for I:=0 to High(Result) do Result[I]:=Work[Offset+I];
  SetLength(NewHistory,Offset);
  for I:=0 to High(NewHistory) do
    NewHistory[I]:=Combined[Length(Combined)-Offset+I];
  FHistory:=NewHistory;
end;

procedure TOverlapSaveConvolver.Reset;
begin SetLength(FHistory,Length(FImpulse)-1); end;

function TOverlapSaveConvolver.Impulse:TDoubleArray;
begin Result:=Copy(FImpulse); end;

function TOverlapSaveConvolver.History:TDoubleArray;
begin Result:=Copy(FHistory); end;

procedure TOverlapSaveConvolver.RestoreHistory(const Values:TDoubleArray);
begin
  if Length(FImpulse)=0 then
    raise EDSPError.Create(
      'TOverlapSaveConvolver.RestoreHistory: convolver is not initialized.');
  RequireFinite(Values,'TOverlapSaveConvolver.RestoreHistory');
  if Length(Values)<>Length(FHistory) then
    raise EDSPError.CreateFmt(
      'TOverlapSaveConvolver.RestoreHistory: expected %d samples; got %d.',
      [Length(FHistory),Length(Values)]);
  FHistory:=Copy(Values);
end;

function TOverlapSaveConvolver.StateSize:SizeInt;
begin Result:=Length(FHistory); end;

class function TDSPKit.ResampleLinear(const Input: TDoubleArray;
  const OutputLength: SizeInt): TDoubleArray;
var
  I, LeftIndex: SizeInt;
  Position, Fraction: Double;
begin
  RequireFinite(Input, 'ResampleLinear');
  if OutputLength < 0 then
    raise EDSPError.Create(
      'ResampleLinear: OutputLength must be non-negative.');
  Result := nil;
  SetLength(Result, OutputLength);
  if OutputLength = 0 then
    Exit;
  if Length(Input) = 0 then
    raise EDSPError.Create(
      'ResampleLinear: non-empty input is required for non-empty output.');
  if (OutputLength = 1) or (Length(Input) = 1) then
  begin
    for I := 0 to OutputLength - 1 do Result[I] := Input[0];
    Exit;
  end;
  for I := 0 to OutputLength - 1 do
  begin
    Position := Double(I) * (Length(Input) - 1) / (OutputLength - 1);
    LeftIndex := Floor(Position);
    if LeftIndex >= High(Input) then
      Result[I] := Input[High(Input)]
    else
    begin
      Fraction := Position - LeftIndex;
      Result[I] := Input[LeftIndex] * (1.0 - Fraction) +
        Input[LeftIndex + 1] * Fraction;
    end;
  end;
end;

class function TDSPKit.ResampleRational(const Input: TDoubleArray;
  const UpFactor, DownFactor: SizeInt): TDoubleArray;
var
  OutputLength: SizeInt;
begin
  if (UpFactor <= 0) or (DownFactor <= 0) then
    raise EDSPError.Create(
      'ResampleRational: UpFactor and DownFactor must be positive.');
  if Length(Input) = 0 then
    Exit(nil);
  if Length(Input) > (High(SizeInt) - DownFactor + 1) div UpFactor then
    raise EDSPError.Create('ResampleRational: output length overflow.');
  OutputLength := (Length(Input) * UpFactor + DownFactor - 1) div DownFactor;
  Result := ResampleLinear(Input, OutputLength);
end;

class function TDSPKit.GetWindowMetrics(const Window: TDoubleArray):
  TWindowMetrics;
var
  I: SizeInt;
  Sum, SumSquares: Double;
begin
  RequireFinite(Window, 'GetWindowMetrics');
  if Length(Window) = 0 then
    raise EDSPError.Create('GetWindowMetrics: Window must not be empty.');
  Sum := 0.0;
  SumSquares := 0.0;
  for I := 0 to High(Window) do
  begin
    Sum := Sum + Window[I];
    SumSquares := SumSquares + Sqr(Window[I]);
  end;
  if Sum = 0.0 then
    raise EDSPError.Create(
      'GetWindowMetrics: coherent window sum must be non-zero.');
  Result.CoherentGain := Sum / Length(Window);
  Result.EquivalentNoiseBandwidth :=
    Length(Window) * SumSquares / Sqr(Sum);
  Result.RMSGain := Sqrt(SumSquares / Length(Window));
end;

function WindowedPeriodogram(const Input, Window: TDoubleArray;
  const SampleRate: Double): TSpectralEstimate;
var
  Work: TDoubleArray;
  Spectrum: TComplexArray;
  I, BinCount, N: SizeInt;
  SumSquares, Factor: Double;
begin
  Result.Frequencies := nil;
  Result.Power := nil;
  N := Length(Input);
  SetLength(Work, N);
  SumSquares := 0.0;
  for I := 0 to N - 1 do
  begin
    Work[I] := Input[I] * Window[I];
    SumSquares := SumSquares + Sqr(Window[I]);
  end;
  if IsNan(SumSquares) or IsInfinite(SumSquares) or
    (SumSquares <= 0.0) then
    raise EDSPError.Create(
      'WindowedPeriodogram: window energy must be finite and positive.');
  Spectrum := TDSPKit.RealTransform(Work);
  BinCount := N div 2 + 1;
  SetLength(Result.Frequencies, BinCount);
  SetLength(Result.Power, BinCount);
  for I := 0 to BinCount - 1 do
  begin
    Result.Frequencies[I] := I * SampleRate / N;
    Factor := 1.0;
    if (I > 0) and not ((N mod 2 = 0) and (I = N div 2)) then
      Factor := 2.0;
    Result.Power[I] := Factor * ComplexMagnitudeSquared(Spectrum[I]) /
      (SampleRate * SumSquares);
  end;
end;

class function TDSPKit.Periodogram(const Input: TDoubleArray;
  const SampleRate: Double; const WindowType: TWindowType): TSpectralEstimate;
var
  Window: TDoubleArray;
begin
  RequireFinite(Input, 'Periodogram');
  if Length(Input) < 2 then
    raise EDSPError.Create(
      'Periodogram: at least two finite samples are required.');
  if IsNan(SampleRate) or IsInfinite(SampleRate) or (SampleRate <= 0.0) then
    raise EDSPError.Create('Periodogram: SampleRate must be finite and positive.');
  Window := TSignalKit.GenerateWindow(WindowType, Length(Input));
  Result := WindowedPeriodogram(Input, Window, SampleRate);
end;

procedure ValidateSegments(const InputLength, SegmentLength, Overlap: SizeInt;
  const Operation: string);
begin
  if SegmentLength < 2 then
    raise EDSPError.Create(Operation + ': SegmentLength must be at least 2.');
  if SegmentLength > InputLength then
    raise EDSPError.Create(Operation +
      ': SegmentLength must not exceed input length.');
  if (Overlap < 0) or (Overlap >= SegmentLength) then
    raise EDSPError.Create(Operation +
      ': Overlap must be in [0, SegmentLength).');
end;

class function TDSPKit.Welch(const Input: TDoubleArray;
  const SegmentLength, Overlap: SizeInt; const SampleRate: Double;
  const WindowType: TWindowType): TSpectralEstimate;
var
  Window, Segment: TDoubleArray;
  Current: TSpectralEstimate;
  StartIndex, Step, FrameCount, I: SizeInt;
begin
  Result.Frequencies := nil;
  Result.Power := nil;
  RequireFinite(Input, 'Welch');
  if IsNan(SampleRate) or IsInfinite(SampleRate) or (SampleRate <= 0.0) then
    raise EDSPError.Create('Welch: SampleRate must be finite and positive.');
  ValidateSegments(Length(Input), SegmentLength, Overlap, 'Welch');
  Window := TSignalKit.GenerateWindow(WindowType, SegmentLength);
  SetLength(Segment, SegmentLength);
  SetLength(Result.Frequencies, SegmentLength div 2 + 1);
  SetLength(Result.Power, SegmentLength div 2 + 1);
  Step := SegmentLength - Overlap;
  StartIndex := 0;
  FrameCount := 0;
  while StartIndex + SegmentLength <= Length(Input) do
  begin
    for I := 0 to SegmentLength - 1 do
      Segment[I] := Input[StartIndex + I];
    Current := WindowedPeriodogram(Segment, Window, SampleRate);
    Result.Frequencies := Copy(Current.Frequencies);
    for I := 0 to High(Result.Power) do
      Result.Power[I] := Result.Power[I] + Current.Power[I];
    Inc(FrameCount);
    Inc(StartIndex, Step);
  end;
  for I := 0 to High(Result.Power) do
    Result.Power[I] := Result.Power[I] / FrameCount;
end;

class function TDSPKit.ShortTimeFourierTransform(
  const Input: TDoubleArray; const FrameLength, HopLength: SizeInt;
  const WindowType: TWindowType): IDenseComplexMatrix;
var
  Window, Frame: TDoubleArray;
  Spectrum: TComplexArray;
  FrameCount, FrameIndex, I, StartIndex: SizeInt;
begin
  RequireFinite(Input, 'ShortTimeFourierTransform');
  if FrameLength < 2 then
    raise EDSPError.Create(
      'ShortTimeFourierTransform: FrameLength must be at least 2.');
  if FrameLength > Length(Input) then
    raise EDSPError.Create(
      'ShortTimeFourierTransform: FrameLength must not exceed input length.');
  if HopLength <= 0 then
    raise EDSPError.Create(
      'ShortTimeFourierTransform: HopLength must be positive.');
  FrameCount := 1 + (Length(Input) - FrameLength) div HopLength;
  Result := TDenseComplexMatrix.Zeros(FrameCount, FrameLength);
  Window := TSignalKit.GenerateWindow(WindowType, FrameLength);
  SetLength(Frame, FrameLength);
  for FrameIndex := 0 to FrameCount - 1 do
  begin
    StartIndex := FrameIndex * HopLength;
    for I := 0 to FrameLength - 1 do
      Frame[I] := Input[StartIndex + I] * Window[I];
    Spectrum := RealTransform(Frame);
    for I := 0 to FrameLength - 1 do
      Result[FrameIndex, I] := Spectrum[I];
  end;
end;

class function TDSPKit.AnalyticSignal(const Input: TDoubleArray):
  TComplexArray;
var
  Spectrum: TComplexArray;
  I, N, PositiveLimit: SizeInt;
begin
  RequireFinite(Input, 'AnalyticSignal');
  N := Length(Input);
  if N = 0 then
    Exit(nil);
  Spectrum := RealTransform(Input);
  if N mod 2 = 0 then
    PositiveLimit := N div 2 - 1
  else
    PositiveLimit := N div 2;
  for I := 1 to PositiveLimit do
    Spectrum[I] := Spectrum[I] * TComplex.Create(2.0, 0.0);
  for I := N div 2 + 1 to N - 1 do
    Spectrum[I] := TComplex.Zero;
  Result := Transform(Spectrum, True);
end;

class function TDSPKit.CrossSpectrum(const A, B: TDoubleArray;
  const SegmentLength, Overlap: SizeInt; const SampleRate: Double;
  const WindowType: TWindowType): TCrossSpectralEstimate;
var
  Window, SegmentA, SegmentB: TDoubleArray;
  SpectrumA, SpectrumB: TComplexArray;
  AutoA, AutoB: TDoubleArray;
  StartIndex, Step, FrameCount, I, BinCount: SizeInt;
  Scale, SumSquares, Factor, Denominator: Double;
  Product: TComplex;
begin
  Result.Frequencies := nil;
  Result.CrossPower := nil;
  Result.Coherence := nil;
  RequireFinite(A, 'CrossSpectrum(A)');
  RequireFinite(B, 'CrossSpectrum(B)');
  if Length(A) <> Length(B) then
    raise EDSPError.Create('CrossSpectrum: inputs must have equal lengths.');
  if IsNan(SampleRate) or IsInfinite(SampleRate) or (SampleRate <= 0.0) then
    raise EDSPError.Create(
      'CrossSpectrum: SampleRate must be finite and positive.');
  ValidateSegments(Length(A), SegmentLength, Overlap, 'CrossSpectrum');
  Window := TSignalKit.GenerateWindow(WindowType, SegmentLength);
  SumSquares := 0.0;
  for I := 0 to High(Window) do
    SumSquares := SumSquares + Sqr(Window[I]);
  if IsNan(SumSquares) or IsInfinite(SumSquares) or
    (SumSquares <= 0.0) then
    raise EDSPError.Create(
      'CrossSpectrum: window energy must be finite and positive.');
  Scale := 1.0 / (SampleRate * SumSquares);
  BinCount := SegmentLength div 2 + 1;
  SetLength(Result.Frequencies, BinCount);
  SetLength(Result.CrossPower, BinCount);
  SetLength(Result.Coherence, BinCount);
  SetLength(AutoA, BinCount);
  SetLength(AutoB, BinCount);
  SetLength(SegmentA, SegmentLength);
  SetLength(SegmentB, SegmentLength);
  Step := SegmentLength - Overlap;
  StartIndex := 0;
  FrameCount := 0;
  while StartIndex + SegmentLength <= Length(A) do
  begin
    for I := 0 to SegmentLength - 1 do
    begin
      SegmentA[I] := A[StartIndex + I] * Window[I];
      SegmentB[I] := B[StartIndex + I] * Window[I];
    end;
    SpectrumA := RealTransform(SegmentA);
    SpectrumB := RealTransform(SegmentB);
    for I := 0 to BinCount - 1 do
    begin
      Factor := 1.0;
      if (I > 0) and not ((SegmentLength mod 2 = 0) and
         (I = SegmentLength div 2)) then
        Factor := 2.0;
      Product := SpectrumA[I] * SpectrumB[I].Conjugate;
      Result.CrossPower[I] := Result.CrossPower[I] +
        Product * TComplex.Create(Factor * Scale, 0.0);
      AutoA[I] := AutoA[I] + Factor * Scale *
        ComplexMagnitudeSquared(SpectrumA[I]);
      AutoB[I] := AutoB[I] + Factor * Scale *
        ComplexMagnitudeSquared(SpectrumB[I]);
    end;
    Inc(FrameCount);
    Inc(StartIndex, Step);
  end;
  for I := 0 to BinCount - 1 do
  begin
    Result.Frequencies[I] := I * SampleRate / SegmentLength;
    Result.CrossPower[I] := Result.CrossPower[I] *
      TComplex.Create(1.0 / Double(FrameCount), 0.0);
    AutoA[I] := AutoA[I] / FrameCount;
    AutoB[I] := AutoB[I] / FrameCount;
    Denominator := AutoA[I] * AutoB[I];
    if Denominator > 0.0 then
      Result.Coherence[I] := Min(1.0,
        ComplexMagnitudeSquared(Result.CrossPower[I]) / Denominator)
    else
      Result.Coherence[I] := 0.0;
  end;
end;

class function TDSPKit.HaarTransform(const Input:TDoubleArray;
  const Inverse:Boolean):TDoubleArray;
var
  Work:TDoubleArray;
  Active,Half,I:SizeInt;
  InvSqrt2:Double;
begin
  RequireFinite(Input,'HaarTransform');
  if Length(Input)=0 then Exit(nil);
  if (Length(Input) and (Length(Input)-1))<>0 then
    raise EDSPError.Create(
      'HaarTransform: input length must be a power of two.');
  Result:=Copy(Input);
  SetLength(Work,Length(Input));
  InvSqrt2:=1/Sqrt(2);
  if not Inverse then
  begin
    Active:=Length(Result);
    while Active>1 do
    begin
      Half:=Active div 2;
      for I:=0 to Half-1 do
      begin
        Work[I]:=(Result[2*I]+Result[2*I+1])*InvSqrt2;
        Work[Half+I]:=(Result[2*I]-Result[2*I+1])*InvSqrt2;
      end;
      for I:=0 to Active-1 do Result[I]:=Work[I];
      Active:=Half;
    end;
  end
  else
  begin
    Active:=1;
    while Active<Length(Result) do
    begin
      for I:=0 to Active-1 do
      begin
        Work[2*I]:=(Result[I]+Result[Active+I])*InvSqrt2;
        Work[2*I+1]:=(Result[I]-Result[Active+I])*InvSqrt2;
      end;
      for I:=0 to 2*Active-1 do Result[I]:=Work[I];
      Active:=2*Active;
    end;
  end;
end;

class function TDSPKit.DesignButterworthLowPass(
  const NormalizedCutoff: Double): TBiquadCoefficients;
var
  Omega, Cosine, Sine, Alpha, A0: Double;
begin
  if IsNan(NormalizedCutoff) or IsInfinite(NormalizedCutoff) or
     (NormalizedCutoff <= 0.0) or (NormalizedCutoff >= 0.5) then
    raise EDSPError.Create(
      'DesignButterworthLowPass: NormalizedCutoff must be finite and in (0, 0.5).');
  Omega := 2.0 * DSP_PI * NormalizedCutoff;
  Cosine := Cos(Omega);
  Sine := Sin(Omega);
  Alpha := Sine / Sqrt(2.0);
  A0 := 1.0 + Alpha;
  Result.B0 := (1.0 - Cosine) * 0.5 / A0;
  Result.B1 := (1.0 - Cosine) / A0;
  Result.B2 := Result.B0;
  Result.A1 := -2.0 * Cosine / A0;
  Result.A2 := (1.0 - Alpha) / A0;
end;

class function TStreamingFIR.Create(
  const Coefficients: TDoubleArray): TStreamingFIR;
begin
  RequireFinite(Coefficients, 'TStreamingFIR.Create');
  if Length(Coefficients) = 0 then
    raise EDSPError.Create(
      'TStreamingFIR.Create: Coefficients must not be empty.');
  Result.FCoefficients := Copy(Coefficients);
  SetLength(Result.FHistory, Length(Coefficients) - 1);
end;

procedure TStreamingFIR.Reset;
begin
  FHistory := nil;
  SetLength(FHistory, Max(0, Length(FCoefficients) - 1));
end;

function TStreamingFIR.ProcessBlock(const Input: TDoubleArray): TDoubleArray;
var
  NewHistory: TDoubleArray;
  I, J: SizeInt;
  Sum: Double;
begin
  if Length(FCoefficients) = 0 then
    raise EDSPError.Create(
      'TStreamingFIR.ProcessBlock: filter state is not initialized.');
  RequireFinite(Input, 'TStreamingFIR.ProcessBlock');
  Result := nil;
  SetLength(Result, Length(Input));
  NewHistory := Copy(FHistory);
  for I := 0 to High(Input) do
  begin
    Sum := SafeProduct(FCoefficients[0], Input[I],
      'TStreamingFIR.ProcessBlock');
    for J := 1 to High(FCoefficients) do
      Sum := SafeSum(Sum, SafeProduct(FCoefficients[J],
        NewHistory[J - 1], 'TStreamingFIR.ProcessBlock'),
        'TStreamingFIR.ProcessBlock');
    Result[I] := Sum;
    for J := High(NewHistory) downto 1 do
      NewHistory[J] := NewHistory[J - 1];
    if Length(NewHistory) > 0 then
      NewHistory[0] := Input[I];
  end;
  FHistory := NewHistory;
end;

function TStreamingFIR.Coefficients: TDoubleArray;
begin
  Result := Copy(FCoefficients);
end;

function TStreamingFIR.History: TDoubleArray;
begin
  Result := Copy(FHistory);
end;

procedure TStreamingFIR.RestoreHistory(const Values: TDoubleArray);
begin
  RequireFinite(Values, 'TStreamingFIR.RestoreHistory');
  if Length(Values) <> Max(0, Length(FCoefficients) - 1) then
    raise EDSPError.CreateFmt(
      'TStreamingFIR.RestoreHistory: expected %d samples; got %d.',
      [Max(0, Length(FCoefficients) - 1), Length(Values)]);
  FHistory := Copy(Values);
end;

function TStreamingFIR.StateSize: SizeInt;
begin
  Result := Length(FHistory);
end;

class function TStreamingBiquad.Create(
  const Coefficients: TBiquadCoefficients): TStreamingBiquad;
begin
  if IsNan(Coefficients.B0) or IsInfinite(Coefficients.B0) or
     IsNan(Coefficients.B1) or IsInfinite(Coefficients.B1) or
     IsNan(Coefficients.B2) or IsInfinite(Coefficients.B2) or
     IsNan(Coefficients.A1) or IsInfinite(Coefficients.A1) or
     IsNan(Coefficients.A2) or IsInfinite(Coefficients.A2) then
    raise EDSPError.Create(
      'TStreamingBiquad.Create: all coefficients must be finite.');
  Result.FCoefficients := Coefficients;
  Result.Reset;
end;

procedure TStreamingBiquad.Reset;
begin
  FZ1 := 0.0;
  FZ2 := 0.0;
end;

function TStreamingBiquad.ProcessBlock(
  const Input: TDoubleArray): TDoubleArray;
var
  I: SizeInt;
  OutputValue, NewZ1, NewZ2, State1, State2: Double;
begin
  RequireFinite(Input, 'TStreamingBiquad.ProcessBlock');
  State1 := FZ1;
  State2 := FZ2;
  Result := nil;
  SetLength(Result, Length(Input));
  for I := 0 to High(Input) do
  begin
    OutputValue := SafeSum(SafeProduct(FCoefficients.B0, Input[I],
      'TStreamingBiquad.ProcessBlock'), State1,
      'TStreamingBiquad.ProcessBlock');
    NewZ1 := SafeSum(SafeSum(
      SafeProduct(FCoefficients.B1, Input[I],
        'TStreamingBiquad.ProcessBlock'),
      -SafeProduct(FCoefficients.A1, OutputValue,
        'TStreamingBiquad.ProcessBlock'),
      'TStreamingBiquad.ProcessBlock'), State2,
      'TStreamingBiquad.ProcessBlock');
    NewZ2 := SafeSum(SafeProduct(FCoefficients.B2, Input[I],
      'TStreamingBiquad.ProcessBlock'),
      -SafeProduct(FCoefficients.A2, OutputValue,
        'TStreamingBiquad.ProcessBlock'),
      'TStreamingBiquad.ProcessBlock');
    if IsNan(OutputValue) or IsInfinite(OutputValue) or
       IsNan(NewZ1) or IsInfinite(NewZ1) or
       IsNan(NewZ2) or IsInfinite(NewZ2) then
      raise EDSPError.CreateFmt(
        'TStreamingBiquad.ProcessBlock: numerical overflow at sample %d.', [I]);
    Result[I] := OutputValue;
    State1 := NewZ1;
    State2 := NewZ2;
  end;
  FZ1 := State1;
  FZ2 := State2;
end;

end.
