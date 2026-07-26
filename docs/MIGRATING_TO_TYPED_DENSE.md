# Migrating to the typed dense API

Versions 1.5.0 and 1.6.0 do not remove or deprecate `IMatrix`, `TMatrixKit`,
`IVector`, or their methods. Migration is opt-in.

| Use case | Compatibility API | Typed allocating API | Repeated/high-performance form |
| --- | --- | --- | --- |
| Construct | `TMatrixKit.CreateFromArray` | `TDenseDoubleMatrix.FromValues` | `Zeros`, then checked writes |
| Multiply | `A.Multiply(B)` | `Multiply(A, B)` | `MultiplyInto(A, B, Destination)` |
| Solve | Previously required inverse multiplication or an iterative method | `Solve(A, B)` | `FactorLU(A).Solve(B)` |
| Positive-definite solve | `Cholesky` plus caller glue | `FactorCholesky(A).Solve(B)` | Reuse the factor |
| Tall least squares | Compatibility `QRDecomposition` plus caller glue | `LeastSquares(A,B,Info)` | `FactorQR(A).SolveLeastSquaresWithInfo(B,Info)` |
| Rank-revealing least squares | Compatibility rank/QR methods have different tolerances and result contracts | `RankRevealingLeastSquares(A,B,Info)` | Reuse `FactorPivotedQR(A)` |
| Pseudoinverse/minimum norm | Compatibility `PseudoInverse` materializes a matrix | `MinimumNormSolve(A,B,Info)` | Reuse `FactorSVD(A)` without forming the pseudoinverse |
| Full symmetric/Hermitian eigen | Compatibility `EigenDecomposition` is double-real and has legacy ordering/error behavior | `FactorSymmetricEigen` / `FactorHermitianEigen` | Reuse the immutable factor outputs |
| Submatrix | Copying `GetSubMatrix` | Mutable retained-owner `View` | Reuse the view handle |
| Compatibility bridge | Already `IMatrix` | `TDenseDoubleMatrix.FromIMatrix` | Keep data typed to avoid repeated copies |

Conversions between `IMatrix`/`TMatrixArray` and typed matrices are deep
copies. `FromVector` also copies an array into matrix-owned storage. `Clone`
copies; interface assignment and `View` alias.

The typed API uses `SizeInt` dimensions and zero-based indices. Existing
`IMatrix` dimensions remain `Integer`, so a conversion back to `IMatrix`
inherits that API's limit. Conversion never hides this copy and never removes
the original matrix.

The compatibility QR, SVD, Cholesky, and eigen methods remain source
compatible. They are not silently routed through the typed implementation:
their shapes, ordering, tolerance, error, and ownership contracts differ.
Opting in means constructing the matching typed matrix, which is a deep copy
when starting from `IMatrix`.

Do not migrate `PseudoInverse(B).Multiply(...)` literally. Express the task:

```pascal
X := MinimumNormSolve(A, B, Info);
```

This uses the reusable compact SVD directly, does not form an inverse or
pseudoinverse, supports multiple right-hand sides, and reports numerical rank
and backward error. For a known full-rank tall problem, prefer
`LeastSquares`; for uncertain rank where a basic solution is enough, use
`RankRevealingLeastSquares`.

For ordinary code, prefer the allocating function:

```pascal
C := Multiply(A, B);
```

For a loop, allocate the destination once:

```pascal
C := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
for Iteration := 1 to IterationCount do
  MultiplyInto(A, B, C);
```

The 1.5 `MultiplyInto` implementation guarantees correct overlapping aliases
by using a temporary. This is deterministic and safe, but a non-overlapping
destination avoids retaining unnecessary aliases and communicates intent.

