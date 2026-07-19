# Synchronized Cartesian Charts Implementation Plan

**Status:** Local review approved; promotion in progress
**Roadmap:** Sprint 12 of Line and Area Product Parity
**Lane:** `feature/synchronized-cartesian-charts`
**Base:** `origin/master` after PR #45
**Design:** `../specs/2026-07-18-path-strokes-and-synchronized-charts-design.md`

## Outcome

Allow independently mounted Cartesian charts to share a semantic X cursor and
X-only viewport while preserving each chart's own Y domain, axes, annotations,
selection, tooltip, lifecycle, and artifact.

The proof surface is one compact stack containing Speed (Line), Elevation
(Area), and Heart rate (Area) over the same distance domain.

## Public contract

Add a caller-owned `ChartInteractionGroupController` and immutable participant
options. A `BravenChartPlus` opts into a group by receiving the controller and
may independently disable cursor or viewport synchronization.

The controller owns only transient coordination:

- shared cursor values are finite data-space X values, never widget offsets;
- shared viewport values are finite X min/max bounds;
- participant registration follows widget mount/update/dispose;
- broadcasts are re-entrancy guarded and deduplicated;
- detached and opted-out participants receive nothing; and
- disposal remains the caller's responsibility.

No synchronization state is encoded in `ChartDocument`, `ChartViewState`, or
Workbench presentation state.

## Rendering bridge

1. A local pointer, touch scrub, or keyboard cursor publishes data X.
2. The group sends that value to every cursor-enabled participant.
3. Each chart maps X through its current `ChartTransform` and plot rectangle.
4. The existing tracking renderer resolves local series intersections using
   local samples, interpolation, visibility, and Y axes.
5. Synchronized peers paint a vertical line and intersection markers without
   importing another chart's tooltip or selection state.
6. Clearing the source interaction clears the transient cursor everywhere.

Applying a synchronized cursor is paint-only. It must not regenerate elements,
invalidate chart documents, or alter durable point state.

The controller coordinates semantic data X, not parent layout. Vertically
stacked participants reserve identical horizontal axis gutters so equal data X
also resolves to one screen-space X coordinate. This keeps layout negotiation
out of the transient controller and preserves independent chart sizing.

## Viewport bridge

Local pan, zoom, reset, scrollbar, keyboard, and reveal operations publish the
resulting X bounds after the transform changes. Recipients restore only X min
and max while retaining their current Y min and max.

Externally applied bounds use a non-broadcasting path. This is the final loop
barrier in addition to controller-level re-entrancy protection. A successful
external viewport application advances the chart's view-state revision but
does not alter its effective document revision.

## Delivery slices

### Slice A — Controller and lifecycle

- Add controller, viewport value object, participant options, and registration.
- Cover broadcast, deduplication, opt-outs, detach, disposal, and re-entrancy.
- Export the public API.

### Slice B — Shared cursor

- Publish local mouse and touch data X from the render boundary.
- Map shared X inside each participant and paint local tracking intersections.
- Clear on exit, touch completion/cancel, focus loss, detach, and group change.
- Cover different widths, sample counts, interpolation modes, and Y domains.

### Slice C — X-only viewport

- Publish viewport changes after local transform updates.
- Apply synchronized bounds without changing participant Y bounds.
- Cover pan, zoom, reset, reveal, opt-out, and loop prevention.

### Slice D — Product surface

- Add one synchronized Speed/Elevation/Heart-rate preset to the Line page.
- Use aligned compact plots with local headings, units, and latest values.
- Retain the stack at compact widths and a minimum 48 px touch target.
- Add focused widget tests and direct-route browser review.

## Verification gates

- Controller and render-path tests for every contract above.
- Existing package and showcase suites remain green.
- Package and showcase analyzers are clean.
- Root and showcase release web builds pass.
- Public docs/navigation and pub.dev dry run remain release-ready.
- Wide and compact direct routes remain available for user pixel review before
  commit or PR promotion.

## Local review evidence

- Controller unit tests: 7 passed.
- Render-path synchronization widget tests: 3 passed.
- Full package suite: 1,982 passed.
- Full showcase suite: 162 passed.
- `flutter analyze lib`: clean.
- Showcase `flutter analyze lib test`: clean.
- Root-base and `/braven_charts/` release web builds: passed.
- Pub archive code validation: clean; the dry run reports only the expected
  uncommitted-worktree warning until this reviewed slice is committed.
- Pixel-alignment regression: reproduced an 11 px crosshair stagger caused by
  content-sized Y-axis gutters, then locked equal stack gutters and added a
  screen-space cursor assertion.
- Intersection regression: removed the synchronized-only nearest-Y override;
  markers now use the exact local path geometry and are asserted to remain on
  the shared data-X coordinate.
- Wide and 500 px compact browser layouts: reviewed locally.
- Review route: `http://127.0.0.1:8177/?page=line-charts&preset=synchronized`.
