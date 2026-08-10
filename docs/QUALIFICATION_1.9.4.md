# mathlib-fp 1.9.4 qualification

Status on 2026-08-10: **all 76 local release-qualification gates passed** on
Windows 11 x86-64 with FPC 3.2.2, Lazarus 4.8, and Python 3.13.5. The release
cannot be tagged until the Linux and Windows clean-archive workflows pass for
the exact candidate commit.

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

## Local preflight result

The command passed all 76 gates. It recorded zero failed gates across normal,
optimised, and checked/heap-traced test suites; examples and output contracts;
documentation and API checks; the catalogue and three-fault mutation gate; the
versioned documentation site and offline archive; the Lazarus package; and the
representative benchmark. The qualification manifest is retained at
`build-temp/release-qualification/results.json` for the local candidate.

## Required clean-archive evidence

The exact candidate commit must pass the Linux and Windows clean-archive
qualification workflows. Those workflows are the authoritative portability and
archive checks; a maintainer checkout cannot replace them.

## Limits

The numerical evidence records bounded release claims. They do not prove
correctness for every input, compiler, or platform, and they do not promote an
unsupported capability to stable status.
