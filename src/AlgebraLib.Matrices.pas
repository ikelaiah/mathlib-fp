unit AlgebraLib.Matrices;

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

{-----------------------------------------------------------------------------
 AlgebraLib.Matrices

 A comprehensive matrix algebra library for Free Pascal
 
 This unit provides:
 - Basic matrix operations (addition, subtraction, multiplication)
 - Matrix transformations (transpose, inverse)
 - Matrix properties (determinant, trace, rank)
 - Dense matrix implementation
 - Matrix decompositions (LU, QR)
 - Direct methods for solving linear systems
 - Basic statistical functions (mean, variance, covariance)
 
 Design principles:
 - Interface-based architecture for flexibility
 - Value semantics for matrix operations (operations return new matrices)
 - Focus on dense matrix representations
 - Numerically stable implementations of key algorithms
 - Comprehensive error checking and exception handling
 - Cache-aware optimizations for performance (see BLOCK_SIZE constant)
-----------------------------------------------------------------------------}

interface

uses
  Classes, SysUtils, Math, MathBase.SharedTypes;

const
  { Debug mode flag to enable additional debugging output }
  DEBUG_MODE = False;
  
  { Block size for optimized matrix multiplication using cache-aware blocking algorithm.
    Adjusting this value can significantly impact performance based on CPU cache size. }
  BLOCK_SIZE = 64;        // Tuned for L1 cache (64 doubles = 512 bytes per block face)
  THREAD_OPERATION_THRESHOLD = 262144; // 64x64x64 scalar multiply-adds
  MAX_MULTIPLY_THREADS = 8;

type
  { Exception type for matrix operation errors }
  EMatrixError = class(Exception);

type
  { 2D array of double values used as underlying storage for dense matrices }
  TMatrixArray = array of array of Double;

type
  { Forward declarations }
  IMatrix = interface;

type
  { Enum specifying iterative methods for solving linear systems
    - imConjugateGradient: Fast for symmetric positive definite matrices
    - imGaussSeidel: Typically converges faster than Jacobi
    - imJacobi: Simple, parallelizable method }
  TIterativeMethod = (imConjugateGradient, imGaussSeidel, imJacobi);

  { Record type representing an eigenvalue and its corresponding eigenvector
    Used in power iteration and eigenvalue computations }
  TEigenpair = record
    EigenValue: Double;
    EigenVector: IMatrix; // Column vector
    function ToString: string;
  end;

  { LU decomposition record
    Represents the factorization A = P^-1*L*U where:
    - L is lower triangular with unit diagonal
    - U is upper triangular
    - P is a permutation matrix (stored as array of indices) }
  TLUDecomposition = record
    L: IMatrix;
    U: IMatrix;
    P: array of Integer;
    function ToString: string;
  end;

  { QR decomposition record
    Represents the factorization A = Q*R where:
    - Q is orthogonal (Q*Q^T = I)
    - R is upper triangular
    Used for solving linear systems and least squares problems }
  TQRDecomposition = record
    Q: IMatrix;
    R: IMatrix;
    function ToString: string;
  end;

  { Eigendecomposition record
    Represents the factorization A = V*D*V^-1 where:
    - D is a diagonal matrix with eigenvalues
    - V contains the corresponding eigenvectors as columns
    Only valid for diagonalizable matrices }
  TEigenDecomposition = record
    EigenValues: array of Double;
    EigenVectors: IMatrix;
    function ToString: string;
  end;

  { Singular Value Decomposition (SVD) record
    Represents the factorization A = U*S*V^T where:
    - U and V are orthogonal matrices
    - S is a diagonal matrix of singular values
    Useful for pseudo-inverse, rank computation, and data analysis }
  TSVD = record
    U: IMatrix;  // Orthogonal matrix
    S: IMatrix;  // Diagonal matrix of singular values
    V: IMatrix;  // Orthogonal matrix
    function ToString: string;
  end;

  { Cholesky decomposition record
    Represents the factorization A = L*L^T where:
    - L is lower triangular
    Only valid for symmetric positive definite matrices
    Faster than LU decomposition when applicable }
  TCholeskyDecomposition = record
    L: IMatrix;  // Lower triangular matrix
    function ToString: string;
  end;

type
  { Matrix interface
    Defines the core functionality for all matrix implementations
    All operations return new matrices rather than modifying existing ones }
  IMatrix = interface
    ['{F8A7B320-7A1D-4E85-9B12-E77D2B5C8A9E}']
    {
      @description Gets the number of rows in the matrix.

      @usage Use to determine the vertical dimension of the matrix.

      @returns Integer representing the number of rows.

      @warning None.

      @example
        var NumRows: Integer;
        NumRows := MyMatrix.GetRows;
    }
    function GetRows: Integer;

    {
      @description Gets the number of columns in the matrix.

      @usage Use to determine the horizontal dimension of the matrix.

      @returns Integer representing the number of columns.

      @warning Returns 0 for an empty matrix (0 rows).

      @example
        var NumCols: Integer;
        NumCols := MyMatrix.GetCols;
    }
    function GetCols: Integer;

    {
      @description Retrieves the value of an element at a specific row and column.

      @usage Use to access individual matrix elements.

      @param Row The 0-based row index.
      @param Col The 0-based column index.

      @returns The Double value at the specified position.

      @warning Raises EMatrixError if indices are out of bounds.

      @example
        var Val: Double;
        Val := MyMatrix.GetValue(1, 2);
    }
    function GetValue(Row, Col: Integer): Double;

    {
      @description Sets the value of an element at a specific row and column.

      @usage Use to modify individual matrix elements.

      @param Row The 0-based row index.
      @param Col The 0-based column index.
      @param Value The new Double value to set.

      @warning Raises EMatrixError if indices are out of bounds.

      @example
        MyMatrix.SetValue(1, 2, 3.14);
    }
    procedure SetValue(Row, Col: Integer; const Value: Double);

    { Basic operations }
    {
      @description Performs element-wise addition of two matrices (A + B).

      @usage To add two matrices of the same dimensions.

      @param Other The matrix to add to the current matrix.

      @returns A new IMatrix containing the result of the addition.

      @warning Raises EMatrixError if matrix dimensions do not match.

      @example
        var SumMatrix: IMatrix;
        SumMatrix := MatrixA.Add(MatrixB);
    }
    function Add(const Other: IMatrix): IMatrix;

    {
      @description Performs element-wise subtraction of two matrices (A - B).

      @usage To subtract one matrix from another of the same dimensions.

      @param Other The matrix to subtract from the current matrix.

      @returns A new IMatrix containing the result of the subtraction.

      @warning Raises EMatrixError if matrix dimensions do not match.

      @example
        var DiffMatrix: IMatrix;
        DiffMatrix := MatrixA.Subtract(MatrixB);
    }
    function Subtract(const Other: IMatrix): IMatrix;

    {
      @description Performs matrix multiplication (A * B).

      @usage To multiply two compatible matrices.

      @param Other The right-hand side matrix for multiplication.

      @returns A new IMatrix containing the product.

      @warning Raises EMatrixError if the inner dimensions (Cols of A, Rows of B) do not match. Uses block multiplication for potential performance gains on larger matrices.

      @example
        var ProductMatrix: IMatrix;
        ProductMatrix := MatrixA.Multiply(MatrixB);
    }
    function Multiply(const Other: IMatrix): IMatrix;

    {
      @description Multiplies every element of the matrix by a scalar value (k * A).

      @usage To scale a matrix.

      @param Scalar The scalar value to multiply by.

      @returns A new IMatrix containing the scaled matrix.

      @warning None.

      @example
        var ScaledMatrix: IMatrix;
        ScaledMatrix := MyMatrix.ScalarMultiply(2.5);
    }
    function ScalarMultiply(const Scalar: Double): IMatrix;

    { Matrix transformations }
    {
      @description Computes the transpose of the matrix (A^T).

      @usage To swap rows and columns of a matrix.

      @returns A new IMatrix representing the transpose.

      @warning None.

      @example
        var TransposedMatrix: IMatrix;
        TransposedMatrix := MyMatrix.Transpose;
    }
    function Transpose: IMatrix;

    {
      @description Computes the inverse of a square matrix (A^-1).

      @usage To find the matrix B such that A * B = I (identity matrix).

      @returns A new IMatrix representing the inverse.

      @warning Raises EMatrixError if the matrix is not square or is singular (determinant is close to zero). Uses LU decomposition.

      @example
        var InverseMatrix: IMatrix;
        try
          InverseMatrix := MySquareMatrix.Inverse;
        except
          on E: EMatrixError do Writeln('Matrix is not invertible: ', E.Message);
        end;
    }
    function Inverse: IMatrix;

    {
      @description Computes the Moore-Penrose pseudoinverse (A^+).

      @usage To find a generalized inverse for non-square or singular matrices, often used in least-squares solutions.

      @returns A new IMatrix representing the pseudoinverse.

      @references Moore-Penrose pseudoinverse. Uses SVD.

      @warning Computationally more intensive than standard inverse.

      @example
        var PseudoInvMatrix: IMatrix;
        PseudoInvMatrix := MyMatrix.PseudoInverse;
    }
    function PseudoInverse: IMatrix;

    { Matrix functions }
    {
      @description Computes the matrix exponential (e^A) using a Taylor series expansion.

      @usage In solving systems of linear differential equations.

      @returns A new IMatrix representing the matrix exponential.

      @references Taylor series expansion: e^A = I + A + A^2/2! + A^3/3! + ...

      @warning Requires a square matrix. The series approximation has limited terms (N=20), potentially affecting accuracy for some matrices.

      @example
        var ExpMatrix: IMatrix;
        ExpMatrix := MySquareMatrix.Exp;
    }
    function Exp: IMatrix;  // Matrix exponential

    {
      @description Computes the matrix power (A^p) for a real exponent p.

      @usage To raise a matrix to a given power.

      @param exponent The power (can be integer or real).

      @returns A new IMatrix representing A raised to the power p.

      @warning Requires a square matrix. Non-integer powers require a symmetric positive-definite matrix and use its eigendecomposition. Negative integer powers use the inverse. Raises EMatrixError when these requirements are not met.

      @example
        var MatrixSquared, MatrixSqrt, MatrixInv: IMatrix;
        MatrixSquared := MySquareMatrix.Power(2);
        MatrixSqrt := MySquareMatrix.Power(0.5);
        MatrixInv := MySquareMatrix.Power(-1); // Equivalent to Inverse
    }
    function Power(exponent: Double): IMatrix;

    { Matrix properties }
    {
      @description Computes the determinant of a square matrix.

      @usage To find a scalar value representing properties of a linear transformation, check invertibility.

      @returns The determinant value (Double).

      @warning Raises EMatrixError if the matrix is not square. Matrices of
      size 3 and above use LU decomposition; singular matrices return zero.

      @example
        var Det: Double;
        Det := MySquareMatrix.Determinant;
        if Abs(Det) < 1E-12 then Writeln('Matrix might be singular');
    }
    function Determinant: Double;

    {
      @description Computes the trace of a square matrix (sum of diagonal elements).

      @usage In various matrix analysis contexts, related to the sum of eigenvalues.

      @returns The trace value (Double).

      @warning Raises EMatrixError if the matrix is not square.

      @example
        var Tr: Double;
        Tr := MySquareMatrix.Trace;
    }
    function Trace: Double;

    {
      @description Computes the rank of the matrix (number of linearly independent rows or columns).

      @usage To determine the dimensionality of the vector space spanned by the matrix's rows or columns.

      @returns The rank (Integer).

      @references Uses Gaussian elimination to find row echelon form.

      @warning Uses a matrix-scale-relative tolerance based on machine precision. Numerically borderline matrices can still have application-dependent rank.

      @example
        var Rnk: Integer;
        Rnk := MyMatrix.Rank;
    }
    function Rank: Integer;

    {
      @description Checks if the matrix is square (number of rows equals number of columns).

      @usage To verify if operations requiring square matrices (like determinant, inverse, trace) are applicable.

      @returns True if the matrix is square, False otherwise.

      @warning None.

      @example
        if MyMatrix.IsSquare then
          // Proceed with square-matrix operations
    }
    function IsSquare: Boolean;

    {
      @description Checks if the matrix is symmetric (A = A^T).

      @usage To verify symmetry, required for certain algorithms like Cholesky decomposition.

      @returns True if the matrix is symmetric, False otherwise.

      @warning Requires a square matrix. Uses direct element comparison (A[i,j] = A[j,i]), floating-point inaccuracies might affect results for near-symmetric matrices. Consider using a tolerance check if needed.

      @example
        if MyMatrix.IsSymmetric then
          // Matrix is symmetric
    }
    function IsSymmetric: Boolean;

    {
      @description Checks if the matrix is diagonal (non-zero elements only on the main diagonal).

      @usage To identify diagonal matrices, which have simpler properties.

      @returns True if the matrix is diagonal, False otherwise.

      @warning Requires a square matrix. Checks if off-diagonal elements are exactly zero.

      @example
        if MyMatrix.IsDiagonal then
          // Matrix is diagonal
    }
    function IsDiagonal: Boolean;

    {
      @description Checks if the matrix is triangular (upper or lower).

      @usage To identify triangular matrices, useful in solving linear systems.

      @param Upper If True (default), checks for upper triangular (zeros below diagonal). If False, checks for lower triangular (zeros above diagonal).

      @returns True if the matrix is triangular of the specified type, False otherwise.

      @warning Requires a square matrix. Checks if relevant off-diagonal elements are exactly zero.

      @example
        if MyMatrix.IsTriangular(True) then Writeln('Upper triangular');
        if MyMatrix.IsTriangular(False) then Writeln('Lower triangular');
    }
    function IsTriangular(Upper: Boolean = True): Boolean;

    {
      @description Checks if the matrix is positive definite.

      @usage Required for Cholesky decomposition. Indicates certain properties related to eigenvalues and quadratic forms (x^T*A*x > 0).

      @returns True if the matrix is symmetric and positive definite, False otherwise.

      @warning Requires a square, symmetric matrix. The implementation verifies positive definiteness by attempting a Cholesky decomposition.

      @example
        // Positive definiteness is checked through Cholesky decomposition.
        if MyMatrix.IsPositiveDefinite then
           // Matrix is symmetric positive definite.
    }
    function IsPositiveDefinite: Boolean;

    {
      @description Checks if the matrix is positive semidefinite.

      @usage In optimization and statistics. Indicates properties related to eigenvalues and quadratic forms (x^T*A*x >= 0).

      @returns True if the matrix is symmetric and positive semidefinite, False otherwise.

      @warning Requires a square, symmetric matrix. Eigenvalues within 1E-9 of zero are treated as zero.

      @example
        // Positive semidefiniteness is checked from the real eigenvalues.
        if MyMatrix.IsPositiveSemidefinite then
          // Matrix has no eigenvalue below the negative tolerance.
    }
    function IsPositiveSemidefinite: Boolean;

    {
      @description Checks if the matrix is orthogonal (A^T * A = I).

      @usage To identify matrices that preserve vector lengths and angles under transformation (rotations, reflections).

      @returns True if the matrix is orthogonal, False otherwise.

      @warning Requires a square matrix. Computes A * A^T and compares it to the identity matrix using a tolerance (1E-12).

      @example
        if MyMatrix.IsOrthogonal then
          // Matrix represents an orthogonal transformation
    }
    function IsOrthogonal: Boolean;

    {
      @description Computes the condition number of the matrix (using the 1-norm).

      @usage To estimate the sensitivity of the solution of a linear system Ax=b to changes in A or b. High condition numbers indicate ill-conditioning.

      @returns The condition number (||A||₁ * ||A⁻¹||₁). Returns MaxDouble if the matrix is singular.

      @warning Requires a square matrix. Based on the 1-norm. Calculation involves matrix inversion, which can be computationally intensive and potentially unstable for ill-conditioned matrices.

      @example
        var CondNum: Double;
        CondNum := MySquareMatrix.Condition;
        if CondNum > 1000 then Writeln('Warning: Matrix might be ill-conditioned');
    }
    function Condition: Double;

    { Vector operations }
    {
      @description Checks if the matrix represents a vector (has only one row or one column).

      @usage To determine if vector-specific operations (like dot product, cross product, normalization) are applicable.

      @returns True if the matrix has 1 row or 1 column, False otherwise.

      @warning None.

      @example
        if MyMatrix.IsVector then
          // Treat as a vector
    }
    function IsVector: Boolean;

    {
      @description Checks if the matrix represents a column vector (has only one column).

      @usage To identify column vectors specifically.

      @returns True if the matrix has 1 column, False otherwise.

      @warning None.

      @example
        if MyMatrix.IsColumnVector then
          // It's a column vector
    }
    function IsColumnVector: Boolean;

    {
      @description Checks if the matrix represents a row vector (has only one row).

      @usage To identify row vectors specifically.

      @returns True if the matrix has 1 row, False otherwise.

      @warning None.

      @example
        if MyMatrix.IsRowVector then
          // It's a row vector
    }
    function IsRowVector: Boolean;

    {
      @description Computes the dot product (scalar product) of two vectors.

      @usage To calculate the projection of one vector onto another, or in various geometric and algebraic formulas.

      @param Other The second vector for the dot product.

      @returns The scalar result of the dot product.

      @warning Raises EMatrixError if either operand is not a vector or if dimensions are incompatible for dot product (e.g., row vector dot column vector requires matching inner dimension).

      @example
        var DotRes: Double;
        DotRes := VectorA.DotProduct(VectorB);
    }
    function DotProduct(const Other: IMatrix): Double;

    {
      @description Computes the cross product of two 3D column vectors.

      @usage In 3D geometry and physics to find a vector perpendicular to two given vectors.

      @param Other The second 3D column vector.

      @returns A new 3D column vector representing the cross product.

      @warning Raises EMatrixError if either operand is not a 3D column vector.

      @example
        var CrossVec: IMatrix;
        CrossVec := Vector3DA.CrossProduct(Vector3DB);
    }
    function CrossProduct(const Other: IMatrix): IMatrix; // For 3D vectors

    {
      @description Normalizes a vector to have unit length (Euclidean norm = 1).

      @usage To obtain a unit vector pointing in the same direction as the original vector.

      @returns A new IMatrix representing the normalized vector.

      @warning Raises EMatrixError if the input is not a vector or if it's a zero vector (cannot normalize).

      @example
        var UnitVec: IMatrix;
        UnitVec := MyVector.Normalize;
    }
    function Normalize: IMatrix;

    { Statistical operations }
    {
      @description Computes the mean of matrix elements along a specified axis.

      @usage To find the average value(s) of the matrix data.

      @param Axis Axis along which to compute the mean: -1 for overall mean (returns 1x1 matrix), 0 for column means (returns 1xCols matrix), 1 for row means (returns Rowsx1 matrix). Default is -1.

      @returns An IMatrix containing the mean(s).

      @warning Raises EMatrixError if Axis value is invalid.

      @example
        var OverallMean, ColMeans, RowMeans: IMatrix;
        OverallMean := MyDataMatrix.Mean(-1); // Or MyDataMatrix.Mean
        ColMeans := MyDataMatrix.Mean(0);
        RowMeans := MyDataMatrix.Mean(1);
    }
    function Mean(Axis: Integer = -1): IMatrix; // -1 = overall, 0 = rows, 1 = columns

    {
      @description Computes the sample covariance matrix of the data.

      @usage To measure how much variables change together. Assumes rows are observations and columns are variables.

      @returns A new square IMatrix (Cols x Cols) representing the covariance matrix.

      @warning Raises EMatrixError if the matrix has fewer than 2 rows or 2 columns. Uses N-1 in the denominator for sample covariance.

      @example
        var CovMat: IMatrix;
        CovMat := MyDataMatrix.Covariance;
    }
    function Covariance: IMatrix;

    {
      @description Computes the sample correlation matrix of the data.

      @usage To measure the linear correlation between variables, scaled between -1 and 1. Assumes rows are observations and columns are variables.

      @returns A new square IMatrix (Cols x Cols) representing the correlation matrix.

      @warning Raises EMatrixError if the matrix has fewer than 2 rows or 2 columns. Derived from the covariance matrix. Values are 0 if standard deviation of a variable is zero.

      @example
        var CorrMat: IMatrix;
        CorrMat := MyDataMatrix.Correlation;
    }
    function Correlation: IMatrix;

    { Matrix norms }
    {
      @description Computes the 1-norm (maximum absolute column sum) of the matrix.

      @usage As a measure of matrix magnitude, often used in condition number estimation.

      @returns The 1-norm value (Double).

      @warning None.

      @example
        var Norm1: Double;
        Norm1 := MyMatrix.NormOne;
    }
    function NormOne: Double;     // Column sum norm

    {
      @description Computes the infinity-norm (maximum absolute row sum) of the matrix.

      @usage As a measure of matrix magnitude.

      @returns The infinity-norm value (Double).

      @warning None.

      @example
        var NormInfVal: Double;
        NormInfVal := MyMatrix.NormInf;
    }
    function NormInf: Double;     // Row sum norm

    {
      @description Computes the Frobenius norm of the matrix (sqrt of sum of squares of elements).

      @usage As a measure of matrix magnitude, equivalent to Euclidean norm of the matrix treated as a vector.

      @returns The Frobenius norm value (Double).

      @warning None.

      @example
        var NormFrob: Double;
        NormFrob := MyMatrix.NormFrobenius;
    }
    function NormFrobenius: Double; // Frobenius norm

    { Matrix decompositions }
    {
      @description Computes the LU decomposition of a square matrix with partial pivoting (PA = LU).

      @usage To solve linear systems (Ax=b), compute determinants, and inverses efficiently.

      @returns A TLUDecomposition record containing L (lower triangular), U (upper triangular), and P (permutation indices).

      @references Gaussian elimination with partial pivoting.

      @warning Raises EMatrixError if the matrix is not square or is singular (detected during pivoting).

      @example
        var LUResult: TLUDecomposition;
        try
          LUResult := MySquareMatrix.LU;
          // Use LUResult.L, LUResult.U, LUResult.P
        except
          on E: EMatrixError do Writeln('LU decomposition failed: ', E.Message);
        end;
    }
    function LU: TLUDecomposition;

    {
      @description Computes the QR decomposition of a matrix (A = QR).

      @usage To solve linear systems, least-squares problems, and in eigenvalue algorithms (QR algorithm).

      @returns A TQRDecomposition record containing Q (orthogonal matrix) and R (upper triangular matrix).

      @references Gram-Schmidt orthogonalization process (current implementation). Householder reflections are often preferred for numerical stability.

      @warning Raises EMatrixError if matrix columns are linearly dependent (detected during normalization in Gram-Schmidt). Gram-Schmidt can be sensitive to numerical errors.

      @example
        var QRResult: TQRDecomposition;
        try
          QRResult := MyMatrix.QR;
          // Use QRResult.Q, QRResult.R
        except
          on E: EMatrixError do Writeln('QR decomposition failed: ', E.Message);
        end;
    }
    function QR: TQRDecomposition;

    {
      @description Computes the eigendecomposition of a square matrix (A = VDV⁻¹).

      @usage To find eigenvalues and eigenvectors, used in stability analysis, PCA, etc.

      @returns A TEigenDecomposition record containing EigenValues (array of Double) and EigenVectors (matrix with eigenvectors as columns).

      @references Uses the Jacobi rotation algorithm for real symmetric matrices
      and direct analytical calculation for real 2x2 matrices.

      @warning Raises EMatrixError for non-square matrices, complex spectra,
      defective 2x2 matrices, non-symmetric matrices larger than 2x2, or if
      the Jacobi iteration does not converge. Eigenvectors of symmetric
      matrices are returned as orthonormal columns.

      @example
        var EigResult: TEigenDecomposition;
        try
          EigResult := MySquareMatrix.EigenDecomposition;
          // Use EigResult.EigenValues, EigResult.EigenVectors
        except
          on E: EMatrixError do Writeln('Eigendecomposition failed: ', E.Message);
        end;
    }
    function EigenDecomposition: TEigenDecomposition;

    {
      @description Computes the Singular Value Decomposition (SVD) of a matrix (A = USV^T).

      @usage For pseudoinverse calculation, rank determination, dimensionality reduction (PCA), least-squares, data analysis.

      @returns A TSVD record containing U (orthogonal), S (diagonal with singular values), and V (orthogonal).

      @references Algorithm based on Householder reduction to bidiagonal form followed by QR-like iteration. (e.g., Numerical Recipes).

      @warning Can be computationally intensive. Iterative part might fail to converge (raises EMatrixError). Uses tolerance (1E-12).

      @example
        var SVDResult: TSVD;
        try
          SVDResult := MyMatrix.SVD;
          // Use SVDResult.U, SVDResult.S, SVDResult.V
        except
          on E: EMatrixError do Writeln('SVD failed: ', E.Message);
        end;
    }
    function SVD: TSVD;

    {
      @description Computes the Cholesky decomposition of a symmetric positive definite matrix (A = LL^T).

      @usage A fast method for solving linear systems (Ax=b) and checking positive definiteness when applicable.

      @returns A TCholeskyDecomposition record containing L (lower triangular matrix).

      @references Cholesky–Banachiewicz algorithm.

      @warning Raises EMatrixError if the matrix is not square, symmetric, or positive definite.

      @example
        var CholResult: TCholeskyDecomposition;
        try
          CholResult := MySymPosDefMatrix.Cholesky;
          // Use CholResult.L
        except
          on E: EMatrixError do Writeln('Cholesky decomposition failed: ', E.Message);
        end;
    }
    function Cholesky: TCholeskyDecomposition;

    { Iterative methods }
    {
      @description Solves a linear system Ax = b using iterative methods.

      @usage For large, sparse systems where direct methods (like LU or QR) are too slow or memory-intensive. Suitable for well-conditioned systems.

      @param B The right-hand side column vector (matrix with 1 column).
      @param Method The iterative method to use (imConjugateGradient, imGaussSeidel, imJacobi). Default is imConjugateGradient.
      @param MaxIterations Maximum number of iterations allowed. Default is 1000.
      @param Tolerance Convergence tolerance based on relative residual norm. Default is 1E-10.

      @returns An IMatrix (column vector) representing the approximate solution x.

      @warning Requires a square matrix A. B must be a column vector with matching rows. Convergence is not guaranteed for all matrices or methods (especially Jacobi and Gauss-Seidel). Conjugate Gradient requires A to be symmetric positive definite for guaranteed convergence. Raises EMatrixError if diagonal elements are near zero for Jacobi/Gauss-Seidel or if MaxIterations is reached without convergence.

      @example
        var X, B: IMatrix;
        // Assume A is a large square matrix, B is a column vector
        try
          X := A.SolveIterative(B, imGaussSeidel, 5000, 1e-8);
          // Use solution X
        except
          on E: EMatrixError do Writeln('Iterative solve failed: ', E.Message);
        end;
    }
    function SolveIterative(
      const B: IMatrix;
      Method: TIterativeMethod = imConjugateGradient;
      MaxIterations: Integer = 1000;
      Tolerance: Double = 1e-10): IMatrix;

    {
      @description Finds the dominant eigenvalue (largest magnitude) and corresponding eigenvector using the Power Iteration method.

      @usage To estimate the principal eigenvalue/eigenvector, e.g., in ranking algorithms or stability analysis.

      @param MaxIterations Maximum number of iterations. Default is 100.
      @param Tolerance Convergence tolerance based on change in eigenvalue estimate. Default is 1E-10.

      @returns A TEigenpair record containing the dominant EigenValue and normalized EigenVector.

      @warning Requires a square matrix, positive MaxIterations and positive
      Tolerance. Convergence is guaranteed only if there is a unique dominant
      eigenvalue and the deterministic initial vector has a component in the
      direction of the corresponding eigenvector. Raises EMatrixError if
      normalization fails or convergence is not reached.

      @example
        var EigPair: TEigenpair;
        try
          EigPair := MySquareMatrix.PowerMethod(200, 1e-9);
          Writeln('Dominant Eigenvalue: ', EigPair.EigenValue);
          // Use EigPair.EigenVector
        except
          on E: EMatrixError do Writeln('Power method failed: ', E.Message);
        end;
    }
    function PowerMethod(MaxIterations: Integer = 100; Tolerance: Double = 1e-10): TEigenpair;

    { Block operations }
    {
      @description Extracts a submatrix (block) from the current matrix.

      @usage To work with parts of a larger matrix.

      @param StartRow 0-based starting row index.
      @param StartCol 0-based starting column index.
      @param NumRows Number of rows in the submatrix.
      @param NumCols Number of columns in the submatrix.

      @returns A new IMatrix containing the extracted submatrix.

      @warning Raises EMatrixError if the specified dimensions are invalid or extend beyond the original matrix boundaries.

      @example
        var SubMat: IMatrix;
        SubMat := MyMatrix.GetSubMatrix(1, 1, 2, 2); // Extracts the 2x2 block starting at (1,1)
    }
    function GetSubMatrix(StartRow, StartCol, NumRows, NumCols: Integer): IMatrix;

    {
      @description Overwrites a block within the current matrix with the values from another matrix.

      @usage To insert or replace a part of a matrix.

      @param StartRow 0-based starting row index in the destination matrix.
      @param StartCol 0-based starting column index in the destination matrix.
      @param SubMatrix The matrix whose values will be copied into the block.

      @warning Raises EMatrixError if the submatrix dimensions plus start indices extend beyond the destination matrix boundaries. Modifies the current matrix in place.

      @example
        var BlockToInsert: IMatrix;
        BlockToInsert := TMatrixKit.Ones(2, 2);
        MyMatrix.SetSubMatrix(0, 0, BlockToInsert); // Overwrites top-left 2x2 block with ones
    }
    procedure SetSubMatrix(StartRow, StartCol: Integer; const SubMatrix: IMatrix);

    { Element-wise operations }
    {
      @description Performs element-wise multiplication (Hadamard product) of two matrices (C[i,j] = A[i,j] * B[i,j]).

      @usage In various algorithms where element-by-element products are needed.

      @param Other The second matrix for element-wise multiplication.

      @returns A new IMatrix containing the element-wise product.

      @warning Raises EMatrixError if matrix dimensions do not match.

      @example
        var HadamardProduct: IMatrix;
        HadamardProduct := MatrixA.ElementWiseMultiply(MatrixB);
    }
    function ElementWiseMultiply(const Other: IMatrix): IMatrix;

    {
      @description Performs element-wise division of two matrices (C[i,j] = A[i,j] / B[i,j]).

      @usage Where element-by-element division is required.

      @param Other The matrix containing the divisors.

      @returns A new IMatrix containing the element-wise division result.

      @warning Raises EMatrixError if matrix dimensions do not match or if any element in the Other matrix is exactly zero.

      @example
        var ElementWiseQuotient: IMatrix;
        try
          ElementWiseQuotient := MatrixA.ElementWiseDivide(MatrixB);
        except
          on E: EMatrixError do Writeln('Element-wise division failed: ', E.Message);
        end;
    }
    function ElementWiseDivide(const Other: IMatrix): IMatrix;

    { String representation }
    {
      @description Creates a string representation of the matrix for display.

      @usage For debugging or printing matrix contents.

      @returns A string with matrix elements formatted and aligned in columns.

      @warning Formatting includes trimming trailing zeros from floating-point numbers. Column widths adjust to the widest number in each column.

      @example
        Writeln(MyMatrix.ToString);
    }
    function ToString: string;

    property Rows: Integer read GetRows;
    property Cols: Integer read GetCols;
    property Values[Row, Col: Integer]: Double read GetValue write SetValue; default;
  end;

type
  { Matrix implementation }
  TMatrixKit = class(TInterfacedObject, IMatrix)
  private
    { Underlying 2D array to store matrix elements in dense format }
    FData: array of array of Double;

    { Basic accessor methods }
    {
      @description Gets the number of rows in the matrix. Implementation for TMatrixKit.

      @usage Internal use and via IMatrix interface.

      @returns Integer representing the number of rows.

      @warning None.

      @example (Internal) Result := Length(FData);
    }
    function GetRows: Integer;

    {
      @description Gets the number of columns in the matrix. Implementation for TMatrixKit.

      @usage Internal use and via IMatrix interface.

      @returns Integer representing the number of columns.

      @warning Returns 0 if the matrix has 0 rows.

      @example (Internal) Result := Length(FData[0]);
    }
    function GetCols: Integer;

    {
      @description Retrieves the value of an element at a specific row and column. Implementation for TMatrixKit.

      @usage Internal use and via IMatrix interface. Accesses the FData array directly.

      @param Row The 0-based row index.
      @param Col The 0-based column index.

      @returns The Double value at the specified position.

      @warning Raises EMatrixError if indices are out of bounds.

      @example (Internal) Result := FData[Row, Col];
    }
    function GetValue(Row, Col: Integer): Double; virtual;

    {
      @description Sets the value of an element at a specific row and column. Implementation for TMatrixKit.

      @usage Internal use and via IMatrix interface. Modifies the FData array directly.

      @param Row The 0-based row index.
      @param Col The 0-based column index.
      @param Value The new Double value to set.

      @warning Raises EMatrixError if indices are out of bounds.

      @example (Internal) FData[Row, Col] := Value;
    }
    procedure SetValue(Row, Col: Integer; const Value: Double); virtual;

    { Helper methods for numerical algorithms }
    {
      @description Swaps two rows in the matrix data array (FData).

      @usage Internal helper for algorithms requiring row pivoting (e.g., Gaussian elimination, LU decomposition). Modifies the matrix in place.

      @param Row1 Index of the first row to swap.
      @param Row2 Index of the second row to swap.

      @warning Raises EMatrixError if row indices are invalid. Modifies the internal FData directly.

      @example (Internal) Self.SwapRows(0, 1);
    }
    procedure SwapRows(Row1, Row2: Integer);

    {
      @description Finds the index of the row (from StartRow downwards) containing the element with the largest absolute value in a specific column.

      @usage Internal helper for partial pivoting in algorithms like LU decomposition to improve numerical stability.

      @param StartRow The starting row index for the search.
      @param Col The column index to search within.

      @returns The 0-based index of the pivot row.

      @warning Assumes StartRow and Col are valid indices within the matrix dimensions.

      @example (Internal) PivotIdx := Self.FindPivot(K, K);
    }
    function FindPivot(StartRow, Col: Integer): Integer;

    {
      @description Solves an upper triangular linear system Ux = b using back substitution.

      @usage Internal helper, typically used after obtaining U from LU or QR decomposition.

      @param Upper An IMatrix representing the upper triangular matrix U.
      @param b A dynamic array of Double representing the right-hand side vector b.

      @returns A dynamic array of Double representing the solution vector x.

      @warning Assumes Upper is upper triangular and square and dimensions match b. Raises EMatrixError for a scale-relative near-zero diagonal pivot.

      @example (Internal) X := Self.BackSubstitution(LUResult.U, Y); // Where Y = L^-1 * b
    }
    function BackSubstitution(const Upper: IMatrix; const b: TDoubleArray): TDoubleArray;

    {
      @description Solves a lower triangular linear system Lx = b using forward substitution.

      @usage Internal helper, typically used with L from LU or Cholesky decomposition.

      @param Lower An IMatrix representing the lower triangular matrix L.
      @param b A dynamic array of Double representing the right-hand side vector b.

      @returns A dynamic array of Double representing the solution vector x.

      @warning Assumes Lower is lower triangular and square and dimensions match b. Raises EMatrixError for a scale-relative near-zero diagonal pivot.

      @example (Internal) Y := Self.ForwardSubstitution(LUResult.L, PermutedB);
    }
    function ForwardSubstitution(const Lower: IMatrix; const b: TDoubleArray): TDoubleArray;

    {
      @description Computes the dot product of two vectors represented as dynamic arrays of Double.

      @usage Internal helper function for various calculations involving vector dot products.

      @param v1 The first vector (TDoubleArray).
      @param v2 The second vector (TDoubleArray).

      @returns The scalar dot product value.

      @warning Raises EMatrixError if the lengths of v1 and v2 do not match.

      @example (Internal) DotRes := Self.DotProduct(VectorData1, VectorData2);
    }
    function DotProduct(const v1, v2: TDoubleArray): Double;

    {
      @description Normalizes a specific column of a given TMatrixKit instance to unit Euclidean length. Modifies the matrix in place.

      @usage Internal helper, e.g., in Gram-Schmidt process (QR decomposition).

      @param Matrix The TMatrixKit instance to modify. Passed by var.
      @param Col The 0-based index of the column to normalize.

      @warning Raises EMatrixError if the column norm is close to zero (cannot normalize zero vector). Modifies the input Matrix directly.

      @example (Internal) Self.NormalizeColumn(QMatrix, J);
    }
    procedure NormalizeColumn(var Matrix: TMatrixKit; Col: Integer);
  public
    {
      @description Creates a new dense matrix instance with specified dimensions, initialized to zero.

      @usage To instantiate a new matrix object.

      @param ARows The number of rows for the new matrix.
      @param ACols The number of columns for the new matrix.

      @returns A new TMatrixKit instance.

      @warning Internal array allocation might fail for extremely large dimensions.

      @example
        var MyMatrix: TMatrixKit; // Or IMatrix
        MyMatrix := TMatrixKit.Create(3, 4);
        // Use MyMatrix...
        MyMatrix.Free; // If declared as TMatrixKit
    }
    constructor Create(const ARows, ACols: Integer);

    {
      @description Frees the memory allocated for the internal matrix data (FData).

      @usage Called automatically when the matrix object is destroyed (either via Free or interface reference counting).

      @warning None.

      @example
        var MyMatrix: TMatrixKit;
        MyMatrix := TMatrixKit.Create(5, 5);
        MyMatrix.Free; // Calls Destroy
    }
    destructor Destroy; override;

    { Static factory methods for creating various types of matrices }

    {
      @description Creates a new dense matrix from a 2D dynamic array of Double.

      @usage To initialize a matrix with predefined values from an array.

      @param Data A TMatrixArray (array of array of Double) containing the initial values.

      @returns A new IMatrix instance populated with the data.

      @warning Raises EMatrixError if the input array is empty or if rows have inconsistent lengths.

      @example
        var
          MatrixData: TMatrixArray;
          NewMatrix: IMatrix;
        begin
          SetLength(MatrixData, 2, 3);
          MatrixData[0, 0] := 1; MatrixData[0, 1] := 2; MatrixData[0, 2] := 3;
          MatrixData[1, 0] := 4; MatrixData[1, 1] := 5; MatrixData[1, 2] := 6;
          NewMatrix := TMatrixKit.CreateFromArray(MatrixData);
          // Use NewMatrix...
        end;
    }
    class function CreateFromArray(const Data: TMatrixArray): IMatrix;

    {
      @description Creates an identity matrix of a specified size.

      @usage To get a square matrix with ones on the diagonal and zeros elsewhere.

      @param Size The number of rows and columns for the identity matrix.

      @returns A new IMatrix instance representing the identity matrix.

      @warning Size must be non-negative.

      @example
        var IdentityMatrix: IMatrix;
        IdentityMatrix := TMatrixKit.Identity(3); // Creates a 3x3 identity matrix
    }
    class function Identity(const Size: Integer): IMatrix;

    {
      @description Creates a matrix of specified dimensions filled entirely with zeros.

      @usage To initialize a matrix with all zero elements.

      @param Rows The number of rows.
      @param Cols The number of columns.

      @returns A new IMatrix instance filled with zeros.

      @warning Dimensions must be non-negative.

      @example
        var ZeroMatrix: IMatrix;
        ZeroMatrix := TMatrixKit.Zeros(2, 3);
    }
    class function Zeros(const Rows, Cols: Integer): IMatrix;

    {
      @description Creates a matrix of specified dimensions filled entirely with ones.

      @usage To initialize a matrix with all elements set to one.

      @param Rows The number of rows.
      @param Cols The number of columns.

      @returns A new IMatrix instance filled with ones.

      @warning Dimensions must be non-negative.

      @example
        var OnesMatrix: IMatrix;
        OnesMatrix := TMatrixKit.Ones(4, 2);
    }
    class function Ones(const Rows, Cols: Integer): IMatrix;

    {
      @description Creates an empty sparse matrix instance with specified dimensions.

      @usage To initialize a sparse matrix structure, suitable for matrices with many zero elements. Use SetValue or AddElement to populate non-zero values.

      @param Rows The number of rows.
      @param Cols The number of columns.

      @returns A new IMatrix instance implemented as TMatrixKitSparse.

      @warning Dimensions must be non-negative.

      @example
        var SparseMat: IMatrix;
        SparseMat := TMatrixKit.CreateSparse(1000, 1000);
        SparseMat.SetValue(10, 20, 5.0); // Add a non-zero element
    }
    class function CreateSparse(Rows, Cols: Integer): IMatrix;

    {
      @description Creates a Hilbert matrix of a specified size. Hilbert matrices are known for being ill-conditioned.

      @usage Primarily for testing numerical algorithms on ill-conditioned matrices. H[i,j] = 1 / (i + j + 1) (using 0-based indexing).

      @param Size The number of rows and columns (must be positive).

      @returns A new IMatrix instance representing the Hilbert matrix.

      @warning Raises EMatrixError if Size is not positive. Becomes severely ill-conditioned even for moderate sizes.

      @example
        var HilbertMat: IMatrix;
        HilbertMat := TMatrixKit.CreateHilbert(5);
    }
    class function CreateHilbert(Size: Integer): IMatrix;

    {
      @description Creates a Toeplitz matrix defined by its first row and first column. A Toeplitz matrix has constant values along its diagonals.

      @usage In signal processing, linear systems, and other areas where diagonal-constant matrices arise.

      @param FirstRow A dynamic array of Double representing the first row.
      @param FirstCol A dynamic array of Double representing the first column.

      @returns A new IMatrix instance representing the Toeplitz matrix.

      @warning Raises EMatrixError if FirstRow or FirstCol are empty, or if FirstRow[0] <> FirstCol[0]. The dimensions of the resulting matrix are Length(FirstCol) x Length(FirstRow).

      @example
        var
          r, c: TDoubleArray;
          ToeplitzMat: IMatrix;
        begin
          SetLength(r, 4); r[0] := 1; r[1] := 2; r[2] := 3; r[3] := 4;
          SetLength(c, 3); c[0] := 1; c[1] := 5; c[2] := 6;
          ToeplitzMat := TMatrixKit.CreateToeplitz(r, c);
          // Results in a 3x4 matrix
        end;
    }
    class function CreateToeplitz(const FirstRow, FirstCol: TDoubleArray): IMatrix;

    {
      @description Creates a Vandermonde matrix from a given vector [x₁, x₂, ..., xₙ]. The matrix V has elements V[i,j] = xᵢʲ (using 0-based indexing for j).

      @usage In polynomial interpolation and fitting.

      @param Vector A dynamic array of Double [x₀, x₁, ..., xₙ₋₁].

      @returns A new NxN IMatrix instance representing the Vandermonde matrix.

      @warning Raises EMatrixError if the input Vector is empty. Can become ill-conditioned.

      @example
        var
          vec: TDoubleArray;
          VandermondeMat: IMatrix;
        begin
          SetLength(vec, 3); vec[0] := 1; vec[1] := 2; vec[2] := 3;
          VandermondeMat := TMatrixKit.CreateVandermonde(vec);
          // Results in [[1, 1, 1], [1, 2, 4], [1, 3, 9]]
        end;
    }
    class function CreateVandermonde(const Vector: TDoubleArray): IMatrix;

    { Interface implementations }

    {
      @description Performs element-wise addition (A + B). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other The matrix to add.

      @returns A new IMatrix containing the sum.

      @warning Raises EMatrixError if dimensions don't match.

      @example See IMatrix.Add example.
    }
    function Add(const Other: IMatrix): IMatrix;

    {
      @description Performs element-wise subtraction (A - B). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other The matrix to subtract.

      @returns A new IMatrix containing the difference.

      @warning Raises EMatrixError if dimensions don't match.

      @example See IMatrix.Subtract example.
    }
    function Subtract(const Other: IMatrix): IMatrix;

    {
      @description Performs matrix multiplication (A * B). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other The right-hand side matrix.

      @returns A new IMatrix containing the product.

      @warning Raises EMatrixError if inner dimensions don't match. Uses block multiplication heuristic based on BLOCK_SIZE constant.

      @example See IMatrix.Multiply example.
    }
    function Multiply(const Other: IMatrix): IMatrix;

    {
      @description Multiplies matrix by a scalar (k * A). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Scalar The scalar value.

      @returns A new IMatrix containing the scaled matrix.

      @warning None.

      @example See IMatrix.ScalarMultiply example.
    }
    function ScalarMultiply(const Scalar: Double): IMatrix;

    {
      @description Computes the transpose (A^T). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns A new IMatrix representing the transpose.

      @warning None.

      @example See IMatrix.Transpose example.
    }
    function Transpose: IMatrix;

    {
      @description Computes the inverse (A^-1). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns A new IMatrix representing the inverse.

      @warning Raises EMatrixError if not square or singular. Uses LU decomposition followed by solving AX=I column by column.

      @example See IMatrix.Inverse example.
    }
    function Inverse: IMatrix;

    {
      @description Computes the Moore-Penrose pseudoinverse (A^+). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns A new IMatrix representing the pseudoinverse.

      @warning Uses SVD, can be computationally intensive.

      @example See IMatrix.PseudoInverse example.
    }
    function PseudoInverse: IMatrix;

    {
      @description Computes the matrix exponential (e^A). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns A new IMatrix representing the matrix exponential.

      @warning Requires square matrix. Uses Taylor series approximation.

      @example See IMatrix.Exp example.
    }
    function Exp: IMatrix;

    {
      @description Computes the matrix power (A^p). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param exponent The power.

      @returns A new IMatrix representing A^p.

      @warning Requires a square matrix. Integer exponents use exponentiation
      by squaring (and inverse for negative integers). Non-integer exponents use
      symmetric eigendecomposition and require strictly positive eigenvalues.

      @example See IMatrix.Power example.
    }
    function Power(exponent: Double): IMatrix;

    {
      @description Computes the determinant. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The determinant value.

      @warning Requires a square matrix. Sizes 3 and above use LU decomposition.

      @example See IMatrix.Determinant example.
    }
    function Determinant: Double;

    {
      @description Computes the trace. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The trace value.

      @warning Requires square matrix.

      @example See IMatrix.Trace example.
    }
    function Trace: Double;

    {
      @description Computes the rank. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The rank value.

      @warning Uses Gaussian elimination with tolerance.

      @example See IMatrix.Rank example.
    }
    function Rank: Integer;

    {
      @description Checks if the matrix is square. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if square, False otherwise.

      @warning None.

      @example See IMatrix.IsSquare example.
    }
    function IsSquare: Boolean;

    {
      @description Computes LU decomposition. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns TLUDecomposition record.

      @warning Requires square matrix. Raises EMatrixError if singular.

      @example See IMatrix.LU example.
    }
    function LU: TLUDecomposition;

    {
      @description Computes QR decomposition. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns TQRDecomposition record.

      @warning Uses Gram-Schmidt, raises EMatrixError if columns are linearly dependent.

      @example See IMatrix.QR example.
    }
    function QR: TQRDecomposition;

    {
      @description Computes eigendecomposition. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns TEigenDecomposition record.

      @warning Requires square matrix. Uses QR algorithm (iterative, may not converge perfectly). Handles 2x2 case separately.

      @example See IMatrix.EigenDecomposition example.
    }
    function EigenDecomposition: TEigenDecomposition;

    {
      @description Computes Singular Value Decomposition (SVD). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns TSVD record.

      @warning Iterative algorithm, may raise EMatrixError on non-convergence.

      @example See IMatrix.SVD example.
    }
    function SVD: TSVD;

    {
      @description Computes Cholesky decomposition. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns TCholeskyDecomposition record.

      @warning Requires a symmetric positive-definite matrix. Raises EMatrixError otherwise.

      @example See IMatrix.Cholesky example.
    }
    function Cholesky: TCholeskyDecomposition;

    {
      @description Creates a string representation. Implementation for TMatrixKit.

      @usage Via IMatrix interface or directly.

      @returns Formatted string representation.

      @warning None.

      @example See IMatrix.ToString example.
    }
    function ToString: string; override;

    { Matrix norm functions }

    {
      @description Computes the 1-norm. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The 1-norm value.

      @warning None.

      @example See IMatrix.NormOne example.
    }
    function NormOne: Double;

    {
      @description Computes the infinity-norm. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The infinity-norm value.

      @warning None.

      @example See IMatrix.NormInf example.
    }
    function NormInf: Double;

    {
      @description Computes the Frobenius norm. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns The Frobenius norm value.

      @warning None.

      @example See IMatrix.NormFrobenius example.
    }
    function NormFrobenius: Double;

    { Additional specialized matrix constructors }

    {
      @description Creates a band matrix (square) with specified lower and upper bandwidths, initialized with ones in the band and zeros elsewhere.

      @usage To create matrices where non-zero elements are confined near the main diagonal.

      @param Size The number of rows and columns.
      @param LowerBand Width of the band below the main diagonal (non-negative).
      @param UpperBand Width of the band above the main diagonal (non-negative).

      @returns A new IMatrix instance representing the band matrix.

      @warning Raises EMatrixError if Size is non-positive or bands are negative. Elements within the band are initialized to 1.0.

      @example
        var BandMat: IMatrix;
        BandMat := TMatrixKit.CreateBandMatrix(5, 1, 1); // Creates a 5x5 tridiagonal matrix (initially with ones)
    }
    class function CreateBandMatrix(Size, LowerBand, UpperBand: Integer): IMatrix;

    {
      @description Creates a symmetric matrix from a 2D array, assuming the array provides at least the upper (or lower) triangular part including the diagonal.

      @usage To easily construct symmetric matrices by specifying only half the off-diagonal elements.

      @param Data A TMatrixArray representing (at least) the upper or lower triangle. The function uses Data[i,j] for i >= j and mirrors it for i < j.

      @returns A new IMatrix instance representing the symmetric matrix.

      @warning Raises EMatrixError if Data is empty, not square, or rows have inconsistent lengths. It specifically uses Data[i,j] and sets Matrix[j,i] = Data[i,j] for j < i. Ensure the input Data array is correctly populated.

      @example
        var
          LowerData: TMatrixArray;
          SymMatrix: IMatrix;
        begin
          SetLength(LowerData, 3, 3);
          LowerData[0, 0] := 1;
          LowerData[1, 0] := 2; LowerData[1, 1] := 4;
          LowerData[2, 0] := 3; LowerData[2, 1] := 5; LowerData[2, 2] := 6;
          SymMatrix := TMatrixKit.CreateSymmetric(LowerData);
          // Result: [[1, 2, 3], [2, 4, 5], [3, 5, 6]]
        end;
    }
    class function CreateSymmetric(const Data: TMatrixArray): IMatrix;

    {
      @description Creates a diagonal matrix from a vector containing the diagonal elements.

      @usage To quickly create a matrix with specified diagonal values and zeros elsewhere.

      @param Diagonal A dynamic array of Double containing the values for the main diagonal.

      @returns A new square IMatrix instance representing the diagonal matrix.

      @warning Raises EMatrixError if the Diagonal array is empty. The size of the matrix is determined by the length of the Diagonal array.

      @example
        var
          diagVals: TDoubleArray;
          DiagMatrix: IMatrix;
        begin
          SetLength(diagVals, 3); diagVals[0] := 1; diagVals[1] := 5; diagVals[2] := 9;
          DiagMatrix := TMatrixKit.CreateDiagonal(diagVals);
          // Result: [[1, 0, 0], [0, 5, 0], [0, 0, 9]]
        end;
    }
    class function CreateDiagonal(const Diagonal: array of Double): IMatrix;

    {
      @description Creates a matrix of specified dimensions filled with random floating-point values uniformly distributed within a given range [Min, Max).

      @usage For initializing matrices with random data for testing or simulation purposes.

      @param Rows The number of rows.
      @param Cols The number of columns.
      @param Min The minimum value (inclusive).
      @param Max The maximum value (exclusive).

      @returns A new IMatrix instance filled with random values.

      @warning Raises EMatrixError if dimensions or bounds are invalid. The
      compatibility overload uses the caller-managed global random generator;
      it never calls Randomize internally. Use the Seed overload for a
      reproducible result that does not mutate global random state.

      @example
        var RandomMatrix: IMatrix;
        RandomMatrix := TMatrixKit.CreateRandom(3, 3, -1.0, 1.0); // 3x3 matrix with values between -1 and 1
    }
    class function CreateRandom(Rows, Cols: Integer;
      Min, Max: Double): IMatrix; overload;
    class function CreateRandom(Rows, Cols: Integer;
      Min, Max: Double; Seed: LongWord): IMatrix; overload;

    { Vector-related functions }

    {
      @description Checks if matrix is a vector. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if 1 row or 1 column, False otherwise.

      @warning None.

      @example See IMatrix.IsVector example.
    }
    function IsVector: Boolean;

    {
      @description Checks if matrix is a column vector. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if 1 column, False otherwise.

      @warning None.

      @example See IMatrix.IsColumnVector example.
    }
    function IsColumnVector: Boolean;

    {
      @description Checks if matrix is a row vector. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if 1 row, False otherwise.

      @warning None.

      @example See IMatrix.IsRowVector example.
    }
    function IsRowVector: Boolean;

    {
      @description Computes dot product between two vectors. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other The second vector.

      @returns The scalar dot product.

      @warning Raises EMatrixError if operands are not vectors or dimensions are incompatible. Handles row/column combinations.

      @example See IMatrix.DotProduct example.
    }
    function DotProduct(const Other: IMatrix): Double;

    {
      @description Computes cross product between two 3D vectors. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other The second 3D column vector.

      @returns A new 3D column vector cross product.

      @warning Raises EMatrixError if inputs aren't 3D column vectors.

      @example See IMatrix.CrossProduct example.
    }
    function CrossProduct(const Other: IMatrix): IMatrix;

    {
      @description Normalizes a vector to unit length. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns A new normalized vector.

      @warning Raises EMatrixError if not a vector or if it's a zero vector.

      @example See IMatrix.Normalize example.
    }
    function Normalize: IMatrix;

    { Statistical functions }

    {
      @description Computes mean value(s). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Axis Axis for mean calculation (-1, 0, or 1).

      @returns Matrix containing the mean(s).

      @warning Raises EMatrixError for invalid Axis.

      @example See IMatrix.Mean example.
    }
    function Mean(Axis: Integer = -1): IMatrix;

    {
      @description Computes covariance matrix. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns Covariance matrix.

      @warning Raises EMatrixError if fewer than 2 rows or 2 columns. Assumes columns are variables.

      @example See IMatrix.Covariance example.
    }
    function Covariance: IMatrix;

    {
      @description Computes correlation matrix. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns Correlation matrix.

      @warning Raises EMatrixError if fewer than 2 rows or 2 columns. Assumes columns are variables.

      @example See IMatrix.Correlation example.
    }
    function Correlation: IMatrix;

    { Iterative solvers for large systems }

    {
      @description Solves Ax = b using iterative methods. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param B Right-hand side vector.
      @param Method Iterative method choice.
      @param MaxIterations Max iterations.
      @param Tolerance Convergence tolerance.

      @returns Approximate solution vector x.

      @warning Requires square A, column vector B. Convergence not guaranteed for all methods/matrices. See IMatrix.SolveIterative warnings.

      @example See IMatrix.SolveIterative example.
    }
    function SolveIterative(
      const B: IMatrix;
      Method: TIterativeMethod = imConjugateGradient;
      MaxIterations: Integer = 1000;
      Tolerance: Double = 1e-10): IMatrix;

    {
      @description Finds dominant eigenvalue/eigenvector using power iteration. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param MaxIterations Max iterations.
      @param Tolerance Convergence tolerance.

      @returns TEigenpair with dominant eigenvalue/eigenvector.

      @warning Requires square matrix. Convergence depends on eigenvalue distribution. See IMatrix.PowerMethod warnings.

      @example See IMatrix.PowerMethod example.
    }
    function PowerMethod(MaxIterations: Integer = 100; Tolerance: Double = 1e-10): TEigenpair;

    { Additional matrix properties }

    {
      @description Checks if matrix is symmetric. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if symmetric, False otherwise.

      @warning Requires square matrix. Uses exact comparison.

      @example See IMatrix.IsSymmetric example.
    }
    function IsSymmetric: Boolean;

    {
      @description Checks if matrix is diagonal. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if diagonal, False otherwise.

      @warning Requires square matrix. Uses exact comparison for off-diagonal zeros.

      @example See IMatrix.IsDiagonal example.
    }
    function IsDiagonal: Boolean;

    {
      @description Checks if matrix is triangular. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Upper True for upper, False for lower.

      @returns True if triangular of specified type, False otherwise.

      @warning Requires square matrix. Uses exact comparison for off-diagonal zeros.

      @example See IMatrix.IsTriangular example.
    }
    function IsTriangular(Upper: Boolean = True): Boolean;

    {
      @description Checks if matrix is positive definite. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if potentially positive definite, False otherwise.

      @warning Requires a square, symmetric matrix. Returns False when Cholesky decomposition fails.

      @example See IMatrix.IsPositiveDefinite example.
    }
    function IsPositiveDefinite: Boolean;

    {
      @description Checks if matrix is positive semidefinite. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if potentially positive semidefinite, False otherwise.

      @warning Requires a square, symmetric matrix. Uses eigenvalue tolerance 1E-9.

      @example See IMatrix.IsPositiveSemidefinite example.
    }
    function IsPositiveSemidefinite: Boolean;

    {
      @description Checks if matrix is orthogonal. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns True if orthogonal within tolerance, False otherwise.

      @warning Requires square matrix. Computes A*A^T and compares to I with tolerance.

      @example See IMatrix.IsOrthogonal example.
    }
    function IsOrthogonal: Boolean;

    {
      @description Computes condition number (1-norm). Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @returns Condition number or MaxDouble if singular.

      @warning Requires square matrix. Involves matrix inversion.

      @example See IMatrix.Condition example.
    }
    function Condition: Double;

    { Block operations }
    {
      @description Extracts a submatrix. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param StartRow Start row index.
      @param StartCol Start column index.
      @param NumRows Number of rows.
      @param NumCols Number of columns.

      @returns New IMatrix with the submatrix.

      @warning Raises EMatrixError if dimensions are invalid.

      @example See IMatrix.GetSubMatrix example.
    }
    function GetSubMatrix(StartRow, StartCol, NumRows, NumCols: Integer): IMatrix;

    {
      @description Overwrites a block with a submatrix. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param StartRow Start row index.
      @param StartCol Start column index.
      @param SubMatrix Matrix to insert.

      @warning Raises EMatrixError if dimensions are invalid. Modifies the matrix in place.

      @example See IMatrix.SetSubMatrix example.
    }
    procedure SetSubMatrix(StartRow, StartCol: Integer; const SubMatrix: IMatrix);

    { Element-wise operations }
    {
      @description Performs element-wise multiplication. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other Second matrix.

      @returns New IMatrix with element-wise product.

      @warning Raises EMatrixError if dimensions don't match.

      @example See IMatrix.ElementWiseMultiply example.
    }
    function ElementWiseMultiply(const Other: IMatrix): IMatrix;

    {
      @description Performs element-wise division. Implementation for TMatrixKit.

      @usage Via IMatrix interface.

      @param Other Matrix of divisors.

      @returns New IMatrix with element-wise quotient.

      @warning Raises EMatrixError if dimensions don't match or division by zero occurs (using tolerance).

      @example See IMatrix.ElementWiseDivide example.
    }
    function ElementWiseDivide(const Other: IMatrix): IMatrix;
  end;

type
  { Record structure for storing non-zero elements in sparse matrix
    Sparse matrices store only non-zero elements to save memory
    when dealing with matrices that have many zeros }
  TSparseElement = record
    Row: Integer;    // Row index of the element
    Col: Integer;    // Column index of the element
    Value: Double;   // Value at this position (always non-zero)
  end;

  { Sparse matrix implementation that inherits from TMatrixKit
    While TMatrixKit stores all elements in a 2D array,
    TMatrixKitSparse only stores non-zero elements for memory efficiency.
    Most suitable for large matrices with >90% zero elements. }
  TMatrixKitSparse = class(TMatrixKit)
  private
    { Array of non-zero elements }
    FElements: array of TSparseElement;

    { Current number of non-zero elements }
    FElementCount: Integer;

    { Current capacity of FElements array }
    FCapacity: Integer;

    {
      @description Ensures the internal FElements array has enough capacity to hold a specified number of elements. Grows the array exponentially if needed.

      @usage Internal helper function called before adding new elements to prevent frequent reallocations.

      @param NewCount The minimum required capacity.

      @warning Array reallocation can be costly. The growth factor is 2.

      @example (Internal) Self.EnsureCapacity(FElementCount + 1);
    }
    procedure EnsureCapacity(NewCount: Integer);
  public
    {
      @description Creates a new sparse matrix instance with specified dimensions. Initializes internal storage for non-zero elements.

      @usage To instantiate an empty sparse matrix.

      @param Rows The number of rows.
      @param Cols The number of columns.

      @returns A new TMatrixKitSparse instance.

      @warning Dimensions must be non-negative. Initial capacity is set internally (e.g., 32).

      @example
        var SparseMat: TMatrixKitSparse; // Or IMatrix
        SparseMat := TMatrixKitSparse.Create(1000, 1000);
        // Use SparseMat...
        SparseMat.Free; // If declared as TMatrixKitSparse
    }
    constructor Create(Rows, Cols: Integer);

    {
      @description Frees the memory allocated for the internal sparse element storage (FElements).

      @usage Called automatically when the sparse matrix object is destroyed.

      @warning None.

      @example
        var SparseMat: TMatrixKitSparse;
        SparseMat := TMatrixKitSparse.Create(100, 100);
        SparseMat.Free; // Calls Destroy
    }
    destructor Destroy; override;

    {
      @description Retrieves the value at a specified position in the sparse matrix. Overrides TMatrixKit.GetValue.

      @usage To access elements in a sparse matrix. Returns 0.0 for elements not explicitly stored.

      @param Row The 0-based row index.
      @param Col The 0-based column index.

      @returns The value at the position, or 0.0 if the element is not stored.

      @warning Raises EMatrixError if indices are out of bounds. Current implementation uses linear search (O(N) where N is non-zero count), not binary search. Performance degrades as the number of non-zero elements increases.

      @example
        var Val: Double;
        Val := MySparseMatrix.GetValue(10, 20); // Returns 0.0 if (10, 20) is not stored
    }
    function GetValue(Row, Col: Integer): Double; override;

    {
      @description Sets the value at a specified position in the sparse matrix. Overrides TMatrixKit.SetValue. Handles adding, updating, and removing elements based on the value.

      @usage To modify elements in a sparse matrix. Setting a value close to zero (Abs(Value) < 1E-15) removes the element from storage.

      @param Row The 0-based row index.
      @param Col The 0-based column index.
      @param Value The new Double value.

      @warning Raises EMatrixError if indices are out of bounds. Performance is O(N) in the worst case (N = non-zero count) due to linear search for existing elements and potential shifting during insertion/deletion to maintain row-major order.

      @example
        MySparseMatrix.SetValue(5, 5, 9.8); // Adds or updates element (5,5)
        MySparseMatrix.SetValue(5, 5, 0.0); // Removes element (5,5) if it exists
    }
    procedure SetValue(Row, Col: Integer; const Value: Double); override;

    {
      @description Adds another matrix (sparse or dense) to this sparse matrix. Overrides TMatrixKit.Add.

      @usage To perform matrix addition where at least one operand is sparse.

      @param Other The matrix to add.

      @returns A new dense IMatrix (TMatrixKit) containing the sum.

      @warning Raises EMatrixError if dimensions don't match. The result is currently always a dense matrix, which might be inefficient if the sum is expected to remain sparse.

      @example
        var SumMatrix: IMatrix;
        SumMatrix := MySparseMatrix.Add(AnotherMatrix); // AnotherMatrix can be dense or sparse
    }
    function Add(const Other: IMatrix): IMatrix;

    { Sparse-specific methods }

    {
      @description Adds a value to an element at a specified position. If the element exists, the value is added; otherwise, a new element is created. This is essentially a wrapper around SetValue.

      @usage Potentially for accumulating values in a sparse structure, though current implementation just calls SetValue.

      @param Row The 0-based row index.
      @param Col The 0-based column index.
      @param Value The value to add/set.

      @warning Performance characteristics are the same as SetValue (O(N) worst case). If adding to an existing element, it overwrites, not accumulates, due to SetValue logic. The name is misleading.

      @example
        MySparseMatrix.AddElement(10, 10, 1.0); // Effectively same as SetValue(10, 10, 1.0)
    }
    procedure AddElement(Row, Col: Integer; Value: Double);

    {
      @description Removes elements with values close to zero and potentially shrinks the internal storage array if significantly underutilized.

      @usage Call periodically after many modifications (especially setting elements to zero) to reclaim memory and potentially improve performance of subsequent operations by reducing the number of elements to search.

      @warning Iterates through all stored elements (O(N)). Resizing the array involves memory reallocation. Uses tolerance 1E-15 to check for zero.

      @example
        MySparseMatrix.SetValue(1, 1, 0.0);
        MySparseMatrix.SetValue(2, 2, 0.0);
        MySparseMatrix.CompactStorage; // Removes zero elements and potentially shrinks FElements
    }
    procedure CompactStorage;
  end;

implementation

{ Helper function to return a value with the magnitude of one parameter
  but the sign of another. Used extensively in various decompositions
  for numerical stability.
  
  Parameters:
    Magnitude: Value whose absolute value to use
    Value: Value whose sign to use
  
  Returns:
    abs(Magnitude) if Value ≥ 0, -abs(Magnitude) otherwise
}
function SignWithMagnitude(const Magnitude, Value: Double): Double;
begin
  if Value >= 0 then
    Result := Abs(Magnitude)
  else
    Result := -Abs(Magnitude);
end;

{ Thread worker for parallel matrix multiplication.
  Each instance computes output rows [FRowStart..FRowEnd-1] of FResult.
  Rows are fully independent — no locking required. }
type
  TMultiplyThread = class(TThread)
  private
    FSelf:     TMatrixKit;  // Left matrix (read-only)
    FOther:    IMatrix;     // Right matrix (read-only)
    FResult:   TMatrixKit;  // Output matrix (disjoint row range per thread)
    FRowStart: Integer;
    FRowEnd:   Integer;     // Exclusive upper bound
  protected
    procedure Execute; override;
  public
    constructor Create(ASelf: TMatrixKit; const AOther: IMatrix; AResult: TMatrixKit; ARowStart, ARowEnd: Integer);
  end;

constructor TMultiplyThread.Create(
  ASelf: TMatrixKit;
  const AOther: IMatrix;
  AResult: TMatrixKit;
  ARowStart, ARowEnd: Integer);
begin
  inherited Create(True); // suspended
  FreeOnTerminate := False;
  FSelf     := ASelf;
  FOther    := AOther;
  FResult   := AResult;
  FRowStart := ARowStart;
  FRowEnd   := ARowEnd;
end;

procedure TMultiplyThread.Execute;
var
  I, J, K, II, JJ, KK: Integer;
  Sum: Double;
  RowLim, ColLim, KLim: Integer;
begin
  // Block multiply over the assigned row range
  II := FRowStart;
  while II < FRowEnd do
  begin
    RowLim := Min(II + BLOCK_SIZE - 1, FRowEnd - 1);
    JJ := 0;
    while JJ < FOther.Cols do
    begin
      ColLim := Min(JJ + BLOCK_SIZE - 1, FOther.Cols - 1);
      KK := 0;
      while KK < FSelf.GetCols do
      begin
        KLim := Min(KK + BLOCK_SIZE - 1, FSelf.GetCols - 1);
        for I := II to RowLim do
          for J := JJ to ColLim do
          begin
            Sum := FResult.FData[I, J];
            for K := KK to KLim do
              Sum := Sum + FSelf.FData[I, K] * FOther.GetValue(K, J);
            FResult.FData[I, J] := Sum;
          end;
        Inc(KK, BLOCK_SIZE);
      end;
      Inc(JJ, BLOCK_SIZE);
    end;
    Inc(II, BLOCK_SIZE);
  end;
end;

{ TMatrixKit }

constructor TMatrixKit.Create(const ARows, ACols: Integer);
var
  I: Integer;
begin
  inherited Create;
  SetLength(FData, ARows);
  for I := 0 to ARows - 1 do
    SetLength(FData[I], ACols);
end;

destructor TMatrixKit.Destroy;
begin
  SetLength(FData, 0);
  inherited;
end;

class function TMatrixKit.CreateFromArray(const Data: TMatrixArray): IMatrix;
var
  I, J, Rows, Cols: Integer;
  Matrix: TMatrixKit;
begin
  Rows := Length(Data);
  if Rows = 0 then
    raise EMatrixError.Create('Cannot create matrix from empty array');
    
  Cols := Length(Data[0]);
  Matrix := TMatrixKit.Create(Rows, Cols);
  Result := Matrix;
  
  for I := 0 to Rows - 1 do
  begin
    if Length(Data[I]) <> Cols then
      raise EMatrixError.Create('All rows must have the same number of columns');
      
    for J := 0 to Cols - 1 do
      Matrix.FData[I, J] := Data[I, J];
  end;
end;

class function TMatrixKit.Identity(const Size: Integer): IMatrix;
var
  I: Integer;
  Matrix: TMatrixKit;
begin
  Matrix := TMatrixKit.Create(Size, Size);
  Result := Matrix;
  for I := 0 to Size - 1 do
    Matrix.FData[I, I] := 1.0;
end;

class function TMatrixKit.Zeros(const Rows, Cols: Integer): IMatrix;
begin
  Result := TMatrixKit.Create(Rows, Cols);
  // Values are already zero-initialized
end;

class function TMatrixKit.Ones(const Rows, Cols: Integer): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  Matrix := TMatrixKit.Create(Rows, Cols);
  Result := Matrix;
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Matrix.FData[I, J] := 1.0;
end;

function TMatrixKit.GetRows: Integer;
begin
  Result := Length(FData);
end;

function TMatrixKit.GetCols: Integer;
begin
  if Length(FData) > 0 then
    Result := Length(FData[0])
  else
    Result := 0;
end;

function TMatrixKit.GetValue(Row, Col: Integer): Double;
begin
  if (Row < 0) or (Row >= GetRows) or (Col < 0) or (Col >= GetCols) then
    raise EMatrixError.Create(Format('Matrix index out of bounds: [%d,%d]', [Row, Col]));
  Result := FData[Row, Col];
end;

procedure TMatrixKit.SetValue(Row, Col: Integer; const Value: Double);
begin
  if (Row < 0) or (Row >= GetRows) or (Col < 0) or (Col >= GetCols) then
    raise EMatrixError.Create(Format('Matrix index out of bounds: [%d,%d]', [Row, Col]));
  FData[Row, Col] := Value;
end;

function TMatrixKit.Add(const Other: IMatrix): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (GetRows <> Other.Rows) or (GetCols <> Other.Cols) then
    raise EMatrixError.Create('Matrix dimensions do not match for addition');
    
  Matrix := TMatrixKit.Create(GetRows, GetCols);
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Matrix.FData[I, J] := FData[I, J] + Other.GetValue(I, J);
  Result := Matrix;
end;

function TMatrixKit.Subtract(const Other: IMatrix): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (GetRows <> Other.Rows) or (GetCols <> Other.Cols) then
    raise EMatrixError.Create('Matrix dimensions do not match for subtraction');
    
  Matrix := TMatrixKit.Create(GetRows, GetCols);
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Matrix.FData[I, J] := FData[I, J] - Other.GetValue(I, J);
  Result := Matrix;
end;

function TMatrixKit.Multiply(const Other: IMatrix): IMatrix;
var
  I, J, K, II, JJ, KK: Integer;
  Matrix: TMatrixKit;
  Sum: Double;
  ThreadCount, CreatedCount, T, RowsPerThread, RowStart, RowEnd: Integer;
  Threads: array of TMultiplyThread;
  ThreadError: String;
begin
  if GetCols <> Other.Rows then
    raise EMatrixError.Create('Matrix dimensions do not match for multiplication');

  Matrix := TMatrixKit.Create(GetRows, Other.Cols);
  Result := Matrix;

  // On Unix, applications without cthreads have no installed thread manager;
  // use the serial path instead of failing at runtime. Work size, not row count
  // alone, determines whether thread startup is worthwhile.
  if
    {$IFDEF UNIX} IsMultiThread and {$ENDIF}
    (Int64(GetRows) * GetCols * Other.Cols >= THREAD_OPERATION_THRESHOLD) and
    (TThread.ProcessorCount > 1) then
  begin
    // Zero the result matrix
    for I := 0 to GetRows - 1 do
      for J := 0 to Other.Cols - 1 do
        Matrix.FData[I, J] := 0.0;

    ThreadCount := Min(Min(TThread.ProcessorCount, GetRows), MAX_MULTIPLY_THREADS);
    Threads := nil;
    SetLength(Threads, ThreadCount);
    RowsPerThread := (GetRows + ThreadCount - 1) div ThreadCount;

    ThreadError := '';
    CreatedCount := 0;
    try
      // Create and start one thread per row partition.
      for T := 0 to ThreadCount - 1 do
      begin
        RowStart := T * RowsPerThread;
        RowEnd   := Min(RowStart + RowsPerThread, GetRows);
        Threads[T] := TMultiplyThread.Create(
          Self, Other, Matrix, RowStart, RowEnd);
        try
          Threads[T].Start;
        except
          Threads[T].Free;
          Threads[T] := nil;
          raise;
        end;
        Inc(CreatedCount);
      end;
    finally
      // Always join and release workers, including after a partial startup.
      for T := 0 to CreatedCount - 1 do
      begin
        Threads[T].WaitFor;
        if (ThreadError = '') and Assigned(Threads[T].FatalException) then
        begin
          if Threads[T].FatalException is Exception then
            ThreadError := Exception(Threads[T].FatalException).Message
          else
            ThreadError := 'unknown worker exception';
        end;
        Threads[T].Free;
        Threads[T] := nil;
      end;
    end;
    if ThreadError <> '' then
      raise EMatrixError.Create('Parallel matrix multiplication failed: ' + ThreadError);
  end
  // Block multiply for medium matrices (>= BLOCK_SIZE but below thread threshold)
  else if (GetRows >= BLOCK_SIZE) and (GetCols >= BLOCK_SIZE) and (Other.Cols >= BLOCK_SIZE) then
  begin
    for I := 0 to GetRows - 1 do
      for J := 0 to Other.Cols - 1 do
        Matrix.FData[I, J] := 0.0;

    II := 0;
    while II < GetRows do
    begin
      JJ := 0;
      while JJ < Other.Cols do
      begin
        KK := 0;
        while KK < GetCols do
        begin
          for I := II to Min(II + BLOCK_SIZE - 1, GetRows - 1) do
            for J := JJ to Min(JJ + BLOCK_SIZE - 1, Other.Cols - 1) do
            begin
              Sum := Matrix.FData[I, J];
              for K := KK to Min(KK + BLOCK_SIZE - 1, GetCols - 1) do
                Sum := Sum + FData[I, K] * Other.GetValue(K, J);
              Matrix.FData[I, J] := Sum;
            end;
          Inc(KK, BLOCK_SIZE);
        end;
        Inc(JJ, BLOCK_SIZE);
      end;
      Inc(II, BLOCK_SIZE);
    end;
  end
  else
  begin
    // Standard multiply for small matrices
    for I := 0 to GetRows - 1 do
      for J := 0 to Other.Cols - 1 do
      begin
        Sum := 0;
        for K := 0 to GetCols - 1 do
          Sum := Sum + FData[I, K] * Other.GetValue(K, J);
        Matrix.FData[I, J] := Sum;
      end;
  end;
end;

function TMatrixKit.ScalarMultiply(const Scalar: Double): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  Matrix := TMatrixKit.Create(GetRows, GetCols);
  Result := Matrix;
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Matrix.FData[I, J] := FData[I, J] * Scalar;
end;

function TMatrixKit.Transpose: IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  Matrix := TMatrixKit.Create(GetCols, GetRows);
  Result := Matrix;
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Matrix.FData[J, I] := FData[I, J];
end;

function TMatrixKit.IsSquare: Boolean;
begin
  Result := GetRows = GetCols;
end;

function TMatrixKit.Determinant: Double;
var
  N, I, J, CycleCount: Integer;
  LUResult: TLUDecomposition;
  Visited: array of Boolean;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix must be square to calculate determinant');

  N := GetRows;
  if N = 0 then begin Result := 0; Exit; end;
  if N = 1 then begin Result := FData[0, 0]; Exit; end;
  if N = 2 then begin Result := FData[0, 0] * FData[1, 1] - FData[0, 1] * FData[1, 0]; Exit; end;

  // O(n^3) via LU decomposition — det(A) = det(P^-1) * prod(diag(U))
  try
    LUResult := LU;
  except
    on E: EMatrixError do begin Result := 0; Exit; end; // singular
  end;

  Result := 1.0;
  for I := 0 to N - 1 do
    Result := Result * LUResult.U.GetValue(I, I);

  // Determine sign from permutation: (-1)^(N - number_of_cycles)
  SetLength(Visited, N);
  CycleCount := 0;
  for I := 0 to N - 1 do
    if not Visited[I] then
    begin
      Inc(CycleCount);
      J := I;
      while not Visited[J] do
      begin
        Visited[J] := True;
        J := LUResult.P[J];
      end;
    end;
  if Odd(N - CycleCount) then
    Result := -Result;
end;

function TMatrixKit.Trace: Double;
var
  I: Integer;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix must be square to calculate trace');
    
  Result := 0;
  for I := 0 to GetRows - 1 do
    Result := Result + FData[I, I];
end;

function TMatrixKit.Rank: Integer;
var
  I, J, K, PivotRow, CurrentRow: Integer;
  Factor, Tolerance, Scale: Double;
  RowEchelon: TMatrixKit;
  MaxVal: Double;
begin
  Result := 0;
  if (GetRows = 0) or (GetCols = 0) then
    Exit;

  // Create a copy of the matrix for row echelon form
  RowEchelon := TMatrixKit.Create(GetRows, GetCols);
  try
    // Copy data
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        RowEchelon.FData[I, J] := FData[I, J];

    Scale := 0.0;
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        Scale := Max(Scale, Abs(FData[I, J]));
    if Scale = 0.0 then
      Exit(0);
    Tolerance := 2.2204460492503131E-16 * Max(GetRows, GetCols) * Scale;
    
    // Convert to row echelon form. The pivot row is independent of the column,
    // which is required when an early column contains no usable pivot.
    CurrentRow := 0;
    for K := 0 to GetCols - 1 do
    begin
      if CurrentRow >= GetRows then
        Break;
      // Find maximum element in this column
      MaxVal := Abs(RowEchelon.FData[CurrentRow, K]);
      PivotRow := CurrentRow;
      for I := CurrentRow + 1 to GetRows - 1 do
        if Abs(RowEchelon.FData[I, K]) > MaxVal then
        begin
          MaxVal := Abs(RowEchelon.FData[I, K]);
          PivotRow := I;
        end;

      if MaxVal <= Tolerance then
        Continue;
      if PivotRow <> CurrentRow then
        RowEchelon.SwapRows(CurrentRow, PivotRow);

      // Eliminate column elements
      for I := CurrentRow + 1 to GetRows - 1 do
      begin
        Factor := RowEchelon.FData[I, K] / RowEchelon.FData[CurrentRow, K];
        RowEchelon.FData[I, K] := 0.0;
        for J := K + 1 to GetCols - 1 do
          RowEchelon.FData[I, J] := RowEchelon.FData[I, J] -
            Factor * RowEchelon.FData[CurrentRow, J];
      end;
      Inc(CurrentRow);
    end;
    Result := CurrentRow;
  finally
    RowEchelon.Free;
  end;
end;

function TMatrixKit.Inverse: IMatrix;
var
  I, J: Integer;
  LUDecomp: TLUDecomposition;
  B, PermutedB: array of Double;
  X: array of Double;
  InvMatrix: TMatrixKit;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix must be square to calculate inverse');
    
  // Get LU decomposition
  LUDecomp := LU;
  
  // Create result matrix
  InvMatrix := TMatrixKit.Create(GetRows, GetRows);
  Result := InvMatrix;
  
  // Solve for each column of the inverse
  SetLength(B, GetRows);
  SetLength(PermutedB, GetRows);
  for J := 0 to GetRows - 1 do
  begin
    // Set up unit vector
    for I := 0 to GetRows - 1 do
      if I = J then
        B[I] := 1
      else
        B[I] := 0;
        
    // LU stores P*A = L*U, so solve L*U*x = P*b.
    for I := 0 to GetRows - 1 do
      PermutedB[I] := B[LUDecomp.P[I]];
    X := ForwardSubstitution(LUDecomp.L, PermutedB);
    X := BackSubstitution(LUDecomp.U, X);
    
    // Fill column of inverse
    for I := 0 to GetRows - 1 do
      InvMatrix.FData[I, J] := X[I];
  end;
end;

{ LU decomposition with partial pivoting
  
  Computes the decomposition of matrix A such that PA = LU where:
  - P is a permutation matrix (stored as array of indices)
  - L is a lower triangular matrix with unit diagonal
  - U is an upper triangular matrix
  
  Algorithm:
  1. Initialize L as identity matrix, U as a copy of this matrix, P as identity permutation
  2. For each column k:
     a. Find pivot (row with largest absolute value in current column)
     b. Swap rows in U and update permutation P
     c. For each row below pivot:
        i. Compute multiplier and store in L
        ii. Eliminate elements below pivot in U
  
  Uses partial pivoting for numerical stability.
  
  Returns: 
    TLUDecomposition record containing L, U matrices and permutation array P
  
  Raises:
    EMatrixError if matrix is not square or is singular
  
  Time complexity: O(n³) where n is the matrix dimension
  Space complexity: O(n²)
}
function TMatrixKit.LU: TLUDecomposition;
var
  I, J, K, PivotRow: Integer;
  Factor, MaxVal, Scale, TempValue: Double;
  L, U: TMatrixKit;
  Tolerance: Double;
begin
  Result := Default(TLUDecomposition);
  if not IsSquare then
    raise EMatrixError.Create('LU decomposition requires square matrix');

  { Initialize L as identity and U as copy of input matrix }
  L := TMatrixKit.Create(GetRows, GetRows);
  U := TMatrixKit.Create(GetRows, GetRows);
  
  { Initialize permutation array to identity permutation }
  SetLength(Result.P, GetRows);
  for I := 0 to GetRows - 1 do
    Result.P[I] := I;

  { Copy original matrix to U }
  for I := 0 to GetRows - 1 do
    for J := 0 to GetRows - 1 do
      U.FData[I, J] := FData[I, J];

  Scale := 0.0;
  for I := 0 to GetRows - 1 do
    for J := 0 to GetRows - 1 do
      Scale := Max(Scale, Abs(U.FData[I, J]));
  if Scale = 0.0 then
  begin
    L.Free;
    U.Free;
    raise EMatrixError.Create('Matrix is singular');
  end;
  Tolerance := 2.2204460492503131E-16 * Max(1, GetRows) * Scale;

  { Initialize L with identity matrix (unit diagonal) }
  for I := 0 to GetRows - 1 do
    L.FData[I, I] := 1;

  { Main LU decomposition loop with partial pivoting }
  for K := 0 to GetRows - 2 do
  begin
    { Find pivot element (maximum absolute value in current column) }
    MaxVal := Abs(U.FData[K, K]);
    PivotRow := K;
    for I := K + 1 to GetRows - 1 do
      if Abs(U.FData[I, K]) > MaxVal then
      begin
        MaxVal := Abs(U.FData[I, K]);
        PivotRow := I;
      end;

    { Check if matrix is singular (pivot too small) }
    if MaxVal <= Tolerance then
    begin
      L.Free;
      U.Free;
      raise EMatrixError.Create('Matrix is singular');
    end;

    { Swap rows if necessary (partial pivoting) }
    if PivotRow <> K then
    begin
      U.SwapRows(K, PivotRow);
      { Previously computed multipliers must follow the same row exchange. }
      for J := 0 to K - 1 do
      begin
        TempValue := L.FData[K, J];
        L.FData[K, J] := L.FData[PivotRow, J];
        L.FData[PivotRow, J] := TempValue;
      end;
      { Update permutation array to track row exchanges }
      J := Result.P[K];
      Result.P[K] := Result.P[PivotRow];
      Result.P[PivotRow] := J;
    end;

    { Perform elimination for all rows below current pivot }
    for I := K + 1 to GetRows - 1 do
    begin
      { Compute multiplier and store in L matrix }
      Factor := U.FData[I, K] / U.FData[K, K];
      L.FData[I, K] := Factor;
      
      { Eliminate elements below pivot in U matrix }
      U.FData[I, K] := 0.0;
      for J := K + 1 to GetRows - 1 do
        U.FData[I, J] := U.FData[I, J] - Factor * U.FData[K, J];
    end;
  end;

  { Final check for singularity (last diagonal element) }
  if Abs(U.FData[GetRows-1, GetRows-1]) <= Tolerance then
  begin
    L.Free;
    U.Free;
    raise EMatrixError.Create('Matrix is singular');
  end;

  { Store results }
  Result.L := L;
  Result.U := U;
end;

function TMatrixKit.QR: TQRDecomposition;
var
  I, J, K: Integer;
  Q, R: TMatrixKit;
  V: array of Double;
  Dot: Double;
begin
  Q := TMatrixKit.Create(GetRows, GetCols);
  R := TMatrixKit.Create(GetCols, GetCols);
  
  try
    // Copy original matrix to Q
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        Q.FData[I, J] := FData[I, J];

    SetLength(V, GetRows);
    try
      // Gram-Schmidt process
      for J := 0 to GetCols - 1 do
      begin
        // Copy column to V
        for I := 0 to GetRows - 1 do
          V[I] := Q.FData[I, J];
          
        // Subtract projections of previous vectors
        for K := 0 to J - 1 do
        begin
          Dot := 0;
          for I := 0 to GetRows - 1 do
            Dot := Dot + Q.FData[I, K] * V[I];
          R.FData[K, J] := Dot;
          
          for I := 0 to GetRows - 1 do
            V[I] := V[I] - Dot * Q.FData[I, K];
        end;
        
        // Normalize V
        Dot := 0;
        for I := 0 to GetRows - 1 do
          Dot := Dot + V[I] * V[I];
        Dot := Sqrt(Dot);
        
        if Dot > 1E-12 then
        begin
          R.FData[J, J] := Dot;
          for I := 0 to GetRows - 1 do
            Q.FData[I, J] := V[I] / Dot;
        end
        else
        begin
          SetLength(V, 0); // Clear V array before raising exception
          Q.Free;
          R.Free;
          raise EMatrixError.Create('Matrix columns are linearly dependent');
        end;
      end;

      // Set result
      Result.Q := Q;
      Result.R := R;
      Q := nil; // Prevent double free
      R := nil; // Prevent double free
    finally
      SetLength(V, 0); // Always clear V array
    end;
  except
    on E: Exception do
    begin
      if Assigned(Q) then Q.Free;
      if Assigned(R) then R.Free;
      raise;
    end;
  end;
end;

function TMatrixKit.EigenDecomposition: TEigenDecomposition;
var
  N, I, J, P, Q, K, Iter, MaxIter: Integer;
  Work, EigenVectors: TMatrixKit;
  Scale, Tolerance, MaxOffDiagonal: Double;
  APP, AQQ, APQ, AKP, AKQ: Double;
  Angle, C, S, VIP, VIQ: Double;
  TraceValue, Det, Discriminant, Lambda, X, Y, Norm: Double;
  IsSymmetricMatrix, Converged: Boolean;

  procedure SetEigenVector(const Column: Integer; const EigenValue: Double);
  var
    Candidate1X, Candidate1Y, Candidate2X, Candidate2Y: Double;
    Norm1, Norm2: Double;
  begin
    Candidate1X := FData[0, 1];
    Candidate1Y := EigenValue - FData[0, 0];
    Candidate2X := EigenValue - FData[1, 1];
    Candidate2Y := FData[1, 0];
    Norm1 := Sqr(Candidate1X) + Sqr(Candidate1Y);
    Norm2 := Sqr(Candidate2X) + Sqr(Candidate2Y);
    if Norm1 >= Norm2 then
    begin
      X := Candidate1X;
      Y := Candidate1Y;
      Norm := Sqrt(Norm1);
    end
    else
    begin
      X := Candidate2X;
      Y := Candidate2Y;
      Norm := Sqrt(Norm2);
    end;
    if Norm <= Tolerance then
    begin
      X := Ord(Column = 0);
      Y := Ord(Column = 1);
      Norm := 1.0;
    end;
    EigenVectors.FData[0, Column] := X / Norm;
    EigenVectors.FData[1, Column] := Y / Norm;
  end;
begin
  Result := Default(TEigenDecomposition);
  if not IsSquare then
    raise EMatrixError.Create('Eigendecomposition requires square matrix');
  N := GetRows;
  Result.EigenValues := nil;
  Result.EigenVectors := nil;
  SetLength(Result.EigenValues, N);
  Scale := 1.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Scale := Max(Scale, Abs(FData[I, J]));
  Tolerance := 1E-12 * Scale;

  if N = 1 then
  begin
    Result.EigenValues[0] := FData[0, 0];
    Result.EigenVectors := TMatrixKit.Identity(1);
    Exit;
  end;

  IsSymmetricMatrix := True;
  for I := 0 to N - 1 do
    for J := I + 1 to N - 1 do
      if Abs(FData[I, J] - FData[J, I]) > Tolerance then
        IsSymmetricMatrix := False;

  if not IsSymmetricMatrix then
  begin
    if N <> 2 then
      raise EMatrixError.Create(
        'Real eigendecomposition currently supports symmetric matrices and 2x2 matrices only');
    TraceValue := FData[0, 0] + FData[1, 1];
    Det := FData[0, 0] * FData[1, 1] - FData[0, 1] * FData[1, 0];
    Discriminant := Sqr(TraceValue) - 4.0 * Det;
    if Discriminant < -Tolerance then
      raise EMatrixError.Create(
        'Eigendecomposition has complex eigenvalues; the real-valued API cannot represent them');
    if Discriminant < 0 then
      Discriminant := 0;
    if (Discriminant <= Sqr(Tolerance)) and
       ((Abs(FData[0, 1]) > Tolerance) or
        (Abs(FData[1, 0]) > Tolerance) or
        (Abs(FData[0, 0] - FData[1, 1]) > Tolerance)) then
      raise EMatrixError.Create('Eigendecomposition requires a diagonalizable matrix');
    Result.EigenValues[0] := (TraceValue + Sqrt(Discriminant)) / 2.0;
    Result.EigenValues[1] := (TraceValue - Sqrt(Discriminant)) / 2.0;
    EigenVectors := TMatrixKit.Create(2, 2);
    SetEigenVector(0, Result.EigenValues[0]);
    SetEigenVector(1, Result.EigenValues[1]);
    Result.EigenVectors := EigenVectors;
    Exit;
  end;

  Work := TMatrixKit.Create(N, N);
  EigenVectors := TMatrixKit.Create(N, N);
  try
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        Work.FData[I, J] := FData[I, J];
        if I = J then
          EigenVectors.FData[I, J] := 1.0;
      end;

    MaxIter := Max(50, 100 * N * N);
    Converged := False;
    for Iter := 1 to MaxIter do
    begin
      P := 0;
      Q := 1;
      MaxOffDiagonal := Abs(Work.FData[P, Q]);
      for I := 0 to N - 1 do
        for J := I + 1 to N - 1 do
          if Abs(Work.FData[I, J]) > MaxOffDiagonal then
          begin
            MaxOffDiagonal := Abs(Work.FData[I, J]);
            P := I;
            Q := J;
          end;
      if MaxOffDiagonal <= Tolerance then
      begin
        Converged := True;
        Break;
      end;

      APP := Work.FData[P, P];
      AQQ := Work.FData[Q, Q];
      APQ := Work.FData[P, Q];
      Angle := 0.5 * ArcTan2(2.0 * APQ, AQQ - APP);
      C := Cos(Angle);
      S := Sin(Angle);

      for K := 0 to N - 1 do
        if (K <> P) and (K <> Q) then
        begin
          AKP := Work.FData[K, P];
          AKQ := Work.FData[K, Q];
          Work.FData[K, P] := C * AKP - S * AKQ;
          Work.FData[P, K] := Work.FData[K, P];
          Work.FData[K, Q] := S * AKP + C * AKQ;
          Work.FData[Q, K] := Work.FData[K, Q];
        end;
      Work.FData[P, P] := Sqr(C) * APP - 2.0 * S * C * APQ + Sqr(S) * AQQ;
      Work.FData[Q, Q] := Sqr(S) * APP + 2.0 * S * C * APQ + Sqr(C) * AQQ;
      Work.FData[P, Q] := 0.0;
      Work.FData[Q, P] := 0.0;

      for K := 0 to N - 1 do
      begin
        VIP := EigenVectors.FData[K, P];
        VIQ := EigenVectors.FData[K, Q];
        EigenVectors.FData[K, P] := C * VIP - S * VIQ;
        EigenVectors.FData[K, Q] := S * VIP + C * VIQ;
      end;
    end;
    if not Converged then
      raise EMatrixError.Create('Eigendecomposition did not converge');

    for I := 0 to N - 1 do
      Result.EigenValues[I] := Work.FData[I, I];
    for I := 0 to N - 2 do
      for J := I + 1 to N - 1 do
        if Result.EigenValues[J] > Result.EigenValues[I] then
        begin
          Lambda := Result.EigenValues[I];
          Result.EigenValues[I] := Result.EigenValues[J];
          Result.EigenValues[J] := Lambda;
          for K := 0 to N - 1 do
          begin
            X := EigenVectors.FData[K, I];
            EigenVectors.FData[K, I] := EigenVectors.FData[K, J];
            EigenVectors.FData[K, J] := X;
          end;
        end;
    Result.EigenVectors := EigenVectors;
    EigenVectors := nil;
  finally
    Work.Free;
    if Assigned(EigenVectors) then
      EigenVectors.Free;
  end;
end;

function TMatrixKit.BackSubstitution(const Upper: IMatrix; const b: TDoubleArray): TDoubleArray;
var
  I, J: Integer;
  N: Integer;
  Scale, Tolerance, Diagonal: Double;
begin
  N := Length(b);
  Result := nil;
  SetLength(Result, N);
  Scale := 0.0;
  for I := 0 to Upper.Rows - 1 do
    for J := 0 to Upper.Cols - 1 do
      Scale := Max(Scale, Abs(Upper.GetValue(I, J)));
  Tolerance := 2.2204460492503131E-16 * Max(1, N) * Scale;
  
  for I := N - 1 downto 0 do
  begin
    Result[I] := b[I];
    for J := I + 1 to N - 1 do
      Result[I] := Result[I] - Upper.GetValue(I, J) * Result[J];
    Diagonal := Upper.GetValue(I, I);
    if Abs(Diagonal) <= Tolerance then
      raise EMatrixError.Create('Singular upper-triangular system');
    Result[I] := Result[I] / Diagonal;
  end;
end;

function TMatrixKit.ForwardSubstitution(const Lower: IMatrix; const b: TDoubleArray): TDoubleArray;
var
  I, J: Integer;
  N: Integer;
  Scale, Tolerance, Diagonal: Double;
begin
  N := Length(b);
  Result := nil;
  SetLength(Result, N);
  Scale := 0.0;
  for I := 0 to Lower.Rows - 1 do
    for J := 0 to Lower.Cols - 1 do
      Scale := Max(Scale, Abs(Lower.GetValue(I, J)));
  Tolerance := 2.2204460492503131E-16 * Max(1, N) * Scale;
  
  for I := 0 to N - 1 do
  begin
    Result[I] := b[I];
    for J := 0 to I - 1 do
      Result[I] := Result[I] - Lower.GetValue(I, J) * Result[J];
    Diagonal := Lower.GetValue(I, I);
    if Abs(Diagonal) <= Tolerance then
      raise EMatrixError.Create('Singular lower-triangular system');
    Result[I] := Result[I] / Diagonal;
  end;
end;

procedure TMatrixKit.SwapRows(Row1, Row2: Integer);
var
  Temp: array of Double;
  J: Integer;
begin
  if (Row1 < 0) or (Row1 >= GetRows) or (Row2 < 0) or (Row2 >= GetRows) then
    raise EMatrixError.Create('Invalid row indices for swap');

  SetLength(Temp, GetCols);
  for J := 0 to GetCols - 1 do
    Temp[J] := FData[Row1, J];
  
  for J := 0 to GetCols - 1 do
    FData[Row1, J] := FData[Row2, J];
    
  for J := 0 to GetCols - 1 do
    FData[Row2, J] := Temp[J];
end;

function TMatrixKit.FindPivot(StartRow, Col: Integer): Integer;
var
  I: Integer;
  MaxVal: Double;
begin
  Result := StartRow;
  MaxVal := Abs(FData[StartRow, Col]);
  
  for I := StartRow + 1 to GetRows - 1 do
    if Abs(FData[I, Col]) > MaxVal then
    begin
      MaxVal := Abs(FData[I, Col]);
      Result := I;
    end;
end;

function TMatrixKit.DotProduct(const v1, v2: TDoubleArray): Double;
var
  I: Integer;
begin
  if Length(v1) <> Length(v2) then
    raise EMatrixError.Create('Vector dimensions must match for dot product');
    
  Result := 0;
  for I := 0 to Length(v1) - 1 do
    Result := Result + v1[I] * v2[I];
end;

procedure TMatrixKit.NormalizeColumn(var Matrix: TMatrixKit; Col: Integer);
var
  I: Integer;
  Norm: Double;
begin
  Norm := 0;
  
  // Calculate Euclidean norm
  for I := 0 to Matrix.GetRows - 1 do
    Norm := Norm + Sqr(Matrix.FData[I, Col]);
  Norm := Sqrt(Norm);
  
  if Norm < 1E-12 then
    raise EMatrixError.Create('Cannot normalize zero vector');
    
  // Normalize the column
  for I := 0 to Matrix.GetRows - 1 do
    Matrix.FData[I, Col] := Matrix.FData[I, Col] / Norm;
end;

function TMatrixKit.ToString: string;
var
  I, J: Integer;
  Values: array of array of string;
  CurrentValue: string;
  ColWidths: array of Integer;
  FormattedValue: string;
begin
  // Initialize arrays
  SetLength(Values, GetRows, GetCols);
  SetLength(ColWidths, GetCols);
  
  // First pass: Format all values and find maximum width per column
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
    begin
      // Format with 6 decimal places, trim trailing zeros
      CurrentValue := Format('%.6f', [FData[I, J]]);
      while (Length(CurrentValue) > 1) and (CurrentValue[Length(CurrentValue)] = '0') do
        Delete(CurrentValue, Length(CurrentValue), 1);
      if CurrentValue[Length(CurrentValue)] = '.' then
        Delete(CurrentValue, Length(CurrentValue), 1);
      
      Values[I, J] := CurrentValue;
      
      // Update maximum width for this column
      if Length(CurrentValue) > ColWidths[J] then
        ColWidths[J] := Length(CurrentValue);
    end;
  
  // Build the string representation with consistent column widths
  Result := '';
  for I := 0 to GetRows - 1 do
  begin
    Result := Result + '|';
    for J := 0 to GetCols - 1 do
    begin
      if J > 0 then
        Result := Result + ' ';  // Single space between columns
      
      // Right-align the value within its column width
      FormattedValue := Values[I, J];
      while Length(FormattedValue) < ColWidths[J] do
        FormattedValue := ' ' + FormattedValue;
      
      Result := Result + FormattedValue;
    end;
    Result := Result + '|';
    
    if I < GetRows - 1 then
      Result := Result + sLineBreak;
  end;
end;

function TMatrixKit.NormOne: Double;
var
  I, J: Integer;
  ColSum: Double;
begin
  Result := 0;
  for J := 0 to GetCols - 1 do
  begin
    ColSum := 0;
    for I := 0 to GetRows - 1 do
      ColSum := ColSum + Abs(FData[I, J]);
    if ColSum > Result then
      Result := ColSum;
  end;
end;

function TMatrixKit.NormInf: Double;
var
  I, J: Integer;
  RowSum: Double;
begin
  Result := 0;
  for I := 0 to GetRows - 1 do
  begin
    RowSum := 0;
    for J := 0 to GetCols - 1 do
      RowSum := RowSum + Abs(FData[I, J]);
    if RowSum > Result then
      Result := RowSum;
  end;
end;

function TMatrixKit.NormFrobenius: Double;
var
  I, J: Integer;
  Sum: Double;
begin
  Sum := 0;
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Sum := Sum + Sqr(FData[I, J]);
  Result := Sqrt(Sum);
end;

function TMatrixKit.IsSymmetric: Boolean;
var
  I, J: Integer;
begin
  if not IsSquare then
    Exit(False);
    
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      if FData[I, J] <> FData[J, I] then
        Exit(False);
  Exit(True);
end;

function TMatrixKit.IsDiagonal: Boolean;
var
  I, J: Integer;
begin
  if not IsSquare then
    Exit(False);
    
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      if (I <> J) and (FData[I, J] <> 0) then
        Exit(False);
  Exit(True);
end;

function TMatrixKit.IsTriangular(Upper: Boolean = True): Boolean;
var
  I, J: Integer;
begin
  if not IsSquare then
    Exit(False);
    
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      if (Upper and (I > J) and (FData[I, J] <> 0)) or
         ((not Upper) and (I < J) and (FData[I, J] <> 0)) then
        Exit(False);
  Exit(True);
end;

function TMatrixKit.IsPositiveDefinite: Boolean;
begin
  Result := False;
  if not IsSquare then Exit;
  if not IsSymmetric then Exit;
  // A symmetric matrix is positive definite iff Cholesky succeeds
  try
    Cholesky;
    Result := True;
  except
    on EMatrixError do ;
  end;
end;

function TMatrixKit.IsPositiveSemidefinite: Boolean;
var
  EigResult: TEigenDecomposition;
  I: Integer;
begin
  Result := False;
  if not IsSquare then Exit;
  if not IsSymmetric then Exit;
  // A symmetric matrix is positive semidefinite iff all eigenvalues >= 0
  try
    EigResult := EigenDecomposition;
    for I := 0 to Length(EigResult.EigenValues) - 1 do
      if EigResult.EigenValues[I] < -1E-9 then Exit;
    Result := True;
  except
    on EMatrixError do ;
  end;
end;

function TMatrixKit.IsOrthogonal: Boolean;
var
  I, J: Integer;
  IdentityMat: TMatrixKit;
  Product: IMatrix;
  Tolerance: Double;
begin
  if not IsSquare then
    Exit(False);
    
  IdentityMat := TMatrixKit.Create(GetRows, GetRows);
  try
    // Initialize identity matrix
    for I := 0 to GetRows - 1 do
      IdentityMat.FData[I, I] := 1.0;
    
    // Check if A * A^T = I
    Product := Multiply(Transpose);
    
    // Compare with identity matrix within tolerance
    Tolerance := 1E-12;
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        if Abs(Product.GetValue(I, J) - IdentityMat.FData[I, J]) > Tolerance then
          Exit(False);
          
    Result := True;
  finally
    IdentityMat.Free;
  end;
end;

function TMatrixKit.Condition: Double;
var
  InverseMatrix: IMatrix;
begin
  if not IsSquare then
    raise EMatrixError.Create('Condition number requires square matrix');
    
  try
    InverseMatrix := Inverse;
    Result := NormOne * InverseMatrix.NormOne;
  except
    on E: EMatrixError do
      Result := MaxDouble;  // Return infinity for singular matrices
  end;
end;

function TMatrixKit.GetSubMatrix(StartRow, StartCol, NumRows, NumCols: Integer): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (StartRow < 0) or (StartRow + NumRows > GetRows) or
     (StartCol < 0) or (StartCol + NumCols > GetCols) then
    raise EMatrixError.Create('Invalid submatrix dimensions');
    
  Matrix := TMatrixKit.Create(NumRows, NumCols);
  Result := Matrix;
  for I := 0 to NumRows - 1 do
    for J := 0 to NumCols - 1 do
      Matrix.FData[I, J] := FData[StartRow + I, StartCol + J];
end;

procedure TMatrixKit.SetSubMatrix(StartRow, StartCol: Integer; const SubMatrix: IMatrix);
var
  I, J: Integer;
begin
  if (StartRow < 0) or (StartRow + SubMatrix.Rows > GetRows) or
     (StartCol < 0) or (StartCol + SubMatrix.Cols > GetCols) then
    raise EMatrixError.Create('Invalid submatrix dimensions');
    
  for I := 0 to SubMatrix.Rows - 1 do
    for J := 0 to SubMatrix.Cols - 1 do
      FData[StartRow + I, StartCol + J] := SubMatrix.GetValue(I, J);
end;

function TMatrixKit.ElementWiseMultiply(const Other: IMatrix): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (GetRows <> Other.Rows) or (GetCols <> Other.Cols) then
    raise EMatrixError.Create('Matrix dimensions do not match for element-wise multiplication');
    
  Matrix := TMatrixKit.Create(GetRows, GetCols);
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      Matrix.FData[I, J] := FData[I, J] * Other.GetValue(I, J);
  Result := Matrix;
end;

function TMatrixKit.ElementWiseDivide(const Other: IMatrix): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
  DivisorValue: Double;
begin
  if (GetRows <> Other.Rows) or (GetCols <> Other.Cols) then
    raise EMatrixError.Create('Matrix dimensions do not match for element-wise division');
    
  Matrix := TMatrixKit.Create(GetRows, GetCols);
  try
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
      begin
        DivisorValue := Other.GetValue(I, J);
        
        // Check for division by zero
        if DivisorValue = 0.0 then
          raise EMatrixError.Create('Division by zero in element-wise division');
          
        Matrix.FData[I, J] := FData[I, J] / DivisorValue;
      end;
    Result := Matrix;
  except
    Matrix.Free;
    raise;
  end;
end;

class function TMatrixKit.CreateBandMatrix(Size, LowerBand, UpperBand: Integer): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (Size <= 0) or (LowerBand < 0) or (UpperBand < 0) then
    raise EMatrixError.Create('Invalid band matrix parameters');
    
  Matrix := TMatrixKit.Create(Size, Size);
  Result := Matrix;
  
  for I := 0 to Size - 1 do
    for J := 0 to Size - 1 do
      if (J - I <= UpperBand) and (I - J <= LowerBand) then
        Matrix.FData[I, J] := 1  // Default value for band elements
      else
        Matrix.FData[I, J] := 0;
end;

class function TMatrixKit.CreateSymmetric(const Data: TMatrixArray): IMatrix;
var
  I, J, Size: Integer;
  Matrix: TMatrixKit;
begin
  Size := Length(Data);
  if Size = 0 then
    raise EMatrixError.Create('Cannot create symmetric matrix from empty array');
    
  if Length(Data[0]) <> Size then
    raise EMatrixError.Create('Matrix must be square for symmetric construction');
    
  Matrix := TMatrixKit.Create(Size, Size);
  Result := Matrix;
  
  for I := 0 to Size - 1 do
  begin
    if Length(Data[I]) <> Size then
      raise EMatrixError.Create('All rows must have the same length');
      
    Matrix.FData[I, I] := Data[I, I];  // Diagonal elements
    for J := 0 to I - 1 do
    begin
      Matrix.FData[I, J] := Data[I, J];
      Matrix.FData[J, I] := Data[I, J];  // Mirror across diagonal
    end;
  end;
end;

class function TMatrixKit.CreateDiagonal(const Diagonal: array of Double): IMatrix;
var
  I, Size: Integer;
  Matrix: TMatrixKit;
begin
  Size := Length(Diagonal);
  if Size = 0 then
    raise EMatrixError.Create('Cannot create diagonal matrix from empty array');
    
  Matrix := TMatrixKit.Create(Size, Size);
  Result := Matrix;
  
  for I := 0 to Size - 1 do
    Matrix.FData[I, I] := Diagonal[I];
end;

class function TMatrixKit.CreateRandom(Rows, Cols: Integer; Min, Max: Double): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if (Rows <= 0) or (Cols <= 0) then
    raise EMatrixError.Create('Invalid matrix dimensions');
  if IsNan(Min) or IsNan(Max) or IsInfinite(Min) or IsInfinite(Max) or
     (Max < Min) then
    raise EMatrixError.Create('Invalid random matrix bounds');
    
  Matrix := TMatrixKit.Create(Rows, Cols);
  Result := Matrix;
  
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Matrix.FData[I, J] := Min + Random * (Max - Min);
end;

class function TMatrixKit.CreateRandom(Rows, Cols: Integer;
  Min, Max: Double; Seed: LongWord): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
  State: LongWord;

  function NextUnit: Double;
  begin
    State := LongWord((QWord(State) * 1664525 + 1013904223) and $FFFFFFFF);
    Result := State / 4294967296.0;
  end;
begin
  if (Rows <= 0) or (Cols <= 0) then
    raise EMatrixError.Create('Invalid matrix dimensions');
  if IsNan(Min) or IsNan(Max) or IsInfinite(Min) or IsInfinite(Max) or
     (Max < Min) then
    raise EMatrixError.Create('Invalid random matrix bounds');
  State := Seed;
  Matrix := TMatrixKit.Create(Rows, Cols);
  Result := Matrix;
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Matrix.FData[I, J] := Min + NextUnit * (Max - Min);
end;

function TMatrixKit.IsVector: Boolean;
begin
  Result := (GetRows = 1) or (GetCols = 1);
end;

function TMatrixKit.IsColumnVector: Boolean;
begin
  Result := GetCols = 1;
end;

function TMatrixKit.IsRowVector: Boolean;
begin
  Result := GetRows = 1;
end;

function TMatrixKit.DotProduct(const Other: IMatrix): Double;
var
  I: Integer;
  Sum: Double;
begin
  if not (IsVector and Other.IsVector) then
    raise EMatrixError.Create('Dot product requires both operands to be vectors');
    
  // Case 1: Both are row vectors
  if IsRowVector and Other.IsRowVector and (GetCols = Other.Cols) then
  begin
    Sum := 0;
    for I := 0 to GetCols - 1 do
      Sum := Sum + FData[0, I] * Other.GetValue(0, I);
    Result := Sum;
  end
  // Case 2: Both are column vectors
  else if IsColumnVector and Other.IsColumnVector and (GetRows = Other.Rows) then
  begin
    Sum := 0;
    for I := 0 to GetRows - 1 do
      Sum := Sum + FData[I, 0] * Other.GetValue(I, 0);
    Result := Sum;
  end
  // Case 3: First is row vector, second is column vector
  else if IsRowVector and Other.IsColumnVector and (GetCols = Other.Rows) then
  begin
    Sum := 0;
    for I := 0 to GetCols - 1 do
      Sum := Sum + FData[0, I] * Other.GetValue(I, 0);
    Result := Sum;
  end
  // Case 4: First is column vector, second is row vector
  else if IsColumnVector and Other.IsRowVector and (GetRows = Other.Cols) then
  begin
    Sum := 0;
    for I := 0 to GetRows - 1 do
      Sum := Sum + FData[I, 0] * Other.GetValue(0, I);
    Result := Sum;
  end
  else
    raise EMatrixError.Create('Vector dimensions do not match for dot product');
end;

function TMatrixKit.CrossProduct(const Other: IMatrix): IMatrix;
var
  ResultMatrix: TMatrixKit;
begin
  // Only defined for 3D vectors
  if not (IsColumnVector and Other.IsColumnVector and (GetRows = 3) and (Other.Rows = 3)) then
    raise EMatrixError.Create('Cross product requires two 3D column vectors');
    
  ResultMatrix := TMatrixKit.Create(3, 1);
  ResultMatrix.SetValue(0, 0, FData[1, 0] * Other.GetValue(2, 0) - FData[2, 0] * Other.GetValue(1, 0));
  ResultMatrix.SetValue(1, 0, FData[2, 0] * Other.GetValue(0, 0) - FData[0, 0] * Other.GetValue(2, 0));
  ResultMatrix.SetValue(2, 0, FData[0, 0] * Other.GetValue(1, 0) - FData[1, 0] * Other.GetValue(0, 0));
  
  Result := ResultMatrix;
end;

function TMatrixKit.Normalize: IMatrix;
var
  I: Integer;
  Norm: Double;
  ResultMatrix: TMatrixKit;
begin
  
  if not IsVector then
    raise EMatrixError.Create('Normalize requires a vector');
    
  Norm := 0;
  
  // Calculate Euclidean norm
  if IsColumnVector then
  begin
    for I := 0 to GetRows - 1 do
      Norm := Norm + Sqr(FData[I, 0]);
    
    if Norm < 1E-12 then
      raise EMatrixError.Create('Cannot normalize zero vector');
    
    Norm := Sqrt(Norm);
    
    // Create normalized vector
    ResultMatrix := TMatrixKit.Create(GetRows, 1);
    for I := 0 to GetRows - 1 do
      ResultMatrix.FData[I, 0] := FData[I, 0] / Norm;
  end
  else // IsRowVector
  begin
    for I := 0 to GetCols - 1 do
      Norm := Norm + Sqr(FData[0, I]);
    
    if Norm < 1E-12 then
      raise EMatrixError.Create('Cannot normalize zero vector');
    
    Norm := Sqrt(Norm);
    
    // Create normalized vector
    ResultMatrix := TMatrixKit.Create(1, GetCols);
    for I := 0 to GetCols - 1 do
      ResultMatrix.FData[0, I] := FData[0, I] / Norm;
  end;
  
  Result := ResultMatrix;
end;

function TMatrixKit.Mean(Axis: Integer = -1): IMatrix;
var
  I, J: Integer;
  Sum: Double;
  ResultMatrix: TMatrixKit;
begin
  if Axis < 0 then
  begin
    ResultMatrix := TMatrixKit.Create(1, 1);
    Sum := 0;
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        Sum := Sum + FData[I, J];
    ResultMatrix.SetValue(0, 0, Sum / (GetRows * GetCols));
    Result := ResultMatrix;
  end
  else if Axis = 0 then
  begin
    ResultMatrix := TMatrixKit.Create(1, GetCols);
    for J := 0 to GetCols - 1 do
    begin
      Sum := 0;
      for I := 0 to GetRows - 1 do
        Sum := Sum + FData[I, J];
      ResultMatrix.SetValue(0, J, Sum / GetRows);
    end;
    Result := ResultMatrix;
  end
  else if Axis = 1 then
  begin
    ResultMatrix := TMatrixKit.Create(GetRows, 1);
    for I := 0 to GetRows - 1 do
    begin
      Sum := 0;
      for J := 0 to GetCols - 1 do
        Sum := Sum + FData[I, J];
      ResultMatrix.SetValue(I, 0, Sum / GetCols);
    end;
    Result := ResultMatrix;
  end
  else
    raise EMatrixError.Create('Invalid axis for mean calculation');
end;

function TMatrixKit.Covariance: IMatrix;
var
  I, J, K: Integer;
  MeanMatrix: IMatrix;
  ResultMatrix: TMatrixKit;
  ColMeans: array of Double;
begin
  if (GetRows <= 1) or (GetCols <= 1) then
    raise EMatrixError.Create('Covariance requires at least two elements');
    
  // Get column means
  MeanMatrix := Mean(0);  // Column means (1 x Cols matrix)
  SetLength(ColMeans, GetCols);
  for J := 0 to GetCols - 1 do
    ColMeans[J] := MeanMatrix.GetValue(0, J);
    
  ResultMatrix := TMatrixKit.Create(GetCols, GetCols);
  
  // Compute covariance matrix
  for I := 0 to GetCols - 1 do
    for J := 0 to GetCols - 1 do
    begin
      ResultMatrix.SetValue(I, J, 0.0);
      for K := 0 to GetRows - 1 do
        ResultMatrix.SetValue(I, J, ResultMatrix.GetValue(I, J) + 
          (FData[K, I] - ColMeans[I]) * (FData[K, J] - ColMeans[J]));
      ResultMatrix.SetValue(I, J, ResultMatrix.GetValue(I, J) / (GetRows - 1));
    end;
    
  Result := ResultMatrix;
end;

function TMatrixKit.Correlation: IMatrix;
var
  I, J: Integer;
  CovMatrix: IMatrix;
  ResultMatrix: TMatrixKit;
  StdDev: array of Double;
begin
  if (GetRows <= 1) or (GetCols <= 1) then
    raise EMatrixError.Create('Correlation requires at least two elements');
    
  CovMatrix := Covariance;
  ResultMatrix := TMatrixKit.Create(GetCols, GetCols);
  
  // Get standard deviations from diagonal of covariance matrix
  SetLength(StdDev, GetCols);
  for I := 0 to GetCols - 1 do
    StdDev[I] := Sqrt(CovMatrix.GetValue(I, I));
  
  // Compute correlation matrix
  for I := 0 to GetCols - 1 do
    for J := 0 to GetCols - 1 do
      if (StdDev[I] > 0) and (StdDev[J] > 0) then
        ResultMatrix.SetValue(I, J, CovMatrix.GetValue(I, J) / (StdDev[I] * StdDev[J]))
      else
        ResultMatrix.SetValue(I, J, 0.0);
        
  Result := ResultMatrix;
end;

function TMatrixKit.SolveIterative(
  const B: IMatrix;
  Method: TIterativeMethod = imConjugateGradient;
  MaxIterations: Integer = 1000;
  Tolerance: Double = 1e-10): IMatrix;
var
  X, R, P, AP, Temp: IMatrix;
  Alpha, Beta, RDotR, OldRDotR, NormB, ResidualNorm, PDotAP: Double;
  DiagA: IMatrix;
  I, J, Iter: Integer;
  Converged: Boolean;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix must be square for iterative solvers');
    
  if B.GetCols <> 1 then
    raise EMatrixError.Create('Right-hand side must be a column vector');
    
  if GetRows <> B.GetRows then
    raise EMatrixError.Create('Matrix and right-hand side dimensions do not match');
  if MaxIterations <= 0 then
    raise EMatrixError.Create('Iterative solver requires MaxIterations > 0');
  if (Tolerance <= 0.0) or IsNan(Tolerance) or IsInfinite(Tolerance) then
    raise EMatrixError.Create('Iterative solver requires a finite positive tolerance');
  
  // Initialize solution vector X with zeros
  X := TMatrixKit.Zeros(GetRows, 1);
  
  // Compute the norm of B for convergence check
  NormB := 0.0;
  for I := 0 to B.GetRows - 1 do
    NormB := NormB + Sqr(B.GetValue(I, 0));
  NormB := Sqrt(NormB);
  
  // If B is zero, return zero solution
  if Abs(NormB) < 1E-15 then
    Exit(X);

  Converged := False;
  case Method of
    imConjugateGradient:
    begin
      // Specialized for symmetric positive definite matrices
      
      // Initialize residual R = B - A*X (since X=0, R = B)
      R := TMatrixKit.Create(GetRows, 1);
      for I := 0 to GetRows - 1 do
        R.SetValue(I, 0, B.GetValue(I, 0));
      
      // Initialize direction vector P = R
      P := TMatrixKit.Create(GetRows, 1);
      for I := 0 to GetRows - 1 do
        P.SetValue(I, 0, R.GetValue(I, 0));
      
      // Initial R dot R
      RDotR := 0.0;
      for I := 0 to GetRows - 1 do
        RDotR := RDotR + Sqr(R.GetValue(I, 0));
      
      Iter := 0;
      Converged := False;
      
      while (not Converged) and (Iter < MaxIterations) do
      begin
        // Compute A*P
        AP := Multiply(P);
        
        // Compute alpha = (R dot R) / (P dot AP)
        PDotAP := 0.0;
        for I := 0 to GetRows - 1 do
          PDotAP := PDotAP + P.GetValue(I, 0) * AP.GetValue(I, 0);
        
        if Abs(PDotAP) < 1E-15 then
          raise EMatrixError.Create('Conjugate-gradient iteration broke down');
          
        Alpha := RDotR / PDotAP;
        
        // Update X = X + alpha*P
        for I := 0 to GetRows - 1 do
          X.SetValue(I, 0, X.GetValue(I, 0) + Alpha * P.GetValue(I, 0));
        
        // Update R = R - alpha*AP
        for I := 0 to GetRows - 1 do
          R.SetValue(I, 0, R.GetValue(I, 0) - Alpha * AP.GetValue(I, 0));
        
        // Compute new R dot R
        OldRDotR := RDotR;
        RDotR := 0.0;
        for I := 0 to GetRows - 1 do
          RDotR := RDotR + Sqr(R.GetValue(I, 0));
        
        // Check convergence
        ResidualNorm := Sqrt(RDotR) / NormB;
        Converged := ResidualNorm < Tolerance;
        
        if Converged then
          Break;
        
        // Compute beta = (new R dot R) / (old R dot R)
        Beta := RDotR / OldRDotR;
        
        // Update P = R + beta*P
        for I := 0 to GetRows - 1 do
          P.SetValue(I, 0, R.GetValue(I, 0) + Beta * P.GetValue(I, 0));
        
        Inc(Iter);
      end;
    end;
    
    imJacobi:
    begin
      // Extract diagonal of A
      DiagA := TMatrixKit.Create(GetRows, 1);
      for I := 0 to GetRows - 1 do
        DiagA.SetValue(I, 0, GetValue(I, I));
      
      // Initialize previous solution
      Temp := TMatrixKit.Zeros(GetRows, 1);
      
      Iter := 0;
      Converged := False;
      
      while (not Converged) and (Iter < MaxIterations) do
      begin
        // Save previous solution
        for I := 0 to GetRows - 1 do
          Temp.SetValue(I, 0, X.GetValue(I, 0));
        
        // Compute new X
        for I := 0 to GetRows - 1 do
        begin
          if Abs(DiagA.GetValue(I, 0)) < 1E-15 then
            raise EMatrixError.Create('Diagonal element near zero in Jacobi method');
            
          X.SetValue(I, 0, B.GetValue(I, 0));
          
          for J := 0 to GetRows - 1 do
            if J <> I then
              X.SetValue(I, 0, X.GetValue(I, 0) - GetValue(I, J) * Temp.GetValue(J, 0));
              
          X.SetValue(I, 0, X.GetValue(I, 0) / DiagA.GetValue(I, 0));
        end;
        
        // Check convergence
        ResidualNorm := 0.0;
        for I := 0 to GetRows - 1 do
          ResidualNorm := ResidualNorm + Sqr(X.GetValue(I, 0) - Temp.GetValue(I, 0));
        ResidualNorm := Sqrt(ResidualNorm) / NormB;
        
        Converged := ResidualNorm < Tolerance;
        Inc(Iter);
      end;
    end;
    
    imGaussSeidel:
    begin
      Iter := 0;
      Converged := False;
      
      while (not Converged) and (Iter < MaxIterations) do
      begin
        // Save previous solution
        Temp := TMatrixKit.Create(GetRows, 1);
        for I := 0 to GetRows - 1 do
          Temp.SetValue(I, 0, X.GetValue(I, 0));
        
        // Compute new X
        for I := 0 to GetRows - 1 do
        begin
          X.SetValue(I, 0, B.GetValue(I, 0));
          
          // Use updated values for already computed elements
          for J := 0 to I - 1 do
            X.SetValue(I, 0, X.GetValue(I, 0) - GetValue(I, J) * X.GetValue(J, 0));
            
          // Use previous values for not-yet-computed elements
          for J := I + 1 to GetRows - 1 do
            X.SetValue(I, 0, X.GetValue(I, 0) - GetValue(I, J) * Temp.GetValue(J, 0));
            
          if Abs(GetValue(I, I)) < 1E-15 then
            raise EMatrixError.Create('Diagonal element near zero in Gauss-Seidel method');
            
          X.SetValue(I, 0, X.GetValue(I, 0) / GetValue(I, I));
        end;
        
        // Check convergence
        ResidualNorm := 0.0;
        for I := 0 to GetRows - 1 do
          ResidualNorm := ResidualNorm + Sqr(X.GetValue(I, 0) - Temp.GetValue(I, 0));
        ResidualNorm := Sqrt(ResidualNorm) / NormB;
        
        Converged := ResidualNorm < Tolerance;
        Inc(Iter);
      end;
    end;
  end;

  if not Converged then
    raise EMatrixError.CreateFmt(
      'Iterative solver did not converge after %d iterations', [MaxIterations]);
  
  Result := X;
end;

function TMatrixKit.PowerMethod(MaxIterations: Integer = 100; Tolerance: Double = 1e-10): TEigenpair;
var
  X, AX: IMatrix;
  Lambda, Norm, Diff: Double;
  I, J: Integer;
  Converged: Boolean;
  Iter: Integer;
  Sum: Double;
begin
  if not IsSquare then
    raise EMatrixError.Create('Power method requires a square matrix');
  if MaxIterations <= 0 then
    raise EMatrixError.Create('Power method requires MaxIterations > 0');
  if (Tolerance <= 0) or IsNan(Tolerance) or IsInfinite(Tolerance) then
    raise EMatrixError.Create('Power method requires a finite positive tolerance');

  // A deterministic, non-uniform initial vector makes tests reproducible while
  // avoiding the common all-ones vector's symmetry-related blind spots.
  X := TMatrixKit.Create(GetRows, 1);
  for I := 0 to GetRows - 1 do
    X.SetValue(I, 0, 1.0 / (I + 1));

  // Normalize initial vector
  Norm := 0.0;
  for I := 0 to GetRows - 1 do
    Norm := Norm + Sqr(X.GetValue(I, 0));
  Norm := Sqrt(Norm);
  
  if Norm < 1E-15 then
    raise EMatrixError.Create('Initial random vector is zero');
    
  for I := 0 to GetRows - 1 do
    X.SetValue(I, 0, X.GetValue(I, 0) / Norm);

  // Iterative power method
  Lambda := 0.0;
  Iter := 0;
  Converged := False;
  
  AX := TMatrixKit.Create(GetRows, 1);

  while (Iter < MaxIterations) and (not Converged) do
  begin
    for I := 0 to GetRows - 1 do
    begin
      Sum := 0.0;
      for J := 0 to GetCols - 1 do
        Sum := Sum + GetValue(I, J) * X.GetValue(J, 0);
      AX.SetValue(I, 0, Sum);
    end;

    Norm := 0.0;
    for I := 0 to GetRows - 1 do
      Norm := Norm + Sqr(AX.GetValue(I, 0));
    Norm := Sqrt(Norm);
    if Norm < 1E-15 then
      raise EMatrixError.Create('Eigenvector approximation is zero');
    for I := 0 to GetRows - 1 do
      X.SetValue(I, 0, AX.GetValue(I, 0) / Norm);

    Lambda := 0.0;
    for I := 0 to GetRows - 1 do
    begin
      Sum := 0.0;
      for J := 0 to GetCols - 1 do
        Sum := Sum + GetValue(I, J) * X.GetValue(J, 0);
      AX.SetValue(I, 0, Sum);
      Lambda := Lambda + X.GetValue(I, 0) * Sum;
    end;
    Diff := 0.0;
    for I := 0 to GetRows - 1 do
      Diff := Diff + Sqr(AX.GetValue(I, 0) - Lambda * X.GetValue(I, 0));
    Diff := Sqrt(Diff);
    Converged := Diff <= Tolerance * Max(1.0, Abs(Lambda));
    Inc(Iter);
  end;
  if not Converged then
    raise EMatrixError.CreateFmt(
      'Power method did not converge within %d iterations', [MaxIterations]);

  // Recompute the Rayleigh quotient for the final normalized vector.
  Lambda := 0.0;
  for I := 0 to GetRows - 1 do
  begin
    Sum := 0.0;
    for J := 0 to GetCols - 1 do
      Sum := Sum + GetValue(I, J) * X.GetValue(J, 0);
    Lambda := Lambda + X.GetValue(I, 0) * Sum;
  end;
  Result.EigenValue := Lambda;
  Result.EigenVector := X;
end;

class function TMatrixKit.CreateSparse(Rows, Cols: Integer): IMatrix;
begin
  Result := TMatrixKitSparse.Create(Rows, Cols);
end;

constructor TMatrixKitSparse.Create(Rows, Cols: Integer);
begin
  inherited Create(Rows, Cols);
  FElementCount := 0;
  FCapacity := 32; // Start with some reasonable capacity
  SetLength(FElements, FCapacity);
end;

destructor TMatrixKitSparse.Destroy;
begin
  SetLength(FElements, 0);
  inherited Destroy;
end;

procedure TMatrixKitSparse.EnsureCapacity(NewCount: Integer);
var
  NewCapacity: Integer;
begin
  if NewCount <= FCapacity then
    Exit;
    
  NewCapacity := FCapacity * 2;
  while NewCapacity < NewCount do
    NewCapacity := NewCapacity * 2;
    
  SetLength(FElements, NewCapacity);
  FCapacity := NewCapacity;
end;

function TMatrixKitSparse.GetValue(Row, Col: Integer): Double;
var
  I: Integer;
begin
  if (Row < 0) or (Row >= GetRows) or (Col < 0) or (Col >= GetCols) then
    raise EMatrixError.Create(Format('Index out of bounds [%d,%d]', [Row, Col]));
    
  Result := 0.0; // Default value for sparse matrix
  
  // Linear search (could be optimized to binary search if sorted)
  for I := 0 to FElementCount - 1 do
    if (FElements[I].Row = Row) and (FElements[I].Col = Col) then
    begin
      Result := FElements[I].Value;
      Break;
    end;
end;

procedure TMatrixKitSparse.SetValue(Row, Col: Integer; const Value: Double);
var
  I, InsertPos: Integer;
  Found: Boolean;
begin
  if (Row < 0) or (Row >= GetRows) or (Col < 0) or (Col >= GetCols) then
    raise EMatrixError.Create(Format('Index out of bounds [%d,%d]', [Row, Col]));
    
  // If value is zero, we might want to remove the element
  if Abs(Value) < 1E-15 then
  begin
    // Find and remove the element if it exists
    for I := 0 to FElementCount - 1 do
      if (FElements[I].Row = Row) and (FElements[I].Col = Col) then
      begin
        // Shift remaining elements
        if I < FElementCount - 1 then
          Move(FElements[I+1], FElements[I], SizeOf(TSparseElement) * (FElementCount - I - 1));
          
        Dec(FElementCount);
        Exit;
      end;
      
    // Element doesn't exist, nothing to do
    Exit;
  end;
  
  // Check if element already exists
  Found := False;
  for I := 0 to FElementCount - 1 do
    if (FElements[I].Row = Row) and (FElements[I].Col = Col) then
    begin
      FElements[I].Value := Value;
      Found := True;
      Break;
    end;
    
  if not Found then
  begin
    // Add new element
    EnsureCapacity(FElementCount + 1);
    
    // Find position to insert (maintain row-major order)
    InsertPos := FElementCount;
    for I := 0 to FElementCount - 1 do
      if (FElements[I].Row > Row) or 
         ((FElements[I].Row = Row) and (FElements[I].Col > Col)) then
      begin
        InsertPos := I;
        Break;
      end;
      
    // Shift elements to make room
    if InsertPos < FElementCount then
      Move(FElements[InsertPos], FElements[InsertPos+1], 
           SizeOf(TSparseElement) * (FElementCount - InsertPos));
           
    // Insert new element
    FElements[InsertPos].Row := Row;
    FElements[InsertPos].Col := Col;
    FElements[InsertPos].Value := Value;
    
    Inc(FElementCount);
  end;
end;

procedure TMatrixKitSparse.AddElement(Row, Col: Integer; Value: Double);
begin
  SetValue(Row, Col, Value);
end;

procedure TMatrixKitSparse.CompactStorage;
var
  I, J: Integer;
begin
  // Remove zero elements
  I := 0;
  while I < FElementCount do
  begin
    if Abs(FElements[I].Value) < 1E-15 then
    begin
      // Shift remaining elements
      for J := I to FElementCount - 2 do
        FElements[J] := FElements[J+1];
        
      Dec(FElementCount);
    end
    else
      Inc(I);
  end;
  
  // Resize array to minimal needed size (with some buffer)
  if FElementCount < FCapacity div 4 then
  begin
    FCapacity := FElementCount * 2;
    if FCapacity < 32 then
      FCapacity := 32;
      
    SetLength(FElements, FCapacity);
  end;
end;

class function TMatrixKit.CreateHilbert(Size: Integer): IMatrix;
var
  I, J: Integer;
  Matrix: TMatrixKit;
begin
  if Size <= 0 then
    raise EMatrixError.Create('Hilbert matrix size must be positive');
    
  Matrix := TMatrixKit.Create(Size, Size);
  Result := Matrix;
  
  for I := 0 to Size - 1 do
    for J := 0 to Size - 1 do
      Matrix.FData[I, J] := 1.0 / (I + J + 1);
end;

class function TMatrixKit.CreateToeplitz(const FirstRow, FirstCol: TDoubleArray): IMatrix;
var
  I, J: Integer;
  Rows, Cols: Integer;
  Matrix: TMatrixKit;
begin
  Rows := Length(FirstCol);
  Cols := Length(FirstRow);
  
  if (Rows = 0) or (Cols = 0) then
    raise EMatrixError.Create('First row and column arrays cannot be empty');
    
  // First elements of row and column must match
  if FirstRow[0] <> FirstCol[0] then
    raise EMatrixError.Create('First elements of row and column must be the same');
    
  Matrix := TMatrixKit.Create(Rows, Cols);
  Result := Matrix;
  
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      if J - I >= 0 then
        Matrix.FData[I, J] := FirstRow[J - I]
      else
        Matrix.FData[I, J] := FirstCol[I - J];
end;

class function TMatrixKit.CreateVandermonde(const Vector: TDoubleArray): IMatrix;
var
  I, J, N: Integer;
  Matrix: TMatrixKit;
begin
  N := Length(Vector);
  if N = 0 then
    raise EMatrixError.Create('Vector cannot be empty');
    
  Matrix := TMatrixKit.Create(N, N);
  Result := Matrix;
  
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Matrix.FData[I, J] := Math.Power(Vector[I], J);
end;

function TMatrixKit.SVD: TSVD;
var
  I, J, K, L, M, Iter: Integer;
  MaxIter: Integer;
  A, S, V: TMatrixKit;  // Removed U from here since we use A as U
  C, F, G, H, S1, X, Y, Z: Double;
  RV1: array of Double;
  Anorm, Scale: Double;
  Flag: Boolean;
begin
  MaxIter := 50;  // Usually converges in fewer iterations
  L := 0;
  
  // Initialize matrices
  A := TMatrixKit.Create(GetRows, GetCols);
  S := TMatrixKit.Create(GetRows, GetCols);
  V := TMatrixKit.Create(GetCols, GetCols);
  
    // Copy original matrix to A
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
        A.FData[I, J] := FData[I, J];
    
  SetLength(RV1, GetCols);
  
  // Householder reduction to bidiagonal form
  G := 0;
  Scale := 0;
  Anorm := 0;
  
        for I := 0 to GetCols - 1 do
        begin
    L := I + 1;
    RV1[I] := Scale * G;
    G := 0;
    S1 := 0;
    Scale := 0;
    
    if I < GetRows then
    begin
      for K := I to GetRows - 1 do
        Scale := Scale + Abs(A.FData[K, I]);
      
      if Scale <> 0 then
      begin
        for K := I to GetRows - 1 do
        begin
          A.FData[K, I] := A.FData[K, I] / Scale;
          S1 := S1 + Sqr(A.FData[K, I]);
        end;
        
        F := A.FData[I, I];
        G := -SignWithMagnitude(Sqrt(S1), F);
        H := F * G - S1;
        A.FData[I, I] := F - G;
        
        for J := L to GetCols - 1 do
        begin
          S1 := 0;
          for K := I to GetRows - 1 do
            S1 := S1 + A.FData[K, I] * A.FData[K, J];
          F := S1 / H;
          for K := I to GetRows - 1 do
            A.FData[K, J] := A.FData[K, J] + F * A.FData[K, I];
        end;
        
        for K := I to GetRows - 1 do
          A.FData[K, I] := Scale * A.FData[K, I];
      end;
    end;
    
    S.FData[I, I] := Scale * G;
    G := 0;
    S1 := 0;
    Scale := 0;
    
    if (I < GetRows) and (I <> GetCols - 1) then
          begin
      for K := L to GetCols - 1 do
        Scale := Scale + Abs(A.FData[I, K]);
      
      if Scale <> 0 then
            begin
        for K := L to GetCols - 1 do
        begin
          A.FData[I, K] := A.FData[I, K] / Scale;
          S1 := S1 + Sqr(A.FData[I, K]);
        end;
        
        F := A.FData[I, L];
        G := -SignWithMagnitude(Sqrt(S1), F);
        H := F * G - S1;
        A.FData[I, L] := F - G;
        
        for K := L to GetCols - 1 do
          RV1[K] := A.FData[I, K] / H;
        
        for J := L to GetRows - 1 do
        begin
          S1 := 0;
          for K := L to GetCols - 1 do
            S1 := S1 + A.FData[J, K] * A.FData[I, K];
          for K := L to GetCols - 1 do
            A.FData[J, K] := A.FData[J, K] + S1 * RV1[K];
        end;
        
        for K := L to GetCols - 1 do
          A.FData[I, K] := Scale * A.FData[I, K];
      end;
    end;
    
    Anorm := Max(Anorm, Abs(S.FData[I, I]) + Abs(RV1[I]));
  end;
  
  // Accumulation of right-hand transformations
  for I := GetCols - 1 downto 0 do
  begin
    if I < GetCols - 1 then
    begin
      if G <> 0 then
      begin
        for J := L to GetCols - 1 do
          V.FData[J, I] := (A.FData[I, J] / A.FData[I, L]) / G;
        
        for J := L to GetCols - 1 do
        begin
          S1 := 0;
          for K := L to GetCols - 1 do
            S1 := S1 + A.FData[I, K] * V.FData[K, J];
          for K := L to GetCols - 1 do
            V.FData[K, J] := V.FData[K, J] + S1 * V.FData[K, I];
        end;
      end;
      
      for J := L to GetCols - 1 do
      begin
        V.FData[I, J] := 0;
        V.FData[J, I] := 0;
      end;
    end;
    
    V.FData[I, I] := 1;
    G := RV1[I];
    L := I;
  end;
  
  // Accumulation of left-hand transformations
  for I := Min(GetRows - 1, GetCols - 1) downto 0 do
  begin
    L := I + 1;
    G := S.FData[I, I];
    
    if I < GetCols - 1 then
      for J := L to GetCols - 1 do
        A.FData[I, J] := 0;
    
    if G <> 0 then
    begin
      G := 1.0 / G;
      
      if I < GetCols - 1 then
      begin
        for J := L to GetCols - 1 do
        begin
          S1 := 0;
          for K := L to GetRows - 1 do
            S1 := S1 + A.FData[K, I] * A.FData[K, J];
          F := (S1 / A.FData[I, I]) * G;
          
          for K := I to GetRows - 1 do
            A.FData[K, J] := A.FData[K, J] + F * A.FData[K, I];
        end;
      end;
      
      for J := I to GetRows - 1 do
        A.FData[J, I] := A.FData[J, I] * G;
          end
          else
          begin
      for J := I to GetRows - 1 do
        A.FData[J, I] := 0;
    end;
    
    A.FData[I, I] := A.FData[I, I] + 1;
  end;
  
  // Diagonalization of the bidiagonal form
  for K := GetCols - 1 downto 0 do
        begin
    for Iter := 1 to MaxIter do
    begin
      Flag := True;
      
      // Test for splitting
      L := K;
      while L >= 0 do
      begin
        M := L - 1;
        if Abs(RV1[L]) + Anorm = Anorm then
        begin
          Flag := False;
          Break;
        end;
        if (M >= 0) and (Abs(S.FData[M, M]) + Anorm = Anorm) then
          Break;
        Dec(L);
      end;
      
      if Flag then
      begin
        C := 0;
        S1 := 1;
        
        for I := L to K do
        begin
          F := S1 * RV1[I];
          RV1[I] := C * RV1[I];
          
          if Abs(F) + Anorm = Anorm then
            Break;
            
          G := S.FData[I, I];
          H := Sqrt(F * F + G * G);
          S.FData[I, I] := H;
          C := G / H;
          S1 := -F / H;
          
          for J := 0 to GetRows - 1 do
          begin
            Y := A.FData[J, M];
            Z := A.FData[J, I];
            A.FData[J, M] := Y * C + Z * S1;
            A.FData[J, I] := -Y * S1 + Z * C;
          end;
        end;
      end;
      
      Z := S.FData[K, K];
      
      if L = K then
      begin
        if Z < 0 then
        begin
          S.FData[K, K] := -Z;
          for J := 0 to GetCols - 1 do
            V.FData[J, K] := -V.FData[J, K];
        end;
        Break;
      end;
      
      if Iter >= MaxIter then
        raise EMatrixError.Create('SVD did not converge');
        
      X := S.FData[L, L];
      Y := S.FData[K - 1, K - 1];
      G := RV1[K - 1];
      H := RV1[K];
      F := ((Y - Z) * (Y + Z) + (G - H) * (G + H)) / (2 * H * Y);
      G := Sqrt(F * F + 1);
      F := ((X - Z) * (X + Z) + H * (Y / (F + SignWithMagnitude(G, F)) - H)) / X;
      
      // Next QR transformation
      C := 1;
      S1 := 1;
      
      for J := L to K - 1 do
      begin
        I := J + 1;
        G := RV1[I];
        Y := S.FData[I, I];
        H := S1 * G;
        G := C * G;
        
        Z := Sqrt(F * F + H * H);
        RV1[J] := Z;
        C := F / Z;
        S1 := H / Z;
        F := X * C + G * S1;
        G := -X * S1 + G * C;
        H := Y * S1;
        Y := Y * C;
        
        for M := 0 to GetCols - 1 do
        begin
          X := V.FData[M, J];
          Z := V.FData[M, I];
          V.FData[M, J] := X * C + Z * S1;
          V.FData[M, I] := -X * S1 + Z * C;
        end;
        
        Z := Sqrt(F * F + H * H);
        S.FData[J, J] := Z;
        
        if Z <> 0 then
        begin
          Z := 1 / Z;
          C := F * Z;
          S1 := H * Z;
        end;
        
        F := C * G + S1 * Y;
        X := -S1 * G + C * Y;
        
        for M := 0 to GetRows - 1 do
        begin
          Y := A.FData[M, J];
          Z := A.FData[M, I];
          A.FData[M, J] := Y * C + Z * S1;
          A.FData[M, I] := -Y * S1 + Z * C;
        end;
      end;
      
      RV1[L] := 0;
      RV1[K] := F;
      S.FData[K, K] := X;
    end;
  end;
  
  // Copy final matrices to result
  Result.U := A;  // A is used as U matrix
  Result.S := S;
  Result.V := V;
end;

function TMatrixKit.Cholesky: TCholeskyDecomposition;
var
  I, J, K: Integer;
  Sum: Double;
  L: TMatrixKit;
begin
  if not IsSquare then
    raise EMatrixError.Create('Cholesky decomposition requires square matrix');
    
  L := TMatrixKit.Create(GetRows, GetRows);
  try
    for I := 0 to GetRows - 1 do
    begin
      for J := 0 to I do
      begin
        Sum := 0;

        if J = I then  // Diagonal elements
        begin
          for K := 0 to J - 1 do
            Sum := Sum + Sqr(L.FData[J, K]);

          if FData[J, J] - Sum < 0 then
            raise EMatrixError.Create('Matrix is not positive definite');
          L.FData[J, J] := Sqrt(FData[J, J] - Sum);
        end
        else  // Lower triangular elements
        begin
          for K := 0 to J - 1 do
            Sum := Sum + L.FData[I, K] * L.FData[J, K];
            
          L.FData[I, J] := (FData[I, J] - Sum) / L.FData[J, J];
        end;
      end;
    end;
    
    Result.L := L;
    L := nil; // Set to nil to prevent double free
  finally
    if Assigned(L) then L.Free;
  end;
end;

function TMatrixKit.PseudoInverse: IMatrix;
var
  SVDResult: TSVD;
  SInverse: IMatrix;
  I: Integer;
  Tolerance: Double;
begin
  // Compute SVD: A = U * S * V^T
  SVDResult := SVD;
  
  // Create inverse of S by inverting non-zero singular values
  SInverse := TMatrixKit.Create(GetCols, GetRows);
    Tolerance := 1E-12 * SVDResult.S.GetValue(0, 0);  // Relative to largest singular value
    
    for I := 0 to Min(GetRows, GetCols) - 1 do
      if Abs(SVDResult.S.GetValue(I, I)) > Tolerance then
      SInverse.Values[I, I] := 1.0 / SVDResult.S.GetValue(I, I);
    
    // Compute pseudoinverse: A^+ = V * S^+ * U^T
  // All matrices are IMatrix interfaces and will be automatically freed
    Result := SVDResult.V.Multiply(SInverse).Multiply(SVDResult.U.Transpose);
end;

function TMatrixKit.Exp: IMatrix;
var
  I, J, K, Squarings: Integer;
  MatrixNorm, ScaleFactor, TermNorm, SumNorm: Double;
  Scaled, Term, NextTerm, Sum: IMatrix;
  Converged: Boolean;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix exponential requires square matrix');
  
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
      if IsNan(FData[I, J]) or IsInfinite(FData[I, J]) then
        raise EMatrixError.Create('Matrix exponential requires finite elements');

  { Scaling and squaring keeps the Taylor argument small. Terms are generated
    recursively, and convergence is tested relative to the accumulated sum. }
  MatrixNorm := NormInf;
  ScaleFactor := 1.0;
  Squarings := 0;
  while MatrixNorm / ScaleFactor > 0.5 do
  begin
    if ScaleFactor > MaxDouble / 2.0 then
      raise EMatrixError.Create('Matrix exponential scaling overflow');
    ScaleFactor := ScaleFactor * 2.0;
    Inc(Squarings);
  end;
  Scaled := ScalarMultiply(1.0 / ScaleFactor);
  Sum := TMatrixKit.Identity(GetRows);
  Term := TMatrixKit.Identity(GetRows);
  Converged := MatrixNorm = 0.0;
  for K := 1 to 100 do
  begin
    { The explicit Double cast avoids FPC treating an isolated real/integer
      quotient as a lower-precision Real expression on some targets. }
    NextTerm := Term.Multiply(Scaled).ScalarMultiply(Double(1.0) / K);
    Term := NextTerm;
    Sum := Sum.Add(Term);
    TermNorm := Term.NormInf;
    SumNorm := Sum.NormInf;
    if TermNorm <= 1E-15 * Max(1.0, SumNorm) then
    begin
      Converged := True;
      Break;
    end;
  end;
  if not Converged then
    raise EMatrixError.Create('Matrix exponential series did not converge');
  try
    for K := 1 to Squarings do
    begin
      Sum := Sum.Multiply(Sum);
      for I := 0 to GetRows - 1 do
        for J := 0 to GetCols - 1 do
          if IsNan(Sum.GetValue(I, J)) or IsInfinite(Sum.GetValue(I, J)) then
            raise EMatrixError.Create('Matrix exponential result overflowed');
    end;
    Result := Sum;
  except
    on E: EMatrixError do raise;
    on E: EOverflow do
      raise EMatrixError.Create('Matrix exponential result overflowed');
    on E: EInvalidOp do
      raise EMatrixError.Create('Matrix exponential result overflowed');
  end;
end;

function TMatrixKit.Power(exponent: Double): IMatrix;
var
  I, J: Integer;
  IntegerExponent, PowerCount: Int64;
  Base, Accumulator, PowerDiagonal: IMatrix;
  EigenResult: TEigenDecomposition;
  Tolerance, Scale: Double;
begin
  if not IsSquare then
    raise EMatrixError.Create('Matrix power requires square matrix');
  if IsNan(exponent) or IsInfinite(exponent) then
    raise EMatrixError.Create('Matrix power requires a finite exponent');
  if Abs(exponent) > MaxInt then
    raise EMatrixError.Create('Matrix power exponent is too large');

  IntegerExponent := Round(exponent);
  if Abs(exponent - IntegerExponent) <= 1E-12 then
  begin
    if IntegerExponent < 0 then
      Base := Inverse
    else
      Base := Self;
    PowerCount := Abs(IntegerExponent);
    Accumulator := TMatrixKit.Identity(GetRows);
    while PowerCount > 0 do
    begin
      if Odd(PowerCount) then
        Accumulator := Accumulator.Multiply(Base);
      PowerCount := PowerCount div 2;
      if PowerCount > 0 then
        Base := Base.Multiply(Base);
    end;
    Result := Accumulator;
  end
  else
  begin
    Scale := 1.0;
    for I := 0 to GetRows - 1 do
      for J := 0 to GetCols - 1 do
      begin
        Scale := Max(Scale, Abs(FData[I, J]));
        if Abs(FData[I, J] - FData[J, I]) > 1E-12 * Scale then
          raise EMatrixError.Create(
            'Fractional matrix powers require a symmetric positive-definite matrix');
      end;
    Tolerance := 1E-12 * Scale;
    EigenResult := EigenDecomposition;
    PowerDiagonal := TMatrixKit.Zeros(GetRows, GetRows);
    for I := 0 to GetRows - 1 do
    begin
      if EigenResult.EigenValues[I] <= Tolerance then
        raise EMatrixError.Create(
          'Fractional matrix powers require strictly positive eigenvalues');
      PowerDiagonal.SetValue(I, I,
        Math.Power(EigenResult.EigenValues[I], exponent));
    end;
    Result := EigenResult.EigenVectors.Multiply(PowerDiagonal).Multiply(
      EigenResult.EigenVectors.Transpose);
  end;
end;

{ TEigenpair }

function TEigenpair.ToString: string;
begin
  Result := 'EigenValue: ' + FloatToStr(EigenValue) + sLineBreak;
  Result := Result + 'EigenVector: ' + sLineBreak;
  Result := Result + EigenVector.ToString;
end;

{ TLUDecomposition }

function TLUDecomposition.ToString: string;
var
  PStr: string;
  I: Integer;
begin
  // Format permutation array
  PStr := '[';
  for I := 0 to High(P) do
  begin
    PStr := PStr + IntToStr(P[I]);
    if I < High(P) then
      PStr := PStr + ', ';
  end;
  PStr := PStr + ']';
  
  Result := 'LU Decomposition:' + sLineBreak +
            'L =' + sLineBreak + L.ToString + sLineBreak +
            'U =' + sLineBreak + U.ToString + sLineBreak +
            'P = ' + PStr;
end;

{ TQRDecomposition }

function TQRDecomposition.ToString: string;
begin
  Result := 'QR Decomposition:' + sLineBreak +
            'Q =' + sLineBreak + Q.ToString + sLineBreak +
            'R =' + sLineBreak + R.ToString;
end;

{ TEigenDecomposition }

function TEigenDecomposition.ToString: string;
var
  ValStr: string;
  I: Integer;
begin
  // Format eigenvalues array
  ValStr := '[';
  for I := 0 to High(EigenValues) do
  begin
    ValStr := ValStr + FloatToStr(EigenValues[I]);
    if I < High(EigenValues) then
      ValStr := ValStr + ', ';
  end;
  ValStr := ValStr + ']';
  
  Result := 'Eigendecomposition:' + sLineBreak +
            'EigenValues = ' + ValStr + sLineBreak +
            'EigenVectors =' + sLineBreak + EigenVectors.ToString;
end;

{ TSVD }

function TSVD.ToString: string;
begin
  Result := 'Singular Value Decomposition:' + sLineBreak +
            'U =' + sLineBreak + U.ToString + sLineBreak +
            'S =' + sLineBreak + S.ToString + sLineBreak +
            'V =' + sLineBreak + V.ToString;
end;

{ TCholeskyDecomposition }

function TCholeskyDecomposition.ToString: string;
begin
  Result := 'Cholesky Decomposition:' + sLineBreak +
            'L =' + sLineBreak + L.ToString;
end;

function TMatrixKitSparse.Add(const Other: IMatrix): IMatrix;
var
  I, J: Integer;
  ResultMatrix: TMatrixKit;
  Value: Double;
begin
  if (GetRows <> Other.GetRows) or (GetCols <> Other.GetCols) then
    raise EMatrixError.Create('Matrix dimensions do not match for addition');
    
  // Create result matrix
  ResultMatrix := TMatrixKit.Create(GetRows, GetCols);
  
  // Special case: If we're adding the same exact object, we need to double the values
  // First collect all non-zero values from self
  for I := 0 to FElementCount - 1 do
    ResultMatrix.SetValue(FElements[I].Row, FElements[I].Col, FElements[I].Value);
  
  // Add values from other matrix
  for I := 0 to GetRows - 1 do
    for J := 0 to GetCols - 1 do
    begin
      Value := ResultMatrix.GetValue(I, J) + Other.GetValue(I, J);
      ResultMatrix.SetValue(I, J, Value);
    end;
    
  Result := ResultMatrix;
end;

end.
