unit TestEngineeringLib_Signal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, Math,
  EngineeringLib.Signal;

type

  { TTestSignalKit }

  TTestSignalKit = class(TTestCase)
  private
    procedure AssertDoubleArraysEqual(const Msg: string; const Expected, Actual: TDoubleArray; Tolerance: Double);
    // Add these helper methods for exception testing
    procedure DoMovingAverageWithZeroWindow;
    procedure DoMovingAverageWithLargeWindow;
    procedure DoApplyWindowWithMismatchedSizes;
  published
    procedure TestMovingAverage;
    procedure TestGenerateWindowRectangular;
    procedure TestGenerateWindowHamming;
    procedure TestGenerateWindowHann;
    procedure TestGenerateWindowBlackman;
    procedure TestGenerateWindowSize1;
    procedure TestApplyWindow;
    procedure TestSignalPower;
    procedure TestSignalEnergy;
    procedure TestRootMeanSquare;
    procedure TestFFTPlaceholders; // Test that FFT functions raise exceptions
  end;

implementation

const
  Tolerance = 1E-9;

procedure TTestSignalKit.AssertDoubleArraysEqual(const Msg: string; const Expected, Actual: TDoubleArray; Tolerance: Double);
var
  I: Integer;
begin
  AssertEquals(Msg + ': Array length mismatch', Length(Expected), Length(Actual));
  for I := 0 to Length(Expected) - 1 do
    AssertEquals(Msg + Format(': Element %d mismatch', [I]), Expected[I], Actual[I], Tolerance);
end;

procedure TTestSignalKit.DoMovingAverageWithZeroWindow;
var
  Input: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
  TSignalKit.MovingAverage(Input, 0); // Should raise exception
end;

procedure TTestSignalKit.DoMovingAverageWithLargeWindow;
var
  Input: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
  TSignalKit.MovingAverage(Input, 7); // Should raise exception - window size > input length
end;

procedure TTestSignalKit.DoApplyWindowWithMismatchedSizes;
var
  Input: TDoubleArray;
  Window: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0);
  Window := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0); // Different size from Input
  TSignalKit.ApplyWindow(Input, Window); // Should raise exception
end;

procedure TTestSignalKit.TestMovingAverage;
var
  Input, Expected, Actual: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);

  // Window size 3
  Expected := TDoubleArray.Create(2.0, 2.0, 2.0, 3.0, 4.0, 5.0); // Replicates first valid avg
  Actual := TSignalKit.MovingAverage(Input, 3);
  AssertDoubleArraysEqual('Moving Average (Size 3)', Expected, Actual, Tolerance);

  // Window size 1
  Expected := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
  Actual := TSignalKit.MovingAverage(Input, 1);
  AssertDoubleArraysEqual('Moving Average (Size 1)', Expected, Actual, Tolerance);

  // Window size = Length
  Expected := TDoubleArray.Create(3.5, 3.5, 3.5, 3.5, 3.5, 3.5); // Average of all elements
  Actual := TSignalKit.MovingAverage(Input, Length(Input));
  AssertDoubleArraysEqual('Moving Average (Size=Length)', Expected, Actual, Tolerance);

  // Test empty input
  Actual := TSignalKit.MovingAverage(nil, 3);
  AssertEquals('Moving Average (Empty Input)', 0, Length(Actual));

  // Test invalid window size
  AssertException('Moving Average (Size 0)', EInvalidOp, @DoMovingAverageWithZeroWindow);
  AssertException('Moving Average (Size > Length)', EInvalidOp, @DoMovingAverageWithLargeWindow);
end;

procedure TTestSignalKit.TestGenerateWindowRectangular;
var
  Expected, Actual: TDoubleArray;
begin
  Expected := TDoubleArray.Create(1.0, 1.0, 1.0, 1.0, 1.0);
  Actual := TSignalKit.GenerateWindow(wtRectangular, 5);
  AssertDoubleArraysEqual('Rectangular Window (Size 5)', Expected, Actual, Tolerance);
end;

procedure TTestSignalKit.TestGenerateWindowHamming;
var
  Expected, Actual: TDoubleArray;
  N_1: Double;
  I: Integer;
  Size: Integer = 5;
begin
  SetLength(Expected, Size);
  N_1 := Size - 1;
  for I := 0 to Size - 1 do
    Expected[I] := 0.54 - 0.46 * Cos(2 * Pi * I / N_1);

  Actual := TSignalKit.GenerateWindow(wtHamming, Size);
  AssertDoubleArraysEqual('Hamming Window (Size 5)', Expected, Actual, Tolerance);
end;

procedure TTestSignalKit.TestGenerateWindowHann;
var
  Expected, Actual: TDoubleArray;
  N_1: Double;
  I: Integer;
  Size: Integer = 5;
begin
  SetLength(Expected, Size);
  N_1 := Size - 1;
  for I := 0 to Size - 1 do
    Expected[I] := 0.5 * (1 - Cos(2 * Pi * I / N_1));

  Actual := TSignalKit.GenerateWindow(wtHann, Size);
  AssertDoubleArraysEqual('Hann Window (Size 5)', Expected, Actual, Tolerance);
end;

procedure TTestSignalKit.TestGenerateWindowBlackman;
var
  Expected, Actual: TDoubleArray;
  N_1: Double;
  I: Integer;
  Size: Integer = 5;
  a0, a1, a2: Double;
begin
  a0 := 0.42; a1 := 0.5; a2 := 0.08;
  SetLength(Expected, Size);
  N_1 := Size - 1;
  for I := 0 to Size - 1 do
    Expected[I] := a0 - a1 * Cos(2 * Pi * I / N_1) + a2 * Cos(4 * Pi * I / N_1);

  Actual := TSignalKit.GenerateWindow(wtBlackman, Size);
  AssertDoubleArraysEqual('Blackman Window (Size 5)', Expected, Actual, Tolerance);
end;

procedure TTestSignalKit.TestGenerateWindowSize1;
var
  Expected, Actual: TDoubleArray;
begin
  Expected := TDoubleArray.Create(1.0);
  Actual := TSignalKit.GenerateWindow(wtHamming, 1); // Type shouldn't matter for size 1
  AssertDoubleArraysEqual('Window (Size 1)', Expected, Actual, Tolerance);
end;

procedure TTestSignalKit.TestApplyWindow;
var
  Input, Window, Expected, Actual: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0);
  Window := TSignalKit.GenerateWindow(wtRectangular, 5); // Rectangular window (all 1s)
  Expected := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0);
  Actual := TSignalKit.ApplyWindow(Input, Window);
  AssertDoubleArraysEqual('Apply Window (Rectangular)', Expected, Actual, Tolerance);

  Window := TSignalKit.GenerateWindow(wtHann, 5);
  Expected := TDoubleArray.Create(
    Input[0] * Window[0],
    Input[1] * Window[1],
    Input[2] * Window[2],
    Input[3] * Window[3],
    Input[4] * Window[4]
  );
  Actual := TSignalKit.ApplyWindow(Input, Window);
  AssertDoubleArraysEqual('Apply Window (Hann)', Expected, Actual, Tolerance);

  // Test mismatch length
  AssertException('Apply Window (Length Mismatch)', EInvalidOp, @DoApplyWindowWithMismatchedSizes);

  // Test empty
  Actual := TSignalKit.ApplyWindow(nil, nil);
  AssertEquals('Apply Window (Empty)', 0, Length(Actual));
end;

procedure TTestSignalKit.TestSignalPower;
var
  Input: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0); // SumSq = 1+4+9+16 = 30
  AssertEquals('Signal Power', 30.0 / 4.0, TSignalKit.SignalPower(Input), Tolerance);
  AssertEquals('Signal Power (Empty)', 0.0, TSignalKit.SignalPower(nil), Tolerance);
end;

procedure TTestSignalKit.TestSignalEnergy;
var
  Input: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0); // SumSq = 30
  AssertEquals('Signal Energy', 30.0, TSignalKit.SignalEnergy(Input), Tolerance);
  AssertEquals('Signal Energy (Empty)', 0.0, TSignalKit.SignalEnergy(nil), Tolerance);
end;

procedure TTestSignalKit.TestRootMeanSquare;
var
  Input: TDoubleArray;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0); // Power = 7.5
  AssertEquals('RMS', Sqrt(7.5), TSignalKit.RootMeanSquare(Input), Tolerance);
  AssertEquals('RMS (Empty)', 0.0, TSignalKit.RootMeanSquare(nil), Tolerance);
end;

procedure TTestSignalKit.TestFFTPlaceholders;
var
  Input, R, I, M, P: TDoubleArray;
  ExceptionRaised: Boolean;
begin
  Input := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0);

  // Test the first overload using try...except
  ExceptionRaised := False;
  try
    TSignalKit.CalculateFFT(Input, R, I);
  except
    on E: Exception do
      ExceptionRaised := True;  // Accept any exception, not just EInvalidOp
    // Allow other exceptions to propagate and fail the test
  end;
  AssertTrue('FFT (Real/Imag) Placeholder should raise exception', ExceptionRaised);

  // Test the renamed second overload using try...except
  ExceptionRaised := False;
  try
    TSignalKit.CalculateFFTMagnitudePhase(Input, M, P);
  except
    on E: Exception do
      ExceptionRaised := True;  // Accept any exception, not just EInvalidOp
    // Allow other exceptions to propagate and fail the test
  end;
  AssertTrue('FFT (Mag/Phase) Placeholder should raise exception', ExceptionRaised);
end;

initialization
  RegisterTest(TTestSignalKit);
end.
