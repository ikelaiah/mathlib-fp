# PR notes: 1.9.7 migration and compatibility rehearsal

## Purpose

Turn the roadmap's 1.9.7 migration claims into executable, archive-owned
evidence while preserving the frozen 1.9 public interface.

## Change boundary

- Add two all-domain consumer projects and one focused alias/package consumer.
- Add a standard-library Python contract validator/checker and regression tests.
- Publish the machine-readable rehearsal, human migration guide, external
  conceptual mappings, and final alias decision list.
- Integrate the checker into CI and release qualification.
- Advance release identity and current documentation to 1.9.7.
- Do not change a `src/*.pas` interface or implementation, add a dependency,
  introduce a compatibility package, or copy third-party numerical code.

## Decisions

1. Retain all four pressure/velocity aliases in place. The rehearsal proves
   they are exact, useful focused imports with no hidden package dependency;
   visual consolidation alone is not a deprecation reason.
2. Keep candidate-2.0 examples on declarations already shipped in 1.9.7. They
   demonstrate conventions, not an unreleased binary surface.
3. Describe NumLib and LMath/DMath mappings at the mathematical/task level and
   require semantic-difference plus unsupported-case notes for every mapping.
4. Store stable claims in `migration-rehearsal-1.9.7.json` and host/compiler
   observations in generated qualification output.

## Review focus

- Correctness: consumers assert results, diagnostics, alias identity, clone/
  ownership behavior, zero-based indexing, and deterministic replay.
- Architecture: migration tooling remains outside the numerical runtime; the
  main package retains its existing unit set and sole FCL dependency.
- Security: external mappings are documentation only; the checker reads local
  JSON/XML as untrusted structured data and runs no downloaded code.
- Performance: release runtime paths are unchanged; rehearsal programs are
  bounded and compile only during validation.
- Documentation: API decision data, generated reference, domain guide,
  changelog, README, support/releasing guidance, and roadmap agree.

## Verification

```bash
python tools/test_migration_rehearsal.py
python tools/check_migration_rehearsal.py --compiler fpc
python tools/test_api_decision.py
python tools/check_api_decision.py
lazbuild --build-all packages/lazarus/mathlib_fp.lpk
```

The complete release gate is:

```bash
python tools/qualify_release.py --release 1.9.7 --compiler fpc \
  --lazbuild lazbuild
```
