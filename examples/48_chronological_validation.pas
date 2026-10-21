program ChronologicalValidation;

{$mode objfpc}{$H+}{$J-}

uses SysUtils, Math, MathBase.SharedTypes, MLLib.MachineLearning,
  MLLib.Analysis, MLLib.PLS;

var
  X, FutureX: TDoubleMatrix;
  Y, FutureY, Prediction, ReplayPrediction: TDoubleArray;
  Splits: TValidationSplits;
  Model, Replay: TPLSModel;
  I, F: Integer;
  Error: Double;
begin
  { Observations are already ordered. Six future rows stay outside all fitting. }
  SetLength(X, 18); SetLength(Y, 18);
  SetLength(FutureX, 6); SetLength(FutureY, 6);
  for I := 0 to 23 do
    if I < 18 then
    begin
      X[I] := TDoubleArray.Create(I, 2 * I);
      Y[I] := 3 + 2 * I;
    end
    else
    begin
      FutureX[I - 18] := TDoubleArray.Create(I, 2 * I);
      FutureY[I - 18] := 3 + 2 * I;
    end;
  Splits := TAnalysisKit.ExpandingWindowSplits(18, 8, 3, 3, 1);
  for F := 0 to High(Splits) do
    if Splits[F].TrainingRows[High(Splits[F].TrainingRows)] + 2 <>
      Splits[F].ValidationRows[0] then
      raise Exception.Create('Chronological gap mismatch.');
  Model := TPLSKit.Fit(X, Y, Splits);
  Replay := TPLSKit.Fit(X, Y, Splits);
  Prediction := TPLSKit.Predict(Model, FutureX);
  ReplayPrediction := TPLSKit.Predict(Replay, FutureX);
  Error := 0;
  for I := 0 to High(Prediction) do
  begin
    if Prediction[I] <> ReplayPrediction[I] then
      raise Exception.Create('Chronological replay mismatch.');
    Error := Error + Sqr(Prediction[I] - FutureY[I]);
  end;
  Error := Sqrt(Error / Length(FutureY));
  if Error > 1E-8 then raise Exception.Create('Future reference missed.');
  Writeln('chronology: 3 expanding windows, horizon=3, gap=1');
  Writeln('scored validation rows: ', Model.CrossValidationSampleCount);
  Writeln('untouched future rows: 6; RMSE=', Error:0:6);
  Writeln('A row gap does not remove every source of temporal leakage.');
  Writeln('chronological validation: success');
end.
