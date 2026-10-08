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
`82a0ed5fe253469b9231aed321eac15732641f03810c1fe6b2c422d8698481e8`.
The generated searchable documentation archive has SHA-256
`790616b0d16bb427a9ee83bddf634b37ed44edabf9106315e91523a7e6a2e7b5`.
The 2.4.0 workflow qualification ran all three representative workflows and
matched their output and exported-artifact digests. Its machine-readable
results are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).

## Release CI

The release workflow still needs to pass from clean source archives on Linux
x86-64 and Windows x86-64. The GitHub run and its source archive checksums will
be recorded here before publication.
