# mathlib-fp v1.9.2

Version 1.9.2 makes the stable 1.9 breadth easier to learn without changing
the frozen public API. The primary teaching path uses double-real data and
simple allocating calls; single precision, complex values, views,
destinations, reusable factors, and workspaces remain clearly linked advanced
steps.

## Beginner learning path

- The [beginner guide](../../start/beginner-guide.md) introduces Free Pascal dynamic
  arrays, zero-based indexing, managed interface lifetimes, callbacks, options
  records, iteration statuses, invalid-contract exceptions, allocation, and
  precision choices.
- The [recipe index](../../start/recipes.md) covers dense and sparse solves, descriptive
  and streaming statistics, normal probability, interpolation and fitting,
  optimisation, FFT convolution and filtering, time series, finance,
  geometry, and unit conversion.
- Every stable domain landing page now starts with a tested beginner route,
  common-task selection table, exact contract/failure links, allocation and
  precision guidance, and a tested advanced route.
- Common entry points appear before compatibility or implementation
  scaffolding, so ordinary double-real programs do not require generic,
  destination-buffer, or workspace knowledge.

## Search and executable documentation

- Generated documentation search is checked for problem phrases including
  “least squares”, “normal probability”, and “FFT convolution”, even when the
  reader does not know a Pascal identifier.
- Release checks require an output-checked runnable beginner program for all
  13 stable domains. All published recipe code and claimed output are compiled
  and run from the clean source archive.
- The [automated beginner-journey contract](automated-journeys.md)
  verifies search discovery, route links, runnable code, claimed output,
  release identity, and public declarations from checksummed clean archives.

## Install

Download the tagged source as
[`.tar.gz`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.2.tar.gz)
or [`.zip`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.2.zip),
extract it, and compile the README program with `src/` on the unit search path.
No configure step, network access, foreign binary, or third-party runtime
package is required.

## Compatibility and limitations

The checked `public-api-1.9.json` snapshot and all 2,880 owner/signature-aware
declaration rows remain unchanged from 1.9.0. Version 1.9.2 adds no public type,
algorithm family, overload, default, deprecation, storage rule, or implicit
conversion. Existing 1.9 source remains compatible, and the limitations in the
[capability inventory](../../reference/capabilities.md) are unchanged.

See the [1.9.2 qualification report](qualification.md) for the exact
automated release gates and clean-archive requirements.
