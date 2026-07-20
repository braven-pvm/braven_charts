# Releasing braven_charts

Releases are label-driven: merging a pull request into `master` that carries
the **`release`** label publishes the package to pub.dev and deploys the
showcase to GitHub Pages. No credentials are stored in the repository —
publishing authenticates with pub.dev via GitHub's OIDC tokens
(trusted publishing).

For the pre-release validation checklist (archive hygiene, screenshots,
pana, showcase smoke tests) see [doc/release_checklist.md](../doc/release_checklist.md).

## How to cut a release

1. Create a release branch **in this repository** (convention:
   `release/0.x.y` — fork branches will not work, the tagger skips them)
   that bumps `version:` in `pubspec.yaml` and adds the CHANGELOG entry.
2. Open a PR into `master` and apply the **`release`** label (before
   merging — the label set is read at merge time).
3. Merge. Everything else is automatic:

```
PR merged into master with label `release`
        │  release.yml (pull_request: closed)
        ▼
waits for "Package quality" to pass on the merge commit
        ▼
creates annotated tag v<pubspec version> on the merge commit → pushes it
        │  (tag pushed with GITHUB_TOKEN — triggers nothing, by GitHub design)
        └─ gh workflow run publish.yml --ref refs/tags/v<version>
                    ▼
publish.yml, running ON the tag ref
        ├─ preflight: tagged commit must be on master + Package quality green
        ├─ publish: OIDC publish via dart-lang/setup-dart reusable workflow
        └─ deploy-showcase: builds example/ and deploys to GitHub Pages
```

The regular master-push showcase deploy also fires on the merge. Both
deploys build the same commit; the tag-path deploy job joins the
`github-pages` concurrency group so they serialize rather than collide.
(For back-to-back releases the last deploy to finish wins — if the
showcase looks stale, re-run the "Deploy showcase" workflow once.)

## One-time setup (pub.dev admin — requires an uploader account)

**This must be completed before merging the first labeled release PR** —
otherwise the tag gets created but the publish is rejected, and you'll
need the manual re-dispatch fallback after fixing the configuration.

On <https://pub.dev/packages/braven_charts/admin> → **Automated publishing**:

1. **Enable publishing from GitHub Actions.**
2. Repository: `braven-pvm/braven_charts`.
3. Tag pattern: `v{{version}}`.
4. Tick **"Enable publishing from `workflow_dispatch` events"** — the
   automated path dispatches the publish workflow on the tag ref rather
   than relying on a tag-push event (tags pushed with `GITHUB_TOKEN`
   cannot trigger workflows). This checkbox is in the admin UI even
   though the dart.dev docs only describe the tag-push flow.
5. Leave "Require GitHub Actions environment" unchecked (the pipeline is
   deliberately fully automatic; tightening later only requires creating
   an environment, ticking that box, and passing `environment:` to the
   reusable workflow in `publish.yml`).

Optional but recommended: validate the whole chain once with a throwaway
prerelease version (e.g. `0.10.0-dev.1` — the tag patterns and pub.dev
both accept it, and prerelease versions don't become the pub.dev
"latest") before relying on it for a real release.

Repo-side prerequisites (already configured):

- The `release` label exists.
- The `github-pages` environment allows deployments from `v*` tags in
  addition to `master` (Settings → Environments → github-pages →
  deployment branches and tags).

## Package page content (README, images, screenshots)

pub.dev has no separate content artifact — everything on the package page
comes from the **published archive** of the version being viewed (default:
latest stable; prereleases are never the default view):

| Package page element | Source | Updates when |
| --- | --- | --- |
| Readme tab (text, image list, captions) | `README.md` in the archive | **Next publish only** |
| Changelog tab | `CHANGELOG.md` in the archive | Next publish only |
| Example tab | `example/` in the archive | Next publish only |
| Screenshot gallery + package thumbnail | pubspec `screenshots:` files in the archive | Next publish only |
| **Pixels of README images** | `raw.githubusercontent.com/.../master/doc/screenshots/...` (absolute URLs) | **Immediately on any master push** |
| API reference | dartdoc run by pub.dev on the upload | Next publish only |

Consequences:

- **Refreshing an existing image** (same filename, better pixels): commit
  the regenerated file under `doc/screenshots/` to master — every
  version's Readme tab shows it immediately, no release needed.
- **Changing README text/structure, captions, adding/removing images, or
  changing the `screenshots:` gallery**: must ship in a release. Fold it
  into the release PR so content and version publish together.
- Because README images track master, the live page can briefly show
  imagery ahead of the published version — acceptable at this release
  cadence; avoid regenerating media that showcases unreleased features
  long before their release.

Constraints: max 10 pubspec screenshots, each ≤ 4 MB (converted to WebP
server-side), first one doubles as the package thumbnail. Media
regeneration commands and README composition rules live in
[doc/release_checklist.md](../doc/release_checklist.md)
(`python tool/capture_showcase_media.py`).

## Guards and failure modes

| Situation | Behavior |
| --- | --- |
| PR merged without the `release` label | Nothing happens (normal merge). |
| Label applied but tag `v<version>` exists on a **different** commit | release.yml aborts with a clear error — bump the version first. |
| Tag exists on **this** merge commit (previous run pushed it but failed later) | Re-running the release run resumes: skips tag creation, re-dispatches publish. |
| Package quality red on the merge commit | release.yml refuses to tag (60-minute poll window). |
| Tag pushed but dispatch failed | Re-run the failed release run (idempotent), or dispatch manually (below). |
| Tagged commit not on master, or CI not green on it | publish.yml preflight refuses to publish — applies to hand-pushed tags too. |
| Tag version ≠ pubspec version | Impossible via automation (tag is derived from pubspec); a hand-pushed mismatched tag is rejected by pub.dev at upload ("Expected tag ..."). |
| Version already published on pub.dev | pub.dev rejects the upload; published versions are immutable. Recovery: retract within 7 days and/or publish a bumped version. |
| Publish succeeded but showcase deploy failed | Re-run the `deploy-showcase` job, or run the "Deploy showcase" workflow manually. |

## Manual fallbacks

- **Forgot the label before merging:** push the tag yourself — a tag
  pushed with personal credentials *does* trigger `publish.yml` (the
  preflight still requires the commit to be on master with green CI):

  ```bash
  git tag -a v0.10.0 -m "Release v0.10.0" <merge-commit>
  git push origin v0.10.0
  ```

  Caveat: the push trigger patterns don't match build-metadata versions
  (`v0.10.0+1`) — for those, push the tag and then use the dispatch below.

- **Re-run publishing for an existing tag** (e.g. after fixing the
  pub.dev admin configuration):

  ```bash
  gh workflow run publish.yml --ref refs/tags/v0.10.0
  ```

- Fully manual `dart pub publish` from a clean checkout keeps working
  unless "manual publishing" is disabled on the pub.dev admin page.

## Security notes

- Publishing needs no long-lived secrets; the OIDC token pub.dev accepts
  is scoped to this repository, the `v{{version}}` tag pattern, and the
  exact version in `pubspec.yaml`.
- Every publish path — label-driven or hand-pushed tag — passes the
  preflight gates: the tagged commit must be reachable from `master` and
  have a green Package quality run. A dangling or unreviewed commit
  cannot be published by tagging it.
- pub.dev pins the repository ID after the **first successful automated
  publish** — from then on, automated publishing self-disables if the
  repository is deleted, recreated, or transferred. Until that first
  publish, the lock is not yet engaged.
- Anyone with **triage** access can apply labels, and `master` is not
  branch-protected. Residual exposure is therefore "someone with write
  access can release what is already green on master". If the
  contributor circle grows, add a `pub.dev` GitHub environment with
  required reviewers (see step 5 above), protect `master`, and consider
  a repository ruleset restricting who may create `v*` tags.
