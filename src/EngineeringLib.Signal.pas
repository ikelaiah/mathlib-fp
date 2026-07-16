unit EngineeringLib.Signal;

{-----------------------------------------------------------------------------
 EngineeringLib.Signal

 Digital signal processing toolkit.

 Provides:
   Basic Filtering
     MovingAverage    — simple sliding-window average

   Windowing
     GenerateWindow   — Rectangular, Hamming, Hann, Blackman
     ApplyWindow      — element-wise multiply signal × window

   FFT / Spectral Analysis
     FFT              — in-place Cooley-Tukey radix-2 DIT (N must be power of 2)
     IFFT             — inverse FFT
     CalculateFFT     — convenience wrapper: real input → complex output arrays
     CalculateIFFT    — inverse: complex arrays → real output
     CalculateFFTMagnitudePhase — magnitude and phase spectra

   FIR Filter Design (windowed-sinc)
     DesignFIRLowPass   — low-pass FIR coefficients
     DesignFIRHighPass  — high-pass FIR coefficients
     DesignFIRBandPass  — band-pass FIR coefficients
     DesignFIRBandStop  — band-stop (notch) FIR coefficients
     ApplyFIRFilter     — convolve signal with FIR coefficients

   Signal Properties
     SignalPower      — mean square
     SignalEnergy     — sum of squares
     RootMeanSquare   — RMS value
-----------------------------------------------------------------------------}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, EngineeringLib.Common;

type
  TDoubleArray = array of Double;

  TWindowType = (wtRectangular, wtHamming, wtHann, wtBlackman);

  TSignalKit = class
  public
    { --- Basic Filtering --- }
    class function MovingAverage(const InputSignal: TDoubleArray; WindowSize: Integer): TDoubleArray; static;

    { --- Windowing --- }
    class function GenerateWindow(WindowType: TWindowType; Size: Integer): TDoubleArray; static;
    class function ApplyWindow(const InputSignal, Window: TDoubleArray): TDoubleArray; static;

    { --- FFT / Spectral Analysis ---
      FFT and IFFT operate on complex data split into separate Real/Imag arrays.
      N must be a power of 2. }

    { In-place Cooley-Tukey radix-2 DIT FFT.
      RealPart and ImagPart must both have length N (a power of 2).
      Set Inverse=True for IFFT (includes the 1/N scaling). }
    class procedure FFT(var RealPart, ImagPart: TDoubleArray; Inverse: Boolean = False); static;

    { Convenience wrapper: real-valued input signal → complex spectrum.
      Pads or truncates to the nearest power-of-2 length automatically.
      OutRealPart[0..N/2] and OutImagPart[0..N/2] are the one-sided spectrum. }
    class procedure CalculateFFT(
      const InputSignal: TDoubleArray;
      out OutRealPart, OutImagPart: TDoubleArray); overload; static;

    { Inverse FFT: complex spectrum → real-valued signal. }
    class procedure CalculateIFFT(const InRealPart, InImagPart: TDoubleArray; out OutputSignal: TDoubleArray); static;

    { Magnitude and phase spectra (one-sided, 0..N/2). }
    class procedure CalculateFFTMagnitudePhase(
      const InputSignal: TDoubleArray;
      out Magnitude, Phase: TDoubleArray); static;

    { --- FIR Filter Design (windowed-sinc) ---
      CutoffFreq is normalised: 0 < fc < 0.5 (where 0.5 = Nyquist).
      Order is the filter order (number of coefficients = Order+1; must be even
      for symmetric linear-phase FIR).
      WindowType selects the window used to taper the ideal sinc kernel. }

    class function DesignFIRLowPass(
      CutoffFreq: Double;
      Order: Integer;
      WindowType: TWindowType = wtHamming): TDoubleArray; static;

    class function DesignFIRHighPass(
      CutoffFreq: Double;
      Order: Integer;
      WindowType: TWindowType = wtHamming): TDoubleArray; static;

    class function DesignFIRBandPass(
      LowCutoff, HighCutoff: Double;
      Order: Integer;
      WindowType: TWindowType = wtHamming): TDoubleArray; static;

    class function DesignFIRBandStop(
      LowCutoff, HighCutoff: Double;
      Order: Integer;
      WindowType: TWindowType = wtHamming): TDoubleArray; static;

    { Convolve Signal with FIR Coefficients (linear/direct-form convolution).
      Output length = Length(Signal) + Length(Coeffs) - 1. }
    class function ApplyFIRFilter(const Signal, Coeffs: TDoubleArray): TDoubleArray; static;

    { --- Signal Properties --- }
    class function SignalPower(const InputSignal: TDoubleArray): Double; static;
    class function SignalEnergy(const InputSignal: TDoubleArray): Double; static;
    class function RootMeanSquare(const InputSignal: TDoubleArray): Double; static;
  end;

implementation

{ ---------------------------------------------------------------------------
  Helpers
  --------------------------------------------------------------------------- }

{ Return smallest power of 2 >= N }
function NextPow2(N: Integer): Integer;
begin
  Result := 1;
  while Result < N do Result := Result shl 1;
end;

{ Bit-reversal permutation for Cooley-Tukey }
procedure BitReverse(var Re, Im: TDoubleArray);
var
  N, I, J, K: Integer;
  Tmp: Double;
begin
  N := Length(Re);
  J := 0;
  for I := 1 to N - 1 do
  begin
    K := N shr 1;
    while J >= K do begin J := J - K; K := K shr 1; end;
    J := J + K;
    if I < J then
    begin
      Tmp := Re[I]; Re[I] := Re[J]; Re[J] := Tmp;
      Tmp := Im[I]; Im[I] := Im[J]; Im[J] := Tmp;
    end;
  end;
end;

{ ---------------------------------------------------------------------------
  TSignalKit — Moving Average
  --------------------------------------------------------------------------- }

class function TSignalKit.MovingAverage(const InputSignal: TDoubleArray; WindowSize: Integer): TDoubleArray;
var
  N, I: Integer;
  Sum: Double;
begin
  if InputSignal = nil then
    Exit(nil);

  N := Length(InputSignal);
  if (WindowSize <= 0) or (WindowSize > N) then
    raise ESignalError.Create('Invalid window size for moving average.');

  SetLength(Result, N);

  Sum := 0.0;
  for I := 0 to WindowSize - 1 do
    Sum := Sum + InputSignal[I];
  Result[WindowSize - 1] := Sum / WindowSize;

  for I := WindowSize to N - 1 do
  begin
    Sum := Sum - InputSignal[I - WindowSize] + InputSignal[I];
    Result[I] := Sum / WindowSize;
  end;

  for I := 0 to WindowSize - 2 do
    Result[I] := Result[WindowSize - 1];
end;

{ ---------------------------------------------------------------------------
  TSignalKit — Windowing
  --------------------------------------------------------------------------- }

class function TSignalKit.GenerateWindow(WindowType: TWindowType; Size: Integer): TDoubleArray;
var
  I: Integer;
  N_1: Double;
const
  Blackman_a0 = 0.42;
  Blackman_a1 = 0.5;
  Blackman_a2 = 0.08;
begin
  Result := nil;
  if Size <= 0 then
    raise ESignalError.Create('Window size must be positive.');
  SetLength(Result, Size);
  N_1 := Size - 1;
  if N_1 = 0 then begin Result[0] := 1.0; Exit; end;

  case WindowType of
    wtRectangular:
      for I := 0 to Size - 1 do Result[I] := 1.0;
    wtHamming:
      for I := 0 to Size - 1 do
        Result[I] := 0.54 - 0.46 * Cos(2 * Pi * I / N_1);
    wtHann:
      for I := 0 to Size - 1 do
        Result[I] := 0.5 * (1 - Cos(2 * Pi * I / N_1));
    wtBlackman:
      for I := 0 to Size - 1 do
        Result[I] := Blackman_a0
                   - Blackman_a1 * Cos(2 * Pi * I / N_1)
                   + Blackman_a2 * Cos(4 * Pi * I / N_1);
  else
    raise ESignalError.Create('Unknown window type specified.');
  end;
end;

class function TSignalKit.ApplyWindow(const InputSignal, Window: TDoubleArray): TDoubleArray;
var
  N, M, I: Integer;
begin
  N := Length(InputSignal);
  M := Length(Window);
  if N <> M then
    raise ESignalError.Create('Input signal and window must have the same length.');
  if N = 0 then Exit(nil);
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := InputSignal[I] * Window[I];
end;

{ ---------------------------------------------------------------------------
  TSignalKit — FFT  (Cooley-Tukey radix-2 DIT)
  --------------------------------------------------------------------------- }

class procedure TSignalKit.FFT(var RealPart, ImagPart: TDoubleArray; Inverse: Boolean);
var
  N, Len, I, J, K: Integer;
  Angle, WR, WI, Ur, Ui, TR, TI: Double;
  Sign: Double;
begin
  N := Length(RealPart);
  if N <> Length(ImagPart) then
    raise ESignalError.Create('FFT: RealPart and ImagPart must have the same length.');
  if N <= 1 then Exit;
  if (N and (N - 1)) <> 0 then
    raise ESignalError.Create('FFT: length must be a power of 2.');

  BitReverse(RealPart, ImagPart);

  Sign := IfThen(Inverse, 1.0, -1.0);

  Len := 1;
  while Len < N do
  begin
    Len := Len shl 1;
    Angle := Sign * 2 * Pi / Len;
    WR := Cos(Angle);
    WI := Sin(Angle);
    I := 0;
    while I < N do
    begin
      Ur := 1.0; Ui := 0.0;
      for J := 0 to (Len shr 1) - 1 do
      begin
        K  := I + J + (Len shr 1);
        TR := Ur * RealPart[K] - Ui * ImagPart[K];
        TI := Ur * ImagPart[K] + Ui * RealPart[K];
        RealPart[K] := RealPart[I + J] - TR;
        ImagPart[K] := ImagPart[I + J] - TI;
        RealPart[I + J] := RealPart[I + J] + TR;
        ImagPart[I + J] := ImagPart[I + J] + TI;
        TR := Ur * WR - Ui * WI;
        Ui := Ur * WI + Ui * WR;
        Ur := TR;
      end;
      I := I + Len;
    end;
  end;

  if Inverse then
    for I := 0 to N - 1 do
    begin
      RealPart[I] := RealPart[I] / N;
      ImagPart[I] := ImagPart[I] / N;
    end;
end;

class procedure TSignalKit.CalculateFFT(const InputSignal: TDoubleArray; out OutRealPart, OutImagPart: TDoubleArray);
var
  N, I: Integer;
begin
  N := NextPow2(Length(InputSignal));
  SetLength(OutRealPart, N);
  SetLength(OutImagPart, N);
  for I := 0 to Length(InputSignal) - 1 do
    OutRealPart[I] := InputSignal[I];
  for I := Length(InputSignal) to N - 1 do
    OutRealPart[I] := 0;
  for I := 0 to N - 1 do
    OutImagPart[I] := 0;
  FFT(OutRealPart, OutImagPart, False);
end;

class procedure TSignalKit.CalculateIFFT(const InRealPart, InImagPart: TDoubleArray; out OutputSignal: TDoubleArray);
var
  Re, Im: TDoubleArray;
  N, I: Integer;
begin
  N := Length(InRealPart);
  SetLength(Re, N);
  SetLength(Im, N);
  for I := 0 to N - 1 do begin Re[I] := InRealPart[I]; Im[I] := InImagPart[I]; end;
  FFT(Re, Im, True);
  SetLength(OutputSignal, N);
  for I := 0 to N - 1 do
    OutputSignal[I] := Re[I];
end;

class procedure TSignalKit.CalculateFFTMagnitudePhase(
  const InputSignal: TDoubleArray;
  out Magnitude, Phase: TDoubleArray);
var
  Re, Im: TDoubleArray;
  N, I: Integer;
begin
  CalculateFFT(InputSignal, Re, Im);
  N := Length(Re);
  SetLength(Magnitude, N);
  SetLength(Phase, N);
  for I := 0 to N - 1 do
  begin
    Magnitude[I] := Sqrt(Re[I]*Re[I] + Im[I]*Im[I]);
    Phase[I]     := ArcTan2(Im[I], Re[I]);
  end;
end;

{ ---------------------------------------------------------------------------
  TSignalKit — FIR Filter Design (windowed-sinc)
  --------------------------------------------------------------------------- }

{ Ideal low-pass sinc kernel, centred at tap M/2, normalised cutoff fc }
function SincKernel(Order: Integer; CutoffFreq: Double; WinType: TWindowType): TDoubleArray;
var
  M, I: Integer;
  Fc2Pi, N0, Sinc: Double;
  Win: TDoubleArray;
begin
  Result := nil;
  M     := Order;
  Fc2Pi := 2 * Pi * CutoffFreq;
  SetLength(Result, M + 1);
  Win := TSignalKit.GenerateWindow(WinType, M + 1);
  for I := 0 to M do
  begin
    N0 := I - M / 2;
    if N0 = 0 then
      Sinc := Fc2Pi / Pi      { limit: sin(x)/x → 1, so 2*fc }
    else
      Sinc := Sin(Fc2Pi * N0) / (Pi * N0);
    Result[I] := Sinc * Win[I];
  end;
end;

{ Normalise coefficients so DC gain = 1 }
procedure NormaliseCoeffs(var C: TDoubleArray);
var
  Sum: Double;
  I: Integer;
begin
  Sum := 0;
  for I := 0 to High(C) do Sum := Sum + C[I];
  if Abs(Sum) > 1E-300 then
    for I := 0 to High(C) do C[I] := C[I] / Sum;
end;

class function TSignalKit.DesignFIRLowPass(CutoffFreq: Double; Order: Integer; WindowType: TWindowType): TDoubleArray;
begin
  if (CutoffFreq <= 0) or (CutoffFreq >= 0.5) then
    raise ESignalError.Create('DesignFIRLowPass: CutoffFreq must be in (0, 0.5).');
  if Order < 2 then Order := 2;
  if Odd(Order) then Inc(Order);
  Result := SincKernel(Order, CutoffFreq, WindowType);
  NormaliseCoeffs(Result);
end;

class function TSignalKit.DesignFIRHighPass(CutoffFreq: Double; Order: Integer; WindowType: TWindowType): TDoubleArray;
var
  LP: TDoubleArray;
  I: Integer;
begin
  Result := nil;
  { High-pass = spectral inversion of low-pass }
  LP := DesignFIRLowPass(CutoffFreq, Order, WindowType);
  SetLength(Result, Length(LP));
  for I := 0 to High(LP) do
    Result[I] := -LP[I];
  Result[Order div 2] := Result[Order div 2] + 1.0;
end;

class function TSignalKit.DesignFIRBandPass(
  LowCutoff, HighCutoff: Double;
  Order: Integer;
  WindowType: TWindowType): TDoubleArray;
var
  LP_Lo, LP_Hi: TDoubleArray;
  I: Integer;
begin
  Result := nil;
  { Band-pass = low-pass(fc_hi) − low-pass(fc_lo) }
  if LowCutoff >= HighCutoff then
    raise ESignalError.Create('DesignFIRBandPass: LowCutoff must be < HighCutoff.');
  LP_Lo := DesignFIRLowPass(LowCutoff,  Order, WindowType);
  LP_Hi := DesignFIRLowPass(HighCutoff, Order, WindowType);
  SetLength(Result, Length(LP_Lo));
  for I := 0 to High(Result) do
    Result[I] := LP_Hi[I] - LP_Lo[I];
end;

class function TSignalKit.DesignFIRBandStop(
  LowCutoff, HighCutoff: Double;
  Order: Integer;
  WindowType: TWindowType): TDoubleArray;
var
  BP: TDoubleArray;
  I: Integer;
begin
  Result := nil;
  { Band-stop = 1 − band-pass (spectral inversion) }
  BP := DesignFIRBandPass(LowCutoff, HighCutoff, Order, WindowType);
  SetLength(Result, Length(BP));
  for I := 0 to High(BP) do
    Result[I] := -BP[I];
  Result[Order div 2] := Result[Order div 2] + 1.0;
end;

class function TSignalKit.ApplyFIRFilter(const Signal, Coeffs: TDoubleArray): TDoubleArray;
var
  NS, NC, OutLen, I, J, K: Integer;
begin
  NS     := Length(Signal);
  NC     := Length(Coeffs);
  if (NS = 0) or (NC = 0) then Exit(nil);
  OutLen := NS + NC - 1;
  SetLength(Result, OutLen);
  for I := 0 to OutLen - 1 do
  begin
    Result[I] := 0;
    for J := 0 to NC - 1 do
    begin
      K := I - J;
      if (K >= 0) and (K < NS) then
        Result[I] := Result[I] + Coeffs[J] * Signal[K];
    end;
  end;
end;

{ ---------------------------------------------------------------------------
  TSignalKit — Signal Properties
  --------------------------------------------------------------------------- }

class function TSignalKit.SignalPower(const InputSignal: TDoubleArray): Double;
var
  SumSq: Double;
  I, N: Integer;
begin
  N := Length(InputSignal);
  if N = 0 then Exit(0.0);
  SumSq := 0.0;
  for I := 0 to N - 1 do SumSq := SumSq + Sqr(InputSignal[I]);
  Result := SumSq / N;
end;

class function TSignalKit.SignalEnergy(const InputSignal: TDoubleArray): Double;
var
  SumSq: Double;
  I, N: Integer;
begin
  N := Length(InputSignal);
  if N = 0 then Exit(0.0);
  SumSq := 0.0;
  for I := 0 to N - 1 do SumSq := SumSq + Sqr(InputSignal[I]);
  Result := SumSq;
end;

class function TSignalKit.RootMeanSquare(const InputSignal: TDoubleArray): Double;
begin
  Result := Sqrt(SignalPower(InputSignal));
end;

end.
