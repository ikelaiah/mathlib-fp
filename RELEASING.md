# Releasing mathlib-fp

Use this checklist for every mathlib-fp release.

## Before tagging

- [ ] Freeze the public API and review exception, rounding, random-state, and
  ownership semantics in the reference docs.
- [ ] Confirm the version matches in `packages/lazarus/mathlib_fp.lpk`, the
  README badge, and `CHANGELOG.md`.
- [ ] Confirm the release section has the publication date and **Unreleased**
  contains only changes made after that release.
- [ ] Confirm CI passes with FPC 3.2.2 on Linux and Windows and builds with the
  minimum supported Lazarus 4.8 on Windows.
- [ ] Confirm CI compiles and runs every example and builds the Lazarus package.
- [ ] Run normal, optimized, runtime-checked, and heap-traced test builds; verify
  the heap-traced run reports zero unfreed blocks.
- [ ] Run `tools/check_performance_evidence.py`; require every exact
  correctness/allocation/storage gate and review same-run and matching-host
  timing movements without treating machine-specific timings as hard limits.
- [ ] Confirm the Lazarus package and complete test suite compile and pass for
  both Win64 and Win32.
- [ ] Install `packages/lazarus/mathlib_fp.lpk` in a clean Lazarus profile and
  compile a small consumer project.
- [ ] Check all Markdown links and compare documented public names with the
  declarations in each unit's `interface` section.
- [ ] Build the current release under its versioned static-site path, rebuild
  each listed older version from its tag, and verify the root page identifies
  the current release without replacing an older directory.
- [ ] Verify every output-producing runnable documentation fence and every
  release-facing example output contract, including final success markers.
- [ ] Run milestone-specific automated evidence. For 1.9.3, regenerate the
  exact API snapshot/reference, require a clean second generation, run
  `python tools/test_api_decision.py` and
  `python tools/check_api_decision.py`, then compile/run every selected common
  program with `python tools/check_doc_examples.py --compiler fpc`. Confirm no
  `src/` interface diff and review the exact source/behavior/warning/packaging
  consequences before the checksummed clean-archive qualification.
- [ ] For 1.9.5, run `python tools/test_performance_evidence.py` and
  `python tools/check_performance_evidence.py --compiler fpc`; confirm every
  published claim maps to a checked row, investigate every `review` comparison,
  and retain the generated `performance-results.json` with qualification.
- [ ] Build the deterministic offline documentation ZIP, verify its SHA-256,
  extract it without network access, and compare its `release.json`, examples,
  signatures, and limitations with repository Markdown.
- [ ] Review the MIT license, security contact route, repository URL, and
  supported-version policy.
- [ ] Confirm the exact commit to tag has green `linux` and `windows` CI jobs;
  do not tag an earlier local commit or an unmerged branch.

## GitHub repository check

- [ ] Set the repository description, website, and topics in the **About**
  panel so the project can be discovered.
- [ ] Confirm GitHub detects the MIT license and that Issues are enabled if
  they are the supported bug-reporting route.
- [ ] Under **Settings → Security → Code security**, enable private
  vulnerability reporting and verify that the **Report a vulnerability** form
  linked from `SECURITY.md` opens.
- [ ] Protect the default branch and require the Linux and Windows CI checks
  if the repository's collaboration model permits it.
- [ ] Confirm the issue forms and pull-request template render correctly.

Recommended commands:

```bash
git diff --check

cd tests
mkdir -p lib/release lib/optimized lib/checked lib/heap
fpc -B -FcUTF8 -Fu../src -FUlib/release TestRunner.lpr
./TestRunner -a --format=plain

fpc -B -O2 -FcUTF8 -Fu../src -FUlib/optimized TestRunner.lpr
./TestRunner -a --format=plain

fpc -B -Cr -Co -Ct -Sa -FcUTF8 -Fu../src -FUlib/checked TestRunner.lpr
./TestRunner -a --format=plain

fpc -B -gh -gl -FcUTF8 -Fu../src -FUlib/heap TestRunner.lpr
./TestRunner -a --format=plain

cd ..
sh ./build-examples.sh
for file in examples/*.pas; do
  "./example-bin/$(basename "${file%.pas}")" > /dev/null
done
python tools/check_example_output.py

python tools/build_docs.py --release X.Y.Z \
  --output build-temp/docs-site/X.Y.Z \
  --offline-archive build-temp/mathlib-fp-docs-X.Y.Z.zip
python tools/check_built_docs.py \
  --site build-temp/docs-site/X.Y.Z --release X.Y.Z

python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc \
  --work-dir build-temp/performance

lazbuild --build-all packages/lazarus/mathlib_fp.lpk
```

## Publish

1. On the validated release branch, finalize publication metadata: move the
   release entries out of **Unreleased**, add the date, update the README badge
   and current-release text, remove release-candidate wording, and update
   `SECURITY.md` to the maintained release line. Commit these changes and
   confirm the branch CI remains green.
2. Merge the validated release branch into the default branch. Do not tag the
   release branch.
3. Confirm the resulting exact default-branch commit has green required CI.
4. Open **Releases → Draft a new release** and create tag `vX.Y.Z` from that
   exact commit, replacing `X.Y.Z` with the version being published.
5. Use `mathlib-fp X.Y.Z` as the release title and copy that version's
   changelog entries into the release notes.
6. Mark it as the latest release, leave **pre-release** unchecked, and publish.
   GitHub automatically provides source `.zip` and `.tar.gz` downloads for the
   tag; no separately generated source archive is needed. The documentation
   workflow deploys the versioned site and attaches the offline HTML ZIP and
   checksum to the published release.

## Verify the published release

- [ ] Download and extract one of GitHub's source archives.
- [ ] Build the README quick start from the extracted archive, not the working
  tree.
- [ ] Confirm the archive includes `src/`, `docs/`, `examples/`, package
  metadata, tests, and the license, but no compiler output.
- [ ] Install `packages/lazarus/mathlib_fp.lpk` from a clean environment.
- [ ] Download the offline documentation ZIP, verify its adjacent SHA-256, and
  confirm its landing page identifies the release and links older versions.
- [ ] Mark only the maintained release lines as supported in `SECURITY.md`.
