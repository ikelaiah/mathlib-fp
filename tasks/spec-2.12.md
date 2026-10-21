# v2.12.0 GLM offsets and exposure

Add TGLMInputs with Offsets/Exposures dynamic double arrays and Default (nil).
New FitLogistic/FitPoisson overloads accept Inputs and optional TGLMOptions.
Existing calls delegate to empty inputs. Prediction gets an Inputs overload.

Eta = X*beta + offset + ln(exposure). Empty arrays mean zero offset/unit
exposure. Supplied arrays match design rows; offsets are finite; exposures are
positive finite and Poisson-only. Simultaneous inputs are allowed. Invalid
inputs raise EGLMError before fitting. Inputs are never mutated or retained.

Results add UsesOffsets/UsesExposure flags. New-row prediction must supply the
same input kinds, including zero/unit inputs; missing or unexpected kinds fail.
Training values are not reused. Empty new designs may use empty arrays.
Poisson predictions are expected counts; count/exposure gives a rate, retaining
any offset effect.

IRLS, deviance and information use total eta. Logistic separation certificates
use X*beta without known offsets. Null deviance fits a free intercept with the
same known inputs: Poisson uses sum(y)/sum(exp(offset)*exposure); Bernoulli solves
the monotone intercept score. Boundary null responses have zero null deviance.
Empty inputs retain the existing null calculation and numerical behavior.

Tests use analytic likelihood equations and 80-digit Python Decimal references
for unequal exposure, null deviance and information, combined inputs, logistic
offsets that cannot separate, zero/unit equivalence, new-row inputs, ownership,
dimensions/domains and numerical failure. Existing GLM references must pass.

Reference: [statsmodels GLM](https://www.statsmodels.org/stable/generated/statsmodels.genmod.generalized_linear_model.GLM.html),
reviewed 2026-10-22. No external runtime. Frequency weights, other links/families,
regularization and robust covariance remain deferred.
