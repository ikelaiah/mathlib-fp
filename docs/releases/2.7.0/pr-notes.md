# v2.7.0 review notes

The [Statistics II contract](../../../tasks/spec-2.7.md) adds a focused
`StatsLib.GLM` workflow for Bernoulli logit and Poisson log regression.
It uses normalized pivoted-QR IRLS, checks deviance before accepting steps,
and requires a small unhalved correction before convergence. Results expose
rank/conditioning, separation/boundary and iteration/numerical failures.
Standard errors come from the final information and failed fits withhold
inference/prediction. Existing inference signatures remain unchanged.

Six independent 90-digit reference fits and 13 focused tests cover coefficients,
means, standard errors, residuals, statuses, scaling and ownership. The example
demonstrates fitting, diagnostics, count prediction and separation handling.
Current API and user docs cover every new public type and operation. The
shared QR has quadratic-in-observations workspace; this is a dense moderate
data baseline with no scalability or speed claim.

The release title is `mathlib-fp 2.7.0`. Its body is extracted from this
version's changelog entries beginning at `### Added`; the title is excluded.
