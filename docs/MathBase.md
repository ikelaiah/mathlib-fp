# MathBase

Foundation domain for mathlib-fp. All other domains depend on its units.

## Units

| Unit | File |
|------|------|
| `MathBase.SharedTypes` | [MathBase.SharedTypes.pas](../src/MathBase.SharedTypes.pas) |
| `MathBase.MathConstants` | [MathBase.MathConstants.pas](../src/MathBase.MathConstants.pas) |
| `MathBase.Precision` | [MathBase.Precision.pas](../src/MathBase.Precision.pas) |
| `MathBase.Trigonometry` | [MathBase.Trigonometry.pas](../src/MathBase.Trigonometry.pas) |

---

## MathBase.SharedTypes

Common numeric array types and a helper record shared by all domains.

### Types

| Type | Definition | Description |
|------|-----------|-------------|
| `TIntegerArray` | `array of Integer` | Dynamic integer array |
| `TDoubleArray` | `array of Double` | Dynamic double array |
| `TSingleArray` | `array of Single` | Dynamic single array |
| `TExtendedArray` | `array of Extended` | Dynamic extended array |
| `TDoublePair` | record `Lower`, `Upper: Double` | Numeric interval / range |

### Conversion Functions

```pascal
function ToDoubleArray(const Data: TIntegerArray):  TDoubleArray; overload;
function ToDoubleArray(const Data: TSingleArray):   TDoubleArray; overload;
function ToDoubleArray(const Data: TExtendedArray): TDoubleArray; overload;
```

Each overload copies every element into a new `TDoubleArray`, widening the numeric type as needed.

---

## MathBase.MathConstants

Compile-time constants for commonly needed mathematical and physical values.

### Mathematical Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MathPi` | 3.14159265358979… | π |
| `MathE` | 2.71828182845904… | Euler's number *e* |
| `MathPhi` | 1.61803398874989… | Golden ratio φ |
| `MathSqrt2` | 1.41421356237309… | √2 |
| `MathLn2` | 0.69314718055994… | ln(2) |
| `MathLn10` | 2.30258509299404… | ln(10) |

### Physical Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `BoltzmannConst` | 1.380649 × 10⁻²³ | Boltzmann constant (J/K) |
| `StefanBoltzmannConst` | 5.670374419 × 10⁻⁸ | Stefan-Boltzmann constant (W/m²/K⁴) |
| `IdealGasConst` | 8.314462618 | Universal gas constant (J/mol/K) |
| `AvogadroConst` | 6.02214076 × 10²³ | Avogadro constant (1/mol) |
| `StandardGravity` | 9.80665 | Standard gravity (m/s²) |
| `StandardAtmosphere` | 101325.0 | Standard atmosphere (Pa) |
| `StandardTemperature` | 273.15 | Standard temperature, 0 °C (K) |

---

## MathBase.Precision

Low-level special functions used as building blocks by higher-level domains.

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `GammaLn` | `(X: Double): Double` | ln(Γ(x)) via a double-precision Lanczos approximation for X > 0 |
| `Beta` | `(Z, W: Double): Double` | Beta function B(z,w), with a cancellation-resistant large-parameter log form |
| `BetaInc` | `(A, B, X: Double): Double` | Regularised incomplete beta I_x(a,b), using a convergence-checked continued fraction |
| `Erf` | `(X: Double): Double` | Error function, evaluated through regularised incomplete-gamma ratios |
| `NormalCDF` | `(X: Double): Double` | Standard normal Φ(x), with the negative tail evaluated directly |
| `StudentT` | `(DF: Integer; X: Double): Double` | Student's t CDF helper for X ≥ 0 and DF ≥ 1 |

`GammaLn` and `Beta` require positive shape arguments. `BetaInc` requires
finite positive A and B and clamps X outside [0,1] to the corresponding
endpoint. Invalid shape arguments and failure to converge return NaN rather
than an unchecked partial iterate. Representable `Beta` underflow and overflow
return 0 and +Infinity respectively.

`StudentT` intentionally covers only the non-negative half of the distribution
and returns NaN for negative X. Use `TProbabilityKit.StudentTCDF` for a complete
signed CDF. Its formula uses I(df/(df+x²); df/2, 1/2); the `df/2` shape is
important for correct t-test p-values.

---

## MathBase.Trigonometry — `TTrigKit`

All methods are **static class functions** — no instance required.

### Angle Conversions

```pascal
class function DegToRad(const Degrees: Double): Double;
class function RadToDeg(const Radians: Double): Double;
class function GradToRad(const Grads: Double): Double;
class function RadToGrad(const Radians: Double): Double;
```

### Angle Normalisation

```pascal
class function NormalizeAngle(const Angle: Double): Double;    // → [0, 2π)
class function NormalizeAngleDeg(const Angle: Double): Double; // → [0, 360)
```

The normalisation routines use constant-time floating-point reduction, including
for very large finite magnitudes. NaN and either infinity return NaN rather than
looping.

### Basic Trigonometry

```pascal
class function Sin(const X: Double): Double;
class function Cos(const X: Double): Double;
class function Tan(const X: Double): Double;
```

### Inverse Trigonometry

```pascal
class function ArcSin(const X: Double): Double;
class function ArcCos(const X: Double): Double;
class function ArcTan(const X: Double): Double;
class function ArcTan2(const Y, X: Double): Double;
```

### Hyperbolic Functions

```pascal
class function Sinh(const X: Double): Double;
class function Cosh(const X: Double): Double;
class function Tanh(const X: Double): Double;
```

### Inverse Hyperbolic Functions

```pascal
class function ArcSinh(const X: Double): Double;
class function ArcCosh(const X: Double): Double;  // X >= 1; returns NaN otherwise
class function ArcTanh(const X: Double): Double;  // X in (-1, 1); returns NaN otherwise
```

The hyperbolic and inverse-hyperbolic implementations use small-argument and
large-argument forms to avoid losing tiny inputs through subtraction and to
avoid avoidable intermediate overflow.

### Reciprocal Trigonometry

```pascal
class function Sec(const X: Double): Double;
class function Csc(const X: Double): Double;
class function Cot(const X: Double): Double;
```

### Triangle Calculations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `Hypotenuse` | `A, B` | √(A² + B²) (Pythagoras) |
| `TriangleArea` | `Base, Height` | ½ × Base × Height |
| `TriangleAreaSAS` | `SideA, Angle, SideB` | ½ × a × b × sin(angle); angle in radians |
| `TriangleAreaSSS` | `A, B, C` | Heron's formula |
| `TrianglePerimeter` | `A, B, C` | A + B + C |
| `TriangleInRadius` | `A, B, C` | Radius of inscribed circle |
| `TriangleCircumRadius` | `A, B, C` | Radius of circumscribed circle |

### Circle Calculations

| Method | Parameters | Description |
|--------|-----------|-------------|
| `CircularSectorArea` | `Radius, Angle` | ½ r² θ; angle in radians |
| `CircularSegmentArea` | `Radius, Angle` | ½ r² (θ − sin θ); angle in radians |
| `ChordLength` | `Radius, Angle` | 2r sin(θ/2); angle in radians |

### 2-D Vector Helpers

| Method | Parameters | Description |
|--------|-----------|-------------|
| `VectorMagnitude` | `X, Y` | Scaled Euclidean magnitude √(X² + Y²), avoiding intermediate square overflow |
| `VectorAngle` | `X1, Y1, X2, Y2` | Angle in radians ∈ [−π, π] from (X1,Y1) to (X2,Y2) |

The triangle, circle, reciprocal-trigonometric, and vector helpers do not
reject negative dimensions, invalid triangle sides, zero divisors, or other
degenerate geometry; validate such inputs in the calling application.

---

## Quick Start

```pascal
uses MathBase.MathConstants, MathBase.SharedTypes, MathBase.Precision, MathBase.Trigonometry;

var
  HypLen: Double;
  Normal: Double;
begin
  HypLen := TTrigKit.Hypotenuse(3, 4);            // 5.0
  Normal := NormalCDF(1.96);                       // ≈ 0.975
  Writeln(HypLen:0:4, '  ', Normal:0:4);
end.
```

## Dependencies

None. `MathBase` has no dependencies on other domains in mathlib-fp.
