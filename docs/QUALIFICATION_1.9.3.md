# mathlib-fp 1.9.3 qualification

Status on 2026-08-04: **all 71 local release-qualification gates passed;
final Linux and Windows checksummed clean-archive CI is pending**.

## Completion-gate evidence

| Gate | Current evidence |
| --- | --- |
| Complete exact classification | The schema-3 snapshot contains all 2,880 owner/signature-aware declarations: 536 recommended, 1,786 advanced, 127 compatibility, zero experimental, and 431 generic implementation-support rows. The decision checker independently reconstructs each result. |
| Complete conventions and ownership/default decisions | All 50 snapshot units belong to one of 13 domains. Every domain inherits the 15 resolved shared concerns and records specific decisions; unresolved lists are empty. |
| Compatibility closure | All 127 compatibility declarations resolve through five non-overlapping decisions: three named typed replacements with semantic differences and two explicitly retained finance units. |
| Common-path programs | Thirteen domain paths point to concise output-checked programs. Documentation execution compiles/runs them; decision checks reject generic implementation surfaces in the selected source. |
| Exact proposed diff | Source, behavior, warning, and packaging consequences are explicit empty lists; four documentary-priority changes are named separately. |
| Future capability routing | Ergonomic 2-D/3-D vector rotation is routed to a separate 1.10.0 design with no 1.9.x declaration. |
| API compatibility | All source-unit interface SHA-256 values still match the frozen 1.9.0 baseline. No `src/` interface is changed. |

## Required local command

Run from the exact clean 1.9.3 source archive selected for release:

```text
python tools/qualify_release.py --release 1.9.3 --compiler fpc \
  --lazbuild lazbuild
```

The driver runs normal, optimised, checked/heap-traced tests, all examples and
output contracts, API-decision/extractor tests, exact decision and
documentation checks, all runnable documentation programs, the versioned site
and offline archive, the Lazarus package, and the representative benchmark.

## Local preflight result

The command above passed all 71 gates on Windows 11 x86-64 with FPC 3.2.2,
Lazarus 4.8, and Python 3.13.5. The retained result manifest reports zero
failed gates across normal, optimised, checked/heap-traced tests, all examples
and output contracts, API-decision/extractor and documentation tests, exact
decision checks, 22 compiled/executed documentation programs with 21 output
contracts, the 75-page web/offline documentation build, the Lazarus package,
and the representative benchmark.

The checked-heap gate parsed the explicit heaptrc evidence log and found zero
unfreed blocks/bytes. Generated snapshot/reference regeneration was also run
twice before qualification and produced identical SHA-256 content.

## Required clean-archive evidence

The candidate commit must then pass the Linux and Windows release-qualification
workflows against checksummed archives of that exact commit. The Windows job
also builds the Lazarus package. Those authoritative CI results cannot be
replaced by a maintainer checkout or a different commit.

## Dependencies and limits

The stable library and examples use native Free Pascal plus standard RTL/FCL
units only. Documentation tooling uses the Python standard library. No network,
foreign numerical DLL, proprietary software, or external service is part of
the qualification suite.

This is an API-decision release only. It does not claim new numerical evidence,
performance results, portability targets, migration rehearsal, external beta
use, or final-freeze evidence.
