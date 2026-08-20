# mathlib-fp 1.9.8 release notes

Version 1.9.8 is the representative workflow qualification. It proves that the
separately mature domains feel like one library in applications not written to
mirror the internal architecture, and makes that evidence reproducible from
repository-owned artifacts and supported build environments. It does not add a
runtime dependency, a foreign runtime, a licence key, or a network path.

## Representative workflows

- [`examples/24_sensor_pipeline.pas`](../../../examples/24_sensor_pipeline.pas) loads a
  small bundled sensor CSV, validates it, applies FIR and Welch DSP, summarises
  it with streaming/descriptive statistics, flags anomalies and fits a trend
  with time-series analysis, rejects a non-finite reading, and exports a
  deterministic report.
- [`examples/25_numerical_modelling_optimisation.pas`](../../../examples/25_numerical_modelling_optimisation.pas)
  fits and interpolates local modelling data, solves a bracketed scalar root,
  runs unconstrained conjugate-gradient and bounded L-BFGS optimisation,
  reports a convergence failure and an invalid-input rejection, and exports.
- [`examples/26_probability_finance.pas`](../../../examples/26_probability_finance.pas)
  seeds a local generator, estimates a return distribution, runs a one-sample
  test and a CAPM-style regression, appraises a project with NPV and IRR,
  rejects an invalid probability, and exports an interpretation.

Each workflow uses multiple genuine library domains, small bundled or seeded
local data, and a meaningful diagnostic path, and produces bounded,
deterministic output. No workflow requires private conversions, undocumented
symbols, a foreign runtime, a licence key, or network access.

## Automated clean-archive qualification

`tools/check_workflow_qualification.py` validates the machine-readable
[`workflow-qualification-1.9.8.json`](../../workflow-qualification-1.9.8.json)
manifest, compiles every workflow with FPC 3.2.2, runs it twice from an
isolated work directory (copying bundled fixtures without mutating sources),
verifies success markers, diagnostics, numerical bounds, and exported
artifacts, and requires byte-identical output across the two runs. Recorded
evidence names the exact compiler and platform that ran; no untested platform
is claimed.

The checker is part of ordinary CI and clean-archive release qualification.

## Upgrade notes

- Existing 1.9 code requires no edit.
- The public 1.9 interface remains frozen; the API snapshot has no declaration
  addition, removal, or signature change.
- The new examples are documentation and qualification artifacts, not new
  public APIs.

## Qualification boundary

Local Windows x86-64 FPC 3.2.2 workflow evidence is recorded in
[QUALIFICATION_1.9.8.md](qualification.md). Exact Linux and Windows
clean-archive candidate jobs remain mandatory before tagging; no local result
is generalized to a target that did not run.

## Known limitations and tested workarounds

See the [workflow qualification guide](workflow-qualification.md) for
the limitations and tested workarounds exposed by end-to-end qualification.
