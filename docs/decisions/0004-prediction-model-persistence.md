# ADR 0004: Selected GLM and PLS prediction artifacts

Status: accepted for v2.14.0.

Inference records belong to the numerical units so prediction remains independent
of interchange. Projection copies coefficients and removes training diagnostics.
The optional interchange unit persists those records using the existing checked
model envelope. Core prediction overloads share validation and arithmetic with
the existing fit-result overloads.

Envelope magic, version 1, length and CRC32 stay unchanged. Object kinds 1–4
retain their bytes; kinds 5 and 6 identify the new payloads. All scalar fields
are IEEE-754 binary64 little-endian. A vector is an unsigned 64-bit count followed
by that many scalars. Limits are checked before allocation.

| Payload byte | GLM kind 5 | PLS kind 6 |
| --- | --- | --- |
| 0 | scalar encoding 1 (binary64 little-endian) | same |
| 1 | family: 0 Bernoulli, 1 Poisson | intercept convention 1 (separate intercept) |
| 2 | link: 0 logit, 1 log; must match family | preprocessing 0 (original-unit coefficients) |
| 3 | intercept convention 0 (explicit design columns) | column order 0 (indexed fitted order) |
| 4 | preprocessing 0 (caller supplies design) | reserved 0 |
| 5 | column order 0 (indexed fitted order) | reserved 0 |
| 6 | flags: bit 0 requires offset, bit 1 requires exposure | reserved 0 |
| 7 | reserved 0 | reserved 0 |
| 8 onward | coefficient vector | finite intercept scalar, then coefficient vector |

Unknown codes, reserved bits, incompatible exposure/family, empty vectors,
nonfinite scalars and unexpected trailing payload bytes fail explicitly.
The coefficient count is the predictor count; semantic column names are caller
metadata. GLM includes an intercept only through the same explicit design
column used during fitting. PLS coefficients and intercept already incorporate
training centering/scaling, so no means/scales or second transform are applied.

This stores prediction parameters, not evidence of successful fitting. Loading
does not synthesize a TGLMFitResult or TPLSModel. Frequencies affect estimation
but are not deployment inputs. Integrity detects corruption, not authenticity.
Existing adapter formats remain readable and byte-identical for fixed fixtures.
