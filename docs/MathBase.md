# MathBase

Foundation domain for mathlib-fp. All other domains depend on its units.

## Learning routes

### Beginner route

Copy and run the [double-real quick start](#quick-start). It prints
`5.0000  0.9750` using a shared array-free scalar path. The calls return
`Double` values and allocate no caller-visible workspace. Read the
[newcomer guide](BEGINNER_GUIDE.md) before selecting another precision.

### Common tasks and algorithm choice

| Task | Start with | Contract or failure guidance |
| --- | --- | --- |
| Shared real samples | `TDoubleArray` | [Shared types](#mathbasesharedtypes) |
| Floating-point comparison | `NearlyEqual` | [Precision](#mathbaseprecision) |
| Angles and triangle helpers | `TTrigKit` | [Trigonometry](#mathbasetrigonometry-ttrigkit) |
| Reproducible simulation | `TLocalRandom` | [Random-state contract](AppliedNumerics.md#reproducible-local-random-state) |
| Portable saved numerical data | `MathBase.Interchange` | [Interchange format choice](Interchange.md#choose-a-format) |

### Advanced route

Run [example 14](../examples/14_complex_vectors.pas) for complex scalars and
destination-reusing vector kernels, or [example 20](../examples/20_interchange_replay.pas)
for explicit random-state replay. `TDoubleArray` remains the shared real
container; moving to `TComplexArray` or a destination buffer is an explicit
choice documented by those guides. The examples are compiled and run in CI.

## Units

| Unit | File |
|------|------|
| `MathBase.SharedTypes` | [MathBase.SharedTypes.pas](../src/MathBase.SharedTypes.pas) |
| `MathBase.Complex` | [MathBase.Complex.pas](../src/MathBase.Complex.pas) |
| `MathBase.MathConstants` | [MathBase.MathConstants.pas](../src/MathBase.MathConstants.pas) |
| `MathBase.Precision` | [MathBase.Precision.pas](../src/MathBase.Precision.pas) |
| `MathBase.Trigonometry` | [MathBase.Trigonometry.pas](../src/MathBase.Trigonometry.pas) |
| `MathBase.Iteration` | [MathBase.Iteration.pas](../src/MathBase.Iteration.pas) |
| `MathBase.Random` | [MathBase.Random.pas](../src/MathBase.Random.pas) |
| `MathBase.Interchange` | [MathBase.Interchange.pas](../src/MathBase.Interchange.pas) |
| `MathBase.Expressions` | [MathBase.Expressions.pas](../src/MathBase.Expressions.pas) |

---

## Reproducibility and interchange

Version 1.8 adds `TLocalRandom`, an explicit-state generator that never touches
the RTL global `RandSeed`, plus invariant text, delimited, Matrix Market, and
checked binary interchange. See the [applied numerics guide](AppliedNumerics.md)
for the random-state contract and the [interchange guide](Interchange.md) for
format versions, ownership, limits, and failure behaviour.

`MathBase.Expressions` is an opt-in, bounded mathematical evaluator for finite
scalar, vector, and dense-matrix symbol bindings. It supports arithmetic,
elementwise elementary functions, `dot`, `matmul`, and `transpose`, subject to
caller-selected text, depth, operation, and element limits. It deliberately
has no assignment, loops, recursion, I/O, process, environment, network, or
callback primitives. See the [interchange guide](Interchange.md) for the
language and safety boundary.

## MathBase.Complex

Portable single- and double-precision complex arithmetic. `TSingleComplex` and
`TComplex` are value records with `Re` and `Im` fields; their operators never
mutate either operand.

```pascal
uses MathBase.Complex;

var
  Z, Root: TComplex;
begin
  Z := TComplex.Create(3.0, 4.0);
  Root := CSqrt(TComplex.Create(-4.0, 0.0));  // 0 + 2i
  Writeln(Z.Magnitude:0:1);                   // 5.0
end;
```

### Type and operations

```pascal
type
  TSingleComplex = record
    Re, Im: Single;
    class function Create(ARe, AIm: Single): TSingleComplex; static;
    function Conjugate: TSingleComplex;
    function SqrMagnitude, Magnitude: Single;
    function IsFinite: Boolean;
  end;

  TComplex = record
    Re, Im: Double;
    class function Create(ARe, AIm: Double): TComplex; static;
    class function FromPolar(Radius, Angle: Double): TComplex; static;
    function Conjugate: TComplex;
    function SqrMagnitude, Magnitude, Argument: Double;
    function IsFinite: Boolean;
  end;

  TSingleComplexArray = array of TSingleComplex;
  TComplexArray = array of TComplex;
```

Both types support addition, subtraction, multiplication, division, unary
negation, equality, conjugation, scale-safe magnitude, and finite checks.
`ToComplex` widens explicitly. `ToSingleComplex` narrows explicitly and rejects
a finite component outside the finite `Single` range; it never silently
discards an imaginary component.

`TComplex` additionally supports real-scalar variants and principal elementary
functions. Division and magnitude use scaled forms to
avoid avoidable intermediate overflow and underflow. `CLog`, `CSqrt`,
`CPow`, `CAsin`, `CAcos`, `CAtan`, `CAsinh`, `CAcosh`, and `CAtanh` return
principal values; `CExp`, `CSin`, `CCos`, `CTan`, `CSinh`, `CCosh`, and
`CTanh` are also provided.

For finite complex inputs, finite representable quotient results are preserved
at extreme scales. Magnitude calculations return infinity when either
component is infinite (including infinity paired with NaN) without performing
an invalid infinity/infinity operation. A NaN component otherwise produces a
NaN complex result; dividing a finite value by an infinite complex value
produces zero.

`Argument`, `CLog`, and `CSqrt` preserve the upper/lower branch distinction on
the negative real axis, including signed-zero imaginary components. The
inverse functions preserve first-order tiny inputs, use scaled component and
asymptotic forms rather than squaring large complex inputs, and retain the
signed-zero side of their principal branch cuts. `CExp(+Infinity + 0i)` and
square roots with infinite components return their defined limiting values;
an indeterminate infinite imaginary angle or a NaN component returns a NaN
complex value.

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

The checked-in reference corpus applies these measured acceptance budgets:
`GammaLn` 3e-15 relative (2e-13 absolute at the `x=100` fixture); `Beta`
5e-15 relative for ordinary inputs and 2e-13 for the `Beta(100,100)` scale
case; `BetaInc` 2e-14 relative/2e-15 absolute for ordinary fixtures. `Erf`,
normal tails, and Student-t use absolute or tail-relative budgets in
`TestMathBase.pas`, because one ULP budget is misleading near zero and in the
tails. These are tested budgets over the published corpus, not universal
worst-case proofs.

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

Expected output:

```text
5.0000  0.9750
```

## Dependencies

None. `MathBase` has no dependencies on other domains in mathlib-fp.

Invalid domains and non-finite inputs follow the exception or IEEE behavior
documented beside each operation. In particular, precision predicates return
a Boolean, while parsers, bounded expressions, invalid RNG state, and
operations with an explicit finite-domain contract raise their named
MathBase exception before returning a result.
