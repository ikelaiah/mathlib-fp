# 1.9.2 review notes

## Review boundary

This change implements only the active 1.9.2 beginner-learning-path
milestone. It adds documentation, runnable examples, output/search checks, and
an independent-walkthrough evidence gate. It does not change any declaration
in the frozen public 1.9 API snapshot and does not begin 1.9.3 API-decision or
later trust, performance, portability, migration, beta, or freeze work.

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
5. Refuse to qualify 1.9.2 until three genuine, reviewed, independent clean-
   room walkthrough records pass `tools/check_walkthroughs.py`.

## Compatibility evidence

`tools/test_api_snapshot.py` and `tools/check_docs.py` continue to compare all
source `interface` sections with the unchanged 1.9.0 snapshot. The change adds
no public type, algorithm family, convenience overload, default, deprecation,
storage rule, or implicit conversion.

## Completion-gate status

All locally automatable gates can be run from a clean archive. The independent
human walkthrough manifest intentionally starts empty; maintainers must record
and review three real sessions before release qualification can pass. An empty
manifest is not completion evidence and this document does not claim that the
1.9.2 completion gate has passed.
