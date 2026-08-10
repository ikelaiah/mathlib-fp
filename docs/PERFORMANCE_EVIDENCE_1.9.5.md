# mathlib-fp 1.9.5 performance evidence

This report maps every v1.9.5 performance and memory statement to a canonical
benchmark row. The machine-readable contract is
[`performance-evidence-1.9.5.json`](performance-evidence-1.9.5.json); the
validator compiles the runner with `-B -O3 -FcUTF8`, captures host and compiler
metadata, checks exact gates, and writes a versioned result artifact.

## Evidence contract

Each `PERF|...` row records its domain, scale, scalar kind, shape, cold time,
warmed aggregate time and repetition count, allocation metric, retained bytes,
logical working elements, dense-shape elements, checksum, tolerance, and setup.
Cold time is the first operation after deterministic fixture construction.
Warmed time follows an unmeasured warm-up and uses prepared inputs or workspace
as named by the row.

The following are hard failures: missing or duplicate rows, incorrect metadata,
checksum drift beyond tolerance, allocation or retained-memory ceilings,
logical working-storage ceilings, and any sparse/matrix-free dense-shape
allocation. Timing ratios are advisory. A ratio outside its review band makes
the result `review`; it does not turn a variable hosted runner into a false
precision gate.

## Checked rows and claims

| Row | Scale and scalar | Checked claim |
| --- | --- | --- |
| `dense-gemm-small-portable` | 16×16×16, `Double` | Prepared portable `Into` overhead; zero result allocations and retained bytes. |
| `dense-gemm-large-portable` | 127×129×65, `Double` | Portable dense reference with bounded logical working storage. |
| `dense-gemm-large-auto` | 127×129×65, `Double` | Automatic dispatch, checked against the portable row in the same run. |
| `sparse-cg-large` | 100,000×100,000 CSR, 100,000 nonzeros, `Double` | Prepared repeated solve retains linear workspace and exactly zero dense-shape elements. |
| `iterative-cg-large` | dimension 200,000, matrix-free, `Double` | Prepared repeated solve retains linear workspace and exactly zero dense-shape elements. |
| `dsp-convolution-small-direct` | lengths 8 and 3, `Double` | Small allocating direct-convolution overhead and checksum. |
| `dsp-fft-large-baseline` | 65,536 complex values, `Double` components | Existing native complex radix-2 baseline. |
| `dsp-fft-large-candidate` | 65,536 complex values, `Double` components | Public applied transform, checked against the baseline in the same run. |
| `modelling-integral-small` | scalar interval, `Double` | Adaptive integration setup-sensitive path at documented default tolerances. |
| `modelling-qmc-large` | 2-D, 100,000 samples, `Double` | Seeded Halton quasi-Monte Carlo throughput with constant-dimensional workspace. |
| `statistics-online-small` | 64 values, `Double` | Fresh streaming-statistics record overhead and six-scalar state. |
| `statistics-online-large` | 2,000,000 values, `Double` | Streaming throughput with the same six-scalar state. |
| `data-analysis-pca-small` | 32×4, 2 components, `Double` | Setup-sensitive allocating PCA and bounded retained output. |
| `data-analysis-pca-large` | 1024×8, 4 components, `Double` | Larger allocating PCA throughput and bounded storage. |

The exact fixture, checksum, tolerance, ceiling, timing semantics, and
claim identifier for each row live beside it in the machine-readable contract.

## Profile-led DSP change

The host-matched 1.9.4 observation records `dsp-fft-large-candidate` at
78.2 ms per prepared call. Inspection located per-butterfly trigonometric
evaluation in the applied radix-2 kernel. Reusing the already tested native
Pascal radix-2 implementation measured 9.4 ms per call in final qualification;
the same run measured `dsp-fft-large-baseline` at 9.2 ms. The checked
candidate/prior ratio was approximately 0.120 and the same-run ratio was 1.022,
both within their advisory bands. These are observations on one Windows
x86-64 machine with FPC 3.2.2, not portable throughput promises.

The change does not alter a public declaration. A new reference and round-trip
test covers the public power-of-two path, the complete FPCUnit suite remains
green, and the `SizeInt` fallback retains an explicit portable twiddle
recurrence for array sizes outside the reused kernel's `Integer` range.

## Reproduction

From the repository root:

```text
python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc \
  --work-dir build-temp/performance
```

The result is `build-temp/performance/performance-results.json`. Compare
timings only when CPU, OS, compiler version, flags, scalar kind, dimensions,
tolerance, setup, and output validation match. Allocation ceilings are logical
counts or explicitly labelled sampled live-heap deltas; they are not claims
about every short-lived RTL allocation event.

## Limits

The suite is representative, not an exhaustive performance model. Timer
resolution can report zero for individual small cold calls; warmed repetitions
remain available. No external library is needed or used. Linux and Windows
clean-archive qualification for the exact candidate commit remains mandatory
before tagging.
