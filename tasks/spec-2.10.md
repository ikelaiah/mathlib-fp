# v2.10.0 validation specification

## Outcome

Let callers evaluate PLS and other models on explicit, reproducible row sets,
including grouped observations. Existing random holdout, K-fold assignment,
and PLS default results remain source and behavior compatible.

## Public contract

`MLLib.Analysis.TValidationSplit` continues to own integer, zero-based
`TrainingRows` and `ValidationRows`. Add `TValidationSplits = array of
TValidationSplit` and `TAnalysisKit.ValidateSplit`, `GroupKFoldSplits`, and
`StratifiedKFoldSplits`. All arrays returned are newly allocated. Record
assignment in ordinary Pascal aliases dynamic-array storage; documented
callers should not mutate a split during a fit. The PLS overload reads all row
sets during the call and retains none of them.

`ValidateSplit(SampleCount, Split)` requires SampleCount in
`[2, High(Integer)]` because row indices are `Integer`, nonempty train
and validation, row indices in [0, SampleCount), no duplicates within or across
the two sets. It does not require exhaustive coverage; this is essential for
time-based validation and outer test rows. A collection requires at least two
splits, with at least two training rows and one validation row per split for
PLS. Rows can be validation rows in multiple splits; pooled RMSE counts every
scored occurrence, and per-split RMSE and sample counts are returned.

`GroupKFoldSplits(Groups, FoldCount, Seed)` requires at least two groups and
FoldCount between 2 and group count. Groups are integer IDs; a whole group is
assigned to one validation fold and to the training rows of all other folds.
Use local seeded random state only. Assign groups largest first to the fold
with the fewest rows; randomized ordering resolves equal-size ties. All rows
appear in validation exactly once; each split is nonempty and disjoint.

`StratifiedKFoldSplits(Labels, FoldCount, Seed)` requires FoldCount >= 2 and
at least FoldCount members of every observed integer class. Shuffle within each
class with local seeded state and distribute round-robin with a rotating fold
start to avoid empty folds. Each sample appears in validation exactly once.
This initial API does not optimize class balance across groups or weighted
labels. Error out on insufficient class size rather than silently changing the
number of folds.

Add `TPLSKit.Fit(X, Y, Splits, Options)` and a defaults overload. Each split
fits preprocessing from training rows only. Effective maximum components is
the minimum supported across all splits and the full fit. Candidate RMSE is
pooled by scored row occurrence; ties choose fewer components. Return
per-split RMSE and scored row counts, plus pooled count. The final model fits
all supplied X/Y after selection. To preserve an untouched outer test, callers
pass only outer-training rows into Fit. Supplied splits have no generated seed:
the existing CrossValidationSeed field is zero for this overload.

Reject invalid row sets before any PLS fitting. Retain existing PLS fit and
prediction behavior, default fold generator, and public result fields. On
the new overload, existing `RMSECV` is pooled RMSE and `CrossValidationFolds`
is supplied split count.

## Evidence and verification

- Hand-enumerated group and class fixtures verify every row assignment,
  disjointness, determinism, and global RNG isolation.
- PLS fixtures compare supplied splits against manual training-only fits and
  check pooled versus per-split error with unequal/overlapping validation sizes.
- Existing TestPLS and TestAnalysis tests must retain their expected results.
- A grouped correlated-predictor example creates an outer group holdout,
  selects components using remaining groups, and evaluates the untouched group.
- Run focused tests, full normal/optimized/checked suites, all examples, docs
  and package checks, then complete clean-archive release qualification.

Methodological reference: [scikit-learn cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html).
The implementation is native Pascal with no runtime dependency on that tool.
