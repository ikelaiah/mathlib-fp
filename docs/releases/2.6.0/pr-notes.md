# 2.6.0 release review notes

This capability release implements the bounded SOS IIR scope in
[`spec-2.6.md`](../../../tasks/spec-2.6.md). It adds public SOS coefficient,
response, stability, designer, and streaming-state APIs while preserving the
existing biquad API. Independent coefficient and complex-response fixtures,
14 focused tests, a reproducible example, and user-facing design/state
documentation accompany the implementation.

The API snapshot and capability inventory identify 2.6.0 as the current stable
surface. Numerical evidence covers all 1–12 prototype orders, both filter
families, and all four response types. Performance evidence carries forward
the benchmark contract without making a new speed claim for the feature.

The GitHub release title is `mathlib-fp 2.6.0`; its body starts with `### Added`
and contains only the version's changelog entries. The title does not appear
in the release body.
