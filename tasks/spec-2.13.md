# v2.13.0 integer frequency-weighted GLMs

Extend TGLMInputs with FrequencyWeights: TGLMFrequencyWeights (array of QWord).
Default leaves it nil, meaning unit weights. Nonempty weights match design
rows and mean literal independent row replication; no fractional, variance,
survey or importance weights. Zero weights exclude a row from estimation and
diagnostics. All supplied design/response/offset/exposure values must still be
valid, including zero-weight rows. Inputs are neither mutated nor retained.

The positive total must not exceed GLM_MAX_FREQUENCY_COUNT = 2,147,483,647 on
every target. Check each value and total before addition/conversion; reject
wrong lengths, zero total and overflow with EGLMError. No replicated matrix is
allocated. Working storage depends on stored rows, not total frequency.

IRLS corrections, objective, final information, null-intercept fitting and
Pearson diagnostics use frequency multiplicities. DegreesOfFreedom is total
frequency minus fitted rank. Rank and separation ignore zero-weight rows.
Use the equivalent replicated-design QR cutoff after weight normalization.
Unit weights retain existing fit results within the numerical contract.

Results add FrequencyCount and DiagnosticRows. For explicitly supplied weights,
FittedMeans/ResponseResiduals/DevianceResiduals contain positive-weight stored
rows in original order, mapped by DiagnosticRows. Response residuals are y-mu;
deviance residuals are signed sqrt(frequency * unit deviance), so their squares
sum to deviance. Nil weights preserve the existing full-row arrays and leave
DiagnosticRows nil. Failed fits keep the existing inference-withholding policy.

Weights are training inputs only. PredictMean rejects nonempty FrequencyWeights
in new-row inputs and requires only the fitted offset/exposure kinds. Frequency
training does not change the inference artifact or require deployment weights.

Acceptance compares both families, offsets/exposure, standard errors, deviance,
null deviance, Pearson statistics and degrees of freedom with explicitly
replicated small datasets. Cover unit/zero weights, active rank, separation,
count overflow and a huge conceptual count with constant stored row count.
The release example demonstrates repeated-observation compression and prediction.

Reference: [statsmodels GLM frequency weights](https://www.statsmodels.org/stable/generated/statsmodels.genmod.generalized_linear_model.GLM.html).
No new families, fractional weights, grouped-binomial responses or robust covariance.
