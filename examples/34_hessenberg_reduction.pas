program hessenberg_reduction;

{$mode objfpc}{$H+}{$J-}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSpectral;

var
  A, H: IDenseDoubleMatrix;
  Factor: IDenseDoubleHessenberg;
begin
  A := TDenseDoubleMatrix.FromValues(4, 4,
    [4.0, 1.0, -2.0, 2.0,
     1.0, 2.0, 0.0, 1.0,
     3.0, -1.0, 1.0, 0.0,
     -2.0, 4.0, 1.0, 3.0]);
  Factor := ReduceHessenberg(A);
  H := Factor.H;

  { Q is orthogonal and Q^T*A*Q=H. Hessenberg form retains a dense upper
    triangle and one subdiagonal while preserving the matrix eigenvalues. }
  WriteLn('matrix size = ', Factor.Size);
  WriteLn('H[3,0] = ', H[3, 0]:0:6);
  WriteLn('Hessenberg reduction: success');
end.
