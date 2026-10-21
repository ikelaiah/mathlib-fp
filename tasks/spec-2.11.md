# v2.11.0 chronological validation specification

Add `TAnalysisKit.ExpandingWindowSplits` and `RollingWindowSplits` returning
the existing zero-based `TValidationSplits`. Parameters are sample count,
minimum/fixed training row count, validation horizon, step, and optional gap
(zero by default), all measured in rows. Callers supply chronologically ordered
observations; these helpers neither sort timestamps nor infer durations.

Sample count is in `[2, High(Integer)]`; training count, horizon and step are
positive and gap is nonnegative. At least one complete training/gap/validation
window must fit. Reject invalid geometry with `EAnalysisError` before building
rows. Partial final horizons are omitted. There is no random state.

For window k, validation starts at `TrainingCount + Gap + k * Step`. Its
training end is `ValidationStart - Gap - 1`. Expanding training starts at zero;
rolling training has exactly TrainingCount rows ending there. Gap rows belong
to neither set. Every training index precedes every validation index. Returned
arrays own new storage; practical output size is bounded by available address
space and memory, with O(total returned row indices) time and storage.

Horizons may overlap when step is less than horizon. PLS supplied-split scoring
counts every validation occurrence, as established in v2.10.0. PLS requires at
least two splits and at least two training rows per split; a valid one-window
splitter result remains useful to other consumers. Fitting PLS on the returned
splits learns preprocessing inside each training window, then fits the final
model on all rows supplied to Fit. An unbiased future holdout therefore stays
outside those supplied rows.

Acceptance uses hand-enumerated expanding/rolling/gap fixtures, overlapping
horizons, invalid and insufficient histories, deterministic replay, and an
analytic future-holdout PLS workflow. Existing seeded results remain unchanged.
This adds evaluation tools, not forecasting estimators, and a row gap alone
does not establish independence or eliminate every source of leakage.

Reference: [scikit-learn time-series cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html#time-series-split).
