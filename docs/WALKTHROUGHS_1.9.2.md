# 1.9.2 clean-room walkthroughs

The 1.9.2 completion gate requires at least three walkthroughs by people who
did not implement the exercised feature. Automated tests cannot substitute for
this evidence, and maintainers must not invent participant records.

Participants can record a session through the
[1.9.2 beginner walkthrough form](https://github.com/ikelaiah/mathlib-fp/issues/new?template=beginner_walkthrough.yml).

## Walkthrough protocol

Each participant starts from a clean source archive and chooses a task from
the [beginner recipes](RECIPES.md). Without reading an implementation unit in
`src/`, they must:

1. find the task through the generated documentation search using problem
   words rather than a Pascal identifier;
2. compile and run the linked beginner program;
3. change one input while preserving a result whose correctness they can
   explain;
4. identify the relevant failure/status guidance; and
5. follow the advanced link far enough to explain when it replaces the simple
   call.

Record environment, elapsed time, route, observed result, confusion or failure,
and a public issue/report link in `walkthroughs-1.9.2.json`. A maintainer who
reviews a record must be different from its participant. The participant may
be anonymised in the repository, but the evidence link must let maintainers
confirm that one real person supplied one record.

## Release gate

Run this only after recording genuine sessions:

```text
python tools/check_walkthroughs.py
```

The release qualification driver runs the same check for release `1.9.2`. It
requires three distinct participants, successful correct results, no
implementation-unit reading, no implementation involvement in the exercised
feature, distinct evidence links, and a recorded independent reviewer.

An empty manifest is the honest initial state while the documentation change
is under review. Version 1.9.2 must not be described as completion-gate-passing
or released until this command succeeds with reviewed evidence.
