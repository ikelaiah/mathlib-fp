# Implementation plan: 1.9.5 predictable performance

## Overview

Build a release-owned performance evidence contract around the existing
portable benchmark runner. The contract records reproducible conditions,
uniform cold/warmed measurements, allocation and retained-state ceilings,
same-run comparisons, and prior-release advisory baselines. Qualification will
fail on missing rows, invalid results, or exact complexity/allocation
regressions; noisy wall-clock changes will be reported for review.

## Architecture decisions

- Keep numerical workloads in the dependency-free Pascal benchmark runner and
  use Python standard-library tooling only to compile, execute, validate, and
  publish its machine-readable rows.
- Store benchmark contracts in `docs/performance-evidence-1.9.5.json`; generated
  host results remain qualification artifacts rather than source-controlled
  claims that accidentally describe every machine.
- Use exact logical allocation, retained-state, and dense-shape tripwires as
  hard gates. Treat elapsed-time comparisons as advisory unless they are
  same-run algorithm comparisons with a deliberately conservative bound.
- Preserve the frozen 1.9 public API. Change internal numerical code only after
  repeated profiling demonstrates a material benefit and existing cross-path
  correctness tests remain green.

## Dependency graph

```text
benchmark workload contract ──> parser/validator tests ──> Pascal row output
           │                              │                         │
           └──────────────> qualification runner <──────────────────┘
                                          │
                                          v
                         performance guide, release notes, qualification
```

## Task list

1. Specify the v1.9.5 benchmark-row and evidence-manifest contracts.
2. Add failing parser/validator tests for missing domains, malformed rows,
   allocation ceilings, complexity tripwires, and timing review signals.
3. Extend the Pascal runner with representative small/large dense, sparse,
   iterative, DSP, modelling, statistics, and data-analysis rows, including
   cold/warm timing and deterministic correctness checks.
4. Add the offline Python performance gate, host/toolchain capture, same-run
   comparisons, and versioned result JSON.
5. Profile repeatable candidate hot paths; make only justified internal
   optimisations and prove portable/candidate equivalence. Record an explicit
   no-change result when evidence does not justify a source change.
6. Integrate performance validation into CI and release qualification.
7. Update performance policy, capability data, README/releasing guidance,
   changelog, release/PR/qualification notes, documentation index, package and
   version metadata, then advance the roadmap to 1.9.6.
8. Run focused checks, the full test suite, documentation builds, package build,
   and the complete local 1.9.5 qualification; perform a five-axis review.

## Checkpoints

### After tasks 1-2

- Contract tests fail for incomplete or unsafe evidence and pass only for a
  complete representative fixture.
- No production numerical source or public interface has changed.

### After tasks 3-5

- Every required domain has small/large coverage where applicable, cold/warm
  timing, scalar/shape/tolerance/setup metadata, and deterministic checksums.
- Exact allocation and complexity ceilings fail mechanically.
- Any optimisation is backed by repeated same-host evidence and cross-path
  tests; otherwise the release records that no optimisation was warranted.

### After tasks 6-8

- CI and local qualification produce checked performance-result JSON.
- All published performance/memory statements resolve to a manifest row and
  identify conditions and limitations.
- The full release qualification and final review are clean.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hosted-runner timing noise creates false failures | High | Keep prior-baseline timing advisory and use repeated samples plus review bands. |
| Logical allocation counts overstate exact heap accounting | Medium | Name each metric precisely and use sampled heap deltas only where monitor boundaries make them meaningful. |
| Benchmark expansion makes qualification too slow | Medium | Use bounded deterministic cases and a quick contract-fixture mode for Python tests. |
| Optimisation changes numerical order or contracts | High | Profile first, preserve the portable path, and require cross-path numerical tests before accepting it. |
| Release claims drift from executable evidence | High | Cross-reference every claim and domain through the checked manifest and documentation gate. |

## Scope decision

The user requested the complete milestone and authorized implementation. No
new public API, external dependency, platform claim, or optional foreign-library
comparison is needed for 1.9.5.
