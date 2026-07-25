# Migrating to the typed dense API

Version 1.5.0 does not remove or deprecate `IMatrix`, `TMatrixKit`, `IVector`,
or their methods. Migration is opt-in.

| Use case | Compatibility API | Typed allocating API | Repeated/high-performance form |
| --- | --- | --- | --- |
| Construct | `TMatrixKit.CreateFromArray` | `TDenseDoubleMatrix.FromValues` | `Zeros`, then checked writes |
| Multiply | `A.Multiply(B)` | `Multiply(A, B)` | `MultiplyInto(A, B, Destination)` |
| Solve | Previously required inverse multiplication or an iterative method | `Solve(A, B)` | `FactorLU(A).Solve(B)` |
| Positive-definite solve | `Cholesky` plus caller glue | `FactorCholesky(A).Solve(B)` | Reuse the factor |
| Submatrix | Copying `GetSubMatrix` | Mutable retained-owner `View` | Reuse the view handle |
| Compatibility bridge | Already `IMatrix` | `TDenseDoubleMatrix.FromIMatrix` | Keep data typed to avoid repeated copies |

Conversions between `IMatrix`/`TMatrixArray` and typed matrices are deep
copies. `FromVector` also copies an array into matrix-owned storage. `Clone`
copies; interface assignment and `View` alias.

The typed API uses `SizeInt` dimensions and zero-based indices. Existing
`IMatrix` dimensions remain `Integer`, so a conversion back to `IMatrix`
inherits that API's limit. Conversion never hides this copy and never removes
the original matrix.

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

