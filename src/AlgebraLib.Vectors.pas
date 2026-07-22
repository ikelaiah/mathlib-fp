unit AlgebraLib.Vectors;

{-----------------------------------------------------------------------------
 AlgebraLib.Vectors

 Re-exports the vector-relevant types and functionality from AlgebraLib.Matrices
 and AlgebraLib.VectorKernels.

 Vector operations are implemented on IMatrix instances — any matrix with a
 single row or column is treated as a vector.  The relevant IMatrix methods are:
   IsVector, IsRowVector, IsColumnVector
   DotProduct, CrossProduct, Normalize
   VectorMagnitude (via the 2-D helpers in MathBase.Trigonometry)

 Add this unit to your uses clause when you want explicit documentation that
 your code is vector-oriented. `IVector` retains the established matrix-vector
 API; `TRealVector` / `TComplexVector` and `TVectorKit` provide the
 complementary contiguous-array API introduced in 1.3.0.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  AlgebraLib.Matrices, AlgebraLib.VectorKernels, MathBase.Complex,
  MathBase.SharedTypes;

{ Re-export the core types so callers need only one uses entry. }
type
  IVector  = IMatrix;            // Alias: a vector is a 1-row or 1-col IMatrix
  TVector  = TMatrixKit;         // Concrete alias for construction
  TRealVector = TDoubleArray;
  TComplexVector = TComplexArray;
  EVectorError = AlgebraLib.VectorKernels.EVectorError;
  TVectorKit = AlgebraLib.VectorKernels.TVectorKit;

implementation

end.
