# mathlib-fp 1.9.9 workflow qualification

Version 1.9.9 adds no new representative workflow. The three 1.9.8 workflows
remain the maintained multi-domain applications and are re-qualified in every
1.9.9 gate:

- [`examples/24_sensor_pipeline.pas`](../examples/24_sensor_pipeline.pas)
- [`examples/25_numerical_modelling_optimisation.pas`](../examples/25_numerical_modelling_optimisation.pas)
- [`examples/26_probability_finance.pas`](../examples/26_probability_finance.pas)

## What runs for 1.9.9

- The unchanged [`workflow-qualification-1.9.8.json`](workflow-qualification-1.9.8.json)
  contract and `tools/check_workflow_qualification.py` checker run in ordinary
  CI and clean-archive release qualification, exactly as for 1.9.8.
- The clean-archive journey re-runs the three workflows from the 1.9.9 tagged
  source with new outbound connections blocked and retains the exported
  artifacts as qualification evidence.
- The 1.9.9 convergence gate runs beside the workflow gate and adds no
  workflow change.

## Evidence status

Local Windows x86-64 workflow evidence was last recorded on 2026-08-16 in
[QUALIFICATION_1.9.8.md](QUALIFICATION_1.9.8.md). Fresh 1.9.9 Linux and
Windows clean-archive workflow runs are mandatory exact-candidate evidence;
see [QUALIFICATION_1.9.9.md](QUALIFICATION_1.9.9.md).
