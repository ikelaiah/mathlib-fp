# Releasing mathlib-fp

Use this checklist for the 1.2.0 first public release and later releases.

## Before tagging

- [ ] Freeze the public API and review exception, rounding, random-state, and
  ownership semantics in the reference docs.
- [ ] Confirm the version matches in `fpmake.pp`, the Lazarus `.lpk`, the
  README badge, and `CHANGELOG.md`.
- [ ] Confirm the release section has the publication date and **Unreleased**
  contains only changes made after that release.
- [ ] Confirm CI passes with FPC 3.2.2 on Linux and Windows.
- [ ] Confirm CI compiles every example, and test the Lazarus package manually.
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
- [ ] Enable private vulnerability reporting so the route documented in
  `SECURITY.md` is available.
- [ ] Protect the default branch and require the Linux and Windows CI checks
  if the repository's collaboration model permits it.

Recommended commands:

```bash
git diff --check

cd tests
mkdir -p lib/release
fpc -B -FcUTF8 -Fu../src -FUlib/release TestRunner.lpr
./TestRunner -a --format=plain

cd ../examples
mkdir -p lib/release
for file in *.lpr; do
  fpc -B -FcUTF8 -Fu../src -FUlib/release "$file"
done
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
- [ ] Install the Lazarus package from a clean environment.
- [ ] Mark only the maintained release lines as supported in `SECURITY.md`.
