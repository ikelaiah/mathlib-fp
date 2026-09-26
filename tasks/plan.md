# Implementation plan: 2.1 Special Functions II

## Overview

Add a bounded, documented real `Double` special-function surface in small,
reviewable changes. Start with cylindrical Bessel functions, then elliptic
integrals/functions, exponential integrals, and a limited hypergeometric
baseline. Each family ships with explicit domains, numerical budgets, an
independent offline reference corpus, cited algorithms, and user guidance.
The proposed contract is in [spec-2.1.md](spec-2.1.md); the roadmap remains the
release-scope authority.

## Architecture decisions to review

- Put new scalar functions in a dedicated `MathBase.SpecialFunctions` unit so
  `MathBase.Precision` stays focused on its existing stable contracts. Confirm
  public names and exact order coverage in the first task before coding.
- Begin with real `Double`. Add no mandatory runtime or test dependency beyond
  FPC and its standard units. High-precision tools may produce committed
  reference values offline, with generator, version, precision, and citations
  recorded beside the corpus.
- Implement one complete family slice at a time: public contract, reference
  values, source, tests, documentation, and one runnable example where useful.
- Preserve 2.0 compatibility. No existing declaration changes or removals are
  part of this milestone.

## Dependency order

```text
scope and API contract -> offline reference corpus -> Bessel J/Y -> Bessel I/K
                              |                         |
                              +-> elliptic methods -----+
                              +-> exponential integrals
                              +-> bounded hypergeometric baseline
all family slices -> capability inventory, examples, full qualification
```

## Tasks and checkpoints

1. **Contract and evidence design.** Resolve exact public names, order/range
   coverage, domains, exceptional-value behavior, and measurable accuracy
   budgets. Record algorithm and reference provenance. Verify the design
   against the roadmap and existing `MathBase.Precision` conventions.
2. **Independent Bessel corpus.** Commit reference values across small,
   ordinary, large, near-zero, near-root, and invalid inputs, with generation
   metadata and a test loader. Verify that incorrect sample values fail the
   checker and that the normal test suite needs no generator dependency.
3. **Bessel J and Y.** Add the agreed initial order coverage with piecewise
   numerics, edge contracts, focused tests, documentation, and a runnable
   example. Check against the corpus on Windows and Linux CI.
4. **Modified Bessel I and K.** Add bounded real I0/I1/K0/K1 functions with
   explicit pole and range behavior. The accepted range does not require scaled
   variants. Verify small/large-scale cases and the I/K Wronskian independently.

**Checkpoint:** J/Y/I/K have documented domains and budgets, independent
reference cases, no dependency additions, and passing focused tests.

5. **Elliptic integrals and functions.** The complete/incomplete Legendre
   K/E/F integral slice is merged. Add real Jacobi sn/cn/dn for parameter
   `m=k^2` in `[0,1]` and bounded real arguments by safeguarded inversion of
   the incomplete Legendre F integral, with exact endpoint cases, independent
   references, identities, docs, and an example. The third-kind slice adds
   real complete/incomplete Pi with `n` in `[-16,1]`, Carlson RJ duplication,
   endpoint limits, independent quadrature references, docs, and an example.
   Defer other Jacobi functions, principal values, and complex arguments.
6. **Exponential integrals.** Define the real `Ei`/`E1` boundary and implement
   only the approved domain/range, with sign, branch, pole, and tail tests.
7. **Hypergeometric baseline.** Implement the bounded real Gauss 2F1 series for
   `A,B` in `[-16,16]`, `C` in `[0.5,32]`, and `X` in `[-0.75,0.75]`. Return
   NaN for invalid input or failure to converge within the fixed iteration
   budget. Add independent references, termination and symmetry checks, API
   docs, and a runnable example. Defer continuation and complex branches.

**Checkpoint:** Each shipped family matches its own contract and evidence;
unsupported regions remain explicit in the docs and capability inventory.

8. **Release integration and review.** Update capability inventory, API
   reference, guides, examples, changelog, and 2.1 release records. Run normal
   tests, checked and optimized builds, examples, docs, package checks, and
   applicable numerical/release qualification. Review the public surface and
   numerical evidence before marking 2.1 complete.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Good accuracy at ordinary inputs hides failures near roots, poles, or extreme scales | Corpus spans those regions; use absolute error near zeros and relative error away from them. |
| Published formulas are unstable when translated directly | Choose algorithms by subdomain and validate transitions against independent values. |
| An open-ended API outgrows the evidence | Freeze bounded domains and order coverage before each slice; label unsupported cases. |
| A reference generator becomes a hidden dependency | Commit plain reference data and metadata; normal build and tests use only FPC. |
| Feature breadth delays 2.1 indefinitely | Land complete vertical slices, review scope at checkpoints, and do not claim a family stable until its gate passes. |

## First reviewable change — merged

Complete tasks 1 and 2, then implement the initial J/Y slice. This provides a
usable feature and validates the evidence workflow before the other families.
The J/Y slice passed the independent corpus, normal/checked/optimized FPC
tests, example output contract, documentation build, Lazarus package build, and
Linux/Windows CI before merge as PR #41.
