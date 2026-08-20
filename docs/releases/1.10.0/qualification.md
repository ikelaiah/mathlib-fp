# mathlib-fp 1.10.0 qualification evidence

Local verification evidence for the `TVector2D.Rotate` addition on
`release/v1.10.0`. Windows x86-64 host, FPC 3.2.2 (Win64), Lazarus 4.8,
Python 3.13.

## Test builds

All four standard configurations build `TestRunner.lpr` with zero errors and
run the whole `-a` suite with **939 tests, 0 errors, 0 failures**:

| Build | Flags | Result |
| --- | --- | --- |
| normal | `-FcUTF8 -Fu../src` | 939 pass |
| optimized | `-O2` | 939 pass |
| runtime-checked | `-Cr -Co -Ct -Sa` | 939 pass |
| heap-traced | `-gh -gl` | 939 pass; **0 unfreed memory blocks** |

The heap-traced run reports `0 unfreed memory blocks : 0`, confirming the new
allocation-free `TVector2D.Rotate` value operation and no introduced leaks.

## Examples and documentation examples

- All 27 `examples/*.pas` compile and link (`build-examples.ps1`).
- The example-output gate verifies **8 contracts**, including the new
  `examples/12_geometry.pas` rotation workflow:
  `Example output checks passed: 8 contracts verified`.
- The documentation-example gate compiles/executes 23 Pascal fragments and
  verifies 22 output contracts:
  `Documentation example checks passed: 23 compiled ... 22 output contracts
  verified`.

## Release gates

| Gate | Result |
| --- | --- |
| `check_api_decision.py` | 2881 declarations, 13 domains, 21 alias reviews, 0 unresolved |
| `check_convergence.py` | manifest closed for 1.10.0; policies, final snapshot, roadmap agree |
| `check_numerical_evidence.py` | passed |
| `check_performance_evidence.py` | 14 rows, 13 comparisons |
| `check_portability_evidence.py` | passed (win64-x86_64 primary) |
| `check_workflow_qualification.py` | passed (3 workflows) |
| `check_migration_rehearsal.py` | 13 domains, 4 alias decisions, no deprecation warnings |
| `run_numerical_mutation.py` | 3 faults detected |
| `test_api_decision.py` / `test_api_snapshot.py` / `test_doc_examples.py` / `test_example_output.py` / `test_build_docs.py` / `test_built_docs.py` / `test_qualify_release.py` / `test_release_state.py` / `test_numerical_evidence.py` / `test_numerical_mutation.py` / `test_performance_evidence.py` / `test_portability_evidence.py` / `test_migration_rehearsal.py` / `test_workflow_qualification.py` / `test_convergence.py` | all pass |

## Qualification boundary

Exact Linux and Windows checksummed, network-isolated clean-archive release
candidate jobs remain mandatory before tagging; no local result is
generalized to a target that did not run in CI. The final 2.0 release
requires at least two 2.0 release-candidate cycles from tagged source and
offline documentation archives per the roadmap.