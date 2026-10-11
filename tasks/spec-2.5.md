# Spec: v2.5.0 reusable spectral processing

**Status:** Finalized release scope and design contract, 11 October 2026.
Implementation and qualification are pending.
Sequence: [plan](plan-2.5.md). Acceptance: [checklist](todo-2.5.md).

## Objective and demonstrated workflow

A Free Pascal signal-processing consumer should prepare transforms once,
repeatedly analyze equally sized finite signals, edit conjugate frequency
bins, and reconstruct the complete original sample range with bounded memory
and visible errors. This maintainer-selected scenario extends the existing
[sensor pipeline](../examples/24_sensor_pipeline.pas).

Source review confirms that `TDSPKit.ShortTimeFourierTransform`,
`Periodogram`, `Welch`, `CrossSpectrum`, FFT normalization, rational
resampling helpers and a second-order Butterworth filter already exist.
The current STFT returns complete frames, drops a trailing partial frame,
and calls an allocating real FFT for each frame. The public DSP interface has
no inverse STFT or reusable FFT plan. This release addresses those concrete
workflow and resource boundaries; no user survey or external issue is claimed,
and allocation observations do not establish a measured speed deficit.

## Scope and non-goals

Ship double-complex reusable FFT plans and real-double STFT analysis/synthesis
plans in `EngineeringLib.DSP`, with existing shared numeric types and dense
matrix interfaces. Repeated prepared execution and inverse STFT are the
additive capabilities that justify the minor release.

Preserve existing API signatures, defaults, normalization, complete-frame
legacy STFT behavior, and current PSD conventions. Benchmark and document both
simple allocating use and repeated destination/workspace use.

Deferred: new IIR families, DCT/DST, wavelet families, resampling redesign,
new PSD estimators, single-precision plans, streaming STFT, custom windows,
half-spectrum storage, arbitrary FFT length separate from frame length,
SIMD, threads, GPU, vendor runtimes, new persistence formats, and unrelated
dense/sparse optimization. These remain candidate work, not 2.5 commitments.

## Public API contract

The following names and signatures are selected for implementation in the
existing unit; all referenced array/enumeration/interface types already exist.

```pascal
type
  TFFTPlan = class
  public
    constructor Create(const ATransformLength: SizeInt);
    destructor Destroy; override;
    function Execute(const Input: TComplexArray;
      const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward): TComplexArray;
    procedure ExecuteInto(const Input: TComplexArray;
      var Destination: TComplexArray; const Inverse: Boolean = False;
      const Normalization: TFFTNormalization = fnBackward);
    function TransformLength: SizeInt;
    function WorkspaceElements: SizeInt;
    function RetainedBytes: SizeInt;
  end;

  TSTFTPlan = class
  public
    constructor Create(const ASampleCount, AFrameLength, AHopLength: SizeInt;
      const WindowType: TWindowType = wtHann);
    destructor Destroy; override;
    function Analyze(const Input: TDoubleArray): IDenseComplexMatrix;
    procedure AnalyzeInto(const Input: TDoubleArray;
      const Destination: IDenseComplexMatrix);
    function Synthesize(const Spectrum: IDenseComplexMatrix): TDoubleArray;
    procedure SynthesizeInto(const Spectrum: IDenseComplexMatrix;
      var Destination: TDoubleArray);
    function SampleCount: SizeInt;
    function FrameLength: SizeInt;
    function HopLength: SizeInt;
    function FrameCount: SizeInt;
    function LeftPadding: SizeInt;
    function RightPadding: SizeInt;
    function RetainedBytes: SizeInt;
  end;
```

Both classes own fixed geometry and private scratch; callers release them with
`Free` in `try/finally`. They do not retain caller inputs or destinations.
Allocating calls return independent results. Pre-sized `Into` calls never
resize or detach destinations. Output array assignments follow Pascal's normal
shared-array semantics; callers copy results when independent copies are needed.

A plan snapshots/generated-copies its window and never exposes internal arrays.
Separate plans can run concurrently. A busy guard rejects overlapping or
reentrant execution on one plan with `EDSPError`, and is released after any
failure. Callers must not destroy a plan or concurrently mutate its
inputs/destinations during use. Operations are synchronous and bounded by
fixed geometry; cancellation is supported between calls, not during a call.

## FFT numerical and resource contract

- `TransformLength >= 1`; input and prepared destination must have exactly
  that length. All input components must be finite. Invalid enum values,
  dimensions and checked-size overflow raise `EDSPError`.
- Forward sign is `exp(-2*pi*i*k*n/N)`. Preserve the existing four
  normalization rules: backward (inverse divided by N), forward (forward
  divided by N), unitary (both divided by sqrt(N)), none (neither).
- Use radix-2 for powers of two. Prepare bit-reversal/twiddle data and scratch
  once. For other lengths use Bluestein with
  `M = nextPowerOfTwo(2*N - 1)`, caching chirps, kernel spectrum, radix-2
  preparation and convolution scratch. Check element and byte arithmetic
  before allocating; construction must not expose a partially built plan.
- Exact input/destination identity is supported by staging input before output
  writes. Distinct arrays are accepted; unsafe pointer-forged partial overlaps
  are outside the public dynamic-array contract.
- Prepare all numeric scratch at construction. Valid warm `ExecuteInto`
  calls make zero heap allocation/reallocation calls. Allocating `Execute`
  allocates its result and uses the same prepared computation.
- `WorkspaceElements` counts complex scratch slots, excluding cached tables,
  indices and caller outputs. `RetainedBytes` is the sum of owned numeric
  array payload bytes, including tables/indices; it excludes object headers,
  allocator overhead and caller results. Publish exact per-array accounting.
- Payload ceiling for radix-2 is `64*N + 2*SizeOf(SizeInt)*N` bytes.
  For Bluestein it is `16*(6*M + 4*N) + SizeOf(SizeInt)*(M + N)`.
  These are storage gates, not claimed physical heap usage.

## STFT geometry, scaling and synthesis

Construction fixes sample count S >= 1, frame length N in
`[2, High(Integer)]`, hop H in `[1,N]`, and an existing valid window enum.
Generate the existing symmetric window via `TSignalKit.GenerateWindow`:
do not substitute a periodic Hann window silently.

Use left padding `L=N-1`, frame count
`F=1+ceil((S+N-2)/H)`, padded length `P=N+(F-1)*H`, and right padding
`R=P-L-S`. Compute all sizes with checked integer arithmetic, including
`F*N` and byte sizes. A frame at row r starts at original sample
`r*H-L`; positions outside `[0,S)` are zero. Short signals are supported.

Analysis returns F rows by N columns containing full, unshifted complex bins,
with an unscaled forward FFT. No sample-rate or PSD normalization is applied.
For a chosen finite positive rate Fs, bin k has the usual unshifted DFT
frequency, with negative frequencies in the upper bins. This matrix is not a
PSD; existing periodogram/Welch APIs keep that role.

Inverse frames use backward normalization (IFFT divided by N), multiplication
by the same analysis window, overlap-add, and division by the sum of squared
overlapping window samples. Trim exactly L samples on the left and retain S
samples. This follows the weighted overlap-add/NOLA construction described
in the [SciPy STFT documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html).
The implementation is independently authored Pascal; SciPy is not a runtime
dependency and its default scaling/window conventions are not copied.

Precompute retained-sample denominators d[j]. Construction requires finite
positive dmax and `min(d) > 1e-12*dmax`; reject all-zero windows, uncovered
samples and poorly conditioned coverage with `EDSPError`. This explicit
conditioning threshold is stronger than mathematical nonzero coverage.

Synthesis requires the exact F-by-N shape and finite full spectra. Per frame,
with `scale=max(1,max(abs(bin)))`, require conjugate-pair residuals and DC
imaginary magnitude <= `1e-11*scale`; check Nyquist likewise for even N.
Reject spectra that fail this real-signal contract. Qualified symmetric edits
are supported, but arbitrary inconsistent spectra have no promised inverse
identity or optimal-estimation interpretation.

AnalyzeInto accepts an assigned built-in dense matrix or writable strided
view of exact shape. SynthesizeInto requires an S-element destination.
Do not resize either. Allocate frame FFT, staging matrix, padded accumulator
and denominator buffers at construction. Valid warm analysis/synthesis calls
allocate nothing. Retained numeric bytes must be no more than the nested
FFT plan's retained bytes plus `16*F*N + 8*(2*P + 3*N + S)`; publish actual
counts and the extra staging-matrix cost.

## Errors, atomicity and compatibility

Validate complete inputs and compute/check finite results in private staging
before publishing any destination. Invalid input, coverage, spectrum symmetry,
busy-plan or arithmetic failure leaves destinations unchanged and the plan
reusable. Normalize floating-point overflow/invalid-operation failures to
`EDSPError` with operation context, following existing DSP error conventions.
Allocation failures during construction/allocating convenience calls may
propagate `EOutOfMemory` and must release partial internal state.

Matrix writes may change aliases of the caller's destination as normal for
shared storage; matrix views must leave elements outside the view unchanged.
Atomicity covers built-in matrix implementations; throwing third-party
interface setters and unsafe pointer-forged aliases are not supported.

Existing STFT outputs cannot be passed to the new synthesis merely by shape
coincidence: the new plan uses padded framing. Document the complete pair,
padding metadata and exact window/hop requirements together.

## Numerical evidence and budgets

Use FPCUnit focused tests plus committed independent values. Reference
generation uses a high-precision direct DFT and explicit overlap-add formulas;
record precision/tool versions/window samples and generation procedure.
Normal tests use committed data only and require no network/Python numerics.

For the qualified corpus require
`max(abs(actual-reference))/max(1,max(abs(reference))) <= 5e-11`
for FFT outputs and reconstruction. This is a corpus budget with an absolute
floor, not a universal relative bound for every finite Double.

Include lengths 1, 2, 3, 7, 8, 31, 64, 1009 and 65536; forward/inverse and all
normalizations; zeros, impulses, tones, deterministic random data and ordinary
amplitudes from 1e-6 through 1e6. Large tests use round-trip/property checks
rather than cubic reference work.

STFT fixtures include frames 16, 63, 64, 257; non-divisible tails, signals
shorter than a frame, all supported windows, valid and invalid hops, first/last
impulses and conjugate-bin edits. Verify exact geometry, Parseval for unitary
FFT, scaling/conjugation, independent results, plan reuse after errors,
non-finite/overflow cases, matrix views, busy guards and zero leaks.
Fault injection must detect wrong normalization, dropped boundary samples,
broken Hermitian checks and unexpected warm allocations.

## Performance evidence and completion gates

Record unmodified v2.4.0 baselines before changes, then exact candidate commit,
compiler/configuration, OS/CPU, warm-up, repetitions and setup. Measure
construction separately from warm calls and output allocation separately from
prepared execution. FFT rows cover N=64,4096,65536 and Bluestein N=1009,10007.
STFT rows cover S=65536 with N/H=256/128 and 255/85, including synthesis.

For legacy STFT comparisons use equivalent complete frames and normalization;
report new padded-tail work separately. Do not compare different output
coverage as if it were identical work. Keep existing canonical benchmark
gates and add exact numerical/allocation/workspace gates for the plans.
Memory-manager counters must measure allocation/reallocation calls rather
than infer their absence from retained heap deltas.

Zero allocations and resource ceilings are release gates. Timing is reviewed
across repeated matching-host runs; report regressions and workload limits.
A performance headline requires repeatable evidence; no blanket speedup
percentage or universal advantage over competitors is promised.

Success requires the complete spectral-edit-reconstruction example, numerical
and performance evidence, API/capability docs, all applicable local gates and
Linux/Windows exact-commit clean-archive CI under RELEASING.md.

## Stack, layout and style

Use FPC 3.2.2-compatible objfpc/advanced-record conventions, existing numeric
types, two-space Pascal indentation, descriptive operation errors and
comments explaining numerical safeguards/provenance. Source goes in
`src/EngineeringLib.DSP.pas`; focused tests/runner/fixtures go in `tests/`;
reference tools in `tools/`; user docs in the applied-numerics/performance
guides; workflow examples in `examples/`; qualification in
`docs/releases/2.5.0/`. Existing release manifests remain historical evidence.

Always validate inputs, preserve public compatibility, include meaningful
tests/docs with behavioral slices, and retain correctness gates. Scope/API
changes require an updated spec and review. New dependencies, support claims
and publication must follow the existing repository policies and authorization.
Never weaken numerical budgets to justify speed or claim unexecuted targets.

## Executable verification commands

From the repository root on Windows, after the focused runner exists:

```powershell
New-Item -ItemType Directory -Force build-temp/spectral-plans | Out-Null
fpc -B -FcUTF8 -Fusrc -Futests -FUbuild-temp/spectral-plans -FEbuild-temp/spectral-plans tests/SpectralPlanRunner.lpr
& .\build-temp\spectral-plans\SpectralPlanRunner.exe -a --format=plain
python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc --work-dir build-temp/performance-2.5
python tools/check_docs.py
.\build-examples.ps1
python tools/check_example_output.py
```

Before candidate version changes, full preflight uses the actual current
version (`--release 2.4.0`) and is not labeled 2.5 release qualification.
After candidate metadata is reconciled:

```text
python tools/update_api_snapshot.py --release 2.5.0
python tools/check_docs.py
python tools/qualify_release.py --release 2.5.0 --compiler fpc --lazbuild lazbuild --work-dir build-temp/qualification-2.5 --result build-temp/qualification-2.5/results.json
python tools/build_docs.py --release 2.5.0 --output build-temp/docs-site/2.5.0 --offline-archive build-temp/mathlib-fp-docs-2.5.0.zip
python tools/check_built_docs.py --site build-temp/docs-site/2.5.0 --release 2.5.0
git diff --check
```

The qualifier owns required normal/optimized/checked/heap configurations,
examples, package consumer and existing release gates. Run the Linux/Windows
release workflow for clean-archive qualification; network-isolated assertions
are used only where the workflow actually blocks outbound connections.

## Algorithm provenance and rejected alternatives

Bluestein: [L. I. Bluestein (1970), A linear filtering approach to the
computation of discrete Fourier transform](https://doi.org/10.1109/TAU.1970.1162132).
Use the repository's existing radix-2/Bluestein derivations as the starting
point and write prepared kernels in-tree. Mathematical references and
independently authored fixtures are recorded in the provenance evidence.

Creating STFT/Welch again was rejected because those APIs already ship.
A performance-only internal pass was rejected as the entire minor scope;
prepared execution and inverse STFT provide actual additive workflows.
Generic multi-domain acceleration, vendor-only numerical paths and immediate
SIMD/threaded APIs are deferred until profiling demonstrates their need.
