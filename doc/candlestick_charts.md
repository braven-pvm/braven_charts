# Candlestick charts

Braven Charts provides Candlestick as a first-class Cartesian series. It uses
the same axes, annotations, viewport, crosshair, controller, themes, portable
artifacts, native data table, and generated Source surface as Line, Area, Bar,
and Scatter while retaining typed open-high-low-close values.

Open the runnable [Candlestick showcase](https://braven-pvm.github.io/braven_charts/?page=candlestick-charts)
to prototype the options in the Chart/Data/Split/Source Workbench.

The showcase is also the family test surface. Its presets cover balanced price
action, sustained trend, volatility, gaps and doji, event annotations,
accessible direction cues, 2,000-source density grouping, and a synchronized
price/volume/navigator composition. The options rail exposes the mounted
chart's data profile, geometry, direction and point colours, selection/focus
colours, tracking and tooltip theme, motion, density grouping, axes, overlays,
legends, and standard Cartesian behavior.

## Basic chart

Use `CandlestickDataPoint` rather than reducing OHLC data to a generic `(x, y)`
pair. Values must be finite, X values must be strictly increasing, `high` must
be at least every body value, and `low` must be at most every body value.

```dart
final candles = <CandlestickDataPoint>[
  CandlestickDataPoint(
    x: 0,
    open: 101,
    high: 106,
    low: 99,
    close: 104,
    timestamp: DateTime.utc(2026, 7, 14),
    label: '14 Jul',
  ),
  CandlestickDataPoint(
    x: 1,
    open: 104,
    high: 105,
    low: 98,
    close: 100,
    timestamp: DateTime.utc(2026, 7, 15),
    label: '15 Jul',
  ),
];

BravenChartPlus(
  series: [
    CandlestickChartSeries(
      id: 'price',
      name: 'Price',
      unit: 'USD',
      points: candles,
    ),
  ],
  xAxisConfig: XAxisConfig(
    label: 'Trading session',
    labelFormatter: (value) {
      final index = value.round().clamp(0, candles.length - 1);
      return candles[index].label!;
    },
  ),
  yAxis: YAxisConfig(
    position: YAxisPosition.right,
    label: 'Price',
    unit: 'USD',
  ),
)
```

The default presentation uses hollow rising bodies and filled falling bodies.
Doji values use a minimum visible body height so equal open and close values do
not disappear.

## Geometry and colour

`CandlestickChartStyle` controls the physical mark rather than the data:

```dart
const CandlestickChartStyle(
  bodyFillMode: CandlestickBodyFillMode.filled,
  bodyWidthFactor: 0.76,
  minBodyWidth: 1,
  maxBodyWidth: 16,
  bodyBorderWidth: 1,
  wickWidth: 1,
  bodyCornerRadius: 2,
  minimumBodyHeight: 1.5,
  showBodyBorder: true,
  showWicks: true,
)
```

Direction colours normally come from `ChartTheme.candlestickTheme`; a series
style may override rising, falling, and doji body, border, and wick colours.
One observation can use `CandlestickPointStyle` for an explicit event colour.
Direction, not colour, remains available to tooltips, semantics, tables, and
source data.

## Time spacing

Candlestick remains numeric Cartesian and does not own a market calendar.
Choose the X values that match the question:

- use an elapsed timestamp or day number to show real weekend and session gaps;
- use `0, 1, 2, ...` to place trading sessions at equal ordinal spacing; and
- keep the original `timestamp` and `label` on every point in either mode so
  interaction and exported data retain the calendar identity.

Applications own exchange calendars, timezone conversion, corporate-action
adjustment, and market-data fetching. These are intentionally outside the
renderer.

## Tracking and selection

Candlestick tracking snaps to a real candle; it never interpolates a synthetic
OHLC value between samples.

```dart
const InteractionConfig(
  enableZoom: true,
  enablePan: true,
  enableSelection: true,
  crosshair: CrosshairConfig(
    enabled: true,
    mode: CrosshairMode.vertical,
    displayMode: CrosshairDisplayMode.tracking,
    interpolateValues: false,
    showTrackingTooltip: true,
    showIntersectionMarkers: true,
    showCoordinateLabels: true,
  ),
  tooltip: TooltipConfig(enabled: true),
  keyboard: KeyboardConfig(enabled: true),
)
```

The tracking payload exposes open, high, low, close, absolute change,
percentage change, direction, timestamp, and source indices. Pointer selection,
keyboard focus, the native data table, and restored artifacts share the same
`ChartPointRef(seriesId, pointIndex)` identity.

The showcase exposes each feedback layer independently so combinations can be
tested without mistaking one layer for another:

- **Crosshair OHLC panel** shows every tracked series at the active X value.
- **Candle hover card** shows one directly hit candle and can follow the cursor.
- **Pinned OHLC summary** follows the hovered or selected candle and falls back
  to the latest candle. It can be a fixed overlay in any plot corner or a
  native, draggable `TextAnnotation` embedded in the chart canvas.
- **Crosshair axis values** are the compact X/Y labels attached to the axes.
- **Crosshair intersection dot** is only a marker and does not add another
  tooltip or value label.

The showcase defaults to the crosshair panel alone. The candle hover card and
pinned summary are opt-in, avoiding overlapping OHLC cards while still allowing
every combination to be exercised. Price axes, pinned summaries, crosshair and
point tooltips, metric pills, and native Workbench OHLC/change cells display two
decimal places. The optional whole-chart focus outline is off by default; candle
focus and selection styling remain available independently.

The pinned summary resolves across the entire active X continuum, including
the space between candle bodies. An in-between X selects the nearest complete
trading session, with an exact midpoint tie selecting the earlier session.
Open, high, low, and close are never interpolated into a synthetic candle;
continuous companion series such as a moving average still interpolate at the
same cursor X through normal Line tracking.

The showcase gives both pinned-summary presentations one appearance model:
background and opacity, border colour and width, text and accent colours,
corner radius, inner padding, and text size. These colour controls reuse
`AnnotationColorPalette`, including clear, selected-swatch toggle, custom
colour, opacity, and recent-colour behavior. Clearing or toggling off the
background or border produces a genuinely transparent surface or stroke; it
does not silently restore the adaptive theme fallback. The overlay starts with
a compact 168-pixel card, 8-pixel padding, and 11-pixel detail text, with the
size controls available when more emphasis is required.

The annotation presentation is a real `TextAnnotation.rich` entry in the
chart's annotation collection. It therefore participates in native annotation
rendering, dragging, portable artifacts, and generated Source. Its `position`
is chart-canvas screen space, by design: dragging moves the card within the
plot, but the card is not anchored to a price or session and does not move with
pan or zoom. Use a point annotation when the label must remain attached to a
specific candle instead.

## Entrance and data-update motion

Candlestick entrance reveals ordered marks through the normal renderer.
Compatible series replacements interpolate OHLC values without changing hit
testing or final geometry.

```dart
const CandlestickAnimationStyle(
  mode: CandlestickAnimationMode.reveal,
  staggerFraction: 0.8,
  dataUpdateMode: CandlestickDataUpdateAnimationMode.interpolate,
)
```

Reduced-motion preferences and zero theme durations render the final frame
immediately. A replacement must keep the series ID, point count, and ordered X
identity to interpolate; incompatible topology changes fall back safely.

For a live current interval, use `LiveStreamController.upsertLatestCandlestick`
to revise the last candle in place. A greater X appends the next interval while
the controller preserves its configured bounded capacity.

## Dense data and OHLC grouping

Viewport culling avoids materializing marks outside the visible domain. When
many visible samples would become thinner than a useful candle, opt into
density grouping:

```dart
CandlestickChartSeries(
  id: 'price',
  points: candles,
  densityGrouping: const CandlestickDensityGrouping(
    enabled: true,
    targetGroupWidth: 7,
    minimumPointsPerGroup: 2,
  ),
)
```

Each rendered group uses the first open, maximum high, minimum low, and last
close. Group boundaries are globally aligned so pan and zoom do not make
candles flicker between identities. Tracking, hit testing, selection, and
semantics retain every represented source index.

Grouping is presentation only. `series.points`, Chart/Data/Split, copy, CSV,
artifacts, hydration, and generated Dart remain source-sized and lossless.

## Overlays and stock composition

One Candlestick series can share its plot with ordinary Line, Area, and Scatter
overlays, such as a moving average or event markers. V1 rejects a second
Candlestick series and same-plot Bar series so financial marks do not silently
overlap with ambiguous layout.

Candlestick also accepts the normal Cartesian annotation collection. Range,
threshold, and point annotations retain their ordinary IDs, styling, and
series/point references; no financial-only annotation API is required.

A complete stock screen is a composition, not a second renderer:

1. a Candlestick chart with optional Line/Area indicators;
2. a separate Bar chart for volume with its own Y scale; and
3. an Area navigator whose selection drives the shared X viewport.

Use `ChartInteractionGroupController` to share data-X cursor and viewport state
between the price and volume panes. Set
`ChartInteractionGroupOptions(synchronizeViewport: false)` on the full-domain
navigator so its own view does not collapse to the selected range.

Technical indicators are application transforms that produce normal chart
series. Braven Charts does not calculate SMA, EMA, Bollinger bands, trading
signals, or portfolio analytics.

## Workbench, artifacts, and AI input

`BravenChartWorkbench` requires no Candlestick-specific fork. Its native table
includes timestamp, open, high, low, close, change, change percentage,
direction, and metadata. Split is resizable and Source emits typed
`CandlestickChartSeries` and `CandlestickDataPoint` construction.

When a portable formatter descriptor resolves to an application formatter,
provide the same `ChartFormatterRegistry` to `ChartTableOptions.formatters`
and `ChartDartSourceOptions.formatters`. Data and Source then hydrate against
one binding set instead of Source reporting a false unregistered-formatter
warning. Source may still note callbacks that cannot be represented in
portable Dart; those are explicit generation limitations, not hydration
errors.

Portable documents declare Candlestick and any enabled style, animation, or
density-grouping capabilities. Older runtimes fail closed rather than treating
OHLC as a generic line. Hydration reconstructs typed points. Tool-driven input
must provide explicit OHLC arrays; generic `(x, y)` data cannot invent missing
financial values.

## Performance contract

Permanent tests cover 50,000 ordered source candles, 5,000 visible marks,
1,000-candle animated revisions, nearest-X crosshair lookup, pan/zoom cache
invalidation, grouped projection, live latest-candle updates, and three-pane
cursor/viewport fanout. Geometry, paint, and controller p95 gates target one
16.67 ms frame on the established benchmark environment.

## V1 boundaries

Core V1 deliberately excludes:

- Heikin-Ashi, Renko, point-and-figure, and OHLC tick-bar renderers;
- automatic technical indicators and trading signals;
- market-data clients, brokerage integration, and exchange calendars;
- split/dividend adjustment and timezone databases; and
- a package-owned stock-dashboard widget.

These can be built from typed candles, ordinary overlay series, annotations,
and synchronized Cartesian panes without weakening the core chart contract.
