# 🔢 pascal-mathlibs.Math.Matrices User Manual

A comprehensive guide to using the matrix operations in pascal-mathlibs.

## Table of Contents
- [Basic Operations](#basic-operations)
- [Matrix Creation](#matrix-creation)
- [Matrix Properties](#matrix-properties)
- [Matrix Decompositions](#matrix-decompositions)
- [Matrix Functions](#matrix-functions)
- [Vector Operations](#vector-operations)
- [Statistical Operations](#statistical-operations)
- [Common Use Cases](#common-use-cases)
- [Memory Management](#memory-management)

## Basic Operations

### Creating Matrices
```pascal
var
  A, B, C: IMatrix;
begin
  // Create from array
  A := TMatrixKit.CreateFromArray([
    [1.0, 2.0],
    [3.0, 4.0]
  ]);

  // Create special matrices
  B := TMatrixKit.Identity(2);     // 2x2 identity matrix
  C := TMatrixKit.Zeros(2, 3);     // 2x3 matrix of zeros
  C := TMatrixKit.Ones(3, 2);      // 3x2 matrix of ones
  
  // Advanced matrix creation
  C := TMatrixKit.CreateHilbert(3);  // 3x3 Hilbert matrix
  C := TMatrixKit.CreateDiagonal([1.0, 2.0, 3.0]);  // Diagonal matrix
end;
```

For example, the above code creates:

$$
A = \begin{bmatrix}
1.0 & 2.0 \\
3.0 & 4.0
\end{bmatrix}, \quad
B = \begin{bmatrix}
1.0 & 0.0 \\
0.0 & 1.0
\end{bmatrix}, \quad
C = \begin{bmatrix}
0.0 & 0.0 & 0.0 \\
0.0 & 0.0 & 0.0
\end{bmatrix}
$$

### Matrix Arithmetic
For a matrix $A$ with elements $a_{ij}$ and a matrix $B$ with elements $b_{ij}$ of compatible dimensions:

- Addition: $C = A + B$
- Subtraction: $C = A - B$
- Matrix multiplication: $C = AB$ where $C_{ij} = \sum_{k=1}^n A_{ik}B_{kj}$
- Scalar multiplication: $C = \alpha A$ where $\alpha$ is a scalar
- Element-wise multiplication (Hadamard product): $C = A \odot B$ where $C_{ij} = A_{ij}B_{ij}$
- Element-wise division: $C_{ij} = A_{ij}/B_{ij}$

```pascal
var
  A, B, C: IMatrix;
begin
  // Addition
  C := A.Add(B);

  // Subtraction
  C := A.Subtract(B);

  // Matrix multiplication
  C := A.Multiply(B);

  // Scalar multiplication
  C := A.ScalarMultiply(2.0);
  
  // Element-wise operations
  C := A.ElementWiseMultiply(B);
  C := A.ElementWiseDivide(B);
end;
```

## Matrix Properties

### Basic Properties
For a matrix $A$:

- Determinant: $\det(A)$ or $|A|$
- Trace: $\text{tr}(A) = \sum_{i=1}^n A_{ii}$
- Rank: $r = \text{rank}(A)$, number of linearly independent rows/columns
- Condition number: $\kappa(A) = \|A\| \cdot \|A^{-1}\|$

```pascal
var
  M: IMatrix;
  Val: Double;
begin
  // Dimensions
  WriteLn('Rows: ', M.Rows);
  WriteLn('Columns: ', M.Cols);

  // Access elements
  Val := M.Values[0, 0];  // First element
  M.Values[1, 1] := 2.0;  // Set element

  // Properties
  WriteLn('Determinant: ', M.Determinant);
  WriteLn('Trace: ', M.Trace);
  WriteLn('Rank: ', M.Rank);
  WriteLn('Condition number: ', M.Condition);
end;
```

### Matrix Type Checks
```pascal
var
  M: IMatrix;
begin
  if M.IsSquare then
    WriteLn('Matrix is square');
  if M.IsSymmetric then
    WriteLn('Matrix is symmetric');
  if M.IsDiagonal then
    WriteLn('Matrix is diagonal');
  if M.IsTriangular(True) then
    WriteLn('Matrix is upper triangular');
  if M.IsPositiveDefinite then
    WriteLn('Matrix is positive definite');
  if M.IsPositiveSemidefinite then
    WriteLn('Matrix is positive semidefinite');
  if M.IsOrthogonal then
    WriteLn('Matrix is orthogonal');
end;
```

### Matrix Norms
For a matrix $A$:

- One norm (maximum column sum): $\|A\|_1 = \max_{j} \sum_{i=1}^m |a_{ij}|$
- Infinity norm (maximum row sum): $\|A\|_\infty = \max_{i} \sum_{j=1}^n |a_{ij}|$
- Frobenius norm: $\|A\|_F = \sqrt{\sum_{i=1}^m \sum_{j=1}^n |a_{ij}|^2}$

```pascal
var
  M: IMatrix;
begin
  WriteLn('One norm: ', M.NormOne);
  WriteLn('Infinity norm: ', M.NormInf);
  WriteLn('Frobenius norm: ', M.NormFrobenius);
end;
```

## Matrix Decompositions

### LU Decomposition
Factors a matrix $A$ into:
$$A = PLU$$
where:
- $P$ is a permutation matrix
- $L$ is lower triangular with ones on diagonal
- $U$ is upper triangular

```pascal
var
  M: IMatrix;
  LU: TLUDecomposition;
begin
  LU := M.LU;
  // LU.L is the lower triangular matrix
  // LU.U is the upper triangular matrix
  // LU.P contains the permutation indices
  
  // Get formatted string representation
  WriteLn(LU.ToString);
end;
```

### QR Decomposition
Factors a matrix $A$ into:
$$A = QR$$
where:
- $Q$ is orthogonal ($Q^TQ = I$)
- $R$ is upper triangular

The QR decomposition is implemented with robust memory management:
- Temporary vectors and matrices are properly cleaned up
- Exception handling ensures resources are freed
- Memory-safe Gram-Schmidt process implementation

```pascal
var
  M: IMatrix;
  QR: TQRDecomposition;
begin
  QR := M.QR;
  // QR.Q and QR.R are automatically managed
  // Temporary matrices used in the decomposition are properly freed
  
  // Get formatted string representation
  WriteLn(QR.ToString);
end;
```

### Eigendecomposition
For a square matrix $A$:
$$A\mathbf{v} = \lambda\mathbf{v}$$
where:
- $\lambda$ is an eigenvalue
- $\mathbf{v}$ is the corresponding eigenvector

```pascal
var
  M: IMatrix;
  Eigen: TEigenDecomposition;
begin
  Eigen := M.EigenDecomposition;
  // Eigen.EigenValues contains the eigenvalues
  // Eigen.EigenVectors contains the eigenvectors
  
  // Get formatted string representation
  WriteLn(Eigen.ToString);
end;
```

### Singular Value Decomposition (SVD)
Factors a matrix $A$ into:
$$A = U\Sigma V^T$$
where:
- $U$ is an orthogonal matrix
- $\Sigma$ is a diagonal matrix with singular values
- $V^T$ is the transpose of an orthogonal matrix

The SVD implementation features:
- Safe management of all temporary matrices
- Proper cleanup of eigendecomposition components
- Memory-efficient QR iteration process

```pascal
var
  M: IMatrix;
  SVD: TSVD;
begin
  SVD := M.SVD;
  // SVD.U, SVD.S, and SVD.V are automatically managed
  // All intermediate calculations use proper cleanup
  
  // Get formatted string representation
  WriteLn(SVD.ToString);
end;
```

### Cholesky Decomposition
For a positive definite matrix $A$, factors it into:
$$A = LL^T$$

The Cholesky decomposition ensures:
- Safe memory management of the L matrix
- Proper cleanup in case of non-positive definite matrices
- Exception safety for all temporary calculations

```pascal
var
  M: IMatrix;
  Chol: TCholeskyDecomposition;
begin
  Chol := M.Cholesky;
  // Chol.L is automatically managed
  // Memory is properly freed even if matrix is not positive definite
  
  // Get formatted string representation
  WriteLn(Chol.ToString);
end;
```

## Matrix Functions

### Matrix Exponential
For a square matrix $A$, the matrix exponential is defined as:
$$e^A = \sum_{k=0}^{\infty} \frac{A^k}{k!}$$

```pascal
var
  M, ExpM: IMatrix;
begin
  ExpM := M.Exp;
end;
```

### Matrix Power
For a square matrix $A$ and a scalar $p$, the matrix power is defined as:
$$A^p = V D^p V^{-1}$$
where $A = VDV^{-1}$ is the eigendecomposition of $A$.

```pascal
var
  M, PowerM: IMatrix;
begin
  // Integer power
  PowerM := M.Power(2);  // A^2
  
  // Fractional power (for positive definite matrices)
  PowerM := M.Power(0.5);  // A^(1/2) or square root of A
end;
```

### Pseudoinverse
For a matrix $A$, the Moore-Penrose pseudoinverse $A^+$ satisfies:
$$AA^+A = A, \quad A^+AA^+ = A^+, \quad (AA^+)^T = AA^+, \quad (A^+A)^T = A^+A$$

```pascal
var
  M, PInv: IMatrix;
begin
  PInv := M.PseudoInverse;
end;
```

## Vector Operations

### Vector Properties and Operations
```pascal
var
  V1, V2, Result: IMatrix;
  DotProd: Double;
begin
  // Create column vectors
  V1 := TMatrixKit.CreateFromArray([[1.0], [2.0], [3.0]]);
  V2 := TMatrixKit.CreateFromArray([[4.0], [5.0], [6.0]]);
  
  // Check if a matrix is a vector
  if V1.IsVector then
    WriteLn('This is a vector');
  if V1.IsColumnVector then
    WriteLn('This is a column vector');
    
  // Dot product
  DotProd := V1.DotProduct(V2);
  
  // Cross product (for 3D vectors)
  Result := V1.CrossProduct(V2);
  
  // Normalize a vector
  Result := V1.Normalize;
end;
```

## Statistical Operations

### Basic Statistics
```pascal
var
  M, Result: IMatrix;
begin
  // Overall mean
  Result := M.Mean;
  
  // Column means
  Result := M.Mean(0);
  
  // Row means
  Result := M.Mean(1);
  
  // Covariance matrix
  Result := M.Covariance;
  
  // Correlation matrix
  Result := M.Correlation;
end;
```

## Common Use Cases

### Solving Linear Systems
For a system $A\mathbf{x} = \mathbf{b}$:
- Direct solution: $\mathbf{x} = A^{-1}\mathbf{b}$
- LU solution: Solve $L\mathbf{y} = P\mathbf{b}$, then $U\mathbf{x} = \mathbf{y}$
- Pseudoinverse solution (for non-square systems): $\mathbf{x} = A^+\mathbf{b}$

The system in matrix form:

$$
\begin{bmatrix}
5 & 7 & 6 & 5 \\
7 & 10 & 8 & 7 \\
6 & 8 & 10 & 9 \\
5 & 7 & 9 & 10
\end{bmatrix}
\begin{bmatrix}
x_1 \\
x_2 \\
x_3 \\
x_4
\end{bmatrix} =
\begin{bmatrix}
57 \\
79 \\
88 \\
86
\end{bmatrix}
$$

```pascal
// Given the system Ax = b
var
  A, B, X: IMatrix;
begin
  // Create coefficient matrix A
  A := TMatrixKit.CreateFromArray([
    [5.0, 7.0, 6.0, 5.0],
    [7.0, 10.0, 8.0, 7.0],
    [6.0, 8.0, 10.0, 9.0],
    [5.0, 7.0, 9.0, 10.0]
  ]);

  // Create right-hand side vector b
  B := TMatrixKit.CreateFromArray([
    [57.0],
    [79.0],
    [88.0],
    [86.0]
  ]);

  // Solve using direct inverse
  X := A.Inverse.Multiply(B);
  
  // Or using pseudoinverse for non-square systems
  X := A.PseudoInverse.Multiply(B);
  
  // Or using iterative methods for large systems
  X := A.SolveIterative(B, imConjugateGradient);
end;
```

### Creating Special Matrices
```pascal
var
  M: IMatrix;
  FirstRow, FirstCol: TDoubleArray;
  Vector: TDoubleArray;
begin
  // Hilbert matrix
  M := TMatrixKit.CreateHilbert(3);
  
  // Toeplitz matrix
  SetLength(FirstRow, 3);
  SetLength(FirstCol, 3);
  FirstRow[0] := 1.0; FirstRow[1] := 2.0; FirstRow[2] := 3.0;
  FirstCol[0] := 1.0; FirstCol[1] := 4.0; FirstCol[2] := 5.0;
  M := TMatrixKit.CreateToeplitz(FirstRow, FirstCol);
  
  // Vandermonde matrix
  SetLength(Vector, 3);
  Vector[0] := 1.0; Vector[1] := 2.0; Vector[2] := 3.0;
  M := TMatrixKit.CreateVandermonde(Vector);
end;
```

## Memory Management

pascal-mathlibs.Math.Matrices uses a dual approach to memory management:

### Interface-Based Memory Management (Recommended)

The library primarily uses interface-based memory management through the `IMatrix` interface. When you use the interface type, memory is automatically managed through reference counting:

```pascal
var
  A, B, C: IMatrix;
begin
  // Create matrices
  A := TMatrixKit.Create(3, 3);
  B := TMatrixKit.Create(3, 3);
  
  // Perform operations
  C := A.Multiply(B);
  
  // No need to free anything - reference counting handles cleanup
  // when variables go out of scope
end;
```

### Internal Implementation Details

Internally, the library uses `TMatrixKit` objects which require manual memory management. However, as a user of the library, you should:

1. **Always use the `IMatrix` interface** in your code, not the `TMatrixKit` class directly
2. **Never manually free `IMatrix` references** - they are automatically managed
3. **Let interface variables go out of scope naturally** for proper cleanup

### When Manual Memory Management Is Needed

If you ever need to work directly with `TMatrixKit` objects (which is rare and not recommended), you must manually free them:

```pascal
var
  M: TMatrixKit;  // Direct object reference - requires manual management
begin
  M := TMatrixKit.CreateMatrix(3, 3);  // Internal constructor
  try
    // Use M...
  finally
    M.Free;  // Manual cleanup required
  end;
end;
```

### Best Practices

1. **Always use `IMatrix` interface** instead of `TMatrixKit` class
2. **Use factory methods** that return interfaces (`TMatrixKit.Create`, `TMatrixKit.Identity`, etc.)
3. **Let interface references go out of scope naturally** for automatic cleanup
4. **Use try-finally blocks** if you ever need to work with direct `TMatrixKit` objects
5. **Avoid mixing interface and direct object references** to the same matrix

By following these guidelines, your code will be memory-safe and avoid leaks when using the matrix library.

### Best Practices

1. Use interface types (`IMatrix`) instead of concrete classes for automatic reference counting.
2. Let matrices go out of scope naturally rather than manually freeing them.
3. Use try-finally blocks when working with multiple matrices to ensure cleanup.
4. Set matrices to nil after assigning them to results to prevent double freeing.

## String Representation of Matrices and Decompositions

pascal-mathlibs.Math.Matrices provides `ToString` methods for all matrices and decomposition records, allowing for easy debugging, logging, and display of results.

### Basic Matrix String Representation

```pascal
var
  M: IMatrix;
  S: string;
begin
  M := TMatrixKit.CreateFromArray([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0]
  ]);
  
  S := M.ToString;
  WriteLn(S);
  // Output:
  // |1 2 3|
  // |4 5 6|
end;
```

### Decomposition String Representations

All decomposition records include `ToString` methods that format their components in a readable manner:

```pascal
var
  M: IMatrix;
  LU: TLUDecomposition;
  QR: TQRDecomposition;
  Eigen: TEigenDecomposition;
  SVD: TSVD;
  Chol: TCholeskyDecomposition;
  Pair: TEigenpair;
begin
  M := TMatrixKit.CreateFromArray([
    [4.0, 3.0],
    [6.0, 3.0]
  ]);
  
  // LU Decomposition
  LU := M.LU;
  WriteLn(LU.ToString);
  // Output includes L, U matrices and P permutation array
  
  // QR Decomposition
  QR := M.QR;
  WriteLn(QR.ToString);
  // Output includes Q and R matrices
  
  // Eigendecomposition
  Eigen := M.EigenDecomposition;
  WriteLn(Eigen.ToString);
  // Output includes eigenvalues and eigenvectors
  
  // SVD
  SVD := M.SVD;
  WriteLn(SVD.ToString);
  // Output includes U, S, and V matrices
  
  // Cholesky Decomposition
  M := TMatrixKit.CreateFromArray([
    [4.0, 1.0],
    [1.0, 5.0]
  ]);
  Chol := M.Cholesky;
  WriteLn(Chol.ToString);
  // Output includes L matrix
  
  // Eigenpair
  Pair := M.PowerMethod;
  WriteLn(Pair.ToString);
  // Output includes eigenvalue and eigenvector
end;
```

These string representations are particularly helpful for:
- Debugging matrix algorithms
- Displaying computation results in console applications
- Logging matrix operations for analysis
- Verifying correctness of decompositions
- Educational purposes to demonstrate matrix concepts 

### Power Method
For a matrix $A$, the power method iteratively finds the dominant eigenvalue and corresponding eigenvector:

```pascal
var
  M: IMatrix;
  Pair: TEigenpair;
begin
  // Create a test matrix with known dominant eigenvalue
  M := TMatrixKit.CreateFromArray([
    [4.0, 1.0],
    [1.0, 3.0]
  ]);
  
  // Compute the dominant eigenpair using the power method
  Pair := M.PowerMethod;
  
  // Access the results
  WriteLn('Dominant eigenvalue: ', Pair.EigenValue:10:6);
  WriteLn('Eigenvector:');
  WriteLn(Pair.EigenVector.ToString);
  
  // Validate that A*v = λ*v
  // A*v should approximately equal λ*v within numerical tolerance
end;
```

### Sparse Matrix Operations
The library provides memory-efficient sparse matrix implementation for matrices with many zero elements:

```pascal
var
  SM, Result: IMatrix;
begin
  // Create a sparse matrix
  SM := TMatrixKit.CreateSparse(5, 5);
  
  // Set only non-zero elements
  SM.SetValue(0, 0, 1.0);
  SM.SetValue(1, 1, 2.0);
  SM.SetValue(2, 2, 3.0);
  SM.SetValue(0, 4, 5.0);
  SM.SetValue(4, 0, 5.0);
  
  // Get values (default is 0.0 for unset elements)
  WriteLn(SM.GetValue(0, 0));  // 1.0
  WriteLn(SM.GetValue(0, 1));  // 0.0
  
  // Addition works with both sparse and dense matrices
  Result := SM.Add(SM);  // Doubles all values
  
  // Convert to dense matrix if needed
  Dense := SM.ToDense;
end;
```


### Matrix Power
For a square matrix $A$ and a scalar $p$, the matrix power is defined as:
$$A^p = V D^p V^{-1}$$
where $A = VDV^{-1}$ is the eigendecomposition of $A$.

The implementation supports:
- Integer powers (positive and negative)
- Fractional powers (positive and negative) for positive definite matrices

```pascal
var
  M, PowerM: IMatrix;
begin
  // Integer power
  PowerM := M.Power(2);  // A^2
  
  // Fractional power (for positive definite matrices)
  PowerM := M.Power(0.5);   // A^(1/2) or square root of A
  PowerM := M.Power(-0.5);  // A^(-1/2) or inverse square root of A
end;
```

For fractional powers, the matrix must be positive definite to ensure real eigenvalues.
