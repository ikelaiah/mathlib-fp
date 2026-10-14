# v2.8.0 qualification record

The [release contract](../../../tasks/spec-2.8.md) adds dense real-double PLS1
regression for correlated predictors, deterministic cross-validation component
selection, original-scale coefficients, and prediction.

## Local qualification

The full Windows x86-64 qualification passed all 136 gates on 2026-10-14 with
FPC 3.2.2, using
`python tools/qualify_release.py --release 2.8.0 --compiler fpc`.

- The 1,041-test suite passed in normal, `-O3`, and checked-heap/runtime-check
  builds.
- All 46 examples compiled and ran; all checked output contracts passed.
- Documentation checks covered 186 pages, 13 learning routes, and 46 indexed
  examples. The docs execution gate compiled and ran 24 Pascal fragments and
  verified 23 output contracts.
- The generated 186-page offline documentation archive passed extracted-link
  checks.
- The Lazarus package, migration rehearsal, representative workflow,
  convergence, portability, and performance gates passed. Performance evidence
  validated 32 rows and 18 comparisons; no speedup claim is made.
- The Decimal PLS coefficient and cross-validation fixtures passed in all test
  modes, including the optimized build.

## Hosted and publication gates

Pull-request Linux/Windows CI passed on 2026-10-14 in
[PR #73](https://github.com/ikelaiah/mathlib-fp/pull/73). The checksummed
clean-source-archive qualification also passed on both primary profiles in
[workflow run #75](https://github.com/ikelaiah/mathlib-fp/actions/runs/38549338444):
Linux ran offline from the extracted tarball, and Windows qualified from the
extracted ZIP. The run published separate Linux and Windows qualification
artifacts. These gates passed before the v2.8.0 tag was created.

The release body is changelog content only; its title stays in the title field.
