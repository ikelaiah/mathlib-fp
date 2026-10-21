program FrequencyWeightedGLM;
{$mode objfpc}{$H+}{$J-}
uses SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices, StatsLib.GLM;
var X, RepeatedX, NewX: IDenseDoubleMatrix;
  Y, RepeatedY, A, B: TDoubleArray;
  Inputs, RepeatedInputs, NewInputs: TGLMInputs;
  Fit, RepeatedFit: TGLMFitResult;
  I, J, K, At: Integer;
begin
  X := TDenseDoubleMatrix.FromValues(3,2,[1,0,1,1,1,2]);
  Y := TDoubleArray.Create(1,8,7); Inputs := TGLMInputs.Default;
  Inputs.Exposures := TDoubleArray.Create(1,2,1);
  Inputs.FrequencyWeights := TGLMFrequencyWeights.Create(2,1,3);
  Fit := TGLMKit.FitPoisson(X,Y,Inputs);
  if not Fit.Identifiable then raise Exception.Create(Fit.Message);
  { Small explicit replication is an independent workflow check, not the
    implementation: frequency fitting itself never expands these rows. }
  RepeatedX := TDenseDoubleMatrix.Zeros(6,2); SetLength(RepeatedY,6);
  RepeatedInputs := TGLMInputs.Default; SetLength(RepeatedInputs.Exposures,6);
  At := 0;
  for I := 0 to 2 do
    for K := 1 to Integer(Inputs.FrequencyWeights[I]) do
    begin
      for J := 0 to 1 do RepeatedX[At,J] := X[I,J];
      RepeatedY[At] := Y[I]; RepeatedInputs.Exposures[At] := Inputs.Exposures[I];
      Inc(At);
    end;
  RepeatedFit := TGLMKit.FitPoisson(RepeatedX,RepeatedY,RepeatedInputs);
  if not RepeatedFit.Identifiable then raise Exception.Create(RepeatedFit.Message);
  NewX := TDenseDoubleMatrix.FromValues(1,2,[1,1]);
  NewInputs := TGLMInputs.Default; NewInputs.Exposures := TDoubleArray.Create(3);
  A := TGLMKit.PredictMean(Fit,NewX,NewInputs);
  B := TGLMKit.PredictMean(RepeatedFit,NewX,NewInputs);
  if (Abs(A[0]-B[0]) > 2E-7) or
    (Abs(Fit.NullDeviance-RepeatedFit.NullDeviance) > 2E-7) then
    raise Exception.Create('Frequency replication reference missed.');
  Writeln('stored rows=3; replicated observations=',Fit.FrequencyCount);
  Writeln('explicitly repeated fit: agrees');
  Writeln('Weights count independent repeated observations; prediction needs no weights.');
  Writeln('frequency weighted GLM: success');
end.
