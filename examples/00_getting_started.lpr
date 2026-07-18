program GettingStarted;

{-----------------------------------------------------------------------------
  00_getting_started.lpr

  A first mathlib-fp program for readers who are new to both the library and
  Free Pascal. It introduces the four small units in the MathBase foundation
  domain: shared array types, constants, precision helpers, and trigonometry.

  From this directory, compile with:

    mkdir lib
    fpc -Fu../src -FUlib 00_getting_started.lpr

  Then run:

    ./00_getting_started        (Linux/macOS)
    00_getting_started.exe      (Windows)

  -Fu tells FPC where to find mathlib-fp's source units.
  -FU keeps generated compiler files in lib/ instead of this directory.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,                    // Format
  MathBase.SharedTypes,        // reusable numeric array and interval types
  MathBase.MathConstants,      // mathematical and physical constants
  MathBase.Precision,          // low-level special functions
  MathBase.Trigonometry;       // TTrigKit

procedure ShowArray(const ALabel: String; const AValues: TDoubleArray);
var
  I: Integer;
begin
  Write(ALabel, ': [');
  for I := 0 to High(AValues) do
  begin
    if I > 0 then
      Write(', ');
    Write(AValues[I]:0:2);
  end;
  WriteLn(']');
end;

procedure DemoSharedTypes;
var
  Counts: TIntegerArray;
  Measurements: TDoubleArray;
  ExpectedRange: TDoublePair;
begin
  WriteLn('=== 1. Shared numeric types ===');

  { Dynamic arrays can be created directly from values. Their first index is
    zero, so this array has valid indexes 0 through 3. }
  Counts := TIntegerArray.Create(2, 4, 8, 16);

  { ToDoubleArray makes a new array. Changing Measurements later would not
    change Counts. This conversion is useful because most numerical APIs take
    TDoubleArray. }
  Measurements := ToDoubleArray(Counts);
  ShowArray('Counts converted to doubles', Measurements);

  { TDoublePair is a small record commonly used for an interval or range. }
  ExpectedRange.Lower := 1.5;
  ExpectedRange.Upper := 2.5;
  WriteLn(Format('Expected range: [%.1f, %.1f]',
    [ExpectedRange.Lower, ExpectedRange.Upper]));
  WriteLn;
end;

procedure DemoConstants;
begin
  WriteLn('=== 2. Named constants ===');

  { Named constants document both the value and its unit. For example,
    StandardGravity is expressed in metres per second squared. }
  WriteLn(Format('Pi                    = %.12f', [MathPi]));
  WriteLn(Format('Golden ratio          = %.12f', [MathPhi]));
  WriteLn(Format('Standard gravity      = %.5f m/s^2', [StandardGravity]));
  WriteLn(Format('Standard atmosphere   = %.0f Pa', [StandardAtmosphere]));
  WriteLn;
end;

procedure DemoTrigonometry;
var
  AngleDegrees, AngleRadians: Double;
begin
  WriteLn('=== 3. Trigonometry and geometry helpers ===');

  { Trigonometric functions use radians. Convert human-friendly degree input
    explicitly so that the unit of every value remains clear. }
  AngleDegrees := 30.0;
  AngleRadians := TTrigKit.DegToRad(AngleDegrees);
  WriteLn(Format('sin(30 degrees)       = %.6f',
    [TTrigKit.Sin(AngleRadians)]));

  { Normalisation turns any degree angle into the interval [0, 360). }
  WriteLn(Format('normalise -450 deg    = %.1f degrees',
    [TTrigKit.NormalizeAngleDeg(-450.0)]));

  { The Kit classes expose class functions: call TTrigKit.Hypotenuse directly;
    there is no TTrigKit object to construct or free. }
  WriteLn(Format('3-4 triangle hypotenuse = %.1f',
    [TTrigKit.Hypotenuse(3.0, 4.0)]));
  WriteLn(Format('3-4-5 triangle area     = %.1f',
    [TTrigKit.TriangleAreaSSS(3.0, 4.0, 5.0)]));
  WriteLn;
end;

procedure DemoPrecision;
begin
  WriteLn('=== 4. Precision helpers ===');

  { NormalCDF here is the standard-normal CDF: it accepts one z-score.
    ProbabilityLib.Distributions provides the higher-level distribution API
    when you need a configurable mean and standard deviation. }
  WriteLn(Format('P(Z <= 1.96)          = %.6f', [NormalCDF(1.96)]));
  WriteLn(Format('erf(1)                = %.6f', [Erf(1.0)]));
  WriteLn(Format('ln(Gamma(5))          = %.6f', [GammaLn(5.0)]));

  { MathBase.Precision is intentionally low-level. Validate domain inputs in
    application code (GammaLn needs X > 0, for example), or use a higher-level
    domain Kit whose documentation defines its validation contract. }
  WriteLn;
end;

begin
  WriteLn('mathlib-fp - Getting Started with MathBase');
  WriteLn('==========================================');
  WriteLn;

  DemoSharedTypes;
  DemoConstants;
  DemoTrigonometry;
  DemoPrecision;

  WriteLn('Done. Try changing the input values and compiling again.');
end.
