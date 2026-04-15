# AlgebraLib

Linear algebra library providing dense matrix operations, decompositions, iterative solvers, and vector operations for Free Pascal.

Depends on: **MathBase**

## Units

| Unit | File | Purpose |
|------|------|---------|
| `AlgebraLib.Matrices` | [AlgebraLib.Matrices.pas](AlgebraLib.Matrices.pas) | Core implementation — all logic lives here |
| `AlgebraLib.Vectors` | [AlgebraLib.Vectors.pas](AlgebraLib.Vectors.pas) | Re-exports vector-oriented type aliases |
| `AlgebraLib.Determinants` | [AlgebraLib.Determinants.pas](AlgebraLib.Determinants.pas) | Re-exports decomposition type aliases |

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

### Decomposition Aliases (`AlgebraLib.Determinants`)

```pascal
TLUDecomp        = TLUDecomposition;
TQRDecomp        = TQRDecomposition;
TEigenDecomp     = TEigenDecomposition;
TSVDecomp        = TSVD;
TCholeskyDecomp  = TCholeskyDecomposition;
TEigenPair       = TEigenpair;
TIterSolverMethod = TIterativeMethod;
```

---

## IMatrix Interface

All operations return **new matrices** — existing matrices are never mutated.

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

### Transformations

| Method | Description |
|--------|-------------|
| `Transpose` | Aᵀ |
| `Inverse` | A⁻¹ via LU decomposition; raises `EMatrixError` if singular or non-square |
| `PseudoInverse` | Moore-Penrose A⁺ via SVD |

### Matrix Functions

| Method | Parameters | Description |
|--------|-----------|-------------|
| `Exp` | — | Matrix exponential e^A via Taylor series (N = 20 terms); square matrices only |
| `Power` | `exponent: Double` | A^p; integer exponents use repeated multiplication; fractional exponents use SVD |

### Matrix Properties (scalar results)

| Method | Returns | Notes |
|--------|---------|-------|
| `Determinant` | `Double` | Cofactor expansion; square matrices only; O(n!) — prefer LU for large n |
| `Trace` | `Double` | Sum of diagonal elements; square matrices only |
| `Rank` | `Integer` | Via Gaussian elimination; tolerance 10⁻¹² |

### Type Checks

```pascal
function IsSquare: Boolean;
function IsSymmetric: Boolean;
function IsVector: Boolean;
function IsRowVector: Boolean;
function IsColumnVector: Boolean;
```

### Decompositions

| Method | Returns | Description |
|--------|---------|-------------|
| `LUDecompose` | `TLUDecomposition` | PA = LU with partial pivoting |
| `QRDecompose` | `TQRDecomposition` | A = QR via Gram-Schmidt |
| `EigenDecompose` | `TEigenDecomposition` | A = VDV⁻¹ for diagonalisable matrices |
| `SVDecompose` | `TSVD` | A = USVᵀ |
| `CholeskyDecompose` | `TCholeskyDecomposition` | A = LLᵀ; symmetric positive-definite matrices only |

### Linear System Solvers

| Method | Parameters | Description |
|--------|-----------|-------------|
| `SolveLinear` | `B: IMatrix` | Direct solve Ax = B via LU decomposition |
| `SolveIterative` | `B: IMatrix; Method: TIterativeMethod; MaxIter, Tol` | Iterative solve; method selected by enum |
| `LeastSquares` | `B: IMatrix` | Min ‖Ax − B‖ via pseudoinverse |

### Vector Operations (single-row or single-column matrices)

| Method | Returns | Notes |
|--------|---------|-------|
| `DotProduct(Other)` | `Double` | Inner product; vectors must have the same length |
| `CrossProduct(Other)` | `IMatrix` | 3-element vectors only |
| `Normalize` | `IMatrix` | Unit vector; raises `EMatrixError` if zero magnitude |
| `OuterProduct(Other)` | `IMatrix` | m × n rank-1 matrix |

### Statistical Methods

| Method | Returns |
|--------|---------|
| `Mean` | Column/row mean depending on orientation |
| `Variance` | Column/row variance |
| `Covariance(Other)` | Covariance matrix |

---

## TMatrixKit — Factory Methods

`TMatrixKit` is the concrete class that implements `IMatrix`. Use its class methods to construct matrices.

```pascal
class function Create(Rows, Cols: Integer): IMatrix;
class function Identity(N: Integer): IMatrix;
class function Zero(Rows, Cols: Integer): IMatrix;
class function FromArray(const Data: TMatrixArray): IMatrix;
class function Diagonal(const Values: TDoubleArray): IMatrix;
class function Random(Rows, Cols: Integer): IMatrix;
```

---

## Quick Start

```pascal
uses AlgebraLib.Matrices;

var
  A, B, C: IMatrix;
  LU: TLUDecomposition;
begin
  A := TMatrixKit.FromArray([[1,2],[3,4]]);
  B := TMatrixKit.Identity(2);

  C  := A.Multiply(B);                // C = A × I = A
  LU := A.LUDecompose;                // PA = LU

  Writeln('Det = ', A.Determinant:0:4);  // -2.0
  Writeln('Rank = ', A.Rank);            // 2
end.
```

## Design Notes

- **Value semantics** — all operations return new `IMatrix` instances.
- **Interface-based** — depend on `IMatrix`, not on `TMatrixKit`, for flexibility.
- **Cache-aware blocking** — matrix multiplication uses `BLOCK_SIZE = 4` blocking; adjust for your CPU cache if working with large matrices.
- **Numerically stable** — LU uses partial pivoting; tolerances guard against near-zero pivots.
