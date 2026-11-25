# 2.17.0 workflow qualification

The [exact sampling example](../../../examples/54_exact_sampling.pas)
computes the probability of drawing exactly 25 marked units when sampling
50 units without replacement from a lot of 100 with 50 marked units.
`CombinationExact` returns `C(100,50) = 100891344545564193334812497256`.
`TBigRational` reduces `C(50,25)² / C(100,50)` to
`2110031698716658293304/13322197258529868226331`.

The example checks both values before printing its success marker. The
[output contract](../../../examples/output-contracts.json) checks the
printed count and probability. The independent Python calculation and
the existing fixed-width failure reproduction are in the
[specification](../../../tasks/spec-2.17.md).
