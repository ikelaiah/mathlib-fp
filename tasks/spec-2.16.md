# 2.16.0 Special Functions III

An engineer computing a circular membrane mode with angular order two needs
the first zero of J2. The current scalar API exposes J0 and J1. A runnable
example will bracket the J2 zero, recover the radial wavenumber, and check that
the mode vanishes at the rim. The same release extends the existing real-double
special-function unit for positive gamma shapes, zeta for convergent real
arguments, exponential-inverse problems, and Airy turning-point solutions.

## Public contracts

All functions are pure scalar calls. They use the standard Free Pascal Math
unit and return NaN for invalid or nonfinite inputs. All orders are `Integer`.

| Functions | Validated input and endpoints |
| --- | --- |
| `Digamma(X)` and `Polygamma(Order, X)` | Finite `X >= 0`, orders 0–16. Order 0 equals digamma. At zero return the signed one-sided pole, negative for even order and positive for odd order. Values outside the representable range return signed infinity or signed zero as appropriate. |
| `RiemannZeta(S)` | Finite `S >= 1`. At one return positive infinity. This release covers the convergent real series and its pole. |
| `LambertW(X, Branch)` | Branch 0 accepts finite `X >= -1/e`. Branch -1 accepts `-1/e <= X <= 0` with a negative infinite limit at zero. Both branches return -1 at the nearest binary64 representation of `-1/e`. Nonconvergence returns NaN. |
| `BesselJ(Order, X)`, `BesselY(Order, X)`, `ModifiedBesselI(Order, X)`, `ModifiedBesselK(Order, X)` | Orders 0–32 and finite `abs(X) <= 100`. J and I use integer parity for negative arguments. Y and K accept `X >= 0` with negative and positive infinite poles at zero. Orders 0 and 1 delegate to the established functions. Higher-order overflow returns the signed infinity. |
| `AiryAi(X)`, `AiryBi(X)`, `AiryAiPrime(X)`, `AiryBiPrime(X)` | Finite `-100 <= X <= 120`. Return signed infinity or signed zero for overflow and underflow, respectively. |

## Methods and verification

- Use a small-argument series or a stable forward/backward recurrence for
  integer-order Bessel functions. Compare near turning points `X = Order`,
  near J/Y roots, and across small-argument overflow and underflow regions.
  [DLMF recurrence methods](https://dlmf.nist.gov/10.74#iv)
- Shift positive digamma into its asymptotic region. Use an Euler–Maclaurin
  tail for zeta and the Hurwitz series used internally by polygamma. Include
  values near the pole, large arguments, and overflow and underflow cases.
  [Digamma asymptotics](https://dlmf.nist.gov/5.11) · [Polygamma](https://dlmf.nist.gov/5.15) · [Zeta](https://dlmf.nist.gov/25.2#iii)
- Use the branch-point series and a bounded Newton solve for Lambert W. Check
  inputs adjacent to the rounded branch point and in both tails.
  [DLMF Lambert W](https://dlmf.nist.gov/4.13)
- Use local Taylor expansions of the Airy equation and large-argument
  asymptotics. Check both derivatives, turning points, and near overflow
  and underflow. [Airy equation](https://dlmf.nist.gov/9.2) · [Asymptotics](https://dlmf.nist.gov/9.7)
- Generate checked-in reference values with development-only mpmath 1.3.0
  at 100 decimal digits, evaluating the exact binary64 input. Validate mixed
  absolute and relative budgets by family and region. Check pole signs,
  branch selection, domain errors, and representable tiny results explicitly.
- Run the focused FPCUnit suite, then the full suite and existing documentation
  and release checks. Historical API and release evidence remain authoritative
  for previous versions.

Complex arguments, continuation to the left of the zeta pole, reflection of
gamma derivatives to negative shapes, fractional-order Bessel functions, and
scaled public Airy or Bessel APIs are outside this milestone.
