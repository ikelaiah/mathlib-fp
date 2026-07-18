# mathlib-fp 1.2.2 release notes

**Release date:** 2026-07-18

**Release status:** Patch release

mathlib-fp 1.2.2 is a backward-compatible documentation and developer-tooling
release focused on making the runnable examples a dependable learning path for
new users.

## Highlights

- Added a MathBase getting-started program covering shared numeric types,
  constants, precision helpers, trigonometry, compiler paths, and generated
  unit output.
- Added a NumericsLib walkthrough covering root finding, integration, ODE
  solving, interpolation, convergence details, and expected input errors.
- The 14 runnable programs now include at least one representative walkthrough
  for every documented mathlib-fp domain.
- Added an example index that explains what each program teaches and suggests a
  short learning path from installation to the complete API guides.
- Reviewed the examples for concise explanations of purpose, inputs, outputs,
  units, and method choice. The statistics walkthrough now uses a reproducible
  local bootstrap seed and gives safer p-value and effect-size guidance.
- Added `build-examples.sh` and `build-examples.ps1`. Both compile every example
  into `example-bin/` while keeping generated units in `example-bin/units/`.

## Build all examples

From the repository root, use the script for your shell:

```bash
sh ./build-examples.sh
```

```powershell
.\build-examples.ps1
```

Use the `FPC` environment variable with the shell script, or PowerShell's
`-Compiler <path>` option, if `fpc` is not on `PATH`. The output directory is
ignored by Git.

See the [example guide](../examples/README.md) for the full index, individual
build instructions, and suggested learning path.

## Compatibility

- No public Pascal unit, type, method, property, or exception was added,
  renamed, or removed.
- No numerical algorithm or library runtime behaviour changed.
- Existing source code compatible with 1.2.1 remains compatible with 1.2.2.
- Requirements remain Free Pascal 3.2.2 or later and Lazarus 4.8 or later when
  using the optional Lazarus package.
- The Lazarus package metadata reports version 1.2.2.

No application migration is required.

## Quality assurance

- All 14 examples compile and run with Free Pascal 3.2.2.
- The shell and PowerShell build scripts compile all 14 examples into their
  documented output directory.
- The full registered suite passes all 789 tests with zero errors and zero
  failures.
- CI is configured to compile through the platform-native script and run every
  resulting example on Linux and Windows.
- `git diff --check` reports no whitespace errors.

For the complete change list, see the
[changelog](../CHANGELOG.md#122---2026-07-18).

Bug reports and contributions are welcome through the GitHub repository. For
security reports, follow the [security policy](../SECURITY.md).

mathlib-fp is distributed under the [MIT License](../LICENSE.md).
