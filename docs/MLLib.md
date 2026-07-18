# MLLib Reference

`MLLib.MachineLearning` — machine learning primitives for Free Pascal.

---

## Quick Start

```pascal
uses MLLib.MachineLearning;

// Preprocess: scale features to [0,1]
Xscaled := TMLKit.Normalise(X);

// Train a linear regression model
model := TMLKit.LinearRegression(X, Y);
pred  := TMLKit.LinearPredict(model, Xtest);

// Classify with K-Nearest Neighbours
labels := TMLKit.KNearestNeighbours(TrainX, TrainY, TestX, 5);

// Cluster with K-Means
clusters := TMLKit.KMeans(X, 3);

// Reduce dimensions with PCA
pca       := TMLKit.PCA(X, 2);
Xreduced  := TMLKit.PCATransform(pca, X);

// Evaluate
WriteLn(TMLKit.Accuracy(YTrue, YPred));
WriteLn(TMLKit.RMSE(YTrue, YPred));
```

All methods are **class static** — no `Create`/`Free` needed.

---

## Key Types

```pascal
{ 2-D matrix: array of row vectors }
TDoubleMatrix = array of TDoubleArray;

{ Fitted linear/logistic model }
TLinearModel = record
  Coefficients: TDoubleArray;   { one per feature }
  Intercept:    Double;
  RSquared:     Double;         { training R² (not meaningful for logistic) }
end;

{ K-Means result }
TKMeansResult = record
  Labels:    TIntegerArray;   { cluster index per sample }
  Centroids: TDoubleMatrix;   { K × NFeatures }
  Inertia:   Double;          { within-cluster sum of squared distances }
  Iters:     Integer;
end;

{ PCA result }
TPCAResult = record
  Components:        TDoubleMatrix;   { NComponents × NFeatures }
  ExplainedVariance: TDoubleArray;
  ExplainedRatio:    TDoubleArray;    { fraction of total variance }
  Mean:              TDoubleArray;    { training mean, needed to transform new data }
  Iterations:         TIntegerArray;   { power iterations used per component }
end;

{ DBSCAN result }
TDBSCANResult = record
  Labels:    TIntegerArray;   { -1 = noise }
  NClusters: Integer;
end;

{ Confusion matrix }
TConfusionMatrix = record
  Counts:   TDoubleMatrix;    { NClasses × NClasses; [true][predicted] }
  NClasses: Integer;
end;
```

---

## Typical ML Workflow

```
Raw data
  ↓ TrainTestSplit (hold out 20%)
  ↓ Normalise / Standardise
  ↓ Train model (LinearRegression, KNN, NaiveBayes, ...)
  ↓ Predict on test set
  ↓ Evaluate (Accuracy, RMSE, R2Score, ConfusionMatrix, ...)
```

---

## Preprocessing

### Normalise

```pascal
Xscaled := TMLKit.Normalise(X);
```

Scales each feature (column) to [0, 1]. Formula: `(x − min) / (max − min)`.  
Columns where max = min are set to 0.

**When to use:** distance- and gradient-based models such as KNN and logistic
regression benefit when feature ranges differ substantially.

### Standardise

```pascal
Xscaled := TMLKit.Standardise(X);
```

Centres each feature at zero mean and scales to unit variance. Formula: `(x − μ) / σ`.  
Columns with σ = 0 are set to 0.

**When to use:** PCA when feature scales should contribute comparably, logistic
regression, and models that use distances or dot products. `PCA` centres input
itself; standardisation is optional and changes covariance PCA into a
scale-normalised analysis.

### TrainTestSplit

```pascal
TMLKit.TrainTestSplit(X, Y, TestFraction, Seed,
  TrainX, TrainY, TestX, TestY);
```

Shuffles rows with a deterministic LCG (seed-reproducible) then splits.  
`TestFraction = 0.2` → 20% test, 80% train.

### OneHotEncode

```pascal
M := TMLKit.OneHotEncode(Labels, NClasses);
```

Converts integer labels `[0..NClasses-1]` to a binary indicator matrix.  
Row `i` has a `1` at column `Labels[i]` and `0` elsewhere.

---

## Regression

### LinearRegression (OLS)

```pascal
model := TMLKit.LinearRegression(X, Y);
// model.Coefficients  — one coefficient per feature
// model.Intercept     — bias term
// model.RSquared      — training R²
```

Uses centered Householder QR rather than forming `X'X`, avoiding the condition-
number squaring of normal equations. The intercept is fitted internally — do
**not** add a bias column to X. At least as many samples as features are
required; rank-deficient designs raise `EMLError`.

### RidgeRegression

```pascal
model := TMLKit.RidgeRegression(X, Y, Lambda);
```

L2-regularised OLS: β = (X'X + λI)⁻¹ X'y. The intercept is not regularised.

- `Lambda = 0` → same as OLS
- `Lambda` large → coefficients shrink toward zero

**When to use:** correlated features, N < NFeatures.

### PolynomialFeatures

```pascal
Xpoly := TMLKit.PolynomialFeatures(X1D, Degree);
// Xpoly[i] = [1, x_i, x_i², ..., x_i^Degree]

// LinearRegression fits an intercept, so omit PolynomialFeatures' bias column:
Xpoly := TMLKit.PolynomialFeatures(X1D, Degree, False);
model := TMLKit.LinearRegression(Xpoly, Y);
```

Expands a 1-D feature vector to a polynomial design matrix. The two-argument
compatibility overload includes a bias column. Pass `IncludeBias = False` when
combining it with `LinearRegression`, which fits its own intercept.

### LinearPredict

```pascal
YHat := TMLKit.LinearPredict(model, Xnew);
```

Applies a fitted LinearRegression or RidgeRegression model to new data.

---

## Classification

### KNearestNeighbours

```pascal
labels := TMLKit.KNearestNeighbours(TrainX, TrainY, TestX, K);
```

For each test point, finds the K closest training points by Euclidean distance and returns the majority class label.

**Tips:**
- Standardise features first (distance is not scale-invariant)
- K=1 overfits; K=sqrt(N) is a common starting point
- Use odd K to avoid ties in binary classification

### NaiveBayes (Gaussian)

```pascal
labels := TMLKit.NaiveBayes(TrainX, TrainY, TestX);
```

Estimates a Gaussian distribution per feature per class, then classifies by maximum log-posterior. Very fast and works well with many features.

**When to use:** text classification, spam filtering, or when features are (approximately) independent.

### LogisticRegression

```pascal
model := TMLKit.LogisticRegression(TrainX, TrainY);
model := TMLKit.LogisticRegression(TrainX, TrainY, LR, MaxIter, Tol);
labels := TMLKit.LogisticPredict(model, Xnew);
```

Binary (0/1) logistic regression trained with gradient descent.  
`Sigmoid(Intercept + Dot(Coefficients, x)) ≥ 0.5` → class 1.

**Parameters:** `LR` learning rate (0.1), `MaxIter` (1000), `Tol` gradient norm (1e-5).

**When to use:** binary classification. `LogisticPredict` returns labels only;
there is no public probability method, so callers needing scores must evaluate
`1 / (1 + Exp(-(Intercept + dot(Coefficients, x))))` themselves. Probability
calibration is not assessed by this implementation.

---

## Clustering

### KMeans

```pascal
R := TMLKit.KMeans(X, K);
R := TMLKit.KMeans(X, K, MaxIter, Seed);
// R.Labels    — cluster index 0..K-1 per sample
// R.Centroids — K centroid coordinates
// R.Inertia   — total within-cluster squared distance
```

Lloyd's algorithm: alternate between assigning each point to its nearest centroid and recomputing centroids.

**Choosing K:**
1. Run KMeans for K = 1, 2, ..., 10
2. Plot Inertia vs K
3. Pick the "elbow" where improvement flattens

**Tips:**
- Run multiple times with different seeds; pick lowest Inertia
- Standardise features first

### DBSCAN

```pascal
R := TMLKit.DBSCAN(X, Eps, MinPts);
// R.Labels    — cluster index or -1 (noise) per sample
// R.NClusters — number of clusters found
```

Finds arbitrarily-shaped clusters without specifying K. Points in low-density regions are labelled noise (-1).

**Choosing parameters:**
- `Eps`: plot sorted k-distances (k = MinPts); pick the knee
- `MinPts`: rule of thumb = 2 × NFeatures; larger = more conservative

---

## Dimensionality Reduction

### PCA

```pascal
R   := TMLKit.PCA(X, NComponents);
Xr  := TMLKit.PCATransform(R, Xnew);
// R.Components[k]       — k-th principal component (unit vector in feature space)
// R.ExplainedVariance   — eigenvalue of each component
// R.ExplainedRatio[k]   — fraction of total variance explained by component k
// R.Mean                — training mean (subtracted before projection)
// R.Iterations[k]       — iterations used for component k
```

Extracts the `NComponents` directions of maximum variance using **power
iteration + deflation** (no LAPACK needed). Each component is re-orthogonalised,
and convergence is sign-invariant. If power iteration exhausts its iteration
limit, `EMLError` is raised instead of returning an unconverged component.
Rank-deficient covariance matrices receive a deterministic orthogonal
completion with zero explained variance; a completely zero-variance dataset is
rejected.

**Steps:**
1. Standardise X before calling PCA
2. Check `ExplainedRatio` to decide how many components to keep
3. Use `PCATransform` to project both training and test data

**When to use:** visualisation (NComponents=2), noise reduction, or to decorrelate features before logistic regression.

---

## Model Evaluation

| Function | Formula | Returns |
|---|---|---|
| `Accuracy` | correct / total | 0..1 |
| `Precision` | TP / (TP+FP) | 0..1 |
| `Recall` | TP / (TP+FN) | 0..1 |
| `F1Score` | 2·P·R / (P+R) | 0..1 |
| `MSE` | mean (y−ŷ)² | ≥ 0 |
| `RMSE` | √MSE | ≥ 0, same units as y |
| `MAE` | mean |y−ŷ| | ≥ 0 |
| `R2Score` | 1 − SS_res/SS_tot | ≤ 1 |

```pascal
// Classification
WriteLn(TMLKit.Accuracy(YTrue, YPred));
WriteLn(TMLKit.F1Score(YTrue, YPred, ClassLabel := 1));
CM := TMLKit.BuildConfusionMatrix(YTrue, YPred, NClasses);

// Regression
WriteLn(TMLKit.RMSE(YTrue, YPred));
WriteLn(TMLKit.R2Score(YTrue, YPred));
```

For a constant `YTrue` (zero total sum of squares), `R2Score` returns `1.0`
regardless of predictions. Handle that degenerate case separately if your
application needs a different convention.

---

## Error Handling

`EMLError` is raised for:
- Empty, ragged, or zero-feature matrices
- NaN or infinite feature/target values
- Feature-count or sample/target length mismatches
- K > number of training samples (KNN, KMeans)
- NComponents > NFeatures (PCA)
- Negative or out-of-range labels, and non-binary logistic-regression labels
- too few samples or a rank-deficient design in `LinearRegression`
- a zero-variance PCA dataset or exhausted PCA power iteration
- Invalid fractions, iteration counts, tolerances, learning rates, radii, or regularisation parameters

`PCATransform` is an exception to the general empty-matrix rule: it returns
`nil` for empty input.

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`, `TIntegerArray`

No other external libraries required.
