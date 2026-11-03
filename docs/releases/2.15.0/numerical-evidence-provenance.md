# v2.15.0 numerical and performance provenance

The [numerical catalogue](numerical-evidence.json) retains prior contracts and
adds the `dense_parallel_multiplication` family described in the
[specification](../../../tasks/spec-2.15.md). The implementation is original
MIT-licensed Pascal using only the FPC RTL thread primitives, with no external
runtime.

The oracle is the serial `MultiplyBlockedInto` kernel computed in the same
process with the same block size. The budget is exact: every parallel element
must have the same IEEE 754 bit pattern, for all four scalar kinds. Fixtures are
deterministic trigonometric matrices authored in the repository. The tests
cover uneven row partitions, more requested workers than rows, block sizes from
1 to `High(SizeInt)`, strided views, aliased destinations and a non-default
rounding mode. They also check overflow in a worker partition, which must
raise the same exception class as the serial kernel. The evidence gate also
records the largest difference from the portable `MultiplyInto` oracle, which
is zero on the qualification host.

The [performance contract](performance-evidence.json) retains the prior
benchmark rows. It adds serial and four-worker rows on the same prepared
192×160×176 operands, with an advisory same-run comparison. The
[large-product evidence](parallel-multiply-win64.json) records host-specific
speedup, scaling efficiency and peak memory. These timings support only a
measured-gain statement on named shapes, not a universal speedup claim.
