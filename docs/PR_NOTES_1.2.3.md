# PR: Improve mathematical correctness and robustness for 1.2.3

## Summary

This change begins the 1.2.3 correctness and robustness release by hardening
the existing scalar numerical kernel and the probability and statistics APIs
that depend on it. It fixes a confirmed Student-t formula defect, improves
special-function accuracy and convergence handling, and preserves small
representable distribution tails.

The change is implemented entirely in Free Pascal. It adds no new domain,
wrapper, DLL, binary SDK, or third-party runtime dependency.

## Motivation

Several operations produced plausible results for ordinary inputs but lost
accuracy or failed at extreme scales:

- `MathBase.Precision.StudentT` used `(df+1)/2` where the incomplete-beta
  identity requires `df/2`;
- survival functions commonly used `1-CDF`, losing upper tails once the CDF
  rounded to one;
- the previous error-function approximation limited normal-CDF accuracy;
- incomplete-beta iteration could return a partial result without reporting
  non-convergence;
- direct products, squares, exponentials, and logarithmic differences caused
  avoidable overflow or cancellation in otherwise representable results.

Because these kernels are shared by distributions and statistical tests, the
fix belongs in the numerical foundation rather than in individual callers.

## Changes

### Special functions

- Replaced the log-gamma core with a higher-accuracy Lanczos implementation
  with reflection and explicit input validation.
- Added stable log-beta evaluation for large and asymmetric parameters.
- Upgraded the incomplete-beta continued fraction with scale protection,
  tighter convergence criteria, a larger iteration budget, symmetry handling,
  and an explicit non-convergence outcome.
- Added incomplete-gamma probability kernels for the error function and direct
  normal-tail evaluation.
- Corrected the Student-t CDF incomplete-beta identity.

### Probability and statistics

- Evaluate normal and lognormal survival probabilities through the negative
  normal tail.
- Evaluate beta survival through incomplete-beta symmetry.
- Evaluate Student-t upper tails directly, including a stable Cauchy tail for
  one degree of freedom.
- Construct F-distribution beta arguments without overflowing `df1*x` and
  evaluate its survival probability directly.
- Avoid overflow from `x*x` in the Student-t density logarithm.
- Use direct normal tails in Mann-Whitney and Shapiro-Wilk approximations.
- Update the Kolmogorov-Smirnov reference expectation to the full-precision
  normal CDF.

### Elementary operations

- Stabilize `Sinh`, `Cosh`, `Tanh`, `ArcSinh`, `ArcCosh`, and `ArcTanh` around
  small arguments, boundaries, and large intermediate values.
- Route two-dimensional vector magnitude through the scaled hypotenuse kernel.

### Documentation

- Document the numerical contracts and direct survival-tail behaviour.
- Add a roadmap for a comprehensive, free, native Free Pascal mathematics
  package while retaining independently usable units and no required DLLs.
- Update the changelog, FAQ, README, and documentation index for 1.2.3 and the
  expanded test count.

## Public API and compatibility

- No public signatures or unit names change.
- No new domain is introduced.
- Source compatibility with 1.2.2 is retained.
- Numerical outputs intentionally change where the old formula or approximation
  was inaccurate.
- Invalid low-level special-function shapes now return NaN consistently, and
  failed iteration no longer masquerades as a converged answer.

## Tests added

- Gamma, beta, incomplete-beta, error-function, normal-CDF, and Student-t
  published/reference values.
- Incomplete-beta symmetry, endpoints, and invalid-shape contracts.
- Tiny hyperbolic arguments and inverse-hyperbolic boundary cases.
- Overflow-resistant vector magnitude.
- Eight-sigma normal and lognormal tails.
- Tiny beta upper tails and extreme Student-t/Cauchy and F tails.

The registered suite grows from 789 to 798 tests.

## Verification

- [x] Release test runner builds successfully.
- [x] All 798 Release tests pass with zero errors and zero failures.
- [x] A direct UTF-8 build passes all 798 tests.
- [x] All 14 examples compile through `build-examples.ps1`.
- [x] The Lazarus `mathlib_fp` package compiles.
- [x] `git diff --check` reports no whitespace errors.
- [x] No generated compiler artifacts remain in `src/`.

## Risk and review notes

The main compatibility risk is changed expected output: callers should see
more accurate Student-t probabilities and non-zero representable upper tails.
Review should concentrate on complement identities, monotonicity, endpoint
semantics, invalid inputs, and behaviour near underflow and overflow limits.

The special-function changes affect multiple domains transitively, so the full
test suite is more relevant than isolated unit tests alone. Public rounding is
still applied only at the API boundary after the unrounded probability has
been calculated.

## Out of scope

- Adding a new mathematical domain.
- Adding wrappers around ALGLIB, BLAS, LAPACK, or another library.
- Requiring a DLL, binary SDK, or third-party runtime component.
- Introducing a new matrix/vector storage model or architecture-specific fast
  path in this patch.
- Expanding API breadth before the current numerical foundation is dependable.

Follow-up work should continue the 1.2.3 audit of existing operations using
reference values, algebraic properties, reconstruction residuals, and extreme-
scale cases described in the [roadmap](ROADMAP.md).
