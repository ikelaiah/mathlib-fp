# mathlib-fp 1.4.0 release notes

**Release status:** prepared for publication; the publication date will be set
when the release is tagged.

## Highlights

- `GeometryLib.Geometry` now provides natural arithmetic for fixed-size
  `TVector2D` and `TVector3D` value records.
- The geometry walkthrough includes a compact Theodorus-spiral construction
  using `Radius := Radius + Step`.

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
until coordinate-transform semantics have their own documented design.

## Validation

Focused tests cover both dimensions, ordinary arithmetic, value/alias
semantics, additive identity and inverse, distributivity, scale inversion,
2-D/3-D agreement, signed zero, zero-scalar division, NaN, infinity, and
overflow. The public-API smoke suite compiles each new operator form. See the
[GeometryLib reference](GeometryLib.md) and run
[`examples/12_geometry.pas`](../examples/12_geometry.pas) for the complete
example.
