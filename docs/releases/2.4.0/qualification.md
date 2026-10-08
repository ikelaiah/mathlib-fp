# 2.4.0 qualification

**Status:** Local Windows qualification passed; clean-archive Linux and
Windows CI qualification is pending.

## Local results

The full release qualifier passed all 125 gates on Windows 11 x86-64 with
Python 3.13.5 and Free Pascal 3.2.2. This includes the 989-test FPCUnit suite
in normal, optimized, and checked-heap modes; runnable example builds and
output contracts; documentation builds and offline link checks; migration,
workflow, portability, and convergence checks; the i386 Lazarus package
consumer; and the benchmark evidence validator.

The machine-readable local release qualification result is retained in
[`qualification-win64.json`](qualification-win64.json) and has SHA-256
`a8811c9a27da4283c86ff0fbc5c83f4a2627605a874bdd502dc147f3d5509bc3`.
The generated searchable documentation archive has SHA-256
`0310c0cd05cbda5df7787446680857c1f6e08b65921a0064dd82b95c24368e74`.
The 2.4.0 workflow qualification ran all three representative workflows and
matched their output and exported-artifact digests. Its machine-readable
results are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).

## Release CI

The release workflow still needs to pass from clean source archives on Linux
x86-64 and Windows x86-64. The GitHub run and its source archive checksums will
be recorded here before publication.
