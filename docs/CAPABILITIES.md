# Capability inventory

The machine-readable source for this page is
[`capabilities.json`](capabilities.json).

| Family | Maturity | Scalar paths | Important limitations |
| --- | --- | --- | --- |
| Complex scalar arithmetic | Stable | Single and double complex; elementary principal functions are double only | Single complex exposes the arithmetic needed by typed kernels, not the double elementary-function catalogue |
| Array vector kernels | Stable | Double real and complex | The 1.3 array facade is retained; typed matrices provide the new single paths |
| Typed dense storage and views | Stable | Single/double real/complex | Dense row-major only; no broadcasting |
| Small 2x2 value arithmetic | Stable | Single/double real/complex | 2x2 only; batch iteration is explicit |
| Typed dense arithmetic | Stable | Single/double real/complex | Portable O(mkn) product; no SIMD/parallel dispatch |
| Pivoted LU and direct solve | Stable | Single/double real/complex | Square systems only; no least squares |
| Cholesky solve | Stable | Single/double real/complex | Positive-definite symmetric/Hermitian matrices only |
| Triangular solve variants | Stable | Single/double real/complex | Dense lower/upper, unit/non-unit, ordinary/transposed/conjugate-transposed |
| Householder QR least squares | Stable | Single/double real/complex | Tall/square, full-rank solve |
| Column-pivoted QR and rank-revealing solve | Stable | Single/double real/complex | Basic rank-deficient solution is not minimum norm |
| Compact SVD and minimum-norm solve | Stable | Single/double real/complex | Full compact deterministic Jacobi path; no truncated/randomized SVD |
| Full symmetric/Hermitian eigensystem | Stable | Single/double real/complex as applicable | No nonsymmetric, generalized, or partial eigensystems |
| Typed CSR/CSC and compact structured storage | Stable | Single/double real/complex | Immutable canonical storage; products may create mathematical fill; no hidden densification |
| Typed stored/matrix-free operators and preconditioners | Stable | Single/double real/complex | Four-scalar ordinary/adjoint and identity/diagonal/IC(0)/ILU(0) execution; caller supplies mathematical symmetry/definiteness |
| CG, MINRES, restarted GMRES, BiCGSTAB, and LSQR | Stable | Single/double real/complex | Every method executes for every scalar; square methods stop on true residual and LSQR on normal residual; LSQR is unpreconditioned in 1.9 |
| Reusable tridiagonal/band/sparse LU factors | Stable | Single/double real/complex | General band has no pivoting; sparse baseline is natural order and fill dependent |
| Restarted partial Lanczos/Arnoldi | Stable | Single/double real/complex | Largest magnitude only; no shift-invert/interior/generalized/Schur path |
| Interpolation and approximation | Stable | Double real | Includes natural/clamped/not-a-knot cubic splines; dense scattered methods target small data sets |
| Numerical/automatic differentiation | Stable | Double real/complex callback and forward dual | Forward mode only; complex-step requires an analytic callback |
| Adaptive integration, fitting, vector equations, polynomial roots, and ODEs | Stable | Double real plus complex root result | ODE path is explicit non-stiff; sampling error values are estimates |
| Diagnostic nonlinear and linear optimisation | Stable | Double real | Detailed bounds/status/best iterate, warm starts, constrained/Pareto baselines, and two-phase dense LP |
| Dense convex QP and SOCP | Stable | Double real | Dense continuous models; SOCP needs a strictly feasible start; general certificates are not claimed |
| Shared iteration diagnostics | Stable | Result metadata | Algorithms expose only statuses applicable to their model |
| Explicit local random state | Stable | UInt64 state; single/double output | Reproducible simulation stream, not cryptographic; mutable instances require caller synchronization |
| Online and mergeable statistics | Stable | Double real | Constant retained state; moments through variance only |
| Applied DSP | Stable | Single/double real/complex | Batch/arbitrary/2-D transforms, direct/FFT/overlap convolution, spectra, Haar, and bounded filter state |
| Statistical inference and regression | Stable | Double real | Paired distribution APIs, estimation/tests/corrections, SVD OLS, and binary logistic with identifiability status |
| Typed data analysis | Stable | Double real dense | PCA, seeded clustering/splits/forests, fitted standardization, binary LDA, and exact low-dimensional KD tree |
| Linear-Gaussian state space | Stable | Double real | Scalar and dense multivariate Kalman filtering/forecasting; no controls, missing observations, or smoothing |
| Numerical interchange and inspection | Stable | Single/double real/complex and random state | Coordinate double/complex Matrix Market and four-scalar sparse binary; independent nonzero/per-axis dimension caps |
| Selected model persistence | Stable | Double real | Versioned spline/FIR/standardizer/scalar-Kalman adapters; not arbitrary model graphs |
| Bounded mathematical expressions | Stable | Double scalar/vector/dense matrix | Explicit resource limits and immutable bindings; no assignment, loops, I/O, process, network, or callbacks |
| Serial blocked dense multiplication | Stable | Single/double real/complex | Portable kernel is the oracle; deterministic serial dispatch only |
| Legacy `IMatrix` API | Stable compatibility | Double real | Nested storage and `Integer` dimensions |
| Error/gamma/beta functions | Stable | Double real | Domains and budgets are documented in MathBase |
| Bessel, elliptic, exponential-integral families | Unsupported | — | Visible roadmap gap; no stable public implementation |
| Advanced sparse direct algorithms | Unsupported | — | No fill-reducing symbolic ordering, multifrontal/supernodal, distributed, out-of-core, or GPU path |
| Advanced iterative variants | Unsupported | — | No block/flexible Krylov, algebraic multigrid, or parallel/SIMD sparse dispatch |
| Remaining advanced spectral families | Unsupported | — | Full nonsymmetric, generalized, polynomial, Schur, shift-invert, and interior-target families remain deferred |
| Advanced DSP design and wavelets | Unsupported | — | Haar is stable; equiripple, advanced IIR families, broader wavelets, and packets remain conditional |
| Conditional statistics and data science | Unsupported | — | Survival/factor analysis, robust covariance, multinomial/count GLMs, boosting, and broader forecasting were not activated |
| General model/decomposition persistence | Unsupported | — | Selected adapters are stable; decomposition, forest, graph, and multivariate-state persistence remain open |
| Parallel/SIMD dispatch | Unsupported | — | No stable thread-pool or vector-intrinsic API |

Unsupported entries are not counted in the 1.9.3 completeness claim. The
[dense solver-selection guide](DenseLinearAlgebra.md#choose-a-dense-solver)
and [sparse solver-selection guide](SparseLinearAlgebra.md#choose-an-iterative-solver)
name the stable linear-algebra boundaries. The
[applied numerics guide](AppliedNumerics.md) covers the other mature workflows.
