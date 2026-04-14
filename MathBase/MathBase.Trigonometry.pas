unit MathBase.Trigonometry;

{-----------------------------------------------------------------------------
 MathBase.Trigonometry

 Trigonometric and geometric calculations.

 Provides:
   - Basic trig functions: Sin, Cos, Tan
   - Inverse trig: ArcSin, ArcCos, ArcTan, ArcTan2
   - Reciprocal: Sec, Csc, Cot
   - Hyperbolic: Sinh, Cosh, Tanh and inverses
   - Angle conversions: DegToRad, RadToDeg, GradToRad, RadToGrad
   - Angle normalisation: NormalizeAngle, NormalizeAngleDeg
   - Triangle calculations: area (3 methods), perimeter, inradius, circumradius, hypotenuse
   - Circle calculations: sector area, segment area, chord length
   - 2-D vector helpers: VectorMagnitude, VectorAngle

 All trig inputs/outputs are in radians unless the method name says Deg/Grad.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math;

type
  { All methods are static class functions — no instance required. }
  TTrigKit = class
  public
    { ---- Angle conversions ---- }
    class function DegToRad(const Degrees: Double): Double; static;
    class function RadToDeg(const Radians: Double): Double; static;
    class function GradToRad(const Grads: Double): Double; static;
    class function RadToGrad(const Radians: Double): Double; static;

    { ---- Angle normalisation ---- }
    { Normalise to [0, 2π) }
    class function NormalizeAngle(const Angle: Double): Double; static;
    { Normalise to [0, 360) }
    class function NormalizeAngleDeg(const Angle: Double): Double; static;

    { ---- Basic trig ---- }
    class function Sin(const X: Double): Double; static;
    class function Cos(const X: Double): Double; static;
    class function Tan(const X: Double): Double; static;

    { ---- Inverse trig ---- }
    class function ArcSin(const X: Double): Double; static;
    class function ArcCos(const X: Double): Double; static;
    class function ArcTan(const X: Double): Double; static;
    class function ArcTan2(const Y, X: Double): Double; static;

    { ---- Hyperbolic ---- }
    class function Sinh(const X: Double): Double; static;
    class function Cosh(const X: Double): Double; static;
    class function Tanh(const X: Double): Double; static;

    { ---- Inverse hyperbolic ---- }
    class function ArcSinh(const X: Double): Double; static;
    { X must be >= 1; returns NaN otherwise }
    class function ArcCosh(const X: Double): Double; static;
    { X must be in (-1, 1); returns NaN otherwise }
    class function ArcTanh(const X: Double): Double; static;

    { ---- Reciprocal trig ---- }
    class function Sec(const X: Double): Double; static;
    class function Csc(const X: Double): Double; static;
    class function Cot(const X: Double): Double; static;

    { ---- Triangle calculations ---- }
    { Hypotenuse from two legs (Pythagoras) }
    class function Hypotenuse(const A, B: Double): Double; static;
    { Area from base and perpendicular height }
    class function TriangleArea(const Base, Height: Double): Double; static;
    { Area from two sides and included angle (SAS) — angle in radians }
    class function TriangleAreaSAS(const SideA, Angle, SideB: Double): Double; static;
    { Area from three sides (Heron's formula) }
    class function TriangleAreaSSS(const A, B, C: Double): Double; static;
    class function TrianglePerimeter(const A, B, C: Double): Double; static;
    { Radius of inscribed circle }
    class function TriangleInRadius(const A, B, C: Double): Double; static;
    { Radius of circumscribed circle }
    class function TriangleCircumRadius(const A, B, C: Double): Double; static;

    { ---- Circle calculations ---- }
    { Area of circular sector; angle in radians }
    class function CircularSectorArea(const Radius, Angle: Double): Double; static;
    { Area of circular segment; angle in radians }
    class function CircularSegmentArea(const Radius, Angle: Double): Double; static;
    { Chord length for a given central angle (radians) }
    class function ChordLength(const Radius, Angle: Double): Double; static;

    { ---- 2-D vector helpers ---- }
    { Euclidean magnitude of vector (X, Y) }
    class function VectorMagnitude(const X, Y: Double): Double; static;
    { Angle (radians, range [-π, π]) of vector from (X1,Y1) to (X2,Y2) }
    class function VectorAngle(const X1, Y1, X2, Y2: Double): Double; static;
  end;

implementation

{ ---- Angle conversions ---- }

class function TTrigKit.DegToRad(const Degrees: Double): Double;
begin
  Result := Degrees * Pi / 180;
end;

class function TTrigKit.RadToDeg(const Radians: Double): Double;
begin
  Result := Radians * 180 / Pi;
end;

class function TTrigKit.GradToRad(const Grads: Double): Double;
begin
  Result := Grads * Pi / 200;
end;

class function TTrigKit.RadToGrad(const Radians: Double): Double;
begin
  Result := Radians * 200 / Pi;
end;

{ ---- Angle normalisation ---- }

class function TTrigKit.NormalizeAngle(const Angle: Double): Double;
begin
  Result := Angle;
  while Result < 0 do
    Result := Result + 2 * Pi;
  while Result >= 2 * Pi do
    Result := Result - 2 * Pi;
end;

class function TTrigKit.NormalizeAngleDeg(const Angle: Double): Double;
begin
  Result := Angle;
  while Result < 0 do
    Result := Result + 360;
  while Result >= 360 do
    Result := Result - 360;
end;

{ ---- Basic trig ---- }

class function TTrigKit.Sin(const X: Double): Double;
begin
  Result := System.Sin(X);
end;

class function TTrigKit.Cos(const X: Double): Double;
begin
  Result := System.Cos(X);
end;

class function TTrigKit.Tan(const X: Double): Double;
begin
  Result := Math.Tan(X);
end;

{ ---- Inverse trig ---- }

class function TTrigKit.ArcSin(const X: Double): Double;
begin
  Result := Math.ArcSin(X);
end;

class function TTrigKit.ArcCos(const X: Double): Double;
begin
  Result := Math.ArcCos(X);
end;

class function TTrigKit.ArcTan(const X: Double): Double;
begin
  Result := Math.ArcTan2(X, 1.0);
end;

class function TTrigKit.ArcTan2(const Y, X: Double): Double;
begin
  Result := Math.ArcTan2(Y, X);
end;

{ ---- Hyperbolic ---- }

class function TTrigKit.Sinh(const X: Double): Double;
begin
  Result := (System.Exp(X) - System.Exp(-X)) / 2;
end;

class function TTrigKit.Cosh(const X: Double): Double;
begin
  Result := (System.Exp(X) + System.Exp(-X)) / 2;
end;

class function TTrigKit.Tanh(const X: Double): Double;
begin
  Result := Sinh(X) / Cosh(X);
end;

{ ---- Inverse hyperbolic ---- }

class function TTrigKit.ArcSinh(const X: Double): Double;
begin
  Result := System.Ln(X + System.Sqrt(System.Sqr(X) + 1));
end;

class function TTrigKit.ArcCosh(const X: Double): Double;
begin
  if X < 1 then
    Result := NaN
  else
    Result := System.Ln(X + System.Sqrt(System.Sqr(X) - 1));
end;

class function TTrigKit.ArcTanh(const X: Double): Double;
begin
  if (X <= -1) or (X >= 1) then
    Result := NaN
  else
    Result := 0.5 * System.Ln((1 + X) / (1 - X));
end;

{ ---- Reciprocal trig ---- }

class function TTrigKit.Sec(const X: Double): Double;
begin
  Result := 1 / System.Cos(X);
end;

class function TTrigKit.Csc(const X: Double): Double;
begin
  Result := 1 / System.Sin(X);
end;

class function TTrigKit.Cot(const X: Double): Double;
begin
  Result := 1 / Math.Tan(X);
end;

{ ---- Triangle calculations ---- }

class function TTrigKit.Hypotenuse(const A, B: Double): Double;
begin
  Result := System.Sqrt(System.Sqr(A) + System.Sqr(B));
end;

class function TTrigKit.TriangleArea(const Base, Height: Double): Double;
begin
  Result := Base * Height / 2;
end;

class function TTrigKit.TriangleAreaSAS(const SideA, Angle, SideB: Double): Double;
begin
  Result := SideA * SideB * System.Sin(Angle) / 2;
end;

class function TTrigKit.TriangleAreaSSS(const A, B, C: Double): Double;
var
  S: Double;
begin
  S      := (A + B + C) / 2;
  Result := System.Sqrt(S * (S - A) * (S - B) * (S - C));
end;

class function TTrigKit.TrianglePerimeter(const A, B, C: Double): Double;
begin
  Result := A + B + C;
end;

class function TTrigKit.TriangleInRadius(const A, B, C: Double): Double;
begin
  Result := 2 * TriangleAreaSSS(A, B, C) / (A + B + C);
end;

class function TTrigKit.TriangleCircumRadius(const A, B, C: Double): Double;
begin
  Result := (A * B * C) / (4 * TriangleAreaSSS(A, B, C));
end;

{ ---- Circle calculations ---- }

class function TTrigKit.CircularSectorArea(const Radius, Angle: Double): Double;
begin
  Result := 0.5 * System.Sqr(Radius) * Angle;
end;

class function TTrigKit.CircularSegmentArea(const Radius, Angle: Double): Double;
begin
  Result := 0.5 * System.Sqr(Radius) * (Angle - System.Sin(Angle));
end;

class function TTrigKit.ChordLength(const Radius, Angle: Double): Double;
begin
  Result := 2 * Radius * System.Sin(Angle / 2);
end;

{ ---- 2-D vector helpers ---- }

class function TTrigKit.VectorMagnitude(const X, Y: Double): Double;
begin
  Result := System.Sqrt(System.Sqr(X) + System.Sqr(Y));
end;

class function TTrigKit.VectorAngle(const X1, Y1, X2, Y2: Double): Double;
begin
  Result := Math.ArcTan2(Y2 - Y1, X2 - X1);
end;

end.
