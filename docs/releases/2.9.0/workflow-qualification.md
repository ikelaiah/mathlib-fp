# v2.9.0 workflow qualification

The runnable [bounded search workflow](../../../examples/46_bounded_global_search.pas)
minimizes a two-dimensional Rastrigin objective on [-5.12,5.12]^2, repeats
the seeded search, and asserts identical results on the current profile.
It checks the known zero minimum, global and polish call limits, total
accounting, and non-worsening polish. It prints the global stopping reason
and explains that a heuristic result is not a global-optimality certificate.

The [output contract](../../../examples/output-contracts.json) checks the
objective, status, replay message, limitation, and final success marker.
Platform-specific evaluation counts are diagnostic output, not a cross-target
bitwise promise. Full qualification is recorded in [qualification.md](qualification.md).
