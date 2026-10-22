# MLLib Reference

`MLLib.MachineLearning` — machine learning primitives for Free Pascal.

`MLLib.Analysis` adds typed-dense PCA, seeded k-means++, deterministic
validation splits, fitted standardization, binary LDA, hierarchical
clustering, reproducible decision forests, and an exact low-dimensional
`TKDTree`. Rows are observations and columns are features. See the
[applied numerics guide](applied-numerics.md) for stable 1.8 contracts and
explicitly open data-science families.

## Learning routes

### Beginner route

Copy and run the [double-real regression quick start](#quick-start). It creates
a small row-major `TDoubleMatrix`, allocates a fitted model, and prints
`y = 1.0 + 2.0*x`.

### Common tasks and algorithm choice

| Task | Start with | Contract or failure guidance |
| --- | --- | --- |
| Scale features | fitted standardisation for train/test work | [Preprocessing](#preprocessing) |
| Continuous prediction | `LinearRegression` / typed `FitOLS` | [Regression](#regression) |
| Regression with correlated predictors | `TPLSKit.Fit` | [PLS regression](#partial-least-squares-regression) |
| Classification | logistic, KNN, or forest by data/diagnostics | [Classification](#classification) |
| Unlabelled grouping | seeded k-means++ or hierarchical clustering | [Clustering](#clustering) |
| Lower-dimensional representation | typed PCA | [Dimensionality reduction](#dimensionality-reduction) |

### Advanced route

Run [example 19](../../../examples/19_applied_data_pipeline.pas) for typed PCA and
seeded clustering or [example 21](../../../examples/21_release_1_8_workflows.pas) for
fitted standardisation and forests. Nested beginner matrices convert through
the explicit typed factories described by the advanced guide; fitted
train/test paths themselves need no undocumented glue.

## Typed analysis additions in 1.8

Use `TAnalysisKit.FitStandardization` only on training rows, then apply the
returned `TStandardizationModel` to training, validation, and test matrices
with `TransformStandardized`. Constant columns receive a safe unit scale.
The model owns its means and scales; transforms return new dense matrices.
This explicit fit/transform split prevents validation leakage.

`HierarchicalCluster(Data, Linkage)` supports `hlSingle`, `hlComplete`, and
`hlAverage`. It returns the two merged cluster IDs, merge distances, and
cluster sizes for each of `N-1` deterministic merges. `CutHierarchy` converts
that tree to exactly the requested number of flat clusters. The portable
baseline stores pairwise distances and is intended for in-memory data; its
worst-case merge search is cubic in the row count.

Choose a forest entry point by target:

| Target | Train | Predict | OOB metric |
| --- | --- | --- | --- |
| Non-negative integer class | `FitClassificationForest` | `PredictForestClasses` | accuracy |
| Finite real value | `FitRegressionForest` | `PredictForestValues` | R-squared |

Forests use a caller-selected seed, bootstrap rows, and a deterministic
feature-subset/split rule. `TDecisionForest.FeatureImportances` contains
normalized total impurity reduction and `OOBScore` uses only rows that received
at least one out-of-bag prediction. For a small tree count, not every row is
guaranteed an OOB prediction. Impurity importance can favour continuous or
high-cardinality inputs and is not a causal measure. Models own all tree
nodes and do not retain the training matrix.

The inspectable tree layout uses `TForestTask`, `TDecisionTreeNode`,
`TDecisionTreeNodes`, `TDecisionTreeModel`, and `TDecisionTrees`; nodes record
their split feature/threshold, child indexes, leaf flag, and prediction.

All typed-analysis additions reject nil/empty, non-finite, or shape-inconsistent
input with `EAnalysisError`. They are dense, serial, in-memory baselines.
Multiclass LDA, gradient boosting, survival forests, factor analysis, and
distributed training are not part of 1.8.

---

## Quick Start

```pascal
uses MathBase.SharedTypes, MLLib.MachineLearning;

var
  X: TDoubleMatrix;
  Y: TDoubleArray;
  Model: TLinearModel;
begin
  X := TDoubleMatrix.Create(
    TDoubleArray.Create(0),
    TDoubleArray.Create(1),
    TDoubleArray.Create(2));
  Y := TDoubleArray.Create(1, 3, 5);
  Model := TMLKit.LinearRegression(X, Y);
  WriteLn('y = ', Model.Intercept:0:1, ' + ',
    Model.Coefficients[0]:0:1, '*x');
end.
```

Expected output:

```text
y = 1.0 + 2.0*x
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

### Partial least-squares regression

Use `MLLib.PLS.TPLSKit.Fit` when predictor columns carry overlapping
information and ordinary least squares is sensitive to their collinearity.
This focused PLS1 workflow models one continuous response, standardizes
predictors by default, and selects the component count by deterministic
cross-validation:

```pascal
uses MathBase.SharedTypes, MLLib.MachineLearning, MLLib.PLS;

var
  X, NewRows: TDoubleMatrix;
  Y, Predicted: TDoubleArray;
  Model: TPLSModel;
begin
  X := TDoubleMatrix.Create(
    TDoubleArray.Create(0.0, 0.0),
    TDoubleArray.Create(1.0, 2.0),
    TDoubleArray.Create(2.0, 4.0),
    TDoubleArray.Create(3.0, 6.0),
    TDoubleArray.Create(4.0, 8.0),
    TDoubleArray.Create(5.0, 10.0));
  Y := TDoubleArray.Create(1.0, 3.0, 5.0, 7.0, 9.0, 11.0);
  Model := TPLSKit.Fit(X, Y);
  NewRows := TDoubleMatrix.Create(TDoubleArray.Create(6.0, 12.0));
  Predicted := TPLSKit.Predict(Model, NewRows);
  WriteLn('components selected: ', Model.SelectedComponents);
  WriteLn('prediction: ', Predicted[0]:0:1);
end;
```

`RMSECV[0]` is the fold-training-mean baseline; index `k` reports pooled
root-mean-square prediction error with `k` components. The selected model uses
the smallest component count attaining the lowest RMSECV. The default uses
five folds (or `N-1` when there are fewer than six observations) and seed
1729. Each fold learns preprocessing from its training rows only. Random
folds assume exchangeable observations; they do not account for time or group
dependencies.

For repeated measurements from the same subject or device, use
`TAnalysisKit.GroupKFoldSplits(Groups, FoldCount, Seed)` and pass the returned
`TValidationSplits` to `TPLSKit.Fit(X, Y, Splits)`. Each group is held out as a
whole. A separate outer test group must be removed from `X` and `Y` before
component selection; the overload fits its final model on all rows supplied
to it. Use `ValidateSplit` for caller-authored train/validation row sets.
`StratifiedKFoldSplits` balances integer class labels for classification
workflows and requires at least one row per class in every fold. These APIs use
zero-based row indices and local random state.

With supplied splits, `RMSECV` pools every scored validation occurrence, even
if a row appears in multiple validation sets. `FoldRMSECV` and
`FoldSampleCounts` report each split; `CrossValidationSampleCount` is their
sum. `CrossValidationSeed` is zero because no fold seed was generated by PLS.
The existing default Fit overload and its seeded result remain available.
See [example 47](../../../examples/47_grouped_model_validation.pas) for an
outer group holdout with PLS and ordinary least squares evaluated on the same
rows.

For observations already ordered in time, `ExpandingWindowSplits(N,
MinimumTrainingRows, ValidationRows, StepRows, GapRows)` grows training from
row zero; `RollingWindowSplits` keeps a fixed training width. Gap defaults to
zero. All sizes measure rows, not elapsed time. Training ends before the gap
and the next validation horizon. Only complete horizons are returned; invalid
or insufficient histories raise `EAnalysisError`. A positive step smaller than
the horizon deliberately scores some rows more than once. PLS pools those
occurrences using the same supplied-split rule above. PLS needs at least two
windows with at least two training rows in each, although the split builders
also support a single window and one-row training sets for other consumers.

Each PLS window learns its own preprocessing from its training rows. The final
model still fits every row supplied to Fit: keep an untouched future holdout
outside those rows. [Example 48](../../../examples/48_chronological_validation.pas)
demonstrates expanding windows with a one-row gap, deterministic replay, and
future evaluation. A row gap alone does not eliminate all temporal leakage;
choose windows to match how observations and features will be available.

Constant predictors remain in the coefficient vector with coefficient zero
and do not count toward numerical rank. Collinear columns reduce the measured
rank; the default component cap follows that rank. A requested cap above rank
raises `EPLSError`. Non-finite and missing values are rejected before fitting.
A constant response yields a valid mean-only model. Multi-response PLS,
imputation, robust fitting, and confidence intervals are outside this release.
See [example 45](../../../examples/45_partial_least_squares.pas) for a complete
correlated-predictor workflow and [ADR 0003](../../decisions/0003-pls-regression.md)
for the API and numerical choices.

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

## Common mistakes

- **Fit standardisation on training data only.** `FitStandardization` must run
  on training rows; apply the returned model to training, validation, and test
  sets to avoid leakage.
- **Importance is not causality.** Forest `FeatureImportances` is impurity
  based and can favour continuous or high-cardinality inputs; it is not a
  causal measure.
- **OOB needs enough trees.** `OOBScore` uses only rows with an out-of-bag
  prediction; for a small tree count not every row is guaranteed one.
- **Dense in-memory baselines.** The typed-analysis APIs are dense, serial,
  in-memory paths; multiclass LDA, boosting, and distributed training are
  outside 1.8.

## Portable PLS prediction

`TPLSKit.ToPredictionModel(Fit)` validates the fitted metadata and returns an
owned `TPLSPredictionModel` with original-unit coefficients and intercept.
Its `Predict` overload consumes original-unit columns in fitted order;
training centering/scaling is already included. Optional
[prediction persistence](interchange.md#selected-model-persistence) saves
this record for a separate consumer without training scores or rows.
