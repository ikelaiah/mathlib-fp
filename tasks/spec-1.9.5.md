# Spec: 1.9.5 predictable performance

## Status

In progress on `feat/v1.9.5-predictable-performance`. The user requested the
complete milestone and a new branch.

## Objective

Version 1.9.5 makes representative performance and allocation behaviour
inspectable and mechanically reviewable. An offline maintainer must be able to
reproduce each published row, distinguish cold setup from warmed repeated use,
see logical and measured memory costs, compare matched paths in the same run,
and identify timing movements that require review without treating hosted
runner noise as mathematical precision.

This release preserves the complete portable Pascal implementation and the
frozen 1.9 public API.

## Required coverage

The checked suite covers representative workflows in these roadmap domains:

1. dense linear algebra;
2. sparse storage/solve;
3. matrix-free iterative solve;
4. DSP, including small and large cases;
5. numerical modelling;
6. streaming/batch statistics; and
7. typed data analysis.

Each applicable domain includes a small/setup-sensitive row and a larger
throughput or scale row. A row states its input dimensions, scalar kind,
compiler flags, warm-up/repetition rules, tolerance/correctness check,
allocation metric, retained memory/state, and comparison reference.

## Evidence semantics

- `cold_ms` includes the first measured operation after deterministic fixture
  construction; `warm_ms` follows an unmeasured warm-up and uses
  repeated prepared calls.
- Exact logical allocation and retained-state counts are hard gates when the
  API makes them countable. Sampled `GetHeapStatus.TotalAllocated` deltas are
  labelled as sampled live-heap observations, not total allocation-event
  counts.
- Dense-shape allocation counters for sparse/matrix-free cases must remain
  exactly zero. Complexity tripwires use two sizes and a generous ratio bound
  on logical work/storage, not wall-clock time.
- Same-run timing comparisons match algorithm, precision, tolerance, setup,
  and result validation. Prior-release timing is advisory and host-keyed.
- A timing ratio outside its review band produces `review`, not failure, on
  variable runners. Invalid checksums, missing rows, and hard ceilings fail.

## Tooling and outputs

- `benchmarks/BenchmarkRunner.lpr` emits human-readable progress plus canonical
  `PERF|key=value` rows.
- `docs/performance-evidence-1.9.5.json` defines required rows, comparison
  policies, hard ceilings, prior 1.9.4 baseline observations, and documentation
  claim identifiers.
- `tools/check_performance_evidence.py` compiles/runs or validates captured
  output and writes `performance-results.json` with host, compiler, flags,
  rows, comparisons, and pass/review status.
- `tools/test_performance_evidence.py` proves parser and contract failures with
  small fixtures and does not execute the full benchmark.
- `tools/qualify_release.py` runs the checked benchmark and retains its JSON and
  log in the qualification directory.

## Constraints

- No network, third-party runtime, foreign numerical library, or proprietary
  reference is required.
- No public declaration changes. `docs/public-api-1.9.json` remains exact.
- Do not hard-gate wall-clock regression against results from a different host
  or an unstable hosted runner.
- Do not claim exact allocation-event counts from sampled heap values.
- Do not optimize a numerical path before repeated profiling shows material
  benefit; preserve a clear portable implementation and cross-path oracle.

## Success criteria

1. Every roadmap domain resolves to checked small/large evidence as applicable.
2. Every published performance/memory claim names reproducible conditions and
   a manifest row.
3. Exact allocation/complexity regressions fail mechanically; noisy timings
   receive an explicit review status.
4. No stable path has an unexplained material prior-baseline regression or an
   inappropriate dense-shape allocation.
5. Full local qualification passes and produces a reviewable versioned result
   artifact; clean-archive Linux/Windows CI remains required before tagging.
