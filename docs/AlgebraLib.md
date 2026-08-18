# AlgebraLib

Linear algebra domain providing typed dense, structured, sparse, and
matrix-free operations, direct/iterative solvers, partial eigensystems, and
vector operations for Free Pascal.

Depends on: **MathBase**

## Learning routes

### Beginner route

New code should copy and run the [typed double-real solve](TypedDenseMatrices.md#60-second-solve),
which prints `solution = 2.0000, 3.0000`. `Solve` allocates a result and private
factor storage without mutating its inputs. The lower [quick start](#quick-start)
documents the retained compatibility API, not the primary beginner path.

### Common tasks and algorithm choice

| Task | Start with | Contract or failure guidance |
| --- | --- | --- |
| Square dense solve | `Solve` / `SolveWithInfo` | [Dense solver choice](DenseLinearAlgebra.md#choose-a-dense-solver) |
| Tall least squares | `LeastSquares` | [Least-squares recipe](RECIPES.md#dense-least-squares) |
| Sparse positive-definite solve | `ConjugateGradient` | [Sparse solver choice](SparseLinearAlgebra.md#choose-an-iterative-solver) |
| Matrix multiplication | `Multiply` | [Typed entry-point choice](TypedDenseMatrices.md#choose-an-entry-point) |
| Compatibility `IMatrix` code | `TMatrixKit` | [Compatibility design notes](#design-notes) |

### Advanced route

Run [example 16](../examples/16_dense_solver_selection.pas) for QR/SVD/eigen
selection and [example 22](../examples/22_sparse_end_to_end.pas) for sparse
storage, preconditioning, and diagnostic statuses. Both keep double-real typed
containers; reusable factors, views, destinations, and workspaces are deeper
forms of the same documented APIs and require no private conversion.

## Units

| Unit | File | Purpose |
|------|------|---------|
| `AlgebraLib.Matrices` | [AlgebraLib.Matrices.pas](../src/AlgebraLib.Matrices.pas) | Core implementation — all logic lives here |
| `AlgebraLib.Vectors` | [AlgebraLib.Vectors.pas](../src/AlgebraLib.Vectors.pas) | Re-exports vector-oriented type aliases |
| `AlgebraLib.Determinants` | [AlgebraLib.Determinants.pas](../src/AlgebraLib.Determinants.pas) | Re-exports decomposition type aliases |
| `AlgebraLib.DenseMatrices` | [AlgebraLib.DenseMatrices.pas](../src/AlgebraLib.DenseMatrices.pas) | Typed aligned row-major storage, views, copies, and compatibility conversions |
| `AlgebraLib.DenseKernels` | [AlgebraLib.DenseKernels.pas](../src/AlgebraLib.DenseKernels.pas) | Matching single/double real/complex allocating and `Into` kernels |
| `AlgebraLib.DenseSolvers` | [AlgebraLib.DenseSolvers.pas](../src/AlgebraLib.DenseSolvers.pas) | Direct solve and reusable LU/Cholesky factors |
| `AlgebraLib.DenseDecompositions` | [AlgebraLib.DenseDecompositions.pas](../src/AlgebraLib.DenseDecompositions.pas) | Typed triangular, QR/CPQR, SVD/minimum-norm, and symmetric/Hermitian eigen workflows |
| `AlgebraLib.SparseMatrices` | [AlgebraLib.SparseMatrices.pas](../src/AlgebraLib.SparseMatrices.pas) | Typed immutable CSR/CSC plus diagonal, tridiagonal, and band storage |
| `AlgebraLib.LinearOperators` | [AlgebraLib.LinearOperators.pas](../src/AlgebraLib.LinearOperators.pas) | Stored/matrix-free operators and identity, diagonal, IC(0), and ILU(0) preconditioners |
| `AlgebraLib.IterativeSolvers` | [AlgebraLib.IterativeSolvers.pas](../src/AlgebraLib.IterativeSolvers.pas) | Diagnostic CG, MINRES, restarted GMRES, BiCGSTAB, and LSQR |
| `AlgebraLib.StructuredSolvers` | [AlgebraLib.StructuredSolvers.pas](../src/AlgebraLib.StructuredSolvers.pas) | Reusable tridiagonal/band factors and explicit natural-order sparse LU baseline |
| `AlgebraLib.PartialEigensystems` | [AlgebraLib.PartialEigensystems.pas](../src/AlgebraLib.PartialEigensystems.pas) | Restarted largest-magnitude Lanczos and Arnoldi |

The typed dense solver-selection and complete factor contracts are in
[Typed dense decompositions and solvers](DenseLinearAlgebra.md). The
large-problem selection, storage, residual, and reuse contracts are in
[Sparse, structured, and matrix-free linear algebra](SparseLinearAlgebra.md).
The
`IMatrix` records below remain the source-compatible legacy surface.

---

## Core Types

### Exception

```pascal
EMatrixError = class(Exception);
```

Raised on dimension mismatches, singular matrices, invalid indices, and other matrix errors.

### Storage

```pascal
TMatrixArray = array of array of Double;
```

Underlying 2-D array type used by the concrete implementation.

### Decomposition Records

| Record | Fields | Factorisation |
|--------|--------|--------------|
| `TLUDecomposition` | `L, U: IMatrix; P: array of Integer` | PA = LU |
| `TQRDecomposition` | `Q, R: IMatrix` | A = QR |
| `TEigenDecomposition` | `EigenValues: array of Double; EigenVectors: IMatrix` | A = VDV⁻¹ |
| `TSVD` | `U, S, V: IMatrix` | A = USVᵀ |
| `TCholeskyDecomposition` | `L: IMatrix` | A = LLᵀ |
| `TEigenpair` | `EigenValue: Double; EigenVector: IMatrix` | Single (λ, v) pair |

All records expose a `ToString: string` method for easy debugging.

### Iterative Solver Enum

```pascal
TIterativeMethod = (imConjugateGradient, imGaussSeidel, imJacobi);
```

### Vector APIs (`AlgebraLib.Vectors`)

```pascal
IVector = IMatrix;     // A vector is a 1-row or 1-column IMatrix
TVector = TMatrixKit;  // Concrete type for construction
```

The matrix-vector API remains the compatibility-oriented API. For contiguous
real or complex arrays, `AlgebraLib.Vectors` also re-exports:

```pascal
TRealVector = TDoubleArray;
TComplexVector = TComplexArray;
TVectorKit = class;
```

`TVectorKit` provides allocation-returning `Add`, `Subtract`,
`ElementWiseMultiply`, `ElementWiseDivide`, `Scale`, and `Axpy` operations,
plus compensated `Sum`/`Dot`, `Mean`, `Min`, `Max`, stable `Norm2`, and
`Normalize` for real vectors. Its complex overloads add non-conjugating `Dot`
and Hermitian `DotConjugate`.

Every allocating transform also has an `...Into` variant, for example:

```pascal
var Destination: TRealVector;
begin
  SetLength(Destination, Length(A));
  TVectorKit.AxpyInto(0.5, A, B, Destination); // Destination := 0.5*A + B
end;
```

`Destination` is a `var` parameter so a correctly sized existing dynamic array
is reused rather than replaced. Elementwise `...Into` transforms may use one
of their inputs as the destination. Inputs must be finite and paired vectors
must have equal length; empty-vector sums, dots, and norms are zero, while
`Mean`, `Min`, `Max`, and zero-vector normalization raise `EVectorError`.

### Decomposition Entry Point (`AlgebraLib.Determinants`)

```pascal
TIterSolverMethod = TIterativeMethod;
```

The decomposition records retain their original names from
`AlgebraLib.Matrices`: `TLUDecomposition`, `TQRDecomposition`,
`TEigenDecomposition`, `TSVD`, `TCholeskyDecomposition`, and `TEigenpair`.
`AlgebraLib.Determinants` provides the focused import path and the one explicit
enum alias shown above; it does not declare shortened record aliases such as
`TLUDecomp` or `TSVDecomp`.

---

## IMatrix Interface

Arithmetic, transformations, decompositions, and matrix functions return new
matrices. `SetValue` and `SetSubMatrix` are explicit in-place mutators; the
sparse implementation also exposes mutating storage methods.

### Dimensions

| Method | Returns | Notes |
|--------|---------|-------|
| `GetRows` | `Integer` | Number of rows |
| `GetCols` | `Integer` | Number of columns; 0 for empty matrix |
| `GetValue(Row, Col)` | `Double` | 0-based indices; raises `EMatrixError` if out of bounds |
| `SetValue(Row, Col, Value)` | — | 0-based indices; raises `EMatrixError` if out of bounds |

### Basic Arithmetic

| Method | Parameters | Description |
|--------|-----------|-------------|
| `Add` | `Other: IMatrix` | Element-wise A + B; dimensions must match |
| `Subtract` | `Other: IMatrix` | Element-wise A − B; dimensions must match |
| `Multiply` | `Other: IMatrix` | Matrix multiplication A × B; uses cache-aware block algorithm |
| `ScalarMultiply` | `Scalar: Double` | k × A for every element |
| `ElementWiseMultiply` | `Other: IMatrix` | Hadamard product; dimensions must match |
| `ElementWiseDivide` | `Other: IMatrix` | Element-wise quotient; dimensions must match and divisors must be non-zero |

### Transformations

| Method | Description |
|--------|-------------|
| `Transpose` | Aᵀ |
| `Inverse` | A⁻¹ via LU decomposition; raises `EMatrixError` if singular or non-square |
| `PseudoInverse` | Moore-Penrose A⁺ via SVD |

### Matrix Functions

| Method | Parameters | Description |
|--------|-----------|-------------|
| `Exp` | — | Matrix exponential e^A via adaptive scaling-and-squaring Taylor series; square finite matrices only; raises if the result cannot be represented |
| `Power` | `Exponent: Double` | Integer powers use exponentiation by squaring; fractional powers use the symmetric eigendecomposition and require a positive-definite matrix |

### Matrix Properties (scalar results)

| Method | Returns | Notes |
|--------|---------|-------|
| `Determinant` | `Double` | LU-based determinant; square matrices only |
| `Trace` | `Double` | Sum of diagonal elements; square matrices only |
| `Rank` | `Integer` | Via pivoted Gaussian elimination with a matrix-scale-relative tolerance |
| `NormOne` | `Double` | Maximum absolute column sum |
| `NormInf` | `Double` | Maximum absolute row sum |
| `NormFrobenius` | `Double` | Square root of the sum of squared elements |
| `Condition` | `Double` | 1-norm condition estimate, `NormOne * Inverse.NormOne` |

### Type Checks

```pascal
function IsSquare: Boolean;
function IsSymmetric: Boolean;
function IsDiagonal: Boolean;
function IsTriangular(Upper: Boolean = True): Boolean;
function IsPositiveDefinite: Boolean;
function IsPositiveSemidefinite: Boolean;
function IsOrthogonal: Boolean;
function IsVector: Boolean;
function IsRowVector: Boolean;
function IsColumnVector: Boolean;
```

### Decompositions

| Method | Returns | Description |
|--------|---------|-------------|
| `LU` | `TLUDecomposition` | PA = LU with partial pivoting |
| `QR` | `TQRDecomposition` | A = QR via Gram-Schmidt |
| `EigenDecomposition` | `TEigenDecomposition` | Real symmetric matrices use Jacobi rotations; real 2×2 nonsymmetric matrices are handled analytically |
| `SVD` | `TSVD` | A = USVᵀ |
| `Cholesky` | `TCholeskyDecomposition` | A = LLᵀ; symmetric positive-definite matrices only |

### Linear System Solvers

| Method | Parameters | Description |
|--------|-----------|-------------|
| `SolveIterative` | `B: IMatrix; Method := imConjugateGradient; MaxIterations := 1000; Tolerance := 1e-10` | Iterative solve for a column-vector right-hand side; conjugate gradient assumes symmetric positive-definite A |
| `PseudoInverse` | none | Moore-Penrose pseudoinverse; use `A.PseudoInverse.Multiply(B)` for least-squares solutions |

The compatibility `IMatrix` interface has no direct `SolveLinear` method.
New code can use the typed [`Solve(A, B)` path](TypedDenseMatrices.md), which
factors the coefficient matrix instead of forming its inverse. Existing code
can opt in through `TDenseDoubleMatrix.FromIMatrix`.
`SolveIterative` raises `EMatrixError` if the selected method exhausts
`MaxIterations`; it never silently returns an unconverged last iterate.

### Vector Operations (single-row or single-column matrices)

| Method | Returns | Notes |
|--------|---------|-------|
| `DotProduct(Other)` | `Double` | Inner product; vectors must have the same length |
| `CrossProduct(Other)` | `IMatrix` | 3-element vectors only |
| `Normalize` | `IMatrix` | Unit vector; raises `EMatrixError` if zero magnitude |

### Statistical Methods

| Method | Returns |
|--------|---------|
| `Mean(Axis := -1)` | 1×1 overall mean for `-1`, 1×Cols column means for `0`, or Rows×1 row means for `1` |
| `Covariance` | Cols×Cols sample covariance matrix; rows are observations |
| `Correlation` | Cols×Cols correlation matrix; a zero-variance column produces zeros |

### Submatrices and Dominant Eigenpair

```pascal
function GetSubMatrix(StartRow, StartCol, NumRows, NumCols: Integer): IMatrix;
procedure SetSubMatrix(StartRow, StartCol: Integer; const SubMatrix: IMatrix);
function PowerMethod(MaxIterations: Integer = 100;
  Tolerance: Double = 1e-10): TEigenpair;
```

All indices are zero-based. `SetSubMatrix` mutates the receiving matrix.
`PowerMethod` returns the dominant real eigenpair and requires a square matrix.
It validates positive controls and raises `EMatrixError` if normalization or
convergence fails.

---

## TMatrixKit — Factory Methods

`TMatrixKit` is the concrete class that implements `IMatrix`. Its constructor
creates a zero-filled dense matrix; class functions provide specialised forms.

```pascal
constructor Create(Rows, Cols: Integer);
class function Identity(N: Integer): IMatrix;
class function Zeros(Rows, Cols: Integer): IMatrix;
class function Ones(Rows, Cols: Integer): IMatrix;
class function CreateFromArray(const Data: TMatrixArray): IMatrix;
class function CreateSparse(Rows, Cols: Integer): IMatrix;
class function CreateDiagonal(const Values: array of Double): IMatrix;
class function CreateBandMatrix(Size, LowerBand, UpperBand: Integer): IMatrix;
class function CreateSymmetric(const Data: TMatrixArray): IMatrix;
class function CreateHilbert(Size: Integer): IMatrix;
class function CreateToeplitz(const FirstRow, FirstCol: TDoubleArray): IMatrix;
class function CreateVandermonde(const Vector: TDoubleArray): IMatrix;
class function CreateRandom(Rows, Cols: Integer; Min, Max: Double): IMatrix; overload;
class function CreateRandom(Rows, Cols: Integer; Min, Max: Double;
  Seed: LongWord): IMatrix; overload;
```

`CreateBandMatrix` fills the requested band with ones. `CreateSymmetric` reads
the lower triangle of `Data` and mirrors it. `CreateToeplitz` returns a
`Length(FirstCol)` by `Length(FirstRow)` matrix and requires matching first
elements.

### Sparse Matrices

`TMatrixKitSparse` stores non-zero entries in row-major order. `GetValue` and
`SetValue` are available through `IMatrix`; zero (within `1e-15`) removes an
entry. The concrete class additionally exposes:

```pascal
procedure AddElement(Row, Col: Integer; Value: Double); // set/replace, not accumulate
procedure CompactStorage;
```

Sparse lookup and insertion are linear in the number of stored entries, and
`Add` currently returns a dense matrix.

---

## Quick Start

For new dense code, start with the
[typed dense five-minute guide](TypedDenseMatrices.md#60-second-solve). The
following example documents the retained compatibility API.

```pascal
uses AlgebraLib.Matrices;

var
  A, B, C: IMatrix;
  LU: TLUDecomposition;
begin
  A := TMatrixKit.CreateFromArray([[1,2],[3,4]]);
  B := TMatrixKit.Identity(2);

  C  := A.Multiply(B);                // C = A × I = A
  LU := A.LU;                         // PA = LU

  Writeln('Det = ', A.Determinant:0:4);  // -2.0
  Writeln('Rank = ', A.Rank);            // 2
end.
```

Expected output:

```text
Det = -2.0000
Rank = 2
```

## Design Notes

- **Mostly value-oriented** — calculations return new `IMatrix` instances;
  the explicitly named setters mutate their receiver.
- **Interface-based** — depend on `IMatrix`, not on `TMatrixKit`, for flexibility.
- **Cache-aware blocking** — matrix multiplication uses cache-aware blocking and bounded parallel workers when the operation count justifies thread startup. Unix callers without an installed thread manager automatically use the serial path.
- **Numerically stable** — LU uses partial pivoting and preserves prior L multipliers across row swaps; singularity and rank tolerances are relative to matrix scale.
- **Explicit convergence** — iterative solves and matrix exponential evaluation raise `EMatrixError` when they cannot converge or produce a finite representable result.
- **Real eigensystem contract** — the API raises `EMatrixError` for complex spectra, defective matrices, and unsupported nonsymmetric matrices larger than 2×2 instead of returning misleading real approximations.
- **Reproducible random matrices** — the seeded `CreateRandom` overload uses local state and does not change the process-wide `RandSeed`; the compatibility overload uses caller-managed global state and never calls `Randomize`.

## Common mistakes

- **Inverse versus solve.** For `A*X = B` prefer `Solve(A, B)` or a reusable
  factor instead of forming `A.Inverse`; inversion is not the recommended way
  to solve a system.
- **Square-only LU solves.** The pivoted-LU `Solve` path handles square
  systems; use QR least squares or SVD minimum norm for tall, wide, or
  rank-deficient problems.
- **Real eigensystems are limited.** The compatibility API raises
  `EMatrixError` for complex spectra, defective matrices, and nonsymmetric
  cases larger than 2×2 rather than returning misleading real approximations.
- **Compatibility versus typed.** `IMatrix` remains the double-real,
  nested-storage compatibility path; new dense code should use the typed dense
  API.
