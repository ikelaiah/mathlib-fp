# 2.0.0 stable publication task list

## Task 1: Stable promotion contract — complete

**Acceptance criteria:** the checker accepts published 2.0.0 metadata and
rejects candidate metadata after finalization.

**Verification:** `python tools/test_promotion_2_0.py` and
`python tools/check_promotion_2_0.py`.

## Task 2: Active release records — complete

**Acceptance criteria:** all active release navigation, notes, and
qualification records identify 2.0.0 as published stable and cite the RC
qualification without altering historical evidence.

**Verification:** `python tools/check_docs.py` and documentation build checks.

## Task 3: Final validation and publication

**Acceptance criteria:** normal CI and final release workflows pass for the
finalization commit and published `v2.0.0` tag.

**Verification:** local release gates, GitHub Actions, and published release
artifacts.
