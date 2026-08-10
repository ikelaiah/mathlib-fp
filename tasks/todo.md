# 1.9.5 task list

## Task 1: Performance evidence contract

**Description:** Define the checked manifest and row format for reproducible
performance, allocation, retained-memory, correctness, and setup evidence.

**Acceptance criteria:**

- [x] The manifest requires all seven roadmap domains and small/large scale
  coverage where meaningful.
- [x] Every row names scalar kind, shape, tolerance, setup, timing mode,
  allocation/retained-state semantics, checksum, and comparison policy.
- [x] Timing review signals are distinct from hard allocation/complexity gates.

**Verification:** `python tools/test_performance_evidence.py`.

**Dependencies:** None.

**Estimated scope:** Medium.

## Task 2: Benchmark rows and exact tripwires

**Description:** Extend `BenchmarkRunner` to emit uniform machine-readable
rows for dense, sparse, iterative, DSP, modelling, statistics, and analysis.

**Acceptance criteria:**

- [x] Rows report cold and warmed timing plus deterministic correctness values.
- [x] Exact allocation, retained-state, and inappropriate dense-shape ceilings
  halt the runner and fail the Python gate.
- [x] Small-call and large-throughput workloads are both represented.

**Verification:** Compile/run the benchmark at `-O3`, then validate its output.

**Dependencies:** Task 1.

**Estimated scope:** Medium, split between runner infrastructure and workloads.

## Task 3: Offline performance validator

**Description:** Compile/run the benchmark, capture reproducible host/toolchain
conditions, validate rows against the manifest, and write versioned JSON.

**Acceptance criteria:**

- [x] Missing/duplicate/malformed rows and hard-ceiling failures are rejected.
- [x] Same-run and prior-baseline ratios are calculated with advisory review
  status for noisy timing.
- [x] The tool uses only FPC and Python's standard library and works offline.

**Verification:** `python tools/test_performance_evidence.py` and a real
`python tools/check_performance_evidence.py --compiler fpc` run.

**Dependencies:** Tasks 1-2.

**Estimated scope:** Medium.

## Task 4: Profile-led optimisation decision

**Description:** Repeat representative hot-path samples and accept an internal
optimisation only if it gives a material reproducible benefit without changing
portable results or public interfaces.

**Acceptance criteria:**

- [x] Profiling commands, repetitions, results, and decision are documented.
- [x] Any changed algorithm has a failing regression/cross-path test first and
  keeps all portable correctness tests green.
- [x] If no candidate clears the evidence threshold, no speculative numerical
  source change is made.

**Verification:** Focused FPCUnit tests and repeated benchmark comparison.

**Dependencies:** Tasks 2-3.

**Estimated scope:** Small to medium.

## Task 5: Qualification and CI integration

**Description:** Make release qualification produce and validate performance
evidence while keeping wall-clock changes advisory on hosted runners.

**Acceptance criteria:**

- [x] Local qualification and the clean-archive workflows invoke the gate.
- [x] Performance JSON and logs are retained as qualification artifacts.
- [x] Tool unit tests run in ordinary CI.

**Verification:** Python tool tests, workflow/documentation checks, and a
qualification run with benchmarks enabled.

**Dependencies:** Tasks 1-4.

**Estimated scope:** Medium.

## Task 6: Documentation and release identity

**Description:** Publish the performance evidence guide and consistently
advance release metadata and documentation to 1.9.5.

**Acceptance criteria:**

- [x] Every performance/memory claim links to a checked row and conditions.
- [x] README, benchmark/releasing guidance, capability inventory, changelog,
  docs index, release/PR/qualification notes, packages, workflows, and version
  manifest agree on 1.9.5.
- [x] Roadmap records 1.9.5 as previous and 1.9.6 as next.

**Verification:** All documentation tests, site/offline build checks, API
snapshot checks, and release-state tests.

**Dependencies:** Tasks 1-5.

**Estimated scope:** Large; land as focused metadata/documentation increments.

## Task 7: Full qualification and review

**Description:** Run all supported local gates and review the complete diff for
correctness, simplicity, architecture, security, and performance.

**Acceptance criteria:**

- [x] Normal, optimized, checked/heap, examples, documentation, package, and
  performance gates pass.
- [x] No public-interface snapshot changes or unexplained material regressions
  remain.
- [x] All critical/required review findings are resolved.

**Verification:** `python tools/qualify_release.py --release 1.9.5 --compiler
fpc --lazbuild lazbuild` plus `git diff --check` and final diff review.

**Dependencies:** Tasks 1-6.

**Estimated scope:** Medium.
