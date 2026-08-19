# mathlib-fp 1.10.0 workflow qualification

Representative multi-domain workflow evidence for the 1.10.0 release. The
three maintained 1.9.8 end-to-end workflows remain representative for 1.10.0:
1.10.0 adds `TVector2D.Rotate` as an additive value operation and changes no
existing workflow contract, ownership, or result type.

The authoritative workflow qualification gate is
`tools/check_workflow_qualification.py`, which compiles and runs each workflow
from an isolated work directory with FPC 3.2.2, verifies success markers,
diagnostic paths, numerical bounds, exported artifacts, and byte-identical
repeatability, and records the exact compiler/platform that ran. The
representative workflows exercised for 1.10.0 are:

- Sensor pipeline (DSP + statistics + time-series).
- Numerical modelling and optimisation (fitting + interpolation + solve +
  bounded optimisation).
- Reproducible probability/finance analysis (seeded sampling + inference +
  NPV/IRR).

Exact Linux and Windows checksummed, network-isolated clean-archive candidate
jobs remain mandatory before tagging; no local result is generalized to a
target that did not run in CI.