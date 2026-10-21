program GroupedModelValidation;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes, MLLib.MachineLearning, MLLib.Analysis, MLLib.PLS;

var
  TrainX, OuterX: TDoubleMatrix;
  TrainY, OuterY, PLSPrediction, OLSPrediction: TDoubleArray;
  Groups: TIntegerArray;
  Splits: TValidationSplits;
  PLSModel: TPLSModel;
  OLSModel: TLinearModel;
  I: Integer;
  T, U, PLSRMSE, OLSRMSE: Double;
begin
  { Four subjects, three measurements each. Subject four is untouched test data. }
  SetLength(TrainX, 9); SetLength(TrainY, 9); SetLength(Groups, 9);
  SetLength(OuterX, 3); SetLength(OuterY, 3);
  for I := 0 to 11 do
  begin
    T := I - 5.5;
    U := ((I * 7) mod 11) - 5;
    if I < 9 then
    begin
      TrainX[I] := TDoubleArray.Create(T, 2 * T + U);
      TrainY[I] := 5 + 1.5 * T - 0.8 * U;
      Groups[I] := I div 3;
    end
    else
    begin
      OuterX[I - 9] := TDoubleArray.Create(T, 2 * T + U);
      OuterY[I - 9] := 5 + 1.5 * T - 0.8 * U;
    end;
  end;

  Splits := TAnalysisKit.GroupKFoldSplits(Groups, 3, 1729);
  PLSModel := TPLSKit.Fit(TrainX, TrainY, Splits);
  OLSModel := TMLKit.LinearRegression(TrainX, TrainY);
  PLSPrediction := TPLSKit.Predict(PLSModel, OuterX);
  OLSPrediction := TMLKit.LinearPredict(OLSModel, OuterX);
  PLSRMSE := 0; OLSRMSE := 0;
  for I := 0 to High(OuterY) do
  begin
    PLSRMSE := PLSRMSE + Sqr(OuterY[I] - PLSPrediction[I]);
    OLSRMSE := OLSRMSE + Sqr(OuterY[I] - OLSPrediction[I]);
  end;
  PLSRMSE := Sqrt(PLSRMSE / Length(OuterY));
  OLSRMSE := Sqrt(OLSRMSE / Length(OuterY));
  if (PLSRMSE > 1E-8) or (OLSRMSE > 1E-8) then
    raise Exception.Create('Grouped outer evaluation missed its reference.');
  Writeln('validation: 3 training groups, 1 untouched test group');
  Writeln('PLS grouped folds: ', PLSModel.CrossValidationFolds,
    ', scored rows: ', PLSModel.CrossValidationSampleCount);
  Writeln('outer RMSE: PLS=', PLSRMSE:0:6, ', OLS=', OLSRMSE:0:6);
  Writeln('grouped model validation: success');
end.
