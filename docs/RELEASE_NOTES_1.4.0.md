# mathlib-fp 1.4.0 release notes

**Release date:** 2026-07-25

## Highlights

- `GeometryLib.Geometry` now provides natural arithmetic for fixed-size
  `TVector2D` and `TVector3D` value records.
- Vector magnitude and normalization are scale-safe for finite extreme-scale
  components.
- The geometry walkthrough includes a compact Theodorus-spiral construction
  using `Radius := Radius + Step`, symmetric 3-D arithmetic, and runnable
  extreme-scale normalization.

## Vector arithmetic

Both vector types provide componentwise addition, binary subtraction, unary
negation, scalar multiplication in either operand order, and vector/scalar
division:

```pascal
V2 := -((V2 + Step) / 2.0);
V3 := 3.0 * (V3 - Offset);
```

The two types expose the same arithmetic operator set. `TVector2D` keeps its
existing `Perpendicular` helper as the intentional dimensional difference.
The operations return independent record values, allocate no storage, and do
not modify their operands, including when a caller assigns an expression back
to one of its inputs.

All fixed-size arithmetic and numeric vector operations are O(1), allocation-
free on successful calls, and reentrant. Concurrent calls are safe when the
same record storage is not being modified by another thread.

## Magnitude and normalization

`Magnitude` scales components before accumulating their squares, avoiding
premature overflow and underflow for representable finite results. Infinity
takes precedence over NaN in the magnitude, matching hypot-style behavior.
`Normalise` now accepts finite non-zero vectors at tiny and large scales and
returns a new value even when the unnormalised magnitude is too large for
`Double`. It raises `EGeometryError` for exact-zero, NaN, or infinite vectors.

## Floating-point behavior

The operators apply ordinary IEEE-754 `Double` arithmetic to each coordinate.
They preserve normal target behavior for signed zero, NaN, infinity, and
overflow rather than rejecting those values. Finite overflow produces signed
infinity; a non-zero finite coordinate divided by signed zero produces the
corresponding signed infinity; zero divided by zero produces NaN. Arithmetic
operators do not raise `EGeometryError` for these cases and do not alter the
caller's FPU exception mask. The described result values apply with the related
IEEE status exceptions masked; an unmasked FPU exception is reported according
to the caller's configured FPU mode.

## Compatibility

This is an additive API change. Existing GeometryLib record fields, methods,
and callers remain source-compatible. Point/vector translation operators are
not included: points and displacement vectors continue to be distinct types
until coordinate-transform semantics have their own documented design. The
existing normalization API now treats small finite non-zero vectors as valid
and reports non-finite vectors explicitly instead of returning indeterminate
coordinates.

## Validation

Focused tests cover both dimensions, ordinary arithmetic, value/alias
semantics, additive identity and inverse, distributivity, scale inversion,
2-D/3-D agreement, signed zero, zero-scalar division, NaN, infinity, and
overflow. Extreme-scale magnitude and normalization tests cover large and tiny
finite vectors, zero vectors, and non-finite inputs. Dot linearity and magnitude
scaling connect the operators to the established vector methods. The public-API
smoke suite compiles each new operator form. See the
[GeometryLib reference](GeometryLib.md) and run
[`examples/12_geometry.pas`](../examples/12_geometry.pas) for arithmetic,
Theodorus construction, and scale-safe normalization examples.
