# Sparse, structured, and matrix-free linear algebra

mathlib-fp 1.9 provides a portable typed path for large systems without
materialising a dense matrix. The stable scalar set is `Single`, `Double`,
`TSingleComplex`, and `TComplex`. All public shapes and indices use checked
`SizeInt`; indices are zero based.

The complete runnable workflow is
[`22_sparse_end_to_end.pas`](../examples/22_sparse_end_to_end.pas). It
assembles a five-point problem through triplets, writes and reads Matrix
Market coordinate data, constructs an incomplete-Cholesky preconditioner, and
solves with conjugate gradient while reporting a true residual.

## Sixty-second sparse solve

```pascal
uses
  MathBase.Iteration, AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices, AlgebraLib.LinearOperators,
  AlgebraLib.IterativeSolvers;
var
  Builder: TSparseDoubleTripletBuilder;
  A: ISparseDoubleMatrix;
  Op: ILinearDoubleOperator;
  B: IDenseDoubleMatrix;
  Options: TLinearSolveOptions;
  Solved: TDoubleLinearSolveResult;
begin
  Builder := TSparseDoubleTripletBuilder.Create(3, 3);
  try
    Builder.Add(0, 0, 2); Builder.Add(0, 1, -1);
    Builder.Add(1, 0, -1); Builder.Add(1, 1, 2);
    Builder.Add(1, 2, -1); Builder.Add(2, 1, -1);
    Builder.Add(2, 2, 2);
    A := Builder.ToCSR;
  finally
    Builder.Free;
  end;
  Op := TDoubleLinearOperator.FromSparse(A);
  B := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 0.0, 1.0]);
  Options := TLinearSolveOptions.Default;
  Solved := TDoubleIterativeSolver.ConjugateGradient(Op, B, Options);
  if Solved.Diagnostics.Status <> isConverged then
    Writeln('solve stopped: ', IterationStatusName(Solved.Diagnostics.Status));
end.
```

The simple overload creates a zero initial guess, solution, and workspace.
Use an `Into` overload and a scalar-specific workspace for repeated solves.

## Choose a representation

| Representation | Public entry points | Use it when |
| --- | --- | --- |
| CSR/CSC | `ISparseSingleMatrix`, `ISparseDoubleMatrix`, `ISparseSingleComplexMatrix`, `ISparseComplexMatrix`; matching `TSparse*Matrix` factories | An arbitrary matrix has few stored entries |
| Diagonal/tridiagonal/band | `IStructuredSingleMatrix`, `IStructuredDoubleMatrix`, `IStructuredSingleComplexMatrix`, `IStructuredComplexMatrix`; matching `TStructured*Matrix` factories | A fixed band describes the matrix exactly |
| Stored operator | `TSingleLinearOperator`, `TDoubleLinearOperator`, `TSingleComplexLinearOperator`, `TComplexLinearOperator` | A solver should consume sparse, structured, or dense storage through one contract |
| Matrix-free operator | `IMatrixFreeSingleAction`, `IMatrixFreeDoubleAction`, `IMatrixFreeSingleComplexAction`, `IMatrixFreeComplexAction` | Products can be computed without retaining matrix entries |

Dense typed matrices remain preferable for genuinely dense problems.
`ToDense`, `Row`, and `Column` are deliberately explicit allocation points.
No sparse product, operator adapter, iterative solver, or partial eigensolver
calls `ToDense`.

## Compressed-storage contract

`TSparseFormat` selects `sfCSR` or `sfCSC`. For CSR, `OuterPointer` has
`Rows + 1` entries and each segment contains strictly increasing column
indices. For CSC it has `Cols + 1` entries and each segment contains strictly
increasing row indices. In both cases:

- the first outer pointer is zero, the last equals `NonZeroCount`, and the
  sequence is nondecreasing;
- inner indices are in range, values are finite, and duplicate coordinates are
  forbidden;
- `szDrop` forbids stored exact zeros; `szKeep` retains them intentionally;
- factories validate and deep-copy caller arrays before publishing an immutable
  interface;
- getters expose scalar values, not writable backing arrays.

Malformed shapes, indices, storage, non-finite values, or incompatible operands
raise `ESparseMatrixError`. Construction is failure-atomic: no matrix interface
is returned until validation and copying finish.

`TSparseSingleTripletBuilder`, `TSparseDoubleTripletBuilder`,
`TSparseSingleComplexTripletBuilder`, and `TSparseComplexTripletBuilder` are
mutable, append-only construction helpers. `ToCSR`/`ToCSC` sort by coordinate
and insertion sequence, sum duplicate contributions in that deterministic
order, then apply `TSparseStoredZeroPolicy`. Finalisation does not consume the
builder, so it can be cleared or reused. A builder is not thread-safe.

### Storage and operation costs

Let `z` be stored entries, `k` contributed triplets, `p` dense right-hand-side
columns, and `w = lower bandwidth + upper bandwidth + 1`.

| Operation | Time | Additional/result storage |
| --- | --- | --- |
| Validated CSR/CSC construction | O(z) | O(z + outer dimension), deep copy |
| Triplet finalisation | O(k log k) | O(k + outer dimension) |
| Indexed lookup | O(log entries in selected row/column), with a scan across the other orientation | O(1) |
| CSR↔CSC conversion | O(z log z) in the current triplet-based implementation | O(z + rows + cols) |
| Addition/scaling | O((zA + zB) log(zA + zB)) / O(z) | canonical sparse result |
| Transpose/conjugate transpose | O(z) | O(z + outer dimension) |
| Sparse × sparse | proportional to visited row expansions plus O(cols) marker/accumulator work per active output row | sparse result plus O(cols) workspace; fill may reach the mathematical product |
| Sparse × dense | O(zp) | caller-provided dense destination |
| Frobenius `Norm2` | O(z) | O(1) |
| `Row` / `Column` | orientation-dependent scan | explicit dense vector result |
| `ToDense` | O(rows × cols + z) | O(rows × cols), explicit only |

`MultiplyDenseInto` forbids the destination from aliasing either input and
validates all shapes before writing. Other factory operations return a new
immutable matrix and never mutate their inputs.

Compact band values are row-major with `w` positions per row; position
`upper bandwidth + column - row` holds an in-band value. Padding positions
outside a rectangular shape must be zero. Structured factories deep-copy their
values and publish immutable, reentrant storage.

## Operators and preconditioners

`ILinearOperator<T>` exposes `Rows`, `Cols`, `ScalarKind`, `Ownership`,
`IsReentrant`, `Apply`, and `ApplyAdjoint`. Input and destination are dense
column vectors of the exact domain/range shape and must not alias.

| Adapter | Ownership | Reentrant contract |
| --- | --- | --- |
| Sparse/structured | `looRetainedImmutable` | Yes |
| Dense | `looRetainedMutable` | No; caller can mutate retained storage |
| Matrix-free action | `looDelegated` | Exactly the action's declaration |

An adapter retains its interface source. A matrix-free action is responsible
for both ordinary and adjoint products and must leave its destination valid or
raise an exception. Shape, nil, and scalar failures raise
`ELinearOperatorError` before an adapter writes a result.

Matrix-free construction validates the row and column vector capacities
independently. It does not multiply the dimensions or impose a hypothetical
dense-matrix allocation limit: the adapter stores only two dimensions and the
delegated action. Each axis must still be non-negative and small enough for one
typed dense vector on the target, which keeps invalid shapes deterministic on
Win32 without rejecting legitimate linear-storage problems.

`IPreconditioner<T>` exposes size, scalar kind, `TPreconditionerKind`,
reentrancy, and `Apply`. The named factories are `TSinglePreconditioner`,
`TDoublePreconditioner`, `TSingleComplexPreconditioner`, and
`TComplexPreconditioner`.

- `Identity` copies a vector.
- `Diagonal` stores checked reciprocals; `SparseDiagonal` extracts them from a
  square sparse matrix.
- `IncompleteCholesky0` requires canonical square CSR with a structurally
  present diagonal and Hermitian positive pivots. It preserves the lower
  pattern and is intended for eligible positive-definite systems.
- `ILU0` requires canonical square CSR and preserves its pattern.

Construction copies all retained factor data and raises
`EPreconditionerError` for unsupported format/shape, a missing or small pivot,
non-Hermitian IC(0) input, non-positive IC(0) curvature, or non-finite
arithmetic. Published preconditioners are immutable and reentrant. Application
supports an exact in-place input/destination vector; separate overlapping views
with different origins are rejected before destination modification.

## Choose an iterative solver

| Solver | Required mathematical model | Memory and products |
| --- | --- | --- |
| `ConjugateGradient` | square symmetric/Hermitian positive-definite operator; positive-definite preconditioner | O(n) workspace, one ordinary product per iteration |
| `MINRES` | square symmetric/Hermitian operator, possibly indefinite; positive-definite preconditioner | O(n) workspace, one ordinary product per iteration |
| restarted `GMRES` | general square operator | O(n × restart + restart²), one ordinary product per inner iteration |
| `BiCGSTAB` | general square operator | O(n), usually two ordinary products per iteration |
| `LSQR` | rectangular or square operator with a correct adjoint | O(rows + cols), ordinary and adjoint products |

Every method above has direct successful-solve coverage for `Single`, `Double`,
`TSingleComplex`, and `TComplex`. Sparse ordinary/adjoint products,
identity/diagonal/IC(0)/ILU(0) preconditioners, tridiagonal/band factors, and
sparse LU likewise execute through their named scalar facades in the test
suite; scalar aliases alone are not qualification evidence.

The solver validates shapes and scalar kinds, not symmetry, definiteness, or
conditioning. Those are caller model obligations. A violated CG/MINRES
assumption may be detected as curvature, preconditioner, or Lanczos breakdown,
but validation is not a proof of the mathematical model. GMRES uses left
preconditioning. LSQR has no preconditioner parameter in 1.9.

### Exact stopping contract

Every method starts from the supplied `Into` solution (or zero for the simple
overload) and defines the true residual

```text
r = b - A*x
```

CG, MINRES, GMRES, and BiCGSTAB stop against

```text
stop = max(AbsoluteTolerance, RelativeTolerance * ||r_initial||_2)
```

LSQR solves the rectangular least-squares problem by stopping on the normal
residual:

```text
g = A^H * r
stop = max(AbsoluteTolerance, RelativeTolerance * ||g_initial||_2)
```

This permits a correctly stationary inconsistent least-squares solution even
when `||r||_2` is nonzero. `InitialResidualNorm` and `FinalResidualNorm` always
report Euclidean norms of the unpreconditioned true residual.
`InitialNormalResidualNorm` and `FinalNormalResidualNorm` are populated by
LSQR and are `NaN` for the square-system methods. For LSQR,
`RequestedTolerance` and `AchievedRelativeResidual` refer to the normal
residual; for the other methods they refer to the true residual. Exact-zero
initial measures are handled explicitly.

Between explicit products, CG and BiCGSTAB monitor their recurrence residual,
MINRES monitors `abs(phi_bar)`, LSQR monitors its bidiagonalization estimate
of `||A^H*r||_2`, and GMRES monitors the left-preconditioned Arnoldi
least-squares estimate. These estimates are provisional:
`ResidualRefresh > 0` recomputes `b-A*x` at that interval where the algorithm
has a current iterate; LSQR recomputes both `r` and `A^H*r`.
`ConfirmConvergence=True` requires the applicable stopping measure to be
explicitly recomputed before accepting convergence. GMRES recomputes at every
restart/update. All methods recompute their final true residual before
returning if the last recorded value was an estimate. Setting
`ResidualRefresh=0` disables scheduled refreshes, not final diagnostics.

`TLinearSolveOptions.Default` is:

| Field | Default |
| --- | ---: |
| `MaxIterations` | 1000 |
| `RelativeTolerance` | `1.0e-8` |
| `AbsoluteTolerance` | `0.0` |
| `RestartSize` | 30 |
| `ResidualRefresh` | 50 |
| `BreakdownTolerance` | `1.0e-30` |
| `ConfirmConvergence` | `True` |
| `Monitor` | `nil` |

`IIterationMonitor.ShouldCancel` is checked at iteration boundaries.
`ReportProgress` receives method, completed iterations, operator-product count,
current residual or estimate, and the true-residual stopping threshold. Monitor
exceptions propagate; the `Into` overload still releases the workspace and
stores the latest complete iterate.

### Results, statuses, and reuse

`TLinearSolveDiagnostics` reports `Method`, `Status`, `BreakdownReason`,
`Iterations`, `ProductCount`, `ResidualRefreshCount`, true and LSQR normal residuals,
requested/achieved tolerance, `ResidualConfirmed`, and
`ConvergenceConfirmed`. `ResidualConfirmed` says the final reported true
residual was explicitly recomputed. `ConvergenceConfirmed` says an
`isConverged` outcome passed the explicitly recomputed method-specific
stopping test. `ResidualRefreshCount` counts interval-triggered explicit
refreshes; initial, final-diagnostic, and convergence-confirmation products are
already included in `ProductCount` but are not interval refreshes.

- `isConverged`: the applicable residual test passed; with the default this was
  confirmed by an explicit true residual.
- `isIterationLimit`: `MaxIterations` was exhausted.
- `isCancelled`: the monitor requested cancellation.
- `isNumericalBreakdown`: a `TLinearBreakdownReason` identifies non-finite
  arithmetic, zero denominator, non-positive curvature/preconditioner,
  Arnoldi invariant subspace, or Lanczos breakdown.
- `isUnknown` is only an initialization value; the stable solvers do not return
  it normally. Other shared `TIterationStatus` values are not emitted here.

Invalid options, nil objects, shape/scalar mismatch, a concurrently used
workspace, or forbidden aliasing raise `EIterativeSolverError`. Numerical
termination is returned as diagnostics rather than raised. An `Into` solve
commits the latest complete iterate on cancellation, limit, or breakdown; this
is intentional so it can be inspected or used as a new initial guess.

`TSingleIterativeWorkspace`, `TDoubleIterativeWorkspace`,
`TSingleComplexIterativeWorkspace`, and `TComplexIterativeWorkspace` own 18
work vectors, operator bridge vectors, and GMRES basis/Hessenberg storage.
They are mutable and non-reentrant. Repeating a solve with unchanged
rows/columns/restart reuses those allocations; changing them may resize.
Solutions, right-hand sides, and a workspace must not be shared concurrently
without caller synchronization. The in-use guard is atomic across threads:
recursive or concurrent reuse raises before an iteration begins. Invalid
options, forbidden aliases, and workspace-use failures leave the destination
unchanged, and the workspace remains reusable after the error.

## Reusable direct factors

The scalar factories `TSingleStructuredSolver`, `TDoubleStructuredSolver`,
`TSingleComplexStructuredSolver`, and `TComplexStructuredSolver` provide:

- `FactorTridiagonal`: adjacent partial pivoting, a possible second
  superdiagonal, multiple right-hand sides, and pivot diagnostics;
- `FactorBand`: compact general-band LU without pivoting; `PivotingUsed=False`
  makes that limitation observable;
- `FactorSparseLU`: an explicit baseline for square CSR matrices using natural
  ordering and row partial pivoting.

The factor interfaces are `IStructuredSingleDirectFactor`,
`IStructuredDoubleDirectFactor`, `IStructuredSingleComplexDirectFactor`,
`IStructuredComplexDirectFactor`, `ISparseSingleLUFactor`,
`ISparseDoubleLUFactor`, `ISparseSingleComplexLUFactor`, and
`ISparseComplexLUFactor`.

The sparse factor reports original, factor, and fill nonzero counts, ordering,
row-interchange count, and minimum pivot magnitude. Fill is retained sparsely
but may be much larger than the input. There is no hidden dense fallback,
symbolic ordering phase, fill-reducing ordering, or automatic iterative/direct
switch. Choosing `FactorSparseLU` is the caller's explicit request.

Factor constructors deep-copy/factor their input and either return a complete
immutable reentrant factor or raise `EStructuredSolveError` /
`ESparseDirectSolveError`. `SolveInto` accepts one or many RHS columns,
validates shapes before writing, and reuses the factor. Exact in-place
`SolveInto(B, B)` is supported because each RHS column is first copied to local
work storage; separate partially overlapping views are rejected before
destination modification.

## Partial eigensystems

`TSinglePartialEigenSolver`, `TDoublePartialEigenSolver`,
`TSingleComplexPartialEigenSolver`, and `TComplexPartialEigenSolver` expose
restarted `Lanczos` and `Arnoldi` over the same operator contract. Lanczos is
for symmetric/Hermitian operators; Arnoldi is general. The implementation
checks shapes and finite recurrence values but cannot prove Hermitian input.

`TSpectralOptions.Default` sets `EigenpairCount=1`, `KrylovDimension=20`,
`MaximumRestarts=20`, `Tolerance=1.0e-8`,
`BreakdownTolerance=1.0e-14`,
`StartingSeed=$4D595DF4D0F33173`, and
`Target=stLargestMagnitude`. `TSpectralResult` returns complex eigenvalues/vectors,
independently recomputed 2-norm residuals `||A*v-lambda*v||_2`, convergence
count/status, restarts, products, and the seed.

Only largest magnitude is supported. There is no shift-invert, interior,
nearest-target, generalized, Schur, or polynomial eigensystem path. For a real
Arnoldi operator, a complex Ritz vector used for restart is projected to its
real part; difficult conjugate-pair cases can therefore require a complex
operator path.

## Interchange

`MathBase.Interchange` supports Matrix Market coordinate `real general` for
double sparse matrices and `complex general` for double-complex sparse
matrices. Readers accept one-based file indices, convert them to zero-based
storage, reject duplicates and explicit zero entries, and independently enforce
caller nonzero and per-axis dimension limits before allocating builders or
outer-pointer arrays. Symmetric, Hermitian,
skew-symmetric, pattern, integer, and coordinate single-precision variants are
outside the 1.9 text subset.

`SaveSparseBinary` overloads cover all four scalar kinds.
`LoadSparseSingleBinary`, `LoadSparseDoubleBinary`,
`LoadSparseSingleComplexBinary`, and `LoadSparseComplexBinary` validate magic,
version, scalar kind, format, zero policy, checked shape/counts, canonical
ordering, payload length, and CRC before exposing a result. The binary format
is little-endian version 1 and is a mathlib-fp interchange format, not an open
standard.

See [Numerical interchange and inspection](Interchange.md) for stream
ownership, resource limits, and the dense formats.

## `TMatrixKitSparse` compatibility

The existing `AlgebraLib.Matrices.TMatrixKitSparse` remains unchanged. It uses
the legacy double-real `IMatrix` conventions and its established representation
and complexity; it is not the scalable typed CSR/CSC implementation. Convert
explicitly by enumerating legacy values into a `TSparseDoubleTripletBuilder`,
as shown in
[`23_api_migration_preview.pas`](../examples/23_api_migration_preview.pas).
No implicit conversion changes ownership, zero handling, or numerical behavior.

## Evidence and limits

Small typed-dense oracle, storage, malformed-input, status, reuse, and residual
fixtures live in
[`TestSparseMatrices.pas`](../tests/TestSparseMatrices.pas),
[`TestIterativeSolvers.pas`](../tests/TestIterativeSolvers.pas),
[`TestStructuredSolvers.pas`](../tests/TestStructuredSolvers.pas),
[`TestSparseInterchange.pas`](../tests/TestSparseInterchange.pas), and
[`TestPartialEigensystems.pas`](../tests/TestPartialEigensystems.pas).
Large non-densifying cases and measured conditions are published in the
[1.9 qualification report](QUALIFICATION_1.9.0.md).

Distributed, out-of-core, GPU, vendor-library, parallel sparse/SIMD,
fill-reducing sparse ordering, advanced sparse factorizations, and the partial
spectral targets listed above are not stable 1.9 capabilities.
