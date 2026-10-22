program PredictionPersistence;
{$mode objfpc}{$H+}{$J-}
uses Classes, SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices,
  MLLib.MachineLearning, MLLib.PLS, StatsLib.GLM, InterchangeLib.Models;
var X:IDenseDoubleMatrix; Rows:TDoubleMatrix; Y,A,B:TDoubleArray;
  Inputs,NewInputs:TGLMInputs; GLMFit:TGLMFitResult; PLSFit:TPLSModel;
  GLM:TGLMPredictionModel; PLS:TPLSPredictionModel;
  GLMStream,PLSStream:TMemoryStream; I:Integer; Directory:String;
begin
  X:=TDenseDoubleMatrix.FromValues(3,1,[1,1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Exposures:=TDoubleArray.Create(1,2,3);
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(2,1,3);
  GLMFit:=TGLMKit.FitPoisson(X,[2,4,6],Inputs);
  GLM:=TGLMKit.ToPredictionModel(GLMFit);
  SetLength(Rows,6); SetLength(Y,6);
  for I:=0 to 5 do begin
    Rows[I]:=TDoubleArray.Create(100+I,200+2*I); Y[I]:=203+2*I;
  end;
  PLSFit:=TPLSKit.Fit(Rows,Y); PLS:=TPLSKit.ToPredictionModel(PLSFit);
  GLMStream:=TMemoryStream.Create; PLSStream:=TMemoryStream.Create;
  try
    SaveGLMPrediction(GLMStream,GLM); SavePLSPrediction(PLSStream,PLS);
    GLMStream.Position:=0; PLSStream.Position:=0;
    GLM:=LoadGLMPrediction(GLMStream); PLS:=LoadPLSPrediction(PLSStream);
    X:=TDenseDoubleMatrix.FromValues(1,1,[1]); NewInputs:=TGLMInputs.Default;
    NewInputs.Exposures:=TDoubleArray.Create(4);
    A:=TGLMKit.PredictMean(GLM,X,NewInputs);
    SetLength(Rows,1); Rows[0]:=TDoubleArray.Create(110,220);
    B:=TPLSKit.Predict(PLS,Rows);
    if (Abs(A[0]-8)>2E-8) or (Abs(B[0]-223)>2E-8) then
      raise Exception.Create('Reloaded analytic prediction missed.');
    if ParamCount>1 then raise Exception.Create('Usage: prediction_persistence [output-directory]');
    if ParamCount=1 then begin
      Directory:=IncludeTrailingPathDelimiter(ParamStr(1));
      if not ForceDirectories(Directory) then raise Exception.Create('Cannot create output directory.');
      GLMStream.SaveToFile(Directory+'glm.mfpmodel');
      PLSStream.SaveToFile(Directory+'pls.mfpmodel');
      Writeln('wrote GLM/PLS prediction artifacts');
    end;
    Writeln('reloaded predictions: GLM=',A[0]:0:6,'; PLS=',B[0]:0:6);
    Writeln('Artifacts contain prediction parameters and explicit input conventions.');
    Writeln('prediction persistence: success');
  finally GLMStream.Free; PLSStream.Free; end;
end.
