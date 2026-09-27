# 2.2.0 workflow qualification

**Status:** Passed.

The [workflow run](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767)
qualified commit `aafd3dd0d3aafb9e335bb4cc9eeb7c2d938e9340` on
`release/2.2.0`. The resolver, Linux clean-archive job, and Windows
clean-archive job all passed.

- Linux extracted the checksummed source `tar.gz` and passed the full
  qualification with outbound network connections blocked.
- Windows extracted the checksummed source ZIP and passed the full
  qualification, including Lazarus 4.8 plus Win32 and Win64 package builds.
- The [Linux artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767/artifacts/10923738368)
  ZIP SHA-256 is `6e0b928eb646c34042c516d9e9528bb809a72729e6e3638a1785e0490ab54ff8`.
- The [Windows artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36295825767/artifacts/10924220470)
  ZIP SHA-256 is `973e54cd1050d451ad5b8efc2df5ba9e4e233f153688d9c83df3724dc7d3989d`.

The final stable tag triggers a qualification run against the publication
commit and retains its artifacts as release evidence.
