unit MLLib.MachineLearning;

{-----------------------------------------------------------------------------
 MLLib.MachineLearning

 Machine learning primitives for Free Pascal.
 No external dependencies — only MathBase and the RTL.

 What this library gives you
 ---------------------------
 Preprocessing
   Normalise           — scale each feature to [0, 1]
   Standardise         — zero mean, unit variance (z-score scaling)
   TrainTestSplit      — shuffle and split dataset into train / test sets
   OneHotEncode        — convert integer class labels to binary indicator matrix

 Regression
   LinearRegression    — ordinary least squares (OLS), y = X*beta + e
   RidgeRegression     — L2-regularised OLS: min ||y-Xb||² + lambda*||b||²
   PolynomialFeatures  — expand a single feature into [1, x, x², ..., x^Degree]

 Classification
   KNearestNeighbours  — k-NN classifier (Euclidean distance, majority vote)
   NaiveBayes          — Gaussian Naive Bayes (per-class mean + variance)
   LogisticRegression  — binary logistic regression trained with gradient descent

 Clustering
   KMeans              — Lloyd's algorithm, returns cluster labels + centroids
   DBSCAN              — density-based clustering; labels -1 = noise

 Dimensionality Reduction
   PCA                 — principal component analysis via covariance eigen-decomp
                         (power-iteration method, no LAPACK needed)

 Model Evaluation
   Accuracy            — fraction of correct predictions
   Precision           — TP / (TP + FP) for binary or per-class
   Recall              — TP / (TP + FN)
   F1Score             — harmonic mean of Precision and Recall
   ConfusionMatrix     — NClass × NClass count matrix
   MSE                 — mean squared error
   RMSE                — root mean squared error
   MAE                 — mean absolute error
   R2Score             — coefficient of determination

 Result records
   TLinearModel        — coefficients + intercept + R²
   TKMeansResult       — Labels array + Centroids matrix + inertia
   TPCAResult          — Components matrix + explained variance ratios
   TConfusionMatrix    — Count matrix + NClasses

 All methods are static on TMLKit — no object creation needed.
 Raises EMLError for invalid inputs.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

type
  { Raised for invalid ML inputs }
  EMLError = class(Exception);

  { 2-D matrix stored as array of rows: M[row][col] }
  TDoubleMatrix = array of TDoubleArray;

  { Result of LinearRegression / RidgeRegression }
  TLinearModel = record
    Coefficients: TDoubleArray;  { beta[0..NFeatures-1] }
    Intercept:    Double;        { bias term }
    RSquared:     Double;        { coefficient of determination on training data }
  end;

  { Result of KMeans }
  TKMeansResult = record
    Labels:    TIntegerArray;   { cluster index for each sample, 0..K-1 }
    Centroids: TDoubleMatrix;   { K × NFeatures centroid coordinates }
    Inertia:   Double;          { sum of squared distances to nearest centroid }
    Iters:     Integer;         { iterations until convergence }
  end;

  { Result of PCA }
  TPCAResult = record
    Components:        TDoubleMatrix;  { NComponents × NFeatures eigenvectors }
    ExplainedVariance: TDoubleArray;   { variance explained by each component }
    ExplainedRatio:    TDoubleArray;   { fraction of total variance }
    Mean:              TDoubleArray;   { per-feature mean (needed to transform new data) }
  end;

  { Confusion matrix }
  TConfusionMatrix = record
    Counts:   TDoubleMatrix;  { NClasses × NClasses  (row=true, col=predicted) }
    NClasses: Integer;
  end;

  { Result of DBSCAN }
  TDBSCANResult = record
    Labels:  TIntegerArray;  { cluster index per sample; -1 = noise }
    NClusters: Integer;      { number of clusters found (excluding noise) }
  end;

  { TMLKit — all methods are class static }
  TMLKit = class
  private
    { Internal matrix helpers }
    class function MatMul(const A, B: TDoubleMatrix): TDoubleMatrix; static;
    class function MatTranspose(const A: TDoubleMatrix): TDoubleMatrix; static;
    class function MatAddIdentity(const A: TDoubleMatrix;
      Lambda: Double): TDoubleMatrix; static;
    { Solve A*x = b for symmetric positive-definite A (Cholesky-like Gauss elim) }
    class function SolveLinear(const A: TDoubleMatrix;
      const B: TDoubleArray): TDoubleArray; static;
    { Euclidean distance between two vectors }
    class function EuclidDist(const A, B: TDoubleArray): Double; static;
    { Dot product }
    class function Dot(const A, B: TDoubleArray): Double; static;
    { Sigmoid function }
    class function Sigmoid(Z: Double): Double; static;
    { Power iteration to find dominant eigenvector of symmetric matrix }
    class function PowerIter(const M: TDoubleMatrix;
      MaxIter: Integer; Tol: Double;
      out EigenVal: Double): TDoubleArray; static;
    { Deflate matrix: remove contribution of one eigenvector }
    class procedure Deflate(var M: TDoubleMatrix;
      const V: TDoubleArray; EigenVal: Double); static;
    { Region query for DBSCAN: return indices within Eps of point }
    class function RegionQuery(const X: TDoubleMatrix;
      PointIdx: Integer; Eps: Double): TIntegerArray; static;

  public

    { =======================================================================
      PREPROCESSING
    ======================================================================= }

    { Scale every feature (column) of X to [0, 1].
      Formula: x_scaled = (x - min) / (max - min).
      Columns where max=min are set to 0 (no information).

      X: NSamples × NFeatures matrix (array of row vectors)
      Returns a new matrix the same shape as X. }
    class function Normalise(const X: TDoubleMatrix): TDoubleMatrix; static;

    { Standardise every feature (column) of X to zero mean and unit variance.
      Formula: x_scaled = (x - mean) / std.
      Columns with std=0 are set to 0.

      Tip: always standardise before using KNN, PCA, or Logistic Regression. }
    class function Standardise(const X: TDoubleMatrix): TDoubleMatrix; static;

    { Shuffle rows of X (and corresponding labels Y) and split into
      train / test subsets.
      TestFraction: proportion to put in the test set (e.g. 0.2 → 20% test).
      Seed: random seed for reproducibility.

      Outputs: TrainX, TrainY, TestX, TestY }
    class procedure TrainTestSplit(
      const X: TDoubleMatrix; const Y: TIntegerArray;
      TestFraction: Double; Seed: Integer;
      out TrainX: TDoubleMatrix; out TrainY: TIntegerArray;
      out TestX:  TDoubleMatrix; out TestY:  TIntegerArray); static;

    { Convert integer class labels [0..NClasses-1] to a binary indicator matrix.
      Each row has exactly one 1 at column = label.
      Useful for softmax / multi-class logistic regression.

      Example: [0,2,1] with NClasses=3 →
        [[1,0,0],
         [0,0,1],
         [0,1,0]] }
    class function OneHotEncode(const Labels: TIntegerArray;
      NClasses: Integer): TDoubleMatrix; static;

    { =======================================================================
      REGRESSION
    ======================================================================= }

    { Ordinary Least Squares linear regression.
      Solves: beta = (X'X)^{-1} X'y  (normal equations, augmented with intercept).
      X: NSamples × NFeatures  (do NOT include a bias column — added internally)
      Y: NSamples target values

      Returns coefficients + intercept + R² on the training set.

      Example:
        model := TMLKit.LinearRegression(X, Y);
        pred  := model.Intercept + Dot(model.Coefficients, newX); }
    class function LinearRegression(const X: TDoubleMatrix;
      const Y: TDoubleArray): TLinearModel; static;

    { Ridge regression (L2-regularised linear regression).
      Solves: beta = (X'X + lambda*I)^{-1} X'y
      Lambda: regularisation strength (0 → same as OLS; larger → more shrinkage).

      Use when features are correlated or N < NFeatures. }
    class function RidgeRegression(const X: TDoubleMatrix;
      const Y: TDoubleArray; Lambda: Double): TLinearModel; static;

    { Expand a 1-D feature vector into polynomial features up to Degree.
      Input:  [x_0, x_1, ..., x_{N-1}]
      Output: NSamples × (Degree+1) matrix where row i = [1, x_i, x_i², ..., x_i^Degree]

      Combine with LinearRegression for polynomial regression:
        Xpoly := TMLKit.PolynomialFeatures(x, 3);
        model := TMLKit.LinearRegression(Xpoly, y); }
    class function PolynomialFeatures(const X: TDoubleArray;
      Degree: Integer): TDoubleMatrix; static;

    { Predict values from a linear model for a new dataset.
      Xnew: NSamples × NFeatures (same features as training X) }
    class function LinearPredict(const Model: TLinearModel;
      const Xnew: TDoubleMatrix): TDoubleArray; static;

    { =======================================================================
      CLASSIFICATION
    ======================================================================= }

    { K-Nearest Neighbours classifier.
      Stores the training set in memory; for each test point finds
      the K closest training points by Euclidean distance and returns
      the majority class label.

      K:       number of neighbours (odd number recommended to avoid ties)
      TrainX:  NSamples × NFeatures training data
      TrainY:  NSamples integer class labels (0-based)
      TestX:   MTestSamples × NFeatures query points
      Returns: MTestSamples predicted labels }
    class function KNearestNeighbours(
      const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
      const TestX: TDoubleMatrix; K: Integer): TIntegerArray; static;

    { Gaussian Naive Bayes classifier.
      Trains per-class mean and variance for each feature, then classifies
      new points using the log-posterior:
        log P(class|x) ∝ log P(class) + Σ log N(x_i; mu_i, sigma_i²)

      TrainX: NSamples × NFeatures
      TrainY: NSamples class labels (0-based, consecutive integers)
      TestX:  MTestSamples × NFeatures
      Returns: MTestSamples predicted labels }
    class function NaiveBayes(
      const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
      const TestX: TDoubleMatrix): TIntegerArray; static;

    { Binary logistic regression trained with gradient descent.
      Labels must be 0 or 1.
      LR:      learning rate (default 0.1)
      MaxIter: maximum gradient steps (default 1000)
      Tol:     convergence threshold on gradient norm (default 1e-5)
      Returns a TLinearModel where Coefficients and Intercept define the
      decision boundary; apply Sigmoid(Intercept + Dot(Coeff, x)) to get P(y=1|x).

      Use LogisticPredict to classify new points. }
    class function LogisticRegression(
      const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
      LR: Double = 0.1; MaxIter: Integer = 1000;
      Tol: Double = 1e-5): TLinearModel; static;

    { Predict binary class labels (0 or 1) from a logistic regression model. }
    class function LogisticPredict(const Model: TLinearModel;
      const Xnew: TDoubleMatrix): TIntegerArray; static;

    { =======================================================================
      CLUSTERING
    ======================================================================= }

    { K-Means clustering (Lloyd's algorithm).
      Partitions X into K clusters by minimising within-cluster variance.
      K:       number of clusters
      MaxIter: maximum Lloyd iterations (default 300)
      Seed:    RNG seed for centroid initialisation (default 42)

      Tips:
      - Run several times with different seeds and pick the lowest Inertia.
      - Choose K by plotting Inertia vs K and looking for the "elbow". }
    class function KMeans(const X: TDoubleMatrix; K: Integer;
      MaxIter: Integer = 300; Seed: Integer = 42): TKMeansResult; static;

    { DBSCAN (Density-Based Spatial Clustering of Applications with Noise).
      Groups points that are close together (density reachable) and marks
      outliers as noise (label = -1). Does NOT require specifying K in advance.

      Eps:     neighbourhood radius — points within Eps of each other are neighbours
      MinPts:  minimum points needed to form a dense region (core point threshold)

      Tips:
      - Eps: plot k-distance graph (distances to k-th nearest neighbour), look for elbow.
      - MinPts: rule of thumb = 2 × NFeatures. }
    class function DBSCAN(const X: TDoubleMatrix;
      Eps: Double; MinPts: Integer): TDBSCANResult; static;

    { =======================================================================
      DIMENSIONALITY REDUCTION
    ======================================================================= }

    { Principal Component Analysis.
      Finds the NComponents directions of maximum variance in X.
      Uses power iteration — no external linear algebra library needed.

      NComponents: number of principal components to extract
      MaxIter:     power iteration steps per component (default 1000)
      Tol:         convergence tolerance (default 1e-8)

      Returns components, explained variance, and per-feature mean.

      To project new data:
        Xtransformed := TMLKit.PCATransform(pca, Xnew); }
    class function PCA(const X: TDoubleMatrix; NComponents: Integer;
      MaxIter: Integer = 1000; Tol: Double = 1e-8): TPCAResult; static;

    { Project data onto PCA components.
      Subtracts the training mean then multiplies by the component matrix.
      Returns NSamples × NComponents score matrix. }
    class function PCATransform(const PCARes: TPCAResult;
      const X: TDoubleMatrix): TDoubleMatrix; static;

    { =======================================================================
      MODEL EVALUATION
    ======================================================================= }

    { Fraction of predictions that match the true labels.
      Accuracy = number correct / total }
    class function Accuracy(const YTrue, YPred: TIntegerArray): Double; static;

    { Precision for one class (binary or one-vs-rest).
      ClassLabel: which class to treat as positive.
      Precision = TP / (TP + FP).  Returns 0 when TP+FP=0. }
    class function Precision(const YTrue, YPred: TIntegerArray;
      ClassLabel: Integer): Double; static;

    { Recall (sensitivity / true-positive rate).
      Recall = TP / (TP + FN).  Returns 0 when TP+FN=0. }
    class function Recall(const YTrue, YPred: TIntegerArray;
      ClassLabel: Integer): Double; static;

    { F1 score: harmonic mean of Precision and Recall.
      F1 = 2 * Precision * Recall / (Precision + Recall) }
    class function F1Score(const YTrue, YPred: TIntegerArray;
      ClassLabel: Integer): Double; static;

    { Build a confusion matrix.
      Entry [i][j] = number of samples with true class i predicted as class j.
      NClasses: total number of classes (labels assumed 0..NClasses-1) }
    class function BuildConfusionMatrix(const YTrue, YPred: TIntegerArray;
      NClasses: Integer): TConfusionMatrix; static;

    { Mean Squared Error: mean of (y_true - y_pred)² }
    class function MSE(const YTrue, YPred: TDoubleArray): Double; static;

    { Root Mean Squared Error: sqrt(MSE) }
    class function RMSE(const YTrue, YPred: TDoubleArray): Double; static;

    { Mean Absolute Error: mean of |y_true - y_pred| }
    class function MAE(const YTrue, YPred: TDoubleArray): Double; static;

    { R² (coefficient of determination).
      R² = 1 - SS_res / SS_tot.  Perfect model → 1.0; baseline mean → 0.0. }
    class function R2Score(const YTrue, YPred: TDoubleArray): Double; static;

  end;

implementation

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TMLKit.Dot(const A, B: TDoubleArray): Double;
var I: Integer;
begin
  Result := 0;
  for I := 0 to High(A) do
    Result := Result + A[I] * B[I];
end;

class function TMLKit.Sigmoid(Z: Double): Double;
begin
  Result := 1.0 / (1.0 + Exp(-Z));
end;

class function TMLKit.EuclidDist(const A, B: TDoubleArray): Double;
var I: Integer; S: Double;
begin
  S := 0;
  for I := 0 to High(A) do
    S := S + Sqr(A[I] - B[I]);
  Result := Sqrt(S);
end;

class function TMLKit.MatTranspose(const A: TDoubleMatrix): TDoubleMatrix;
var R, C: Integer;
begin
  if Length(A) = 0 then begin SetLength(Result, 0); Exit; end;
  SetLength(Result, Length(A[0]));
  for C := 0 to High(A[0]) do
  begin
    SetLength(Result[C], Length(A));
    for R := 0 to High(A) do
      Result[C][R] := A[R][C];
  end;
end;

class function TMLKit.MatMul(const A, B: TDoubleMatrix): TDoubleMatrix;
var
  RA, CA, CB, I, J, K: Integer;
  S: Double;
begin
  RA := Length(A);
  CA := Length(A[0]);
  CB := Length(B[0]);
  SetLength(Result, RA);
  for I := 0 to RA - 1 do
  begin
    SetLength(Result[I], CB);
    for J := 0 to CB - 1 do
    begin
      S := 0;
      for K := 0 to CA - 1 do
        S := S + A[I][K] * B[K][J];
      Result[I][J] := S;
    end;
  end;
end;

class function TMLKit.MatAddIdentity(const A: TDoubleMatrix;
  Lambda: Double): TDoubleMatrix;
var N, I, J: Integer;
begin
  N := Length(A);
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    SetLength(Result[I], N);
    for J := 0 to N - 1 do
      Result[I][J] := A[I][J];
    Result[I][I] := Result[I][I] + Lambda;
  end;
end;

{ Gaussian elimination with partial pivoting — solves A*x = b.
  A is copied internally; b is not modified. }
class function TMLKit.SolveLinear(const A: TDoubleMatrix;
  const B: TDoubleArray): TDoubleArray;
var
  N, I, J, K, PivRow: Integer;
  PivVal, F, Tmp: Double;
  M: TDoubleMatrix;
  RHS: TDoubleArray;
begin
  N := Length(A);
  SetLength(M, N);
  for I := 0 to N - 1 do
  begin
    SetLength(M[I], N);
    for J := 0 to N - 1 do M[I][J] := A[I][J];
  end;
  SetLength(RHS, N);
  for I := 0 to N - 1 do RHS[I] := B[I];

  for K := 0 to N - 1 do
  begin
    { Find pivot }
    PivRow := K; PivVal := Abs(M[K][K]);
    for I := K + 1 to N - 1 do
      if Abs(M[I][K]) > PivVal then
      begin PivVal := Abs(M[I][K]); PivRow := I; end;

    if PivVal < 1e-14 then
      raise EMLError.Create('SolveLinear: singular or near-singular matrix');

    { Swap rows }
    if PivRow <> K then
    begin
      for J := 0 to N - 1 do
      begin Tmp := M[K][J]; M[K][J] := M[PivRow][J]; M[PivRow][J] := Tmp; end;
      Tmp := RHS[K]; RHS[K] := RHS[PivRow]; RHS[PivRow] := Tmp;
    end;

    { Eliminate }
    for I := K + 1 to N - 1 do
    begin
      F := M[I][K] / M[K][K];
      for J := K to N - 1 do M[I][J] := M[I][J] - F * M[K][J];
      RHS[I] := RHS[I] - F * RHS[K];
    end;
  end;

  { Back-substitution }
  SetLength(Result, N);
  for I := N - 1 downto 0 do
  begin
    Result[I] := RHS[I];
    for J := I + 1 to N - 1 do
      Result[I] := Result[I] - M[I][J] * Result[J];
    Result[I] := Result[I] / M[I][I];
  end;
end;

{ Power iteration: find dominant eigenvector of symmetric matrix M.
  Returns unit-length eigenvector; sets EigenVal. }
class function TMLKit.PowerIter(const M: TDoubleMatrix;
  MaxIter: Integer; Tol: Double; out EigenVal: Double): TDoubleArray;
var
  N, I, J, Iter: Integer;
  Norm, Delta: Double;
  V, Mv: TDoubleArray;
begin
  N := Length(M);
  SetLength(V, N);
  { Initialise to ones }
  for I := 0 to N - 1 do V[I] := 1.0;
  Norm := Sqrt(N);
  for I := 0 to N - 1 do V[I] := V[I] / Norm;

  EigenVal := 0;
  for Iter := 0 to MaxIter - 1 do
  begin
    { Mv = M * v }
    SetLength(Mv, N);
    for I := 0 to N - 1 do
    begin
      Mv[I] := 0;
      for J := 0 to N - 1 do Mv[I] := Mv[I] + M[I][J] * V[J];
    end;
    { Rayleigh quotient }
    EigenVal := Dot(V, Mv);
    { Normalise }
    Norm := 0;
    for I := 0 to N - 1 do Norm := Norm + Sqr(Mv[I]);
    Norm := Sqrt(Norm);
    if Norm < 1e-14 then Break;
    { Convergence check }
    Delta := 0;
    for I := 0 to N - 1 do Delta := Delta + Sqr(Mv[I]/Norm - V[I]);
    for I := 0 to N - 1 do V[I] := Mv[I] / Norm;
    if Sqrt(Delta) < Tol then Break;
  end;
  Result := V;
end;

{ Remove contribution of eigenvector V (with eigenvalue EigenVal) from M.
  M := M - EigenVal * v*v' }
class procedure TMLKit.Deflate(var M: TDoubleMatrix;
  const V: TDoubleArray; EigenVal: Double);
var N, I, J: Integer;
begin
  N := Length(M);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      M[I][J] := M[I][J] - EigenVal * V[I] * V[J];
end;

class function TMLKit.RegionQuery(const X: TDoubleMatrix;
  PointIdx: Integer; Eps: Double): TIntegerArray;
var
  I, Count: Integer;
begin
  SetLength(Result, Length(X));
  Count := 0;
  for I := 0 to High(X) do
    if EuclidDist(X[PointIdx], X[I]) <= Eps then
    begin
      Result[Count] := I;
      Inc(Count);
    end;
  SetLength(Result, Count);
end;

{ ---------------------------------------------------------------------------
  PREPROCESSING
--------------------------------------------------------------------------- }

class function TMLKit.Normalise(const X: TDoubleMatrix): TDoubleMatrix;
var
  NSamples, NFeatures, I, J: Integer;
  MinVal, MaxVal, Range: Double;
begin
  NSamples  := Length(X);
  if NSamples = 0 then raise EMLError.Create('Normalise: empty matrix');
  NFeatures := Length(X[0]);
  SetLength(Result, NSamples);
  for I := 0 to NSamples - 1 do SetLength(Result[I], NFeatures);

  for J := 0 to NFeatures - 1 do
  begin
    MinVal := X[0][J]; MaxVal := X[0][J];
    for I := 1 to NSamples - 1 do
    begin
      if X[I][J] < MinVal then MinVal := X[I][J];
      if X[I][J] > MaxVal then MaxVal := X[I][J];
    end;
    Range := MaxVal - MinVal;
    for I := 0 to NSamples - 1 do
      if Range > 0 then Result[I][J] := (X[I][J] - MinVal) / Range
      else              Result[I][J] := 0;
  end;
end;

class function TMLKit.Standardise(const X: TDoubleMatrix): TDoubleMatrix;
var
  NSamples, NFeatures, I, J: Integer;
  Mu, Variance, Std: Double;
begin
  NSamples  := Length(X);
  if NSamples = 0 then raise EMLError.Create('Standardise: empty matrix');
  NFeatures := Length(X[0]);
  SetLength(Result, NSamples);
  for I := 0 to NSamples - 1 do SetLength(Result[I], NFeatures);

  for J := 0 to NFeatures - 1 do
  begin
    Mu := 0;
    for I := 0 to NSamples - 1 do Mu := Mu + X[I][J];
    Mu := Mu / NSamples;
    Variance := 0;
    for I := 0 to NSamples - 1 do Variance := Variance + Sqr(X[I][J] - Mu);
    Variance := Variance / NSamples;
    Std := Sqrt(Variance);
    for I := 0 to NSamples - 1 do
      if Std > 0 then Result[I][J] := (X[I][J] - Mu) / Std
      else            Result[I][J] := 0;
  end;
end;

class procedure TMLKit.TrainTestSplit(
  const X: TDoubleMatrix; const Y: TIntegerArray;
  TestFraction: Double; Seed: Integer;
  out TrainX: TDoubleMatrix; out TrainY: TIntegerArray;
  out TestX:  TDoubleMatrix; out TestY:  TIntegerArray);
var
  N, NTest, NTrain, I, J, Tmp: Integer;
  Idx: TIntegerArray;
  { LCG random number generator for reproducibility }
  RandState: Int64;

  function LCGNext: Integer;
  begin
    RandState := (RandState * 6364136223846793005 + 1442695040888963407) and $7FFFFFFFFFFFFFFF;
    Result := RandState mod N;
  end;

begin
  N := Length(X);
  if N = 0 then raise EMLError.Create('TrainTestSplit: empty dataset');
  if (TestFraction <= 0) or (TestFraction >= 1) then
    raise EMLError.Create('TrainTestSplit: TestFraction must be in (0,1)');

  { Build index array }
  SetLength(Idx, N);
  for I := 0 to N - 1 do Idx[I] := I;

  { Fisher-Yates shuffle using LCG }
  RandState := Seed + 1;
  for I := N - 1 downto 1 do
  begin
    J := LCGNext mod (I + 1);
    Tmp := Idx[I]; Idx[I] := Idx[J]; Idx[J] := Tmp;
  end;

  NTest  := Round(N * TestFraction);
  if NTest < 1 then NTest := 1;
  if NTest >= N then NTest := N - 1;
  NTrain := N - NTest;

  SetLength(TrainX, NTrain); SetLength(TrainY, NTrain);
  for I := 0 to NTrain - 1 do
  begin
    TrainX[I] := X[Idx[I]];
    TrainY[I] := Y[Idx[I]];
  end;

  SetLength(TestX, NTest); SetLength(TestY, NTest);
  for I := 0 to NTest - 1 do
  begin
    TestX[I] := X[Idx[NTrain + I]];
    TestY[I] := Y[Idx[NTrain + I]];
  end;
end;

class function TMLKit.OneHotEncode(const Labels: TIntegerArray;
  NClasses: Integer): TDoubleMatrix;
var I, J: Integer;
begin
  if NClasses < 2 then
    raise EMLError.Create('OneHotEncode: NClasses must be >= 2');
  SetLength(Result, Length(Labels));
  for I := 0 to High(Labels) do
  begin
    if (Labels[I] < 0) or (Labels[I] >= NClasses) then
      raise EMLError.Create('OneHotEncode: label out of range');
    SetLength(Result[I], NClasses);
    for J := 0 to NClasses - 1 do Result[I][J] := 0;
    Result[I][Labels[I]] := 1.0;
  end;
end;

{ ---------------------------------------------------------------------------
  REGRESSION
--------------------------------------------------------------------------- }

{ Build augmented X with intercept column prepended, solve normal equations }
class function TMLKit.LinearRegression(const X: TDoubleMatrix;
  const Y: TDoubleArray): TLinearModel;
var
  NSamples, NFeatures, I, J, K: Integer;
  XA: TDoubleMatrix;  { augmented X: [1 | X] }
  XAt, XAtXA: TDoubleMatrix;
  XAtY: TDoubleArray;
  Beta: TDoubleArray;
  YMean, SSTot, SSRes, YHat: Double;
begin
  NSamples  := Length(X);
  NFeatures := Length(X[0]);
  if NSamples <= NFeatures then
    raise EMLError.Create('LinearRegression: need more samples than features');

  { Augment X with bias column }
  SetLength(XA, NSamples);
  for I := 0 to NSamples - 1 do
  begin
    SetLength(XA[I], NFeatures + 1);
    XA[I][0] := 1.0;
    for J := 0 to NFeatures - 1 do XA[I][J + 1] := X[I][J];
  end;

  XAt   := MatTranspose(XA);
  XAtXA := MatMul(XAt, XA);

  { XAt * y }
  SetLength(XAtY, NFeatures + 1);
  for I := 0 to NFeatures do
  begin
    XAtY[I] := 0;
    for K := 0 to NSamples - 1 do XAtY[I] := XAtY[I] + XAt[I][K] * Y[K];
  end;

  Beta := SolveLinear(XAtXA, XAtY);

  Result.Intercept := Beta[0];
  SetLength(Result.Coefficients, NFeatures);
  for J := 0 to NFeatures - 1 do Result.Coefficients[J] := Beta[J + 1];

  { R² }
  YMean := 0;
  for I := 0 to NSamples - 1 do YMean := YMean + Y[I];
  YMean := YMean / NSamples;
  SSTot := 0; SSRes := 0;
  for I := 0 to NSamples - 1 do
  begin
    YHat  := Result.Intercept;
    for J := 0 to NFeatures - 1 do YHat := YHat + Result.Coefficients[J] * X[I][J];
    SSTot := SSTot + Sqr(Y[I] - YMean);
    SSRes := SSRes + Sqr(Y[I] - YHat);
  end;
  if SSTot > 0 then Result.RSquared := 1.0 - SSRes / SSTot
  else              Result.RSquared := 1.0;
end;

class function TMLKit.RidgeRegression(const X: TDoubleMatrix;
  const Y: TDoubleArray; Lambda: Double): TLinearModel;
var
  NSamples, NFeatures, I, J, K: Integer;
  XA, XAt, XAtXA, Reg: TDoubleMatrix;
  XAtY, Beta: TDoubleArray;
  YMean, SSTot, SSRes, YHat: Double;
begin
  NSamples  := Length(X);
  NFeatures := Length(X[0]);

  SetLength(XA, NSamples);
  for I := 0 to NSamples - 1 do
  begin
    SetLength(XA[I], NFeatures + 1);
    XA[I][0] := 1.0;
    for J := 0 to NFeatures - 1 do XA[I][J + 1] := X[I][J];
  end;

  XAt   := MatTranspose(XA);
  XAtXA := MatMul(XAt, XA);
  { Add lambda*I but NOT to the intercept row/col (index 0) }
  Reg := MatAddIdentity(XAtXA, Lambda);
  Reg[0][0] := XAtXA[0][0];  { leave intercept unregularised }

  SetLength(XAtY, NFeatures + 1);
  for I := 0 to NFeatures do
  begin
    XAtY[I] := 0;
    for K := 0 to NSamples - 1 do XAtY[I] := XAtY[I] + XAt[I][K] * Y[K];
  end;

  Beta := SolveLinear(Reg, XAtY);

  Result.Intercept := Beta[0];
  SetLength(Result.Coefficients, NFeatures);
  for J := 0 to NFeatures - 1 do Result.Coefficients[J] := Beta[J + 1];

  YMean := 0;
  for I := 0 to NSamples - 1 do YMean := YMean + Y[I];
  YMean := YMean / NSamples;
  SSTot := 0; SSRes := 0;
  for I := 0 to NSamples - 1 do
  begin
    YHat  := Result.Intercept;
    for J := 0 to NFeatures - 1 do YHat := YHat + Result.Coefficients[J] * X[I][J];
    SSTot := SSTot + Sqr(Y[I] - YMean);
    SSRes := SSRes + Sqr(Y[I] - YHat);
  end;
  if SSTot > 0 then Result.RSquared := 1.0 - SSRes / SSTot
  else              Result.RSquared := 1.0;
end;

class function TMLKit.PolynomialFeatures(const X: TDoubleArray;
  Degree: Integer): TDoubleMatrix;
var
  N, I, D: Integer;
begin
  if Degree < 1 then raise EMLError.Create('PolynomialFeatures: Degree must be >= 1');
  N := Length(X);
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    SetLength(Result[I], Degree + 1);
    Result[I][0] := 1.0;
    for D := 1 to Degree do
      Result[I][D] := Power(X[I], D);
  end;
end;

class function TMLKit.LinearPredict(const Model: TLinearModel;
  const Xnew: TDoubleMatrix): TDoubleArray;
var
  NSamples, NFeatures, I, J: Integer;
begin
  NSamples  := Length(Xnew);
  NFeatures := Length(Model.Coefficients);
  SetLength(Result, NSamples);
  for I := 0 to NSamples - 1 do
  begin
    Result[I] := Model.Intercept;
    for J := 0 to NFeatures - 1 do
      Result[I] := Result[I] + Model.Coefficients[J] * Xnew[I][J];
  end;
end;

{ ---------------------------------------------------------------------------
  CLASSIFICATION
--------------------------------------------------------------------------- }

class function TMLKit.KNearestNeighbours(
  const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
  const TestX: TDoubleMatrix; K: Integer): TIntegerArray;
var
  NTrain, NTest, NFeatures, I, J, L, MaxCount, MaxClass: Integer;
  Dist: Double;
  Distances: TDoubleArray;
  SortedIdx: TIntegerArray;
  Votes: TIntegerArray;
  Tmp: Integer;
  TmpD: Double;
begin
  NTrain    := Length(TrainX);
  NTest     := Length(TestX);
  NFeatures := Length(TrainX[0]);

  if K < 1 then raise EMLError.Create('KNN: K must be >= 1');
  if K > NTrain then raise EMLError.Create('KNN: K > training samples');

  SetLength(Result, NTest);
  SetLength(Distances, NTrain);
  SetLength(SortedIdx, NTrain);

  for I := 0 to NTest - 1 do
  begin
    { Compute distances to all training points }
    for J := 0 to NTrain - 1 do
    begin
      Distances[J] := EuclidDist(TestX[I], TrainX[J]);
      SortedIdx[J] := J;
    end;

    { Partial insertion sort to find K smallest }
    for J := 1 to K do
      for L := J - 1 downto 0 do
      begin
        if Distances[SortedIdx[L]] > Distances[SortedIdx[L + 1]] then
        begin
          Tmp := SortedIdx[L]; SortedIdx[L] := SortedIdx[L+1]; SortedIdx[L+1] := Tmp;
        end else Break;
      end;

    { Majority vote among K nearest }
    SetLength(Votes, 0);
    for J := 0 to K - 1 do
    begin
      L := TrainY[SortedIdx[J]];
      while Length(Votes) <= L do
      begin
        SetLength(Votes, Length(Votes) + 1);
        Votes[High(Votes)] := 0;
      end;
      Inc(Votes[L]);
    end;

    MaxCount := -1; MaxClass := 0;
    for J := 0 to High(Votes) do
      if Votes[J] > MaxCount then begin MaxCount := Votes[J]; MaxClass := J; end;
    Result[I] := MaxClass;
  end;
end;

class function TMLKit.NaiveBayes(
  const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
  const TestX: TDoubleMatrix): TIntegerArray;
var
  NSamples, NTest, NFeatures, NClasses, I, J, C: Integer;
  ClassCounts: TIntegerArray;
  ClassMeans, ClassVars: TDoubleMatrix;
  LogProb, BestProb, Diff, V: Double;
  BestClass: Integer;
begin
  NSamples  := Length(TrainX);
  NTest     := Length(TestX);
  NFeatures := Length(TrainX[0]);

  { Find NClasses }
  NClasses := 0;
  for I := 0 to NSamples - 1 do
    if TrainY[I] >= NClasses then NClasses := TrainY[I] + 1;

  SetLength(ClassCounts, NClasses);
  SetLength(ClassMeans,  NClasses);
  SetLength(ClassVars,   NClasses);
  for C := 0 to NClasses - 1 do
  begin
    SetLength(ClassMeans[C], NFeatures);
    SetLength(ClassVars[C],  NFeatures);
  end;

  { Accumulate means }
  for I := 0 to NSamples - 1 do
  begin
    C := TrainY[I];
    Inc(ClassCounts[C]);
    for J := 0 to NFeatures - 1 do
      ClassMeans[C][J] := ClassMeans[C][J] + TrainX[I][J];
  end;
  for C := 0 to NClasses - 1 do
    if ClassCounts[C] > 0 then
      for J := 0 to NFeatures - 1 do
        ClassMeans[C][J] := ClassMeans[C][J] / ClassCounts[C];

  { Accumulate variances (with Laplace smoothing 1e-9) }
  for I := 0 to NSamples - 1 do
  begin
    C := TrainY[I];
    for J := 0 to NFeatures - 1 do
      ClassVars[C][J] := ClassVars[C][J] + Sqr(TrainX[I][J] - ClassMeans[C][J]);
  end;
  for C := 0 to NClasses - 1 do
    if ClassCounts[C] > 0 then
      for J := 0 to NFeatures - 1 do
        ClassVars[C][J] := ClassVars[C][J] / ClassCounts[C] + 1e-9;

  { Classify test points }
  SetLength(Result, NTest);
  for I := 0 to NTest - 1 do
  begin
    BestProb := -Infinity; BestClass := 0;
    for C := 0 to NClasses - 1 do
    begin
      if ClassCounts[C] = 0 then Continue;
      { log prior }
      LogProb := Ln(ClassCounts[C] / NSamples);
      { log likelihood: Gaussian log N(x; mu, sigma²) }
      for J := 0 to NFeatures - 1 do
      begin
        V    := ClassVars[C][J];
        Diff := TestX[I][J] - ClassMeans[C][J];
        LogProb := LogProb - 0.5 * Ln(2 * Pi * V) - 0.5 * Sqr(Diff) / V;
      end;
      if LogProb > BestProb then begin BestProb := LogProb; BestClass := C; end;
    end;
    Result[I] := BestClass;
  end;
end;

class function TMLKit.LogisticRegression(
  const TrainX: TDoubleMatrix; const TrainY: TIntegerArray;
  LR: Double; MaxIter: Integer; Tol: Double): TLinearModel;
var
  NSamples, NFeatures, I, J, Iter: Integer;
  W: TDoubleArray;  { weights including bias at index 0 }
  YHat, Err, GradNorm, G: Double;
  Grad: TDoubleArray;
begin
  NSamples  := Length(TrainX);
  NFeatures := Length(TrainX[0]);

  SetLength(W, NFeatures + 1);  { W[0] = bias }
  for I := 0 to High(W) do W[I] := 0.0;

  SetLength(Grad, NFeatures + 1);

  for Iter := 0 to MaxIter - 1 do
  begin
    { Compute gradient of cross-entropy }
    for I := 0 to NFeatures do Grad[I] := 0;
    for I := 0 to NSamples - 1 do
    begin
      YHat := W[0];
      for J := 0 to NFeatures - 1 do YHat := YHat + W[J + 1] * TrainX[I][J];
      YHat := Sigmoid(YHat);
      Err  := YHat - TrainY[I];
      Grad[0] := Grad[0] + Err;
      for J := 0 to NFeatures - 1 do
        Grad[J + 1] := Grad[J + 1] + Err * TrainX[I][J];
    end;
    GradNorm := 0;
    for I := 0 to NFeatures do
    begin
      G := Grad[I] / NSamples;
      W[I] := W[I] - LR * G;
      GradNorm := GradNorm + Sqr(G);
    end;
    if Sqrt(GradNorm) < Tol then Break;
  end;

  Result.Intercept := W[0];
  SetLength(Result.Coefficients, NFeatures);
  for J := 0 to NFeatures - 1 do Result.Coefficients[J] := W[J + 1];
  Result.RSquared := 0;  { not meaningful for logistic — use Accuracy instead }
end;

class function TMLKit.LogisticPredict(const Model: TLinearModel;
  const Xnew: TDoubleMatrix): TIntegerArray;
var
  NSamples, NFeatures, I, J: Integer;
  Z: Double;
begin
  NSamples  := Length(Xnew);
  NFeatures := Length(Model.Coefficients);
  SetLength(Result, NSamples);
  for I := 0 to NSamples - 1 do
  begin
    Z := Model.Intercept;
    for J := 0 to NFeatures - 1 do Z := Z + Model.Coefficients[J] * Xnew[I][J];
    if Sigmoid(Z) >= 0.5 then Result[I] := 1 else Result[I] := 0;
  end;
end;

{ ---------------------------------------------------------------------------
  CLUSTERING
--------------------------------------------------------------------------- }

class function TMLKit.KMeans(const X: TDoubleMatrix; K: Integer;
  MaxIter: Integer; Seed: Integer): TKMeansResult;
var
  NSamples, NFeatures, I, J, C, Iter, NearC: Integer;
  Centroids: TDoubleMatrix;
  Labels: TIntegerArray;
  ClusterSizes: TIntegerArray;
  MinDist, Dist, Inertia: Double;
  Changed: Boolean;
  RandState: Int64;

  function LCGNext(Range: Integer): Integer;
  begin
    RandState := (RandState * 6364136223846793005 + 1442695040888963407) and $7FFFFFFFFFFFFFFF;
    Result := RandState mod Range;
  end;

begin
  NSamples  := Length(X);
  NFeatures := Length(X[0]);
  if K < 1 then raise EMLError.Create('KMeans: K must be >= 1');
  if K > NSamples then raise EMLError.Create('KMeans: K > number of samples');

  { Initialise centroids by random sampling }
  RandState := Seed + 1;
  SetLength(Centroids, K);
  for I := 0 to K - 1 do
  begin
    C := LCGNext(NSamples);
    SetLength(Centroids[I], NFeatures);
    for J := 0 to NFeatures - 1 do Centroids[I][J] := X[C][J];
  end;

  SetLength(Labels, NSamples);
  SetLength(ClusterSizes, K);

  for Iter := 0 to MaxIter - 1 do
  begin
    Changed := False;

    { Assignment step }
    for I := 0 to NSamples - 1 do
    begin
      MinDist := Infinity; NearC := 0;
      for C := 0 to K - 1 do
      begin
        Dist := EuclidDist(X[I], Centroids[C]);
        if Dist < MinDist then begin MinDist := Dist; NearC := C; end;
      end;
      if Labels[I] <> NearC then Changed := True;
      Labels[I] := NearC;
    end;

    if not Changed then Break;

    { Update step: recompute centroids }
    for C := 0 to K - 1 do
    begin
      ClusterSizes[C] := 0;
      for J := 0 to NFeatures - 1 do Centroids[C][J] := 0;
    end;
    for I := 0 to NSamples - 1 do
    begin
      C := Labels[I];
      Inc(ClusterSizes[C]);
      for J := 0 to NFeatures - 1 do Centroids[C][J] := Centroids[C][J] + X[I][J];
    end;
    for C := 0 to K - 1 do
      if ClusterSizes[C] > 0 then
        for J := 0 to NFeatures - 1 do Centroids[C][J] := Centroids[C][J] / ClusterSizes[C];
  end;

  { Compute final inertia }
  Inertia := 0;
  for I := 0 to NSamples - 1 do
    Inertia := Inertia + Sqr(EuclidDist(X[I], Centroids[Labels[I]]));

  Result.Labels    := Labels;
  Result.Centroids := Centroids;
  Result.Inertia   := Inertia;
  Result.Iters     := Iter + 1;
end;

class function TMLKit.DBSCAN(const X: TDoubleMatrix;
  Eps: Double; MinPts: Integer): TDBSCANResult;
var
  N, I, J, ClusterID: Integer;
  Labels: TIntegerArray;
  Visited: array of Boolean;
  Neighbours, NewNeighbours: TIntegerArray;
  Queue: TIntegerArray;
  QHead, QTail, QItem: Integer;
begin
  N := Length(X);
  if N = 0 then raise EMLError.Create('DBSCAN: empty dataset');

  SetLength(Labels,  N);
  SetLength(Visited, N);
  for I := 0 to N - 1 do begin Labels[I] := -1; Visited[I] := False; end;

  ClusterID := 0;
  SetLength(Queue, N);

  for I := 0 to N - 1 do
  begin
    if Visited[I] then Continue;
    Visited[I] := True;
    Neighbours := RegionQuery(X, I, Eps);

    if Length(Neighbours) < MinPts then
    begin
      Labels[I] := -1;  { noise — may be absorbed later }
      Continue;
    end;

    { Start new cluster }
    Labels[I] := ClusterID;
    QHead := 0; QTail := 0;
    for J := 0 to High(Neighbours) do
    begin
      Queue[QTail] := Neighbours[J];
      Inc(QTail);
    end;

    while QHead < QTail do
    begin
      QItem := Queue[QHead]; Inc(QHead);
      if Labels[QItem] = -1 then Labels[QItem] := ClusterID;  { absorb noise }
      if Visited[QItem] then Continue;
      Visited[QItem] := True;
      Labels[QItem]  := ClusterID;
      NewNeighbours  := RegionQuery(X, QItem, Eps);
      if Length(NewNeighbours) >= MinPts then
        for J := 0 to High(NewNeighbours) do
        begin
          Queue[QTail] := NewNeighbours[J];
          Inc(QTail);
          if QTail >= N * 4 then  { grow queue if needed }
          begin
            SetLength(Queue, Length(Queue) * 2);
          end;
        end;
    end;

    Inc(ClusterID);
  end;

  Result.Labels    := Labels;
  Result.NClusters := ClusterID;
end;

{ ---------------------------------------------------------------------------
  DIMENSIONALITY REDUCTION
--------------------------------------------------------------------------- }

class function TMLKit.PCA(const X: TDoubleMatrix; NComponents: Integer;
  MaxIter: Integer; Tol: Double): TPCAResult;
var
  NSamples, NFeatures, I, J, K: Integer;
  Mu: TDoubleArray;
  Xc: TDoubleMatrix;  { centred X }
  Cov: TDoubleMatrix; { covariance matrix NFeatures × NFeatures }
  EigenVal, TotalVar: Double;
  Component: TDoubleArray;
  CovCopy: TDoubleMatrix;
begin
  NSamples  := Length(X);
  NFeatures := Length(X[0]);
  if NComponents < 1 then
    raise EMLError.Create('PCA: NComponents must be >= 1');
  if NComponents > NFeatures then
    raise EMLError.Create('PCA: NComponents > NFeatures');

  { Compute column means }
  SetLength(Mu, NFeatures);
  for J := 0 to NFeatures - 1 do
  begin
    Mu[J] := 0;
    for I := 0 to NSamples - 1 do Mu[J] := Mu[J] + X[I][J];
    Mu[J] := Mu[J] / NSamples;
  end;

  { Centre X }
  SetLength(Xc, NSamples);
  for I := 0 to NSamples - 1 do
  begin
    SetLength(Xc[I], NFeatures);
    for J := 0 to NFeatures - 1 do Xc[I][J] := X[I][J] - Mu[J];
  end;

  { Covariance matrix = (Xc' * Xc) / (NSamples - 1) }
  SetLength(Cov, NFeatures);
  for I := 0 to NFeatures - 1 do
  begin
    SetLength(Cov[I], NFeatures);
    for J := 0 to NFeatures - 1 do
    begin
      Cov[I][J] := 0;
      for K := 0 to NSamples - 1 do Cov[I][J] := Cov[I][J] + Xc[K][I] * Xc[K][J];
      Cov[I][J] := Cov[I][J] / (NSamples - 1);
    end;
  end;

  { Extract NComponents dominant eigenvectors by power iteration + deflation }
  SetLength(Result.Components,        NComponents);
  SetLength(Result.ExplainedVariance, NComponents);

  { Work on a copy of Cov for deflation }
  SetLength(CovCopy, NFeatures);
  for I := 0 to NFeatures - 1 do
  begin
    SetLength(CovCopy[I], NFeatures);
    for J := 0 to NFeatures - 1 do CovCopy[I][J] := Cov[I][J];
  end;

  for K := 0 to NComponents - 1 do
  begin
    Component := PowerIter(CovCopy, MaxIter, Tol, EigenVal);
    Result.Components[K]        := Component;
    Result.ExplainedVariance[K] := EigenVal;
    Deflate(CovCopy, Component, EigenVal);
  end;

  { Total variance = trace of original covariance matrix }
  TotalVar := 0;
  for I := 0 to NFeatures - 1 do TotalVar := TotalVar + Cov[I][I];

  SetLength(Result.ExplainedRatio, NComponents);
  for K := 0 to NComponents - 1 do
    if TotalVar > 0 then
      Result.ExplainedRatio[K] := Result.ExplainedVariance[K] / TotalVar
    else
      Result.ExplainedRatio[K] := 0;

  Result.Mean := Mu;
end;

class function TMLKit.PCATransform(const PCARes: TPCAResult;
  const X: TDoubleMatrix): TDoubleMatrix;
var
  NSamples, NFeatures, NComponents, I, J, K: Integer;
  Centered: TDoubleArray;
begin
  NSamples    := Length(X);
  NFeatures   := Length(PCARes.Mean);
  NComponents := Length(PCARes.Components);

  SetLength(Result, NSamples);
  SetLength(Centered, NFeatures);

  for I := 0 to NSamples - 1 do
  begin
    SetLength(Result[I], NComponents);
    for J := 0 to NFeatures - 1 do
      Centered[J] := X[I][J] - PCARes.Mean[J];
    for K := 0 to NComponents - 1 do
      Result[I][K] := Dot(PCARes.Components[K], Centered);
  end;
end;

{ ---------------------------------------------------------------------------
  MODEL EVALUATION
--------------------------------------------------------------------------- }

class function TMLKit.Accuracy(const YTrue, YPred: TIntegerArray): Double;
var N, I, Correct: Integer;
begin
  N := Length(YTrue);
  if N = 0 then raise EMLError.Create('Accuracy: empty arrays');
  if N <> Length(YPred) then raise EMLError.Create('Accuracy: length mismatch');
  Correct := 0;
  for I := 0 to N - 1 do
    if YTrue[I] = YPred[I] then Inc(Correct);
  Result := Correct / N;
end;

class function TMLKit.Precision(const YTrue, YPred: TIntegerArray;
  ClassLabel: Integer): Double;
var N, I, TP, FP: Integer;
begin
  N := Length(YTrue);
  TP := 0; FP := 0;
  for I := 0 to N - 1 do
  begin
    if YPred[I] = ClassLabel then
    begin
      if YTrue[I] = ClassLabel then Inc(TP) else Inc(FP);
    end;
  end;
  if TP + FP = 0 then Result := 0 else Result := TP / (TP + FP);
end;

class function TMLKit.Recall(const YTrue, YPred: TIntegerArray;
  ClassLabel: Integer): Double;
var N, I, TP, FN: Integer;
begin
  N := Length(YTrue);
  TP := 0; FN := 0;
  for I := 0 to N - 1 do
  begin
    if YTrue[I] = ClassLabel then
    begin
      if YPred[I] = ClassLabel then Inc(TP) else Inc(FN);
    end;
  end;
  if TP + FN = 0 then Result := 0 else Result := TP / (TP + FN);
end;

class function TMLKit.F1Score(const YTrue, YPred: TIntegerArray;
  ClassLabel: Integer): Double;
var P, R: Double;
begin
  P := Precision(YTrue, YPred, ClassLabel);
  R := Recall(YTrue, YPred, ClassLabel);
  if P + R = 0 then Result := 0
  else              Result := 2 * P * R / (P + R);
end;

class function TMLKit.BuildConfusionMatrix(const YTrue, YPred: TIntegerArray;
  NClasses: Integer): TConfusionMatrix;
var N, I, C: Integer;
begin
  N := Length(YTrue);
  if N <> Length(YPred) then
    raise EMLError.Create('ConfusionMatrix: length mismatch');
  Result.NClasses := NClasses;
  SetLength(Result.Counts, NClasses);
  for C := 0 to NClasses - 1 do
  begin
    SetLength(Result.Counts[C], NClasses);
    for I := 0 to NClasses - 1 do Result.Counts[C][I] := 0;
  end;
  for I := 0 to N - 1 do
  begin
    if (YTrue[I] < 0) or (YTrue[I] >= NClasses) or
       (YPred[I] < 0) or (YPred[I] >= NClasses) then
      raise EMLError.Create('ConfusionMatrix: label out of range');
    Result.Counts[YTrue[I]][YPred[I]] := Result.Counts[YTrue[I]][YPred[I]] + 1;
  end;
end;

class function TMLKit.MSE(const YTrue, YPred: TDoubleArray): Double;
var N, I: Integer;
begin
  N := Length(YTrue);
  if N = 0 then raise EMLError.Create('MSE: empty arrays');
  Result := 0;
  for I := 0 to N - 1 do Result := Result + Sqr(YTrue[I] - YPred[I]);
  Result := Result / N;
end;

class function TMLKit.RMSE(const YTrue, YPred: TDoubleArray): Double;
begin
  Result := Sqrt(MSE(YTrue, YPred));
end;

class function TMLKit.MAE(const YTrue, YPred: TDoubleArray): Double;
var N, I: Integer;
begin
  N := Length(YTrue);
  if N = 0 then raise EMLError.Create('MAE: empty arrays');
  Result := 0;
  for I := 0 to N - 1 do Result := Result + Abs(YTrue[I] - YPred[I]);
  Result := Result / N;
end;

class function TMLKit.R2Score(const YTrue, YPred: TDoubleArray): Double;
var N, I: Integer;
    YMean, SSTot, SSRes: Double;
begin
  N := Length(YTrue);
  if N = 0 then raise EMLError.Create('R2Score: empty arrays');
  YMean := 0;
  for I := 0 to N - 1 do YMean := YMean + YTrue[I];
  YMean := YMean / N;
  SSTot := 0; SSRes := 0;
  for I := 0 to N - 1 do
  begin
    SSTot := SSTot + Sqr(YTrue[I] - YMean);
    SSRes := SSRes + Sqr(YTrue[I] - YPred[I]);
  end;
  if SSTot > 0 then Result := 1 - SSRes / SSTot
  else              Result := 1.0;
end;

end.
