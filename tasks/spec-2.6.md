# Spec: v2.6.0 stable SOS IIR filtering

**Status:** Scope and initial API contract finalized 13 October 2026.
Sequence: [plan](plan-2.6.md). Acceptance: [checklist](todo-2.6.md).
This specification implements the bounded [2.6.0 roadmap gate](../docs/project/roadmap.md#next-release-260--signal-processing-ii).
The public representation and streaming-state choices are recorded in
[ADR-0001](../docs/decisions/0001-stable-sos-iir-filters.md).

## Objective

Provide an end-to-end, real-double IIR filtering workflow that designs
Butterworth and Chebyshev Type I low-pass, high-pass, band-pass, and band-stop
filters as stable second-order sections, applies them to finite signals with
explicit streaming state, evaluates their complex frequency response, and
reports denominator stability. Existing `TStreamingBiquad` and
`DesignButterworthLowPass` remain source- and behavior-compatible.

## Scope and limits

- Filter prototype order is an integer from 1 through 12. Band-pass and
  band-stop designs have twice that total transfer-function order.
- Edges and sample rates are finite positive values in hertz. Single-edge
  responses require `0 < cutoff < sampleRate/2`. Band responses require
  `0 < low < high < sampleRate/2`.
- Chebyshev Type I ripple is finite and in `(0, 12]` dB. Butterworth designs
  have no ripple parameter.
- The implementation is real-double, portable serial Pascal. It does not add
  FIR design, Chebyshev Type II, elliptic/Bessel filters, automatic order
  selection, zero-phase filtering, complex-signal application, SIMD, threads,
  vendor backends, or a plotting framework.
- Design from analog prototype poles and zeros, apply the appropriate
  low-pass/high-pass/band-pass/band-stop frequency transform, prewarp digital
  edges, and map roots with the bilinear transform. Pair roots into real
  first- or second-order sections. Never expand a high-order transfer function
  into one numerator/denominator polynomial.

## Public representation and operations

Add `TIIRResponse = (irLowPass, irHighPass, irBandPass, irBandStop)` and
`TSOSCoefficients = array of TBiquadCoefficients`. The existing coefficient
record represents
`(B0 + B1 z^-1 + B2 z^-2) / (1 + A1 z^-1 + A2 z^-2)`; its denominator is
normalized to `a0 = 1`. First-order sections set `B2 = A2 = 0`.

Add four `TDSPKit` designers, overloaded by edge count:

```pascal
DesignButterworthSOS(const Response: TIIRResponse; const Order: SizeInt;
  const SampleRateHz, CutoffHz: Double): TSOSCoefficients;
DesignButterworthSOS(const Response: TIIRResponse; const Order: SizeInt;
  const SampleRateHz, LowCutoffHz, HighCutoffHz: Double): TSOSCoefficients;
DesignChebyshevISOS(const Response: TIIRResponse; const Order: SizeInt;
  const SampleRateHz, CutoffHz, PassbandRippleDb: Double): TSOSCoefficients;
DesignChebyshevISOS(const Response: TIIRResponse; const Order: SizeInt;
  const SampleRateHz, LowCutoffHz, HighCutoffHz,
  PassbandRippleDb: Double): TSOSCoefficients;
```

The single-edge overloads accept only low-pass/high-pass responses; the
two-edge overloads accept only band-pass/band-stop responses. Designers return
at least one section and assign section gains deterministically. Their
coefficients are independently owned by the caller.

Add `TStreamingSOSFilter`, a value record that snapshots its coefficients and
owns two transposed-direct-form-II delay values per section. Construction
requires a nonempty finite, stable section array. `ProcessBlock` validates the
complete finite input, computes into private staged state, and advances state
only if the complete block succeeds. It returns an independently allocated
output array. Initial state is zero; `Reset` restores zero state. `State`
returns the flattened `[z1_0,z2_0,z1_1,z2_1,...]` snapshot;
`RestoreState` requires exactly two finite values per section and copies them.
State and coefficient accessors return copies. Callers synchronize access to
one mutable record; copied records evolve independently on subsequent calls.

Add `TDSPKit.AnalyzeSOSStability`, which validates finite nonempty sections
and returns `TSOSStabilityDiagnostics` with `IsStable`, the maximum pole
radius, the minimum unit-circle margin, and the first unstable section index
(`-1` when all are stable). Stability is strict: every section's poles must
lie inside the unit circle. Use the exact second-order Jury inequalities for
normalized real denominators and a robust pole-radius calculation. Do not
silently stabilize, clip, or rewrite caller-supplied coefficients.

Add `TDSPKit.EvaluateSOSResponse`, which accepts a finite positive sample rate
and a nonempty array of finite frequencies in `[0, sampleRate/2]`. It returns
an owned copy of the frequencies and complex response values evaluated from
the cascade at `z = exp(i*2*pi*f/sampleRate)`. Validate the full request before
publishing results. A zero denominator or non-finite result raises
`EDSPError`.

## Numerical and failure contract

- Validate enum values, order, edge arity/ordering, finite positive sample
  rate, strict Nyquist bounds, ripple, section count, and all coefficients.
- Prewarp both band edges before computing analog bandwidth and center. Map
  all roots with the same bilinear scale, so every specified digital edge is
  an analog prototype edge after prewarping.
- Normalize the passband peak to unity. For Chebyshev Type I even prototype
  orders, the low-frequency prototype endpoint has the specified ripple and
  the band-center/high-pass-Nyquist references inherit that endpoint value.
- Return only finite coefficients whose sections pass the stability check.
  If finite inputs produce unrepresentable intermediate or final values, raise
  `EDSPError` with operation context. Never repair the result silently.
- `ProcessBlock` rejects NaN/infinity and arithmetic overflow before committing
  any state changes. Empty blocks return empty output and preserve state.
- A bad frequency, invalid section, response/overload mismatch, unstable section,
  or invalid state restore raises `EDSPError`; failures preserve filter state.
- Existing filter behavior and conventions remain unchanged.

## Verification and release gates

The focused FPCUnit suite must cover every family/response, odd and even
orders, reference coefficient cases, independent frequency-response values,
passband/stopband edges, stability and mutation diagnostics, first- and
second-order sections, impulse/step signals, state save/restore, chunked versus
one-shot equivalence, copied-state independence, invalid inputs, non-finite
values, overflow atomicity, and recovery after a rejected block.

Commit independent reference fixtures and provenance. Compare response
magnitude and phase across low, edge, passband, stopband, and Nyquist points;
test the designed coefficients themselves, rather than only a plotted or
sampled output. Reference generation is development-only; normal tests and
release qualification use checked-in values and require no Python numerical
package or network.

Regenerate and check the decimal coefficient corpus with
`python tools/generate_sos_iir_reference.py` and
`python tools/generate_sos_iir_reference.py --check`.

Add a deterministic example that designs one filter, checks response and
stability diagnostics, and processes one signal in multiple blocks while
reporting a final success marker. Update applied-numerics guidance, task
recipes, API snapshot, capability inventory, release notes, numerical-evidence
catalogue, package/version metadata, README, support policy, release index, and
the versioned offline documentation. Keep examples textual; the release adds
no graphing or plotting interface.

The release gate requires passing the focused and full normal, optimized,
runtime-checked, and heap-traced suites; all example, API, documentation,
capability, numerical, performance, portability, migration, and workflow
checks; the Win64 and Win32 Lazarus package consumer checks; exact-commit Linux
and Windows CI; checksummed clean-archive release qualification; and published
source/documentation archive and site verification.

## References

- SciPy documents digital Butterworth and Chebyshev Type I IIR designs and
  recommends second-order sections where a high-order polynomial is
  numerically fragile: <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.iirfilter.html>.
- The bilinear mapping and its Tustin substitution are documented at
  <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.bilinear_zpk.html>.
- The cascaded transposed-direct-form-II state convention is documented at
  <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.sosfilt.html>.
- The code is independently authored Pascal. SciPy is a development reference,
  not a runtime or build dependency.
