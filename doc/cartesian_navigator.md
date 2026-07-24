# Cartesian navigator

`CartesianNavigator` is a native Flutter overview-and-selection control for
Cartesian chart viewports. It renders one caller-supplied Line or Area series
over the complete X domain and controls every chart attached to the same
`ChartInteractionGroupController`.

The controlled charts can be Line, Area, Bar, Scatter, or Candlestick charts.
The navigator does not inspect or translate their series: the shared data-X
viewport is the family-neutral contract.

## Basic composition

Own and dispose one interaction-group controller in the host state, then give
it to both the detailed chart and navigator:

```dart
final interactionGroup = ChartInteractionGroupController();

Column(
  children: [
    Expanded(
      child: BravenChartPlus(
        series: [detailSeries],
        interactionGroupController: interactionGroup,
      ),
    ),
    CartesianNavigator(
      interactionGroupController: interactionGroup,
      overviewSeries: AreaChartSeries(
        id: 'overview',
        name: 'Overview',
        points: overviewPoints,
      ),
      fullDomain: const ChartXViewport(min: 0, max: 240),
      initialViewport: const ChartXViewport(min: 60, max: 120),
      snapPolicy: CartesianNavigatorSnapPolicy.interval(5),
    ),
  ],
)
```

The interaction group is the sole viewport authority. An already valid group
viewport wins over `initialViewport`; otherwise the navigator uses the initial
viewport and finally the complete domain. External controller writes update
the selection window, and local navigator changes update every synchronized
chart.

## Interaction

The selected window has three independent, accessible controls:

- drag the body to pan while preserving its span;
- drag the start or end handle to resize without crossing the opposite edge;
- focus any control and use Left/Right Arrow, or use its semantic increase and
  decrease actions.

All input paths use the same data-space reducer. `minimumSpan` prevents a
selection from collapsing. `livePreview` publishes continuously while a
gesture is active; disabling it keeps the local preview but publishes only the
committed result.

Snapping can preserve exact values, use a fixed interval, or use a strictly
ordered list of domain values. Ordered-value snapping uses binary lookup and is
appropriate for irregular timestamps or market sessions:

```dart
snapPolicy: CartesianNavigatorSnapPolicy.values(
  candles.map((point) => point.x),
),
behavior: const CartesianNavigatorBehavior(
  minimumSpan: 60 * 60 * 1000,
),
```

## Overview isolation

The internal overview chart deliberately opts out of shared cursor and
viewport synchronization. It therefore:

- always renders `fullDomain`;
- keeps an independent automatic Y range;
- does not emit tracking or cursor traffic;
- cannot become another viewport authority.

The caller supplies exactly one `LineChartSeries` or `AreaChartSeries` for the
overview. This keeps the generic component free of financial, categorical, or
family-specific summarization policy. Hosts may pre-aggregate a dense source
before constructing that series.

## Styling and accessibility

`CartesianNavigatorStyle` configures the selected fill and border, outside
mask, handles, hover/pressed/focus/disabled states, and geometry. Defaults are
resolved from the Material and chart themes. Painted handles remain compact,
while `handleHitWidth` defaults to a 48 logical-pixel pointer and touch target.

`enabled: false` preserves the current selection and renders a disabled state
without accepting pointer, keyboard, or semantic changes. Use `semanticLabel`
to describe the domain in application language.

## Controller and lifecycle rules

- The host owns and disposes `ChartInteractionGroupController`.
- Replacing `fullDomain` reconciles the current viewport into the new domain.
- An external viewport received during a local drag is remembered and applied
  after that gesture finishes.
- Pointer cancellation restores the pre-gesture or pending external viewport.
- The navigator's callbacks report local previews and commits; controller
  listeners remain the source for system-wide viewport state.

The public navigator replaces the earlier Candlestick showcase prototype that
used a draggable `RangeAnnotation`. That prototype remains useful as design
history, but the package contract is now one reusable Cartesian control.

## Resizable host panes

The navigator's selection handles resize the visible X domain. They do not set
the navigator widget's height. Vertical pane allocation belongs to the host:
overlay an accessible drag handle on each pane seam, then update their
`SizedBox` or flex constraints while retaining the same
`ChartInteractionGroupController`, chart controllers, and widget keys. An
overlay keeps the panes visually contiguous while allowing the handle to keep
a comfortably large hit target.

`CartesianNavigator` and `BravenChartPlus` both relayout from their current
constraints. No navigator-specific resizing API is required, and a host can
apply application-specific minimum heights without coupling that policy to
chart rendering. Keep live resize state inside the pane host so pointer deltas
only rebuild pane geometry rather than the page's charts and option controls.
The Technical Indicators showcase demonstrates this pattern between every
study pane and the navigator.

## Runnable examples

The showcase keeps navigation opt-in and places it where a full-domain summary
materially helps the example:

- Line — Synchronized controls three independent distance plots;
- Area — Forecast controls one continuous time domain;
- Bar — Categories snaps across a dense categorical axis;
- Scatter — Correlation uses a binned X-distribution overview while retaining
  the original unsorted points in the detail chart;
- Candlestick — Stock uses ordered-value snapping across irregular sessions;
- Interaction — Navigator lets developers change the source point count and
  compare drag/resize input with direct controller viewport commands;
- Live Stream — Live Navigator grows a retained overview while direct,
  frame-coalesced ingestion continues; moving the selection enters historical
  inspection and Return to live restores the rolling detail viewport;
- Gallery — Synchronized Cartesian provides the compact cross-family example.

These are compositions of the same public API, not special rendering paths.

## Live ingestion

`LiveStreamController` owns both ingest and viewport movement by default. When
the navigator must be the only viewport authority, keep the direct render path
and disable only that controller responsibility:

```dart
final viewport = ChartInteractionGroupController();
final live = LiveStreamController(
  seriesId: 'sensor',
  maxPoints: 1200,
  manageViewport: false,
);

BravenChartPlus(
  liveStreamController: live,
  interactionGroupController: viewport,
  series: [LineChartSeries(id: 'sensor', points: const [])],
);

CartesianNavigator(
  interactionGroupController: viewport,
  overviewSeries: AreaChartSeries(
    id: 'sensor-overview',
    points: live.points,
  ),
  fullDomain: retainedDomain,
  behavior: const CartesianNavigatorBehavior(
    allowExternalDomainGrowth: true,
  ),
);
```

The host decides whether new samples advance `viewport`, remain fixed while a
user inspects history, or return to the latest window. The live controller
continues buffering and painting samples in every mode.

For a smooth follow-latest host, listen to `dataRevision` and coalesce viewport
publication and bounded overview snapshots to a display frame. The signal is
an invalidation token, so the callback can read `oldestPoint`, `latestPoint`,
and `pointCount` in O(1). If full-history snapshots are intentionally slower,
use the diagnostics appropriate to the host and expect the overview itself to
present at that reduced cadence.
`allowExternalDomainGrowth` prevents a slower overview snapshot from clamping
an ahead-of-snapshot live viewport and publishing that stale clamp back to the
detail chart.
