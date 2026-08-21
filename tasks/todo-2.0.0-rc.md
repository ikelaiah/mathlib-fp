# 2.0.0 RC task list

## Task 1: Candidate metadata and API evidence — complete

**Acceptance criteria:** `VERSION`, package, layout, and candidate navigation agree on `2.0.0`; `1.10.0` remains latest published stable; generated 2.0 evidence matches frozen 1.10.0 API.

**Verification:** `python tools/update_api_snapshot.py --release 2.0.0` and focused API checks.

## Task 2: Candidate-promotion gate — complete

**Acceptance criteria:** the gate asserts target, predecessor, closed decisions, migration evidence, API consistency, and candidate/stable documentation state.

**Verification:** focused checker tests and `python tools/check_promotion_2_0.py`.

## Task 3: Migration and release documentation — complete

**Acceptance criteria:** documentation distinguishes no-change, preferred, compatibility, and actual-breaking paths; release notes are clearly candidate-only.

**Verification:** `python tools/check_docs.py` and documentation build.

## Task 4: Final qualification — complete

**Acceptance criteria:** relevant local gates pass and the diff excludes Pascal-source or historical-evidence changes.

**Verification:** release qualification driver where practical, `git diff --check`, and diff review.
