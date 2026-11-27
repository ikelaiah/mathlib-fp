# 2.17.0 release qualification

The [numerical provenance](numerical-evidence-provenance.md) describes the
deterministic reference corpus. The [resource measurements](exact-arithmetic-limits.md)
record bounded workloads on native Windows x86-64 and i386. The
[release checklist](../../../tasks/todo-2.17.md) tracks verification,
clean-archive checks, and publication.

## Local verification

All 158 local qualification gates passed on 2026-11-25. The
[machine-readable result](qualification-win64.json) lists each gate.

- FPC 3.2.2 on Win64 passed 1,105 tests in each of the normal, optimized,
  and runtime-checked heap-traced profiles. Heap tracing reported zero
  unfreed blocks.
- FPC 3.2.2 on Win32 passed 1,105 tests with optimization, range checks,
  and overflow checks enabled.
- Lazarus built the package for Win32 and Win64. The sampling example
  compiled and ran against the compiled package units on both targets.
- The API snapshot comparison with 2.16.0 found 42 added declarations.
  All existing declarations match the published snapshot.
- All 55 examples ran and 36 example output contracts passed. The
  documentation check ran 26 Pascal fragments and verified 25 output
  contracts. The 2.16.0 documentation also rebuilt from its published tag
  using the updated version navigation.
- The numerical mutation gate detected all 13 injected faults. The
  generated site and extracted offline documentation passed link checks.
  Migration, workflow consumers, and portability checks also passed.

All hard performance checks passed across 34 benchmark rows. The timing
review flagged the existing allocating FFT at lengths 4,096 and 65,536
at 1.90× and 1.92× the matching-host 2.4.0 baselines. The FFT
implementation and benchmark definitions match 2.16.0.
[Performance results](performance-results-win64.json)

## Hosted qualification

Hosted [Linux and Windows CI](https://github.com/ikelaiah/mathlib-fp/actions/runs/45595291177)
passed for candidate commit `d355900`. The matching
[clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/45591331230)
passed with a SHA-256-verified ZIP on Windows and an outbound-isolated,
SHA-256-verified tarball on Linux. The squash merge `8d5806d` retained
the same Git tree and passed [Linux and Windows CI on main](https://github.com/ikelaiah/mathlib-fp/actions/runs/45928886400).
