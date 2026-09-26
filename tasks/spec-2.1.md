# Spec: 2.1 Special Functions II

Status: J/Y baseline implemented; I/K, elliptic, exponential-integral, and
hypergeometric contracts remain to be resolved before their slices.

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
- Check committed Bessel data: `python tools/generate_bessel_data.py --check`.
- Examples on Windows: `./build-examples.ps1`; on Unix: `sh ./build-examples.sh`.

## Contracts to resolve before code

- Exact names and order coverage for I/K, including whether scaled forms
  are needed to provide useful extreme-range results.
- Real input domains, endpoints, poles, branch conventions, NaN/Infinity,
  overflow, underflow, and signed-zero behavior for each function.
- Per-region absolute/relative error budgets, including neighborhoods of
  zeros and transitions between numerical methods.
- Elliptic parameter convention and complete/incomplete/function subset.
- Exponential-integral branch/sign convention and real supported range.
- Hypergeometric parameter/argument bounds and visible nonconvergence result.

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
