# v2.6.0 workflow qualification

The runnable
[`43_sos_iir_filter.pas`](../../../examples/43_sos_iir_filter.pas) example
demonstrates a 4th-order Butterworth low-pass filter, response and stability
inspection, and processing a two-tone signal in ten streaming blocks. Its
deterministic output contract ends with `workflow: success`.

The example compiles and runs locally with Free Pascal 3.2.2 on Windows x86-64.
Its qualified output reports stable sections, `0.707107` gain at the cutoff,
four retained state values, and output amplitudes `0.699882` at 30 Hz and
`0.000363` at 300 Hz. All 44 examples and their output contracts passed in the
local release qualification.

The release workflow also passed its three deterministic cross-domain
workflows on the same Windows host. Their output and exported-artifact SHA-256
values are retained in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).
GitHub-hosted clean-archive release workflow evidence is pending publication.
