program example11_machinelearning;

{-----------------------------------------------------------------------------
 Example 11 — MLLib Walkthrough

 Written for someone new to machine learning in Pascal.
 Each section introduces one technique with a plain-English explanation,
 a concrete toy dataset, and guidance on when to use it.

 Compile:  fpc example11_machinelearning.lpr
 Run:      ./example11_machinelearning   (Linux/Mac)
           example11_machinelearning.exe (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  MLLib.MachineLearning;

procedure Sep; begin WriteLn(StringOfChar('-', 55)); end;

procedure ShowVec(const Lbl: String; const V: TDoubleArray; MaxN: Integer = 6);
var I: Integer;
begin
  Write(Format('  %-28s [', [Lbl]));
  for I := 0 to Min(MaxN - 1, High(V)) do
  begin
    if I > 0 then Write(', ');
    Write(Format('%.4f', [V[I]]));
  end;
  if Length(V) > MaxN then Write(', ...');
  WriteLn(']');
end;

procedure ShowIntVec(const Lbl: String; const V: TIntegerArray; MaxN: Integer = 10);
var I: Integer;
begin
  Write(Format('  %-28s [', [Lbl]));
  for I := 0 to Min(MaxN - 1, High(V)) do
  begin
    if I > 0 then Write(', ');
    Write(V[I]);
  end;
  if Length(V) > MaxN then Write(', ...');
  WriteLn(']');
end;

{ ============================================================
  Build some toy datasets
============================================================ }

{ Linear dataset: Y = 3 + 2*x (single feature, 20 samples) }
procedure MakeLinear1D(out X: TDoubleMatrix; out Y: TDoubleArray);
var I: Integer;
begin
  SetLength(X, 20); SetLength(Y, 20);
  for I := 0 to 19 do
  begin
    SetLength(X[I], 1);
    X[I][0] := I;
    Y[I]    := 3 + 2.0 * I;
  end;
end;

{ Two linearly-separable classes:
  Class 0: x in [0..9],  Class 1: x in [20..29] }
procedure MakeBinaryData(out X: TDoubleMatrix; out Y: TIntegerArray);
var I: Integer;
begin
  SetLength(X, 20); SetLength(Y, 20);
  for I := 0 to 9 do
  begin
    SetLength(X[I], 1); X[I][0] := I;
    Y[I] := 0;
  end;
  for I := 10 to 19 do
  begin
    SetLength(X[I], 1); X[I][0] := 20 + (I - 10);
    Y[I] := 1;
  end;
end;

{ Three well-separated 2-D clusters }
function MakeClusterData: TDoubleMatrix;
var I: Integer;
begin
  SetLength(Result, 30);
  for I := 0 to 9 do
  begin
    SetLength(Result[I], 2); Result[I][0] := I * 0.1; Result[I][1] := 0;
  end;
  for I := 10 to 19 do
  begin
    SetLength(Result[I], 2); Result[I][0] := 10 + (I-10)*0.1; Result[I][1] := 5;
  end;
  for I := 20 to 29 do
  begin
    SetLength(Result[I], 2); Result[I][0] := 0; Result[I][1] := 10 + (I-20)*0.1;
  end;
end;

{ ============================================================
  SECTION 1 — Preprocessing
============================================================ }
procedure DemoPreprocessing;
var
  X, N, S: TDoubleMatrix;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== PREPROCESSING ===');
  WriteLn('Raw features often have very different scales.');
  WriteLn('Normalise → [0,1].  Standardise → mean=0, std=1.');
  Sep;

  SetLength(X, 5);
  for I := 0 to 4 do
  begin
    SetLength(X[I], 2);
    X[I][0] := I * 100;    { large scale }
    X[I][1] := I * 0.01;   { tiny scale }
  end;

  WriteLn('  Raw features (col0 is 0-400, col1 is 0-0.04):');
  for I := 0 to 4 do
    WriteLn(Format('    [%.2f, %.4f]', [X[I][0], X[I][1]]));

  N := TMLKit.Normalise(X);
  WriteLn('  After Normalise — both columns in [0,1]:');
  for I := 0 to 4 do
    WriteLn(Format('    [%.4f, %.4f]', [N[I][0], N[I][1]]));

  S := TMLKit.Standardise(X);
  WriteLn('  After Standardise — mean=0, std=1 per column:');
  for I := 0 to 4 do
    WriteLn(Format('    [%+.4f, %+.4f]', [S[I][0], S[I][1]]));

  WriteLn;
  WriteLn('  Rule of thumb: Standardise before KNN, PCA, logistic regression.');
end;

{ ============================================================
  SECTION 2 — Train/Test Split
============================================================ }
procedure DemoTrainTestSplit;
var
  X: TDoubleMatrix; Y, TrainY, TestY: TIntegerArray;
  TrainX, TestX: TDoubleMatrix;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== TRAIN / TEST SPLIT ===');
  WriteLn('Hold out 20% of data for evaluation, never touch it during training.');
  Sep;

  SetLength(X, 10); SetLength(Y, 10);
  for I := 0 to 9 do
  begin
    SetLength(X[I], 1); X[I][0] := I; Y[I] := I mod 2;
  end;

  TMLKit.TrainTestSplit(X, Y, 0.3, 42, TrainX, TrainY, TestX, TestY);
  WriteLn(Format('  Total: 10 samples → Train: %d, Test: %d',
    [Length(TrainX), Length(TestX)]));
  ShowIntVec('Test labels', TestY);
  WriteLn('  Seed=42 makes the shuffle reproducible every run.');
end;

{ ============================================================
  SECTION 3 — Linear Regression
============================================================ }
procedure DemoLinearRegression;
var
  X, Xpoly: TDoubleMatrix; Y, YHat: TDoubleArray;
  Model: TLinearModel;
begin
  WriteLn;
  WriteLn('=== LINEAR REGRESSION ===');
  WriteLn('Fit y = a + b*x. OLS minimises sum of squared errors.');
  Sep;

  MakeLinear1D(X, Y);
  Model := TMLKit.LinearRegression(X, Y);
  WriteLn(Format('  Fitted:   y = %.4f + %.4f * x', [Model.Intercept, Model.Coefficients[0]]));
  WriteLn(Format('  Expected: y = 3.0000 + 2.0000 * x'));
  WriteLn(Format('  R² = %.6f  (1.0 = perfect fit)', [Model.RSquared]));

  WriteLn;
  WriteLn('  Polynomial regression (degree=2) on a curved target:');
  { Y = x² }
  SetLength(Y, 10);
  for var I := 0 to 9 do Y[I] := I * I;
  SetLength(X, 10);
  for var I := 0 to 9 do begin SetLength(X[I], 1); X[I][0] := I; end;
  Xpoly := TMLKit.PolynomialFeatures(
    TDoubleArray.Create(0,1,2,3,4,5,6,7,8,9), 2);
  Model := TMLKit.LinearRegression(Xpoly, Y);
  WriteLn(Format('  Poly R² = %.6f  (fitting x² with [1, x, x²] features)', [Model.RSquared]));
  YHat := TMLKit.LinearPredict(Model, Xpoly);
  WriteLn(Format('  Prediction at x=5: %.4f  (true: 25.0)', [YHat[5]]));
end;

{ ============================================================
  SECTION 4 — Classification: KNN
============================================================ }
procedure DemoKNN;
var
  X: TDoubleMatrix; Y, Pred: TIntegerArray;
  TestX: TDoubleMatrix;
begin
  WriteLn;
  WriteLn('=== K-NEAREST NEIGHBOURS ===');
  WriteLn('Classify by majority vote of the K closest training points.');
  WriteLn('No training phase — it is a "lazy" learner.');
  Sep;

  MakeBinaryData(X, Y);
  SetLength(TestX, 3);
  SetLength(TestX[0], 1); TestX[0][0] := 3;   { should be class 0 }
  SetLength(TestX[1], 1); TestX[1][0] := 25;  { should be class 1 }
  SetLength(TestX[2], 1); TestX[2][0] := 14;  { boundary area }

  Pred := TMLKit.KNearestNeighbours(X, Y, TestX, 3);
  WriteLn('  Query x=3  → predicted class: ', Pred[0], '  (expected: 0)');
  WriteLn('  Query x=25 → predicted class: ', Pred[1], '  (expected: 1)');
  WriteLn('  Query x=14 → predicted class: ', Pred[2]);
  WriteLn;
  WriteLn('  Tip: always Standardise features before KNN.');
  WriteLn('  Tip: try K=1,3,5,7 and pick the one with lowest test error.');
end;

{ ============================================================
  SECTION 5 — Classification: Naive Bayes
============================================================ }
procedure DemoNaiveBayes;
var
  TrainX, TestX: TDoubleMatrix;
  TrainY, Pred: TIntegerArray;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== GAUSSIAN NAIVE BAYES ===');
  WriteLn('Estimates a Gaussian for each feature per class.');
  WriteLn('Fast, handles many features, assumes feature independence.');
  Sep;

  { Class 0: x≈0, y≈0;  Class 1: x≈10, y≈10 }
  SetLength(TrainX, 20); SetLength(TrainY, 20);
  for I := 0 to 9 do
  begin
    SetLength(TrainX[I], 2);
    TrainX[I][0] := I * 0.2; TrainX[I][1] := I * 0.3; TrainY[I] := 0;
  end;
  for I := 10 to 19 do
  begin
    SetLength(TrainX[I], 2);
    TrainX[I][0] := 10 + I * 0.1; TrainX[I][1] := 10 + I * 0.2; TrainY[I] := 1;
  end;

  SetLength(TestX, 2);
  SetLength(TestX[0], 2); TestX[0][0] := 0.5;  TestX[0][1] := 0.5;
  SetLength(TestX[1], 2); TestX[1][0] := 10.5; TestX[1][1] := 11.0;

  Pred := TMLKit.NaiveBayes(TrainX, TrainY, TestX);
  WriteLn('  Query (0.5, 0.5)   → predicted: ', Pred[0], '  (expected: 0)');
  WriteLn('  Query (10.5, 11.0) → predicted: ', Pred[1], '  (expected: 1)');
end;

{ ============================================================
  SECTION 6 — Logistic Regression
============================================================ }
procedure DemoLogistic;
var
  X: TDoubleMatrix; Y, Pred: TIntegerArray;
  Model: TLinearModel;
  Acc: Double;
begin
  WriteLn;
  WriteLn('=== LOGISTIC REGRESSION ===');
  WriteLn('Binary classifier. Outputs probability P(y=1|x) via sigmoid.');
  WriteLn('Trained with gradient descent on cross-entropy loss.');
  Sep;

  MakeBinaryData(X, Y);
  Model := TMLKit.LogisticRegression(X, Y, 0.05, 3000);
  Pred  := TMLKit.LogisticPredict(Model, X);
  Acc   := TMLKit.Accuracy(Y, Pred);

  WriteLn(Format('  Training accuracy: %.1f%%', [Acc * 100]));
  WriteLn(Format('  Intercept: %.4f,  Coefficient: %.4f',
    [Model.Intercept, Model.Coefficients[0]]));
  WriteLn('  Positive coefficient means larger x → class 1 is more likely.');
end;

{ ============================================================
  SECTION 7 — K-Means Clustering
============================================================ }
procedure DemoKMeans;
var
  X: TDoubleMatrix; R: TKMeansResult;
begin
  WriteLn;
  WriteLn('=== K-MEANS CLUSTERING ===');
  WriteLn('Partition points into K groups by minimising within-cluster variance.');
  WriteLn('Three well-separated 2-D blobs → expect K=3 to find them.');
  Sep;

  X := MakeClusterData;
  R := TMLKit.KMeans(X, 3, 300, 42);

  WriteLn(Format('  Converged in %d iterations', [R.Iters]));
  WriteLn(Format('  Inertia (lower = tighter clusters): %.4f', [R.Inertia]));
  WriteLn('  Labels for first 12 samples (should be 3 distinct groups):');
  ShowIntVec('Labels[0..11]', R.Labels, 12);

  WriteLn;
  WriteLn('  Centroids:');
  for var I := 0 to 2 do
    WriteLn(Format('    Cluster %d: (%.3f, %.3f)',
      [I, R.Centroids[I][0], R.Centroids[I][1]]));
end;

{ ============================================================
  SECTION 8 — DBSCAN
============================================================ }
procedure DemoDBSCAN;
var
  X: TDoubleMatrix; R: TDBSCANResult; I: Integer;
begin
  WriteLn;
  WriteLn('=== DBSCAN CLUSTERING ===');
  WriteLn('Finds clusters of any shape without specifying K.');
  WriteLn('Points in sparse regions are labelled as noise (-1).');
  Sep;

  X := MakeClusterData;
  { Add an isolated noise point }
  SetLength(X, Length(X) + 1);
  SetLength(X[High(X)], 2);
  X[High(X)][0] := 50; X[High(X)][1] := 50;

  R := TMLKit.DBSCAN(X, 1.5, 3);
  WriteLn(Format('  Clusters found: %d  (expected: 3)', [R.NClusters]));
  WriteLn(Format('  Isolated point label: %d  (expected: -1 = noise)',
    [R.Labels[High(R.Labels)]]));
  ShowIntVec('Labels (first 15)', R.Labels, 15);
end;

{ ============================================================
  SECTION 9 — PCA
============================================================ }
procedure DemoPCA;
var
  X, Xr: TDoubleMatrix; R: TPCAResult; I: Integer;
begin
  WriteLn;
  WriteLn('=== PCA (PRINCIPAL COMPONENT ANALYSIS) ===');
  WriteLn('Find the directions of maximum variance.');
  WriteLn('Useful for visualisation, noise reduction, and decorrelation.');
  Sep;

  { 3-D data lying mostly along [1,2,3] direction }
  SetLength(X, 20);
  for I := 0 to 19 do
  begin
    SetLength(X[I], 3);
    X[I][0] := I;
    X[I][1] := 2 * I + Sin(I * 0.5);
    X[I][2] := 3 * I + Cos(I * 0.5);
  end;

  X := TMLKit.Standardise(X);  { always standardise before PCA }
  R := TMLKit.PCA(X, 2);

  WriteLn('  Explained variance ratios:');
  for I := 0 to 1 do
    WriteLn(Format('    PC%d: %.2f%%', [I+1, R.ExplainedRatio[I] * 100]));
  WriteLn('  (PC1 should capture most variance since data lies along one direction)');

  Xr := TMLKit.PCATransform(R, X);
  WriteLn(Format('  Original shape: 20 × 3 → Projected shape: 20 × 2'));
  WriteLn('  First 3 projected samples:');
  for I := 0 to 2 do
    WriteLn(Format('    [%.4f, %.4f]', [Xr[I][0], Xr[I][1]]));
end;

{ ============================================================
  SECTION 10 — Evaluation Metrics
============================================================ }
procedure DemoEvaluation;
var
  YTrue, YPred: TIntegerArray;
  YTrueR, YPredR: TDoubleArray;
  CM: TConfusionMatrix;
begin
  WriteLn;
  WriteLn('=== EVALUATION METRICS ===');
  Sep;

  { Classification metrics }
  YTrue := TIntegerArray.Create(0,0,1,1,1,0,1,0,1,1);
  YPred := TIntegerArray.Create(0,1,1,1,0,0,1,0,0,1);

  WriteLn('  Classification (YTrue vs YPred):');
  WriteLn(Format('    Accuracy : %.4f', [TMLKit.Accuracy(YTrue, YPred)]));
  WriteLn(Format('    Precision: %.4f  (for class 1)', [TMLKit.Precision(YTrue, YPred, 1)]));
  WriteLn(Format('    Recall   : %.4f  (for class 1)', [TMLKit.Recall(YTrue, YPred, 1)]));
  WriteLn(Format('    F1 Score : %.4f  (for class 1)', [TMLKit.F1Score(YTrue, YPred, 1)]));

  CM := TMLKit.BuildConfusionMatrix(YTrue, YPred, 2);
  WriteLn('    Confusion matrix [true\pred]:');
  WriteLn(Format('      [%.0f, %.0f]', [CM.Counts[0][0], CM.Counts[0][1]]));
  WriteLn(Format('      [%.0f, %.0f]', [CM.Counts[1][0], CM.Counts[1][1]]));

  WriteLn;
  { Regression metrics }
  YTrueR := TDoubleArray.Create(1, 2, 3, 4, 5);
  YPredR := TDoubleArray.Create(1.1, 2.2, 2.9, 4.1, 4.8);

  WriteLn('  Regression (YTrue=[1..5], YPred≈YTrue):');
  WriteLn(Format('    MSE  = %.4f', [TMLKit.MSE(YTrueR, YPredR)]));
  WriteLn(Format('    RMSE = %.4f', [TMLKit.RMSE(YTrueR, YPredR)]));
  WriteLn(Format('    MAE  = %.4f', [TMLKit.MAE(YTrueR, YPredR)]));
  WriteLn(Format('    R²   = %.4f  (1.0 = perfect)', [TMLKit.R2Score(YTrueR, YPredR)]));
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp — MLLib Example');
  WriteLn('============================');

  DemoPreprocessing;
  DemoTrainTestSplit;
  DemoLinearRegression;
  DemoKNN;
  DemoNaiveBayes;
  DemoLogistic;
  DemoKMeans;
  DemoDBSCAN;
  DemoPCA;
  DemoEvaluation;

  WriteLn;
  WriteLn('Done.');
end.
