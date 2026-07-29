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
| Legacy `IMatrix` API | Stable compatibility | Double real | Nested storage and `Integer` dimensions |
| Error/gamma/beta functions | Stable | Double real | Domains and budgets are documented in MathBase |
| Bessel, elliptic, exponential-integral families | Unsupported | — | Visible roadmap gap; no stable public implementation |
| Sparse typed storage and solvers | Unsupported | — | Deferred beyond the 1.6 dense milestone |
| Iterative and matrix-free typed solvers | Unsupported | — | CG/MINRES/GMRES/BiCGSTAB/LSQR, preconditioners, and operators are deferred |
| Advanced spectral families | Unsupported | — | Nonsymmetric/generalized/partial/Schur families are deferred |

Unsupported entries are not counted in the 1.7.0 completeness claim. The
[dense solver-selection guide](DenseLinearAlgebra.md#choose-a-dense-solver)
names the stable boundary and the deferred families.
