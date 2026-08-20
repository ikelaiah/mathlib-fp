# Numerical interchange and inspection

`MathBase.Interchange` is an optional unit for invariant text, delimited text,
Matrix Market, versioned binary persistence, typed metadata, and concise
summaries. `InterchangeLib.Models` adds separate versioned adapters for a small
set of fitted/stateful models. Numerical core units do not depend on either
interchange unit.

Maturity: **stable for the dense and sparse real/complex, RNG-state, and
selected model formats documented here**.

## Learning routes

### Beginner route

Copy and run the [in-memory double-matrix round trip](#60-second-round-trip).
It prints `round trip value = 4.0`. Saving allocates stream payload bytes;
loading validates the complete payload before returning a new typed matrix.

### Common tasks and algorithm choice

| Task | Start with | Contract or failure guidance |
| --- | --- | --- |
| Human-readable vector/matrix text | invariant or delimited helpers | [Choose a format](#choose-a-format) |
| Exchange with numerical tools | Matrix Market | [Text forms](#text-forms) |
| Exact typed numerical round trip | binary save/load pair | [Binary format](#binary-format-version-1) |
| Reproducible RNG replay | random-state binary pair | [Binary format](#binary-format-version-1) |
| Selected fitted model | `InterchangeLib.Models` pair | [Model persistence](#selected-model-persistence) |

### Advanced route

Run [example 20](../../../examples/20_interchange_replay.pas) for matrix/RNG replay
and [example 22](../../../examples/22_sparse_end_to_end.pas) for Matrix Market sparse
exchange. All conversions are named, allocate independent results, and retain
the source scalar precision unless an explicitly named conversion is chosen.

## 60-second round trip

```pascal
uses
  Classes, AlgebraLib.DenseMatrices, MathBase.Interchange;

var
  Stream: TMemoryStream;
  A, B: IDenseDoubleMatrix;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [1.0, 2.0, 3.0, 4.0]);
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, A);
    Stream.Position := 0;
    B := LoadDoubleMatrixBinary(Stream);
    WriteLn('round trip value = ', B[1, 1]:0:1);
  finally
    Stream.Free;
  end;
end.
```

Expected output:

```text
round trip value = 4.0
```

See [example 20](../../../examples/20_interchange_replay.pas) for matrix and random
state replay. [Example 22](../../../examples/22_sparse_end_to_end.pas) performs a
sparse Matrix Market round trip before an iterative solve.

## Choose a format

| Need | Format/API | Important contract |
| --- | --- | --- |
| Pasteable configuration | `DoubleVectorToInvariant`, `ComplexVectorToInvariant`, `DenseMatrixToInvariant` | Locale independent; finite values only |
| Simple table interchange | `WriteDelimitedMatrix`, `ReadDelimitedMatrix` | Dense rectangular numeric rows; caller-selected delimiter |
| Other numerical tools | `WriteMatrixMarket`, `ReadMatrixMarketDouble`, `ReadMatrixMarketComplex` | Matrix Market dense `array`, `real`/`complex`, `general` subset |
| Sparse exchange with other tools | `WriteSparseMatrixMarket`, `ReadSparseMatrixMarketDouble`, `ReadSparseMatrixMarketComplex` | Matrix Market coordinate double-real/double-complex `general`; canonical entries only |
| Large exact round trip | `SaveBinary`, typed `Load...Binary` | Versioned, little-endian scalar payload and CRC-32 |
| Exact typed sparse round trip | `SaveSparseBinary`, `LoadSparseSingleBinary`, `LoadSparseDoubleBinary`, `LoadSparseSingleComplexBinary`, `LoadSparseComplexBinary` | Versioned CSR/CSC metadata, all four scalar paths, CRC-32 |
| Reproducible simulation | `SaveRandomStateBinary`, `LoadRandomStateBinary` | Exact four-word `TLocalRandom` state |
| Logging/debugging | `Summarize` | Shape/type metadata plus bounded values |
| Programmatic inspection | `Describe` | `TValueMetadata` kind, scalar type, shape, and element count |
| Selected fitted/stateful models | `InterchangeLib.Models` | Separate model magic/version/kind, resource cap, and CRC-32 |

Delimited input is the numeric rectangular subset: it does not interpret
headers, dates, categories, missing fields, or quoted embedded delimiters.
Dense Matrix Market uses array real/complex general. Sparse Matrix Market uses
coordinate real/complex general, one-based file coordinates, and rejects
duplicates and explicit stored zeros. Pattern, integer, symmetric, Hermitian,
and skew-symmetric variants are rejected. Metadata uses the public
`TInterchangeValueKind` and `TInterchangeScalarType` enums.

## Binary format version 1

Every object starts with:

- eight-byte magic `MFPBIN1` plus a zero byte;
- little-endian unsigned 16-bit format version;
- scalar/storage kind and one reserved byte;
- little-endian unsigned 64-bit rows, columns, and payload byte count;
- little-endian CRC-32 of the payload; and
- row-major IEEE binary64 real values, interleaved real/imaginary binary64
  values, four unsigned 64-bit RNG state words, or a sparse payload.

A sparse payload contains format and stored-zero-policy tags, checked
`SizeInt` shape/nonzero metadata encoded as little-endian 64-bit integers,
the complete outer-pointer and inner-index arrays, then IEEE binary32/binary64
real or interleaved complex values matching the kind tag. Readers validate the
CSR/CSC canonical invariants after checksum validation and before returning an
interface.

The format is endian-defined and does not write Pascal record memory layouts.
It therefore avoids ABI padding and host-endian ambiguity.

Loaders validate magic, version, kind, dimension products, platform address
limits, caller element/nonzero and sparse dimension limits, payload byte count,
truncation, checksum, and finite scalar values. Sparse loaders additionally validate
format, zero policy, outer terminal/counts, sorted in-range indices, duplicate
absence, and policy-compatible zeros. Only after those checks does a loader
return a new array/matrix/state. There is no destination to partially mutate.

`DEFAULT_MAX_INTERCHANGE_ELEMENTS` and `DEFAULT_MAX_SPARSE_DIMENSION` are both
16,000,000. Dense loaders apply the element limit to the total scalar count.
Sparse loaders apply the nonzero limit to the stored nonzero count and apply the
dimension limit independently to each axis before allocating outer-pointer
arrays, reading payloads, or constructing builders. Pass a smaller limit when
processing untrusted input with a known expected shape. A larger caller limit
does not bypass `SizeInt`, byte-count, or address-space checks.

## Text forms

- Complex scalar: `(real,imaginary)`.
- Real vector: `[value,value,...]`.
- Complex vector: `[(real,imaginary);(real,imaginary);...]`.
- Dense real matrix: `[row values;row values]`, with commas between columns.

`ParseComplexInvariant`, `ParseDoubleVectorInvariant`,
`ParseComplexVectorInvariant`, and `ParseDenseMatrixInvariant` use a fixed dot
decimal separator. Locale-aware presentation belongs in application code.
NaN and Infinity are rejected so persistence cannot silently introduce
non-finite numerical state.

## Ownership, allocation, and thread safety

Streams are borrowed synchronously and never retained. Write functions do not
close or reposition a stream after their payload. Read functions start at the
current position and stop after one binary object or at end-of-stream for text
formats.

Results own independent arrays or typed dense/sparse storage. Binary validation
uses a payload buffer before construction, so peak memory is approximately
payload plus result. Text writers build and validate the complete representation
before writing it; an unsupported explicit sparse zero therefore does not
partially modify the stream. Functions are reentrant when callers do not
concurrently mutate the same stream.

`EInterchangeError` names the failing operation and violated format or limit.
I/O errors from an underlying stream may also propagate.

Malformed magic/version/kind metadata, truncated payloads, CRC mismatches,
non-canonical sparse entries, non-finite text values, and configured resource
limit violations raise before a matrix, state, or model is returned. A stream
may already contain bytes if the stream itself raises during a write; callers
needing transactional file replacement should write a temporary file and
rename it after success.

## Selected model persistence

`InterchangeLib.Models` provides these explicit adapters:

| Model | Save/load | Persisted state |
| --- | --- | --- |
| `TCubicSplineInterpolator` | `SaveCubicSpline` / `LoadCubicSpline` | boundary kind, knots, values, and polynomial coefficients |
| `TStreamingFIR` | `SaveStreamingFIR` / `LoadStreamingFIR` | coefficient snapshot and current history |
| `TStandardizationModel` | `SaveStandardization` / `LoadStandardization` | fitted means and positive scales |
| `TScalarKalmanFilter` | `SaveScalarKalman` / `LoadScalarKalman` | configuration, current estimate, and covariance |

The model envelope is version 1, little endian, kind tagged, and CRC-32
protected. Loaders enforce payload/element caps, validate the complete object,
and construct a new model only after validation succeeds. They work with
streams that return partial reads. `SummarizeCubicSpline`,
`SummarizeStreamingFIR`, `SummarizeStandardization`, and
`SummarizeScalarKalman` report bounded structural state without dumping an
unbounded payload.

`DEFAULT_MAX_MODEL_ELEMENTS` is the default adapter cap;
`EModelInterchangeError` identifies model-envelope/schema failures.

These adapters are deliberately separate from the numerical units, so using a
spline, filter, standardizer, or Kalman filter never pulls persistence into
the numerical dependency graph. The schema does not dump Pascal record memory
and therefore does not depend on record padding.

## Bounded expression evaluation

`MathBase.Expressions` evaluates opt-in arithmetic over caller-supplied finite
scalar, vector, and dense-matrix symbols. `TExpressionValue` snapshots vector
and matrix bindings; `TExpressionLimits` caps text length, parser depth,
operation count, and produced elements.

`TExpressionValueKind` distinguishes `evScalar`, `evVector`, and `evMatrix`;
`TExpressionSymbols` is the owned symbol-array alias. `EExpressionError`
identifies parse, type, shape, arithmetic, and resource failures.

The supported language contains scalar arithmetic, elementwise compatible
arithmetic, unary elementary functions, `dot`, `matmul`, and `transpose`.
Vectors and matrices enter through bindings rather than text literals. There
is no assignment, loop, recursion, file, environment, process, network, or
user callback primitive. Unknown names, shape errors, division by zero,
non-finite results, and exhausted limits raise `EExpressionError` before a
result is returned. This is a bounded mathematical evaluator, not a general
Pascal or scripting runtime.

## Open persistence families

Version 1.9 does not promise decomposition or preconditioner factors, arbitrary
model graphs, decision forests, multivariate Kalman filters, or general filter
objects as stable formats. Adding one requires a separate versioned schema and
compatibility tests; raw Pascal record dumps are not accepted as persistence.

## Common mistakes

- **Persistence rejects malformed input.** Loaders validate magic, version,
  checksum, shapes, limits, and finite values before returning; a corrupt
  stream raises rather than producing a partial result.
- **Invariant text is locale-independent.** The `...ToInvariant` and
  `Parse...Invariant` helpers use a fixed decimal separator; locale-aware
  presentation belongs in application code.
- **Streams are borrowed.** Interchange functions use the caller's stream
  synchronously and never retain it; write a temporary file and rename it for
  transactional replacement.
- **Only selected models persist.** `InterchangeLib.Models` covers the
  documented spline/FIR/standardizer/scalar-Kalman adapters; decomposition
  factors, forests, and general object graphs are not stable formats.
