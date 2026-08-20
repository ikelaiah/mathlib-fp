# mathlib-fp 1.9.9 PR notes

## Change boundary

This release branch completes the 1.9.9 convergence handoff without touching
`src/`. The public interface digest of every unit must remain identical to the
frozen 1.9 snapshot; the API snapshot check enforces that.

## What changed

- Added the closed [`capability-manifest-1.10.0.json`](../../capability-manifest-1.10.0.json)
  and its [human-readable explanation](../1.10.0/capability-manifest.md).
- Added the final [`api-snapshot-final-1.9.9.json`](../../api-snapshot-final-1.9.9.json)
  and [`API_SNAPSHOT_FINAL_1.9.9.md`](api-snapshot-final.md), and closed
  the routing language in the 1.9.3 candidate and diff documents.
- Added the [provenance audit](provenance-audit.md)
  ([`provenance-audit-1.9.9.json`](../../provenance-audit-1.9.9.json)) covering all
  50 `src/` units.
- Added the [governance policies](../../project/governance.md) and updated `SECURITY.md`
  (security support window) and `CONTRIBUTING.md` (new-domain gate).
- Added `tools/convergence.py`, `tools/check_convergence.py`, and
  `tools/test_convergence.py` (20 focused unit tests).
- Integrated the convergence gate into `tools/qualify_release.py`, `ci.yml`
  (Linux, Windows, and checksummed clean-archive steps),
  `release-qualification.yml`, and `RELEASING.md`.
- Advanced release identity to 1.9.9: `CHANGELOG.md`, `README.md`,
  `docs/versions.json`, `docs/capabilities.json`, `docs/index.md`,
  `docs/SUPPORT.md`, the Lazarus package version, `check_docs.py`, the
  roadmap, and the documentation workflow.

## Review checklist

- [ ] The closed manifest accepts exactly the roadmap 1.10.0 scope:
      `TVector2D.Rotate` plus the no-deprecation decision; everything else is
      explicitly deferred.
- [ ] The final snapshot diff is empty across source/behaviour/warnings/
      packaging, and no `src/` interface digest changed.
- [ ] Every unsupported capability-inventory family has a matching deferral
      record.
- [ ] Policies state testable commitments, not aspirations; the checker fails
      when the documents disagree.
- [ ] CI runs `python tools/test_convergence.py` and
      `python tools/check_convergence.py` on Linux and Windows and from the
      checksummed clean archive.

## Verification commands

```bash
python tools/test_convergence.py
python tools/check_convergence.py
python tools/check_docs.py
python tools/test_release_state.py
git diff --check
```
