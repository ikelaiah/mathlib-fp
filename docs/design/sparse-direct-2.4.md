# Sparse Direct II design (2.4)

## Objective

Extend the existing sparse LU baseline with a deterministic fill-reducing
ordering, separate symbolic analysis from numeric factorization, and make the
symbolic result reusable for matrices with the same canonical sparsity pattern.
Retain the native Free Pascal implementation and sparse storage throughout.

## Scope and decisions

- Support general square CSR and CSC sparse matrices in all four existing
  scalar families: `Single`, `Double`, `TSingleComplex`, and `TComplex`.
- Add deterministic minimum-degree ordering over the symmetrized structural
  graph. Ties are broken by original vertex index. Numeric LU continues to use
  row partial pivoting after the symmetric row/column permutation.
- Keep natural ordering available as a baseline and compatibility option.
- Split the API into symbolic analysis and numeric factorization. Analysis
  retains a canonical immutable structural pattern and permutation. Numeric
  factorization validates the exact dimensions, format-independent coordinates,
  and structural-zero policy, then factors only the supplied values.
- A symbolic analysis may be reused for multiple value sets with an identical
  canonical pattern. A completed numeric factor remains immutable and supports
  repeated multi-RHS solves.
- Report input, factor, and fill nonzero counts, selected ordering, pivot
  interchanges, and minimum pivot magnitude. Define fill relative to the
  analyzed input pattern after canonical conversion.
- Preserve failure-atomic construction, input immutability, shape validation,
  exact in-place RHS solves, and rejection of partially overlapping views.

## Out of scope

Distributed, out-of-core, parallel, GPU, vendor-library, multifrontal, and
supernodal algorithms; indefinite symmetric-specific factorization; automatic
solver selection; performance claims beyond measured fixtures.

## API and behavior

The public ordering enum gains a minimum-degree value. A scalar-specific
symbolic analysis interface exposes size, ordering, analyzed pattern count,
and `Factorize(matrix, pivotTolerance)`. The existing `FactorSparseLU(matrix,
pivotTolerance)` remains source-compatible and delegates through a natural
ordering analysis. A new analysis factory accepts an explicit ordering.

Minimum-degree analysis builds the undirected graph from the union of each
stored coordinate and its transpose, excluding diagonal entries. At each step
it selects the remaining vertex with the fewest remaining neighbors, connects
those neighbors to model elimination fill, and removes the selected vertex.
The analysis and graph storage are sparse; no rows-by-columns dense structure
is permitted.

Numeric factorization permutes rows and columns using the analyzed ordering,
applies partial row pivoting, and stores L/U rows sparsely. Solves apply the
ordering permutation, row pivots, triangular solves, then inverse ordering.
The factor fill count is `factorNonZeroCount - inputNonZeroCount`, clamped at
zero to preserve the existing diagnostic contract.

Pattern mismatch, non-square input, invalid ordering, invalid pivot tolerance,
singular pivots, malformed storage, and non-finite arithmetic raise
`ESparseDirectSolveError` before exposing a partial result.

## Commands and verification

- Focused test: compile and run `tests/TestStructuredSolvers.pas` with FPC 3.2.2.
- Full suite: use the repository's release qualification workflow and its
  normal, optimized, runtime-checked, and heap-traced configurations.
- Documentation: run Markdown/link/API checks and compile runnable examples.
- Release: follow `RELEASING.md`, including Linux/Windows CI, Win32/Win64 tests,
  package consumer, performance and portability evidence, archive/offline
  qualification, and versioned documentation checks.

## Success criteria

- Existing natural-order callers and results remain source-compatible.
- Minimum-degree analysis produces deterministic permutations and reduces or
  preserves factor nonzeros on representative fill-sensitive fixtures.
- Reusing an analysis accepts equal patterns with changed values and rejects
  any structural mismatch.
- All scalar families solve single and multiple RHS fixtures against typed
  dense reference solutions with bounded residuals.
- Large sparse fixtures prove storage remains sparse; no dense fallback is
  used by analysis, factorization, or solve.
- Public API reference, capability inventory, examples, release evidence, and
  release metadata consistently describe v2.4.
