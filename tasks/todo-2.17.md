# 2.17.0 release checklist

- [x] Identify an exact workflow blocked by the published fixed-width API.
- [x] Record the proposed value, failure, resource, and conversion contracts in the [specification](spec-2.17.md).
- [x] Order the implementation and verification work in the [release plan](plan-2.17.md).
- [x] Add deterministic independent fixtures and test signed integer storage, text, comparison, and `Int64` boundaries.
- [x] Qualify exact arithmetic, division identities and correction paths, GCD, powers, and the counting helpers on Windows.
- [x] Qualify reduced rational values and the end-to-end exact sampling example on Windows.
- [x] Verify binary64 rounding and domain behavior by bit pattern on Win64 and Win32.
- [x] Measure bounded workloads and document the tested limit and scratch use.
- [x] Integrate the unit, API snapshot, capability inventory, example, and Lazarus package for 2.17.0.
- [x] Pass full local qualification.
- [ ] Pass hosted Linux and Windows qualification, including Linux binary64 fixtures.
- [ ] Publish and verify the checksummed release archives.
