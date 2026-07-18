# mathlib-fp 1.2.1 release notes

**Release date:** 2026-07-18
**Release status:** Patch release

mathlib-fp 1.2.1 is a backward-compatible documentation and test-harness
maintenance release. It standardises how the project describes its domains,
Pascal units, unit families, Kit classes, focused aliases, and Lazarus package.

## Highlights

- Added a canonical terminology guide distinguishing the mathlib-fp project,
  its mathematical domains, Pascal unit families, individual units, Kit
  classes, focused alias units, and the optional Lazarus package.
- Added a public API naming inventory mapping every domain to its primary units
  and documented Kit classes.
- Aligned the README, FAQ, API guides, contributor guidance, source headers,
  release documentation, and Lazarus package description with the terminology.
- Corrected the test-runner registration so the existing focused Engineering
  alias tests run as part of the main suite.
- Added compile-time smoke coverage for every documented Kit class and focused
  alias, bringing the registered suite to 789 tests.

## Compatibility

- No public Pascal unit, type, method, property, or exception name was renamed
  or removed.
- No numerical algorithm or runtime behaviour changed in this release.
- Existing 1.2.0 source code remains compatible with 1.2.1.
- Requirements remain Free Pascal 3.2.2 or later and Lazarus 4.8 or later when
  using the optional Lazarus package.

No migration work is required. “Kit” now consistently describes an API class,
not a domain, Pascal unit, or Lazarus package.

## Quality assurance

- The full registered suite contains 789 tests.
- Normal, optimized, runtime-checked, and heap-traced local builds pass with
  zero failures and zero unfreed memory blocks.
- All 12 examples compile and run.
- The representative benchmark runner compiles and completes.
- The `mathlib_fp` Lazarus package builds with Lazarus 4.8.
- The release PR must pass the Linux, Win64, and Win32 CI matrix before the
  `v1.2.1` tag is created.

For the complete change list, see the
[changelog](../CHANGELOG.md#121---2026-07-18).

Bug reports and contributions are welcome through the GitHub repository. For
security reports, follow the [security policy](../SECURITY.md).

mathlib-fp is distributed under the [MIT License](../LICENSE.md).
