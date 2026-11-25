# 2.16.0 Special Functions III

## Added

- Added real-double digamma and polygamma, convergent real Riemann zeta,
  both real Lambert W branches, integer-order Bessel J/Y and modified I/K,
  and Airy Ai/Bi with their first derivatives.
- Added independent high-precision reference fixtures and a circular-membrane
  example that computes and checks the first positive J2 zero.

## Compatibility

- The new scalar calls are additive. The existing order-zero and order-one
  Bessel entry points retain their domains and behavior. The implementation
  uses Free Pascal and its standard units.

The [MathBase guide](../../guides/domains/math-base.md#special-functions-iii-in-2160)
lists argument bounds, pole behavior, and runnable guidance. The
[numerical provenance](numerical-evidence-provenance.md) records the test
budgets for this release.
