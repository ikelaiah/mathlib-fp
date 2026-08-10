# mathlib-fp 1.9.4 qualification

Status: local release qualification is pending for the final candidate commit.
The release cannot be tagged until the local result below is replaced with the
candidate's recorded outcome and the Linux and Windows clean-archive workflows
pass for that same commit.

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Stable-family coverage | `numerical-evidence-1.9.4.json` has one checked record for every stable capability in `capabilities.json`. |
| Bounded claims | Every record names an input domain, edge cases, evidence category, and an exact or numerical budget. |
| Provenance | Every reference record identifies its method, source, precision, parameters, licence, and regeneration procedure. |
| Fault-detection sampling | Three high-risk mutations compile in isolated source overlays and must produce FPCUnit failures. |
| Compatibility | The 1.9.0 public-interface snapshot remains unchanged; the 1.9.3 API decision remains historical documentation. |

## Required local command

Run from the exact clean 1.9.4 source archive selected for release:

```text
python tools/qualify_release.py --release 1.9.4 --compiler fpc \
  --lazbuild lazbuild
```

The driver runs normal, optimised, checked/heap-traced tests, examples and
output contracts, documentation and API checks, numerical evidence and
mutation gates, the versioned documentation build, the Lazarus package, and a
representative benchmark. All gates are offline and use only Free Pascal,
standard RTL/FCL units, and Python's standard library.

## Required clean-archive evidence

The exact candidate commit must pass the Linux and Windows clean-archive
qualification workflows. Those workflows are the authoritative portability and
archive checks; a maintainer checkout cannot replace them.

## Limits

The numerical evidence records bounded release claims. They do not prove
correctness for every input, compiler, or platform, and they do not promote an
unsupported capability to stable status.
