program real_schur_factorization;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels,
  AlgebraLib.DenseSpectral;

var
  A, Q, T, Reconstructed: IDenseDoubleMatrix;
  Factor: IDenseDoubleRealSchur;
  I, J: SizeInt;
  MaxResidual: Double;
begin
  A := TDenseDoubleMatrix.FromValues(4, 4,
    [4.0, 1.0, -2.0, 2.0,
     1.0, 2.0, 0.0, 1.0,
     3.0, -1.0, 1.0, 0.0,
     -2.0, 4.0, 1.0, 3.0]);
  Factor := FactorRealSchur(A);
  Q := Factor.Q;
  T := Factor.T;
  Reconstructed := Multiply(Q, Multiply(T, Transpose(Q)));
  MaxResidual := 0.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
    begin
      MaxResidual := Max(MaxResidual, Abs(A[I, J] - Reconstructed[I, J]));
      if (I > J + 1) and (T[I, J] <> 0.0) then
        raise Exception.Create('T is not upper quasi-triangular.');
    end;
  if MaxResidual > 1E-10 then
    raise Exception.Create('Schur reconstruction residual is too large.');

  WriteLn('matrix size = ', Factor.Size);
  WriteLn('Schur iterations = ', Factor.Iterations);
  WriteLn('Schur form = upper quasi-triangular');
  WriteLn('Real Schur factorization: success');
end.
