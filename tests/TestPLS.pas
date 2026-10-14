unit TestPLS;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testregistry,
  MathBase.SharedTypes,
  MLLib.MachineLearning,
  MLLib.PLS;

type
  TTestPLS = class(TTestCase)
  private
    procedure AssertNear(const AMessage: String; Expected, Actual,
      Tolerance: Double);
    procedure MakeCorrelatedData(out X: TDoubleMatrix; out Y: TDoubleArray);
  published
    procedure TestOnePredictorLinearFitAndPredict;
    procedure TestCorrelatedPredictorsUseTwoComponents;
    procedure TestThreeComponentsRecoverExactLinearModel;
    procedure TestDecimalReferenceFitAndCrossValidation;
    procedure TestRankDeficiencyAndConstantPredictor;
    procedure TestTooManyComponentsRaises;
    procedure TestNonFiniteAndRaggedInputsRaise;
    procedure TestConstantResponseIsMeanOnly;
    procedure TestCrossValidationIsSeededAndRepeatable;
    procedure TestFitDoesNotMutateInputs;
    procedure TestInvalidOptionsRaise;
    procedure TestPredictionValidatesShapeAndFiniteValues;
    procedure TestCenterOnlyScalingOption;
    procedure TestAllConstantPredictorsAreMeanOnly;
    procedure TestTamperedModelIsRejected;
    procedure TestInsufficientRowsAndResponseShapeRaise;
  end;

implementation

{$I PLSReference.inc}

procedure TTestPLS.AssertNear(const AMessage: String; Expected, Actual,
  Tolerance: Double);
begin
  AssertTrue(AMessage + ': expected ' + FloatToStr(Expected) + ', got ' +
    FloatToStr(Actual), Abs(Expected - Actual) <= Tolerance);
end;

procedure TTestPLS.MakeCorrelatedData(out X: TDoubleMatrix;
  out Y: TDoubleArray);
var
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
end;

procedure TTestPLS.TestOnePredictorLinearFitAndPredict;
var
  X, XNew: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
begin
  SetLength(X, 7);
  SetLength(Y, 7);
  for I := 0 to High(X) do
  begin
    SetLength(X[I], 1);
    X[I][0] := I - 3;
    Y[I] := 3.0 + 2.0 * X[I][0];
  end;

  Model := TPLSKit.Fit(X, Y);
  AssertEquals('one component selected', 1, Model.SelectedComponents);
  AssertEquals('one predictor rank', 1, Model.PredictorRank);
  AssertNear('original-unit slope', 2.0, Model.Coefficients[0], 1E-12);
  AssertNear('original-unit intercept', 3.0, Model.Intercept, 1E-12);
  AssertEquals('default folds bounded by N-1', 5, Model.CrossValidationFolds);
  AssertEquals('RMSECV includes the mean-only baseline and one component',
    2, Length(Model.RMSECV));

  XNew := TDoubleMatrix.Create(TDoubleArray.Create(3.5),
    TDoubleArray.Create(-2.5));
  Predicted := TPLSKit.Predict(Model, XNew);
  AssertNear('prediction 0', 10.0, Predicted[0], 1E-12);
  AssertNear('prediction 1', -2.0, Predicted[1], 1E-12);
end;

procedure TTestPLS.TestCorrelatedPredictorsUseTwoComponents;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Model: TPLSModel;
  Predicted: TDoubleArray;
  I: Integer;
begin
  MakeCorrelatedData(X, Y);
  Model := TPLSKit.Fit(X, Y);
  AssertEquals('correlated design rank', 2, Model.PredictorRank);
  AssertEquals('two components selected by cross-validation', 2,
    Model.SelectedComponents);
  Predicted := TPLSKit.Predict(Model, X);
  for I := 0 to High(Y) do
    AssertNear('correlated training prediction ' + IntToStr(I), Y[I],
      Predicted[I], 1E-9);
end;

procedure TTestPLS.TestThreeComponentsRecoverExactLinearModel;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
  T, U, V: Double;
begin
  SetLength(X, 13);
  SetLength(Y, 13);
  for I := 0 to High(X) do
  begin
    T := I - 6.0;
    U := ((I * 5) mod 13) - 6.0;
    V := ((I * 7) mod 13) - 6.0;
    SetLength(X[I], 3);
    X[I][0] := T;
    X[I][1] := 0.4 * T + U;
    X[I][2] := -0.2 * T + 0.3 * U + V;
    Y[I] := 2.75 + 1.2 * T - 0.7 * U + 0.45 * V;
  end;

  Model := TPLSKit.Fit(X, Y);
  AssertEquals('full-rank predictors select three components', 3,
    Model.SelectedComponents);
  AssertEquals('full-rank predictor rank', 3, Model.PredictorRank);
  AssertNear('three-component coefficient 0', 1.624,
    Model.Coefficients[0], 1E-10);
  AssertNear('three-component coefficient 1', -0.835,
    Model.Coefficients[1], 1E-10);
  AssertNear('three-component coefficient 2', 0.45,
    Model.Coefficients[2], 1E-10);
  AssertNear('centered three-component intercept', 2.75,
    Model.Intercept, 1E-10);
end;

procedure TTestPLS.TestDecimalReferenceFitAndCrossValidation;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
begin
  MakeCorrelatedData(X, Y);
  Model := TPLSKit.Fit(X, Y);
  AssertEquals('Decimal fixture rank', PLSReferenceRank, Model.PredictorRank);
  AssertEquals('Decimal fixture selection', PLSReferenceSelectedComponents,
    Model.SelectedComponents);
  AssertNear('Decimal reference intercept', PLSReferenceIntercept,
    Model.Intercept, 1E-11);
  for I := 0 to High(PLSReferenceCoefficients) do
    AssertNear('Decimal reference coefficient ' + IntToStr(I),
      PLSReferenceCoefficients[I], Model.Coefficients[I], 1E-11);
  for I := 0 to High(PLSReferenceRMSECV) do
    AssertNear('Decimal reference RMSECV ' + IntToStr(I),
      PLSReferenceRMSECV[I], Model.RMSECV[I], 1E-10);
end;

procedure TTestPLS.TestRankDeficiencyAndConstantPredictor;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
begin
  SetLength(X, 8);
  SetLength(Y, 8);
  for I := 0 to High(X) do
  begin
    SetLength(X[I], 3);
    X[I][0] := I - 3.5;
    X[I][1] := 2.0 * X[I][0];
    X[I][2] := 7.0;
    Y[I] := 1.0 + 3.0 * X[I][0];
  end;

  Model := TPLSKit.Fit(X, Y);
  AssertEquals('rank excludes duplicate and constant columns', 1,
    Model.PredictorRank);
  AssertEquals('one useful component', 1, Model.SelectedComponents);
  AssertEquals('coefficient shape retains every input column', 3,
    Length(Model.Coefficients));
  AssertNear('constant column has zero coefficient', 0.0,
    Model.Coefficients[2], 0.0);
end;

procedure TTestPLS.TestTooManyComponentsRaises;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Options: TPLSOptions;
  Raised: Boolean;
  I: Integer;
begin
  SetLength(X, 6);
  SetLength(Y, 6);
  for I := 0 to High(X) do
  begin
    SetLength(X[I], 1);
    X[I][0] := I;
    Y[I] := 2 * I;
  end;
  Options := TPLSOptions.Default;
  Options.MaxComponents := 2;
  Raised := False;
  try
    TPLSKit.Fit(X, Y, Options);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('component cap above numerical rank is rejected', Raised);
end;

procedure TTestPLS.TestNonFiniteAndRaggedInputsRaise;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Raised: Boolean;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0, 2.0), TDoubleArray.Create(2.0));
  Y := TDoubleArray.Create(1.0, 2.0, 3.0);
  Raised := False;
  try
    TPLSKit.Fit(X, Y);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('ragged design is rejected', Raised);

  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(NaN), TDoubleArray.Create(2.0));
  Raised := False;
  try
    TPLSKit.Fit(X, Y);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('missing/non-finite predictor is rejected', Raised);

  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0), TDoubleArray.Create(2.0));
  Y[1] := Infinity;
  Raised := False;
  try
    TPLSKit.Fit(X, Y);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('non-finite response is rejected', Raised);
end;

procedure TTestPLS.TestConstantResponseIsMeanOnly;
var
  X: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
begin
  SetLength(X, 6);
  SetLength(Y, 6);
  for I := 0 to High(X) do
  begin
    SetLength(X[I], 2);
    X[I][0] := I;
    X[I][1] := I * I;
    Y[I] := 4.25;
  end;

  Model := TPLSKit.Fit(X, Y);
  AssertEquals('constant response chooses mean-only model', 0,
    Model.SelectedComponents);
  AssertEquals('mean-only status', Ord(plsMeanOnly), Ord(Model.Status));
  AssertNear('mean-only baseline RMSECV', 0.0, Model.RMSECV[0], 1E-14);
  Predicted := TPLSKit.Predict(Model,
    TDoubleMatrix.Create(TDoubleArray.Create(100.0, -3.0)));
  AssertNear('mean-only prediction', 4.25, Predicted[0], 1E-14);
end;

procedure TTestPLS.TestCrossValidationIsSeededAndRepeatable;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Options: TPLSOptions;
  A, B: TPLSModel;
  I: Integer;
begin
  MakeCorrelatedData(X, Y);
  Options := TPLSOptions.Default;
  Options.Seed := 123456;
  A := TPLSKit.Fit(X, Y, Options);
  B := TPLSKit.Fit(X, Y, Options);
  AssertEquals('selected components repeat', A.SelectedComponents,
    B.SelectedComponents);
  AssertEquals('fold count repeats', A.CrossValidationFolds,
    B.CrossValidationFolds);
  AssertEquals('CV vector shape repeats', Length(A.RMSECV), Length(B.RMSECV));
  for I := 0 to High(A.RMSECV) do
    AssertNear('CV score repeats ' + IntToStr(I), A.RMSECV[I], B.RMSECV[I], 0.0);
  for I := 0 to High(A.Coefficients) do
    AssertNear('coefficient repeats ' + IntToStr(I), A.Coefficients[I],
      B.Coefficients[I], 0.0);
end;

procedure TTestPLS.TestFitDoesNotMutateInputs;
var
  X: TDoubleMatrix;
  Y, XCopy, YCopy: TDoubleArray;
  Model: TPLSModel;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(-2.0, 4.0),
    TDoubleArray.Create(-1.0, 1.0), TDoubleArray.Create(0.0, 0.0),
    TDoubleArray.Create(1.0, 2.0), TDoubleArray.Create(2.0, -1.0));
  Y := TDoubleArray.Create(5.0, 2.0, 1.0, 0.0, -3.0);
  XCopy := Copy(X[0]);
  YCopy := Copy(Y);
  Model := TPLSKit.Fit(X, Y);
  AssertEquals('input predictor row unchanged', Length(XCopy), Length(X[0]));
  AssertNear('input predictor value unchanged', XCopy[1], X[0][1], 0.0);
  AssertEquals('response length unchanged', Length(YCopy), Length(Y));
  AssertNear('response value unchanged', YCopy[3], Y[3], 0.0);
  AssertEquals('model created', Length(X[0]), Length(Model.Coefficients));
end;

procedure TTestPLS.TestInvalidOptionsRaise;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Options: TPLSOptions;
  Raised: Boolean;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0), TDoubleArray.Create(2.0));
  Y := TDoubleArray.Create(0.0, 1.0, 4.0);
  Options := TPLSOptions.Default;
  Options.Folds := 1;
  Raised := False;
  try
    TPLSKit.Fit(X, Y, Options);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('one fold is invalid', Raised);

  Options := TPLSOptions.Default;
  Options.RankTolerance := 0.0;
  Raised := False;
  try
    TPLSKit.Fit(X, Y, Options);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('nonpositive rank tolerance is invalid', Raised);
end;

procedure TTestPLS.TestPredictionValidatesShapeAndFiniteValues;
var
  X, XBad: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
  Raised: Boolean;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0, 2.0),
    TDoubleArray.Create(1.0, 1.0), TDoubleArray.Create(2.0, -1.0),
    TDoubleArray.Create(3.0, 4.0));
  Y := TDoubleArray.Create(1.0, 2.0, 0.0, 5.0);
  Model := TPLSKit.Fit(X, Y);

  XBad := TDoubleMatrix.Create(TDoubleArray.Create(1.0));
  Raised := False;
  try
    Predicted := TPLSKit.Predict(Model, XBad);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('prediction rejects a mismatched feature count', Raised);

  XBad := TDoubleMatrix.Create(TDoubleArray.Create(NaN, 2.0));
  Raised := False;
  try
    Predicted := TPLSKit.Predict(Model, XBad);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('prediction rejects non-finite input', Raised);
end;

procedure TTestPLS.TestCenterOnlyScalingOption;
var
  X: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Options: TPLSOptions;
  Model: TPLSModel;
  I: Integer;
begin
  SetLength(X, 7);
  SetLength(Y, 7);
  for I := 0 to High(X) do
  begin
    SetLength(X[I], 2);
    X[I][0] := I - 3;
    X[I][1] := 100.0 * (I - 3);
    Y[I] := 8.0 + 2.0 * X[I][0];
  end;
  Options := TPLSOptions.Default;
  Options.ScalePredictors := False;
  Model := TPLSKit.Fit(X, Y, Options);
  Predicted := TPLSKit.Predict(Model,
    TDoubleMatrix.Create(TDoubleArray.Create(2.5, 250.0)));
  AssertNear('center-only scaling preserves the original units', 13.0,
    Predicted[0], 1E-11);
end;

procedure TTestPLS.TestAllConstantPredictorsAreMeanOnly;
var
  X: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
  I: Integer;
begin
  SetLength(X, 6);
  Y := TDoubleArray.Create(1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
  for I := 0 to High(X) do
    X[I] := TDoubleArray.Create(7.0, -2.0);
  Model := TPLSKit.Fit(X, Y);
  AssertEquals('all constant predictors have rank zero', 0,
    Model.PredictorRank);
  AssertEquals('no predictive component is selected', 0,
    Model.SelectedComponents);
  AssertEquals('mean-only status', Ord(plsMeanOnly), Ord(Model.Status));
  Predicted := TPLSKit.Predict(Model,
    TDoubleMatrix.Create(TDoubleArray.Create(-100.0, 200.0)));
  AssertNear('mean-only prediction ignores constant columns', 3.5,
    Predicted[0], 1E-14);
end;

procedure TTestPLS.TestTamperedModelIsRejected;
var
  X: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
  Raised: Boolean;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0), TDoubleArray.Create(2.0),
    TDoubleArray.Create(3.0));
  Y := TDoubleArray.Create(0.0, 1.0, 2.0, 3.0);
  Model := TPLSKit.Fit(X, Y);
  Model.Coefficients[0] := NaN;
  Raised := False;
  try
    Predicted := TPLSKit.Predict(Model, X);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('prediction rejects non-finite model parameters', Raised);
end;

procedure TTestPLS.TestInsufficientRowsAndResponseShapeRaise;
var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Raised: Boolean;
begin
  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0));
  Y := TDoubleArray.Create(0.0, 1.0);
  Raised := False;
  try
    TPLSKit.Fit(X, Y);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('fewer than three observations are rejected', Raised);

  X := TDoubleMatrix.Create(TDoubleArray.Create(0.0),
    TDoubleArray.Create(1.0), TDoubleArray.Create(2.0));
  Y := TDoubleArray.Create(1.0, 2.0);
  Raised := False;
  try
    TPLSKit.Fit(X, Y);
  except
    on EPLSError do Raised := True;
  end;
  AssertTrue('response length mismatch is rejected', Raised);
end;

initialization
  RegisterTest(TTestPLS);

end.
