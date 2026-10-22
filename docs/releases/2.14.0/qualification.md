# v2.14.0 qualification record

Contract: [specification](../../../tasks/spec-2.14.md).

## Local qualification

Windows x86-64 FPC 3.2.2 passed all 149 release-qualification
gates on 2026-10-22. The [machine-readable result](qualification-win64.json)
retains the gate list; [workflow evidence](workflow-qualification-win64.json)
retains the representative consumer checks.

- All 1,084 tests passed in normal, optimized and runtime-checked/heap
  profiles, with no unfreed heap blocks. A separate optimized Win32 suite passed all tests.
- All 52 examples ran and 33 output contracts passed. Documentation
  checks covered 224 pages, 3,290 API declarations and 13 beginner
  routes; 25 fragments compiled and executed with 24 output contracts.
- Offline HTML identity, SHA-256 and extracted links, numerical fault injection,
  migration, convergence, three representative workflows, portability and the
  Lazarus package passed. Performance evidence reviewed 32 rows and 18
  comparisons; this release makes no new speedup claim.
- Five-axis review covered the specification, numerical/reference and failure
  contracts, ownership, compatibility, bounded arithmetic and resource use.

The [artifact-only consumer evidence](prediction-consumer-win64.json) records
separate compilation, artifact hashes and new-row GLM/PLS predictions.

The [captured performance result](performance-results-win64.json) passed all
exact correctness, allocation and storage gates and both same-run comparisons.
Two prior-baseline timings require advisory review: `spectral-fft-allocating-n4096` 2.30x, `spectral-fft-allocating-n65536` 2.58x.
The same two rows were flagged in the local 2.12.0 and 2.13.0 qualifications;
the FFT implementation is unchanged in this release. These timings do not
establish a new prediction-persistence regression or a speedup claim. Their
movement is retained explicitly rather than presented as a performance pass.

## Hosted and publication gates

Linux and Windows CI passed in [PR #79](https://github.com/ikelaiah/mathlib-fp/pull/79)
and [CI run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39735803468).
The [clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39735767594)
passed 148 Linux and 149 Windows gates.
Linux blocked new outbound connections after checksum verification and
extraction; Windows qualified its verified ZIP. Separate platform artifacts
retain the complete evidence.

Local archive preflight verified SHA-256, matching ZIP/tar contents, the README
quick start, the release example, a fresh-profile Lazarus package consumer,
and offline documentation identity and links.

The finalized branch must retain green CI and clean-archive qualification, and
the resulting exact main commit must pass CI before tagging. Publication and
downloaded artifact verification follow [RELEASING.md](../../../RELEASING.md).
Release bodies contain changelog content; the title stays in the title field.
