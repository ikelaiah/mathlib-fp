# v2.14.0 GLM/PLS prediction persistence

Introduce TGLMPredictionModel and TPLSPredictionModel in their numerical units,
with ToPredictionModel(Fit) and prediction overloads. GLM records contain family,
coefficients and required offset/exposure kinds; PLS records contain original-unit
coefficients and intercept. Projection validates the existing fit contract and
deep-copies coefficients. Prediction shares the canonical numerical path. Full
training results and legacy prediction validation remain available.

Add SaveGLMPrediction/LoadGLMPrediction and SavePLSPrediction/LoadPLSPrediction
to optional InterchangeLib.Models. Load returns inference records, never a
fabricated successful training report. No training rows, CV scores, standard
errors, frequencies, callbacks or executable objects are stored. GLM columns
stay in fitted order with explicit design/intercept convention; new rows supply
the recorded offset/exposure kinds. PLS coefficients already include training
centering/scaling and must be applied exactly once to original-unit predictors.

Retain the MFP model envelope version 1 and legacy kind codes 1–4. Add kinds 5
(GLM prediction) and 6 (PLS prediction). Envelopes are little-endian, length- and
CRC32-checked. New payload headers specify binary64 encoding, family/link,
intercept, preprocessing and indexed-column order conventions, with reserved
bytes checked. Reject unknown versions/codes/flags, nonfinite values, empty or
inconsistent dimensions, truncation, checksum and trailing-payload errors.

Loaders accept the existing default MaxElements cap and check positive limits,
byte arithmetic and Integer-indexed payload capacity before reading/allocating.
New payloads require at least one finite coefficient; PLS intercept is finite.
All loaded arrays own storage. Save preallocates vector payloads with checked
sizes and preserves old adapter bytes.

Acceptance: both families and weighted offset/exposure GLM fit/project/save/
reload/predict; scaled PLS and mean-only prediction without double transforms;
ownership and malformed artifacts; independent fixed legacy spline/FIR/
standardizer/scalar-Kalman envelope fixtures. A separate clean-archive consumer
loads only artifacts and new rows, with no training data or fitting calls.
The release qualification driver compiles and runs that consumer.

The [format decision](../docs/decisions/0004-prediction-model-persistence.md)
records exact payload fields. No general object serializer or training-report
format is added.
