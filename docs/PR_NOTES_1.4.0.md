# PR: Add GeometryLib value-vector arithmetic for 1.4.0

## Summary

This PR prepares the mathlib-fp 1.4.0 GeometryLib milestone. It adds concise,
native Free Pascal arithmetic operators to the existing fixed-size `TVector2D`
and `TVector3D` records, along with their documentation, examples, public-API
smoke coverage, tests, release notes, changelog entry, and Lazarus package
metadata.

The change is additive: existing GeometryLib APIs and callers remain
source-compatible. It adds no third-party dependency, external binary, or
later-roadmap storage or matrix work.

## Motivation

Before this change, callers who wanted to combine ordinary geometry vectors had
to construct a new record from individual coordinates. The new operators make
the motivating workflow direct and readable:

```pascal
Radius := Radius + Step;
```

The runnable GeometryLib example uses that form in a compact Theodorus-spiral
construction.

## Changes

### GeometryLib vector operators

`TVector2D` and `TVector3D` now provide the same componentwise operator set:

- vector addition and binary subtraction;
- unary negation;
- scalar multiplication in both orders; and
- vector/scalar division.

The records retain value semantics: operators allocate no storage and do not
modify either operand. Assigning an expression back to an operand, including
`V := V + V`, is safe.

### Floating-point contract

The implementation applies ordinary IEEE-754 `Double` operations to each
coordinate. The reference documents signed-zero preservation, NaN/infinity
propagation, overflow, and scalar zero division. With related IEEE status
exceptions masked, finite overflow produces signed infinity, a non-zero finite
coordinate divided by signed zero produces the corresponding signed infinity,
and zero divided by zero produces NaN.

The operators do not change the caller's FPU exception mask. A caller that has
unmasked invalid-operation, zero-divide, or overflow exceptions receives the
configured FPU exception instead of a result for that operation.

### Documentation and release preparation

- Updated the GeometryLib reference with operator declarations, value/alias
  semantics, floating-point behavior, and the Theodorus example.
- Extended `examples/12_geometry.pas` with runnable arithmetic and
  Theodorus-spiral output.
- Added 1.4.0 prepared release notes and an index entry.
- Added an Unreleased changelog entry and advanced the Lazarus package metadata
  to 1.4.

## Tests and verification

Focused tests cover:

- ordinary arithmetic in both dimensions and both scalar operand orders;
- immutable value/alias behavior;
- additive identity and inverse, distributivity, scale inversion, and 2-D/3-D
  agreement; and
- signed zero, zero-scalar division, NaN, infinity, and overflow with the
  IEEE status exceptions locally masked and restored by the test.

The public-API smoke test compiles every new operator form.

Local verification completed:

- [x] 825 tests pass on Win64 normal, optimized, runtime-checked, and
  heap-traced configurations; heap tracing reports zero unfreed blocks.
- [x] 825 tests pass on optimized Win32.
- [x] All runnable examples compile and execute; the geometry example prints
  Theodorus radii through `sqrt(6)`.
- [x] The Lazarus package builds successfully on Win64.
- [x] `git diff --check` passes.

Linux and Windows CI remain the publication checks for the branch containing
this PR.

## Compatibility and review notes

- No public identifier is removed or renamed.
- Point/vector translation operators are deliberately excluded. Points,
  displacement vectors, and coordinate transforms need a dedicated documented
  design before adding such operators.
- The main review focus is the public numerical contract: scalar-zero division,
  FPU exception-mask behavior, and whether componentwise value arithmetic is
  consistently documented across 2-D and 3-D vectors.

## Out of scope

- Any 1.5.0 or later contiguous storage, matrix, decomposition, or solver
  work.
- Point arithmetic, coordinate-transform APIs, or implicit point/vector
  conversion.
- Publishing or tagging the 1.4.0 release.
