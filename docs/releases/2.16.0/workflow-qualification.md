# 2.16.0 workflow qualification

The [circular-membrane example](../../../examples/53_circular_membrane.pas)
uses `BesselJ(2, X)` with the existing bracketed bisection solver. It
finds the first positive J2 zero and computes the radial wavenumber for a
fixed circular rim of radius 0.25 m. The example checks the root to
2e-12 absolute and verifies the rim residual before printing its success
marker. The [output contract](../../../examples/output-contracts.json)
checks the printed root and wavenumber.
