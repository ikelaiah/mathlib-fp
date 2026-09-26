program generalized_eigenproblem;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  MathBase.Complex,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSpectral;

var
  AReal, BReal: IDenseDoubleMatrix;
  AComplex, BComplex: IDenseComplexMatrix;
  RealEigen: IDenseDoubleGeneralizedEigen;
  ComplexEigen: IDenseComplexGeneralizedEigen;
  I: SizeInt;
  MaxResidual: Double;
begin
  AReal := TDenseDoubleMatrix.FromValues(2, 2,
    [6.0, 0.0,
     0.0, 4.0]);
  BReal := TDenseDoubleMatrix.FromValues(2, 2,
    [3.0, 0.0,
     0.0, 0.0]);
  RealEigen := FactorRealGeneralizedEigen(AReal, BReal);
  MaxResidual := 0.0;
  for I := 0 to RealEigen.Size - 1 do
    MaxResidual := Max(MaxResidual, RealEigen.Residuals[I]);
  if (Abs(RealEigen.Alpha[0].Re / RealEigen.Beta[0].Re - 2.0) > 1E-12) or
    (RealEigen.Beta[1].Magnitude <> 0.0) or (MaxResidual > 1E-12) then
    raise Exception.Create('Unexpected real generalized eigenpairs.');
  WriteLn('real lambda[0] = ',
    (RealEigen.Alpha[0].Re / RealEigen.Beta[0].Re):0:6);
  WriteLn('real lambda[1] = infinity');
  WriteLn('real maximum normalized residual = ', MaxResidual:0:12);

  AComplex := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(6.0, 2.0), TComplex.Zero,
     TComplex.Zero, TComplex.Create(4.0, 0.0)]);
  BComplex := TDenseComplexMatrix.FromValues(2, 2,
    [TComplex.Create(3.0, 1.0), TComplex.Zero,
     TComplex.Zero, TComplex.Zero]);
  ComplexEigen := FactorComplexGeneralizedEigen(AComplex, BComplex);
  MaxResidual := 0.0;
  for I := 0 to ComplexEigen.Size - 1 do
    MaxResidual := Max(MaxResidual, ComplexEigen.Residuals[I]);
  if ((ComplexEigen.Alpha[0] / ComplexEigen.Beta[0] - 2.0).Magnitude >
      1E-12) or (ComplexEigen.Beta[1].Magnitude <> 0.0) or
      (MaxResidual > 1E-12) then
    raise Exception.Create('Unexpected complex generalized eigenpairs.');
  WriteLn('complex lambda[0] = ',
    (ComplexEigen.Alpha[0] / ComplexEigen.Beta[0]).Re:0:6);
  WriteLn('complex lambda[1] = infinity');
  WriteLn('complex maximum normalized residual = ', MaxResidual:0:12);
  WriteLn('Generalized eigenproblem: success');
end.
