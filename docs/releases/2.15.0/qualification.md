# v2.15.0 qualification record

Contract: [specification](../../../tasks/spec-2.15.md).

## Local qualification

Windows x86-64 FPC 3.2.2 passed all 153 release-qualification gates on
2026-11-04. The [machine-readable result](qualification-win64.json) retains
the gate list; [workflow evidence](workflow-qualification-win64.json) retains
the representative consumer checks.

- All 1,092 tests passed in normal, optimized and runtime-checked/heap
  profiles, with no unfreed heap blocks. A separate optimized Win32 suite
  passed all 1,092 tests.
- All 53 examples ran and 34 output contracts passed. Documentation checks
  covered 230 pages, 3,298 API declarations and 13 beginner routes; 25
  fragments compiled and executed with 24 output contracts.
- Offline HTML identity, SHA-256 and extracted links, numerical fault
  injection, migration, convergence, three representative workflows, the
  artifact-only prediction consumer, portability and the Lazarus package
  passed.
- Five-axis review covered the specification, bitwise and failure contracts,
  FPU state, thread lifetime, compatibility, bounded workers and resource use;
  see the [review notes](pr-notes.md).

The [large-product evidence](parallel-multiply-win64.json) ran three named
shapes at 1, 2, 4 and 8 workers on 16 logical processors, one process per
row. Every run was bitwise equal to the serial blocked kernel, and every
difference from the portable oracle was zero.

| Shape | 2 workers | 4 workers | 8 workers |
| --- | --- | --- | --- |
| 256³ double | 1.96× (0.98) | 4.03× (1.01) | 5.08× (0.64) |
| 384×128×320 double | 1.84× (0.92) | 3.19× (0.80) | 4.50× (0.56) |
| 160³ complex | 1.90× (0.95) | 3.36× (0.84) | 4.10× (0.51) |

Each cell shows speedup over the serial kernel, with scaling efficiency in
parentheses. Peak resident memory changed by at most 0.22 MB relative to
one worker. The build without a thread manager compiled and agreed bitwise.
On Windows it still has threads, so the Unix serial fallback is checked by
the Linux clean-archive run.

The [captured performance result](performance-results-win64.json) passed all
exact correctness, allocation and storage gates. The new four-worker row took
0.38× the serial row's time in the same run. Four advisory timings were
flagged: prior-release `iterative-cg-large` 1.54×, `modelling-qmc-large`
1.51×, `spectral-fft-allocating-n65536` 1.73×, and the same-run
`dsp-fft-large-candidate` 2.03×. Two standalone reruns on the same host
flagged different subsets of FFT/CG/QMC/small-GEMM rows each time. The
four-worker row stayed at 0.37–0.52×. These paths are unchanged in this
release, so the movements are treated as host timing variance. They are
retained explicitly rather than presented as a performance pass. The
speedups above describe this host only.

## Hosted and publication gates

Linux and Windows CI passed in [PR #82](https://github.com/ikelaiah/mathlib-fp/pull/82)
and [CI run](https://github.com/ikelaiah/mathlib-fp/actions/runs/41728537826).
The [clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/41728530088)
passed 152 Linux and 153 Windows gates.
Linux blocked new outbound connections after checksum verification and
extraction; Windows qualified its verified ZIP. Separate platform artifacts
retain the complete evidence.

The first hosted run caught a platform difference. FPC's Linux SIGFPE handler
chooses the exception class from sticky status flags, so the serial kernel
reported an overflow as `EInvalidOp` while a fresh worker reported
`EOverflow`. The contract and test now require an `EMathError` on both paths
and the same subclass on Windows; see the
[specification](../../../tasks/spec-2.15.md).

Both hosted parallel runs were bitwise equal to the serial kernel on every
shape. On Linux, the build without `cthreads` reported no thread manager,
used one worker and agreed bitwise, which confirms the Unix serial fallback.
The hosted runners report 4 logical processors, but speedups were much
smaller than on the local host. In the
[Linux evidence](parallel-multiply-linux-hosted.json), speedup was
1.10–1.22× with 2 workers and 1.53–1.81× with 4–8. In the
[Windows evidence](parallel-multiply-windows-hosted.json), it was
1.85–1.97× with 2 workers and 2.02–2.31× with 4–8. These shared runners
saturate at about two workers' worth of throughput. This is why speedups are
published per host and are not a universal claim.

The finalized branch must retain green CI and clean-archive qualification, and
the resulting exact main commit must pass CI before tagging. Publication and
downloaded artifact verification follow [RELEASING.md](../../../RELEASING.md).
Release bodies contain changelog content; the title stays in the title field.
