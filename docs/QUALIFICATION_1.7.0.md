# mathlib-fp 1.7.0 qualification

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Interpolation workflow | Barycentric, rational, PCHIP/Akima, grid, and scattered tests plus example 17 |
| Fitting workflow | Typed rank-revealing QR polynomial fit and bounded LM reference tests |
| Integration workflow | Gauss-Kronrod sine and transformed Gaussian improper references |
| Root workflow | Existing bracketed scalar suite plus diagnostic vector Newton reference |
| ODE workflow | Dormand-Prince exponential solution, dense output, and localised event |
| LP/QP workflow | Existing simplex optimal/unbounded tests and constrained convex QP reference |
| Cone workflow | Feasible-start unit second-order-cone optimum and feasibility residual |
| Nonlinear optimisation | Existing L-BFGS/Nelder-Mead/penalty suite plus reentrant adapter change |
| Termination distinctions | Shared status names and convergence/acceptable/stagnation/breakdown/infeasible/unbounded/limit/cancel result paths |
| Derivative agreement | Analytic, central numerical, and dual-number AD smooth reference; deliberate bad-gradient detection |
| Callback reentrancy | No mutable callback/model state in 1.7 units; legacy penalty/maximize globals removed |
| Selection guidance | `NumericalModelling.md` and `ConvexOptimization.md` compare assumptions and limitations |

## Local release qualification

The release gate runs:

```text
lazbuild --build-mode=Release tests/TestRunner.lpi
tests/TestRunner.exe --all --format=plain
lazbuild --build-mode=Debug tests/TestRunner.lpi
tests/TestRunner.exe --all --format=plain
build-examples.ps1
lazbuild --build-all packages/lazarus/mathlib_fp.lpk
python tools/check_docs.py
python tools/build_docs.py
```

Normal, optimised, runtime-checked/heap-traced, package, example, documentation,
and public-API paths must all pass before the milestone is marked complete.
CI retains Linux, Win64, and optimised Win32 coverage through the existing
workflow.

### Observed local results

| Path | Result |
| --- | --- |
| Win64 release (`-O3`) | 864 tests, 0 errors, 0 failures |
| Win64 debug (`-Ci -Cr -Co -Ct -gh`) | 864 tests, 0 errors, 0 failures, 0 unfreed blocks |
| Win32 i386 optimised (`-O3`) | 864 tests, 0 errors, 0 failures |
| Examples | 19 compiled; examples 17 and 18 ran end to end |
| Lazarus package, Win64 | all package units compiled |
| Package umbrella, Win32 i386 | all package units compiled |
| Documentation check | 42 pages, 19 indexed examples, 104 public symbols |
| Documentation build | 42 HTML pages and a populated search index |

## Numerical budgets

| Workflow | Published check |
| --- | --- |
| Barycentric quadratic | absolute error <= 1e-12 |
| Adaptive sine integral | absolute error <= 1e-10 |
| Improper Gaussian integral | absolute error <= 2e-7 |
| Linear fit parameters | absolute error <= 1e-10 |
| Nonlinear fit parameters | absolute error <= 1e-6 |
| Vector equation solution | absolute error <= 1e-9 |
| ODE dense output | absolute error <= 2e-6 |
| ODE event time | absolute error <= 2e-5 |
| Convex QP variables | absolute error <= 2e-5, feasibility <= configured tolerance |
| Unit SOCP optimum | absolute error <= 2e-3, no positive cone violation |

These are precision-appropriate regression budgets for the named fixtures, not
global guarantees.

## Dependency and scope audit

All new stable implementation units are Object Pascal source. They use only the
RTL, MathBase, and the repository's typed dense units. They do not load a DLL,
invoke an external program, access a service/network, or require a licence key.

No 1.8.0 persistence/interchange, data-analysis, tooling, large-data streaming,
parallel/SIMD, or performance-maturity feature is included.
