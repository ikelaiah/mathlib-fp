# mathlib-fp 1.2.3 release notes

**Release date:** 2026-07-21

**Release status:** Patch release

mathlib-fp 1.2.3 improves the correctness and numerical robustness of existing
operations. It does not introduce a new mathematical domain or require a
wrapper, DLL, binary SDK, or third-party runtime library.

## Highlights

- Corrected the shared Student-t CDF formula to use the required `df/2`
  incomplete-beta shape parameter. This also corrects statistical p-values
  calculated through that helper.
- Reworked the scalar special-function kernel with a higher-accuracy Lanczos
  log-gamma, cancellation-resistant beta evaluation, convergence-checked
  incomplete-beta continued fractions, and incomplete-gamma normal tails.
- Normal, lognormal, beta, Student-t, and F survival functions now calculate
  representable upper-tail probabilities directly instead of subtracting a
  rounded CDF from one.
- F-distribution argument construction avoids overflowing `df1*x` when the
  final probability remains representable.
- Hyperbolic and inverse-hyperbolic functions preserve small arguments and
  avoid avoidable cancellation or intermediate overflow.
- Two-dimensional vector magnitude now uses a scaled hypotenuse calculation,
  keeping results such as the magnitude of `(1e308, 1e308)` finite.
- Invalid low-level special-function shape parameters return NaN predictably,
  and iterative kernels do not silently return unconverged partial results.
- Normal-tail approximations used by statistical tests follow the same direct-
  tail path as the probability-distribution APIs.
- Kolmogorov-Smirnov empirical CDF steps now use explicit double-precision
  fractions, avoiding compiler-dependent single-precision evaluation.

## Numerical behaviour changes

Applications may observe more accurate results, especially for:

- Student-t CDFs and p-values;
- normal probabilities several standard deviations into a tail;
- beta, Student-t, and F survival probabilities close to zero;
- beta functions with large or asymmetric parameters;
- tiny hyperbolic arguments and values close to inverse-hyperbolic boundaries;
- vector magnitudes containing very large or very small components.

Code that depended on the previous inaccurate Student-t formula, rounded-tail
subtraction, or unconverged special-function values should update its expected
reference values.

## Compatibility

- No public Pascal unit, type, method, property, exception, or parameter was
  added, renamed, or removed.
- Existing source code compatible with 1.2.2 remains source-compatible with
  1.2.3.
- Correctness fixes intentionally change affected numerical results.
- Requirements remain Free Pascal 3.2.2 or later and Lazarus 4.8 or later when
  using the optional Lazarus package.
- The implementation remains native Object Pascal with no required external
  runtime dependency.

No application migration is required unless tests or stored results encode the
previous numerical approximations.

## Quality assurance

- Normal, optimized, runtime-checked, and heap-traced Win64 builds pass all 798
  tests with zero errors and zero failures; the heap-traced run reports zero
  unfreed memory blocks.
- The complete 798-test suite also passes with the native Win32 compiler.
- All 14 runnable examples compile and run.
- The representative benchmark runner compiles and completes.
- The `mathlib_fp` Lazarus package compiles for Win64 and Win32.
- The Lazarus package metadata reports version 1.2.3.
- New tests cover published reference values, symmetry and complement
  identities, invalid inputs, convergence outcomes, tiny arguments, very large
  vector components, representable extreme distribution tails, and portable
  `Double` evaluation across FPC targets.
- All local Markdown targets resolve, and `git diff --check` reports no
  whitespace errors.

For the complete change list, see the
[1.2.3 changelog](../CHANGELOG.md#123---2026-07-21). The broader native Free
Pascal numerical-computing direction is described in the
[project roadmap](ROADMAP.md).

Bug reports and contributions are welcome through the GitHub repository. For
security reports, follow the [security policy](../SECURITY.md).

mathlib-fp is distributed under the [MIT License](../LICENSE.md).
