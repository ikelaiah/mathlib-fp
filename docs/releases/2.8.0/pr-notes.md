# v2.8.0 review notes

The public surface is a focused PLS1 regression API for one continuous
response. The review covers the PLS score/rotation equations, rank tolerance,
fold-local preprocessing, deterministic seed, component cap, original-unit
mapping, constant predictors/responses, and array ownership.

Qualification evidence is recorded in
[`qualification.md`](qualification.md), the machine-readable numerical
catalogue, and [release PR #73](https://github.com/ikelaiah/mathlib-fp/pull/73).

Linux and Windows PR CI passed, including the Lazarus Win64/Win32 package
build. The Linux and Windows checksummed clean-source-archive profiles passed
in [workflow run #75](https://github.com/ikelaiah/mathlib-fp/actions/runs/38549338444).
