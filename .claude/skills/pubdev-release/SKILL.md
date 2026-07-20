---
name: pubdev-release
description: Use when asked to release/publish braven_charts to pub.dev, cut a version, or update the pub.dev package page — README structure, screenshots, images, changelog, or "release and also update the images". Also use when deciding whether a package-page change needs a new version published.
---

# Releasing braven_charts to pub.dev

## Overview

Releases are label-driven and fully automated (runbook:
`docs/releasing.md`). The pub.dev package page has **no separate content
artifact** — it renders the published archive of the latest stable
version, with ONE exception: README image pixels load live from
`raw.githubusercontent.com/.../master/doc/screenshots/`.

**Core principle: decide first whether the request needs a publish, a
master commit, or both.**

## Decision table

| User asks for | What it takes |
| --- | --- |
| "Release to pub.dev" | Release PR: bump `version:` in pubspec + retitle CHANGELOG section → apply **`release`** label → merge. Automation does the rest (tag → OIDC publish → showcase deploy). |
| "Refresh/fix an image" (same filename) | Regenerate → commit to master. Page updates live. **No release needed.** |
| "Update README structure / captions / add images / change screenshots gallery" | Archive-frozen content — must go **in the release PR** (or wait for the next one). |
| "Release AND update images/structure" | One release PR: regenerate media + edit README/pubspec `screenshots:` + version bump + changelog, then label and merge. |

## Release PR checklist (in order)

1. Branch `release/0.x.y` **in this repo** (fork branches are skipped by
   the tagger) from a pulled master.
2. If media/structure changes: regenerate media
   (`python tool/capture_showcase_media.py --capture <target>`; targets
   and README composition rules in `doc/release_checklist.md`), update
   the README grid and pubspec `screenshots:`.
3. Bump `version:` in pubspec.yaml; retitle the CHANGELOG `## Unreleased`
   (or `-dev`) section to the version.
4. Validate: every `screenshots:` path exists and is ≤ 4 MB (max 10
   entries; first = package thumbnail); README image URLs resolve;
   `dart pub publish --dry-run` is clean (CI also runs it).
5. Open PR to master, apply the **`release` label before merging**
   (labels are read at merge time). Merging fires the whole chain.
6. Verify: "Release tagger" then "Publish to pub.dev" runs green; version
   on pub.dev; showcase deployed.

## Gotchas

- Published versions are **immutable** — a bad publish can only be
  retracted (7 days) or superseded, never replaced. Get the archive
  content right in the PR.
- `-dev.N` prereleases never become pub.dev "latest" and default
  constraints never resolve to them — use one to shake down pipeline
  changes.
- Tag is derived from pubspec (`v{{version}}`); never hand-manage
  versions/tags separately.
- README images track **master**, not the release — don't land media for
  unreleased features long before their release ships.
- The page shown by default is the latest **stable** — publishing a
  prerelease does not refresh what visitors see.

## Common mistakes

- Editing README text and expecting pub.dev to update without a publish
  (only image *pixels* update live).
- Labeling the PR after merging — the tagger only reads labels present at
  merge time (recovery: `docs/releasing.md` → Manual fallbacks).
- Adding an 11th screenshot or a >4 MB GIF — pub.dev rejects/drops them.
