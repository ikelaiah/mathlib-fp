# 2.2.0 workflow qualification

**Status:** Passed.

The [workflow run](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499)
qualified commit `1a31a2a6fe94f7a419e03c1a88a698244e955966` on
`release/2.2.0`. The resolver, Linux clean-archive job, and Windows
clean-archive job all passed.

- Linux extracted the checksummed source `tar.gz` and passed the full
  qualification with outbound network connections blocked.
- Windows extracted the checksummed source ZIP and passed the full
  qualification, including Lazarus 4.8 plus Win32 and Win64 package builds.
- The [Linux artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499/artifacts/10924232032)
  ZIP SHA-256 is `9c9cde8f51385c306e7c35a204315dc4515902a7ec79c15591e1e9ab950d6f2b`.
- The [Windows artifact](https://github.com/ikelaiah/mathlib-fp/actions/runs/36297034499/artifacts/10924630624)
  ZIP SHA-256 is `52a7634fc6d58454829c5220cce4fa6bea6ab051b3c5b078c54a7aa568f12abc`.

The final stable tag triggers a qualification run against the publication
commit and retains its artifacts as release evidence.
