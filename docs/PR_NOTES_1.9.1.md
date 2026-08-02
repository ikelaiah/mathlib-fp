# 1.9.1 review notes

## Review boundary

This change implements only the active 1.9.1 stabilisation and documentation
delivery milestone. The public 1.9 snapshot is unchanged. It does not add the
beginner recipe set planned for 1.9.2 or any later API, numerical-trust,
performance, portability, migration, or 2.0-freeze work.

## Reviewable changes

1. Correct the confirmed seeded-bootstrap low-bit sampling defect and retain a
   power-of-two-length regression.
2. Make every output-producing runnable documentation fence declare checked
   output, and verify release-facing example statuses and final markers.
3. Generate release-identified, searchable HTML, a default version index, and
   a deterministic offline ZIP/checksum from the same Markdown.
4. Publish 1.9.0 and 1.9.1 side by side through the documentation workflow so
   a new deployment cannot silently replace the older release.
5. Add the focused 1.9 feedback form and clean-archive qualification workflow.

## Compatibility evidence

`python tools/test_api_snapshot.py` compares every `interface` section with
`docs/public-api-1.9.json`; no snapshot regeneration is part of this change.
The bootstrap correction changes only private sampling behavior that could
return a materially wrong interval. Seeded calls remain deterministic and do
not touch process-global random state.

## Completion-gate mapping

The [qualification report](QUALIFICATION_1.9.1.md) records defect triage,
five-minute first use, web/offline/repository release identity, and all required
build/test/package/archive configurations. The output-contract manifests make
the documentation and example claims mechanical release gates.
