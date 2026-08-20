# Implementation plan: documentation information-architecture milestone

## Objective

Complete a documentation-only milestone before the next roadmap capability.
Make the maintained user documentation easy to find from the repository and
the versioned/offline site, while retaining every release, qualification,
provenance, and design record as traceable evidence.

This milestone changes documentation, documentation tooling, and release
process text only. It must not change public Pascal API, numerical behaviour,
package contents other than documentation paths, or the supported-target
contract.

## Why this is needed

`docs/` currently contains 26 user-facing guides and 74 release/evidence
records in a mostly flat directory. `docs/index.md` mixes its user landing
purpose with a long chronological release ledger; its release list also does
not lead with the current 1.10.0 release. The guides are good, but users must
know their filenames or search through historical material to reach them.

The repository already has a dependency-free static-site builder, link
checker, versioned Pages deployment, offline ZIP, and checked runnable
examples. Preserve those strengths and make the information architecture
explicit rather than replacing the publishing system.

## Information architecture decision

Organise by reader intent. One document has one primary purpose.

```text
docs/
  index.md                         # concise documentation home
  start/                           # first-use learning path
    index.md
    beginner-guide.md
    recipes.md
    cheatsheet.md
  guides/                          # problem/domain/task guidance
    index.md
    tasks.md
    domains/
    topics/
    migration/
  reference/                       # exact stable contracts and inventories
    index.md
    api/
    capabilities.md
    conventions.md
  project/                         # project-level, current policies/status
    index.md
    roadmap.md
    support.md
    health.md
    governance.md
    feedback.md
  releases/                        # immutable release handoff records
    index.md
    1.10.0/
    1.9.9/
    ...
  design/                          # existing design records; no new ADR scheme
  assets/
```

### Classification rules

- **Start**: a newcomer can copy, run, and understand a first program.
  `BEGINNER_GUIDE`, `RECIPES`, and `CHEATSHEET` belong here.
- **Guides**: choose an algorithm, understand a domain, complete a common
  task, or migrate application code. Domain pages, focused algebra/modelling/
  DSP/interchange guides, `TOP_TASKS`, and the two user migration guides
  belong here.
- **Reference**: exhaustive/API-like material and the stable capability and
  convention inventories. Generated API reference and its machine-readable
  snapshot remain paired.
- **Project**: current project promises, contribution/support policies, health,
  feedback, and roadmap. These are not tutorials or release evidence.
- **Releases**: release notes, PR notes, qualification, workflow qualification,
  migrations rehearsals, manifests, audits, evidence reports, and their JSON
  inputs are co-located under the release to which they belong.
- **Design**: preserve the present `docs/design/` records and their historical
  names. An ADR migration is explicitly out of scope for this milestone.

Keep the beginner guide and recipes separate: the former teaches the Free
Pascal/data/ownership concepts that explain a program, while the latter answers
“which entry point solves my task?”. Keep the cheatsheet compact and retain the
broader task index for problem discovery.

## Canonical navigation

`docs/index.md` becomes a short, task-oriented landing page, in this order:

1. **New here?** First program, beginner guide, recipes, and examples.
2. **I know my task.** Task index, domain guides, and algorithm-selection
   guides.
3. **I need exact behaviour.** API reference, capabilities, support matrix,
   and API conventions.
4. **Project and maintenance.** Roadmap, governance, health, contribution and
   feedback routes.
5. **Release history and evidence.** One link to `releases/index.md`, which
   leads with the current release and groups all historical records by version.

The README remains a self-contained first compilation path, but its
documentation links use the new canonical paths. It must not become a second
long-form beginner guide.

## Compatibility and publishing decisions

- Treat the new nested Markdown paths as canonical source and site URLs.
- Add a small, versioned redirect manifest for the existing public *user-guide*
  URLs. Extend `tools/build_docs.py` to generate redirect pages in the current
  release site and include them in the offline archive. Do not generate aliases
  for every historical evidence filename.
- Update every repository-internal link to a canonical path; redirects are for
  outside bookmarks, not a substitute for maintenance.
- The versioned Pages workflow keeps building historical tags unchanged. The
  builder must recognise both the old root release-note location (historical
  tags) and the new nested current/future location.
- Release record filenames no longer encode the version once their enclosing
  directory does. For example, `docs/releases/1.10.0/release-notes.md` and
  `docs/releases/1.10.0/qualification.md` are clearer than root-level
  `RELEASE_NOTES_1.10.0.md` and `QUALIFICATION_1.10.0.md`.

## Dependency graph

```text
path map + redirect manifest
          |
          +--> move/update Markdown and JSON links
          |             |
          |             +--> documentation landing and section indexes
          |
          +--> builder/checker support and tests
                        |
                        +--> CI, Pages, offline archive, release tooling
                                      |
                                      +--> README, roadmap, changelog,
                                           contributing and releasing text
```

## Task list

### Task 1: Define and test path conventions

**Description:** Add a single documentation-layout/redirect manifest (JSON is
preferred because the existing documentation toolchain is Python) that names
canonical locations, current-release records, and legacy user-guide aliases.
Centralise path lookup in the documentation tooling instead of spreading new
path literals across checks.

**Acceptance criteria:**

- [ ] The manifest has a documented schema and names every moved Markdown/JSON
  artifact exactly once.
- [ ] It maps the current release's release notes, PR notes, qualification, and
  workflow qualification paths.
- [ ] It lists aliases only for moved user-facing guide URLs and rejects
  duplicate, missing, escaping, or cyclic targets.
- [ ] Focused tests cover the old historical layout and the new nested layout.

**Verification:** `python tools/test_build_docs.py` plus a new focused manifest
test; `python tools/check_docs.py`.

**Dependencies:** None.

**Estimated scope:** Medium.

### Task 2: Make the builder and validators layout-aware

**Description:** Update `tools/build_docs.py`, `tools/check_docs.py`,
`tools/check_built_docs.py`, and their tests to use the layout manifest.
Generate accessible redirect HTML for aliases, retain searchable canonical
pages, and assert the user landing/navigation routes in source and built HTML.

**Acceptance criteria:**

- [ ] Historical tagged documentation builds without modification using the
  old root release-note convention.
- [ ] The current nested layout builds a complete site and offline archive.
- [ ] Redirect targets exist, preserve fragments where applicable, do not
  leave the built-site root, and are excluded from duplicate search results.
- [ ] The source and generated-site checks assert links from the documentation
  home to Start, Guides, Reference, Project, Releases, and the current release.
- [ ] Link, anchor, fence, search-index, release-identity, and offline archive
  checks remain green.

**Verification:** focused Python tests; `python tools/check_docs.py`; build a
standalone release site and run `python tools/check_built_docs.py --site ...
--release 1.10.0`.

**Dependencies:** Task 1.

**Estimated scope:** Large; land tool tests before implementation.

### Task 3: Reorganise user documentation and create navigation pages

**Description:** Move start, guide, reference, and project documents to the
canonical paths; add short section index pages; replace `docs/index.md` with
the reader-intent landing page. Update all links in the moved documents and
the README/examples without rewriting established technical content.

**Acceptance criteria:**

- [ ] A new user reaches a compile-ready example through the Start route in at
  most two documentation clicks after the README link.
- [ ] A task-oriented user reaches `guides/tasks.md`, then the corresponding
  domain/algorithm page without navigating release records.
- [ ] The API reference, capability inventory, support matrix, roadmap, and
  release archive each have one discoverable canonical home.
- [ ] `BEGINNER_GUIDE`, `RECIPES`, `CHEATSHEET`, `TOP_TASKS`, all domain/topic
  guides, both current user migration guides, and the current project pages
  appear exactly once at their canonical paths.
- [ ] Existing learning-route headings and runnable example links still meet
  `check_docs.py` requirements.

**Verification:** `python tools/check_docs.py`; manually inspect the generated
home, start, task-index, and reference pages in the built offline site.

**Dependencies:** Task 2.

**Estimated scope:** Large; split into Start/Guides and Reference/Project commits.

### Task 4: Archive release handoff and evidence records by version

**Description:** Move every release-owned Markdown and JSON artifact into its
release directory; add a concise release archive index that shows release
notes first and evidence second. Update historical release links in the
roadmap, health/support/capability pages, and the release notes themselves.

**Acceptance criteria:**

- [ ] Every current root-level `RELEASE_NOTES_*`, `PR_NOTES_*`,
  `QUALIFICATION_*`, `WORKFLOW_QUALIFICATION_*`, evidence/audit/manifest,
  API-snapshot/diff, and release-owned JSON file has one version-owned home.
- [ ] Each release archive page identifies the release, release notes,
  qualification record, and any additional evidence; no evidence is discarded
  or rewritten as user guidance.
- [ ] Frozen API baseline bytes remain unchanged after relocation; all tools
  that inspect them use the manifest path.
- [ ] Machine-readable paths embedded in `capabilities.json` and related
  validators are updated together with their artifacts.
- [ ] The roadmap's completed-release table links to archived release notes
  and does not describe root-level names as a required permanent layout.

**Verification:** `python tools/check_docs.py`; relevant evidence/convergence
checks; built-site link check; `git diff --check`.

**Dependencies:** Tasks 1-3.

**Estimated scope:** Large; migrate one release group at a time, newest first.

### Task 5: Update repository and release-process documentation/configuration

**Description:** Update all documentation consumers and release-facing text to
refer to canonical paths and the new navigational model. This includes CI and
Pages configuration, qualification tooling, README, CHANGELOG, ROADMAP,
CONTRIBUTING, RELEASING, example README, support/governance/health/capability
references, and any release-identification checks.

**Acceptance criteria:**

- [ ] CI, Pages deployment, release qualification, and offline docs generation
  use layout-aware path helpers or manifest entries, not stale root paths.
- [ ] `README.md` points to the new Start, task-finding, documentation-home,
  current release-notes, and support paths.
- [ ] `CHANGELOG.md` records the documentation IA milestone under
  **Unreleased** without presenting it as a numerical/API release.
- [ ] `ROADMAP.md` records this as a completed pre-capability documentation
  milestone or explicitly marks it as the final documentation-readiness gate
  before the next capability; its documentation/discoverability commitments
  name the new navigation model.
- [ ] `CONTRIBUTING.md` and `RELEASING.md` show only commands and paths that
  work from a clean archive with the reorganised layout.

**Verification:** repository link check, documentation build/check, clean
working-tree review of all changed workflow/configuration paths.

**Dependencies:** Tasks 2-4.

**Estimated scope:** Medium.

### Task 6: End-to-end release-quality verification and documentation review

**Description:** Verify the current and preserved historical sites, inspect
the generated offline archive, and review the path migration for accidental
content loss or broken external-facing routes.

**Acceptance criteria:**

- [ ] Current and all preserved historical documentation sites build.
- [ ] The current offline archive opens at the new documentation home, has a
  functioning search index, and contains alias redirect pages.
- [ ] All Markdown links/anchors/fences, generated links, and release identity
  checks pass.
- [ ] No public API/code/package behaviour changed beyond documentation file
  paths and documentation tooling.
- [ ] A final review confirms no beginner/user guidance remains uniquely
  discoverable through PR notes, qualification notes, or release notes.

**Verification:** repository CI-equivalent documentation commands, relevant
qualification driver documentation phase, `git diff --check`, and manual
offline-site smoke review.

**Dependencies:** Tasks 1-5.

**Estimated scope:** Medium.

## Checkpoints

### Checkpoint A: Tooling ready (after Tasks 1-2)

- [ ] Old historical sources and the new nested-layout fixture build.
- [ ] Canonical/alias validation fails safely on invalid paths.
- [ ] No docs are moved until the toolchain and tests support the destination.

### Checkpoint B: User routes complete (after Task 3)

- [ ] Documentation home visibly prioritises Start, task finding, reference,
  project material, then release evidence.
- [ ] Beginner and task routes work in source Markdown and built HTML.

### Checkpoint C: Archive and repository integration complete (after Tasks 4-5)

- [ ] No stale root-path reference remains outside explicitly supported
  historical-layout compatibility code/tests.
- [ ] Release/evidence material is discoverable but cannot dominate the home.

### Checkpoint D: Ready for next roadmap capability (after Task 6)

- [ ] All documentation/release checks pass.
- [ ] The human reviews the generated documentation home and offline archive.
- [ ] The next capability milestone starts from the approved canonical layout.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A bulk move breaks many relative links | High | Make tooling layout-aware first; migrate one content group at a time; run source and built-link checks after each group. |
| Historical Pages versions fail because they retain the flat layout | High | Maintain backward-compatible old-root lookup; exercise old-layout fixtures/tests before moving current docs. |
| Redirects hide stale internal links or pollute search | Medium | Require canonical internal links; validate aliases; omit redirect pages from the search index. |
| Immutable evidence is accidentally altered | High | Move rather than rewrite; preserve byte checks for frozen API artifacts and retain current evidence validators. |
| README becomes stale or duplicates tutorials | Medium | Keep one compile-ready quick start in README; link onward to canonical Start pages. |
| Scope expands into redesigning every technical guide | Medium | Preserve guide content and headings; this milestone changes placement, indexes, and links only. |
| The roadmap misrepresents the milestone as a capability release | Medium | Record it expressly as documentation/discoverability readiness before the next capability, with no API claim. |

## Out of scope

- Adding or changing a numerical algorithm, public API, package dependency, or
  supported platform claim.
- Rewriting established domain/algorithm content or changing runnable examples
  except for relative documentation links.
- Replacing the custom dependency-free documentation builder, adding a new site
  generator, or redesigning the visual theme.
- Retrofitting every tagged historical source tree to the new source layout.
- Introducing an ADR framework or moving existing design records.

## Recommended execution model

Use **Terra** for the implementation. This is a multi-file migration with
Python tooling, CI/release compatibility, and a large link graph; Terra's
slower but steadier verification loop is a better match. Luna is well suited
to a bounded follow-up such as link-inventory review, redirect-fixture tests,
or a final documentation consistency audit after Terra lands the structural
change.
