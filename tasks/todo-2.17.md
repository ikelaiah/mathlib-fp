# 2.17.0 release checklist

- [x] Identify an exact workflow blocked by the published fixed-width API.
- [x] Record the proposed value, failure, resource, and conversion contracts in the [specification](spec-2.17.md).
- [x] Order the implementation and verification work in the [release plan](plan-2.17.md).
- [ ] Add deterministic independent fixtures and test signed integer storage, text, comparison, and `Int64` boundaries.
- [ ] Qualify exact arithmetic, division identities and correction paths, GCD, powers, and the counting helpers.
- [ ] Qualify reduced rational values and the end-to-end exact sampling example.
- [ ] Verify binary64 rounding and domain behavior by bit pattern across supported targets.
- [ ] Measure bounded workloads and document the tested limit and scratch use.
- [ ] Integrate the unit, API snapshot, capability inventory, example, and Lazarus package for 2.17.0.
- [ ] Pass local and hosted qualification, then verify the released artifacts.
