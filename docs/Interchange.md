# Numerical interchange and inspection

`MathBase.Interchange` is an optional unit for invariant text, delimited text,
Matrix Market, versioned binary persistence, and concise summaries. Numerical
core units do not depend on it.

Maturity: **stable for the dense real/complex and RNG-state formats documented
here**.

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
  finally
    Stream.Free;
  end;
end.
```

See [example 20](../examples/20_interchange_replay.pas) for matrix and random
state replay.

## Choose a format

| Need | Format/API | Important contract |
| --- | --- | --- |
| Pasteable configuration | `DoubleVectorToInvariant`, `ComplexVectorToInvariant`, `DenseMatrixToInvariant` | Locale independent; finite values only |
| Simple table interchange | `WriteDelimitedMatrix`, `ReadDelimitedMatrix` | Dense rectangular numeric rows; caller-selected delimiter |
| Other numerical tools | `WriteMatrixMarket`, `ReadMatrixMarketDouble`, `ReadMatrixMarketComplex` | Matrix Market dense `array`, `real`/`complex`, `general` subset |
| Large exact round trip | `SaveBinary`, typed `Load...Binary` | Versioned, little-endian scalar payload and CRC-32 |
| Reproducible simulation | `SaveRandomStateBinary`, `LoadRandomStateBinary` | Exact four-word `TLocalRandom` state |
| Logging/debugging | `Summarize` | Shape/type metadata plus bounded values |

Delimited input is the numeric rectangular subset: it does not interpret
headers, dates, categories, missing fields, or quoted embedded delimiters.
Matrix Market coordinate/sparse and structured symmetry variants are rejected.

## Binary format version 1

Every object starts with:

- eight-byte magic `MFPBIN1` plus a zero byte;
- little-endian unsigned 16-bit format version;
- scalar/storage kind and one reserved byte;
- little-endian unsigned 64-bit rows, columns, and payload byte count;
- little-endian CRC-32 of the payload; and
- row-major IEEE binary64 real values, interleaved real/imaginary binary64
  values, or four unsigned 64-bit RNG state words.

The format is endian-defined and does not write Pascal record memory layouts.
It therefore avoids ABI padding and host-endian ambiguity.

Loaders validate magic, version, kind, dimension products, platform address
limits, caller element limits, payload byte count, truncation, checksum, and
finite scalar values. Only after those checks does a loader return a new
array/matrix/state. There is no destination to partially mutate.

`DEFAULT_MAX_INTERCHANGE_ELEMENTS` is 16,000,000. Pass a smaller limit when
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

Results own independent arrays or typed dense storage. Binary validation uses
a payload buffer before construction, so peak memory is approximately payload
plus result. Functions are reentrant when callers do not concurrently mutate
the same stream.

`EInterchangeError` names the failing operation and violated format or limit.
I/O errors from an underlying stream may also propagate.

## Open persistence families

Version 1.8 does not promise sparse matrices, fitted models, decomposition
factors, splines, general filter objects, or configuration graphs as stable
formats. Adding one requires a separate versioned schema and compatibility
tests; raw Pascal record dumps are not accepted as persistence.
