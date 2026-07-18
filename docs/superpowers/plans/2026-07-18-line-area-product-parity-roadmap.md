# Line and Area Product Parity — Sprint Roadmap

**Branch:** `feature/line-area-product-parity`
**PR:** #35
**Merge policy:** Keep the PR open and unmerged until every sprint is complete,
the consolidated E2E gate passes, and the user gives final merge approval.

## Sprint 1 — Motion and workbench foundation

**Status:** Complete

- Public opt-in entrance and compatible data-update motion for Line and Area.
- Canonical artifact persistence and controller replay.
- Shared Chart/Data/Split workbench on both chart-family pages.
- Motion presets, responsive layouts, and controller lifecycle regression.
- Local pixel review, package/showcase verification, release build, and green
  PR CI.

## Sprint 2 — Flagship runtime hardening

**Status:** Complete

- Prove reveal behavior across linear, bezier, monotone, and stepped paths.
- Prove multi-axis transforms use stable target bounds throughout motion.
- Prove zero-duration themes render the final state synchronously.
- Prove controller-fed streaming tails retain their dedicated animation and do
  not also trigger path interpolation or reveal.
- Retain the radial data-transition runtime introduced on `master` while path
  transitions are active in the same package build.

## Sprint 3 — Public package and media parity

**Status:** Complete

- Add packaged Line/Area motion and workbench guidance under `doc/`.
- Update the API reference, feature matrix, root README, and example README.
- Refresh release screenshots and direct links so public claims show the new
  workbench and Motion compositions rather than legacy surfaces.
- Verify every public route and publication asset against a release build.

## Sprint 4 — Consolidated E2E and merge readiness

**Status:** In progress

- Run full package and showcase tests and analyzers from a clean tree.
- Build the release web app and validate the pub.dev archive.
- Exercise Line and Area Chart/Data/Split, resizing, preset switching,
  annotations, multi-axis normalization, entrance replay, data updates,
  reduced motion, compact fallback, and direct routes in the browser.
- Check browser console output, PR scope, generated docs, screenshots, and CI.
- Record residual risks and request final merge approval. Do not merge as part
  of the E2E run without that approval.
