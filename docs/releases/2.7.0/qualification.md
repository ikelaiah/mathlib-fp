# v2.7.0 qualification record

The [release contract](../../../tasks/spec-2.7.md) adds canonical real-double
logistic and Poisson GLMs with explicit fit failures, final-information
standard errors, prediction and model diagnostics. Existing APIs remain
compatible. Release implementation and documentation are reviewed together.

## Current evidence

Focused GLM behavior and all 1,025 normal FPCUnit tests passed on Windows
x86-64 with FPC 3.2.2. The independent 90-digit Decimal fixtures regenerate
without external packages; the GLM example compiles and runs successfully.
Full local checked/optimized/heap-traced qualification, exact-commit hosted
CI and Linux/Windows clean-archive qualification must pass before tagging.
This record will be updated with the measured results before publication.

## Publication gates

All documentation, API/capability/numerical manifests, support policy,
package/version metadata, examples and output contracts must agree before
the tag is created. The annotated tag targets the qualified main commit.
The published release triggers immutable-tag qualification; the documentation
workflow attaches the offline HTML ZIP and SHA-256 sidecar and deploys the
versioned site. Downloaded source and documentation archives are verified
after publication. No GLM performance improvement is claimed.
