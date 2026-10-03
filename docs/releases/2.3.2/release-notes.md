# mathlib-fp 2.3.2

Version 2.3.2 is a documentation patch release. It makes mathlib-fp's current
scope boundaries visible in the Pascal numerical-library comparison and
retains the 2.3.1 numerical runtime without changes to algorithms or public
APIs.

## Documentation

- Added a concise limitations section covering compiler focus, execution
  backends, precision and selected specialist workflows.
- Linked the limitations to the capability inventory and described them as
  release scope, not as criticism of other libraries or a roadmap promise.
- Preserved the v2.3.1 versioned documentation site as it moves into the
  historical release set.
- Carried forward the unchanged numerical-evidence catalogue from 2.3.1 and
  recorded its provenance.

The runtime qualification and supported target matrix continue to be based on
the unchanged 2.3.0 implementation; see the
[qualification record](../2.3.0/qualification.md) and
[workflow evidence](../2.3.0/workflow-qualification.md).
