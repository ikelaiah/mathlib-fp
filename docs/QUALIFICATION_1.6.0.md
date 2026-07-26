# 1.6.0 release qualification

This report qualifies only the 1.6 typed dense decomposition and direct-solver
milestone. It does not claim any 1.7 modelling/optimisation or deferred sparse,
iterative, or advanced spectral family.

## Supported targets and configurations

| Target/configuration | Result | Evidence |
| --- | --- | --- |
| Windows x86-64, FPC 3.2.2, normal | Pass | Full `TestRunner` |
| Windows x86-64, FPC 3.2.2, `-O3` | Pass | Optimized full `TestRunner` |
| Windows x86-64, FPC 3.2.2, runtime checks | Pass | Range/overflow/stack/IO-checked full `TestRunner` |
| Windows x86-64, FPC 3.2.2, heap trace | Pass, zero unfreed blocks | Heap-traced full `TestRunner` |
| Windows i386, FPC 3.2.2, `-O2` | Pass | Optimized full `TestRunner` |
| Lazarus package 1.6, Win64 and Win32 | Pass | Clean package builds |
| Published examples | Pass | All 17 compile and execute |
| Documentation contract and offline search | Pass | Link/fence/inventory/public-symbol checks and static build |
| Clean source archive | Pass | Checksummed archive; square and solver-selection examples compile/run offline |

The repository CI runs the complete public API test suite on Linux x86-64,
Windows x86-64, and Windows i386, compiles/runs every example, checks/builds
documentation, compiles benchmarks, builds both Lazarus package targets, and
tests the archived quick starts. Local qualification results and CI coverage
are distinguished: the table records the completion run on the qualification
host; the workflow is the cross-platform evidence executed for each pushed
commit.

## Algorithm-specific acceptance budgets

| Family | Double real/complex budget | Single real/complex budget | Measures |
| --- | --- | --- | --- |
| Triangular, LU, Cholesky solve | `2e-13` ordinary fixture, backward error below `1e-14` where conditioned | `2e-5` | RHS residual, normalized backward error, factor reuse |
| Householder QR | `2e-12` complex, `2e-13` real | `2e-5` | `||A-QR||F/||A||F`, `||Q^H Q-I||F`, solve residual |
| Column-pivoted QR | `2e-11` badly scaled permutation fixture | `2e-5` | `||AP-QR||F/||A||F`, permutation identity, rank decision |
| Compact SVD | `2e-11` complex, `2e-12` real | `2e-5` | `||A-U S V^H||F/||A||F`, descending singular values, unit vectors |
| Minimum-norm solve | `2e-12` | `2e-5` | RHS residual and independent Moore-Penrose reference solution |
| Symmetric/Hermitian eigen | `2e-12` | `2e-5` | `||A v-lambda v||`, `||V^H V-I||`, ascending eigenvalues |

Budgets are attached to the named deterministic fixtures; they are not
universal forward-error promises for arbitrarily ill-conditioned input.
Tolerance decisions scale with scalar epsilon, dimensions, and the relevant
pivot/diagonal/singular value.

## Reference, structural, and adversarial evidence

- QR uses an independently checkable four-observation straight-line fit with
  coefficients `(3.5, 1.4)`, plus reconstruction and orthogonality identities.
- CPQR checks `A*P=Q*R`, largest-trailing-column selection, exact rank
  deficiency, a caller-controlled near-rank threshold, and a useful basic
  rank-deficient solve.
- SVD checks diagonal reference singular values `(3,2)`, tall/wide and complex
  reconstruction, descending ordering, and the underdetermined reference
  solution `(2/3,2/3,4/3)`.
- Real eigen checks analytic eigenvalues `(1,3,5)`; Hermitian complex eigen
  checks `(1,3)`. Both check every eigenpair residual. Repeated spectra and
  a `1e-200` scale fixture check basis freedom and scale-relative convergence.
- Empty factors, empty output arrays, multiple right-hand sides, source
  mutation after factorisation, invalid wide QR, nonsymmetric/non-Hermitian
  input, non-finite SVD input, singularity, indefiniteness, and unchanged
  caller storage after validation failure are permanent tests.
- Existing 1.5 LU/Cholesky reconstruction, complex Hermitian, tiny
  positive-definite, singular, ill-conditioned, and multiple-RHS tests remain
  in the full suite.

The test corpus is checked into the repository and needs no network or
external numerical runtime.

## Deterministic performance and allocation evidence

`BenchmarkRunner` uses deterministic trigonometric and structured inputs and
reports:

- a `96 x 32` QR factor plus 20 reused four-RHS solves;
- five allocating least-squares convenience calls on the same shape;
- a `48 x 16` compact SVD plus two-RHS minimum-norm solve; and
- a `24 x 24` full symmetric eigensystem.

Output includes elapsed milliseconds, checksums, convergence sweeps/rank,
factor-build counts, result-allocation counts, and scalar working-storage
estimates. Factor reuse performs one factor build; the convenience path
performs one factor build per call. A solve returns a fresh result by contract.
The benchmark does not claim parallel, SIMD, external-BLAS, or cross-library
performance.

On the Windows x86-64 FPC 3.2.2 `-O3` qualification host, the completion run
recorded:

| Workload | Elapsed |
| --- | --- |
| `96 x 32` QR factor plus 20 reused four-RHS solves | 15 ms |
| Five allocating QR least-squares calls | 63 ms |
| `48 x 16` compact SVD plus two-RHS minimum-norm solve | below 1 ms timer resolution; 8 sweeps |
| `24 x 24` symmetric eigensystem | below 1 ms timer resolution; 7 sweeps |

The same run reported QR checksum `2.786934`, SVD checksum `2.917959`, and
eigen checksum `4.230000`. Timings are host-specific reproducibility data.

## Ownership, compatibility, dependencies, and licence

Factor snapshot and copied-accessor tests prove that source mutation cannot
alter an existing factor. No factor stores a last result or shared public
workspace. All validation occurs before a caller-visible result is returned.

The source-compatible `IMatrix`, `TMatrixKit`, and `IVector` public surface is
unchanged. The new tests import both compatibility and typed units in the same
runner. The migration guide names every compatibility bridge as a deep copy
and does not imply contract equivalence.

The stable units import only Free Pascal RTL units and existing MIT-licensed
mathlib-fp source. A dependency scan checks for foreign declarations, dynamic
library loading, process execution, sockets, HTTP, and external commands.
Normal build, test, documentation, examples, and runtime use need no network,
DLL, service, licence key, or third-party package.

## Deferred families

The capability inventory records sparse/structured storage, LDLT, iterative
and matrix-free solves, advanced nonsymmetric/generalized/partial spectral
families, factor updates, destructive/public-workspace APIs, automatic
dispatch, parallel/SIMD/GPU kernels, and external BLAS/LAPACK as unsupported.
No deferred family counts toward the 1.6 completeness claim.
