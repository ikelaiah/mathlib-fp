# mathlib-fp 1.9.7 release notes

Version 1.9.7 is the migration and compatibility rehearsal. It proves source
edits and package boundaries before 2.0 changes any documentation default. It
does not remove or deprecate a maintained 1.x declaration and does not add a
runtime dependency.

## Executable migration evidence

- Independent [supported-1.x](../../../examples/migration/one_x/consumer_1_9.lpr)
  and [candidate-2.0](../../../examples/migration/candidate_2_0/consumer_2_0.lpr)
  projects compile and run across all 13 documented domains.
- Each project asserts construction, ordinary success, a diagnostic failure
  contract, ownership/copy behavior, indexing, precision, defaults, and result
  interpretation. Expected compiler warnings are recorded and currently empty.
- `tools/check_migration_rehearsal.py` validates the machine-readable contract,
  compiles/runs both consumers plus the package-boundary consumer, verifies the
  Lazarus package unit/dependency boundary, and writes host-specific evidence.
- The same checker is part of ordinary CI and clean-archive release
  qualification; no network or third-party numerical package is required.

## Compatibility decision

`TPressureKit`, `EPressureError`, `TVelocityKit`, and `EVelocityError` remain
supported in `EngineeringLib.Pressure` and `EngineeringLib.Velocity`.
Executable evidence confirms exact facade/exception identity and equal
defaults, ownership, failure behavior, and numerical results. The main Lazarus
package already includes both focused and canonical units and still depends
only on FCL.

New code spanning pressure, velocity, and flow may prefer
`TFluidDynamicsKit`/`EFluidDynamicsError`. That documentation preference is not
a deprecation: 1.9.7 emits no warning, performs no package move, and starts no
removal runway.

## External-library migration guidance

The [migration rehearsal guide](migration-rehearsal.md) publishes
conceptual mappings from common NumLib and LMath/DMath tasks to mathlib-fp.
Mappings call out zero-based storage, shapes, ownership and mutation,
precision, defaults, callbacks, convergence/status interpretation, package and
licensing boundaries, and unsupported cases. They are source-migration
directions, not ABI, symbol-name, random-sequence, or drop-in compatibility.

## Upgrade notes

- Existing 1.9 code requires no edit.
- The public 1.9 interface remains frozen; the API snapshot has no declaration
  addition, removal, or signature change.
- To adopt candidate conventions early, compare the two consumer projects and
  make only the documented import/storage/diagnostic edits.
- Re-run application-specific reference values, residual checks, and edge cases
  after migrating from another numerical library.

## Qualification boundary

Local Windows x86-64 FPC 3.2.2 consumer and Lazarus 4.8 package evidence is
recorded in [QUALIFICATION_1.9.7.md](qualification.md). Exact Linux and
Windows clean-archive candidate jobs remain mandatory before tagging; no local
result is generalized to a target that did not run.
