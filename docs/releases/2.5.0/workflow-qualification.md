# v2.5.0 workflow qualification

**Status:** The local Windows candidate workflow gate passed.

The public example
[`42_spectral_plan_reconstruction.pas`](../../../examples/42_spectral_plan_reconstruction.pas)
was compiled with FPC 3.2.2 on Windows x64 and completed with
`SPECTRAL_PLAN_EXAMPLE_OK`. It reports 35 frames, reconstructs all 4096 input
samples, and applies a conjugate-bin edit.

The release qualifier also ran the repository's three representative
cross-domain workflows on Windows 11 x86-64 with FPC 3.2.2. Their success
markers, standard output digests, and exported-artifact digests are recorded in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).
The complete local gate results are in
[`qualification-win64.json`](qualification-win64.json). Linux and Windows
clean-archive qualification for the exact candidate commit remains pending.
