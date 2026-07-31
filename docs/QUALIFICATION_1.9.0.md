# mathlib-fp 1.9.0 qualification

## Completion-gate evidence

| Gate | Reproducible evidence |
| --- | --- |
| End-to-end workflow | Example 22: 5x5 Poisson triplets → CSR → Matrix Market → CSR → IC(0) → CG; 13 stored entries, one iteration, three products, confirmed true residual, endpoint solution 1 |
| Four-scalar storage/operators | `TestSparseMatrices`, `TestIterativeSolvers`, `TestStructuredSolvers`, and `TestPartialEigensystems`; all five iterative methods, operator adjoints, preconditioner families, and direct-factor families execute through named scalar facades |
| Complete outcomes | Iterative success/limit/cancel/breakdown; invalid preconditioner structure; band/sparse singularity; spectral validation |
| No dense-scale allocation | 20,000-dimensional matrix-free test; 100,000-entry sparse and 200,000-dimensional matrix-free benchmark rows below |
| Reuse/aliasing/mutation/failure atomicity | sequential/concurrent factor and preconditioner reuse, exact in-place operation, partial-view rejection, source snapshots, atomic validation/construction failures, and atomic workspace ownership/recovery |
| Interchange | text real/complex and four-scalar binary round trips; malformed index, duplicate, explicit zero, version, kind, checksum, truncation, nonzero-limit, and per-axis dimension-limit rejection |
| Migration/API freeze | example 23 runs dense/sparse solves, fitting, interpolation, optimization, DSP, and statistics; schema-2 snapshot distinguishes owners/overloads and the generated reference contains every exact declaration |
| Documentation audit | `check_doc_examples.py` inventories 225 Pascal fences and compiles/runs all 15 self-contained programs; every 1.9 release-facing Pascal fence must be self-contained; 59 pages, capability data, release notes, examples, and declarations reconcile |

## Numerical contracts exercised

| Workflow | Published check |
| --- | --- |
| CSR/CSC/triplets | strict canonical ordering, deterministic duplicate sum, zero policy, shape/index/finite validation, transpose/conjugate transpose and arithmetic |
| Structured storage | compact diagonal/tridiagonal/band products agree with dense values |
| Operator adapters | sparse/structured/dense/matrix-free ordinary and adjoint products agree with direct references |
| Preconditioners | diagonal/IC(0)/ILU(0) application plus missing diagonal, non-Hermitian, and pivot failures |
| Krylov solvers | all five methods execute for all four scalars; square true-residual and inconsistent-LSQR normal-residual convergence; refresh/progress, result statuses, aliasing, atomic failure, and workspace reuse |
| Direct factors | pivoted tridiagonal multiple RHS; no-pivot band singularity; sparse natural-order fill/pivot; real/complex single/double |
| Partial spectra | deterministic selected pairs and `||A*v-lambda*v||_2`; general Arnoldi and Hermitian Lanczos; target/shape rejection |
| Interchange | canonical round trip plus corrupt/malformed/nonzero-limit/dimension-limit rejection before result publication |

Fixture tolerances are precision- and algorithm-specific checks in the linked
test source, not universal worst-case guarantees.

## Large sparse and matrix-free evidence

Observed locally with FPC 3.2.2, Win64 x86-64, `-B -O3 -FcUTF8`, on
2026-07-31. `GetTickCount64` timing and `GetHeapStatus.TotalAllocated` sampling
are machine-specific. Logical slots are derived from public matrix,
preconditioner, input/output, and prepared workspace capacities. They exclude
small object/interface headers.

| Case | Shape / retained matrix data | Initial / 20 warmed solves | Iterations / products per solve | Final true residual | Warmed peak / retained heap delta | Approximate retained storage |
| --- | --- | ---: | --- | ---: | ---: | --- |
| CSR diagonal + exact sparse diagonal preconditioner + CG | 100,000²; 100,000 nonzeros | 125 ms / 2,109 ms | 1 / 3 | `0.0` confirmed | 0 / 0 bytes | 3,300,041 scalar/index slots; initial sampled heap increase 26,404,352 bytes |
| Matrix-free scaled identity + CG | 200,000²; 0 retained operator values | 172 ms / 3,484 ms | 1 / 3 (action count 63 including warm-up and repeats) | `0.0` confirmed | 0 / 0 bytes | 5,800,041 scalar slots; initial sampled heap increase 46,404,000 bytes |

Both report `dense_shape_elements_allocated=0`. Their storage is linear in
vector length/nonzeros; a full dense binary64 allocation would require 80 GB
and 320 GB respectively. The stable regression suite separately uses
dimension 20,000, where a dense matrix alone would require 3.2 GB, and passes
within linear workspace storage.

The warmed measurements use `GetHeapStatus.TotalAllocated`, sampled by the
iteration monitor and after every solve from a post-warm-up baseline. The
benchmark fails above 65,536 bytes. This catches retained or vector-scale
transient growth; it is not a count of every short-lived RTL allocation
between sample points.

Reproduce:

```text
fpc -B -O3 -FcUTF8 -Fusrc -FUbenchmarks/lib/qualification \
  -FEbenchmarks/lib/qualification benchmarks/BenchmarkRunner.lpr
benchmarks/lib/qualification/BenchmarkRunner.exe
```

The benchmark reports measurements; CI compiles it for bit-rot protection and
does not enforce machine timing thresholds.

## Release verification commands

```text
fpc -B -FcUTF8 -Fusrc -FUtests/lib/normal -FEtests/lib/normal tests/TestRunner.lpr
tests/lib/normal/TestRunner.exe -a --format=plain
fpc -B -O3 -FcUTF8 -Fusrc -FUtests/lib/release -FEtests/lib/release tests/TestRunner.lpr
tests/lib/release/TestRunner.exe -a --format=plain
fpc -B -Ci -Cr -Co -Ct -gl -gh -FcUTF8 -Fusrc -FUtests/lib/checked -FEtests/lib/checked tests/TestRunner.lpr
tests/lib/checked/TestRunner.exe -a --format=plain
build-examples.ps1
lazbuild --build-all packages/lazarus/mathlib_fp.lpk
python tools/test_api_snapshot.py
python tools/test_doc_examples.py
python tools/check_docs.py
python tools/check_doc_examples.py
python tools/build_docs.py --output build-temp/docs-site/1.9.0
```

The final observed matrix is recorded after the commands complete:

| Path | Result |
| --- | --- |
| Win64 normal | 930 tests, 0 errors, 0 failures |
| Win64 `-O3` | 930 tests, 0 errors, 0 failures |
| Win64 checked/heap-traced | 930 tests, 0 errors, 0 failures; 295,567 blocks allocated/freed and 0 unfreed |
| Win32 `-O2` | GitHub Actions gate configured; no Win32 compiler is installed in the local qualification environment |
| Linux x86-64 | GitHub Actions gate configured; no Linux FPC target is installed in the local qualification environment |
| Examples | 24 compiled and ran successfully on Win64 |
| Lazarus package | Win64 package 1.9 built successfully; Win32 package remains in the configured CI gate |
| Documentation/API snapshot | Static checks pass for 59 pages, 24 indexed examples, 281 required entry names, and 2,880 exact owner/signature-aware declaration rows; 15 self-contained Pascal fragments compile and run |
| Representative benchmark | Compiled and ran at `-O3`; large results above |
| Clean checksummed archive | 197 source files checksummed and extracted into an isolated directory; normal, `-O3`, checked/heap-traced, documentation, all examples, Win64 package, and benchmark gates repeated successfully |

The two cross-target rows remain mandatory remote release checks; they are
explicitly not represented as local successes.

## Dependency and remaining-gap audit

The new stable units use only repository code and Free Pascal RTL/FCL units.
They do not load third-party DLLs, invoke programs, contact a service/network,
require a licence key, or hide a dense/vendor fallback.

The stable boundary does not include distributed/out-of-core/GPU execution,
parallel/SIMD sparse kernels, fill-reducing sparse ordering, advanced sparse
direct methods, block/flexible Krylov or algebraic multigrid, LSQR
preconditioning, shift-invert/interior/generalized/Schur/polynomial spectral
families, or unrelated deferred DSP/statistics/state-space/ODE/optimisation
families. These exact gaps are machine-readable in `capabilities.json`.
