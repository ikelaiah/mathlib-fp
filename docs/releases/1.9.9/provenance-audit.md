# Algorithm, fixture provenance, and licence audit

Version 1.9.9 completes the provenance and licence audit required by the
roadmap convergence gate. The machine-readable source is
[`provenance-audit-1.9.9.json`](../../provenance-audit-1.9.9.json); the normative
policy is [`GOVERNANCE.md`](../../project/governance.md#provenance-and-licence).

## Audit scope

The audit covers every stable unit in `src/` (50 units at 1.9.9). Each record
names:

- the implemented algorithm families;
- the published algorithm provenance the implementation follows;
- the fixture provenance used for numerical qualification;
- the licence status.

## Results

- **Licence:** every unit is MIT licensed original Object Pascal source. No
  unit contains third-party code. No unit loads a DLL/shared object, imports
  networking or process units, or requires generated source at build time.
- **Algorithm provenance:** implementations are original Pascal ports that
  follow MIT-compatible or public-domain published algorithms. Named
  references include Golub and Van Loan (dense decompositions), Higham
  (accuracy/summation guidance), Saad and Barrett et al. (iterative methods),
  Nocedal and Wright (optimisation), Hastie et al. (machine-learning
  conventions), Boyd and Vandenberghe (convex conventions), NIST DLMF and the
  public-domain Abramowitz and Stegun reference values (special functions),
  and the public-domain xoshiro256**/SplitMix64 generators by Blackman and
  Vigna.
- **Fixture provenance:** numerical evidence records in
  [`numerical-evidence-1.9.4.json`](../../numerical-evidence-1.9.4.json) name the
  independent reference method, source, precision, and licence for every
  qualified capability family. Test fixtures are repository-authored
  literals, closed-form identities, or documented tabulated values; no
  fixture requires an external data file or a foreign runtime.
- **Dependency audit:** stable units import only standard FPC RTL/FCL units.
  The source/package audit is exercised by the portability checker on every
  qualified target; the dependency assumptions are part of
  [`portability-evidence-1.9.6.json`](../../portability-evidence-1.9.6.json).

## Enforcement

`tools/check_convergence.py` fails if any `src/*.pas` unit is missing from the
audit, if any record lacks provenance text, if the licence is not MIT, or if
the audit disagrees with the policy document. New units or new algorithm
families must extend the audit in the same change, under the
[contribution gate](../../project/governance.md#contribution-gate-for-new-domains).
