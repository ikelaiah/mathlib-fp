# Performance-manifest provenance

The [2.6.0 performance manifest](performance-evidence.json) carries forward
the benchmark contracts from 2.5.1. This release makes no performance claim
for the new SOS design or streaming API; timing is not part of its acceptance
budget. The local Windows qualification passed correctness, allocation, and
storage checks. Two allocating spectral FFT timing comparisons returned the
manifest's advisory `review` status against the 2.4.0 baseline; they do not
change the carried-forward contract or represent an SOS measurement. Full
measurements are in [`performance-results.json`](performance-results.json).
