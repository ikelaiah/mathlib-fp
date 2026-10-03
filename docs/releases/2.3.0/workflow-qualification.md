# 2.3.0 workflow qualification

**Status:** Passed on Linux and Windows.

The [Release qualification workflow run 37090437943](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943)
qualified commit
[`9175c1276032b4843f3be3208f6ffee81600bd61`](https://github.com/ikelaiah/mathlib-fp/commit/9175c1276032b4843f3be3208f6ffee81600bd61)
on `release/2.3.0`. Both jobs extracted and qualified checksummed clean
archives with Free Pascal 3.2.2.

- Linux passed the complete qualification with new outbound connections
  blocked. [Artifact 11261603685](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943/artifacts/11261603685)
  SHA-256: `7a9ff27e823e9acf0065784b42c626b587d73befe0949edd1d05351d4392b6d7`.
- Windows passed the complete qualification with Lazarus 4.8 and Win32/Win64
  package builds. [Artifact 11261723741](https://github.com/ikelaiah/mathlib-fp/actions/runs/37090437943/artifacts/11261723741)
  SHA-256: `ef6f9ea86868bb4167d5c385f1eb675d5e81545a0b093bef2b6c5d3d7150a6d0`.

The hashes identify the retained GitHub Actions artifact ZIPs. The workflow
artifacts include the extracted-archive checksums, gate results, and logs.
Publishing the release tag runs the same qualification against the publication
commit.
