# Candlestick Cartesian Chart — Research and Product Design

**Date:** 2026-07-19  
**Status:** Implementation active; Slice 1 foundation complete locally  
**Coordinate family:** Cartesian  
**Depends on:** `doc/chart_family_integration.md`

## Executive decision

Candlestick becomes a first-class built-in Cartesian series in
`BravenChartPlus`. It is not a standalone stock-chart renderer and it is not a
decorated Bar series.

The product is split into two explicit layers:

1. `CandlestickChartSeries` owns OHLC data, candle geometry, painting,
   interaction, animation, artifacts, native table projection, generated Dart,
   and Workbench support.
2. A stock-style composition demonstrates range presets, a navigator, optional
   volume, ordinal session spacing, and shared viewport control using normal
   Braven Cartesian charts and controllers.

This gives Candlestick the same axes, annotations, viewport, controller, and
Workbench contract as Line, Area, Bar, and Scatter without forcing
stock-specific UI into the renderer.

## Research basis

### What established chart systems agree on

- Highcharts defines a candle as one time/X value plus open, high, low, and
  close. The body spans open-to-close and the wicks span the remaining
  high-to-low range. Its default visual convention distinguishes falling and
  rising candles through separate body and line colours, with rising bodies
  transparent by default.
- TradingView Lightweight Charts also treats Candlestick as an OHLC time
  series. It exposes independent rising/falling body, border, and wick colours,
  and represents absent samples as whitespace rather than inventing a price.
- Syncfusion Flutter implements `CandleSeries` inside its Cartesian chart. It
  maps X, low, high, open, and close independently and exposes width, spacing,
  border, opacity, rounded corners, and equal-value indication.
- Plotly likewise accepts parallel X/open/high/low/close fields and composes a
  date axis and range slider around the candlestick trace.

Primary sources:

- [Highcharts Candlestick chart](https://www.highcharts.com/docs/stock/candlestick-chart)
- [Highcharts Candlestick data API](https://api.highcharts.com/highstock/series.candlestick.data)
- [Highcharts Candlestick series API](https://api.highcharts.com/highstock/series.candlestick)
- [Syncfusion Flutter Candle chart](https://help.syncfusion.com/flutter/cartesian-charts/chart-types/candle-chart)
- [TradingView supported series](https://tradingview.github.io/lightweight-charts/docs/series-types)
- [TradingView Candlestick data](https://tradingview.github.io/lightweight-charts/docs/api/interfaces/CandlestickData)
- [TradingView Candlestick style options](https://tradingview.github.io/lightweight-charts/docs/api/interfaces/CandlestickStyleOptions)
- [Plotly JavaScript Candlestick charts](https://plotly.com/javascript/candlestick-charts/)

### What belongs outside the candle renderer

Highcharts describes its navigator as a small chart showing the whole dataset,
with its own series and axes. Its range selector is UI that applies
preconfigured or manually entered date bounds. This supports implementing both
features as chart composition and viewport commands rather than candle paint
logic.

Highcharts also groups dense OHLC data by taking the first open, maximum high,
minimum low, and last close for a group. Grouping is based on available pixel
width. This is an aggregation layer; the Workbench must continue to preserve
the raw source candles.

Relevant sources:

- [Highcharts Navigator](https://www.highcharts.com/docs/stock/navigator)
- [Highcharts Range selector](https://www.highcharts.com/docs/stock/range-selector)
- [Highcharts Data grouping](https://www.highcharts.com/docs/stock/data-grouping)
- [Highcharts Candlestick grouping API](https://api.highcharts.com/highstock/series.candlestick.dataGrouping)

### Time spacing is a real product choice

Financial series have two valid horizontal domains:

- **Elapsed time:** nights, weekends, and missing intervals consume their real
  duration.
- **Ordinal sessions:** observations are equally spaced and market closures do
  not consume screen width.

Highcharts Stock defaults to an ordinal X axis, while TradingView explicitly
separates timestamp ranges from logical bar-index ranges. Braven must not hide
this choice inside Candlestick geometry.

- [Highcharts ordinal X axis](https://api.highcharts.com/highstock/xAxis.ordinal)
- [TradingView time-scale ranges](https://tradingview.github.io/lightweight-charts/docs/time-scale)

The initial API therefore keeps `x` as the actual Cartesian coordinate and
retains `timestamp` as semantic time. An application can use epoch milliseconds
for elapsed-time spacing or an ordinal index for equal session spacing. The
stock composition will provide the timestamp-to-ordinal mapping and date-label
formatting needed for the latter.

## Repository findings

### The existing family boundary is explicit

`doc/chart_family_integration.md` correctly states that extending
`ChartSeries` is insufficient. A built-in family must cover model validation,
rendering, interaction, artifacts, hydration, table semantics, Dart source,
Workbench, showcase, documentation, and release tests.

The current implementation confirms that boundary:

- `ChartSeries` and `ChartDataPoint` transport one Y value.
- `DataConverter.computeDataBounds()` normally derives Y bounds from
  `point.y`; only Bar has a specialized multi-value branch.
- `DataConverter.seriesToElements()` creates the Cartesian `SeriesElement`,
  whose paint, hit, focus, and marker dispatch is explicit by series subtype.
- `ChartDataHit` exposes one primary formatted value plus family-specific
  auxiliary values.
- `ChartSeriesDocumentCodec`, `ChartDocumentHydrator`,
  `ChartDartSourceGenerator`, and `ChartSourceCaptureAdapter` enumerate every
  built-in family.
- `ChartTableModel` has generic Cartesian long/wide projections and a dedicated
  radial projection. Generic `(x, y)` rows would lose OHLC meaning.
- `chart_tool_schema.dart` and `ChartConfigBuilder` enumerate the built-in
  series available to the agentic input surface.
- The Workbench is already family-neutral after the mounted chart can produce a
  complete effective document.

### Reuse and non-reuse

Reuse these existing foundations:

- `ChartLayoutKind.cartesian` and `ChartTransform`;
- numeric/category X axes and multi-Y-axis binding;
- grid, legend, annotations, preview, theme, and viewport infrastructure;
- `ChartInteractionGroupController` for stock composition synchronization;
- controller point identity, focus, selection, and Workbench mounting;
- inline point/column artifact storage and point-extension transport.

Do not force Candlestick through `BarChartSeries`, `BarGeometry`, or bar
composition. A candle has two body endpoints plus two wick endpoints, no
baseline, no stack, and no category grouping semantics. Reusing Bar would make
bounds, stacking, hit testing, transitions, and tables incorrect.

## Public model

### Typed datum

Add a dedicated immutable point type:

```dart
final class CandlestickDataPoint extends ChartDataPoint {
  const CandlestickDataPoint({
    required double x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
    this.candlestickStyle,
  }) : super(
         x: x,
         y: close,
         timestamp: timestamp,
         label: label,
         metadata: metadata,
       );

  final double open;
  final double high;
  final double low;
  final double close;
  final CandlestickPointStyle? candlestickStyle;
}
```

`y == close` is a deliberate compatibility anchor. Generic viewport identity,
annotations that target a point, and existing callbacks retain a meaningful
primary value, while every candlestick-aware surface uses the typed OHLC
fields. The constructor and decoder enforce that equality; callers never set
`y` independently.

An elapsed-time convenience factory may map a `DateTime` to UTC epoch
milliseconds. Ordinal session charts continue to supply an ordinal `x` and the
real `timestamp` separately.

### Series

```dart
final class CandlestickChartSeries extends ChartSeries {
  CandlestickChartSeries({
    required super.id,
    super.name,
    required List<CandlestickDataPoint> points,
    super.metadata,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.candlestickStyle = const CandlestickChartStyle(),
    this.animation = const CandlestickAnimationStyle(),
  }) : super(points: points, isXOrdered: true);

  final CandlestickChartStyle candlestickStyle;
  final CandlestickAnimationStyle animation;
}
```

The public series is always X ordered. It exposes typed access to its candles
without weakening the base `ChartSeries` contract.

### Style surface

The first release should expose useful choices without copying every competing
API:

- rising, falling, and doji body fill;
- rising, falling, and doji border colour;
- rising, falling, and doji wick colour;
- body border width and wick width;
- show/hide body border and wicks;
- body width factor plus minimum and maximum logical-pixel widths;
- optional body corner radius;
- hollow-rising versus filled-body presentation;
- minimum visible body height / equal-value indication;
- optional per-point body, border, and wick overrides.

Defaults belong in a `CandlestickTheme` attached to `ChartTheme`, with nullable
series overrides. Rising/falling state must never be communicated by colour
alone: the default light theme uses a hollow rising body and filled falling
body, and doji remains a visible horizontal mark.

### Direction semantics

- rising: `close > open`;
- falling: `close < open`;
- doji: `close == open`.

Names and tooltip copy use rising/falling rather than bull/bear, avoiding the
inconsistent naming seen across libraries.

## Validation contract

Construction, artifact hydration, and AI input all apply the same rules:

1. X, open, high, low, and close must be finite.
2. `high >= max(open, close)` and `low <= min(open, close)`.
3. `high >= low`.
4. X values must be strictly increasing and unique.
5. Empty series are valid and render the normal empty state.
6. Invalid candles fail closed with an index-specific diagnostic. Values are
   never reordered or clamped silently.
7. A single-point series is valid.
8. Multiple Candlestick series in one plot are rejected in v1.
9. Line, Area, and Scatter overlays are allowed. Bar is excluded from the same
   plot in v1; volume belongs in a synchronized pane.

The one-candle restriction can be revisited after table, legend, selection, and
overlap semantics are proven.

## Geometry and paint

### Candle geometry

Create `lib/src/rendering/candlestick_geometry.dart` with a pure calculator
that resolves, for each visible source point:

- source point index and X center;
- body rectangle or doji line;
- upper and lower wick segments;
- rising/falling/doji state;
- paint bounds and expanded semantic/hit bounds.

Y bounds use every valid candle's low and high, never just close. X edge
padding includes half the maximum resolved candle body width.

Body width uses a robust nominal X interval from adjacent valid points rather
than the mean of the entire dataset. The interval is transformed to pixels,
multiplied by `bodyWidthFactor`, and clamped to the configured min/max width.
This prevents one market closure or missing sample from producing an enormous
candle. Irregular elapsed-time gaps remain visible as empty X space.

### Current renderer integration

The lowest-risk first implementation keeps `SeriesElement` as the Cartesian
data-series element and adds a Candlestick dispatch backed by isolated geometry
and paint helpers. Introducing a separate element today would require replacing
many `SeriesElement`-specific paths in crosshair, streaming, events,
annotations, and render-box code. That refactor is not required to render the
family correctly.

Candlestick-specific code must nevertheless remain outside the existing Bar
helpers. If the planned internal `ChartFamilyAdapter` later generalizes the
renderer boundary, Candlestick geometry can move behind it without changing
the public model.

### Paint fast path

- Binary-search the ordered source data and process only candles whose body or
  wick can overlap the visible X range.
- Reuse paint objects per resolved state.
- Batch wick segments and body outlines into state-specific paths.
- Batch rectangular fills into state-specific paths.
- Enter a slower per-point override path only when at least one visible candle
  has `CandlestickPointStyle`.
- Use crisp logical-pixel alignment for one-pixel wicks and doji marks.
- Clip once at the series paint scope.

No candle should allocate a `Paint`, `Path`, or text object during a uniform
warm paint.

## Interaction, semantics, and tracking

### Hit testing

The body is the primary target. The wick remains hittable with an expanded
touch tolerance so thin and doji candles do not become inaccessible. A hit
returns the original source index and anchors the tooltip near the body center,
clamped to the plot.

### Crosshair and tooltip

Candlestick tracking is sample-based, not interpolated. The nearest visible X
candle supplies:

- timestamp or X;
- Open, High, Low, Close;
- absolute and percentage change from Open;
- rising, falling, or doji state;
- optional previous-close change in a later indicator layer, not in the core
  candle definition.

`ChartDataHit` gains explicit optional OHLC fields and display strings. The
generic `formattedValue` remains the formatted close. Crosshair axis labels
continue to use the active X and Y coordinate; the floating tooltip carries the
complete OHLC payload.

### Keyboard and accessibility

- Left/right traverses candles in source order.
- Home/End select first/last visible candle.
- Enter/Space uses existing durable point selection.
- The semantic label announces timestamp/category, open, high, low, close,
  direction, position in series, and selection state.
- Hollow/filled treatment plus border/shape keeps direction non-colour-only.
- Reduced-motion users receive final geometry without entrance or update
  animation.

## Temporal axis and session spacing

The Candlestick renderer remains numeric Cartesian. The lane adds a small
portable temporal-axis contract rather than teaching the renderer about
calendars:

- a deterministic UTC epoch-millisecond formatter option for elapsed-time X;
- source-captured runtime locale formatting when an application needs local
  conventions;
- a `FinancialTimeDomain` utility for ordinal session index ↔ timestamp
  lookup, labels, range presets, and navigator synchronization;
- explicit documentation showing both elapsed and ordinal construction.

Calendar-aware tick selection is useful beyond Candlestick and should be kept
axis-owned. It must not be hidden in candle geometry.

## Motion

Entrance and compatible data updates feed the normal geometry pipeline.

- Entrance reveals candles in X order. The current candle may resolve its wick
  and body from the close value toward final OHLC geometry.
- Stable updates match by point identity/X and interpolate open, high, low, and
  close independently.
- Inserted candles grow from their close; removed candles collapse to their
  close while retaining old X identity until exit completes.
- Any interpolated frame still uses the target high/low axis bounds so the plot
  does not breathe.
- Duration zero and reduced motion paint final geometry synchronously.

Animations do not change the source document, table, hit identity, or generated
source.

## Live candle updates

Financial feeds commonly revise the active interval many times before appending
the next candle. The current Braven streaming path appends generic
`ChartDataPoint` values and tracks bounds from one Y value, so it is not
Candlestick-correct without an explicit extension.

- Ordinary immutable series replacement supports initial Candlestick release
  and uses the compatible OHLC transition above.
- The high-frequency controller gains a typed latest-candle upsert: replace the
  final candle when X matches, append when X increases, and reject an older X.
- Streaming and paused-buffer bounds use candle low/high.
- Revising the active candle preserves its point identity and does not grow the
  circular buffer.
- Auto-scroll follows the latest X exactly as other Cartesian series do.
- Append and active-candle revision are benchmarked separately.

This behavior belongs to the shared controller/buffer boundary, not to paint.

## Dense data and grouping

The native renderer first proves 50,000 source candles with viewport culling
and 1,000 visible candles. A later opt-in grouping layer handles densities where
multiple candles occupy one pixel column.

For each ordered group:

- open = first source open;
- high = maximum source high;
- low = minimum source low;
- close = last source close;
- timestamp/X = the first source candle in the globally aligned source-index
  bucket;
- identity = stable group key plus every represented source index.

Grouping affects render and tracking projection only. Artifacts, Data mode,
copy, and CSV preserve raw source candles unless the user explicitly requests a
grouped export. Grouping thresholds use visible pixel density and are computed
outside paint.

The public opt-in is `CandlestickDensityGrouping` on
`CandlestickChartSeries`. `targetGroupWidth` defines the desired logical-pixel
width per rendered group and `minimumPointsPerGroup` prevents accidental
single-point "groups". Buckets align to raw source indices, which keeps the
group key and represented source span stable while the viewport pans at one
grouping resolution. A grouped point intentionally drops point-level paint
overrides because one group can represent conflicting raw styles; series and
theme direction styling still applies.

## Portable document and Workbench

### Artifact representation

Use the existing `ChartPointDocument.extensions` field for the built-in OHLC
sidecar:

```text
type: candlestick
point.x: Cartesian X
point.y: close
point.extensions[braven.candlestick.ohlc.v1]: { open, high, low }
requiredCapabilities: { series.candlestick,
                        series.candlestick.ohlc.v1 }
```

This is a built-in schema use, not a third-party renderer codec. It keeps
schema-v1 point and column storage compatible, makes close the canonical Y
anchor, and lets older runtimes reject unsupported Candlestick documents by
capability rather than partially rendering them.

The codec validates the sidecar, reconstructs `CandlestickDataPoint`, and
round-trips point style, timestamp, label, metadata, axis, annotations, theme,
animation, and series style.

### Native Data projection

Add `ChartTableProjectionKind.candlestick` and a dedicated lossless row with:

- Time/X;
- Open;
- High;
- Low;
- Close;
- derived change and change percentage;
- unit;
- stable source point reference.

Line/Area/Scatter overlays may appear as exact-X auxiliary columns. Sorting,
copy, CSV, focus, and selection retain the candle source reference. Derived
fields are clearly labelled and never replace source values.

### Generated source

`ChartDartSourceGenerator` emits `CandlestickChartSeries` and
`CandlestickDataPoint`, including all portable style and animation options.
Temporal runtime formatters follow the existing binding/placeholder rules.
Generated source must be deterministic and compile in a fixture.

### Agentic input

Extend the chart tool schema and builder with `candlestick` plus required
`open`, `high`, `low`, and `close` fields. Reject generic Y-only candlestick
requests. AI input receives the same index-specific OHLC validation as direct
Dart and artifacts.

### Workbench

The chart mounts in the existing `BravenChartWorkbench` and provides Chart,
Data, Split, and Source. No Candlestick-specific Workbench fork is allowed.
Failures in one presentation remain isolated by the current Workbench contract.

## Stock-style composition

The screenshot's complete experience is assembled after the native series is
proven:

```text
Range preset controls ── set shared X viewport
                         │
Main Candlestick chart ──┼── ChartInteractionGroupController
Optional volume chart  ──┤
Close-price navigator  ──┘
```

- The navigator is an ordinary compact Area/Line chart derived from candle
  closes.
- Drag handles update the shared visible X viewport; main-chart pan/zoom updates
  the navigator window.
- 1m/3m/6m/YTD/1y/All buttons convert dates through the active elapsed or
  ordinal time domain and issue the same viewport command.
- Volume is a separate Bar chart in a synchronized pane with its own Y scale.
- Technical indicators are ordinary Line/Area series produced by application
  data transforms. SMA/EMA/Bollinger calculations are not part of the candle
  renderer.
- Data fetching, market calendars, split/dividend adjustment, exchange
  timezones, and live brokerage integration remain application concerns.

The composition may earn reusable public widgets after its controller and
accessibility behavior are proven. It does not block the core Candlestick API.

## Performance gates

Permanent benchmarks must cover:

- 50,000 ordered source candles, 1,000 visible: cold geometry and warm paint;
- 5,000 visible candles: renderer stress without grouping;
- crosshair nearest-candle lookup at 60 Hz;
- pan/zoom viewport regeneration and cache invalidation;
- stable OHLC update animation for 1,000 visible candles;
- active-candle upsert and next-interval append under live updates;
- stock composition fanout across main, volume, and navigator charts;
- grouped projection cost and source-index preservation.

Targets:

- p95 geometry/paint and controller fanout each remain below 16.67 ms on the
  established benchmark environment;
- nearest-candle lookup is `O(log n)` for ordered data;
- warm uniform paint performs no per-candle object allocation;
- changing viewport does not scan all 50,000 source candles;
- Workbench document extraction remains source-sized and independent of
  rendered/grouped marks.

## Explicit exclusions from core v1

- Heikin-Ashi, hollow-candle rules beyond the presentation mode, Renko,
  point-and-figure, and OHLC tick bars;
- automatic technical indicators;
- market-data clients and live feeds;
- exchange calendars and timezone databases;
- split/dividend adjustment;
- server-side data grouping;
- multi-candlestick comparison in one plot;
- same-plot volume bars.

These can build on the typed OHLC and stock-composition foundation later.

## Definition of done

Candlestick is a supported Braven chart family only when:

- the public model and all validation paths agree;
- low/high bounds, irregular X spacing, doji geometry, and paint are correct;
- mouse, touch, keyboard, focus, selection, crosshair, tooltip, and semantics
  expose the original candle;
- animation and reduced-motion behavior are deterministic;
- artifacts round-trip without losing OHLC or style;
- native Data/Split and generated Source preserve OHLC semantics;
- AI schema input cannot create a partial candle;
- the direct showcase route demonstrates core candles and stock composition;
- package/example analysis, complete tests, release web builds, browser checks,
  docs, and pub.dev dry run pass;
- performance gates are recorded at the promoted commit;
- the user has completed local pixel and interaction review before any PR.
