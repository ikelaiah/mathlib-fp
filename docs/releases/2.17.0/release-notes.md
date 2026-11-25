# 2.17.0 release notes

- Adds `TBigInteger` and `TBigRational` in `MathBase.ExactArithmetic`
  for signed integers and reduced fractions with up to 131,072 bits per
  component.
- Supports decimal and hexadecimal text, signed quotient and remainder,
  GCD, integer powers, and explicit binary64 conversions with
  round-to-nearest, ties-to-even export.
- Adds `TCombinatoricsKit.FactorialExact` and `CombinationExact`.
  The sampling example uses them to compute an exact probability with a
  denominator beyond `Int64`.

See the [guide](../../guides/domains/math-base.md#exact-arithmetic-in-2170),
[resource limits](exact-arithmetic-limits.md), and [qualification](qualification.md).
