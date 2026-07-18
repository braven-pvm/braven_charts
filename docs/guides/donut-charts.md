# Donut chart guide

`DonutChartSeries` renders one ordered category whole around a shared center
opening. It is a first-class radial chart type: it cannot mix with Cartesian
or Pie series, and it intentionally does not use axes, crosshairs, scrollbars,
pan, or zoom.

```dart
final series = DonutChartSeries.fromMap(
  id: 'revenue-share',
  unit: 'USD',
  values: const {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 20,
    'Training': 4,
    'Support': 3,
  },
  sliceGroupingConfig: const RadialSliceGroupingConfig(
    minimumShare: 0.05,
    label: 'Other',
  ),
  donutStyle: const DonutChartStyle(innerRadiusFactor: 0.58),
  centerContent: const DonutCenterContent(
    label: 'Revenue',
    valueMode: DonutCenterValueMode.selectedOrTotal,
  ),
);

BravenChartPlus(series: [series]);
```

The public contract covers:

- complete or partial annular geometry;
- clockwise/counter-clockwise ordering and configurable start angle;
- solid or gradient fills, physical gaps, three corner treatments, opacity,
  borders, shadows, selected elevation, and `none`, `grow`, `sweep`, or `fade`
  reduced-motion-aware entrance animation;
- inside or collision-managed outside labels and positioned legends;
- total, selected, selected-or-total, or custom portable center text;
- optional complete second-metric values for variable outer radii;
- optional small-slice grouping that preserves every original source point;
- shared slice, legend, keyboard, table, and controller selection;
- category/value/radius/share tables with copy and CSV export; and
- canonical artifact JSON, PNG previews, capability validation, and hydration.

Read the complete [Donut chart reference](../../doc/donut_charts.md) for
validation rules, every center mode, table linkage, controller examples,
artifact capabilities, AI tool input, theming, and accessibility.

Try the [live Donut showcase](https://braven-pvm.github.io/braven_charts/?page=donut-charts)
to compare Chart, Data, and Split modes and capture a restorable artifact.
Split mode uses the package-owned content-aware divider: drag it to resize, use
arrow keys while it is focused, or press Escape/double-click to fit the data
table again.
Use the Motion controls to compare modes and replay the entrance without
changing the chart data.

When grouping is enabled, qualifying positive categories render as one
aggregate slice at the end of the visible order. The data table and CSV still
contain one row per original category. Selecting the aggregate through the
slice or legend—or selecting any grouped table row—selects every represented
`ChartPointRef`. Grouping and variable slice radii are intentionally mutually
exclusive until the application chooses an explicit second-metric aggregation
policy.
