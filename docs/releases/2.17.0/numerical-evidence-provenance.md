# Exact arithmetic numerical evidence

The MIT-licensed [reference generator](../../../tools/generate_exact_arithmetic_reference.py)
uses Python standard-library `int`, `math`, `fractions.Fraction`, `struct`
and a fixed random seed. Verify the committed
[fixture data](../../../tests/ExactArithmeticReference.inc) with
`python tools/generate_exact_arithmetic_reference.py --check`.

| Group | Cases | Coverage |
| --- | ---: | --- |
| Signed integers | 111 | Carries, borrows, sign combinations, quotient and remainder, quotient estimate correction, borrow add-back, and GCD |
| Rationals | 38 | Reduction, positive denominators, comparison and four arithmetic operations |
| Binary64 decoding | 54 | Exact dyadic fractions, integral values, and subnormal and normal extremes |
| Binary64 encoding | 70 | Exact bit patterns at halfway ties, subnormal boundaries, exponent changes, and overflow |

The [FPCUnit suite](../../../tests/TestExactArithmetic.pas) checks exact
values and binary64 bits without a tolerance. Encoding cases run in all
four ambient FPU rounding modes. Additional tests cover malformed text,
the public width limit, aliasing, nonfinite conversion inputs, wide rational
intermediates, and exact counting.

Python's `math.comb(2147483647, 6638)` gives a 131,068-bit result.
Multiplying before dividing in the final recurrence step would require
131,081 bits. The test checks the result's hexadecimal width and both
ends against Python.
