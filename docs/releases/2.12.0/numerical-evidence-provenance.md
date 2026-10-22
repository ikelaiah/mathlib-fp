# v2.12.0 numerical and performance provenance

The [numerical catalogue](numerical-evidence.json) retains prior contracts and
adds the independently derived fixtures described in the
[specification](../../../tasks/spec-2.12.md). The implementation
is original MIT-licensed Pascal with no external runtime. The
[performance contract](performance-evidence.json) retains the prior benchmark
rows; this release makes no new speedup claim.

Regenerate the offset/exposure fixtures with
`python tools/generate_glm_offset_reference.py`. It uses only standard-library
80-digit Decimal arithmetic and writes `tests/GLMOffsetReference.inc`.
For exposure (1,2,1), design rows (1,0),(1,1),(1,2), and counts (2,8,8),
the exact coefficients are both ln(2), information is [[18,24],[24,40]],
and the null rate is 18/4. The logistic fixture has two failures at known
odds 2/3 and two successes at known odds 6; its fitted intercept is -ln(2),
means are 1/4 and 3/4, information is 3/4, and deviance is -8 ln(3/4).
These equations are independent of production IRLS and null-intercept code.
