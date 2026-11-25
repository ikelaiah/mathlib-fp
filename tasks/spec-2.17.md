# 2.17.0 exact integers and rationals

## Workflow and evidence

An exact sampling calculation draws 50 units from a lot of 100, of which 50
are marked. The probability of drawing exactly 25 marked units is
`C(50,25)² / C(100,50)`. The denominator is
`100891344545564193334812497256`, beyond signed 64-bit storage. The reduced
probability is `2110031698716658293304/13322197258529868226331`. An exact
count and fraction let callers compare and reproduce the result without
rounding. [NIST combinatorial identities](https://dlmf.nist.gov/26.3)

The fixed-width `TCombinatoricsKit.Combination` checks each product before
dividing. Its guard can reject an intermediate even when the final count
fits. For example, the exact `C(66,33)` is `7219428434016265740`. The new
helper should support that count as well as `C(67,33)` and `C(100,50)`.
The reproduction passed with Free Pascal 3.2.2 on Win64 and Win32 with
range and overflow checking enabled against the published 2.16.0 source.

```pascal
program FixedWidthCombinationRepro;

{$mode objfpc}{$H+}

uses
  SysUtils, CombinatoricsLib.Combinatorics;

procedure ExpectOverflow(N, K: Integer);
var
  Count: Int64;
begin
  try
    Count := TCombinatoricsKit.Combination(N, K);
    Writeln('Unexpected count ', Count);
    Halt(1);
  except
    on E: ECombinatoricsError do
    begin
      if Pos('overflows Int64', E.Message) = 0 then
        raise;
      Writeln('C(', N, ',', K, ') exceeds the fixed-width calculation');
    end;
  end;
end;

begin
  if TCombinatoricsKit.Combination(61, 30) <> 232714176627630544 then
    Halt(1);
  ExpectOverflow(66, 33);
  ExpectOverflow(67, 33);
  ExpectOverflow(100, 50);
end.
```

Independent oracle using the Python standard library

```python
from fractions import Fraction
from math import comb

assert comb(61, 30) == 232714176627630544
assert comb(66, 33) == 7219428434016265740
assert comb(67, 33) == 14226520737620288370
denominator = comb(100, 50)
assert denominator == 100891344545564193334812497256
assert Fraction(comb(50, 25) ** 2, denominator) == Fraction(
    2110031698716658293304, 13322197258529868226331
)
```

## Proposed public contracts

Use the existing Object Pascal record style and a focused unit, provisionally
`MathBase.ExactArithmetic`, for `TBigInteger` and `TBigRational`. Expose
arithmetic and comparison without writable storage. Exact factorial and
combination helpers are additive to the combinatorics API.

| Area | Contract |
| --- | --- |
| Integer values | A default-initialized value is zero. Assignment, arithmetic, and conversion leave the original value intact. Zero has one representation. |
| Integer operations | Signed comparison, addition, subtraction, multiplication, negation, division with remainder, GCD, and nonnegative integer powers. Division truncates toward zero and preserves `A = B*Q + R`, with `abs(R) < abs(B)` and nonzero `R` carrying the sign of `A`. GCD is nonnegative, with `GCD(0, 0) = 0`. Exponent zero returns one. |
| Rational values | A default-initialized value is `0/1`. Every value is reduced and has a positive denominator. Provide construction from two integers, comparison and exact arithmetic including division. A zero denominator or division by zero raises a documented exact-arithmetic error. |
| Text | Select decimal or hexadecimal explicitly. Accept the selected radix's ASCII digits and one optional leading sign per integer component. Hex input is case-insensitive. Rational input accepts an integer or a numerator and denominator separated by one slash. Format with uppercase hex digits, no prefix, no redundant zeroes, and a canonical `numerator/denominator` for rationals. Reject whitespace, grouping separators and malformed inputs. |
| `Int64` | Conversion in is exact, including `Low(Int64)`. Conversion out succeeds only for an integral value in range. A checked conversion reports range or integrality failures explicitly. |
| `Double` | Decode finite binary64 inputs as exact dyadic values. Reject NaN and infinity. The integer constructor also rejects fractional values. Both stored zeros are canonical. Conversion out rounds to nearest with ties to even, independently of ambient FPU rounding. Report overflow if the rounded value would be infinite. Preserve the sign when a nonzero rational rounds to zero. |
| Combinatorics | Require `N >= 0` for factorial and `0 <= K <= N` for a combination. Return `0! = 1` and `C(N,0) = C(N,N) = 1`. Use the smaller of `K` and `N-K` and keep every recurrence step exact. |

Decimal text and binary64 represent different exact values in general.
Parsing `1/10` produces that fraction. Converting the binary64 value
`0.1` produces `3602879701896397/36028797018963968`.
[Python Fraction reference](https://docs.python.org/3/library/fractions.html)

## Storage and work bounds

- Use normalized little-endian base-`2³²` limbs in a private managed record.
  Treat published buffers as immutable, as Free Pascal dynamic-array
  assignment shares elements. Arithmetic writes fresh or explicitly owned
  scratch buffers. [Free Pascal array reference](https://www.freepascal.org/docs-html/ref/refsu14.html)
- Use a `QWord` accumulator for schoolbook multiplication. The maximum
  limb product plus carry and the existing output limb is `2⁶⁴-1`.
  Use one-limb division and normalized basecase multi-limb division.
  Qualify the quotient estimate, its correction, and the borrow add-back
  with independent fixtures. [GMP basecase division notes](https://gmplib.org/manual/Basecase-Division)
- Start qualification with a proposed cap of 4,096 limbs per public
  magnitude. Each integer therefore has a 16 KiB limb payload cap. Bound
  parsing before allocation and count leading zeros toward the digit limit.
  Report total scratch usage separately from the public payload cap.
- Permit up to twice the public limb width plus one carry limb in a scratch
  magnitude. Each parsed component is subject to the public integer cap.
  Reduce arithmetic results before checking the public cap so a fitting
  rational can survive wider intermediate cross-products. Cross-cancel
  factors before rational multiplication and division.
- Document linear comparison and addition, quadratic schoolbook
  multiplication, and basecase division work proportional to divisor limbs
  times quotient limbs. Record measured timings and memory at named sizes
  on the supported targets before fixing a larger capacity or adding a
  faster multiplication path.

The stable implementation uses only the Free Pascal standard units.
Arbitrary-precision floating point, cryptographic operations, constant-time
guarantees, and solver integration remain outside this milestone.

## Acceptance

- The fixed-width reproduction runs on the supported compiler. The new
  workflow returns the independent exact count and reduced fraction, and
  the existing fixed-width API stays callable with its established behavior.
- Offline Python `int`, `math.comb`, and `fractions.Fraction` fixtures
  cover sign combinations, zero, carries and borrows, powers of the limb
  base, large operands, division identities, reduced fractions, aliasing and
  every documented input and output limit.
- Binary64 fixtures cover exact dyadic conversion, subnormals, halfway ties,
  largest finite values, and overflow across Win32 and the primary targets.
  Record conversion results by bit pattern.
- The Lazarus package and direct-source example compile with standard units
  alone. Finish with the existing normal, optimized, checked and heap-traced
  tests, documentation checks, and release qualification.
