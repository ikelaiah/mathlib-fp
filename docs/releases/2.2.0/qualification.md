# 2.2.0 qualification

**Status:** Passed on Linux and Windows from checksummed clean archives.

The [Release qualification run 36297034499](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499)
passed on 2026-09-27 against finalized release commit
[`1a31a2a6fe94f7a419e03c1a88a698244e955966`](https://github.com/ikelaiah/mathlib-fp/commit/1a31a2a6fe94f7a419e03c1a88a698244e955966).
Linux completed the checksummed clean-archive profile with new outbound
connections blocked. Windows completed the checksummed clean-ZIP profile,
including Lazarus 4.8 and Win32/Win64 package builds.

| Platform evidence | Result |
| --- | --- |
| [Linux qualification artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499/artifacts/10924232032) | Passed; artifact ZIP SHA-256 `9c9cde8f51385c306e7c35a204315dc4515902a7ec79c15591e1e9ab950d6f2b` |
| [Windows qualification artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499/artifacts/10924630624) | Passed; artifact ZIP SHA-256 `52a7634fc6d58454829c5220cce4fa6bea6ab051b3c5b078c54a7aa568f12abc` |

The workflow artifacts contain the full gate results, logs, checksums, and
platform-specific qualification evidence. The published `v2.2.0` tag will
run the same qualification workflow from the merged publication commit.

Numerical qualification for the newly stable function and spectral families
is recorded in [the 2.2.0 evidence catalogue](numerical-evidence.json). It
points to the independent decimal reference corpora, their test budgets, and
the factor reconstruction and normalized residual checks. The frozen 1.9.4
catalogue remains unchanged and continues to document that release's evidence.
