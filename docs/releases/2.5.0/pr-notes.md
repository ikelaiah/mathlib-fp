# 2.5.0 release review notes

The release adds fixed-geometry reusable FFT and STFT plans. The supported
scope is double-complex FFT execution and real-double padded STFT analysis and
weighted overlap-add synthesis. Existing transforms and PSD APIs remain
source-compatible.

The review surface includes the independent DFT and overlap-add fixtures with
[provenance](numerical-fixture-provenance.md), focused FPCUnit coverage, exact
allocation and retained-storage measurements, the signal-edit-reconstruction
example, current API snapshot, capability inventory, and public usage/performance
guidance.

The Windows x64 performance evidence meets its numerical, allocation, and
workspace ceilings. Its advisory comparison flags the allocating FFT path at
N=4096 and N=65536 above the 1.5 review band; the report records these measured
tradeoffs and makes no blanket speed claim. Linux and Windows clean-archive
release qualification passed. Merge, tag, publication, and archive verification
are tracked in the release checklist.
