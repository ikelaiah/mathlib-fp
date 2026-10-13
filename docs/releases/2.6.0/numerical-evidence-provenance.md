# Numerical-evidence provenance

The [2.6.0 catalogue](numerical-evidence.json) carries forward the four
post-1.9 numerical-evidence families from 2.5.1 unchanged and adds
`stable_sos_iir_filtering`.

The SOS entry uses repository-authored Python Decimal calculations at 100-digit
precision for coefficients and complex frequency-response components. The
generator is `tools/generate_sos_iir_reference.py`; its committed values are in
[`SOSIIRReference.inc`](../../../tests/SOSIIRReference.inc). The coefficient
cases include Butterworth and first- and second-order Chebyshev Type I designs.
The response case checks both real and imaginary components at DC, an
interior frequency, the design edge, quarter-rate, and Nyquist. Independent
analytic checks cover critical edges, ripple endpoints, stability, and
direct-form impulse/step recurrences. The ordinary test and release paths
require only the checked-in fixture and verify its reproducibility without
external packages.

The [SciPy IIR design documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.iirfilter.html),
[bilinear-transform documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.bilinear_zpk.html),
and [SOS filtering documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.sosfilt.html)
informed the independently authored design contract; SciPy is not a runtime
or build dependency.
