# v2.14.0 numerical and performance provenance

The [numerical catalogue](numerical-evidence.json) retains prior contracts and
adds the independently derived fixtures described in the
[specification](../../../tasks/spec-2.14.md). The implementation
is original MIT-licensed Pascal with no external runtime. The
[performance contract](performance-evidence.json) retains the prior benchmark
rows; this release makes no new speedup claim.

GLM/PLS prediction artifacts are checked against analytic Poisson rate and
original-unit linear responses, including new rows after fitting. The separate
consumer receives only artifacts and new observations. Existing spline, FIR,
standardization and scalar Kalman bytes are independently generated with Python
`struct` and `zlib` and compared exactly. Malformed schemas, caps, nonfinite
values, projection failure and array ownership are explicit regression fixtures.
