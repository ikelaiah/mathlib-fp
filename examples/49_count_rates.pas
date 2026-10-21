program CountRates;
{$mode objfpc}{$H+}{$J-}
uses SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices, StatsLib.GLM;
var X, NewX: IDenseDoubleMatrix; Inputs, NewInputs: TGLMInputs;
  Fit: TGLMFitResult; Counts: TDoubleArray; Rate: Double;
begin
  { Analytic count fixture: mean = exposure * 2 * 2^predictor. }
  X := TDenseDoubleMatrix.FromValues(3,2,[1,0, 1,1, 1,2]);
  Inputs := TGLMInputs.Default;
  Inputs.Exposures := TDoubleArray.Create(1,2,1);
  Fit := TGLMKit.FitPoisson(X,[2,8,8],Inputs);
  if not Fit.Identifiable then raise Exception.Create(Fit.Message);
  NewX := TDenseDoubleMatrix.FromValues(1,2,[1,1]);
  NewInputs := TGLMInputs.Default;
  NewInputs.Exposures := TDoubleArray.Create(3);
  Counts := TGLMKit.PredictMean(Fit,NewX,NewInputs);
  Rate := Counts[0] / NewInputs.Exposures[0];
  if (Abs(Counts[0]-12) > 1E-7) or (Abs(Rate-4) > 1E-7) then
    raise Exception.Create('Count-rate analytic reference missed.');
  Writeln('Poisson exposure fit: converged');
  Writeln('new exposure=3; expected count=',Counts[0]:0:6,'; rate=',Rate:0:6);
  Writeln('Prediction requires an exposure for each new observation.');
  Writeln('count rates: success');
end.
