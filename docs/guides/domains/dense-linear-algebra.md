# Typed dense decompositions and solvers

Status: **stable in 1.6.0**. All implementations are native Object Pascal and
need no external numerical library. Storage, views, kernels, and conversion
rules remain documented in [Typed dense matrices](typed-dense-matrices.md).

## 60-second least-squares solve

```pascal
uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseDecompositions;

var
  A, B, X: IDenseDoubleMatrix;
  Info: TDenseSolveDiagnostics;
begin
  A := TDenseDoubleMatrix.FromValues(4, 2,
    [1.0, 1.0, 1.0, 2.0, 1.0, 3.0, 1.0, 4.0]);
  B := TDenseDoubleMatrix.FromValues(4, 1, [6.0, 5.0, 7.0, 10.0]);
  X := LeastSquares(A, B, Info);
  WriteLn('intercept=', X[0, 0]:0:3, ' slope=', X[1, 0]:0:3);
  WriteLn('residual=', Info.ResidualNorm:0:6);
end.
```

Expected output:

```text
intercept=3.500 slope=1.400
residual=2.049390
```

This fits a line without forming normal equations or an inverse. The complete
[solver-selection example](../../../examples/16_dense_solver_selection.pas) also
handles a rank-deficient calibration with SVD and interprets a covariance
eigensystem.

## Choose a dense solver

| Problem you have | Recommended entry point | Why | Important failure or diagnostic |
| --- | --- | --- | --- |
| General square `A*X=B` | `SolveWithInfo(A,B,Info)` or reusable `FactorLU(A)` | Partial pivoting; preserves the concise 1.5 path | Singular pivot raises; inspect `PivotRatio`, `IsIllConditioned`, and backward error |
| Symmetric/Hermitian positive-definite square system | `SolvePositiveDefinite` or reusable `FactorCholesky` | Uses structure and about half the factor work/storage of LU | Non-Hermitian or non-positive-definite input raises |
| Explicit lower/upper factor | `SolveTriangular` | Select lower/upper, unit/non-unit, ordinary/transpose/conjugate transpose | A numerically zero non-unit diagonal raises |
| Tall full-rank least squares | `LeastSquares` or reusable `FactorQR` | Householder QR; no normal equations | Rank deficiency raises on the unpivoted solve |
| Tall system whose rank is uncertain | `RankRevealingLeastSquares` or `FactorPivotedQR` | Column pivoting exposes numerical rank and a basic solution | Inspect permutation, rank, tolerance, and `IsRankDeficient` |
| Rank-deficient or underdetermined minimum-norm solve | `MinimumNormSolve` or reusable `FactorSVD` | Returns the Moore-Penrose minimum-norm solution at the selected rank | More expensive; rank depends on the documented singular-value tolerance |
| Every eigenpair of a real symmetric matrix | `FactorSymmetricEigen` | Deterministic full Jacobi eigensystem | Input must be symmetric and finite |
| Every eigenpair of a complex Hermitian matrix | `FactorHermitianEigen` | Deterministic full unitary Jacobi eigensystem | Diagonal must be real; input must be Hermitian and finite |

Do not choose SVD merely because it is the most general option. QR is the
predictable default for a full-rank tall least-squares problem. Choose CPQR
when rank must be diagnosed, and SVD when the solution must be minimum norm or
rank deficiency is part of the problem.

Sparse, iterative, matrix-free, nonsymmetric/generalized/partial eigen,
LDLT, update/downdate, public workspace, parallel/SIMD, GPU, and external
BLAS/LAPACK paths are unsupported in the typed 1.6 API. The compatibility
`IMatrix` methods do not make those typed families stable.

## Common contracts

All indices and shapes use zero-based `SizeInt`. Inputs must be finite.
Factorisation clones its source; later source mutation cannot alter the
factor. Accessors return copies, and solves never overwrite coefficients or
right-hand sides. A factor has no mutable last-result state, so concurrent
reads and solves are safe when callers do not concurrently mutate a shared
input matrix.

Convenience calls allocate and factor once. A reusable factor retains O(mn)
or O(n²) private storage and avoids repeated O(n³) work, but each solve returns
a newly allocated result. The 1.6 API has no destructive factorisation or
public workspace form.

Every decomposition supports matching `Single`, `Double`, `TSingleComplex`,
and `TComplex` paths wherever the mathematics applies. A typed factor never
converts through nested `Double` storage or `IMatrix`. Real symmetric
eigensystems apply to the real paths; Hermitian eigensystems apply to the
complex paths.

Invalid nil/shape/option/tolerance input, non-finite entries, singular factors,
invalid structure, and convergence failure raise `EDenseMatrixError` before a
result is returned. User tolerances must be finite and nonnegative; the default
is selected by a negative value and scales with precision, dimensions, and the
leading pivot/diagonal/singular value.

## Diagnostics

`TDenseSolveDiagnostics` contains:

```pascal
Method: string;
NumericalRank: SizeInt;
IsRankDeficient: Boolean;
Tolerance: Double;
ConditionIndicator: Double;
ResidualNorm: Double;
BackwardError: Double;
```

`ResidualNorm` is `||B-A*X||F`. `BackwardError` is the scale-aware normalized
quantity

`||B-A*X||F / (||A||F*||X||F + ||B||F)`.

`ConditionIndicator` is the smallest accepted to largest relevant pivot,
factor diagonal, or singular value. A smaller value warns of greater
sensitivity, but it is deliberately not presented as a formal reciprocal
condition-number estimate. No diagnostic forms an inverse.

LU, Cholesky, QR/CPQR, and SVD reusable factors expose
`SolveWithInfo`, `SolveLeastSquaresWithInfo`, or
`SolveMinimumNormWithInfo`. The matching methods without `WithInfo` return the
same solution while omitting residual calculation.

## Triangular solve reference

`TDenseTriangle` is `dtLower` or `dtUpper`; `TDenseDiagonal` is
`ddNonUnit` or `ddUnit`; `TDenseTranspose` is `dtNoTranspose`,
`dtTranspose`, or `dtConjugateTranspose`.

`SolveTriangular(A,B,Triangle,Transpose,Diagonal)` accepts square `n x n`
`A` and `n x r` `B`, including `n=0` or `r=0`. Entries outside the selected
triangle are ignored. Real transpose and conjugate transpose have the same
mathematics. Time is O(n²r); the result needs O(nr) additional storage.

## LU and Cholesky reference

The four LU handles are `IDenseSingleLU`, `IDenseDoubleLU`,
`IDenseSingleComplexLU`, and `IDenseComplexLU`. They expose `Size`, copied
`L`, `U`, and `Permutation`, `PivotRatio`, `ConditionIndicator`,
`IsIllConditioned`, `Solve`, and `SolveWithInfo`. The permutation convention
is `P*A=L*U`; `Permutation[i]` is the source row occupying factor row `i`.

The four Cholesky handles are `IDenseSingleCholesky`,
`IDenseDoubleCholesky`, `IDenseSingleComplexCholesky`, and
`IDenseComplexCholesky`. They expose `Size`, copied `L`,
`ConditionIndicator`, `Solve`, and `SolveWithInfo`. Real factors satisfy
`A=L*L^T`; complex factors satisfy `A=L*L^H`.

Factorisation is O(n³) time/O(n²) factor storage; a solve with `r`
right-hand sides is O(n²r).

## QR and rank-revealing QR reference

The handles are `IDenseSingleQR`, `IDenseDoubleQR`,
`IDenseSingleComplexQR`, and `IDenseComplexQR`. `FactorQR` and
`FactorPivotedQR` accept `m x n` with `m>=n`.

Compact `Q` has shape `m x n`; `R` is `n x n`. For CPQR,
`A*P=Q*R` and `Permutation[j]` is the source column now in factor column
`j`. `Q`, `R`, and `Permutation` accessors return copies. Individual
Householder column signs/phases are unspecified; reconstruction and
orthogonality/unitarity are the contract.

The factor exposes `Rows`, `Cols`, `NumericalRank`, `Tolerance`,
`ConditionIndicator`, `IsColumnPivoted`, `SolveLeastSquares`, and
`SolveLeastSquaresWithInfo`. CPQR's rank-deficient solve is a deterministic
basic solution, not a minimum-norm promise. Factorisation is O(mn²); compact
factor/result storage is O(mn+n²).

The implementation is Householder QR, not classical Gram-Schmidt. CPQR chooses
the largest remaining trailing column norm deterministically. See Golub and
Van Loan, *Matrix Computations*, 4th ed., sections 5.2 and 5.4.

## SVD and minimum-norm reference

The handles are `IDenseSingleSVD`, `IDenseDoubleSVD`,
`IDenseSingleComplexSVD`, and `IDenseComplexSVD`. `FactorSVD` accepts tall,
square, wide, singleton, and empty matrices. With `p=min(m,n)`, `U` is
`m x p`, `SingularValues` has length `p`, and `V` is `n x p`:

`A=U*diag(SingularValues)*V^H`.

Singular values are nonnegative and descending. Singular-vector signs/phases
and bases inside repeated singular subspaces are unspecified. The factor
exposes rank, tolerance, condition indicator, convergence sweep count,
`SolveMinimumNorm`, and `SolveMinimumNormWithInfo`.

The deterministic one-sided Jacobi algorithm operates directly in the declared
scalar type. Its leading cost is O(sweeps*m*n²), with O(mn+n²) private
working storage during factorisation. See Drmač and Veselić, “New fast and
accurate Jacobi SVD algorithm. I,” *SIAM J. Matrix Anal. Appl.* 29(4), 2008.

## Symmetric and Hermitian eigensystem reference

`FactorSymmetricEigen` returns `IDenseSingleSymmetricEigen` or
`IDenseDoubleSymmetricEigen`. `FactorHermitianEigen` returns
`IDenseSingleComplexHermitianEigen` or
`IDenseComplexHermitianEigen`.

Each factor exposes `Size`, copied ascending `Eigenvalues`, copied normalized
column `Eigenvectors`, `Sweeps`, and `Converged`. Every returned factor has
`Converged=True`; failure within the sweep limit raises instead of returning a
partial result. Vector signs/phases and bases within repeated or clustered
eigenspaces are unspecified. Judge results by unitary/orthogonal structure and
`A*v=lambda*v`.

The deterministic cyclic Jacobi method costs O(sweeps*n³) and uses O(n²)
factor/working storage. See Demmel, *Applied Numerical Linear Algebra*,
section 5.3.

## Empty, non-finite, and degenerate behavior

- `0 x 0` square, QR, SVD, and eigensystem factors are valid.
- Zero right-hand-side columns produce correctly shaped empty results.
- Rank-zero matrices are valid CPQR/SVD factors; unpivoted QR solve rejects
  them, while SVD returns the zero minimum-norm solution.
- Repeated and clustered eigenvalues may rotate their eigenvector basis.
- NaN and infinity are rejected in every coefficient and right-hand side.
- Symmetry/Hermitian and rank decisions are relative to matrix scale and
  scalar precision; definiteness has its own Cholesky threshold.

The full ownership, tolerance, pivot, shape, convergence, compatibility, and
algorithm-provenance decisions are fixed in the
[1.6 design record](../../design/typed-dense-1.6.md).
