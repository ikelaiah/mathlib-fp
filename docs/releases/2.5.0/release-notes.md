# mathlib-fp 2.5.0 (candidate notes)

**Status:** Draft for release qualification. Not published.

## Added

- Reusable double-complex FFT plans with radix-2 and cached Bluestein paths,
  prepared destinations, normalization choices, and workspace diagnostics.
- Reusable real-double STFT analysis and synthesis plans with full spectra,
  explicit padding metadata, conditioned weighted overlap-add reconstruction,
  and safe conjugate-bin editing.
- A complete public-API example that repeatedly analyzes a signal, edits a
  conjugate pair, reconstructs the original sample range, and reports residuals.

## Compatibility

Existing FFT, STFT, PSD, filter, and normalization APIs retain their prior
signatures and conventions. The legacy STFT continues to return complete
frames only. The new plan uses a separate padded geometry and must be paired
with its matching synthesis plan.
