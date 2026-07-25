program typed_dense_solve;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels,
  AlgebraLib.DenseSolvers;

var
  A, B, X, Residual: IDenseDoubleMatrix;
  Factors: IDenseDoubleLU;
begin
  A := TDenseDoubleMatrix.FromValues(3, 3,
    [3.0, 2.0, -1.0,
     2.0, -2.0, 4.0,
     -1.0, 0.5, -1.0]);
  B := TDenseDoubleMatrix.FromValues(3, 1, [1.0, -2.0, 0.0]);

  { Solve factors A once and uses triangular solves; it never forms A^-1. }
  X := Solve(A, B);
  Residual := Subtract(Multiply(A, X), B);
  WriteLn('x = [', X[0, 0]:0:6, ', ', X[1, 0]:0:6, ', ',
    X[2, 0]:0:6, ']');
  WriteLn('maximum residual = ',
    Max(Abs(Residual[0, 0]),
      Max(Abs(Residual[1, 0]), Abs(Residual[2, 0]))):0:3);

  { Keep a factor when solving the same A for more right-hand sides. }
  Factors := FactorLU(A);
  X := Factors.Solve(TDenseDoubleMatrix.FromValues(3, 2,
    [1.0, 2.0, -2.0, -4.0, 0.0, 0.0]));
  WriteLn('two-RHS first row = [', X[0, 0]:0:6, ', ', X[0, 1]:0:6, ']');
end.
