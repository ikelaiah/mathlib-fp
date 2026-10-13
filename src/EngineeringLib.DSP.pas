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
  TIIRResponse = (irLowPass, irHighPass, irBandPass, irBandStop);
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

  TSOSCoefficients = array of TBiquadCoefficients;

  TSOSStabilityDiagnostics = record
    IsStable: Boolean;
    MaximumPoleRadius: Double;
    MinimumStabilityMargin: Double;
    FirstUnstableSection: SizeInt;
  end;

  TSOSFrequencyResponse = record
    FrequenciesHz: TDoubleArray;
    Values: TComplexArray;
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

  { Mutable streaming state for an immutable snapshot of real SOS sections. }
  TStreamingSOSFilter = record
  private
    FSections: TSOSCoefficients;
    FState: TDoubleArray;
  public
    class function Create(const Coefficients: TSOSCoefficients):
      TStreamingSOSFilter; static;
    procedure Reset;
    function ProcessBlock(const Input: TDoubleArray): TDoubleArray;
    function State: TDoubleArray;
    procedure RestoreState(const Values: TDoubleArray);
    function Coefficients: TSOSCoefficients;
    function SectionCount: SizeInt;
    function StateSize: SizeInt;
  end;

  { Owns a fixed-size complex FFT workspace. Valid ExecuteInto calls reuse all
    prepared storage; one instance rejects overlapping execution. }
  TFFTPlan = class
  private
    FLength: SizeInt;
    FWorkLength: SizeInt;
    FIsBluestein: Boolean;
    FWorkspace: TComplexArray;
    FTwiddles: TComplexArray;
    FBluesteinKernel: TComplexArray;
    FChirp: TComplexArray;
    FBitReverse: array of SizeInt;
    FBusy: LongInt;
    FRetainedBytes: SizeInt;
    procedure Acquire;
    procedure Release;
    procedure Radix2Prepared(const Inverse: Boolean);
    procedure TransformPrepared(const Input: TComplexArray;
      const Inverse: Boolean; const Normalization: TFFTNormalization);
  public
    constructor Create(const ATransformLength: SizeInt);
    destructor Destroy; override;
    function Execute(const Input: TComplexArray;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward): TComplexArray;
    procedure ExecuteInto(const Input: TComplexArray;
      var Destination: TComplexArray; const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward);
    function TransformLength: SizeInt;
    function WorkspaceElements: SizeInt;
    function RetainedBytes: SizeInt;
  end;

  { Fixed-geometry full-spectrum STFT analysis and weighted overlap-add
    synthesis for one finite real-double signal. }
  TSTFTPlan = class
  private
    FSampleCount: SizeInt;
    FFrameLength: SizeInt;
    FHopLength: SizeInt;
    FFrameCount: SizeInt;
    FLeftPadding: SizeInt;
    FRightPadding: SizeInt;
    FPaddedLength: SizeInt;
    FWindow: TDoubleArray;
    FDenominator: TDoubleArray;
    FFrame: TComplexArray;
    FAccumulator: TDoubleArray;
    FStagedResult: TDoubleArray;
    FStagedSpectrum: IDenseComplexMatrix;
    FFFT: TFFTPlan;
    FBusy: LongInt;
    FRetainedBytes: SizeInt;
    procedure Acquire;
    procedure Release;
    procedure ValidateSpectrum(const Spectrum: IDenseComplexMatrix);
  public
    constructor Create(const ASampleCount, AFrameLength, AHopLength: SizeInt;
      const WindowType: TWindowType = wtHann);
    destructor Destroy; override;
    function Analyze(const Input: TDoubleArray): IDenseComplexMatrix;
    procedure AnalyzeInto(const Input: TDoubleArray;
      const Destination: IDenseComplexMatrix);
    function Synthesize(const Spectrum: IDenseComplexMatrix): TDoubleArray;
    procedure SynthesizeInto(const Spectrum: IDenseComplexMatrix;
      var Destination: TDoubleArray);
    function SampleCount: SizeInt;
    function FrameLength: SizeInt;
    function HopLength: SizeInt;
    function FrameCount: SizeInt;
    function LeftPadding: SizeInt;
    function RightPadding: SizeInt;
    function RetainedBytes: SizeInt;
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
    class function DesignButterworthSOS(const Response: TIIRResponse;
      const Order: SizeInt; const SampleRateHz, CutoffHz: Double):
      TSOSCoefficients; overload; static;
    class function DesignButterworthSOS(const Response: TIIRResponse;
      const Order: SizeInt; const SampleRateHz, LowCutoffHz,
      HighCutoffHz: Double): TSOSCoefficients; overload; static;
    class function DesignChebyshevISOS(const Response: TIIRResponse;
      const Order: SizeInt; const SampleRateHz, CutoffHz,
      PassbandRippleDb: Double): TSOSCoefficients; overload; static;
    class function DesignChebyshevISOS(const Response: TIIRResponse;
      const Order: SizeInt; const SampleRateHz, LowCutoffHz,
      HighCutoffHz, PassbandRippleDb: Double): TSOSCoefficients;
      overload; static;
    class function AnalyzeSOSStability(
      const Coefficients: TSOSCoefficients): TSOSStabilityDiagnostics; static;
    class function EvaluateSOSResponse(const Coefficients: TSOSCoefficients;
      const SampleRateHz: Double; const FrequenciesHz: TDoubleArray):
      TSOSFrequencyResponse; static;
  end;

implementation

const
  DIRECT_CONVOLUTION_THRESHOLD = 4096;
  DSP_PI: Double = 3.141592653589793238462643383279502884;
  DSP_DOUBLE_EPSILON: Double = 2.220446049250313080847263336181640625E-16;
  MAX_IIR_PROTOTYPE_ORDER = 12;

type
  TSOSRootPair = record
    First: TComplex;
    Second: TComplex;
    FirstOrder: Boolean;
  end;
  TSOSRootPairArray = array of TSOSRootPair;

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

procedure RequireFiniteSOS(const Coefficients: TSOSCoefficients;
  const Operation: string);
var
  I: SizeInt;
begin
  if Length(Coefficients) = 0 then
    raise EDSPError.Create(Operation + ': at least one SOS section is required.');
  for I := 0 to High(Coefficients) do
    if IsNan(Coefficients[I].B0) or IsInfinite(Coefficients[I].B0) or
       IsNan(Coefficients[I].B1) or IsInfinite(Coefficients[I].B1) or
       IsNan(Coefficients[I].B2) or IsInfinite(Coefficients[I].B2) or
       IsNan(Coefficients[I].A1) or IsInfinite(Coefficients[I].A1) or
       IsNan(Coefficients[I].A2) or IsInfinite(Coefficients[I].A2) then
      raise EDSPError.CreateFmt(
        '%s: section %d must contain only finite coefficients.',
        [Operation, I]);
end;

function SOSSectionPoleRadius(const A1, A2: Double): Double;
var
  Scale, Linear, Constant, Discriminant, RootDiscriminant: Double;
  Root1, Root2, LargestRoot: Double;
begin
  Scale := Max(1.0, Max(Abs(A1), Sqrt(Abs(A2))));
  Linear := A1 / Scale;
  Constant := (A2 / Scale) / Scale;
  Discriminant := Linear * Linear - 4.0 * Constant;

  if Discriminant < 0.0 then
  begin
    if Constant <= 0.0 then
      Exit(Infinity);
    LargestRoot := Sqrt(Constant);
  end
  else
  begin
    RootDiscriminant := Sqrt(Discriminant);
    if Linear >= 0.0 then
      Root1 := -0.5 * (Linear + RootDiscriminant)
    else
      Root1 := -0.5 * (Linear - RootDiscriminant);
    if Root1 = 0.0 then
    begin
      Root1 := -0.5 * (Linear + RootDiscriminant);
      Root2 := -0.5 * (Linear - RootDiscriminant);
    end
    else
      Root2 := Constant / Root1;
    LargestRoot := Max(Abs(Root1), Abs(Root2));
  end;

  if (LargestRoot > 1.0) and (Scale > MaxDouble / LargestRoot) then
    Result := Infinity
  else
    Result := Scale * LargestRoot;
end;

function IsEffectivelyRealRoot(const Value: TComplex): Boolean;
begin
  Result := Abs(Value.Im) <= 64.0 * DSP_DOUBLE_EPSILON *
    Max(1.0, Abs(Value.Re));
end;

function PairSOSRoots(const Roots: TComplexArray;
  const Operation: string): TSOSRootPairArray;
var
  Used: array of Boolean;
  RealRoots: TDoubleArray;
  I, J, BestIndex, RealCount, PairIndex: SizeInt;
  BestDistance, Distance, Tolerance, RealPart, ImaginaryPart, Temp: Double;
  Value, Candidate: TComplex;
begin
  if Length(Roots) = 0 then
    raise EDSPError.Create(Operation + ': root set must not be empty.');
  Result := nil;
  SetLength(Used, Length(Roots));
  SetLength(RealRoots, Length(Roots));
  SetLength(Result, (Length(Roots) + 1) div 2);
  PairIndex := 0;
  RealCount := 0;
  for I := 0 to High(Roots) do
  begin
    if Used[I] then Continue;
    Value := Roots[I];
    if not Value.IsFinite then
      raise EDSPError.CreateFmt('%s: root %d is not finite.', [Operation, I]);
    Used[I] := True;
    if IsEffectivelyRealRoot(Value) then
    begin
      RealRoots[RealCount] := Value.Re;
      Inc(RealCount);
      Continue;
    end;

    BestIndex := -1;
    BestDistance := Infinity;
    for J := 0 to High(Roots) do
      if (J <> I) and not Used[J] then
      begin
        Candidate := Roots[J];
        Distance := (Candidate - Value.Conjugate).Magnitude;
        if Distance < BestDistance then
        begin
          BestDistance := Distance;
          BestIndex := J;
        end;
      end;
    Tolerance := 1E-9 * Max(1.0, Value.Magnitude);
    if (BestIndex < 0) or (BestDistance > Tolerance) then
      raise EDSPError.CreateFmt(
        '%s: root %d has no matching conjugate.', [Operation, I]);
    Used[BestIndex] := True;
    RealPart := 0.5 * (Value.Re + Roots[BestIndex].Re);
    ImaginaryPart := 0.5 * (Abs(Value.Im) + Abs(Roots[BestIndex].Im));
    Result[PairIndex].First := TComplex.Create(RealPart, ImaginaryPart);
    Result[PairIndex].Second := Result[PairIndex].First.Conjugate;
    Inc(PairIndex);
  end;

  for I := 1 to RealCount - 1 do
  begin
    Temp := RealRoots[I];
    J := I;
    while (J > 0) and (RealRoots[J - 1] > Temp) do
    begin
      RealRoots[J] := RealRoots[J - 1];
      Dec(J);
    end;
    RealRoots[J] := Temp;
  end;
  for I := 0 to (RealCount div 2) - 1 do
  begin
    Result[PairIndex].First := TComplex.Create(RealRoots[2 * I], 0.0);
    Result[PairIndex].Second := TComplex.Create(RealRoots[2 * I + 1], 0.0);
    Inc(PairIndex);
  end;
  if (Length(Roots) mod 2) <> 0 then
  begin
    if (RealCount mod 2) = 0 then
      raise EDSPError.Create(Operation + ': odd root set has no real singleton.');
    Result[PairIndex].First := TComplex.Create(RealRoots[RealCount - 1], 0.0);
    Result[PairIndex].Second := TComplex.Zero;
    Result[PairIndex].FirstOrder := True;
    Inc(PairIndex);
  end
  else if (RealCount mod 2) <> 0 then
    raise EDSPError.Create(Operation + ': even root set has an unmatched real root.');

  if PairIndex <> Length(Result) then
    raise EDSPError.Create(Operation + ': root pairing count is inconsistent.');
end;

procedure SOSPolynomialFromRoots(const Pair: TSOSRootPair;
  out FirstCoefficient, SecondCoefficient: Double; const Operation: string);
var
  SumRoots, ProductRoots: TComplex;
begin
  if Pair.FirstOrder then
  begin
    FirstCoefficient := -Pair.First.Re;
    SecondCoefficient := 0.0;
    Exit;
  end;
  SumRoots := Pair.First + Pair.Second;
  ProductRoots := Pair.First * Pair.Second;
  if (Abs(SumRoots.Im) > 1E-10 * Max(1.0, Abs(SumRoots.Re))) or
     (Abs(ProductRoots.Im) > 1E-10 * Max(1.0, Abs(ProductRoots.Re))) then
    raise EDSPError.Create(Operation + ': paired roots do not form real coefficients.');
  FirstCoefficient := -SumRoots.Re;
  SecondCoefficient := ProductRoots.Re;
end;

function PrewarpIIRFrequency(const SampleRateHz, FrequencyHz: Double;
  const Operation: string): Double;
var
  Ratio, Angle: Double;
begin
  if IsNan(FrequencyHz) or IsInfinite(FrequencyHz) or
     (FrequencyHz <= 0.0) or (FrequencyHz >= SampleRateHz * 0.5) then
    raise EDSPError.Create(Operation + ': cutoff must lie strictly between DC and Nyquist.');
  Ratio := FrequencyHz / SampleRateHz;
  Angle := DSP_PI * Ratio;
  if (Ratio <= 0.0) or (Ratio >= 0.5) or
     (Angle <= 0.0) or (Angle >= DSP_PI * 0.5) then
    raise EDSPError.Create(Operation + ': cutoff is outside the representable prewarping range.');
  Result := Tan(Angle);
  if IsNan(Result) or IsInfinite(Result) or (Result <= 0.0) then
    raise EDSPError.Create(Operation + ': cutoff prewarping is not finite.');
end;

function ChebyshevPassbandEpsilon(const RippleDb: Double): Double;
var
  Exponent, Delta: Double;
begin
  Exponent := RippleDb * (Ln(10.0) / 10.0);
  if RippleDb < 1E-6 then
  begin
    Delta := Exponent;
    Result := Sqrt(RippleDb) * Sqrt(Ln(10.0) / 10.0) *
      Sqrt(1.0 + Delta * 0.5 + Delta * Delta / 6.0);
  end
  else
    Result := Sqrt(Exp(Exponent) - 1.0);
end;

function ChebyshevArcSinh(const Value: Double): Double;
begin
  if Value < 1E150 then
    Result := Ln(Value + Sqrt(Value * Value + 1.0))
  else
    Result := Ln(Value) + Ln(2.0);
end;

function BuildIIRPrototypePoles(const Order: SizeInt;
  const Chebyshev: Boolean; const RippleDb: Double;
  out Epsilon: Double): TComplexArray;
var
  I: SizeInt;
  Angle, Mu: Double;
begin
  Result := nil;
  SetLength(Result, Order);
  Epsilon := 0.0;
  if Chebyshev then
  begin
    Epsilon := ChebyshevPassbandEpsilon(RippleDb);
    if (Epsilon <= 0.0) or IsNan(Epsilon) or IsInfinite(Epsilon) then
      raise EDSPError.Create('DesignChebyshevISOS: ripple has no finite epsilon representation.');
    Mu := ChebyshevArcSinh(1.0 / Epsilon) / Order;
    for I := 0 to Order - 1 do
    begin
      Angle := DSP_PI * (2.0 * I + 1.0) / (2.0 * Order);
      Result[I] := TComplex.Create(-Sinh(Mu) * Sin(Angle),
        Cosh(Mu) * Cos(Angle));
    end;
  end
  else
    for I := 0 to Order - 1 do
    begin
      Angle := DSP_PI * (2.0 * I + 1.0 + Order) / (2.0 * Order);
      Result[I] := TComplex.Create(Cos(Angle), Sin(Angle));
    end;
end;

function MapIIRPoleToDigital(const AnalogPole: TComplex;
  const Operation: string): TComplex;
var
  Denominator: TComplex;
begin
  Denominator := TComplex.One - AnalogPole;
  if (Denominator.Re = 0.0) and (Denominator.Im = 0.0) then
    raise EDSPError.Create(Operation + ': bilinear pole mapping is singular.');
  Result := (TComplex.One + AnalogPole) / Denominator;
  if not Result.IsFinite then
    raise EDSPError.Create(Operation + ': bilinear pole mapping overflowed.');
end;

function TransformIIRPoles(const Prototype: TComplexArray;
  const Response: TIIRResponse; const LowWarped, HighWarped: Double):
  TComplexArray;
var
  I, OutputIndex: SizeInt;
  Pole, DiscriminantRoot, Value1, Value2: TComplex;
  Bandwidth, Center: Double;
begin
  Result := nil;
  if Response in [irLowPass, irHighPass] then
    SetLength(Result, Length(Prototype))
  else
    SetLength(Result, 2 * Length(Prototype));
  OutputIndex := 0;
  if Response in [irBandPass, irBandStop] then
  begin
    Bandwidth := HighWarped - LowWarped;
    Center := Sqrt(LowWarped * HighWarped);
  end
  else
  begin
    Bandwidth := LowWarped;
    Center := LowWarped;
  end;

  for I := 0 to High(Prototype) do
  begin
    Pole := Prototype[I];
    case Response of
      irLowPass:
        Value1 := Pole * LowWarped;
      irHighPass:
        Value1 := TComplex.Create(LowWarped, 0.0) / Pole;
      irBandPass:
        begin
          DiscriminantRoot := CSqrt(
            (Pole * Bandwidth) * (Pole * Bandwidth) - 4.0 * Sqr(Center));
          Value1 := (Pole * Bandwidth + DiscriminantRoot) * 0.5;
          Value2 := (Pole * Bandwidth - DiscriminantRoot) * 0.5;
        end;
      irBandStop:
        begin
          DiscriminantRoot := CSqrt(TComplex.Create(Sqr(Bandwidth), 0.0) -
            (Pole * Pole) * (4.0 * Sqr(Center)));
          Value1 := (TComplex.Create(Bandwidth, 0.0) + DiscriminantRoot) /
            (Pole * 2.0);
          Value2 := (TComplex.Create(Bandwidth, 0.0) - DiscriminantRoot) /
            (Pole * 2.0);
        end;
    end;
    if not Value1.IsFinite then
      raise EDSPError.Create('IIR design: analog pole transform overflowed.');
    Result[OutputIndex] := MapIIRPoleToDigital(Value1, 'IIR design');
    Inc(OutputIndex);
    if Response in [irBandPass, irBandStop] then
    begin
      if not Value2.IsFinite then
        raise EDSPError.Create('IIR design: analog pole transform overflowed.');
      Result[OutputIndex] := MapIIRPoleToDigital(Value2, 'IIR design');
      Inc(OutputIndex);
    end;
  end;
end;

function BuildDigitalIIRZeros(const Order: SizeInt; const Response: TIIRResponse;
  const LowWarped, HighWarped: Double): TComplexArray;
var
  I, Count: SizeInt;
  Center, Denominator: Double;
  PositiveZero: TComplex;
begin
  Result := nil;
  if Response in [irLowPass, irHighPass] then
    Count := Order
  else
    Count := 2 * Order;
  SetLength(Result, Count);
  case Response of
    irLowPass:
      for I := 0 to Order - 1 do Result[I] := TComplex.Create(-1.0, 0.0);
    irHighPass:
      for I := 0 to Order - 1 do Result[I] := TComplex.One;
    irBandPass:
      for I := 0 to Order - 1 do
      begin
        Result[I] := TComplex.One;
        Result[Order + I] := TComplex.Create(-1.0, 0.0);
      end;
    irBandStop:
      begin
        Center := Sqrt(LowWarped * HighWarped);
        Denominator := 1.0 + Sqr(Center);
        PositiveZero := TComplex.Create(
          (1.0 - Sqr(Center)) / Denominator,
          (2.0 * Center) / Denominator);
        for I := 0 to Order - 1 do
        begin
          Result[I] := PositiveZero;
          Result[Order + I] := PositiveZero.Conjugate;
        end;
      end;
  end;
end;

function ComplexLogMagnitude(const Value: TComplex;
  const Operation: string): Double;
var
  Scale, NormalizedMagnitude: Double;
begin
  if not Value.IsFinite then
    raise EDSPError.Create(Operation + ': non-finite section response.');
  Scale := Max(Abs(Value.Re), Abs(Value.Im));
  if Scale = 0.0 then
    raise EDSPError.Create(Operation + ': zero section response at normalization frequency.');
  NormalizedMagnitude := Sqrt(Sqr(Value.Re / Scale) + Sqr(Value.Im / Scale));
  Result := Ln(Scale) + Ln(NormalizedMagnitude);
end;

procedure EvaluateSOSSection(const Coefficients: TBiquadCoefficients;
  const FrequencyFraction: Double; out Numerator, Denominator: TComplex);
var
  Angle: Double;
  ZInverse, ZInverseSquared: TComplex;
begin
  Angle := 2.0 * DSP_PI * FrequencyFraction;
  ZInverse := TComplex.Create(Cos(Angle), -Sin(Angle));
  ZInverseSquared := ZInverse * ZInverse;
  Numerator := TComplex.Create(Coefficients.B0, 0.0) +
    ZInverse * Coefficients.B1 + ZInverseSquared * Coefficients.B2;
  Denominator := TComplex.Create(1.0, 0.0) +
    ZInverse * Coefficients.A1 + ZInverseSquared * Coefficients.A2;
end;

function DesignSOSInternal(const Response: TIIRResponse; const Order: SizeInt;
  const SampleRateHz, CutoffOrLowHz, HighCutoffHz, RippleDb: Double;
  const Chebyshev: Boolean): TSOSCoefficients;
var
  Prototype, DigitalPoles, DigitalZeros: TComplexArray;
  PolePairs, ZeroPairs: TSOSRootPairArray;
  I: SizeInt;
  LowWarped, HighWarped, Center, ReferenceHz, ReferenceGainLog: Double;
  Epsilon, SectionGainLog, SectionGain: Double;
  Numerator, Denominator: TComplex;
  Diagnostics: TSOSStabilityDiagnostics;
begin
  Result := nil;
  if (Order < 1) or (Order > MAX_IIR_PROTOTYPE_ORDER) then
    raise EDSPError.CreateFmt(
      'IIR design: prototype order must be between 1 and %d.',
      [MAX_IIR_PROTOTYPE_ORDER]);
  if IsNan(SampleRateHz) or IsInfinite(SampleRateHz) or
     (SampleRateHz <= 0.0) then
    raise EDSPError.Create('IIR design: SampleRateHz must be finite and positive.');
  if (Response < irLowPass) or (Response > irBandStop) then
    raise EDSPError.Create('IIR design: Response is not a valid filter type.');
  if Chebyshev and (IsNan(RippleDb) or IsInfinite(RippleDb) or
     (RippleDb <= 0.0) or (RippleDb > 12.0)) then
    raise EDSPError.Create(
      'DesignChebyshevISOS: PassbandRippleDb must be in (0, 12].');
  if Response in [irLowPass, irHighPass] then
  begin
    if HighCutoffHz <> 0.0 then
      raise EDSPError.Create('IIR design: single-edge response has an unexpected second edge.');
    LowWarped := PrewarpIIRFrequency(SampleRateHz, CutoffOrLowHz, 'IIR design');
    HighWarped := 0.0;
  end
  else
  begin
    if IsNan(HighCutoffHz) or IsInfinite(HighCutoffHz) or
       (HighCutoffHz <= CutoffOrLowHz) then
      raise EDSPError.Create('IIR design: band edges must be finite and strictly increasing.');
    LowWarped := PrewarpIIRFrequency(SampleRateHz, CutoffOrLowHz, 'IIR design');
    HighWarped := PrewarpIIRFrequency(SampleRateHz, HighCutoffHz, 'IIR design');
  end;

  Prototype := BuildIIRPrototypePoles(Order, Chebyshev, RippleDb, Epsilon);
  DigitalPoles := TransformIIRPoles(Prototype, Response, LowWarped, HighWarped);
  DigitalZeros := BuildDigitalIIRZeros(Order, Response, LowWarped, HighWarped);
  PolePairs := PairSOSRoots(DigitalPoles, 'IIR design poles');
  ZeroPairs := PairSOSRoots(DigitalZeros, 'IIR design zeros');
  if Length(PolePairs) <> Length(ZeroPairs) then
    raise EDSPError.Create('IIR design: pole and zero section counts differ.');

  SetLength(Result, Length(PolePairs));
  for I := 0 to High(Result) do
  begin
    Result[I].B0 := 1.0;
    SOSPolynomialFromRoots(ZeroPairs[I], Result[I].B1, Result[I].B2,
      'IIR design zeros');
    SOSPolynomialFromRoots(PolePairs[I], Result[I].A1, Result[I].A2,
      'IIR design poles');
  end;

  if Response = irHighPass then
    ReferenceHz := SampleRateHz * 0.5
  else if Response = irBandPass then
  begin
    Center := Sqrt(LowWarped * HighWarped);
    ReferenceHz := SampleRateHz * ArcTan(Center) / DSP_PI;
  end
  else
    ReferenceHz := 0.0;

  ReferenceGainLog := 0.0;
  if Chebyshev and ((Order mod 2) = 0) then
    ReferenceGainLog := -0.5 * Ln(1.0 + Sqr(Epsilon));
  for I := 0 to High(Result) do
  begin
    EvaluateSOSSection(Result[I], ReferenceHz / SampleRateHz,
      Numerator, Denominator);
    if (Denominator.Re = 0.0) and (Denominator.Im = 0.0) then
      raise EDSPError.CreateFmt('IIR design: section %d has a singular normalization response.', [I]);
    SectionGainLog := ReferenceGainLog / Length(Result) -
      (ComplexLogMagnitude(Numerator, 'IIR design') -
       ComplexLogMagnitude(Denominator, 'IIR design'));
    if (SectionGainLog > 709.0) or (SectionGainLog < -740.0) then
      raise EDSPError.CreateFmt('IIR design: section %d gain is not representable.', [I]);
    SectionGain := Exp(SectionGainLog);
    if IsNan(SectionGain) or IsInfinite(SectionGain) or (SectionGain = 0.0) then
      raise EDSPError.CreateFmt('IIR design: section %d gain is not representable.', [I]);
    Result[I].B0 := Result[I].B0 * SectionGain;
    Result[I].B1 := Result[I].B1 * SectionGain;
    Result[I].B2 := Result[I].B2 * SectionGain;
  end;

  RequireFiniteSOS(Result, 'IIR design');
  Diagnostics := TDSPKit.AnalyzeSOSStability(Result);
  if not Diagnostics.IsStable then
    raise EDSPError.CreateFmt(
      'IIR design: digital section %d is not strictly stable.',
      [Diagnostics.FirstUnstableSection]);
end;

function CheckedSizeAdd(const LeftValue, RightValue: SizeInt;
  const Operation: string): SizeInt;
begin
  if (RightValue > 0) and (LeftValue > High(SizeInt) - RightValue) then
    raise EDSPError.Create(Operation + ': size arithmetic overflow.');
  if (RightValue < 0) and (LeftValue < Low(SizeInt) - RightValue) then
    raise EDSPError.Create(Operation + ': size arithmetic overflow.');
  Result := LeftValue + RightValue;
end;

function CheckedSizeMultiply(const LeftValue, RightValue: SizeInt;
  const Operation: string): SizeInt;
begin
  if (LeftValue < 0) or (RightValue < 0) then
    raise EDSPError.Create(Operation + ': negative allocation size.');
  if (RightValue <> 0) and
    (LeftValue > High(SizeInt) div RightValue) then
    raise EDSPError.Create(Operation + ': size arithmetic overflow.');
  Result := LeftValue * RightValue;
end;

function CheckedArrayBytes(const ElementCount, ElementSize: SizeInt;
  const Operation: string): SizeInt;
begin
  Result := CheckedSizeMultiply(ElementCount, ElementSize, Operation);
end;

function CheckedByteSum(const CurrentValue, AdditionalValue: SizeInt;
  const Operation: string): SizeInt;
begin
  Result := CheckedSizeAdd(CurrentValue, AdditionalValue, Operation);
end;

function SquareModulo(const Value, Modulus: QWord): QWord;
var
  Addend, Multiplier: QWord;
begin
  Result := 0;
  Addend := Value mod Modulus;
  Multiplier := Value;
  while Multiplier <> 0 do
  begin
    if (Multiplier and 1) <> 0 then
      Result := (Result + Addend) mod Modulus;
    Addend := (Addend + Addend) mod Modulus;
    Multiplier := Multiplier shr 1;
  end;
end;

function IsFiniteDouble(const Value: Double): Boolean; inline;
begin
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

function StableMagnitude(const Value: TComplex): Double;
var
  A, B, Swap, Factor: Double;
begin
  A := Abs(Value.Re);
  B := Abs(Value.Im);
  if A < B then
  begin
    Swap := A;
    A := B;
    B := Swap;
  end;
  if A = 0.0 then
    Exit(0.0);
  Factor := Sqrt(1.0 + Sqr(B / A));
  if A > MaxDouble / Factor then
    Result := Infinity
  else
    Result := A * Factor;
end;

procedure AcquireBusyFlag(var Busy: LongInt; const Operation: string);
begin
  if InterlockedCompareExchange(Busy, 1, 0) <> 0 then
    raise EDSPError.Create(Operation + ': plan is already executing.');
end;

procedure ReleaseBusyFlag(var Busy: LongInt); inline;
begin
  InterlockedExchange(Busy, 0);
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

constructor TFFTPlan.Create(const ATransformLength: SizeInt);
var
  I, Bit, Bits, ReverseIndex, Value, MinimumWork, TotalBytes,
    ArrayBytes: SizeInt;
  Angle, ChirpAngle: Double;
  Chirp: TComplex;
begin
  inherited Create;
  FBusy := 0;
  FLength := ATransformLength;
  if FLength < 1 then
    raise EDSPError.Create('TFFTPlan.Create: TransformLength must be positive.');

  FIsBluestein := (FLength and (FLength - 1)) <> 0;
  if FIsBluestein then
  begin
    if FLength > (High(SizeInt) div 2) + 1 then
      raise EDSPError.Create(
        'TFFTPlan.Create: Bluestein workspace dimension overflows.');
    MinimumWork := 2 * FLength - 1;
    FWorkLength := NextPowerOfTwo(MinimumWork);
  end
  else
    FWorkLength := FLength;

  { Prove every array payload and the retained-byte total representable before
    asking the allocator for any part of a plan. }
  TotalBytes := 0;
  ArrayBytes := CheckedArrayBytes(FWorkLength, SizeOf(TComplex),
    'TFFTPlan.Create workspace');
  TotalBytes := CheckedByteSum(TotalBytes, ArrayBytes,
    'TFFTPlan.Create retained storage');
  ArrayBytes := CheckedArrayBytes(FWorkLength div 2, SizeOf(TComplex),
    'TFFTPlan.Create twiddle table');
  TotalBytes := CheckedByteSum(TotalBytes, ArrayBytes,
    'TFFTPlan.Create retained storage');
  ArrayBytes := CheckedArrayBytes(FWorkLength, SizeOf(SizeInt),
    'TFFTPlan.Create bit-reversal table');
  TotalBytes := CheckedByteSum(TotalBytes, ArrayBytes,
    'TFFTPlan.Create retained storage');
  if FIsBluestein then
  begin
    ArrayBytes := CheckedArrayBytes(FWorkLength, SizeOf(TComplex),
      'TFFTPlan.Create Bluestein kernel');
    TotalBytes := CheckedByteSum(TotalBytes, ArrayBytes,
      'TFFTPlan.Create retained storage');
    ArrayBytes := CheckedArrayBytes(FLength, SizeOf(TComplex),
      'TFFTPlan.Create chirp table');
    TotalBytes := CheckedByteSum(TotalBytes, ArrayBytes,
      'TFFTPlan.Create retained storage');
  end;

  SetLength(FWorkspace, FWorkLength);
  SetLength(FBitReverse, FWorkLength);
  SetLength(FTwiddles, FWorkLength div 2);
  Bits := 0;
  Value := FWorkLength;
  while Value > 1 do
  begin
    Inc(Bits);
    Value := Value shr 1;
  end;
  for I := 0 to FWorkLength - 1 do
  begin
    Value := I;
    ReverseIndex := 0;
    for Bit := 1 to Bits do
    begin
      ReverseIndex := (ReverseIndex shl 1) or (Value and 1);
      Value := Value shr 1;
    end;
    FBitReverse[I] := ReverseIndex;
  end;
  for I := 0 to High(FTwiddles) do
  begin
    Angle := -2.0 * DSP_PI * Double(I) / Double(FWorkLength);
    FTwiddles[I] := TComplex.Create(Cos(Angle), Sin(Angle));
  end;

  if FIsBluestein then
  begin
    SetLength(FChirp, FLength);
    for I := 0 to FLength - 1 do
    begin
      { n^2 only affects exp(i*pi*n^2/N) modulo 2N. Reducing it as an
        integer keeps large chirp phases accurate before libm range reduction. }
      ChirpAngle := DSP_PI *
        Double(SquareModulo(QWord(I), 2 * QWord(FLength))) /
        Double(FLength);
      FChirp[I] := TComplex.Create(Cos(ChirpAngle), -Sin(ChirpAngle));
      Chirp := FChirp[I].Conjugate;
      FWorkspace[I] := Chirp;
      if I > 0 then
        FWorkspace[FWorkLength - I] := Chirp;
    end;
    Radix2Prepared(False);
    FBluesteinKernel := FWorkspace;
    FWorkspace := nil;
    SetLength(FWorkspace, FWorkLength);
  end;

  FRetainedBytes := TotalBytes;
end;

destructor TFFTPlan.Destroy;
begin
  FWorkspace := nil;
  FTwiddles := nil;
  FBluesteinKernel := nil;
  FChirp := nil;
  FBitReverse := nil;
  inherited Destroy;
end;

procedure TFFTPlan.Acquire;
begin
  AcquireBusyFlag(FBusy, 'TFFTPlan.ExecuteInto');
end;

procedure TFFTPlan.Release;
begin
  ReleaseBusyFlag(FBusy);
end;

procedure TFFTPlan.Radix2Prepared(const Inverse: Boolean);
var
  I, J, StageLength, HalfLength, BlockStart, TwiddleIndex: SizeInt;
  EvenValue, OddValue, Twiddle: TComplex;
begin
  for I := 0 to FWorkLength - 1 do
    if I < FBitReverse[I] then
    begin
      EvenValue := FWorkspace[I];
      FWorkspace[I] := FWorkspace[FBitReverse[I]];
      FWorkspace[FBitReverse[I]] := EvenValue;
    end;

  StageLength := 2;
  while StageLength <= FWorkLength do
  begin
    HalfLength := StageLength shr 1;
    BlockStart := 0;
    while BlockStart < FWorkLength do
    begin
      for J := 0 to HalfLength - 1 do
      begin
        TwiddleIndex := J * (FWorkLength div StageLength);
        Twiddle := FTwiddles[TwiddleIndex];
        if Inverse then
          Twiddle := Twiddle.Conjugate;
        EvenValue := FWorkspace[BlockStart + J];
        OddValue := FWorkspace[BlockStart + J + HalfLength] * Twiddle;
        FWorkspace[BlockStart + J] := EvenValue + OddValue;
        FWorkspace[BlockStart + J + HalfLength] := EvenValue - OddValue;
      end;
      Inc(BlockStart, StageLength);
    end;
    if StageLength = FWorkLength then
      Break;
    StageLength := StageLength shl 1;
  end;
end;

procedure TFFTPlan.TransformPrepared(const Input: TComplexArray;
  const Inverse: Boolean; const Normalization: TFFTNormalization);
var
  I: SizeInt;
  Value, Product: TComplex;
  Scale: Double;
begin
  Scale := NormalizationScale(FLength, Inverse, Normalization);
  if FIsBluestein then
  begin
    for I := 0 to FLength - 1 do
    begin
      Value := Input[I];
      if Inverse then
        Value.Im := -Value.Im;
      FWorkspace[I] := Value * FChirp[I];
    end;
    for I := FLength to FWorkLength - 1 do
      FWorkspace[I] := TComplex.Zero;
    Radix2Prepared(False);
    for I := 0 to FWorkLength - 1 do
      FWorkspace[I] := FWorkspace[I] * FBluesteinKernel[I];
    Radix2Prepared(True);
    for I := 0 to FLength - 1 do
    begin
      Product := (FWorkspace[I] * (1.0 / Double(FWorkLength))) * FChirp[I];
      if Inverse then
        Product := Product.Conjugate;
      FWorkspace[I] := Product * Scale;
    end;
  end
  else
  begin
    for I := 0 to FLength - 1 do
      FWorkspace[I] := Input[I];
    Radix2Prepared(Inverse);
    if Scale <> 1.0 then
      for I := 0 to FLength - 1 do
        FWorkspace[I] := FWorkspace[I] * Scale;
  end;

  for I := 0 to FLength - 1 do
    if not FWorkspace[I].IsFinite then
      raise EDSPError.CreateFmt(
        'TFFTPlan.Execute: numerical overflow at output bin %d.', [I]);
end;

function TFFTPlan.Execute(const Input: TComplexArray;
  const Inverse: Boolean; const Normalization: TFFTNormalization):
  TComplexArray;
begin
  Result := nil;
  SetLength(Result, FLength);
  ExecuteInto(Input, Result, Inverse, Normalization);
end;

procedure TFFTPlan.ExecuteInto(const Input: TComplexArray;
  var Destination: TComplexArray; const Inverse: Boolean;
  const Normalization: TFFTNormalization);
var
  I: SizeInt;
begin
  Acquire;
  try
    if Length(Input) <> FLength then
      raise EDSPError.CreateFmt(
        'TFFTPlan.ExecuteInto: input length must be %d; got %d.',
        [FLength, Length(Input)]);
    if Length(Destination) <> FLength then
      raise EDSPError.CreateFmt(
        'TFFTPlan.ExecuteInto: destination length must be %d; got %d.',
        [FLength, Length(Destination)]);
    { Calling this also validates the enumeration before any output is touched. }
    NormalizationScale(FLength, Inverse, Normalization);
    RequireFinite(Input, 'TFFTPlan.ExecuteInto');
    try
      TransformPrepared(Input, Inverse, Normalization);
    except
      on E: EMathError do
        raise EDSPError.Create(
          'TFFTPlan.ExecuteInto: floating-point failure during transform.');
    end;
    for I := 0 to FLength - 1 do
      Destination[I] := FWorkspace[I];
  finally
    Release;
  end;
end;

function TFFTPlan.TransformLength: SizeInt;
begin
  Result := FLength;
end;

function TFFTPlan.WorkspaceElements: SizeInt;
begin
  Result := Length(FWorkspace);
end;

function TFFTPlan.RetainedBytes: SizeInt;
begin
  Result := FRetainedBytes;
end;

constructor TSTFTPlan.Create(const ASampleCount, AFrameLength,
  AHopLength: SizeInt; const WindowType: TWindowType);
var
  Numerator, FullHops, I, Frame, LocalIndex, PaddedIndex, SampleIndex,
    WindowBytes, FrameBytes, DenominatorBytes, AccumulatorBytes,
    ResultBytes, SpectrumElements, SpectrumBytes, OwnBytes, TotalBytes:
    SizeInt;
  MinimumDenominator, MaximumDenominator, Weight, AddedValue: Double;
begin
  inherited Create;
  FBusy := 0;
  FSampleCount := ASampleCount;
  FFrameLength := AFrameLength;
  FHopLength := AHopLength;
  if FSampleCount < 1 then
    raise EDSPError.Create('TSTFTPlan.Create: SampleCount must be positive.');
  if (FFrameLength < 2) or (FFrameLength > High(Integer)) then
    raise EDSPError.Create(
      'TSTFTPlan.Create: FrameLength must be in [2, High(Integer)].');
  if (FHopLength < 1) or (FHopLength > FFrameLength) then
    raise EDSPError.Create(
      'TSTFTPlan.Create: HopLength must be in [1, FrameLength].');
  case WindowType of
    wtRectangular, wtHamming, wtHann, wtBlackman: ;
  else
    raise EDSPError.Create('TSTFTPlan.Create: unknown window type.');
  end;

  FLeftPadding := FFrameLength - 1;
  Numerator := CheckedSizeAdd(FSampleCount, FFrameLength - 2,
    'TSTFTPlan.Create frame count');
  FullHops := Numerator div FHopLength;
  if (Numerator mod FHopLength) <> 0 then
    FullHops := CheckedSizeAdd(FullHops, 1,
      'TSTFTPlan.Create frame count');
  FFrameCount := CheckedSizeAdd(FullHops, 1,
    'TSTFTPlan.Create frame count');
  FPaddedLength := CheckedSizeAdd(FFrameLength,
    CheckedSizeMultiply(FFrameCount - 1, FHopLength,
      'TSTFTPlan.Create padded length'), 'TSTFTPlan.Create padded length');
  FRightPadding := CheckedSizeAdd(FPaddedLength, -FLeftPadding,
    'TSTFTPlan.Create right padding');
  FRightPadding := CheckedSizeAdd(FRightPadding, -FSampleCount,
    'TSTFTPlan.Create right padding');
  if FRightPadding < 0 then
    raise EDSPError.Create('TSTFTPlan.Create: invalid padding geometry.');

  SpectrumElements := CheckedSizeMultiply(FFrameCount, FFrameLength,
    'TSTFTPlan.Create spectrum matrix');
  SpectrumBytes := CheckedArrayBytes(SpectrumElements, SizeOf(TComplex),
    'TSTFTPlan.Create spectrum matrix');
  WindowBytes := CheckedArrayBytes(FFrameLength, SizeOf(Double),
    'TSTFTPlan.Create window');
  FrameBytes := CheckedArrayBytes(FFrameLength, SizeOf(TComplex),
    'TSTFTPlan.Create frame workspace');
  DenominatorBytes := CheckedArrayBytes(FSampleCount, SizeOf(Double),
    'TSTFTPlan.Create denominator');
  AccumulatorBytes := CheckedArrayBytes(FPaddedLength, SizeOf(Double),
    'TSTFTPlan.Create overlap accumulator');
  ResultBytes := CheckedArrayBytes(FSampleCount, SizeOf(Double),
    'TSTFTPlan.Create result staging');
  OwnBytes := 0;
  OwnBytes := CheckedByteSum(OwnBytes, SpectrumBytes,
    'TSTFTPlan.Create retained storage');
  OwnBytes := CheckedByteSum(OwnBytes, WindowBytes,
    'TSTFTPlan.Create retained storage');
  OwnBytes := CheckedByteSum(OwnBytes, FrameBytes,
    'TSTFTPlan.Create retained storage');
  OwnBytes := CheckedByteSum(OwnBytes, DenominatorBytes,
    'TSTFTPlan.Create retained storage');
  OwnBytes := CheckedByteSum(OwnBytes, AccumulatorBytes,
    'TSTFTPlan.Create retained storage');
  OwnBytes := CheckedByteSum(OwnBytes, ResultBytes,
    'TSTFTPlan.Create retained storage');
  TotalBytes := OwnBytes;
  { The nested plan performs its own checked sizing before allocating. }
  FFFT := TFFTPlan.Create(FFrameLength);
  TotalBytes := CheckedByteSum(TotalBytes, FFFT.RetainedBytes,
    'TSTFTPlan.Create retained storage');

  FWindow := TSignalKit.GenerateWindow(WindowType, Integer(FFrameLength));
  SetLength(FDenominator, FSampleCount);
  for I := 0 to FSampleCount - 1 do
    FDenominator[I] := 0.0;
  for Frame := 0 to FFrameCount - 1 do
    for LocalIndex := 0 to FFrameLength - 1 do
    begin
      PaddedIndex := Frame * FHopLength + LocalIndex;
      SampleIndex := PaddedIndex - FLeftPadding;
      if (SampleIndex >= 0) and (SampleIndex < FSampleCount) then
      begin
        Weight := FWindow[LocalIndex];
        AddedValue := Weight * Weight;
        FDenominator[SampleIndex] :=
          SafeSum(FDenominator[SampleIndex], AddedValue,
            'TSTFTPlan.Create coverage denominator');
      end;
    end;

  MinimumDenominator := MaxDouble;
  MaximumDenominator := 0.0;
  for I := 0 to FSampleCount - 1 do
  begin
    if not IsFiniteDouble(FDenominator[I]) then
      raise EDSPError.Create(
        'TSTFTPlan.Create: coverage denominator is non-finite.');
    if FDenominator[I] < MinimumDenominator then
      MinimumDenominator := FDenominator[I];
    if FDenominator[I] > MaximumDenominator then
      MaximumDenominator := FDenominator[I];
  end;
  if (MaximumDenominator <= 0.0) or
    (MinimumDenominator <= 1E-12 * MaximumDenominator) then
    raise EDSPError.Create(
      'TSTFTPlan.Create: window and hop do not provide conditioned coverage.');

  SetLength(FFrame, FFrameLength);
  SetLength(FAccumulator, FPaddedLength);
  SetLength(FStagedResult, FSampleCount);
  FStagedSpectrum := TDenseComplexMatrix.Zeros(FFrameCount, FFrameLength);
  FRetainedBytes := TotalBytes;
end;

destructor TSTFTPlan.Destroy;
begin
  FFFT.Free;
  FFFT := nil;
  FWindow := nil;
  FDenominator := nil;
  FFrame := nil;
  FAccumulator := nil;
  FStagedResult := nil;
  FStagedSpectrum := nil;
  inherited Destroy;
end;

procedure TSTFTPlan.Acquire;
begin
  AcquireBusyFlag(FBusy, 'TSTFTPlan');
end;

procedure TSTFTPlan.Release;
begin
  ReleaseBusyFlag(FBusy);
end;

function TSTFTPlan.Analyze(const Input: TDoubleArray): IDenseComplexMatrix;
begin
  Result := nil;
  Result := TDenseComplexMatrix.Zeros(FFrameCount, FFrameLength);
  AnalyzeInto(Input, Result);
end;

procedure TSTFTPlan.AnalyzeInto(const Input: TDoubleArray;
  const Destination: IDenseComplexMatrix);
var
  Frame, LocalIndex, SampleIndex, I: SizeInt;
  FrameStart: SizeInt;
  Value: Double;
begin
  Acquire;
  try
    if Length(Input) <> FSampleCount then
      raise EDSPError.CreateFmt(
        'TSTFTPlan.AnalyzeInto: input length must be %d; got %d.',
        [FSampleCount, Length(Input)]);
    RequireFinite(Input, 'TSTFTPlan.AnalyzeInto');
    if Destination = nil then
      raise EDSPError.Create(
        'TSTFTPlan.AnalyzeInto: destination matrix must not be nil.');
    if (Destination.Rows <> FFrameCount) or
      (Destination.Cols <> FFrameLength) then
      raise EDSPError.CreateFmt(
        'TSTFTPlan.AnalyzeInto: destination must have shape %d x %d.',
        [FFrameCount, FFrameLength]);

    for Frame := 0 to FFrameCount - 1 do
    begin
      FrameStart := Frame * FHopLength - FLeftPadding;
      for LocalIndex := 0 to FFrameLength - 1 do
      begin
        SampleIndex := FrameStart + LocalIndex;
        if (SampleIndex < 0) or (SampleIndex >= FSampleCount) then
          Value := 0.0
        else
          Value := SafeProduct(Input[SampleIndex], FWindow[LocalIndex],
            'TSTFTPlan.AnalyzeInto windowing');
        FFrame[LocalIndex] := TComplex.Create(Value, 0.0);
      end;
      FFFT.ExecuteInto(FFrame, FFrame, False, fnNone);
      for I := 0 to FFrameLength - 1 do
        FStagedSpectrum[Frame, I] := FFrame[I];
    end;

    { Publish only after every frame was validated and transformed. }
    for Frame := 0 to FFrameCount - 1 do
      for I := 0 to FFrameLength - 1 do
        Destination[Frame, I] := FStagedSpectrum[Frame, I];
  finally
    Release;
  end;
end;

procedure TSTFTPlan.ValidateSpectrum(const Spectrum: IDenseComplexMatrix);
var
  Frame, Bin, PairBin: SizeInt;
  Value, PairValue: TComplex;
  Scale, Magnitude, ResidualReal, ResidualImag, Tolerance: Double;
begin
  if Spectrum = nil then
    raise EDSPError.Create('TSTFTPlan.Synthesize: spectrum matrix must not be nil.');
  if (Spectrum.Rows <> FFrameCount) or
    (Spectrum.Cols <> FFrameLength) then
    raise EDSPError.CreateFmt(
      'TSTFTPlan.Synthesize: spectrum must have shape %d x %d.',
      [FFrameCount, FFrameLength]);

  for Frame := 0 to FFrameCount - 1 do
  begin
    Scale := 1.0;
    for Bin := 0 to FFrameLength - 1 do
    begin
      Value := Spectrum[Frame, Bin];
      if not Value.IsFinite then
        raise EDSPError.CreateFmt(
          'TSTFTPlan.Synthesize: spectrum frame %d bin %d must be finite.',
          [Frame, Bin]);
      Magnitude := StableMagnitude(Value);
      if not IsFiniteDouble(Magnitude) then
        raise EDSPError.CreateFmt(
          'TSTFTPlan.Synthesize: spectrum magnitude overflows at frame %d bin %d.',
          [Frame, Bin]);
      if Magnitude > Scale then
        Scale := Magnitude;
    end;
    Tolerance := 1E-11;
    Value := Spectrum[Frame, 0];
    if Abs(Value.Im / Scale) > Tolerance then
      raise EDSPError.CreateFmt(
        'TSTFTPlan.Synthesize: frame %d has a non-real DC bin.', [Frame]);
    for Bin := 1 to (FFrameLength - 1) div 2 do
    begin
      PairBin := FFrameLength - Bin;
      Value := Spectrum[Frame, Bin];
      PairValue := Spectrum[Frame, PairBin];
      ResidualReal := Value.Re / Scale - PairValue.Re / Scale;
      ResidualImag := Value.Im / Scale + PairValue.Im / Scale;
      if StableMagnitude(TComplex.Create(ResidualReal, ResidualImag)) >
        Tolerance then
        raise EDSPError.CreateFmt(
          'TSTFTPlan.Synthesize: frame %d bins %d and %d are not conjugates.',
          [Frame, Bin, PairBin]);
    end;
    if (FFrameLength mod 2) = 0 then
    begin
      Value := Spectrum[Frame, FFrameLength div 2];
      if Abs(Value.Im / Scale) > Tolerance then
        raise EDSPError.CreateFmt(
          'TSTFTPlan.Synthesize: frame %d has a non-real Nyquist bin.',
          [Frame]);
    end;
  end;
end;

function TSTFTPlan.Synthesize(const Spectrum: IDenseComplexMatrix):
  TDoubleArray;
begin
  Result := nil;
  SetLength(Result, FSampleCount);
  SynthesizeInto(Spectrum, Result);
end;

procedure TSTFTPlan.SynthesizeInto(const Spectrum: IDenseComplexMatrix;
  var Destination: TDoubleArray);
var
  Frame, LocalIndex, PaddedIndex, SampleIndex, I: SizeInt;
  Contribution: Double;
begin
  Acquire;
  try
    if Length(Destination) <> FSampleCount then
      raise EDSPError.CreateFmt(
        'TSTFTPlan.SynthesizeInto: destination length must be %d; got %d.',
        [FSampleCount, Length(Destination)]);
    ValidateSpectrum(Spectrum);

    for I := 0 to FPaddedLength - 1 do
      FAccumulator[I] := 0.0;
    for Frame := 0 to FFrameCount - 1 do
    begin
      for LocalIndex := 0 to FFrameLength - 1 do
        FFrame[LocalIndex] := Spectrum[Frame, LocalIndex];
      FFFT.ExecuteInto(FFrame, FFrame, True, fnBackward);
      for LocalIndex := 0 to FFrameLength - 1 do
      begin
        PaddedIndex := Frame * FHopLength + LocalIndex;
        { The inverse frame already contains x*w; multiply by w once so
          overlap-add accumulates x*w^2 for the precomputed denominator. }
        Contribution := SafeProduct(FFrame[LocalIndex].Re,
          FWindow[LocalIndex],
          'TSTFTPlan.Synthesize overlap-add');
        FAccumulator[PaddedIndex] := SafeSum(FAccumulator[PaddedIndex],
          Contribution, 'TSTFTPlan.Synthesize overlap-add');
      end;
    end;

    for I := 0 to FSampleCount - 1 do
    begin
      SampleIndex := FLeftPadding + I;
      FStagedResult[I] := FAccumulator[SampleIndex] / FDenominator[I];
      if not IsFiniteDouble(FStagedResult[I]) then
        raise EDSPError.CreateFmt(
          'TSTFTPlan.Synthesize: numerical overflow at sample %d.', [I]);
    end;
    for I := 0 to FSampleCount - 1 do
      Destination[I] := FStagedResult[I];
  finally
    Release;
  end;
end;

function TSTFTPlan.SampleCount: SizeInt;
begin
  Result := FSampleCount;
end;

function TSTFTPlan.FrameLength: SizeInt;
begin
  Result := FFrameLength;
end;

function TSTFTPlan.HopLength: SizeInt;
begin
  Result := FHopLength;
end;

function TSTFTPlan.FrameCount: SizeInt;
begin
  Result := FFrameCount;
end;

function TSTFTPlan.LeftPadding: SizeInt;
begin
  Result := FLeftPadding;
end;

function TSTFTPlan.RightPadding: SizeInt;
begin
  Result := FRightPadding;
end;

function TSTFTPlan.RetainedBytes: SizeInt;
begin
  Result := FRetainedBytes;
end;

procedure Radix2Unscaled(var Values: TComplexArray; const Inverse: Boolean);
var
  N, I, J, Bit, TransformLength, HalfLength, BlockStart: SizeInt;
  Direction, StepAngle, StepRe, StepIm, TwiddleRe, TwiddleIm,
    NextTwiddleRe, ProductRe, ProductIm: Double;
  Temporary, EvenValue, OddValue: TComplex;
begin
  N := Length(Values);
  if N <= 1 then
    Exit;
  if (N and (N - 1)) <> 0 then
    raise EDSPError.Create(
      'Radix2Unscaled: transform length must be a power of two.');

  { Reuse the established in-place portable kernel while its Integer indexing
    can represent the complete array. The SizeInt recurrence below preserves
    the applied-DSP contract for larger address spaces. The legacy inverse
    kernel applies 1/N, so undo that normalization here: this helper's contract
    is deliberately unscaled in both directions. }
  if N <= High(Integer) then
  begin
    TSignalKit.FFT(Values, Inverse);
    if Inverse then
      ScaleComplex(Values, N);
    Exit;
  end;

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
    StepAngle := Direction * 2.0 * DSP_PI / TransformLength;
    StepRe := Cos(StepAngle);
    StepIm := Sin(StepAngle);
    BlockStart := 0;
    while BlockStart < N do
    begin
      TwiddleRe := 1.0;
      TwiddleIm := 0.0;
      for J := 0 to HalfLength - 1 do
      begin
        EvenValue := Values[BlockStart + J];
        OddValue := Values[BlockStart + J + HalfLength];
        ProductRe := TwiddleRe * OddValue.Re - TwiddleIm * OddValue.Im;
        ProductIm := TwiddleRe * OddValue.Im + TwiddleIm * OddValue.Re;
        Values[BlockStart + J] := TComplex.Create(
          EvenValue.Re + ProductRe, EvenValue.Im + ProductIm);
        Values[BlockStart + J + HalfLength] := TComplex.Create(
          EvenValue.Re - ProductRe, EvenValue.Im - ProductIm);
        NextTwiddleRe := TwiddleRe * StepRe - TwiddleIm * StepIm;
        TwiddleIm := TwiddleRe * StepIm + TwiddleIm * StepRe;
        TwiddleRe := NextTwiddleRe;
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

class function TDSPKit.DesignButterworthSOS(const Response: TIIRResponse;
  const Order: SizeInt; const SampleRateHz, CutoffHz: Double):
  TSOSCoefficients;
begin
  if not (Response in [irLowPass, irHighPass]) then
    raise EDSPError.Create(
      'DesignButterworthSOS: this overload requires a low-pass or high-pass response.');
  Result := DesignSOSInternal(Response, Order, SampleRateHz, CutoffHz, 0.0,
    0.0, False);
end;

class function TDSPKit.DesignButterworthSOS(const Response: TIIRResponse;
  const Order: SizeInt; const SampleRateHz, LowCutoffHz,
  HighCutoffHz: Double): TSOSCoefficients;
begin
  if not (Response in [irBandPass, irBandStop]) then
    raise EDSPError.Create(
      'DesignButterworthSOS: this overload requires a band-pass or band-stop response.');
  Result := DesignSOSInternal(Response, Order, SampleRateHz, LowCutoffHz,
    HighCutoffHz, 0.0, False);
end;

class function TDSPKit.DesignChebyshevISOS(const Response: TIIRResponse;
  const Order: SizeInt; const SampleRateHz, CutoffHz,
  PassbandRippleDb: Double): TSOSCoefficients;
begin
  if not (Response in [irLowPass, irHighPass]) then
    raise EDSPError.Create(
      'DesignChebyshevISOS: this overload requires a low-pass or high-pass response.');
  Result := DesignSOSInternal(Response, Order, SampleRateHz, CutoffHz, 0.0,
    PassbandRippleDb, True);
end;

class function TDSPKit.DesignChebyshevISOS(const Response: TIIRResponse;
  const Order: SizeInt; const SampleRateHz, LowCutoffHz,
  HighCutoffHz, PassbandRippleDb: Double): TSOSCoefficients;
begin
  if not (Response in [irBandPass, irBandStop]) then
    raise EDSPError.Create(
      'DesignChebyshevISOS: this overload requires a band-pass or band-stop response.');
  Result := DesignSOSInternal(Response, Order, SampleRateHz, LowCutoffHz,
    HighCutoffHz, PassbandRippleDb, True);
end;

class function TDSPKit.AnalyzeSOSStability(
  const Coefficients: TSOSCoefficients): TSOSStabilityDiagnostics;
var
  I: SizeInt;
  SectionStable: Boolean;
  Radius: Double;
begin
  RequireFiniteSOS(Coefficients, 'AnalyzeSOSStability');
  Result.IsStable := True;
  Result.MaximumPoleRadius := 0.0;
  Result.MinimumStabilityMargin := 1.0;
  Result.FirstUnstableSection := -1;
  for I := 0 to High(Coefficients) do
  begin
    { Jury's strict second-order conditions for z^2 + A1*z + A2. }
    SectionStable := (Coefficients[I].A2 > -1.0) and
      (Coefficients[I].A2 < 1.0) and
      (Coefficients[I].A1 > -1.0 - Coefficients[I].A2) and
      (Coefficients[I].A1 < 1.0 + Coefficients[I].A2);
    Radius := SOSSectionPoleRadius(Coefficients[I].A1,
      Coefficients[I].A2);
    Result.MaximumPoleRadius := Max(Result.MaximumPoleRadius, Radius);
    if not SectionStable then
    begin
      Result.IsStable := False;
      if Result.FirstUnstableSection < 0 then
        Result.FirstUnstableSection := I;
    end;
  end;
  Result.MinimumStabilityMargin := 1.0 - Result.MaximumPoleRadius;
end;

class function TDSPKit.EvaluateSOSResponse(
  const Coefficients: TSOSCoefficients; const SampleRateHz: Double;
  const FrequenciesHz: TDoubleArray): TSOSFrequencyResponse;
var
  I, J: SizeInt;
  Angle: Double;
  ZInverse, ZInverseSquared, Numerator, Denominator, Value: TComplex;
begin
  RequireFiniteSOS(Coefficients, 'EvaluateSOSResponse');
  if IsNan(SampleRateHz) or IsInfinite(SampleRateHz) or
     (SampleRateHz <= 0.0) then
    raise EDSPError.Create(
      'EvaluateSOSResponse: SampleRateHz must be finite and positive.');
  if Length(FrequenciesHz) = 0 then
    raise EDSPError.Create(
      'EvaluateSOSResponse: at least one frequency is required.');
  for I := 0 to High(FrequenciesHz) do
    if IsNan(FrequenciesHz[I]) or IsInfinite(FrequenciesHz[I]) or
       (FrequenciesHz[I] < 0.0) or
       (FrequenciesHz[I] > SampleRateHz * 0.5) then
      raise EDSPError.CreateFmt(
        'EvaluateSOSResponse: frequency %d must lie in [0, Nyquist].', [I]);

  Result.FrequenciesHz := Copy(FrequenciesHz);
  Result.Values := nil;
  SetLength(Result.Values, Length(FrequenciesHz));
  for I := 0 to High(FrequenciesHz) do
  begin
    Angle := 2.0 * DSP_PI * (FrequenciesHz[I] / SampleRateHz);
    ZInverse := TComplex.Create(Cos(Angle), -Sin(Angle));
    ZInverseSquared := ZInverse * ZInverse;
    Value := TComplex.One;
    for J := 0 to High(Coefficients) do
    begin
      Numerator := TComplex.Create(Coefficients[J].B0, 0.0) +
        ZInverse * Coefficients[J].B1 +
        ZInverseSquared * Coefficients[J].B2;
      Denominator := TComplex.Create(1.0, 0.0) +
        ZInverse * Coefficients[J].A1 +
        ZInverseSquared * Coefficients[J].A2;
      if (Denominator.Re = 0.0) and (Denominator.Im = 0.0) then
        raise EDSPError.CreateFmt(
          'EvaluateSOSResponse: section %d has a zero denominator at frequency %g Hz.',
          [J, FrequenciesHz[I]]);
      Value := (Value * Numerator) / Denominator;
      if not Value.IsFinite then
        raise EDSPError.CreateFmt(
          'EvaluateSOSResponse: response overflow at frequency %g Hz.',
          [FrequenciesHz[I]]);
    end;
    Result.Values[I] := Value;
  end;
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

class function TStreamingSOSFilter.Create(
  const Coefficients: TSOSCoefficients): TStreamingSOSFilter;
var
  Diagnostics: TSOSStabilityDiagnostics;
begin
  RequireFiniteSOS(Coefficients, 'TStreamingSOSFilter.Create');
  if Length(Coefficients) > High(SizeInt) div 2 then
    raise EDSPError.Create(
      'TStreamingSOSFilter.Create: state size overflow.');
  Diagnostics := TDSPKit.AnalyzeSOSStability(Coefficients);
  if not Diagnostics.IsStable then
    raise EDSPError.CreateFmt(
      'TStreamingSOSFilter.Create: section %d is not strictly stable.',
      [Diagnostics.FirstUnstableSection]);
  Result.FSections := Copy(Coefficients);
  SetLength(Result.FState, 2 * Length(Coefficients));
end;

procedure TStreamingSOSFilter.Reset;
begin
  if Length(FSections) = 0 then
    raise EDSPError.Create('TStreamingSOSFilter.Reset: filter is not initialized.');
  FState := nil;
  SetLength(FState, 2 * Length(FSections));
end;

function TStreamingSOSFilter.ProcessBlock(
  const Input: TDoubleArray): TDoubleArray;
var
  NewState: TDoubleArray;
  I, J, StateIndex: SizeInt;
  Value, OutputValue, NewZ1, NewZ2: Double;
begin
  if (Length(FSections) = 0) or
     (Length(FState) <> 2 * Length(FSections)) then
    raise EDSPError.Create(
      'TStreamingSOSFilter.ProcessBlock: filter state is not initialized.');
  RequireFinite(Input, 'TStreamingSOSFilter.ProcessBlock');
  NewState := Copy(FState);
  Result := nil;
  SetLength(Result, Length(Input));
  for I := 0 to High(Input) do
  begin
    Value := Input[I];
    for J := 0 to High(FSections) do
    begin
      StateIndex := 2 * J;
      OutputValue := SafeSum(SafeProduct(FSections[J].B0, Value,
        'TStreamingSOSFilter.ProcessBlock'), NewState[StateIndex],
        'TStreamingSOSFilter.ProcessBlock');
      NewZ1 := SafeSum(SafeSum(
        SafeProduct(FSections[J].B1, Value,
          'TStreamingSOSFilter.ProcessBlock'),
        -SafeProduct(FSections[J].A1, OutputValue,
          'TStreamingSOSFilter.ProcessBlock'),
        'TStreamingSOSFilter.ProcessBlock'), NewState[StateIndex + 1],
        'TStreamingSOSFilter.ProcessBlock');
      NewZ2 := SafeSum(
        SafeProduct(FSections[J].B2, Value,
          'TStreamingSOSFilter.ProcessBlock'),
        -SafeProduct(FSections[J].A2, OutputValue,
          'TStreamingSOSFilter.ProcessBlock'),
        'TStreamingSOSFilter.ProcessBlock');
      if IsNan(OutputValue) or IsInfinite(OutputValue) or
         IsNan(NewZ1) or IsInfinite(NewZ1) or
         IsNan(NewZ2) or IsInfinite(NewZ2) then
        raise EDSPError.CreateFmt(
          'TStreamingSOSFilter.ProcessBlock: numerical overflow at sample %d, section %d.',
          [I, J]);
      NewState[StateIndex] := NewZ1;
      NewState[StateIndex + 1] := NewZ2;
      Value := OutputValue;
    end;
    Result[I] := Value;
  end;
  FState := NewState;
end;

function TStreamingSOSFilter.State: TDoubleArray;
begin
  Result := Copy(FState);
end;

procedure TStreamingSOSFilter.RestoreState(const Values: TDoubleArray);
begin
  if (Length(FSections) = 0) or
     (Length(FState) <> 2 * Length(FSections)) then
    raise EDSPError.Create(
      'TStreamingSOSFilter.RestoreState: filter state is not initialized.');
  if Length(Values) <> Length(FState) then
    raise EDSPError.CreateFmt(
      'TStreamingSOSFilter.RestoreState: expected %d values; got %d.',
      [Length(FState), Length(Values)]);
  RequireFinite(Values, 'TStreamingSOSFilter.RestoreState');
  FState := Copy(Values);
end;

function TStreamingSOSFilter.Coefficients: TSOSCoefficients;
begin
  Result := Copy(FSections);
end;

function TStreamingSOSFilter.SectionCount: SizeInt;
begin
  Result := Length(FSections);
end;

function TStreamingSOSFilter.StateSize: SizeInt;
begin
  Result := Length(FState);
end;

end.
