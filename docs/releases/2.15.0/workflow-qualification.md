# v2.15.0 workflow qualification

The [release example](../../../examples/52_parallel_multiply.pas) multiplies a
240×200×180 product with caller-chosen workers and asserts that the result
matches the serial blocked kernel bitwise. It also checks the small-product
serial fallback and rejects an oversized worker count. Its printed output has
a checked contract.

The [large-product evidence](parallel-multiply-win64.json) runs named square,
rectangular and complex products at 1, 2, 4 and 8 workers in separate
processes. It records speedup, scaling efficiency, peak resident memory and
accuracy, and checks a build without a thread manager. Platform evidence is in
[qualification.md](qualification.md).
