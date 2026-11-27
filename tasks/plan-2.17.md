# 2.17.0 implementation plan

The [specification](spec-2.17.md) records the fixed-width reproduction,
independent results, and the proposed contracts. The first end-to-end
workflow computes a large combination and then the exact probability of
one outcome when sampling without replacement.

| Order | Deliverable | Acceptance and verification |
| --- | --- | --- |
| 1 | Signed integer storage, comparison, text, and checked `Int64` conversion | Compile a small direct-source program that round-trips decimal and hex values above 64 bits. Compare signs, leading zeros, boundary values, and malformed or oversized inputs against the fixture data. |
| 2 | Integer arithmetic, then division with remainder | Implement signed add, subtract, and schoolbook multiply before one-limb and normalized multi-limb division. Check mixed signs, carry chains, exact division, quotient correction and add-back, and the quotient/remainder identity in FPCUnit. |
| 3 | GCD, power, exact counting | Reuse the verified division path. For combinations, reduce the small multiplier and divisor by their GCD, divide the accumulated value exactly by the remaining divisor, and then multiply. Verify one successful recurrence whose final value fits even though multiply-before-divide would exceed the public cap. Compare factorials and combinations to Python. |
| 4 | Reduced rational arithmetic and text | Verify default zero, sign normalization, zero-denominator rejection, comparison, reduced fractions, and near-cap intermediates that reduce to a fitting result. Run the sampling example end to end. |
| 5 | Binary64 conversion in both directions | Decode and encode binary64 by bit pattern. Exercise the rounding ties, carry into a new exponent, signed zero, subnormal and finite overflow boundaries under the supported compiler targets and altered ambient rounding modes. |
| 6 | Package and version the new API | Add the unit to Lazarus and the API and capability inventory. Compile the documented example from source and package consumers. Preserve the published 2.16.0 snapshot, then run the existing full qualification for 2.17.0. |

## Numerical review checkpoints

- Keep published limb buffers immutable. Review assigning a result to an
  operand, copying a value before arithmetic, and returning division results
  together before expanding the public surface.
- Generate deterministic checked-in fixtures with Python's standard library.
  For Pascal's truncation convention, compute the quotient magnitude with
  `abs(a) // abs(b)`, apply the quotient sign, then derive `r = a - b*q`.
  Python's signed `//` and `%` have different semantics for mixed signs.
- Use around one, two, and many limbs for basic coverage. Include
  `2^(32*k) ± 1`, high-limb normalization shifts, malformed text, and the
  public ceiling. Add explicit decimal and hex round trips for the ceiling.
- Inspect bit-pattern conversion tests separately from arithmetic tests.
  An integer or finite fraction should be rounded once, without first
  converting the rational numerator and denominator to floating point.
- Measure public payload and peak scratch use for balanced multiplication,
  multi-limb division, and a rational calculation at smaller and near-cap
  shapes before freezing the proposed limit. The
  [release checklist](todo-2.17.md) tracks this and the existing qualification
  requirements.
