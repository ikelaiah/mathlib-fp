program complex_hessenberg_reduction;

{$mode objfpc}{$H+}{$J-}

uses
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSpectral;

var
  A, H: IDenseComplexMatrix;
  Factor: IDenseComplexHessenberg;
begin
  A := TDenseComplexMatrix.FromValues(3, 3,
    [TComplex.Create(1.0, 1.0), TComplex.Create(2.0, -1.0),
     TComplex.Create(0.0, 2.0), TComplex.Create(3.0, -2.0),
     TComplex.Create(4.0, 0.5), TComplex.Create(1.0, 0.0),
     TComplex.Create(-1.0, 1.5), TComplex.Create(2.0, 3.0),
     TComplex.Create(5.0, -1.0)]);
  Factor := ReduceHessenberg(A);
  H := Factor.H;

  { Q is unitary and Q^H*A*Q=H. }
  WriteLn('matrix size = ', Factor.Size);
  WriteLn('H[2,0] magnitude = ', H[2, 0].Magnitude:0:6);
  WriteLn('Complex Hessenberg reduction: success');
end.
