unit AlgebraLib.Determinants;

{-----------------------------------------------------------------------------
 AlgebraLib.Determinants

 Re-exports decomposition records and determinant-related types from
 AlgebraLib.Matrices.

 All decomposition logic lives in AlgebraLib.Matrices (uMatrices.pas) because
 the algorithms are tightly coupled to the TMatrixKit implementation.
 This unit provides a named entry point for code that is specifically focused
 on decompositions and matrix properties.

 Re-exported types (available via uses clause):
   TLUDecomposition    — PA = LU factorisation
   TQRDecomposition    — A = QR factorisation
   TEigenDecomposition — A = VDV⁻¹ factorisation
   TSVD                — A = USVᵀ factorisation
   TCholeskyDecomposition — A = LLᵀ factorisation
   TEigenpair          — (eigenvalue, eigenvector) pair from power iteration
   TIterativeMethod    — enum for iterative solvers (aliased as TIterSolverMethod)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  AlgebraLib.Matrices;

{ All decomposition record types are declared in AlgebraLib.Matrices and are
  available to any unit that uses AlgebraLib.Determinants via its uses clause.
  Only the enum alias is declared here since FPC does not permit cross-unit
  record aliases with the plain = syntax. }
type
  TIterSolverMethod = TIterativeMethod;

implementation

end.
