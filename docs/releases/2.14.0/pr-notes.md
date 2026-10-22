# v2.14.0 review notes

It adds portable GLM and PLS prediction artifacts with explicit input conventions and checked model schemas.

The numerical units expose owned prediction records; optional interchange
adapters store parameters without inventing a successful training report.
Existing prediction overloads delegate to the same validated arithmetic.

Five-axis review covered:

- Correctness: analytic new-row Poisson, Bernoulli and original-unit PLS
  predictions, including offsets, exposure, frequencies and mean-only PLS.
- Compatibility: additive public APIs, preserved fit validation, unchanged
  version-1 legacy kind bytes verified against independent fixed envelopes.
- Ownership and failures: projection copies arrays; loaders return fresh
  coefficients and reject incompatible conventions, corruption and nonfinite data.
- Resource use: checked vector byte arithmetic, bounded payloads before
  allocation, linear encoding and explicit stream ownership.
- Maintainability and deployment: one prediction path per family, documented
  field conventions, no numerical-to-interchange dependency, and a separately
  compiled consumer that receives artifacts and new rows only.

Supported-platform and release evidence is retained in
[qualification.md](qualification.md). No new speedup claim is made.
