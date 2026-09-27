# mathlib-fp 2.2.0 release candidate

This candidate combines the 2.1 special-functions work and the 2.2
nonsymmetric spectral-algebra work. It is not a published stable release;
2.0.0 remains the latest published stable version until qualification and
stable publication are complete.

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
limits. See the [candidate API reference](../../reference/api/reference-2.2.0.md),
[dense linear algebra guide](../../guides/domains/dense-linear-algebra.md),
[MathBase guide](../../guides/domains/math-base.md), and [changelog](../../../CHANGELOG.md).

## Qualification status

The candidate is awaiting the required clean-archive release qualification on
Linux and Windows, including its performance, portability, documentation,
package, and artifact checks. No new platform support claim is made until that
qualification completes.
