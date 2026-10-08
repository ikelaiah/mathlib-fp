# 2.4.0 release review notes

This release implements the committed 2.4 Sparse Direct II roadmap gate. The
existing explicit sparse LU baseline is extended with reusable symbolic
analysis, deterministic minimum-degree ordering, and permutation-aware sparse
numeric factorization. No third-party numerical runtime is introduced.

The public surface covers general square CSR and CSC matrices for the four
existing scalar families. Natural ordering remains available through the
source-compatible `FactorSparseLU` factory. Pattern mismatch is rejected
before factor publication; a valid analysis can be reused with changed values
on the same pattern.

Release completion depends on the qualification record, generated API
snapshot/reference, capability inventory, examples, documentation builds,
cross-platform CI, and clean-archive release gates all agreeing on this scope.
