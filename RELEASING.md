# Releasing mathlib-fp

Use this checklist for the 1.2.0 first public release and later releases.

## Before tagging

- [ ] Freeze the public API and review exception, rounding, random-state, and
  ownership semantics in the reference docs.
- [ ] Confirm the version matches in `packages/lazarus/mathlib_fp.lpk`, the
  README badge, and `CHANGELOG.md`.
- [ ] Confirm the release section has the publication date and **Unreleased**
  contains only changes made after that release.
- [ ] Confirm CI passes with FPC 3.2.2 on Linux and Windows.
- [ ] Confirm CI compiles and runs every example and builds the Lazarus package.
- [ ] Run normal, optimized, runtime-checked, and heap-traced test builds; verify
  the heap-traced run reports zero unfreed blocks.
- [ ] Compile and run `benchmarks/BenchmarkRunner.lpr` with `-O3`; record results
  for comparison without treating machine-specific timings as pass thresholds.
- [ ] Confirm the Lazarus package and complete test suite compile and pass for
  both Win64 and Win32.
- [ ] Install `packages/lazarus/mathlib_fp.lpk` in a clean Lazarus profile and
  compile a small consumer project.
- [ ] Check all Markdown links and compare documented public names with the
  declarations in each unit's `interface` section.
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

cd ../examples
mkdir -p lib/release
for file in *.lpr; do
  fpc -B -FcUTF8 -Fu../src -FUlib/release "$file"
  "./${file%.lpr}" > /dev/null
done

cd ..
mkdir -p benchmarks/lib/release
fpc -B -O3 -FcUTF8 -Fusrc -FUbenchmarks/lib/release \
  -FEbenchmarks/lib/release benchmarks/BenchmarkRunner.lpr
./benchmarks/lib/release/BenchmarkRunner

lazbuild --build-all packages/lazarus/mathlib_fp.lpk
```

## Publish

1. Merge the release commit into the default branch and confirm its required
   CI checks are green.
2. Open **Releases → Draft a new release** and create tag `v1.2.0` from that
   exact commit.
3. Use `mathlib-fp 1.2.0` as the release title and copy the 1.2.0 changelog
   entries into the release notes.
4. Mark it as the latest release, leave **pre-release** unchecked, and publish.
   GitHub automatically provides source `.zip` and `.tar.gz` downloads for the
   tag; no separately generated source archive is needed.

## Verify the published release

- [ ] Download and extract one of GitHub's source archives.
- [ ] Build the README quick start from the extracted archive, not the working
  tree.
- [ ] Confirm the archive includes `src/`, `docs/`, `examples/`, package
  metadata, tests, and the license, but no compiler output.
- [ ] Install `packages/lazarus/mathlib_fp.lpk` from a clean environment.
- [ ] Mark only the maintained release lines as supported in `SECURITY.md`.
