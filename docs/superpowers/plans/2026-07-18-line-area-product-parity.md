# Line and Area Product Parity — Implementation Plan

**Original branch:** `feature/line-area-product-parity`
**Status:** Complete; PR #35 and continuation PR #37 merged
**Next work:** Sprint 8 is tracked in the
[product-parity roadmap](2026-07-18-line-area-product-parity-roadmap.md).

## Lane 1 — Core path motion

- [x] Add immutable public path-animation configuration to Line and Area series.
- [x] Add pure compatible-point transition helpers and unit coverage.
- [x] Add entrance/data-update controllers to `BravenChartPlus`.
- [x] Drive the standard `SeriesElement` render path with in-flight geometry.
- [x] Clip and interaction-gate entrance reveal at the element boundary.
- [x] Add generic controller replay while preserving radial replay.
- [x] Cover entrance, update, fallback, replay, and reduced motion with render-path tests.

## Lane 2 — Workbench and samples

- [x] Put Line and Area showcase charts in `BravenChartWorkbench`.
- [x] Preserve existing presets and add one focused Motion preset per family.
- [x] Add replay and target-data update actions.
- [x] Verify wide split resizing and compact chart/data switching.
- [x] Add example widget tests for both routes and responsive modes.

## Lane 3 — Quality gate

- [x] Format changed Dart files.
- [x] Run focused tests while iterating.
- [x] Run full package tests and static analysis.
- [x] Run example tests and a release web build.
- [x] Run `git diff --check` and inspect branch scope.
- [x] Launch a local web server and visually inspect Line and Area at wide and narrow sizes.
- [x] Leave the local route running for joint review.
- [x] Record review findings before any PR decision.

## Local review checkpoint

- Desktop Split mode was reviewed at 1440 x 1000 for both chart families. The
  chart pane retains the primary footprint, legends remain readable, and the
  data table uses explicit horizontal overflow where required.
- Compact Line and Area routes were exercised at 390 x 844 through widget
  tests without layout exceptions.
- The branch debug server is available on port 8097 with direct Motion/Split
  routes for joint review.
- Local visual review was accepted and PR #35 merged with green package-quality
  CI. Topology motion, identity continuity, and consolidated continuation E2E
  subsequently completed in Sprints 5-7 and merged through PR #37.
