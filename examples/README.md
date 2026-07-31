# mathlib-fp examples

These runnable programs now cover every documented mathlib-fp domain. They are
walkthroughs of representative workflows, not an exhaustive listing of every
public method; the linked domain guides are the complete API reference.

New to the library? Start with
[`00_getting_started.pas`](00_getting_started.pas), then choose the workflow
closest to your project.

| Example | Domain | What it introduces |
| --- | --- | --- |
| `00_getting_started.pas` | MathBase | Setup, shared arrays, constants, precision, and trigonometry |
| `01_stats_basics.pas` | StatsLib | Descriptive statistics, correlation, and bootstrap intervals |
| `02_hypothesis_test.pas` | StatsLib | Hypothesis tests and interpretation |
| `03_matrix_operations.pas` | AlgebraLib | Matrices, arithmetic, and decompositions |
| `04_finance_npv_irr.pas` | FinanceLib | Cash flows, NPV, and IRR |
| `05_unit_conversion.pas` | EngineeringLib | Type-safe physical unit conversions |
| `06_fluid_dynamics.pas` | EngineeringLib | Pipe flow, Bernoulli, head loss, and aerodynamics |
| `07_probability.pas` | ProbabilityLib | Common continuous and discrete distributions |
| `08_combinatorics.pas` | CombinatoricsLib | Counting, sequences, permutations, and number theory |
| `09_optimization.pas` | OptimizationLib | Scalar, multivariate, constrained, and linear optimisation |
| `10_timeseries.pas` | TimeSeriesLib | Smoothing, decomposition, forecasting, and anomalies |
| `11_machinelearning.pas` | MLLib | Preprocessing, models, clustering, PCA, and metrics |
| `12_geometry.pas` | GeometryLib | Vector arithmetic and normalization, 2-D/3-D geometry, intersections, hulls, and transforms |
| `13_numerical_methods.pas` | NumericsLib | Roots, integration, ODEs, interpolation, and errors |
| `14_complex_vectors.pas` | MathBase / AlgebraLib / EngineeringLib | Complex inverse functions, elementwise and reusable-buffer vector kernels, Hermitian dot products, and complex FFT round trips |
| `15_typed_dense_solve.pas` | AlgebraLib | Infer item prices from receipt totals with a typed direct solve, then price a new order |
| `16_dense_solver_selection.pas` | AlgebraLib | Choose QR, SVD minimum norm, and a symmetric eigensystem for realistic calibration tasks |
| `17_numerical_modelling.pas` | NumericsLib | Monotone interpolation, noisy/weighted/rank-deficient and badly-scaled bounded fitting, adaptive vector ODEs, and event diagnostics |
| `18_convex_optimization.pas` | OptimizationLib | Dense convex QP and second-order-cone models with feasibility and termination diagnostics |
| `19_applied_data_pipeline.pas` | DSP / StatsLib / NumericsLib / MLLib / TimeSeriesLib | Reuse shared containers across spectral analysis, streaming statistics, fitting, PCA, seeded clustering, and scalar Kalman filtering |
| `20_interchange_replay.pas` | MathBase / AlgebraLib | Round-trip a typed dense matrix and replay an explicitly saved local random-generator state |
| `21_release_1_8_workflows.pas` | DSP / StatsLib / MLLib / TimeSeriesLib / InterchangeLib | Block convolution, paired distribution APIs, leakage-safe preprocessing, seeded forests, multivariate Kalman filtering, model persistence, and bounded expressions |
| `22_sparse_end_to_end.pas` | AlgebraLib / MathBase | Assemble canonical sparse storage, round-trip Matrix Market, build IC(0), solve without densification, and interpret residual diagnostics |
| `23_api_migration_preview.pas` | Cross-domain migration | Run and verify typed dense and sparse solves, fitting, interpolation, optimisation, DSP, and statistics while preserving explicit compatibility paths |

## Build and run

From the `examples` directory:

```bash
mkdir -p lib
fpc -Fu../src -FUlib 00_getting_started.pas
./00_getting_started
```

On Windows, run `00_getting_started.exe`. In Lazarus, add `../src` under
**Project Options -> Compiler Options -> Paths -> Other Unit Files**, or install
the package at
[`packages/lazarus/mathlib_fp.lpk`](../packages/lazarus/mathlib_fp.lpk).

Generated unit files go into `lib/` because of `-FUlib`. Keeping compiler output
there makes the example directory easy to browse and clean.

### Compile every example

From the repository root, use the script for your shell. Both scripts compile
all `.pas` files into `example-bin/` and keep generated units in
`example-bin/units/`:

```bash
sh ./build-examples.sh
```

```powershell
.\build-examples.ps1
```

Set the `FPC` environment variable for the shell script, or pass
`-Compiler <path>` to the PowerShell script, when `fpc` is not on `PATH`.

## Suggested learning path

1. Run `00_getting_started.pas` to verify installation and learn the common
   types used across domains.
2. Read and modify one domain example. Changing its literal input values is a
   quick way to learn the API.
3. Open the corresponding guide in [`../docs`](../docs/index.md) for complete
   signatures, validation rules, and exception contracts.
