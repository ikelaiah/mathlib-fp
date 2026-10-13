# ADR-0001: Use second-order sections for designed IIR filters

## Status

Accepted

## Date

2026-10-13

## Context

The DSP unit already supports a streaming biquad, but it cannot provide a
portable design and streaming workflow for higher-order IIR filters. Expanding
the denominator into one polynomial makes higher-order filters increasingly
sensitive to coefficient rounding. The library also requires finite-input
validation, stable ownership, and testable numerical diagnostics without a
third-party runtime dependency.

## Decision

Design Butterworth and Chebyshev Type I filters from analog poles and zeros,
prewarp digital edges, apply the bilinear transform, and return real cascades
of normalized second-order sections. Pair conjugate roots deterministically;
keep first-order sections for an unmatched real root. Provide complex response
and strict pole-stability diagnostics over those sections.

Apply the cascade with a value-record streaming filter that snapshots its
coefficients, owns transposed-direct-form-II state, and commits state only
after a complete block succeeds. Limit prototype order to 12 and keep the
interface in `EngineeringLib.DSP`; preserve the existing biquad API.

## Alternatives considered

### One high-order numerator and denominator

Rejected because polynomial expansion loses the numerical conditioning and
section-level stability benefits that motivate the filter design.

### Third-party DSP backend

Rejected because the stable library must remain source-based Free Pascal with
no third-party runtime dependency.

### Generic plotting or charting surface

Deferred because filtering, response inspection, and state replay are the
numerical workflow; a plotting API would add a separate, broad interface with
no need in this release.

## Consequences

- Callers can inspect response and stability before processing a signal.
- Section arrays and streaming snapshots have explicit copy and ownership
  behavior.
- The feature remains real-double and serial; automatic order selection,
  zero-phase filtering, SIMD, and additional filter families remain outside
  the API.
- Independent decimal coefficient and response fixtures are maintained with
  the implementation.

See the [v2.6.0 specification](../../tasks/spec-2.6.md) for the full public
contract.
