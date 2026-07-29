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
| Interpolation and approximation | Stable | Double real | Dense RBF/thin-plate methods target small data sets; knot-domain evaluation clamps |
| Numerical/automatic differentiation | Stable | Double real and forward dual | Forward mode only; explicit dual elementary-function catalogue |
| Adaptive integration, fitting, vector equations, and ODEs | Stable | Double real | ODE path is non-stiff; QMC error is a scale estimate |
| Dense convex QP and SOCP | Stable | Double real | Dense continuous models; SOCP needs a strictly feasible start |
| Shared iteration diagnostics | Stable | Result metadata | Algorithms expose only statuses applicable to their model |
| Explicit local random state | Stable | UInt64 state; single/double output | Reproducible simulation stream, not cryptographic; mutable instances require caller synchronization |
| Online and mergeable statistics | Stable | Double real | Constant retained state; moments through variance only |
| Applied DSP | Stable | Single/double real/complex | Arbitrary-length and 2-D transforms, convolution, spectra, and bounded FIR/biquad state; advanced design and wavelets remain open |
| Typed data analysis | Stable | Double real dense | PCA, seeded k-means++, splits, binary LDA, and exact low-dimensional KD tree; no forests/GLM/survival |
| Scalar linear state space | Stable | Double real | Scalar linear-Gaussian Kalman baseline only |
| Numerical interchange | Stable | Double real/complex and random state | Versioned little-endian binary plus invariant/delimited/Matrix Market subsets; no model/decomposition persistence |
| Serial blocked dense multiplication | Stable | Single/double real/complex | Portable kernel is the oracle; deterministic serial dispatch only |
| Legacy `IMatrix` API | Stable compatibility | Double real | Nested storage and `Integer` dimensions |
| Error/gamma/beta functions | Stable | Double real | Domains and budgets are documented in MathBase |
| Bessel, elliptic, exponential-integral families | Unsupported | — | Visible roadmap gap; no stable public implementation |
| Sparse typed storage and solvers | Unsupported | — | Deferred beyond the 1.6 dense milestone |
| Iterative and matrix-free typed solvers | Unsupported | — | CG/MINRES/GMRES/BiCGSTAB/LSQR, preconditioners, and operators are deferred |
| Advanced spectral families | Unsupported | — | Nonsymmetric/generalized/partial/Schur families are deferred |
| Advanced DSP design and wavelets | Unsupported | — | Equiripple and Chebyshev/elliptic/Bessel design, wavelets, and packets remain open |
| Expanded statistics and data science | Unsupported | — | GLMs, survival/factor analysis, robust covariance, and forests remain open |
| Model/expression persistence | Unsupported | — | No stable safe expression language or model/decomposition serialization |
| Parallel/SIMD dispatch | Unsupported | — | No stable thread-pool or vector-intrinsic API |

Unsupported entries are not counted in the 1.8.0 completeness claim. The
[dense solver-selection guide](DenseLinearAlgebra.md#choose-a-dense-solver)
and [applied numerics guide](AppliedNumerics.md) name the stable boundaries,
common workflows, resource bounds, and deferred families.
