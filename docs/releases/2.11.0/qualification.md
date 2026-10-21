# v2.11.0 qualification record

Contract: [Chronological validation specification](../../../tasks/spec-2.11.md).

## Local qualification

Windows x86-64 FPC 3.2.2 passed all 142 release-qualification gates on
2026-10-22. The [machine-readable result](qualification-win64.json) retains
the gate list; [workflow evidence](workflow-qualification-win64.json) retains
the representative consumer checks.

- All 1,065 tests passed in normal, optimized and runtime-checked/heap profiles,
  with no unfreed heap blocks. A separate optimized Win32 suite passed all tests.
- All 49 examples ran and 30 output contracts passed. Documentation checks
  covered 205 pages, 3,257 API declarations and 13 beginner routes; 25 fragments
  compiled and executed with 24 checked output contracts.
- Offline HTML identity, SHA-256 and extracted links, numerical fault injection,
  migration, convergence, three representative workflows, portability and the
  Lazarus package passed. Performance evidence reviewed 32 rows and 18
  comparisons; this release makes no new speedup claim.
- Five-axis review covered arithmetic bounds, complete-horizon construction,
  row ownership, replay, gap/overlap semantics and PLS integration. Existing
  seeded paths are unchanged.

## Hosted and publication gates

Hosted Linux/Windows CI and checksummed clean-archive qualification, a fresh
archive consumer, exact-main CI, and downloaded release/docs verification
remain required. The final tag must name the validated main tree. Release
bodies contain changelog content; the release title stays in the title field.
