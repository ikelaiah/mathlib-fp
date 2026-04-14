# 📐 pascal-mathlibs.Trigonometry: Trigonometric Functions Library

The `TTrigKit` class provides comprehensive trigonometric calculations with Double precision. This module is part of the [pascal-mathlibs.Math](pascal-mathlibs.Math.md) library.

## Table of Contents
- [Angle Conventions](#angle-conventions)
- [Angle Conversions](#angle-conversions)
- [Basic Trigonometric Functions](#basic-trigonometric-functions)
- [Inverse Trigonometric Functions](#inverse-trigonometric-functions)
- [Hyperbolic Functions](#hyperbolic-functions)
- [Triangle Calculations](#triangle-calculations)
- [Circle Sector and Segment Calculations](#circle-sector-and-segment-calculations)
- [Vector Operations](#vector-operations)
- [Common Pitfalls](#common-pitfalls)
- [Precision Notes](#precision-notes)
- [Examples](#examples)

## Angle Conventions

All angle-related functions follow these conventions:

- All trigonometric functions (Sin, Cos, Tan) expect input angles in **radians**
- All inverse trigonometric functions (ArcSin, ArcCos, ArcTan, ArcTan2) return angles in **radians**
- Vector angle calculations return results in **radians**
- Use `DegToRad` and `RadToDeg` functions for angle conversions when working with degrees

## Angle Conversions

```pascal
uses pascal-mathlibs.Math.Trigonometry;

// Convert between degrees, radians, and grads
Rad := TTrigKit.DegToRad(Degrees);           // Degrees to radians
Deg := TTrigKit.RadToDeg(Radians);           // Radians to degrees
Rad := TTrigKit.GradToRad(Grads);            // Grads to radians
Grad := TTrigKit.RadToGrad(Radians);         // Radians to grads

// Normalize angles to standard ranges
Rad := TTrigKit.NormalizeAngle(Radians);     // To [0, 2π]
Deg := TTrigKit.NormalizeAngleDeg(Degrees);  // To [0, 360]
```

## Basic Trigonometric Functions

```pascal
// Primary functions
Sin := TTrigKit.Sin(X);                      // Sine
Cos := TTrigKit.Cos(X);                      // Cosine
Tan := TTrigKit.Tan(X);                      // Tangent

// Reciprocal functions
Sec := TTrigKit.Sec(X);                      // Secant
Csc := TTrigKit.Csc(X);                      // Cosecant
Cot := TTrigKit.Cot(X);                      // Cotangent
```

## Inverse Trigonometric Functions

```pascal
// Primary inverse functions
ASin := TTrigKit.ArcSin(X);                  // Inverse sine
ACos := TTrigKit.ArcCos(X);                  // Inverse cosine
ATan := TTrigKit.ArcTan(X);                  // Inverse tangent
ATan2 := TTrigKit.ArcTan2(Y, X);             // Two-argument inverse tangent
```

## Hyperbolic Functions

```pascal
// Direct hyperbolic functions
SinH := TTrigKit.Sinh(X);                    // Hyperbolic sine
CosH := TTrigKit.Cosh(X);                    // Hyperbolic cosine
TanH := TTrigKit.Tanh(X);                    // Hyperbolic tangent

// Inverse hyperbolic functions
ASinH := TTrigKit.ArcSinh(X);                // Inverse hyperbolic sine
ACosH := TTrigKit.ArcCosh(X);                // Inverse hyperbolic cosine
ATanH := TTrigKit.ArcTanh(X);                // Inverse hyperbolic tangent
```

## Triangle Calculations

```pascal
// Area calculations
Area := TTrigKit.TriangleArea(Base, Height); // From base and height
Area := TTrigKit.TriangleAreaSAS(A, Angle, B); // From SAS
Area := TTrigKit.TriangleAreaSSS(A, B, C);   // From three sides

// Other triangle metrics
Perim := TTrigKit.TrianglePerimeter(A, B, C); // Perimeter
InRad := TTrigKit.TriangleInRadius(A, B, C);  // Inscribed circle radius
CircumRad := TTrigKit.TriangleCircumRadius(A, B, C); // Circumscribed circle radius

// Basic triangle calculations
H := TTrigKit.Hypotenuse(A, B);              // Calculate hypotenuse
```

## Circle Sector and Segment Calculations

```pascal
// Circular measurements
SectorArea := TTrigKit.CircularSectorArea(R, Angle); // Sector area
SegmentArea := TTrigKit.CircularSegmentArea(R, Angle); // Segment area
ChordLen := TTrigKit.ChordLength(R, Angle);  // Chord length
```

## Vector Operations

```pascal
// Vector calculations
Mag := TTrigKit.VectorMagnitude(X, Y);       // Vector magnitude
Angle := TTrigKit.VectorAngle(X1, Y1, X2, Y2); // Angle between vectors
```

## Common Pitfalls

1. **Wrong Angle Units**: Always ensure angles are in the correct units:
   ```pascal
   // INCORRECT - using degrees directly
   S := TTrigKit.Sin(45);  // Wrong! 45 degrees
   
   // CORRECT - convert to radians first
   S := TTrigKit.Sin(TTrigKit.DegToRad(45));  // Correct!
   ```

2. **Not Converting Inverse Function Results**: Remember that inverse functions return radians:
   ```pascal
   // INCORRECT - assuming result is in degrees
   angle_deg := TTrigKit.ArcSin(0.5);  // Wrong! Result is in radians
   
   // CORRECT - convert to degrees if needed
   angle_deg := TTrigKit.RadToDeg(TTrigKit.ArcSin(0.5));  // Correct!
   ```

3. **Triangle Area with Angle**: The `TriangleAreaSAS` function expects the angle in radians:
   ```pascal
   // INCORRECT - using degrees
   Area := TTrigKit.TriangleAreaSAS(4, 60, 5);  // Wrong! 60 degrees
   
   // CORRECT - convert to radians
   Area := TTrigKit.TriangleAreaSAS(4, TTrigKit.DegToRad(60), 5);  // Correct!
   ```

## Precision Notes

- All trigonometric functions maintain Double precision (15-17 significant digits)
- Angle conversions are accurate to Double precision
- Triangle calculations preserve precision for accurate geometric results
- Special cases (undefined values, domain errors) are handled with exceptions
- Vector operations maintain precision for both magnitude and angles

## Examples

### Basic Trigonometry

```pascal
var
  AngleRad, AngleDeg, SinValue, CosValue: Double;
begin
  // Convert 45 degrees to radians
  AngleDeg := 45;
  AngleRad := TTrigKit.DegToRad(AngleDeg);
  
  // Calculate trigonometric functions
  SinValue := TTrigKit.Sin(AngleRad);
  CosValue := TTrigKit.Cos(AngleRad);
  
  WriteLn('Angle: ', AngleDeg:0:1, ' degrees = ', AngleRad:0:4, ' radians');
  WriteLn('Sin(', AngleDeg:0:1, '°) = ', SinValue:0:4);
  WriteLn('Cos(', AngleDeg:0:1, '°) = ', CosValue:0:4);
end;
```

### Triangle Calculations

```pascal
var
  Side1, Side2, Side3, Area, Perimeter: Double;
  InRadius, CircumRadius: Double;
begin
  // Triangle with sides 3, 4, 5
  Side1 := 3;
  Side2 := 4;
  Side3 := 5;
  
  // Calculate area using Heron's formula
  Area := TTrigKit.TriangleAreaSSS(Side1, Side2, Side3);
  
  // Calculate perimeter
  Perimeter := TTrigKit.TrianglePerimeter(Side1, Side2, Side3);
  
  // Calculate radii
  InRadius := TTrigKit.TriangleInRadius(Side1, Side2, Side3);
  CircumRadius := TTrigKit.TriangleCircumRadius(Side1, Side2, Side3);
  
  WriteLn('Triangle with sides ', Side1:0:1, ', ', Side2:0:1, ', ', Side3:0:1);
  WriteLn('Area: ', Area:0:2);
  WriteLn('Perimeter: ', Perimeter:0:2);
  WriteLn('Inscribed circle radius: ', InRadius:0:4);
  WriteLn('Circumscribed circle radius: ', CircumRadius:0:4);
end;
```

### Vector Angle Calculation

```pascal
var
  X1, Y1, X2, Y2: Double;
  Angle, AngleDeg: Double;
begin
  // Calculate angle between two vectors
  X1 := 1; Y1 := 0;  // Vector 1 (1,0)
  X2 := 0; Y2 := 1;  // Vector 2 (0,1)
  
  // Calculate angle in radians
  Angle := TTrigKit.VectorAngle(X1, Y1, X2, Y2);
  
  // Convert to degrees
  AngleDeg := TTrigKit.RadToDeg(Angle);
  
  WriteLn('Vector 1: (', X1:0:1, ',', Y1:0:1, ')');
  WriteLn('Vector 2: (', X2:0:1, ',', Y2:0:1, ')');
  WriteLn('Angle between vectors: ', Angle:0:4, ' radians = ', AngleDeg:0:1, ' degrees');
end;
``` 