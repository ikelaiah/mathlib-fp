# Spec: 2.1 Special Functions II

Status: J/Y, I/K, the first elliptic integral slice, real Ei/E1, and bounded
real Gauss 2F1 are implemented. A bounded real Jacobi sn/cn/dn slice is
implemented and locally qualified; third-kind elliptic integrals remain to be
resolved.

## Objective

Give Free Pascal users a dependable, native scalar special-function baseline
for scientific and engineering calculations. The [roadmap](../docs/project/roadmap.md)
commits Bessel J/Y/I/K families, elliptic integrals and functions, exponential
integrals, and a bounded hypergeometric baseline for 2.1. A family is ready
only when its domain, error budget, independent references, and algorithm
provenance are published and tested.

## Assumptions for review

1. The first implementation slice is real `Double` Bessel J/Y at orders zero
   and one. Broader orders are a separate decision based on numerical evidence.
2. A new `MathBase.SpecialFunctions` unit owns the public functions. Existing
   `MathBase.Precision` signatures and behavior remain intact.
3. The initial Bessel names and bounded real contract are fixed below; the
   other families' contracts are decided before their implementation.
4. Only the roadmap's 2.1 families enter this release; arbitrary precision and
   an unbounded hypergeometric API remain outside scope.

## Environment and commands

- Language/compiler: Object Pascal, FPC 3.2.2+; no third-party runtime.
- Source: `src/MathBase.*.pas`; tests: `tests/TestMathBase.pas` or a focused
  `tests/TestSpecialFunctions.pas` registered in `tests/TestRunner.lpr`.
- Documentation: `docs/guides/domains/math-base.md`, `docs/reference/capabilities.md`,
  API reference and a runnable `examples/` program.
- Build/test from `tests/`:
  `fpc -B -FcUTF8 '-Fu..\src' '-FUlib' TestRunner.lpr` on Windows, then
  `./TestRunner -a --format=plain` (use `./TestRunner.exe` on Windows).
- Documentation from repository root: `python tools/check_docs.py`.
- Check committed reference data with the family generator, including
  `python tools/generate_hypergeometric_data.py --check`.
- Examples on Windows: `./build-examples.ps1`; on Unix: `sh ./build-examples.sh`.

## Remaining contract decisions

- Third-kind elliptic integral domain and parameter conventions.

## Initial J/Y contract

- Public functions: `BesselJ0`, `BesselJ1`, `BesselY0`, `BesselY1`, each taking
  one `Double` and returning `Double` from `MathBase.SpecialFunctions`.
- J0/J1 accept finite `|X| <= 100`; J0 is even and J1 is odd. `J0(0)=1` and
  `J1(0)=0`. Y0/Y1 accept finite `0 < X <= 100`; at zero both return negative
  infinity, and Y1 returns negative infinity on representable positive inputs
  where its pole exceeds the `Double` range. Negative X, nonfinite inputs, and
  finite inputs beyond the validated bound return NaN.
- Across the accepted range, the absolute error target is at most `5e-13` or
  the relative error target is at most `5e-12`, whichever allows more error.
  Near roots the absolute budget governs. The corpus includes points on each
  side of the 8 and 16 method transitions and values near J/Y roots.
- The implementation uses a small-argument series, a Chebyshev approximation
  over `[8,16]`, and a large-argument asymptotic series. The committed
  reference values are calculated independently with 120-digit decimal power
  series arithmetic through the full validated range.

## Modified Bessel I/K contract

- Public functions: `ModifiedBesselI0`, `ModifiedBesselI1`,
  `ModifiedBesselK0`, and `ModifiedBesselK1`, each taking and returning
  `Double` from `MathBase.SpecialFunctions`.
- I0/I1 accept finite `|X| <= 100`; I0 is even, I1 is odd, `I0(0)=1`, and
  `I1(0)=0`. K0/K1 accept finite `0 < X <= 100`; both return positive
  infinity at zero, and K1 returns positive infinity when its pole exceeds
  the `Double` range. Negative K inputs, nonfinite inputs, and finite inputs
  beyond the validated bound return NaN.
- Across the accepted range, the error target is at most `5e-13` absolute or
  `5e-12` relative, whichever allows more error. Small-positive K1 values
  whose result is infinite are covered as pole behavior rather than by the
  finite-value error budget.
- No scaled variants are included: over the bounded range, I0/I1 remain
  finite and K0/K1 remain representable for ordinary positive inputs. The
  implementation uses the positive power series for I0/I1, the logarithmic
  series for K0/K1 near zero, a generated Chebyshev approximation for K in
  the middle interval, and the large-argument asymptotic expansions for K.
  The independent reference corpus uses 120-digit Decimal series arithmetic.
- Formula sources: NIST DLMF [I definition](https://dlmf.nist.gov/10.25.E2),
  [K integer-order series](https://dlmf.nist.gov/10.31.E1),
  [K0 series](https://dlmf.nist.gov/10.31.E2), and [large-argument
  expansions](https://dlmf.nist.gov/10.40.E1).

## Legendre elliptic integral contract

- Public functions: `CompleteEllipticK(m)`, `CompleteEllipticE(m)`,
  `IncompleteEllipticF(phi, m)`, and `IncompleteEllipticE(phi, m)` in
  `MathBase.SpecialFunctions`. The parameter is `m = k^2`, matching the
  parameter convention common in numerical APIs; it is not the modulus `k`.
- All functions accept finite `0 <= m <= 1`. Incomplete functions additionally
  accept finite `-Pi/2 <= phi <= Pi/2`; outside these domains, and for NaN or
  infinity, they return NaN. Incomplete F/E are odd in `phi`.
- At `m=0`, complete K/E equal `Pi/2` and incomplete F/E both equal `phi`.
  At `m=1`, complete K is positive infinity and complete E is 1.
  Incomplete F is `atanh(sin(phi))` for interior amplitudes and signed infinity
  at either endpoint; incomplete E is `sin(phi)`, including signed endpoints.
- The numerical target for finite results is `5e-13` absolute or `5e-12`
  relative, whichever allows more error. Tests include the singular limit,
  amplitudes near both endpoints, small and near-unit parameters, and symmetry.
- For `0 <= m < 1`, incomplete functions use Carlson's symmetric forms:
  `F = s RF(c^2, c^2+(1-m)s^2, 1)` and
  `E = s RF(...) - m s^3 RD(...)/3`, where `s=sin(phi)` and `c=cos(phi)`.
  Complete values evaluate these at `phi=Pi/2`. Duplication iterations use the
  convergent correction polynomials for RF and RD; the complementary argument
  is formed as `c^2+(1-m)s^2` to avoid cancellation near `m=1`.
- Definitions: NIST DLMF [Legendre integrals](https://dlmf.nist.gov/19.2),
  relations to Carlson forms [DLMF §19.25](https://dlmf.nist.gov/19.25), and
  duplication computation [DLMF §19.36](https://dlmf.nist.gov/19.36). The
  checked-in independent corpus is generated by Gauss-Legendre quadrature in
  the defining integrals, separate from the Carlson implementation.
- The first slice defers third-kind integrals, amplitudes outside the principal
  interval, complex arguments, and Jacobi elliptic functions.

## Real Jacobi elliptic function contract

- Public functions: `JacobiEllipticSN(U, M)`, `JacobiEllipticCN(U, M)`, and
  `JacobiEllipticDN(U, M)` in `MathBase.SpecialFunctions`. `M` is the
  parameter `m=k^2`, matching the Legendre elliptic API, not the modulus `k`.
- Accept finite `|U| <= 100` and finite `0 <= M <= 1`. Nonfinite values or
  inputs outside these bounds return NaN. The real functions are finite across
  the accepted domain.
- At `M=0`, return `sin(U)`, `cos(U)`, and `1`. At `M=1`, return `tanh(U)`,
  `sech(U)`, and `sech(U)`. SN is odd; CN and DN are even.
- Finite results target `5e-13` absolute error or `5e-12` relative error,
  whichever allows more. The reference corpus covers small and large U,
  negative arguments, modulus parameters near both endpoints, quarter-period
  neighborhoods, and the `M=0`/`M=1` limits. Identities are additional checks.
- For `0<M<1`, reduce U by the half-period `2K(M)` and solve
  `F(phi|M)=U` on `[-Pi/2,Pi/2]` with safeguarded Newton/bisection. The
  incomplete integral uses the already-qualified Carlson RF implementation;
  see DLMF [Legendre definitions](https://dlmf.nist.gov/19.2) and
  [Carlson forms](https://dlmf.nist.gov/19.25). Compute DN from
  `sqrt(1-M*SN^2)` using the real identity in [§22.6(i)](https://dlmf.nist.gov/22.6).
- The reference corpus uses 100-digit Decimal AGM and inverse-sine arithmetic,
  independent of the Carlson inversion used by the functions.
- Other Jacobi functions, the amplitude as a public API, complex arguments,
  and parameter values outside `[0,1]` remain deferred.

## Real exponential integral contract

- Public functions: `ExponentialIntegralEi(X)` and
  `ExponentialIntegralE1(X)` in `MathBase.SpecialFunctions`.
- `ExponentialIntegralEi` accepts finite `|X| <= 100`. It returns negative
  infinity at either signed zero, following the real principal-value limit;
  nonfinite inputs and finite values outside the validated range return NaN.
- `ExponentialIntegralE1` accepts finite `0 <= X <= 100`. It returns positive
  infinity at zero; negative, nonfinite, and out-of-range values return NaN.
  The real negative-axis branch of complex E1 is deliberately unsupported.
- Finite results target `5e-13` absolute error or `5e-12` relative error,
  whichever allows more. Coverage includes both sides of zero, the zero poles,
  the series/continued-fraction transition, large positive and negative tails,
  denormal-scale positive inputs, and the range boundary.
- Ei for positive X uses the convergent DLMF power series. For negative X,
  compute `Ei(X)=-E1(-X)`. E1 uses its logarithmic power series through X=2
  and the DLMF continued fraction for X>2. This avoids cancellation in the
  alternating series on the large positive tail. The validated input bound
  keeps Ei(100) representable and avoids an overflow contract.
- Definitions and identities: NIST DLMF [§6.2](https://dlmf.nist.gov/6.2);
  power series [§6.6](https://dlmf.nist.gov/6.6); continued fraction
  [§6.9](https://dlmf.nist.gov/6.9); large-argument behavior
  [§6.12](https://dlmf.nist.gov/6.12); computation guidance
  [§6.18](https://dlmf.nist.gov/6.18). Reference fixtures combine 120-digit
  Decimal power-series values with independent Gauss-Legendre quadrature of
  the defining E1 integral for the continued-fraction range.
- Complex-valued branches, generalized exponential integrals, and scaled
  exponential integrals are deferred.

## Bounded Gauss hypergeometric contract

- Public function: `GaussHypergeometric2F1(A, B, C, X)` in
  `MathBase.SpecialFunctions`, returning real `Double`.
- Accept finite `-16 <= A,B <= 16`, `0.5 <= C <= 32`, and
  `-0.75 <= X <= 0.75`. These limits keep the denominator parameter away from
  its poles and the Gauss series inside its disk of convergence.
- The convergent Gauss series returns the value, including terminating cases
  when A or B is a nonpositive integer and `X=0` where the value is 1. Invalid,
  nonfinite, or out-of-range arguments return NaN. If the series does not meet
  its convergence test within 10,000 terms, return NaN.
- Finite results target `5e-13` absolute error or `5e-12` relative error,
  whichever allows more. Use compensated summation and a tail-aware stopping
  test. Reference coverage includes positive and negative X, near-zero and
  boundary arguments, terminating polynomials, a near-zero function value,
  and parameter boundaries.
- Evaluate the Gauss series from NIST DLMF [§15.2](https://dlmf.nist.gov/15.2)
  using the Maclaurin-method guidance in [§15.19(i)](https://dlmf.nist.gov/15.19.i).
  The restriction `|X| <= 0.75` deliberately defers continuation and branch
  handling at or beyond the unit circle.
- Complex parameters/arguments, analytic continuation, regularized forms,
  confluent functions, and other generalized hypergeometric functions remain
  outside this slice.

## Testing and evidence

- Commit an independent reference corpus with generator/version/precision,
  citations, and decimal values. Generation may use an external high-precision
  tool during development; routine builds and tests may not require it.
- Test normal values, boundaries, roots/poles, small and large magnitudes,
  invalid inputs, and every algorithm transition. Add identities or recurrence
  checks as secondary evidence, not as the sole accuracy oracle.
- Keep platform checks in the supported CI matrix, and run optimized and
  checked FPC builds before declaring a family stable.

## Primary numerical references to evaluate

- NIST DLMF [Bessel methods of computation](https://dlmf.nist.gov/10.74).
- NIST DLMF [elliptic integral methods](https://dlmf.nist.gov/19.36).
- NIST DLMF [exponential integral definitions](https://dlmf.nist.gov/6.2)
  and [methods of computation](https://dlmf.nist.gov/6.18).
- NIST DLMF [hypergeometric methods of computation](https://dlmf.nist.gov/15.19).

These are starting references for design and validation. Each implemented
piecewise method needs a specific formula or algorithm citation in the final
source documentation.

## Boundaries

- Preserve every 2.0 public contract. No mandatory DLL, foreign numerical
  runtime, service, or network access.
- Prefer small scalar APIs and readable Pascal algorithms over a broad wrapper
  surface. Do not import third-party numerical source without a separate
  licensing and maintenance review.
- Document unsupported orders, domains, and parameter regions rather than
  silently returning plausible values outside the validated range.

## Success criteria

Each family shipped in 2.1 meets the roadmap completion gate, appears
accurately in the capability inventory and guides, and passes the independent
corpus, FPC test suite, examples, and supported platform checks. The release
records distinguish shipped coverage from deferred cases.
