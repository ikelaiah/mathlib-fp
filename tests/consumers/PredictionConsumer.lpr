program PredictionConsumer;
{$mode objfpc}{$H+}{$J-}
uses Classes, SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices,
  MLLib.MachineLearning, MLLib.PLS, StatsLib.GLM, InterchangeLib.Models;
var GLM:TGLMPredictionModel; PLS:TPLSPredictionModel; Stream:TFileStream;
  X:IDenseDoubleMatrix; Rows:TDoubleMatrix; Inputs:TGLMInputs; A,B:TDoubleArray;
begin
  if ParamCount<>2 then raise Exception.Create('Expected GLM and PLS artifact paths.');
  Stream:=TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyWrite);
  try GLM:=LoadGLMPrediction(Stream); finally Stream.Free; end;
  Stream:=TFileStream.Create(ParamStr(2),fmOpenRead or fmShareDenyWrite);
  try PLS:=LoadPLSPrediction(Stream); finally Stream.Free; end;
  X:=TDenseDoubleMatrix.FromValues(1,1,[1]); Inputs:=TGLMInputs.Default;
  Inputs.Exposures:=TDoubleArray.Create(4);
  A:=TGLMKit.PredictMean(GLM,X,Inputs);
  SetLength(Rows,1); Rows[0]:=TDoubleArray.Create(110,220);
  B:=TPLSKit.Predict(PLS,Rows);
  if (Abs(A[0]-8)>2E-8) or (Abs(B[0]-223)>2E-8) then
    raise Exception.Create('Prediction-only consumer reference missed.');
  Writeln('artifact-only predictions: GLM=',A[0]:0:6,'; PLS=',B[0]:0:6);
  Writeln('prediction-only consumer: success');
end.
