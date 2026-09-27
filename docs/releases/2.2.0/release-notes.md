# mathlib-fp 2.2.0

Version 2.2.0 is the current published stable release. It combines the 2.1
special-functions scope with the 2.2 nonsymmetric spectral-algebra scope.

## Included capabilities

- Bounded real-double Bessel J/Y and modified Bessel I/K functions, Legendre
  elliptic integrals, real exponential integrals, bounded real Gauss 2F1, and
  Jacobi elliptic sn/cn/dn.
- Real and complex Hessenberg reductions and Schur factorizations.
- Real-input nonsymmetric eigenvalues and right eigenvectors, with ordering,
  residual, and bounded convergence diagnostics.
- Real and complex generalized matrix-pencil factors and homogeneous
  eigenvalues, including infinite eigenvalues when the B matrix is singular.

Each family retains its documented domain, accuracy, convergence, and failure
limits. See the [2.2 API reference](../../reference/api/reference-2.2.0.md),
[dense linear algebra guide](../../guides/domains/dense-linear-algebra.md),
[MathBase guide](../../guides/domains/math-base.md), and [changelog](../../../CHANGELOG.md).

## Qualification status

The release passed checksummed clean-archive qualification on Linux and
Windows, including performance, portability, documentation, Lazarus package,
and artifact checks. The [qualification record](qualification.md) links the
workflow and its uploaded evidence.
