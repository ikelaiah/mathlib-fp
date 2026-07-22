program MatrixOperations;

{-----------------------------------------------------------------------------
  03_matrix_operations.pas

  Introduces matrix creation, immutable-style arithmetic, common properties,
  inversion, and LU/QR decompositions. IMatrix values are reference-counted,
  so these local variables need no manual Free call.

  Build (FPC command line):
    mkdir lib
    fpc -Fu../src -FUlib 03_matrix_operations.pas

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  MathBase.SharedTypes,
  AlgebraLib.Matrices;   // TMatrixKit, IMatrix, TLUDecomposition, TQRDecomposition

var
  A, B, C, Inv: IMatrix;
  LU: TLUDecomposition;
  QR: TQRDecomposition;

begin
  // ── 1. Create matrices from literal arrays ───────────────────────────────
  // TMatrixKit.CreateFromArray takes a 2-D open array.
  // All rows must have the same column count.
  A := TMatrixKit.CreateFromArray([
    [3.0, 1.0, 2.0],
    [1.0, 4.0, 0.0],
    [2.0, 0.0, 5.0]
  ]);

  B := TMatrixKit.CreateFromArray([
    [1.0, 0.0, 0.0],
    [0.0, 2.0, 0.0],
    [0.0, 0.0, 3.0]
  ]);

  WriteLn('=== Matrix A ===');
  WriteLn(A.ToString);

  WriteLn('=== Matrix B (diagonal) ===');
  WriteLn(B.ToString);

  // ── 2. Basic arithmetic ───────────────────────────────────────────────
  // All operations return a new matrix; A and B are unchanged.
  C := A.Add(B);
  WriteLn('=== A + B ===');
  WriteLn(C.ToString);

  C := A.Multiply(B);
  WriteLn('=== A * B ===');
  WriteLn(C.ToString);

  C := A.ScalarMultiply(2.0);
  WriteLn('=== 2 * A ===');
  WriteLn(C.ToString);

  // ── 3. Properties ─────────────────────────────────────────────────────
  WriteLn('=== Properties of A ===');
  WriteLn(Format('  Rows        : %d',    [A.Rows]));
  WriteLn(Format('  Cols        : %d',    [A.Cols]));
  WriteLn(Format('  Determinant : %.4f',  [A.Determinant]));
  WriteLn(Format('  Trace       : %.4f',  [A.Trace]));
  WriteLn(Format('  Rank        : %d',    [A.Rank]));
  WriteLn(Format('  Frobenius   : %.4f',  [A.NormFrobenius]));
  WriteLn(Format('  Symmetric?  : %s',    [BoolToStr(A.IsSymmetric, True)]));
  WriteLn;

  // ── 4. Transpose and inverse ──────────────────────────────────────────
  WriteLn('=== Transpose of A ===');
  WriteLn(A.Transpose.ToString);

  Inv := A.Inverse;
  WriteLn('=== Inverse of A ===');
  WriteLn(Inv.ToString);

  // Verify: A * A^{-1} should be the identity
  C := A.Multiply(Inv);
  WriteLn('=== A * A^{-1} (should be I) ===');
  WriteLn(C.ToString);

  // ── 5. LU decomposition ───────────────────────────────────────────────
  // A = P^{-1} * L * U  (P stored as permutation indices)
  LU := A.LU;
  WriteLn('=== LU Decomposition of A ===');
  WriteLn(LU.ToString);

  // ── 6. QR decomposition ───────────────────────────────────────────────
  // A = Q * R  (Q orthogonal, R upper triangular)
  QR := A.QR;
  WriteLn('=== QR Decomposition of A ===');
  WriteLn(QR.ToString);

  // ── 7. Factory helpers ────────────────────────────────────────────────
  WriteLn('=== 3×3 Identity matrix ===');
  WriteLn(TMatrixKit.Identity(3).ToString);

  WriteLn('=== 2×3 Zeros matrix ===');
  WriteLn(TMatrixKit.Zeros(2, 3).ToString);

  WriteLn('=== 2×2 Ones matrix ===');
  WriteLn(TMatrixKit.Ones(2, 2).ToString);

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
