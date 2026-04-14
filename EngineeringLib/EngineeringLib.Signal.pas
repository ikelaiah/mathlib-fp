unit EngineeringLib.Signal;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, Generics.Collections;

type
  TDoubleArray = array of Double;

  TWindowType = (wtRectangular, wtHamming, wtHann, wtBlackman);

  TSignalKit = class
  public
    { Basic Filtering }
    // Simple Moving Average (SMA) filter
    class function MovingAverage(const InputSignal: TDoubleArray; WindowSize: Integer): TDoubleArray; static;

    { Windowing Functions }
    // Generate a window of a specified type and size
    class function GenerateWindow(WindowType: TWindowType; Size: Integer): TDoubleArray; static;
    // Apply a window function to a signal
    class function ApplyWindow(const InputSignal: TDoubleArray; const Window: TDoubleArray): TDoubleArray; static;

    { Spectral Analysis (Placeholders - Requires FFT implementation) }
    // Note: A full FFT implementation is complex and might require dedicated libraries.
    // These are placeholders for future expansion.
    class procedure CalculateFFT(const InputSignal: TDoubleArray; out RealPart, ImaginaryPart: TDoubleArray); overload; static;
    class procedure CalculateFFTMagnitudePhase(const InputSignal: TDoubleArray; out Magnitude, Phase: TDoubleArray); static;

    { Signal Properties }
    class function SignalPower(const InputSignal: TDoubleArray): Double; static;
    class function SignalEnergy(const InputSignal: TDoubleArray): Double; static;
    class function RootMeanSquare(const InputSignal: TDoubleArray): Double; static;
  end;

implementation

{ TSignalKit }

class function TSignalKit.MovingAverage(const InputSignal: TDoubleArray; WindowSize: Integer): TDoubleArray;
var
  N, I, J, StartIndex, EndIndex: Integer;
  Sum: Double;
begin
  N := Length(InputSignal);
  
  // Add check for nil input signal
  if InputSignal = nil then
  begin
    Exit(nil); // Return nil for nil input
  end;
  
  if (WindowSize <= 0) or (WindowSize > N) then
    raise EInvalidOp.Create('Invalid window size for moving average.');

  SetLength(Result, N);

  Sum := 0.0;
  // Calculate initial sum for the first window
  for I := 0 to WindowSize - 1 do
    Sum := Sum + InputSignal[I];

  // Calculate the first output point (average of the first window)
  Result[WindowSize - 1] := Sum / WindowSize;

  // Use sliding window approach for efficiency
  for I := WindowSize to N - 1 do
  begin
    Sum := Sum - InputSignal[I - WindowSize] + InputSignal[I];
    Result[I] := Sum / WindowSize;
  end;

  // Handle the beginning part (less than full window size) - optional, depends on desired behavior
  // Here, we fill the beginning with NaN or replicate the first valid value
  // For simplicity, let's replicate the first valid average
  for I := 0 to WindowSize - 2 do
    Result[I] := Result[WindowSize - 1]; // Or use NaN if preferred: Result[I] := NaN;
end;

class function TSignalKit.GenerateWindow(WindowType: TWindowType; Size: Integer): TDoubleArray;
var
  I: Integer;
  N_1: Double; // Size - 1
// Moved constants here
const
  Blackman_a0 = 0.42;
  Blackman_a1 = 0.5;
  Blackman_a2 = 0.08;
begin
  if Size <= 0 then
    raise Exception.Create('Window size must be positive.');

  SetLength(Result, Size);
  N_1 := Size - 1;
  if N_1 = 0 then // Handle size 1 case
  begin
     Result[0] := 1.0;
     Exit;
  end;

  case WindowType of
    wtRectangular:
      begin
        for I := 0 to Size - 1 do
          Result[I] := 1.0;
      end;
    wtHamming:
      begin
        // a0 = 0.54, a1 = 0.46
        for I := 0 to Size - 1 do
          Result[I] := 0.54 - 0.46 * Cos(2 * Pi * I / N_1);
      end;
    wtHann: // Also known as Hanning
      begin
        for I := 0 to Size - 1 do
          Result[I] := 0.5 * (1 - Cos(2 * Pi * I / N_1));
      end;
    wtBlackman:
      begin
        // Use the constants declared above
        for I := 0 to Size - 1 do
          Result[I] := Blackman_a0 - Blackman_a1 * Cos(2 * Pi * I / N_1) + Blackman_a2 * Cos(4 * Pi * I / N_1);
      end;
  else
    raise Exception.Create('Unknown window type specified.');
  end;
end;

class function TSignalKit.ApplyWindow(const InputSignal: TDoubleArray; const Window: TDoubleArray): TDoubleArray;
var
  N, M, I: Integer;
begin
  N := Length(InputSignal);
  M := Length(Window);

  if N <> M then
    raise EInvalidOp.Create('Input signal and window must have the same length.');
  if N = 0 then
    Exit(nil); // Return empty array if input is empty

  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := InputSignal[I] * Window[I];
end;

class procedure TSignalKit.CalculateFFT(const InputSignal: TDoubleArray; out RealPart, ImaginaryPart: TDoubleArray);
begin
  // Placeholder: Requires a dedicated FFT algorithm implementation.
  // This could involve complex numbers and recursive algorithms (like Cooley-Tukey).
  // For now, raise an exception indicating it's not implemented.
  raise Exception.Create('FFT calculation is not yet implemented in TidyKit.Signal.');
  // Example initialization (if implemented):
  // SetLength(RealPart, Length(InputSignal));
  // SetLength(ImaginaryPart, Length(InputSignal));
  // ... perform FFT calculation ...
end;

class procedure TSignalKit.CalculateFFTMagnitudePhase(const InputSignal: TDoubleArray; out Magnitude, Phase: TDoubleArray);
var
  RealPart, ImaginaryPart: TDoubleArray;
  I, N: Integer;
begin
  // Placeholder: Requires FFT implementation first.
  CalculateFFT(InputSignal, RealPart, ImaginaryPart); // Call the primary FFT calculation

  N := Length(InputSignal);
  SetLength(Magnitude, N);
  SetLength(Phase, N);

  for I := 0 to N - 1 do
  begin
    Magnitude[I] := Sqrt(Sqr(RealPart[I]) + Sqr(ImaginaryPart[I]));
    Phase[I] := ArcTan2(ImaginaryPart[I], RealPart[I]); // Radians
  end;
end;

class function TSignalKit.SignalPower(const InputSignal: TDoubleArray): Double;
var
  SumSq: Double;
  I, N: Integer;
begin
  N := Length(InputSignal);
  if N = 0 then Exit(0.0);

  SumSq := 0.0;
  for I := 0 to N - 1 do
    SumSq := SumSq + Sqr(InputSignal[I]);

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
  for I := 0 to N - 1 do
    SumSq := SumSq + Sqr(InputSignal[I]);

  Result := SumSq; // Assuming unit time step or resistance
end;

class function TSignalKit.RootMeanSquare(const InputSignal: TDoubleArray): Double;
begin
  Result := Sqrt(SignalPower(InputSignal));
end;

end.
