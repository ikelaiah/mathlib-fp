program complex_schur_factorization;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels,
  AlgebraLib.DenseSpectral;

var
  A, Q, T, Reconstructed: IDenseComplexMatrix;
  Factor: IDenseComplexSchur;
  I, J: SizeInt;
  MaxResidual: Double;
begin
  A := TDenseComplexMatrix.FromValues(3, 3,
    [TComplex.Create(2.0, 1.0), TComplex.Create(1.0, -2.0),
      TComplex.Create(-1.0, 0.5),
     TComplex.Create(3.0, 0.25), TComplex.Create(-1.0, 2.0),
      TComplex.Create(4.0, -1.0),
     TComplex.Create(0.5, -3.0), TComplex.Create(2.0, 1.0),
      TComplex.Create(0.5, 0.0)]);
  Factor := FactorComplexSchur(A);
  Q := Factor.Q;
  T := Factor.T;
  Reconstructed := Multiply(Q, Multiply(T, ConjugateTranspose(Q)));
  MaxResidual := 0.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
    begin
      MaxResidual := Max(MaxResidual,
        (A[I, J] - Reconstructed[I, J]).Magnitude);
      if (I > J) and (T[I, J].Magnitude <> 0.0) then
        raise Exception.Create('T is not upper triangular.');
    end;
  if MaxResidual > 2E-10 then
    raise Exception.Create('Complex Schur reconstruction residual is too large.');

  WriteLn('matrix size = ', Factor.Size);
  WriteLn('Schur iterations = ', Factor.Iterations);
  WriteLn('Schur form = upper triangular');
  WriteLn('maximum reconstruction residual = ', MaxResidual:0:12);
  WriteLn('Complex Schur factorization: success');
end.
