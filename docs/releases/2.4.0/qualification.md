# 2.4.0 qualification

**Status:** The stable 2.4.0 metadata passes all local qualification gates.
Candidate source code passed clean-archive qualification on Linux and Windows;
release branch updates and the final tag run the same qualification workflow.

## Local results

The full release qualifier passed all 125 gates on Windows 11 x86-64 with
Python 3.13.5 and Free Pascal 3.2.2. This includes the 989-test FPCUnit suite
in normal, optimized, and checked-heap modes; runnable example builds and
output contracts; documentation builds and offline link checks; migration,
workflow, portability, and convergence checks; the i386 Lazarus package
consumer; and the benchmark evidence validator.

The machine-readable local release qualification result is retained in
[`qualification-win64.json`](qualification-win64.json) and has SHA-256
`b9d0d2e4ad8dc114e3337add999047945dadc286f6878057a43c94139d13a2d6`.
The 2.4.0 workflow qualification ran all three representative workflows and
matched their output and exported-artifact digests. Its machine-readable
results are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).

## Release CI

Release qualification run
[37772756273](https://github.com/ikelaiah/mathlib-fp/actions/runs/37772756273)
passed on commit `a2b4970e196faa7e9eafb38935faec1014d1cc02`.

- Linux x86-64, FPC 3.2.2: all 124 gates passed offline from a clean source
  archive. SHA-256: `7bca5abf8337d647bbe71fd649eda57ddf33b9b363d782ff12b65de01b1e80dd`.
  See [`qualification-linux.json`](qualification-linux.json).
- Windows x86-64, FPC 3.2.2: all 125 gates passed from a clean source archive,
  including the Lazarus package consumer. SHA-256:
  `428eeab60848f2a2b28327da7fef397245e514e7e2247c00aada800cef8c1d31`.
  See [`qualification-windows.json`](qualification-windows.json).

Each release branch update and the final `v2.4.0` release event runs the same
qualification workflow against its exact source commit.
