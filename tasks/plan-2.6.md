# Implementation plan: v2.6.0 stable SOS IIR filtering

**Objective:** Deliver the complete real-double SOS IIR design, response,
stability, and streaming workflow defined in [spec-2.6.md](spec-2.6.md).
Acceptance is tracked in [todo-2.6.md](todo-2.6.md).

## Decisions

- Extend `EngineeringLib.DSP` around its existing `TBiquadCoefficients`,
  `TStreamingBiquad`, and DSP error conventions.
- Keep one generic streaming record for designed or caller-supplied SOS
  coefficients, and separate designer overloads for one-edge and two-edge
  responses.
- Use bounded real-double Butterworth/Chebyshev-I analog prototypes, root
  transformations, bilinear prewarping, and deterministic SOS pairing.
- Make state snapshots explicit and copied; stage state so invalid blocks leave
  the filter reusable and unchanged.
- Keep plotting and GUI integration outside this release and library API.
- Add high-precision or analytically independent fixtures, tests, docs, and a
  single end-to-end example before candidate release metadata.

## Dependency order

```text
spec and reference provenance
  -> public types and denominator/stability analysis
  -> Butterworth low/high and band root transforms
  -> Chebyshev-I prototypes and ripple normalization
  -> SOS complex response and independent references
  -> streaming state, atomic blocks, restore/reset
  -> end-to-end example and user docs
  -> API/capability/numerical evidence and candidate metadata
  -> local/cross-platform qualification, PR, merge, tag and publication
```

## Checkpoints

1. Stability checker and single-section response match known analytic cases;
   instability and invalid coefficients are identified without state changes.
2. All four Butterworth and Chebyshev-I response families satisfy independent
   edge/response fixtures and every designed section passes strict stability.
3. Block streaming matches one-shot execution; state restore, reset, copy,
   rejection, and numerical-overflow recovery are qualified.
4. Example output, generated API snapshot, release evidence, README/package
   metadata, and docs agree on the same stable surface.
5. Full release qualification and exact-commit CI pass before merge/tag;
   published source, offline docs, checksums, and versioned site are verified.

## Risks and controls

| Risk | Control |
| --- | --- |
| Root pairing creates a complex section or poorly scaled cascade | Explicit conjugate pairing, real coefficient checks, deterministic reference corpus, and bounded order |
| Prewarping near DC/Nyquist loses representability | Strict edge validation, finite checks at every transformation, and documented numerical limits |
| Even-order Chebyshev gain shifts the ripple band | Independent prototype/ripple references at edges and passband extrema |
| Section or block failures partially advance streaming state | Private staged state with tests for late-sample overflow and recovery |
| API grows into a filter-design framework | Keep to the two committed families, four responses, finite order ceiling, and explicit overloads |
| External research package becomes a hidden dependency | Commit generated fixtures; standard-library-only normal test and release path |

No scope expansion is planned. If numerical experiments show the spec needs a
different supported order or domain, update the contract and evidence before
changing the implementation.
