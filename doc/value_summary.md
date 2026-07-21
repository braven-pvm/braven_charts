# Cartesian value summary

Braven Charts can keep the current policy-resolved datum visible in a
persistent in-plot panel — the Cartesian value summary. It applies to every
built-in Cartesian family (Line, Area, Bar, Scatter, and Candlestick),
including multi-series, mixed, and multi-axis charts, and is fed by the same
immutable tracking snapshot as the crosshair, so the panel never resolves the
data a second time (the sole exception is the divergent value mode described
under "Value mode" below). It is independent of the crosshair panel, point tooltip,
and axis value labels: enabling one never implicitly enables another.

Open the runnable [Value Summary showcase](https://braven-pvm.github.io/braven_charts/?page=value-summary)
to prototype presets for single-series fallback, multi-series, multi-axis
units, Candlestick OHLC, synchronized pairs, and the draggable panel.

## Quick start

The summary is configured through `InteractionConfig.valueSummary` and
defaults to disabled. Two presentations exist and share content, style,
semantics, and formatting.

The **fixed overlay** anchors to the plot interior, never moves with pan or
zoom, and always passes pointer input through to the chart beneath it:

```dart
BravenChartPlus(
  series: series,
  interactionConfig: InteractionConfig(
    valueSummary: CartesianValueSummaryConfig(
      enabled: true,
      presentation: CartesianValueSummaryPresentation.overlay(
        placement: ChartOverlayPlacement.topLeft,
      ),
    ),
  ),
)
```

The **annotation-style panel** sits at an anchor + offset in plot-screen space
and can optionally be dragged with the pointer or moved with the arrow keys:

```dart
CartesianValueSummaryConfig(
  enabled: true,
  presentation: CartesianValueSummaryPresentation.annotation(
    placement: ChartOverlayPlacement(
      anchor: Alignment.topRight,
      offset: Offset(12, 12),
    ),
    draggable: true,
    clampToPlot: true,
  ),
  onPlacementChanged: (placement) => savePlacement(placement),
)
```

`ChartOverlayPlacement` is anchor-relative rather than an absolute canvas
offset, so a placed panel stays stable across plot resizes, axis-width
changes, RTL resolution (anchors are direction-relative: `topLeft` resolves to
the top-right plot corner under RTL), and responsive layouts.

## Value policies

`valuePolicy` selects the datum deterministically. Each policy is a precedence
chain; when a source is unavailable the resolution falls through, and when no
source yields a valid datum the summary hides:

| Policy | Precedence |
| --- | --- |
| `trackingThenLatest` (default) | live tracking → latest visible datum |
| `trackingThenFirst` | live tracking → first visible datum |
| `selectionThenTrackingThenLatest` | focused/selected point → tracking → latest visible |
| `pinnedThenTrackingThenLatest` | pinned point → tracking → latest visible |
| `explicitOnly` | pinned point only; hidden otherwise |

Live tracking covers the local pointer, keyboard data navigation, and the
synchronized cursor. A pin that references a removed or replaced point is
cleared automatically and resolution continues through the chain.

## Value mode: interpolated curve vs actual data points

`valueMode` chooses what the *tracking* stage reports while the cursor sits
between samples:

- `CartesianValueSummaryValueMode.interpolated` (default) — the summary
  reuses the crosshair's value resolution as-is. With
  `CrosshairConfig.interpolateValues` true (its default) rows carry values
  computed at the exact cursor X on the curve (`Power: 240.54 W` halfway
  between two samples); with it false they already snap to the nearest
  datum. This is the pre-existing behavior.
- `CartesianValueSummaryValueMode.dataPoints` — rows always snap to the
  nearest actual data point, regardless of the crosshair's interpolation
  setting: `isInterpolated` is false and the formatted strings are those of
  the real sample, matching what the point tooltip shows for that datum.

```dart
CartesianValueSummaryConfig(
  enabled: true,
  valueMode: CartesianValueSummaryValueMode.dataPoints,
)
```

The mode governs only live tracking; the pinned, selection, and
latest/first-visible fallback stages always report actual data points.

`valueMode` and `CrosshairConfig.interpolateValues` are deliberately
independent options. For a visually consistent chart, pair them: use
`interpolateValues: true` with the interpolated mode and `false` with
`dataPoints`, so the crosshair's intersection marker, its labels, and the
summary rows all resolve the same way — everything follows the curve, or
everything snaps to the same real sample (this pairing also keeps every
combination on the chart's single shared tracking resolution). Opposing them
remains supported for advanced cases — for example a marker riding the curve
while the panel reports the nearest measured sample: the visual tracking
follows the crosshair's setting and the summary rows follow `valueMode`.

Cost: the summary keeps reusing the chart's single shared per-frame tracking
resolution whenever the mode is compatible with it — interpolated mode
always, and dataPoints mode while the crosshair does not interpolate (or is
not consuming the tracking resolution at all). Only when the crosshair
actively tracks *with* interpolation while the summary wants data points do
the two genuinely diverge: the summary then runs one extra memoized
resolution per frame — recomputed per cursor change, republished per datum
change, and never per repaint. The crosshair's own resolution cost is
unchanged in every combination.

## Content model

`CartesianValueSummaryContent.automatic()` builds family-aware rows from the
resolved snapshot with tooltip-parity formatting — values arrive already
formatted with their axis units and are never re-formatted:

- **Line, Area, Bar** — one formatted value row, plus a `Grouped: N points`
  row when the sample aggregates multiple source points.
- **Scatter** — X and Y rows plus one row per active encoding (size, color,
  opacity, category), using the encoding labels shown in the tooltip.
- **Candlestick** — Open, High, Low, Close, Change, and Direction rows from
  the typed OHLC payload, plus a `Grouped: N candles` row under density
  grouping; the panel context uses the formatted candle timestamp.
- **Multi-series and mixed charts** — one section per visible series at the
  resolved X: single-row families collapse into an accented `name: value`
  row, multi-row families emit an accented series title row followed by
  their family rows.

`includeTrends: true` adds rows for trend annotations (moving averages and
friends) evaluated at the resolved X.

Fully custom rows use a builder over the published snapshot:

```dart
CartesianValueSummaryContent.builder(
  (snapshot) => CartesianValueSummaryContentModel(
    title: 'Session',
    subtitle: snapshot.values.first.formattedX,
    rows: [
      for (final value in snapshot.values)
        CartesianValueSummaryRow(
          label: value.seriesName,
          value: value.formattedY,
          color: value.seriesColor,
        ),
    ],
  ),
  descriptorId: 'my-app.session-summary',
)
```

The builder is invoked only when a new snapshot is published, never per
pointer pixel. Rows can carry an optional `semanticValue` announced to screen
readers instead of the display text.

## Styling, tri-state clears, and theming

`CartesianValueSummaryStyle` is tri-state per field via `ChartStyleValue`:

- `ChartStyleValue.inherit()` (default) resolves the
  `CartesianValueSummaryTheme` default of the active chart theme;
- `ChartStyleValue.value(...)` overrides the theme;
- `ChartStyleValue.none()` clears the property outright — a cleared
  background is truly transparent and a cleared border draws no stroke, with
  no silent fallback to the theme, and the clears survive artifact and
  Source round trips.

```dart
CartesianValueSummaryConfig(
  enabled: true,
  style: CartesianValueSummaryStyle(
    backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),
    borderColor: ChartStyleValue.none(),
  ),
  showSeriesAccent: false,
)
```

Fields cover surface color and opacity, border, corner radius, padding, value
and label text styles, series accent color, shadow, min/max width, row gap,
and the label-value gap. Theme presets exist for `light`, `dark`,
`highContrast`, and `colorblindFriendly` through
`ChartTheme.cartesianValueSummaryTheme`. A transparent surface does not waive
text-contrast requirements; authors clearing the background remain
responsible for a legible explicit text color.

`labelValueGap` selects between the two row layouts. Inherited (no theme
preset sets a default) or cleared, rows **spread**: values right-align to the
panel's content edge and the panel fills `minWidth`, which can leave a wide
gap between short labels and short values. An explicit value **packs** the
rows: every value left-aligns in a shared column that starts at the widest
row label plus the gap, and the panel's intrinsic width tightens to
labels + gap + widest value — still clamped by `minWidth`/`maxWidth`, with
long values (for example a candlestick's `203.81 USD`) still ellipsizing at
`maxWidth`. Title, subtitle, and section-header rows are unaffected.

```dart
CartesianValueSummaryConfig(
  enabled: true,
  style: CartesianValueSummaryStyle(
    labelValueGap: ChartStyleValue.value(16), // pack values behind labels
    minWidth: ChartStyleValue.none(),         // let the panel shrink to fit
  ),
)
```

## Controller and pinning

`CartesianValueSummaryController` pins and unpins a datum by stable
`ChartPointRef` identity and resets a dragged panel:

```dart
final controller = DefaultCartesianValueSummaryController();

CartesianValueSummaryConfig(
  enabled: true,
  valuePolicy: CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
  controller: controller,
);

controller.pin(const ChartPointRef(seriesId: 'price', pointIndex: 41));
controller.clearPin();
controller.resetPlacement();
```

Use (or subclass) `DefaultCartesianValueSummaryController` when
`resetPlacement` must actually restore a dragged panel: the chart observes
controllers as a generic listenable, and only the default controller carries
the internal reset handshake. The controller never accepts formatted strings
and never owns placement — the widget configuration stays authoritative, and
committed drags surface through `onPlacementChanged`.

## Placement, drag, and keyboard

A draggable annotation panel:

- wins the pointer strictly inside its painted bounds and never steals hits
  elsewhere; the fixed overlay never intercepts input at all;
- previews continuously during a drag and emits exactly one committed
  anchor-relative placement through `onPlacementChanged` on release;
- clamps inside the plot during drags, keyboard moves, and resizes while
  `clampToPlot` is true;
- never disturbs tracking: hover, selection, and the crosshair freeze during
  the drag and resume after release;
- moves with the arrow keys once clicked (1 logical pixel per press, 10 with
  Shift), committing the accumulated movement once on key release; Escape
  restores the configured placement and releases focus.

Non-primary buttons fall through: right-click over the panel opens the chart
context menu and middle-drag pans the chart.

## Synchronized charts

In a synchronized interaction group each participating chart resolves its own
series values locally at the shared X — one group broadcast, one local
resolution per participant, and no cross-chart row models. Configure the
summary per chart; the shared cursor drives the `tracking` stage of every
participant's policy chain.

## Artifacts, Source, and portability

Automatic configurations round-trip losslessly through artifacts, hydration,
and generated Dart Source, including presentation, placement, policy,
tri-state style clears, `showSeriesAccent`, and `announceChanges`.

Builder content is portable only when `descriptorId` names a registered
runtime content descriptor: encoding a builder without a descriptor emits a
`runtimeBindingRequired` diagnostic and falls back to automatic content
rather than serializing rendered text. Hydrating a document whose descriptor
binding is unavailable likewise reports the diagnostic and activates
automatic content. `onPlacementChanged` and `controller` are runtime bindings
and are never serialized.

## Performance notes

The summary is designed to be free when idle and marginal when tracking:

- Series values resolve once per interaction frame through the shared
  tracking snapshot; the crosshair and summary reuse the same resolution.
  The one exception is the divergent value mode combination — crosshair
  interpolation and summary `dataPoints` simultaneously active — which adds
  exactly one extra memoized resolution per frame (see "Value mode" above).
- A snapshot is republished only when the resolved datum identity or its
  formatted values change; pointer movement within the same snapped datum
  never rebuilds or repaints the panel.
- Panel layout is cached until content, style, text scale, or plot bounds
  change; updates repaint only the feedback layer and never invalidate the
  series picture cache, geometry, or spatial indices.
- Dragging the panel paints continuously but commits (and rebuilds) once.

The permanent benchmark matrix covers 5k-point dual-series no-regression, a
50k-point overlay update inside one frame, 2k Candlesticks with a moving
average at zero cache invalidations, dense Scatter without a second O(N)
scan, three synchronized charts, and drag cadence.

## Accessibility

Both presentations expose one grouped semantic region per visible summary:
the label is `Value summary` plus the panel title and context (for example
`Value summary, Power, 14:32`), and the region value lists every row in
source order with its unit (`Open: 101.20 USD`). The `Value summary` prefix
keeps traversal unambiguous next to the crosshair panel, which paints on
canvas and adds no competing node.

- `announceChanges` (default false) enables screen-reader announcements,
  debounced by resolved datum identity: one announcement per datum change,
  never per pointer pixel or repaint.
- The annotation panel is focusable only while draggable. A draggable panel
  exposes `Move left/right/up/down` (one 10-pixel step per action, committed
  immediately) and `Reset position` custom semantic actions.
- `Pin value` and `Clear pin` actions appear only while a controller is
  attached and the active policy involves pinning.
- The panel renders statically — it has no animated behavior, so reduced
  motion needs no special handling — and the `highContrast` theme preset
  covers high-contrast environments.

## Known V1 limitations

- Bar grouped-context rows are thin: aggregated samples report
  `Grouped: N points` without richer per-group composition rows.
- `CartesianValueSummaryContent.automatic(includeHiddenSeries: true)` is
  currently a no-op: hidden series are filtered before resolution and never
  reach the summary pipeline.
- A series whose viewport contains only a single visible point does not
  resolve the latest/first fallback; the summary stays hidden until live
  tracking, a selection, or a pin resolves a datum.
- A pinned point that pans or zooms outside the visible viewport is treated
  as unresolvable: the pin is cleared and the policy falls through, rather
  than being remembered until the point returns.
