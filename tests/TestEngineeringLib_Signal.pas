unit TestEngineeringLib_Signal;

{-----------------------------------------------------------------------------
 TestEngineeringLib_Signal

 Comprehensive tests for EngineeringLib.Signal:
   - MovingAverage
   - Window generation (Rectangular, Hamming, Hann, Blackman)
   - ApplyWindow
   - FFT (Cooley-Tukey): linearity, Parseval, round-trip IFFT
   - FFT magnitude / phase
   - FIR filter design (low-pass, high-pass, band-pass, band-stop)
   - ApplyFIRFilter
   - SignalPower, SignalEnergy, RootMeanSquare
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  EngineeringLib.Signal;

type
  TTestSignalKit = class(TTestCase)
  private
    const
      TOL_TIGHT  = 1E-9;
      TOL_FFT    = 1E-8;   { floating-point accumulation in FFT }
      TOL_FILTER = 1E-6;   { FIR: DC gain tolerance }

    procedure AssertArraysNear(const Msg: string; const Expected, Actual: TDoubleArray; Tol: Double);
    procedure AssertNear(const Expected, Actual, Tol: Double; const Msg: String = '');

    { Exception helpers }
    procedure DoMovingAverageWithZeroWindow;
    procedure DoMovingAverageWithLargeWindow;
    procedure DoApplyWindowWithMismatchedSizes;
    procedure DoFFT_NotPow2;
    procedure DoFFT_MismatchedArrays;
    procedure DoFIR_LP_BadCutoff_High;
    procedure DoFIR_LP_BadCutoff_Low;
    procedure DoFIR_BP_SwappedCutoffs;

  published
    { --- Moving Average --- }
    procedure TestMovingAverage_Size3;
    procedure TestMovingAverage_Size1;
    procedure TestMovingAverage_SizeEqLength;
    procedure TestMovingAverage_NilInput;
    procedure TestMovingAverage_ZeroWindowRaises;
    procedure TestMovingAverage_TooLargeWindowRaises;

    { --- Window Generation --- }
    procedure TestWindow_Rectangular;
    procedure TestWindow_Hamming_Endpoints;
    procedure TestWindow_Hamming_Centre;
    procedure TestWindow_Hann_Endpoints;
    procedure TestWindow_Hann_Centre;
    procedure TestWindow_Blackman_Endpoints;
    procedure TestWindow_Size1;

    { --- ApplyWindow --- }
    procedure TestApplyWindow_Rectangular;
    procedure TestApplyWindow_Hann;
    procedure TestApplyWindow_MismatchRaises;
    procedure TestApplyWindow_Empty;

    { --- FFT (Cooley-Tukey) --- }
    procedure TestFFT_ImpulseAtZero;
    procedure TestFFT_RoundTrip_Random;
    procedure TestFFT_Parseval;
    procedure TestFFT_Linearity;
    procedure TestFFT_DCComponent;
    procedure TestFFT_NyquistFrequency;
    procedure TestFFT_NotPow2Raises;
    procedure TestFFT_MismatchedArraysRaises;
    procedure TestFFT_Length1;
    procedure TestFFT_Length2;

    { --- Magnitude / Phase --- }
    procedure TestMagnitudePhase_Impulse;
    procedure TestMagnitudePhase_DCSignal;

    { --- FIR Filter Design --- }
    procedure TestFIR_LowPass_DCGain;
    procedure TestFIR_LowPass_Symmetry;
    procedure TestFIR_LowPass_Length;
    procedure TestFIR_HighPass_DCGain;
    procedure TestFIR_HighPass_NyquistGain;
    procedure TestFIR_HighPass_Symmetry;
    procedure TestFIR_BandPass_Length;
    procedure TestFIR_BandPass_Symmetry;
    procedure TestFIR_BandStop_DCGain;
    procedure TestFIR_BadCutoffHighRaises;
    procedure TestFIR_BadCutoffLowRaises;
    procedure TestFIR_BandPass_SwappedRaises;

    { --- ApplyFIRFilter --- }
    procedure TestApplyFIR_Impulse;
    procedure TestApplyFIR_OutputLength;
    procedure TestApplyFIR_Step;
    procedure TestApplyFIR_NilSignal;
    procedure TestApplyFIR_NilCoeffs;

    { --- Signal Properties --- }
    procedure TestSignalPower;
    procedure TestSignalEnergy;
    procedure TestRootMeanSquare;
    procedure TestSignalPower_Empty;
    procedure TestSignalEnergy_Empty;
    procedure TestRootMeanSquare_Empty;
  end;

implementation

{ =========================================================================
  Helpers
  ========================================================================= }

procedure TTestSignalKit.AssertArraysNear(const Msg: string; const Expected, Actual: TDoubleArray; Tol: Double);
var I: Integer;
begin
  AssertEquals(Msg + ': length', Length(Expected), Length(Actual));
  for I := 0 to High(Expected) do
    AssertTrue(Msg + Format('[%d] expected %.10g got %.10g', [I, Expected[I], Actual[I]]),
      Abs(Expected[I] - Actual[I]) <= Tol);
end;

procedure TTestSignalKit.AssertNear(const Expected, Actual, Tol: Double; const Msg: String);
begin
  AssertTrue(Msg + Format(' (exp %.10g, got %.10g)', [Expected, Actual]),
    Abs(Expected - Actual) <= Tol);
end;

{ ---- exception helpers ---- }

procedure TTestSignalKit.DoMovingAverageWithZeroWindow;
var S: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3);
  TSignalKit.MovingAverage(S, 0);
end;

procedure TTestSignalKit.DoMovingAverageWithLargeWindow;
var S: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3);
  TSignalKit.MovingAverage(S, 4);
end;

procedure TTestSignalKit.DoApplyWindowWithMismatchedSizes;
var S, W: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3);
  W := TDoubleArray.Create(1, 2);
  TSignalKit.ApplyWindow(S, W);
end;

procedure TTestSignalKit.DoFFT_NotPow2;
var Re, Im: TDoubleArray;
begin
  SetLength(Re, 3); SetLength(Im, 3);
  TSignalKit.FFT(Re, Im);
end;

procedure TTestSignalKit.DoFFT_MismatchedArrays;
var Re, Im: TDoubleArray;
begin
  SetLength(Re, 4); SetLength(Im, 8);
  TSignalKit.FFT(Re, Im);
end;

procedure TTestSignalKit.DoFIR_LP_BadCutoff_High;
begin
  TSignalKit.DesignFIRLowPass(0.5, 32);
end;

procedure TTestSignalKit.DoFIR_LP_BadCutoff_Low;
begin
  TSignalKit.DesignFIRLowPass(0.0, 32);
end;

procedure TTestSignalKit.DoFIR_BP_SwappedCutoffs;
begin
  TSignalKit.DesignFIRBandPass(0.3, 0.1, 32);
end;

{ =========================================================================
  Moving Average
  ========================================================================= }

procedure TTestSignalKit.TestMovingAverage_Size3;
var Input, Expected, Actual: TDoubleArray;
begin
  Input    := TDoubleArray.Create(1, 2, 3, 4, 5, 6);
  Expected := TDoubleArray.Create(2, 2, 2, 3, 4, 5);
  Actual   := TSignalKit.MovingAverage(Input, 3);
  AssertArraysNear('MA size 3', Expected, Actual, TOL_TIGHT);
end;

procedure TTestSignalKit.TestMovingAverage_Size1;
var Input, Expected, Actual: TDoubleArray;
begin
  Input    := TDoubleArray.Create(1, 2, 3, 4, 5, 6);
  Expected := TDoubleArray.Create(1, 2, 3, 4, 5, 6);
  Actual   := TSignalKit.MovingAverage(Input, 1);
  AssertArraysNear('MA size 1', Expected, Actual, TOL_TIGHT);
end;

procedure TTestSignalKit.TestMovingAverage_SizeEqLength;
var Input, Expected, Actual: TDoubleArray;
begin
  Input    := TDoubleArray.Create(1, 2, 3, 4, 5, 6);
  Expected := TDoubleArray.Create(3.5, 3.5, 3.5, 3.5, 3.5, 3.5);
  Actual   := TSignalKit.MovingAverage(Input, 6);
  AssertArraysNear('MA size=length', Expected, Actual, TOL_TIGHT);
end;

procedure TTestSignalKit.TestMovingAverage_NilInput;
var Actual: TDoubleArray;
begin
  Actual := TSignalKit.MovingAverage(nil, 3);
  AssertEquals('MA nil returns nil/empty', 0, Length(Actual));
end;

procedure TTestSignalKit.TestMovingAverage_ZeroWindowRaises;
begin
  AssertException('MA zero window raises', EInvalidOp, @DoMovingAverageWithZeroWindow);
end;

procedure TTestSignalKit.TestMovingAverage_TooLargeWindowRaises;
begin
  AssertException('MA too-large window raises', EInvalidOp, @DoMovingAverageWithLargeWindow);
end;

{ =========================================================================
  Window Generation
  ========================================================================= }

procedure TTestSignalKit.TestWindow_Rectangular;
var W: TDoubleArray;
    I: Integer;
begin
  W := TSignalKit.GenerateWindow(wtRectangular, 8);
  AssertEquals('Rect window length', 8, Length(W));
  for I := 0 to 7 do
    AssertNear(1.0, W[I], TOL_TIGHT, Format('Rect[%d]', [I]));
end;

procedure TTestSignalKit.TestWindow_Hamming_Endpoints;
var W: TDoubleArray;
begin
  { Hamming: w(0) = 0.54 - 0.46 = 0.08, w(N-1) = same }
  W := TSignalKit.GenerateWindow(wtHamming, 9);
  AssertNear(0.08, W[0],   1E-10, 'Hamming w[0]');
  AssertNear(0.08, W[8],   1E-10, 'Hamming w[N-1]');
end;

procedure TTestSignalKit.TestWindow_Hamming_Centre;
var W: TDoubleArray;
begin
  { Centre of even-length: w[4] for size 9 → 0.54 + 0.46 = 1.0 }
  W := TSignalKit.GenerateWindow(wtHamming, 9);
  AssertNear(1.0, W[4], 1E-10, 'Hamming w[centre]');
end;

procedure TTestSignalKit.TestWindow_Hann_Endpoints;
var W: TDoubleArray;
begin
  { Hann: w(0) = 0, w(N-1) = 0 }
  W := TSignalKit.GenerateWindow(wtHann, 8);
  AssertNear(0.0, W[0],   TOL_TIGHT, 'Hann w[0]');
  AssertNear(0.0, W[7],   TOL_TIGHT, 'Hann w[N-1]');
end;

procedure TTestSignalKit.TestWindow_Hann_Centre;
var W: TDoubleArray;
begin
  { Hann size 5: centre at index 2 → 0.5*(1 - cos(2π*2/4)) = 0.5*(1-cos(π)) = 1.0 }
  W := TSignalKit.GenerateWindow(wtHann, 5);
  AssertNear(1.0, W[2], 1E-10, 'Hann w[centre]');
end;

procedure TTestSignalKit.TestWindow_Blackman_Endpoints;
var W: TDoubleArray;
begin
  { Blackman: w(0) = 0.42-0.5+0.08 = 0 }
  W := TSignalKit.GenerateWindow(wtBlackman, 8);
  AssertNear(0.0, W[0], 1E-10, 'Blackman w[0]');
  AssertNear(0.0, W[7], 1E-10, 'Blackman w[N-1]');
end;

procedure TTestSignalKit.TestWindow_Size1;
var W: TDoubleArray;
begin
  W := TSignalKit.GenerateWindow(wtHamming, 1);
  AssertEquals('Size-1 window length', 1, Length(W));
  AssertNear(1.0, W[0], TOL_TIGHT, 'Size-1 w[0]');
end;

{ =========================================================================
  ApplyWindow
  ========================================================================= }

procedure TTestSignalKit.TestApplyWindow_Rectangular;
var S, W, R, Expected: TDoubleArray;
begin
  S        := TDoubleArray.Create(1, 2, 3, 4, 5);
  W        := TSignalKit.GenerateWindow(wtRectangular, 5);
  Expected := TDoubleArray.Create(1, 2, 3, 4, 5);
  R        := TSignalKit.ApplyWindow(S, W);
  AssertArraysNear('ApplyWindow rect', Expected, R, TOL_TIGHT);
end;

procedure TTestSignalKit.TestApplyWindow_Hann;
var S, W, R: TDoubleArray;
    I: Integer;
begin
  S := TDoubleArray.Create(1, 1, 1, 1, 1);
  W := TSignalKit.GenerateWindow(wtHann, 5);
  R := TSignalKit.ApplyWindow(S, W);
  AssertEquals('ApplyWindow Hann length', 5, Length(R));
  { Each element should equal the window value }
  for I := 0 to 4 do
    AssertNear(W[I], R[I], TOL_TIGHT, Format('ApplyWindow Hann[%d]', [I]));
end;

procedure TTestSignalKit.TestApplyWindow_MismatchRaises;
begin
  AssertException('ApplyWindow mismatch raises', EInvalidOp,
    @DoApplyWindowWithMismatchedSizes);
end;

procedure TTestSignalKit.TestApplyWindow_Empty;
var R: TDoubleArray;
begin
  R := TSignalKit.ApplyWindow(nil, nil);
  AssertEquals('ApplyWindow empty = nil/empty', 0, Length(R));
end;

{ =========================================================================
  FFT
  ========================================================================= }

procedure TTestSignalKit.TestFFT_ImpulseAtZero;
{ δ[0] → FFT = all-ones spectrum }
var Re, Im: TDoubleArray;
    N, I: Integer;
begin
  N := 8;
  SetLength(Re, N); SetLength(Im, N);
  Re[0] := 1;
  TSignalKit.FFT(Re, Im);
  for I := 0 to N - 1 do
  begin
    AssertNear(1.0, Re[I], TOL_FFT, Format('Impulse FFT Re[%d]', [I]));
    AssertNear(0.0, Im[I], TOL_FFT, Format('Impulse FFT Im[%d]', [I]));
  end;
end;

procedure TTestSignalKit.TestFFT_RoundTrip_Random;
{ FFT then IFFT must reproduce the original signal }
var Re, Im, OutSig: TDoubleArray;
    OrigRe: TDoubleArray;
    N, I: Integer;
begin
  N := 16;
  SetLength(Re, N); SetLength(Im, N);
  SetLength(OrigRe, N);
  for I := 0 to N - 1 do
  begin
    Re[I]     := Sin(2 * Pi * I / N) + 0.5 * Cos(6 * Pi * I / N);
    OrigRe[I] := Re[I];
    Im[I]     := 0;
  end;
  TSignalKit.CalculateIFFT(Re, Im, OutSig);
  { After building FFT and IFFT we need to actually do the forward first }
  { Use the convenience pair: CalculateFFT then CalculateIFFT }
  TSignalKit.CalculateFFT(OrigRe, Re, Im);
  TSignalKit.CalculateIFFT(Re, Im, OutSig);
  for I := 0 to N - 1 do
    AssertNear(OrigRe[I], OutSig[I], TOL_FFT,
      Format('Round-trip[%d]', [I]));
end;

procedure TTestSignalKit.TestFFT_Parseval;
{ Parseval: Σ|x[n]|² = (1/N) Σ|X[k]|²  }
var Re, Im: TDoubleArray;
    N, I: Integer;
    TimeEnergy, FreqEnergy: Double;
    Signal: TDoubleArray;
begin
  N := 8;
  SetLength(Signal, N);
  for I := 0 to N - 1 do
    Signal[I] := I + 1.0;

  TimeEnergy := 0;
  for I := 0 to N - 1 do TimeEnergy := TimeEnergy + Sqr(Signal[I]);

  TSignalKit.CalculateFFT(Signal, Re, Im);

  FreqEnergy := 0;
  for I := 0 to N - 1 do
    FreqEnergy := FreqEnergy + Sqr(Re[I]) + Sqr(Im[I]);
  FreqEnergy := FreqEnergy / N;

  AssertNear(TimeEnergy, FreqEnergy, 1E-6, 'Parseval theorem');
end;

procedure TTestSignalKit.TestFFT_Linearity;
{ FFT(a*x + b*y) = a*FFT(x) + b*FFT(y) }
var X, Y, XY, Re_X, Im_X, Re_Y, Im_Y, Re_XY, Im_XY: TDoubleArray;
    N, I: Integer;
    A, B: Double;
begin
  N := 8; A := 2.0; B := 3.0;
  SetLength(X, N); SetLength(Y, N); SetLength(XY, N);
  for I := 0 to N - 1 do
  begin
    X[I]  := Sin(2 * Pi * I / N);
    Y[I]  := Cos(4 * Pi * I / N);
    XY[I] := A * X[I] + B * Y[I];
  end;
  TSignalKit.CalculateFFT(X,  Re_X,  Im_X);
  TSignalKit.CalculateFFT(Y,  Re_Y,  Im_Y);
  TSignalKit.CalculateFFT(XY, Re_XY, Im_XY);
  for I := 0 to N - 1 do
  begin
    AssertNear(A*Re_X[I] + B*Re_Y[I], Re_XY[I], TOL_FFT,
      Format('Linearity Re[%d]', [I]));
    AssertNear(A*Im_X[I] + B*Im_Y[I], Im_XY[I], TOL_FFT,
      Format('Linearity Im[%d]', [I]));
  end;
end;

procedure TTestSignalKit.TestFFT_DCComponent;
{ Constant signal x[n]=c → X[0]=N*c, X[k≠0]=0 }
var Sig, Re, Im: TDoubleArray;
    N, I: Integer;
    C: Double;
begin
  N := 8; C := 3.0;
  SetLength(Sig, N);
  for I := 0 to N - 1 do Sig[I] := C;
  TSignalKit.CalculateFFT(Sig, Re, Im);
  AssertNear(N * C, Re[0], TOL_FFT, 'DC Re[0]');
  AssertNear(0.0,   Im[0], TOL_FFT, 'DC Im[0]');
  for I := 1 to N - 1 do
  begin
    AssertNear(0.0, Re[I], TOL_FFT, Format('DC Re[%d]', [I]));
    AssertNear(0.0, Im[I], TOL_FFT, Format('DC Im[%d]', [I]));
  end;
end;

procedure TTestSignalKit.TestFFT_NyquistFrequency;
{ Alternating +1/-1 → energy only at k=N/2 }
var Sig, Re, Im: TDoubleArray;
    N, I: Integer;
begin
  N := 8;
  SetLength(Sig, N);
  for I := 0 to N - 1 do
    Sig[I] := IfThen(Odd(I), -1.0, 1.0);
  TSignalKit.CalculateFFT(Sig, Re, Im);
  { X[0] should be ~0 }
  AssertNear(0.0, Re[0], TOL_FFT, 'Nyquist: Re[0]=0');
  { X[N/2] should be N }
  AssertNear(N * 1.0, Abs(Re[N div 2]), TOL_FFT, 'Nyquist: |X[N/2]|=N');
end;

procedure TTestSignalKit.TestFFT_NotPow2Raises;
begin
  AssertException('FFT non-pow2 raises', EInvalidArgument, @DoFFT_NotPow2);
end;

procedure TTestSignalKit.TestFFT_MismatchedArraysRaises;
begin
  AssertException('FFT mismatched arrays raises', EInvalidArgument,
    @DoFFT_MismatchedArrays);
end;

procedure TTestSignalKit.TestFFT_Length1;
var Re, Im: TDoubleArray;
begin
  SetLength(Re, 1); SetLength(Im, 1);
  Re[0] := 5; Im[0] := 3;
  TSignalKit.FFT(Re, Im);   { must not crash }
  AssertNear(5.0, Re[0], TOL_TIGHT, 'FFT length-1 Re');
  AssertNear(3.0, Im[0], TOL_TIGHT, 'FFT length-1 Im');
end;

procedure TTestSignalKit.TestFFT_Length2;
{ x=[1,1] → X=[2,0] }
var Re, Im: TDoubleArray;
begin
  SetLength(Re, 2); SetLength(Im, 2);
  Re[0] := 1; Re[1] := 1; Im[0] := 0; Im[1] := 0;
  TSignalKit.FFT(Re, Im);
  AssertNear(2.0, Re[0], TOL_FFT, 'FFT length-2 X[0]');
  AssertNear(0.0, Re[1], TOL_FFT, 'FFT length-2 X[1]');
  AssertNear(0.0, Im[0], TOL_FFT, 'FFT length-2 Im[0]');
  AssertNear(0.0, Im[1], TOL_FFT, 'FFT length-2 Im[1]');
end;

{ =========================================================================
  Magnitude / Phase
  ========================================================================= }

procedure TTestSignalKit.TestMagnitudePhase_Impulse;
var Sig, Mag, Ph: TDoubleArray;
    N, I: Integer;
begin
  N := 8;
  SetLength(Sig, N);
  Sig[0] := 1.0;
  TSignalKit.CalculateFFTMagnitudePhase(Sig, Mag, Ph);
  for I := 0 to N - 1 do
    AssertNear(1.0, Mag[I], TOL_FFT,
      Format('Impulse magnitude[%d]', [I]));
end;

procedure TTestSignalKit.TestMagnitudePhase_DCSignal;
{ All-ones signal of length 8: magnitude[0]=8, rest≈0 }
var Sig, Mag, Ph: TDoubleArray;
    N, I: Integer;
begin
  N := 8;
  SetLength(Sig, N);
  for I := 0 to N - 1 do Sig[I] := 1.0;
  TSignalKit.CalculateFFTMagnitudePhase(Sig, Mag, Ph);
  AssertNear(8.0, Mag[0], TOL_FFT, 'DC magnitude[0]');
  for I := 1 to N - 1 do
    AssertNear(0.0, Mag[I], TOL_FFT, Format('DC magnitude[%d]', [I]));
end;

{ =========================================================================
  FIR Filter Design
  ========================================================================= }

function SumArray(const A: TDoubleArray): Double;
var I: Integer;
begin Result := 0; for I := 0 to High(A) do Result := Result + A[I]; end;

function SumArrayAbs(const A: TDoubleArray): Double;
var I: Integer;
begin Result := 0; for I := 0 to High(A) do Result := Result + Abs(A[I]); end;

procedure TTestSignalKit.TestFIR_LowPass_DCGain;
var C: TDoubleArray;
begin
  { Normalised DC gain = sum of coefficients = 1 }
  C := TSignalKit.DesignFIRLowPass(0.25, 32);
  AssertNear(1.0, SumArray(C), TOL_FILTER, 'LP DC gain = 1');
end;

procedure TTestSignalKit.TestFIR_LowPass_Symmetry;
{ Linear-phase FIR must have symmetric coefficients }
var C: TDoubleArray;
    I: Integer;
begin
  C := TSignalKit.DesignFIRLowPass(0.2, 32);
  for I := 0 to High(C) div 2 do
    AssertNear(C[I], C[High(C) - I], 1E-12,
      Format('LP symmetry coeff[%d]', [I]));
end;

procedure TTestSignalKit.TestFIR_LowPass_Length;
var C: TDoubleArray;
begin
  C := TSignalKit.DesignFIRLowPass(0.2, 32);
  AssertEquals('LP length', 33, Length(C));   { Order+1 }
end;

procedure TTestSignalKit.TestFIR_HighPass_DCGain;
{ High-pass: DC gain = sum ≈ 0 }
var C: TDoubleArray;
begin
  C := TSignalKit.DesignFIRHighPass(0.25, 32);
  AssertNear(0.0, SumArray(C), TOL_FILTER, 'HP DC gain = 0');
end;

procedure TTestSignalKit.TestFIR_HighPass_NyquistGain;
{ Nyquist gain: alternating sign sum should be close to 1.
  Windowed-sinc normalisation introduces ~0.15% error at this order. }
var C: TDoubleArray;
    AltSum: Double;
    I: Integer;
begin
  C := TSignalKit.DesignFIRHighPass(0.25, 32);
  AltSum := 0;
  for I := 0 to High(C) do
    AltSum := AltSum + C[I] * IntPower(-1, I);
  AssertNear(1.0, Abs(AltSum), 2E-3, 'HP Nyquist gain');
end;

procedure TTestSignalKit.TestFIR_HighPass_Symmetry;
var C: TDoubleArray;
    I: Integer;
begin
  C := TSignalKit.DesignFIRHighPass(0.25, 32);
  for I := 0 to High(C) div 2 do
    AssertNear(C[I], C[High(C) - I], 1E-12,
      Format('HP symmetry coeff[%d]', [I]));
end;

procedure TTestSignalKit.TestFIR_BandPass_Length;
var C: TDoubleArray;
begin
  C := TSignalKit.DesignFIRBandPass(0.1, 0.3, 32);
  AssertEquals('BP length', 33, Length(C));
end;

procedure TTestSignalKit.TestFIR_BandPass_Symmetry;
var C: TDoubleArray;
    I: Integer;
begin
  C := TSignalKit.DesignFIRBandPass(0.1, 0.3, 32);
  for I := 0 to High(C) div 2 do
    AssertNear(C[I], C[High(C) - I], 1E-12,
      Format('BP symmetry coeff[%d]', [I]));
end;

procedure TTestSignalKit.TestFIR_BandStop_DCGain;
{ Band-stop: DC is passed → sum of coefficients ≈ 1 }
var C: TDoubleArray;
begin
  C := TSignalKit.DesignFIRBandStop(0.1, 0.3, 32);
  AssertNear(1.0, SumArray(C), TOL_FILTER, 'BS DC gain = 1');
end;

procedure TTestSignalKit.TestFIR_BadCutoffHighRaises;
begin
  AssertException('LP cutoff >= 0.5 raises', EInvalidArgument,
    @DoFIR_LP_BadCutoff_High);
end;

procedure TTestSignalKit.TestFIR_BadCutoffLowRaises;
begin
  AssertException('LP cutoff <= 0 raises', EInvalidArgument,
    @DoFIR_LP_BadCutoff_Low);
end;

procedure TTestSignalKit.TestFIR_BandPass_SwappedRaises;
begin
  AssertException('BP low>high raises', EInvalidArgument,
    @DoFIR_BP_SwappedCutoffs);
end;

{ =========================================================================
  ApplyFIRFilter
  ========================================================================= }

procedure TTestSignalKit.TestApplyFIR_Impulse;
{ Filter * impulse = filter coefficients (shifted) }
var Sig, H, Out: TDoubleArray;
    I: Integer;
begin
  H   := TDoubleArray.Create(0.25, 0.5, 0.25);
  Sig := TDoubleArray.Create(1, 0, 0, 0, 0);
  Out := TSignalKit.ApplyFIRFilter(Sig, H);
  { Out = H convolved with impulse = H padded with zeros }
  AssertNear(0.25, Out[0], TOL_TIGHT, 'Impulse response Out[0]');
  AssertNear(0.5,  Out[1], TOL_TIGHT, 'Impulse response Out[1]');
  AssertNear(0.25, Out[2], TOL_TIGHT, 'Impulse response Out[2]');
  for I := 3 to High(Out) do
    AssertNear(0.0, Out[I], TOL_TIGHT, Format('Impulse response Out[%d]', [I]));
end;

procedure TTestSignalKit.TestApplyFIR_OutputLength;
{ Output length = length(signal) + length(coeffs) - 1 }
var Sig, H, Out: TDoubleArray;
begin
  Sig := TDoubleArray.Create(1, 2, 3, 4, 5);   { length 5 }
  H   := TDoubleArray.Create(0.25, 0.5, 0.25); { length 3 }
  Out := TSignalKit.ApplyFIRFilter(Sig, H);
  AssertEquals('FIR output length', 7, Length(Out));
end;

procedure TTestSignalKit.TestApplyFIR_Step;
{ Constant signal [1,1,1,1,1] through H=[0.25,0.5,0.25]:
  In steady-state the output should equal the DC gain of the filter (=1.0) }
var Sig, H, Out: TDoubleArray;
begin
  Sig := TDoubleArray.Create(1, 1, 1, 1, 1, 1, 1, 1);
  H   := TDoubleArray.Create(0.25, 0.5, 0.25);
  Out := TSignalKit.ApplyFIRFilter(Sig, H);
  { Middle of output should be 1.0 (steady-state) }
  AssertNear(1.0, Out[4], TOL_TIGHT, 'FIR step steady-state');
end;

procedure TTestSignalKit.TestApplyFIR_NilSignal;
var H, Out: TDoubleArray;
begin
  H   := TDoubleArray.Create(0.5, 0.5);
  Out := TSignalKit.ApplyFIRFilter(nil, H);
  AssertEquals('FIR nil signal = nil', 0, Length(Out));
end;

procedure TTestSignalKit.TestApplyFIR_NilCoeffs;
var Sig, Out: TDoubleArray;
begin
  Sig := TDoubleArray.Create(1, 2, 3);
  Out := TSignalKit.ApplyFIRFilter(Sig, nil);
  AssertEquals('FIR nil coeffs = nil', 0, Length(Out));
end;

{ =========================================================================
  Signal Properties
  ========================================================================= }

procedure TTestSignalKit.TestSignalPower;
var S: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3, 4);  { SumSq=30, N=4 → power=7.5 }
  AssertNear(7.5, TSignalKit.SignalPower(S), TOL_TIGHT, 'SignalPower');
end;

procedure TTestSignalKit.TestSignalEnergy;
var S: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3, 4);  { SumSq=30 }
  AssertNear(30.0, TSignalKit.SignalEnergy(S), TOL_TIGHT, 'SignalEnergy');
end;

procedure TTestSignalKit.TestRootMeanSquare;
var S: TDoubleArray;
begin
  S := TDoubleArray.Create(1, 2, 3, 4);  { power=7.5, RMS=sqrt(7.5) }
  AssertNear(Sqrt(7.5), TSignalKit.RootMeanSquare(S), TOL_TIGHT, 'RMS');
end;

procedure TTestSignalKit.TestSignalPower_Empty;
begin
  AssertNear(0.0, TSignalKit.SignalPower(nil), TOL_TIGHT, 'Power empty');
end;

procedure TTestSignalKit.TestSignalEnergy_Empty;
begin
  AssertNear(0.0, TSignalKit.SignalEnergy(nil), TOL_TIGHT, 'Energy empty');
end;

procedure TTestSignalKit.TestRootMeanSquare_Empty;
begin
  AssertNear(0.0, TSignalKit.RootMeanSquare(nil), TOL_TIGHT, 'RMS empty');
end;

initialization
  RegisterTest(TTestSignalKit);

end.
