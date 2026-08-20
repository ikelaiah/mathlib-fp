# PR notes: 1.9.5

## Scope

This release makes representative performance and allocation behaviour
inspectable, adds exact regression tripwires, and fixes one profile-confirmed
internal DSP bottleneck. It intentionally leaves the frozen public 1.9 API
unchanged.

## Review boundary

- `benchmarks/PerformanceBenchmarks.pas` and `BenchmarkRunner.lpr` emit 14
  canonical rows covering every roadmap domain and required scale.
- `docs/performance-evidence-1.9.5.json` owns claims, correctness budgets,
  exact ceilings, comparison policies, and host-keyed 1.9.4 observations.
- `tools/check_performance_evidence.py` validates captured or newly executed
  output and writes the reviewable result artifact.
- `EngineeringLib.DSP.pas` reuses the tested native radix-2 kernel for supported
  sizes and retains the explicit portable recurrence fallback.
- Release qualification and CI run the contract tests and checked benchmark;
  timing review remains advisory while exact storage/correctness gates fail.

## Required checks

```text
python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc
python tools/qualify_release.py --release 1.9.5 --compiler fpc \
  --lazbuild lazbuild
```

The complete FPCUnit suite, example/output contracts, documentation/API gates,
historical 1.9.4 numerical-evidence gates, package build, and clean-archive
Linux/Windows workflows remain part of qualification.

## Non-goals

This patch does not add SIMD, threads, architecture-specific assembly, external
benchmark dependencies, public APIs, or universal throughput claims. The next
roadmap milestone owns portability and distribution expansion.
