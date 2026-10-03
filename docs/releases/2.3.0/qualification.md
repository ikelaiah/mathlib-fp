# 2.3.0 qualification

**Status:** Passed on Linux and Windows from checksummed clean archives.

The release requires a checksummed clean-source-archive qualification on Linux
and a checksummed clean-ZIP qualification on Windows. Both profiles include
the full test and example suites, documentation and output checks, numerical,
performance, and portability gates; Windows also builds the Lazarus package
for Win64 and Win32. Linux additionally runs with new outbound connections
blocked.

| Platform | Result | Evidence |
| --- | --- | --- |
| Linux x86-64, FPC 3.2.2 | Passed; outbound connections blocked | [Linux artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943/artifacts/11261603685), ZIP SHA-256 `7a9ff27e823e9acf0065784b42c626b587d73befe0949edd1d05351d4392b6d7` |
| Windows x86-64, FPC 3.2.2, Lazarus 4.8 | Passed; Win64 and Win32 package builds | [Windows artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943/artifacts/11261723741), ZIP SHA-256 `ef6f9ea86868bb4167d5c385f1eb675d5e81545a0b093bef2b6c5d3d7150a6d0` |

The evidence above is from the [Release qualification workflow run
37090437943](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943),
which qualified commit
[`9175c1276032b4843f3be3208f6ffee81600bd61`](https://github.com/ikelaiah/mathlib-fp/commit/9175c1276032b4843f3be3208f6ffee81600bd61)
on `release/2.3.0`. The [workflow qualification record](workflow-qualification.md)
describes the profiles and retained artifact digests.
