# Typed sparse and iterative linear algebra design for 1.9

## Status and scope

This record fixes the public contracts for the active 1.9.0 scalable-linear-
algebra milestone before the associated types are declared stable. It does not
remove or change the legacy `TMatrixKitSparse` compatibility implementation,
make a 2.0 default change, or add any later-roadmap numerical family.

The 1.9 implementation is split into reviewable vertical slices:

1. canonical typed compressed and structured storage;
2. stored, structured, dense, and matrix-free linear operators;
3. iterative solvers, workspaces, progress/cancellation, and preconditioners;
4. reusable tridiagonal, band, and sparse factors;
5. partial Lanczos/Arnoldi eigensystems;
6. sparse Matrix Market/binary interchange, migration/API snapshots,
   documentation, examples, benchmarks, and qualification.

## Scalar, shape, and indexing contract

Stable storage and operator products cover `Single`, `Double`,
`TSingleComplex`, and `TComplex` without conversion through another public
scalar type. Dimensions, compressed offsets, inner indices, iteration counts,
and nonzero counts use checked zero-based `SizeInt` values. Allocation
arithmetic is checked with `SizeUInt` before memory is requested.

Empty `0 x N`, `M x 0`, and `0 x 0` shapes are valid. Negative dimensions,
offset/index values outside the declared shape, decreasing compressed offsets,
an offset other than zero at the start, an offset other than `nnz` at the end,
unsorted or duplicate inner indices, and non-finite stored values are rejected
before a public result is returned.

## Compressed storage and ownership

`ISparseMatrix<T>` is an immutable, reference-counted handle. A factory or
builder deep-copies caller arrays into canonical storage:

- CSR has `Rows + 1` outer offsets and strictly increasing column indices
  within every row;
- CSC has `Cols + 1` outer offsets and strictly increasing row indices within
  every column;
- stored values and inner indices have exactly `NonZeroCount` entries;
- exact scalar zero is either retained or removed according to the explicit
  `TSparseStoredZeroPolicy`.

The handle owns its arrays. It never borrows caller memory and exposes scalar
accessors rather than mutable raw pointers. Concurrent reads are safe; no
method mutates the matrix. Conversions and arithmetic allocate independent
canonical results. Explicit `ToDense` conversion is the only general operation
allowed to allocate `Rows * Cols` scalar storage.

The mutable triplet builder owns an append-only contribution buffer. `Add`
is amortised O(1). Finalisation sorts by outer index, inner index, and original
sequence, then combines duplicates in that deterministic order and applies the
stored-zero policy. It is O(k log k) time and O(k) additional storage for `k`
contributions; it never performs compressed-array insertion per contribution.
The builder is not thread-safe and remains reusable after successful or failed
finalisation because finalisation works on a private copy.

## Structured storage

Diagonal, tridiagonal, and general band handles are immutable deep copies.
Band storage uses one compact row per diagonal offset and retains
`Rows * (LowerBandwidth + UpperBandwidth + 1)` scalar slots, with positions
outside the logical shape ignored and required to be exact zero on import.
Products and extraction operate directly on compact storage. Conversion to
sparse storage is explicit and O(stored structure); conversion to dense is
explicit and O(`Rows * Cols`).

## Arithmetic, aliasing, and destination rules

Sparse addition, scaling, transpose/conjugate transpose, sparse-vector and
sparse/dense products, sparse-sparse products, norms, and row/column extraction
preserve canonical compressed output. Sparse-sparse multiplication uses a
row accumulator whose marker/work arrays are proportional to the result column
count, not the full dense shape.

`...Into` products require exact destination shape. A destination may not
share dense storage with an input; validation occurs before modification.
After validation, callback or arithmetic failures leave caller-owned
destinations unspecified only when the callback itself modified shared state;
library-owned destination writes use a private temporary and commit on
success.

## Linear operators

`ILinearOperator<T>` is an immutable, reference-counted contract exposing
dimensions, scalar kind, ordinary product, and (where available) adjoint
product. Stored sparse, structured, and dense adapters retain their immutable
matrix handle. Matrix-free adapters retain procedural callbacks plus an opaque
caller context; the caller owns that context and must keep it alive.

Operator methods accept dense column blocks with exact input/output shapes.
They do not retain those blocks. Implementations and callbacks must be
reentrant for concurrent calls with distinct destination storage. A nil
callback, shape violation, non-finite callback result, or callback exception
fails the current operation without publishing a solver success result.

## Iteration options, stopping tests, and results

All iterative solvers share `TIterativeSolveOptions` and typed result records.
The simple overload allocates a workspace; the expert overload accepts a
caller-owned typed workspace. A workspace owns scratch matrices, may grow, is
reusable sequentially, is not safe for simultaneous calls, and never retains
an operator, preconditioner, right-hand side, initial guess, callback context,
or returned solution.

Let `r0 = b - A*x0`, `rk = b - A*xk`, and use the Euclidean vector norm. The
requested threshold is

```text
max(AbsoluteTolerance, RelativeTolerance * ||r0||2).
```

Convergence is claimed only after an explicit true-residual recomputation
satisfies this threshold. Recurrence residuals may trigger a check but never
alone establish `isConverged`. The final result reports initial/final true
residuals, the threshold, achieved relative residual, iterations, ordinary and
adjoint product counts, preconditioner applications, restart/refresh counts,
breakdown detail, and whether the final residual was recomputed.

`MaxIterations`, tolerances, restart size, and refresh interval are validated
before workspace or destination mutation. Cancellation is polled before the
first product and at every iteration. Progress is reported only with finite
metrics. A callback exception propagates and does not change caller inputs.
Workspace ownership is protected by an atomic in-use guard so concurrent and
recursive reuse are rejected consistently across supported threads.

The stable methods and mathematical assumptions are:

- CG: square Hermitian positive-definite operator and positive-definite
  preconditioner; preconditioned `rho = real(r^H z)` must remain positive.
- MINRES: square Hermitian operator; the implemented short Lanczos recurrence
  minimises the residual over the generated Krylov space. Its optional
  preconditioner must be Hermitian positive-definite.
- restarted GMRES: general square operator; modified Gram-Schmidt Arnoldi and
  unitary Givens rotations minimise the Euclidean residual in each restart
  cycle. Left preconditioning is reported separately from the confirmed true
  residual.
- BiCGSTAB: general square operator; complex inner products use conjugation in
  the first argument. Near-zero `rho`, denominator, or `omega` is numerical
  breakdown.
- LSQR: rectangular operator with a working adjoint; Golub-Kahan
  bidiagonalisation uses the true normalised residual for final confirmation.

Qualification invokes all five methods for every stable scalar and exercises
ordinary/adjoint products, preconditioners, and direct factors rather than
treating successful generic specialization as numerical evidence.

No solver silently tests symmetry, Hermitian structure, or positive
definiteness by densifying the operator. Eligibility is a caller contract;
detected violations or non-positive preconditioned products are reported as
breakdown.

## Preconditioners

`IPreconditioner<T>` is immutable and reentrant for concurrent applications.
Identity and diagonal preconditioners cover all four scalar paths. A diagonal
entry must be finite and nonzero. Exact in-place application is supported;
distinct views sharing storage are rejected before either view is modified.

ILU(0) accepts canonical square CSR storage with an explicit diagonal in every
row. It retains the input sparsity pattern, performs no fill, uses natural
ordering, and reports the first zero/invalid pivot. IC(0) accepts canonical
square CSR storage representing a Hermitian positive-definite matrix, retains
the lower pattern plus diagonal, and reports missing/complex/non-positive
pivots. Construction is failure-atomic. Applications use private caller
destinations and immutable factor data.

## Structured and sparse direct factors

The tridiagonal factor is a pivoted O(n) LU representation with first and
second superdiagonals and row pivots. It owns a snapshot, supports dense
multiple right-hand sides, reports pivot count and the first singular pivot,
and never mutates caller matrices.

The band factor converts compact band storage to the sparse direct baseline;
the conversion is explicit in documentation and retains storage proportional
to the band plus numerical fill. The sparse baseline uses natural column
ordering, sparse row storage, threshold-free row partial pivoting, and explicit
fill. Diagnostics report input nonzeros, factor nonzeros, numerical fill,
pivots, and singular position. Pathological fill may approach dense storage;
the factor never preallocates or silently materialises a dense matrix.
Unsupported ordering or matrix classes fail unless the caller explicitly
chooses another path.

Factors are immutable snapshots and safe for concurrent solves with distinct
outputs. Solve validation and singularity checks precede publication of a
result. A factor workspace is local to each solve.

## Partial eigensystems

Restarted Lanczos accepts square Hermitian operators and returns selected
largest-magnitude Ritz pairs, true residuals, convergence flags, product
counts, and deterministic-start metadata. The projected tridiagonal
eigensystem is solved in double precision; single-precision operator products
remain single precision and use single-appropriate residual budgets.

Restarted Arnoldi accepts a general square operator and returns selected
largest-magnitude complex Ritz pairs. Real operators apply separately to real
and imaginary Ritz-vector components when confirming residuals. The projected
Hessenberg problem uses a portable complex QR/Schur iteration. Shift-invert,
interior targets, generalized problems, and left eigenvectors are explicitly
unsupported in 1.9.

Starting vectors are generated by a documented deterministic local state or
supplied explicitly. Returned vectors own independent dense storage. A restart
workspace is reusable sequentially and is not concurrently mutable.

## Sparse interchange

Matrix Market support is the coordinate `real general` and `complex general`
subset for all four scalar paths. Indices in the file are one-based and are
converted to the library's zero-based contract only after range checks.
Duplicate coordinates are either combined deterministically or rejected by an
explicit read policy.

The binary format records magic, version, scalar kind, compressed format,
shape, nonzero count, outer count, payload size, and CRC-32. Integer fields and
IEEE scalar components are little-endian. Loads enforce caller limits, exact
payload size, checksum, canonical offsets/indices, stored-zero policy, and
finite values before constructing a public matrix. Truncation, trailing
payload, incompatible version/kind, corrupt checksum, unreasonable sizes, and
malformed canonical data expose no partial result.

## Compatibility and migration

`TMatrixKitSparse`, `IMatrix`, and all maintained 1.x entry points remain
source-compatible. Conversion between `TMatrixKitSparse` and typed sparse
storage is explicit and documented as a deep O(`Rows * Cols`) compatibility
scan when the legacy interface cannot expose its entries directly.

The 1.9 API preview classifies maintained entry points without removing or
changing defaults. Machine-readable snapshots cover normalized public
interface declarations. A snapshot change is accepted only with a reviewed
1.9 compatibility or correctness reason.

## Provenance

- CSR/CSC and sparse accumulation follow standard compressed-storage
  definitions used by Matrix Market and sparse BLAS interfaces.
- CG and Lanczos follow Hestenes--Stiefel and the symmetric Lanczos process.
- MINRES follows Paige--Saunders.
- GMRES follows Saad--Schultz with restarted modified Gram-Schmidt.
- BiCGSTAB follows van der Vorst.
- LSQR follows Paige--Saunders Golub--Kahan bidiagonalisation.
- ILU(0)/IC(0) retain the input zero-fill pattern; sparse Gaussian
  elimination uses explicit row partial pivoting and natural ordering.
- Tridiagonal pivoting follows the `xGTTRF/xGTTRS` storage and solve
  conventions without copying external implementation code.

All implementations are original portable Pascal written for this repository.
Independent dense comparisons, exact fixtures, residual identities, malformed
input tests, and reproducible large sparse cases provide qualification
evidence without a runtime numerical dependency.
