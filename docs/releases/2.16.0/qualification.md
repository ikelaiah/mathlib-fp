# 2.16.0 release qualification

The [numerical provenance](numerical-evidence-provenance.md) records the
independent reference corpus and supported error budgets. The
[workflow qualification](workflow-qualification.md) describes the checked
example. The [release checklist](../../../tasks/todo-2.16.md) tracks exact
candidate validation, archive evidence, and publication.

## Local verification

All 155 Win64 qualification gates passed on 2026-11-25. The
[machine-readable result](qualification-win64.json) records the gate list.

- FPC 3.2.2 on Win64 passed all 1,095 tests in normal, optimized, and
  runtime-checked heap-traced builds. Heap tracing reported zero unfreed blocks.
- FPC 3.2.2 on Win32 passed all 1,095 tests in an optimized build. Lazarus
  built the Win32 package in an isolated configuration profile.
- The 1,646-reference corpus and the Airy anchors regenerate byte-for-byte
  with the pinned offline reference generator.
- All 54 examples ran and 35 example output contracts passed, including the
  circular-membrane example. The documentation gate executed 25 Pascal
  fragments and checked 24 documentation output contracts.
- The API snapshot comparison with 2.15.0 found 12 added declarations in
  `MathBase.SpecialFunctions`. Every existing declaration was preserved.
- The local gates also covered numerical mutation, the rendered and extracted
  offline documentation, migration, workflow checks, portability, and the
  Win64 Lazarus package.

The [performance result](performance-results-win64.json) passed the exact
checks. The existing allocating FFT benchmark was 1.72× the matching-host
2.4.0 timing and triggered an advisory review. Its source and benchmark
definition are unchanged from 2.15.0, which recorded a 1.73× timing for the
same comparison.

Hosted CI and clean-archive verification are publication gates for the
exact candidate.
