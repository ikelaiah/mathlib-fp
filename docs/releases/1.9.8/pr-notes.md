# chore(release): complete v1.9.8 representative workflow qualification

## Purpose

Turn the roadmap's 1.9.8 representative-workflow claims into executable,
archive-owned evidence while preserving the frozen 1.9 public interface.

## Change boundary

- Add three maintained multi-domain end-to-end workflow programs and a bundled
  sensor fixture.
- Add a standard-library Python contract validator/checker and regression tests.
- Publish the machine-readable workflow manifest and a human guide.
- Integrate the checker into CI and release qualification.
- Advance release identity and current documentation to 1.9.8.
- Do not change a `src/*.pas` interface or implementation, add a dependency, or
  add a public algorithm family.

## Decisions

1. Express numerical expectations as named `line_prefix`/`minimum`/`maximum`
   bounds parsed from deterministic workflow output, not exact floating-point
   strings, so qualification is bounded rather than bit-fragile.
2. Verify determinism by running each workflow twice from an isolated work
   directory and byte-comparing output and exported artifacts, not by comparing
   against a separately maintained golden file.
3. Record host/compiler observations in generated qualification output; the
   manifest holds only stable, host-independent contracts.
4. Keep desirable new algorithm families out of 1.9.8; no workflow required a
   new public API.

## Review focus

- Correctness: workflows assert results, diagnostics, and deterministic export;
  the checker validates every path against the manifest.
- Architecture: qualification tooling remains outside the numerical runtime;
  no new unit, dependency, or public symbol is introduced.
- Security: the checker reads local JSON as untrusted structured data and runs
  only repository-owned programs compiled locally.
- Performance: release runtime paths are unchanged; workflow programs are
  bounded and compile only during validation.
- Documentation: manifest, guide, changelog, README, support/releasing guidance,
  release notes, and roadmap agree on the 1.9.8 boundary.

## Verification

```bash
python tools/test_workflow_qualification.py
python tools/check_workflow_qualification.py --compiler fpc
python tools/test_example_output.py
python tools/check_docs.py
```

The complete release gate is:

```bash
python tools/qualify_release.py --release 1.9.8 --compiler fpc \
  --lazbuild lazbuild
```
