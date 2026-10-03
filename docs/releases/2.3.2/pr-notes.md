# 2.3.2 release review notes

This patch makes the current scope limits of mathlib-fp explicit in the
comparison guide. It changes no Pascal implementation units, numerical
behavior, public declarations, or runtime dependencies. The 2.3.2 API snapshot
and reference preserve the 2.3.1 public API surface.

The numerical-evidence catalogue is carried forward from 2.3.1. The runtime
qualification and target evidence continue to refer to the unchanged 2.3.0
implementation. Repository CI and Linux/Windows clean-archive qualification
must pass for the release candidate and exact tag before publication.
