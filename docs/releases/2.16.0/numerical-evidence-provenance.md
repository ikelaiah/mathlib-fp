# 2.16.0 numerical evidence

The [reference generator](../../../tools/generate_special_functions_iii.py)
uses mpmath 1.3.0 at 100 decimal digits and rounds its results to binary64.
Each oracle runs on the exact binary64 input recorded in the
[corpus of 1,646 evaluations](../../../tests/SpecialFunctionsIIIReference.inc). The generator
also produces integer-centered Airy Taylor anchors from high-precision
values and first derivatives. Noninteger Airy fixtures and the Wronskian
check exercise the Taylor evaluation independently of the anchors.

| Output | Relative tolerance | Absolute floor or regional allowance |
| --- | --- | --- |
| Digamma | 2e-13 | 2e-14 near the zero |
| Polygamma | 2e-12 | Four binary64 subnormal steps |
| Riemann zeta | 2e-14 | Four binary64 subnormal steps |
| Lambert W | 1e-13 | Four binary64 subnormal steps |
| Bessel J | 2e-12 | 8e-13 when `abs(X) >= Order`, four subnormal steps otherwise |
| Bessel Y | 1e-11 | 8e-13 |
| Modified Bessel I | 2e-12 | Four binary64 subnormal steps |
| Modified Bessel K | 2e-12 | 2e-10 relative for `2 < X < 16` where the established K0/K1 bases lose relative precision. Absolute floor of four subnormal steps. |
| Airy functions and first derivatives | 5e-12 | 2e-12 for `X <= 0`, four subnormal steps for positive X |

The test uses the larger of the relative allowance and the absolute floor.
It checks infinity signs and explicit boundary behavior separately. These
are corpus budgets. The release guide defines the supported domains.

To regenerate the data, install mpmath 1.3.0 in a development environment and
run `python tools/generate_special_functions_iii.py`. Pass `--check` to
compare both generated artifacts without writing. The checked-in fixtures
allow FPCUnit and release consumers to run offline with the standard units.

The Pascal implementations follow the DLMF descriptions of
[gamma derivatives](https://dlmf.nist.gov/5.15),
[Euler–Maclaurin zeta](https://dlmf.nist.gov/25.2#iii),
[Lambert W](https://dlmf.nist.gov/4.13),
[Bessel recurrence computation](https://dlmf.nist.gov/10.74#iv), and
[Airy asymptotics](https://dlmf.nist.gov/9.7).
