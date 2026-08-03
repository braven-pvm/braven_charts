# Series label callouts

Series label callouts identify several visible line or area series without
forcing the reader to trace colours back to a separate legend. Each label sits
in one shared lane at the edge of the plot and connects to a meaningful point
on its series.

Use callouts when a dense comparison benefits from direct identification. Keep
the legend when it still communicates additional state, or hide it when the
callout lane provides the complete series key.

## Quick start

Configure the shared lane once on `BravenChartPlus`:

```dart
BravenChartPlus(
  series: series,
  seriesCallouts: const SeriesCalloutConfig(
    enabled: true,
    side: SeriesCalloutSide.right,
    anchor: SeriesCalloutAnchor.lastVisible,
    connector: SeriesCalloutConnector.elbow,
  ),
)
```

Callouts are disabled by default. Enabling them includes every supported,
visible line and area series unless the series is explicitly excluded.

## Global policy and per-series overrides

The chart-level configuration owns layout and default behavior. The `series`
map applies exceptions by stable `ChartSeries.id`:

```dart
BravenChartPlus(
  series: series,
  seriesCallouts: const SeriesCalloutConfig(
    enabled: true,
    showByDefault: true,
    maximumVisible: 8,
    minimumGap: 6,
    packing: SeriesCalloutPacking.compact,
    laneWidth: 164,
    series: {
      'observed': SeriesCalloutSpec(
        label: 'Observed response',
        priority: 10,
      ),
      'target': SeriesCalloutSpec(priority: 8),
      'reference-band': SeriesCalloutSpec(show: false),
    },
  ),
)
```

Set `showByDefault: false` to make the lane opt-in. In that mode, only entries
with `SeriesCalloutSpec(show: true)` participate.

Per-series overrides can also change the label, connector colour, anchor,
label text style, background, border, connector width and opacity, and label
border geometry. Values that are not overridden use the shared configuration
and then the series colour or chart theme.

## Choosing the anchor

`SeriesCalloutAnchor` controls which data feature the connector identifies:

- `lastVisible` and `firstVisible` follow the current visible X window;
- `maximumVisible` and `minimumVisible` identify visible extrema;
- `xValue` samples the series at `anchorX`, interpolating between adjacent
  finite points when necessary.

The per-series `anchor` and `anchorX` fields override the global choice. This
is useful when most series should follow the viewport edge but one reference
series needs a fixed analytical anchor.

## Collision and overflow behavior

Callouts share one vertical lane. Braven Charts measures every candidate,
keeps labels inside the plot, and separates them by `minimumGap`. When the lane
cannot fit all candidates, higher `priority` values survive first, followed by
stable series ID ordering. `maximumVisible` provides an explicit upper bound.

This deterministic policy avoids label flicker while panning or zooming. It
also means priority is a product decision: give primary measurements a higher
value than secondary comparisons.

`packing: SeriesCalloutPacking.followAnchors` is the default and keeps every
label as close as possible to its own anchor. Use `compact` when the labels
should read as one tight bank: their stable vertical order is preserved and
adjacent labels are separated by exactly `minimumGap`, while the complete bank
is positioned as close as possible to its collective anchors.

The V1 lane is painted inside the plot. Increase `laneWidth` to allow longer
labels, but remember that the lane deliberately overlays the right or left
edge of the data pane rather than changing the chart's external layout.

## Styling

Global styling includes:

- `connector`, `connectorColor`, `connectorWidth`, `connectorOpacity`, and
  `connectorGlow`;
- `anchorRadius`;
- `labelPadding`, `labelStyle`, `backgroundColor`, and `backgroundOpacity`;
- `borderColor`, `borderWidth`, and `borderRadius`;
- `panelPadding`, `panelBackgroundColor`, `panelOpacity`, `panelBorderColor`,
  `panelBorderWidth`, and `panelBorderRadius`;
- `side`, `laneWidth`, and `inset`.

If label foreground or background colours are omitted, the renderer derives
contrast-aware defaults from the chart theme. A null global `connectorColor`
keeps each connector tied to its series colour. A `SeriesCalloutSpec` can
replace the connector colour, text style, background, border, opacity, width,
glow, or radius for one series.

The lane panel is optional, content-sized around the resolved labels, and
bounded inside the plot. Use `panelPadding` to control its breathing room.
Leave both panel colours null for no panel, use a translucent fill to group
dense labels, or add a border when the lane needs a stronger visual boundary.

## Portability and source generation

Series callout configuration is part of the effective chart document. Artifact
capture, JSON encoding, hydration, and generated Config Dart source preserve
the global policy and every stable-ID override.

Typed Chart Grammar does not yet have a callout clause. Grammar source
generation reports this as an unsupported chart option instead of silently
dropping it. Use generated Config source when a callout-enabled chart must be
reproduced as Dart.

## Interactive example

Open the **Series Styling** showcase and choose **Series callouts**. The example
contains seven competing series so you can:

1. move the lane between the left and right edge;
2. switch anchor, compact-packing, and connector strategies;
3. style label typography, fill, opacity, borders, and rounding;
4. switch connectors between inherited series colour and one fixed colour,
   then tune their width, opacity, and glow;
5. style the shared lane panel;
6. override Build independently or hide Recovery while global callouts remain
   enabled.

Deep link: `?page=series-styling`

## Current boundary

V1 supports Cartesian line and area series. It does not add callout widgets to
radial families, bars, scatter marks, range bands, or heatmap cells. Those
families have different anchor and collision semantics and should not inherit
the Cartesian contract implicitly.
