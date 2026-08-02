# 1.9.2 review notes

## Review boundary

This change implements only the active 1.9.2 beginner-learning-path
milestone. It adds documentation, runnable examples, output/search checks, and
an automated clean-archive beginner-journey gate. It does not change any
declaration in the frozen public 1.9 API snapshot and does not begin 1.9.3
API-decision or later trust, performance, portability, migration, beta, or
freeze work.

## Reviewable changes

1. Put the double-real, simple allocating route before generic implementation
   details and expert destination/workspace controls.
2. Give every stable domain a beginner route, common-task choice, exact
   contract/failure links, allocation/precision note, and tested advanced
   example.
3. Add a newcomer guide for arrays, zero-based indexing, interface lifetimes,
   callbacks, options, statuses, exceptions, copies, and precision.
4. Add task recipes for all families named by the 1.9.2 roadmap and make the
   common-problem search phrases mechanical checks.
5. Qualify first use mechanically from a checksummed clean archive: verify
   problem-oriented search, all beginner and advanced links, compile/run every
   beginner program, compare claimed output, and audit public declarations.

## Compatibility evidence

`tools/test_api_snapshot.py` and `tools/check_docs.py` continue to compare all
source `interface` sections with the unchanged 1.9.0 snapshot. The change adds
no public type, algorithm family, convenience overload, default, deprecation,
storage rule, or implicit conversion.

## Completion-gate status

Every 1.9.2 gate is deterministic and can run from a clean archive without
external participation, accounts, reports, services, or network access. The
release driver checks documentation structure and declarations, compiles and
runs all published beginner programs, compares claimed output, builds the
searchable versioned site, checks problem phrases and links, and verifies the
offline archive before qualification can pass.
