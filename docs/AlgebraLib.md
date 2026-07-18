# AlgebraLib

Linear algebra library providing dense matrix operations, decompositions, iterative solvers, and vector operations for Free Pascal.

Depends on: **MathBase**

## Units

| Unit | File | Purpose |
|------|------|---------|
| `AlgebraLib.Matrices` | [AlgebraLib.Matrices.pas](../src/AlgebraLib.Matrices.pas) | Core implementation — all logic lives here |
| `AlgebraLib.Vectors` | [AlgebraLib.Vectors.pas](../src/AlgebraLib.Vectors.pas) | Re-exports vector-oriented type aliases |
| `AlgebraLib.Determinants` | [AlgebraLib.Determinants.pas](../src/AlgebraLib.Determinants.pas) | Re-exports decomposition type aliases |

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

### Vector Aliases (`AlgebraLib.Vectors`)

```pascal
IVector = IMatrix;     // A vector is a 1-row or 1-column IMatrix
TVector = TMatrixKit;  // Concrete type for construction
```

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

There is no public direct `SolveLinear` method. For a direct solve, multiply the
right-hand side by `A.Inverse`, or use `A.PseudoInverse` for least squares.
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

## Design Notes

- **Mostly value-oriented** — calculations return new `IMatrix` instances;
  the explicitly named setters mutate their receiver.
- **Interface-based** — depend on `IMatrix`, not on `TMatrixKit`, for flexibility.
- **Cache-aware blocking** — matrix multiplication uses cache-aware blocking and bounded parallel workers when the operation count justifies thread startup. Unix callers without an installed thread manager automatically use the serial path.
- **Numerically stable** — LU uses partial pivoting and preserves prior L multipliers across row swaps; singularity and rank tolerances are relative to matrix scale.
- **Explicit convergence** — iterative solves and matrix exponential evaluation raise `EMatrixError` when they cannot converge or produce a finite representable result.
- **Real eigensystem contract** — the API raises `EMatrixError` for complex spectra, defective matrices, and unsupported nonsymmetric matrices larger than 2×2 instead of returning misleading real approximations.
- **Reproducible random matrices** — the seeded `CreateRandom` overload uses local state and does not change the process-wide `RandSeed`; the compatibility overload uses caller-managed global state and never calls `Randomize`.
