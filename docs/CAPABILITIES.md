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
| Legacy `IMatrix` API | Stable compatibility | Double real | Nested storage and `Integer` dimensions |
| Error/gamma/beta functions | Stable | Double real | Domains and budgets are documented in MathBase |
| Bessel, elliptic, exponential-integral families | Unsupported | — | Visible roadmap gap; no stable public implementation |
| Sparse typed storage and solvers | Unsupported | — | Planned after the 1.5 dense foundation |

Unsupported entries are not counted in the 1.5.0 completeness claim.
