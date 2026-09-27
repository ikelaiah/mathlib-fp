# 2.2.0 qualification

**Status:** Passed on Linux and Windows from checksummed clean archives.

The [Release qualification run 36295825767](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767)
passed on 2026-09-27 against candidate commit
[`aafd3dd0d3aafb9e335bb4cc9eeb7c2d938e9340`](https://github.com/ikelaiah/mathlib-fp/commit/aafd3dd0d3aafb9e335bb4cc9eeb7c2d938e9340).
Linux completed the checksummed clean-archive profile with new outbound
connections blocked. Windows completed the checksummed clean-ZIP profile,
including Lazarus 4.8 and Win32/Win64 package builds.

| Platform evidence | Result |
| --- | --- |
| [Linux qualification artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767/artifacts/10923738368) | Passed; artifact ZIP SHA-256 `6e0b928eb646c34042c516d9e9528bb809a72729e6e3638a1785e0490ab54ff8` |
| [Windows qualification artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767/artifacts/10924220470) | Passed; artifact ZIP SHA-256 `973e54cd1050d451ad5b8efc2df5ba9e4e233f153688d9c83df3724dc7d3989d` |

The workflow artifacts contain the full gate results, logs, checksums, and
platform-specific qualification evidence. The published `v2.2.0` tag will
run the same qualification workflow from the finalized release commit.

Numerical qualification for the newly stable function and spectral families
is recorded in [the 2.2.0 evidence catalogue](numerical-evidence.json). It
points to the independent decimal reference corpora, their test budgets, and
the factor reconstruction and normalized residual checks. The frozen 1.9.4
catalogue remains unchanged and continues to document that release's evidence.
