# v2.13.0 numerical and performance provenance

The [numerical catalogue](numerical-evidence.json) retains prior contracts and
adds the independently derived fixtures described in the
[specification](../../../tasks/spec-2.13.md). The implementation
is original MIT-licensed Pascal with no external runtime. The
[performance contract](performance-evidence.json) retains the prior benchmark
rows; this release makes no new speedup claim.

The frequency fixtures independently construct literal repeated rows and compare
coefficients, information-based standard errors, deviance, null deviance,
Pearson statistics and degrees of freedom. The logistic fixture additionally
has exact coefficients -ln(3)-0.2 and ln(12)+0.5 from two empirical success
odds (1/3 and 4) and their known offsets. A single-row Poisson fixture with
frequency 2,147,483,647 has coefficient ln(2) and standard error
1/sqrt(2*frequency), independently checking information without expansion.
