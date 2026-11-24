# 2.16.0 release candidate qualification

The [numerical provenance](numerical-evidence-provenance.md) records the
independent reference corpus and supported error budgets. The
[workflow qualification](workflow-qualification.md) describes the checked
example. The [release checklist](../../../tasks/todo-2.16.md) tracks exact
candidate validation, archive evidence, and publication.

## Local verification

- FPC 3.2.2 on Win64 passed all 1,095 tests in normal, optimized, and
  runtime-checked heap-traced builds. Heap tracing reported zero unfreed blocks.
- FPC 3.2.2 on Win32 passed all 1,095 tests in an optimized build. Lazarus
  built the Win32 package in an isolated configuration profile.
- The 1,646-reference corpus and the Airy anchors regenerate byte-for-byte
  with the pinned offline reference generator.
- All 54 examples ran, including the circular-membrane example. The
  documentation example gate executed 25 Pascal fragments and checked 24
  output contracts.
- The API snapshot comparison with 2.15.0 found 12 added declarations in
  `MathBase.SpecialFunctions`. Every existing declaration was preserved.

Hosted CI and clean-archive verification are publication gates for the
exact candidate.
