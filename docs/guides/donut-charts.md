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
    'Hardware': 27,
  },
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
  borders, shadows, selected elevation, and reduced-motion-aware animation;
- inside or collision-managed outside labels and positioned legends;
- total, selected, selected-or-total, or custom portable center text;
- optional complete second-metric values for variable outer radii;
- shared slice, legend, keyboard, table, and controller selection;
- category/value/radius/share tables with copy and CSV export; and
- canonical artifact JSON, PNG previews, capability validation, and hydration.

Read the complete [Donut chart reference](../../doc/donut_charts.md) for
validation rules, every center mode, table linkage, controller examples,
artifact capabilities, AI tool input, theming, and accessibility.

Try the [live Donut showcase](https://braven-pvm.github.io/braven_charts/?page=donut-charts)
to compare Chart, Data, and Split modes and capture a restorable artifact.
