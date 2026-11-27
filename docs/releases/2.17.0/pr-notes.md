# 2.17.0 review notes

`MathBase.ExactArithmetic` stores immutable base-2³² limbs and uses only
standard Free Pascal units. Signed integer division uses a one-limb fast
path and normalized long division. Rational arithmetic cross-cancels or
reduces wide intermediate values before enforcing the public result limit.
Conversion to binary64 rounds the exact quotient and remainder once.

The [specification](../../../tasks/spec-2.17.md) records the fixed-width
reproduction and contracts. Review the [API reference](../../reference/api/reference-2.17.0.md),
[numerical provenance](numerical-evidence-provenance.md), and
[qualification record](qualification.md) for evidence.
