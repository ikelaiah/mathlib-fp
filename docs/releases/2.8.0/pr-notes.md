# v2.8.0 review notes

The public surface is a focused PLS1 regression API for one continuous
response. The review covers the PLS score/rotation equations, rank tolerance,
fold-local preprocessing, deterministic seed, component cap, original-unit
mapping, constant predictors/responses, and array ownership.

Qualification evidence is recorded in
[`qualification.md`](qualification.md), the machine-readable numerical
catalogue, and the release PR once final CI completes.
