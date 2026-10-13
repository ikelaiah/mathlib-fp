program GeneralizedLinearModels;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices, StatsLib.GLM;

var
  Design, NewDesign: IDenseDoubleMatrix;
  Binary, Counts, Prediction: TDoubleArray;
  Logistic, Poisson, Separated: TGLMFitResult;
begin
  { Include an intercept explicitly; rows are observations. }
  Design := TDenseDoubleMatrix.FromValues(6, 2,
    [1,-2, 1,-1, 1,0, 1,1, 1,2, 1,3]);
  Binary := TDoubleArray.Create(0,1,0,1,0,1);
  Counts := TDoubleArray.Create(0,1,1,2,3,4);
  Logistic := TGLMKit.FitLogistic(Design, Binary);
  Poisson := TGLMKit.FitPoisson(Design, Counts);
  if not Logistic.Identifiable or not Poisson.Identifiable then
    raise Exception.Create('GLM example requires converged identifiable fits.');
  Writeln('logistic: converged, rank = ', Logistic.Rank);
  Writeln('logistic slope = ', Logistic.Coefficients[1]:0:6,
    ', standard error = ', Logistic.StandardErrors[1]:0:6);
  Writeln('logistic deviance = ', Logistic.Deviance:0:6,
    ', null deviance = ', Logistic.NullDeviance:0:6);
  Writeln('Poisson: converged, rank = ', Poisson.Rank);
  Writeln('Poisson slope = ', Poisson.Coefficients[1]:0:6,
    ', standard error = ', Poisson.StandardErrors[1]:0:6);
  Writeln('Poisson deviance = ', Poisson.Deviance:0:6,
    ', Pearson / df = ', (Poisson.PearsonChiSquare / Poisson.DegreesOfFreedom):0:6);
  NewDesign := TDenseDoubleMatrix.FromValues(2, 2, [1,0, 1,2]);
  Prediction := TGLMKit.PredictMean(Poisson, NewDesign);
  Writeln('predicted counts at x=0 and x=2: ', Prediction[0]:0:6, ', ', Prediction[1]:0:6);
  Separated := TGLMKit.FitLogistic(
    TDenseDoubleMatrix.FromValues(4, 2, [1,-2, 1,-1, 1,1, 1,2]),
    TDoubleArray.Create(0,0,1,1));
  if Separated.Status <> glsCompleteSeparation then
    raise Exception.Create('Expected a complete-separation certificate.');
  Writeln('separation: no finite logistic MLE, standard errors withheld');
  Writeln('GLM workflow: success');
end.
