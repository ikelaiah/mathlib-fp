# mathlib-fp 1.9.8 representative workflow qualification

Version 1.9.8 validates that separately mature domains feel like one library in
applications not written to mirror the internal architecture. This guide
documents the three qualified workflows, the machine-readable contract, and the
automated clean-archive journey that reproduces them.

## The three workflows

### 1. Sensor pipeline — `examples/24_sensor_pipeline.pas`

Domains: MathBase, EngineeringLib, StatsLib, TimeSeriesLib.

The program loads a bundled 48-reading CSV (`examples/data/sensor_readings.csv`),
validates every reading for finite, in-range values, smooths with a windowed-sinc
FIR and estimates a Welch spectrum, summarises with streaming and descriptive
statistics, flags an injected anomaly and fits a linear trend with time-series
analysis, rejects a non-finite reading through its validation path, round-trips
the series through versioned binary interchange, and writes
`workflow-exports/sensor_report.txt`.

- Indexing: zero-based dynamic arrays throughout; the CSV has one reading per
  line and blank lines are ignored.
- Ownership: `TDoubleArray` results are value-owned copies returned by value.
- Defaults: `TOnlineStatistics.Create` rejects non-finite input by default.
- Limitations: the FIR filter lengthens the output by its impulse response;
  statistics over the smoothed series therefore span that extended length.

### 2. Numerical modelling and optimisation —
`examples/25_numerical_modelling_optimisation.pas`

Domains: MathBase, NumericsLib, OptimizationLib.

The program validates embedded modelling data, recovers an exact linear fit and
a monotone PCHIP interpolant, solves the bracketed root sqrt(2), minimises a
smooth objective with unconstrained conjugate gradient and a bounded L-BFGS
solve, and then exercises two diagnostics: a root solve starved of iterations
reports non-convergence (`iteration limit`), and a negative-degree fit request
raises `EModellingError`. The fitted parameters are round-tripped through binary
interchange and the report is written to `workflow-exports/model_report.txt`.

- Defaults: `TOptimizationOptions.Defaults` supplies tolerances; the example
  overrides `MaxIterations` and bounds explicitly.
- Cancellation: not exercised; these solvers terminate on tolerances or
  iteration limits, which the diagnostics make visible.
- Limitations: `BisectionResult` raises `EInvalidArgument` when a bracket has
  no sign change; the example demonstrates the iteration-limit path instead.

### 3. Reproducible probability/finance analysis —
`examples/26_probability_finance.pas`

Domains: MathBase, ProbabilityLib, StatsLib, FinanceLib.

The program seeds a local `TLocalRandom` (xoshiro256**) and simulates 64
market/asset returns, estimates the asset-return distribution, runs a one-sample
t-test and a CAPM-style OLS regression, computes NPV/IRR and a project decision,
rejects an invalid standard deviation with `EProbabilityError`, round-trips the
cash flows through binary interchange, and writes an interpretation to
`workflow-exports/finance_report.txt`.

- RNG ownership: `TLocalRandom` is caller-owned and never touches the RTL global
  generator; the fixed seed makes the run reproducible.
- Limitations: seeded results are reproducible within a single build/platform;
  cross-platform floating-point rounding is not claimed to be bitwise identical.

## Machine-readable contract

[`workflow-qualification-1.9.8.json`](workflow-qualification-1.9.8.json) is the
stable, host-independent manifest. Each workflow records its source, success
marker, exercised domains, bundled fixtures (with a size bound), required
diagnostic output, named numerical bounds (parsed as `line_prefix` plus a
`minimum`/`maximum` range), and exported artifact paths.

`tools/workflow_qualification.py` validates the manifest and rejects missing,
malformed, duplicate, unsafe, or absolute paths; missing fixtures; oversized
fixtures; missing diagnostic paths; and invalid numerical expectations. It is
covered by `tools/test_workflow_qualification.py`.

## The automated clean-archive journey

`tools/check_workflow_qualification.py` performs, for each workflow:

1. compile with FPC 3.2.2 using only `src/` on the unit path;
2. copy bundled fixtures into an isolated work directory (sources are never
   mutated);
3. run the workflow twice from that directory;
4. verify the success marker, every diagnostic, and every numerical bound;
5. verify exported artifacts exist, are non-empty, and are byte-identical across
   the two runs.

The recorded result JSON names the exact `platform` and `compiler_version` that
ran; it makes no claim about any other platform. The checker uses only Python's
standard library and needs no network access.

## Evidence

Generated qualification output is written to
`build-temp/workflow-qualification/results.json` (or the path given by
`--result`). Local Windows x86-64 FPC 3.2.2 evidence is summarised in
[QUALIFICATION_1.9.8.md](QUALIFICATION_1.9.8.md). Exact Linux and Windows
clean-archive candidate artifacts are produced by CI and are not pre-recorded
in the repository.
