# PR notes: 1.9.4

## Scope

This release closes the stable numerical-evidence audit. It is source and
interface neutral: the changes add evidence records, validation tools,
qualification coverage, and release documentation.

## Review boundary

- `docs/numerical-evidence-1.9.4.json` contains exactly one record for every
  stable family in `docs/capabilities.json`.
- `tools/check_numerical_evidence.py` validates the catalogue and its cited
  repository inputs.
- `tools/run_numerical_mutation.py` overlays three sampled high-risk faults and
  requires FPCUnit to detect each one.

## Required checks

```text
python tools/test_numerical_evidence.py
python tools/check_numerical_evidence.py
python tools/test_numerical_mutation.py
python tools/run_numerical_mutation.py --compiler fpc
python tools/qualify_release.py --release 1.9.4 --compiler fpc
```

## Non-goals

Tag-name normalisation for the prior 1.9.3 release remains a separate
repository-history repair and is intentionally outside this branch.
