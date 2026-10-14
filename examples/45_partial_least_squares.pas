program PartialLeastSquaresRegression;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils,
  MathBase.SharedTypes,
  MLLib.MachineLearning,
  MLLib.PLS;

var
  X, NewRow: TDoubleMatrix;
  Y, Prediction: TDoubleArray;
  Model: TPLSModel;
  Options: TPLSOptions;
  I: Integer;
  T, U: Double;

begin
  SetLength(X, 10);
  SetLength(Y, 10);
  for I := 0 to High(X) do
  begin
    T := I - 4.5;
    U := ((I * 7) mod 11) - 5;
    SetLength(X[I], 3);
    X[I][0] := T;
    X[I][1] := 2.0 * T + U;
    X[I][2] := -T + 3.0 * U;
    Y[I] := 5.0 + 1.5 * T - 0.8 * U;
  end;

  Options := TPLSOptions.Default;
  Model := TPLSKit.Fit(X, Y, Options);
  if Model.SelectedComponents <> 2 then
    raise Exception.Create('Cross-validation did not select the two predictive directions.');

  NewRow := TDoubleMatrix.Create(TDoubleArray.Create(1.25, 4.5, 4.75));
  Prediction := TPLSKit.Predict(Model, NewRow);
  if Abs(Prediction[0] - 5.275) > 1E-9 then
    raise Exception.Create('The correlated-predictor prediction missed its reference.');

  Writeln('validation: ', Model.CrossValidationFolds,
    ' folds, ', Model.SelectedComponents, ' components selected');
  Writeln('RMSECV: mean only=', Model.RMSECV[0]:0:6,
    ', 1=', Model.RMSECV[1]:0:6, ', 2=', Model.RMSECV[2]:0:6);
  Writeln('predict: ', Prediction[0]:0:6);
  Writeln('workflow: success');
end.
