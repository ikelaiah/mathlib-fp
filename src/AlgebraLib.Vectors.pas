unit AlgebraLib.Vectors;

{-----------------------------------------------------------------------------
 AlgebraLib.Vectors

 Re-exports the vector-relevant types and functionality from AlgebraLib.Matrices.

 Vector operations are implemented on IMatrix instances — any matrix with a
 single row or column is treated as a vector.  The relevant IMatrix methods are:
   IsVector, IsRowVector, IsColumnVector
   DotProduct, CrossProduct, Normalize
   VectorMagnitude (via the 2-D helpers in MathBase.Trigonometry)

 Add this unit to your uses clause together with AlgebraLib.Matrices when you
 want explicit documentation that your code is vector-oriented.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  AlgebraLib.Matrices;

{ Re-export the core types so callers need only one uses entry. }
type
  IVector  = IMatrix;            // Alias: a vector is a 1-row or 1-col IMatrix
  TVector  = TMatrixKit;         // Concrete alias for construction

implementation

end.
