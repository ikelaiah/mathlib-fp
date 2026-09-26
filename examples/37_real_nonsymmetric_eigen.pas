program real_nonsymmetric_eigen;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSpectral;

var
  A: IDenseDoubleMatrix;
  Factor: IDenseDoubleRealEigen;
  Values: TComplexArray;
  I: SizeInt;
  MaxResidual: Double;
begin
  A := TDenseDoubleMatrix.FromValues(4, 4,
    [1.0, 1.0, 0.0, 0.0,
     0.0, 2.0, 0.0, 0.0,
     0.0, 0.0, 0.0, -1.0,
     0.0, 0.0, 1.0, 0.0]);
  Factor := FactorRealEigen(A, reoRealPart);
  Values := Factor.Eigenvalues;
  MaxResidual := 0.0;
  for I := 0 to Factor.Size - 1 do
    MaxResidual := Max(MaxResidual, Factor.Residuals[I]);

  if (Abs(Values[0].Re) > 1E-12) or
    (Abs(Values[0].Im - 1.0) > 1E-12) or
    (Abs(Values[1].Im + 1.0) > 1E-12) or
    (Abs(Values[2].Re - 1.0) > 1E-12) or
    (Abs(Values[3].Re - 2.0) > 1E-12) then
    raise Exception.Create('Unexpected eigenvalue ordering or values.');
  if (not Factor.Converged) or (MaxResidual > 1E-12) then
    raise Exception.Create('Eigenpair residual or convergence check failed.');

  for I := 0 to Factor.Size - 1 do
    WriteLn('lambda[', I, '] = ', Values[I].Re:0:6, ' + ',
      Values[I].Im:0:6, 'i');
  WriteLn('maximum normalized residual = ', MaxResidual:0:12);
  WriteLn('Real nonsymmetric eigensystem: success');
end.
