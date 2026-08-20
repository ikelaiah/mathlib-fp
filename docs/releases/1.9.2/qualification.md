# mathlib-fp 1.9.2 qualification

Status on 2026-08-02: **all 69 local release-qualification gates passed;
final Linux and Windows clean-archive CI is pending**.

## Completion-gate evidence

| Gate | Current evidence |
| --- | --- |
| Automated clean-archive journey | Documentation/API structure, all beginner and advanced links, executable programs, claimed output, generated search, built links, release identity, and offline artifacts are checked without external participation or services. |
| Stable-domain beginner and advanced routes | 13 domain landing pages contain ordered beginner/common-task/advanced sections. Every beginner route has an output-checked runnable program; every advanced route links an example compiled and run by CI. |
| Problem-oriented search | Generated search is required to find “least squares”, “normal probability”, and “FFT convolution” in the current release path. |
| Recipe execution | 22 self-contained documentation programs compile and execute, with 21 exact or ordered output contracts and all 13 beginner domains covered. Clean-archive CI runs the same checker. |
| API compatibility | The schema-2 1.9.0 baseline remains unchanged: 2,880 exact owner/signature-aware declarations and 281 required public names. No `src/` interface changed. |

## Automated preflight

The 1.9.2 candidate passed all 69 local gates in `qualify_release.py`: normal,
optimised, checked/heap-traced tests, all examples and output contracts,
documentation structure/API/execution/search checks, generated/offline
documentation, Lazarus package, and representative benchmark. The run used
FPC 3.2.2 and Lazarus 4.8 on Windows 11 x86-64 and reported no test, example,
documentation, package, or benchmark failure.

The checked-heap gate directs heaptrc to an explicit evidence log and parses
its unfreed-block and byte counts. A missing summary or any nonzero count is a
failure; qualification artifacts are retained even when a later gate fails.

The authoritative Linux and Windows results must come from checksummed clean
source archives of the exact commit selected for the tag. They are not
replaced by the pre-tag local run.

## Required final command

Run from the exact clean 1.9.2 source archive selected for release:

```text
python tools/qualify_release.py --release 1.9.2 --compiler fpc \
  --lazbuild lazbuild
```

The driver enforces the
[automated beginner-journey contract](automated-journeys.md) alongside
the numerical, example, package, archive, and benchmark gates. The release
must then pass Linux and Windows clean-archive workflows, including the
Lazarus package on Windows, before the tag is published.

## Compatibility, dependencies, and limitations

The complete library remains native Free Pascal source with standard RTL/FCL
units only. Documentation generation uses the Python standard library. No
foreign numerical DLL, service, licence key, network connection, or third-
party runtime package is required by the stable library or examples.

The public 1.9 API and capability limitations are unchanged. Version 1.9.2 is
a learning-path release and does not begin the 1.9.3 API-decision milestone or
any later trust, performance, portability, migration, beta, or freeze work.
