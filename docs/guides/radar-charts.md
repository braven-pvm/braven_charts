# Radar and Spider charts

Radar charts compare several aligned quantitative profiles across one ordered
set of dimensions. Spider or Spiderweb describes the polygon-grid
presentation of the same data model; it is not a separate chart family.

Use Radar when the shape of a small multidimensional profile is itself useful:

- comparing two or three teams against the same capability model;
- comparing an actual profile with a target profile;
- reviewing a balanced operational scorecard on one explicit scale.

Prefer a grouped Bar chart or the Workbench Data view when exact ranked
comparison matters more than profile shape. Avoid Radar when the categories
have unrelated scales, values can be missing, category order is arbitrary, or
many overlapping profiles would make the web unreadable.

## A first Radar chart

Every profile must provide the same categories in the same authored order.
Map insertion order is therefore part of the public category identity.

```dart
BravenChartPlus(
  series: [
    RadarChartSeries.fromMap(
      id: 'allocated-budget',
      name: 'Allocated budget',
      unit: '%',
      color: const Color(0xFF0EA5E9),
      values: const {
        'Sales': 78,
        'Marketing': 46,
        'Development': 84,
        'Support': 58,
        'Technology': 67,
        'Administration': 42,
      },
    ),
    RadarChartSeries.fromMap(
      id: 'actual-spending',
      name: 'Actual spending',
      unit: '%',
      color: const Color(0xFF4F46E5),
      values: const {
        'Sales': 69,
        'Marketing': 78,
        'Development': 74,
        'Support': 52,
        'Technology': 38,
        'Administration': 31,
      },
    ),
  ],
  radarChartConfig: const RadarChartConfig(
    radialAxis: RadarNumericAxisConfig(
      minimum: 0,
      maximum: 100,
      gridShape: RadarGridShape.polygon,
    ),
  ),
)
```

V1 deliberately rejects fewer than three categories, duplicate or missing
categories, negative or non-finite values, mixed Radar and Cartesian series,
partial sweeps, and hollow centers. It does not silently normalize each spoke
to a different scale.

## Polygon and circular webs

`RadarGridShape.polygon` produces the familiar Spider web. Use
`RadarGridShape.circle` when circular reference rings make the comparison less
visually dominant:

```dart
const RadarChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: -90,
    outerRadiusFactor: 0.78,
  ),
  categoryAxis: RadarCategoryAxisConfig(
    labelOffset: 8,
    maximumVisibleLabels: 12,
  ),
  radialAxis: RadarNumericAxisConfig(
    minimum: 0,
    maximum: 100,
    tickCount: 5,
    gridShape: RadarGridShape.circle,
  ),
)
```

All profiles in one pane share this radial domain. A fixed `maximum` is
recommended when charts are compared across screens or time periods.

## Profile styling

`RadarSeriesStyle` controls one profile without changing its category or value
identity:

```dart
RadarChartSeries.fromMap(
  id: 'current-window',
  name: 'Current window',
  values: const {
    'Availability': 88,
    'Latency': 66,
    'Throughput': 74,
    'Recovery': 62,
    'Security': 82,
  },
  radarStyle: const RadarSeriesStyle(
    strokeWidth: 2.5,
    strokeDashPattern: [6, 4],
    fillOpacity: 0.14,
    showMarkers: true,
    markerRadius: 3,
    showDataLabels: false,
    animationMode: RadarAnimationMode.radial,
  ),
)
```

Colors inherit from the series and chart theme. Category and radial label
styles are configured on `RadarChartConfig` because they belong to the shared
web, not one profile.

## Interaction and durable identity

Each Radar vertex is addressed by the series ID and category index. Pointer,
keyboard, controller, legend, and Workbench table selection all resolve that
same durable reference. Tracking one category can therefore show the aligned
value from every visible profile.

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  series: profiles,
)

controller.selectPoint(
  const ChartPointRef(seriesId: 'actual-spending', pointIndex: 2),
);
```

Use arrow keys while the chart has focus to traverse vertices, Enter or Space
to select, and Escape to clear. Category text, marker shape, exact values,
tooltips, and the native table keep meaning available without relying on color
alone.

## Motion and updates

Radar supports radial growth, final-geometry fade, and immediate rendering.
Stable series and category identities interpolate values without morphing one
dimension into another. A category topology change reveals the new final web
instead of cross-wiring old and new vertices.

```dart
const RadarSeriesStyle(
  animationMode: RadarAnimationMode.fade,
)
```

Reduced-motion environments complete directly at final geometry. The public
controller can replay entrance motion without rebuilding the chart.

## Data, Source, and portable artifacts

`BravenChartWorkbench` can show the same mounted Radar chart as Chart, Data,
Split, or Source. The native wide table uses one row per category and one value
column per profile, making the common scale and exact values explicit.

Radar artifacts preserve series/category identity, shared configuration,
profile styling, visibility, selection, and declared capabilities through
JSON extraction and hydration. Direct Dart Source and typed Grammar Source are
both fidelity checked; unsupported runtime callbacks are reported rather than
silently omitted.

```dart
BravenChart.of(rows)
    .geomRadar(
      category: (row) => row.category,
      value: (row) => row.allocated,
      id: 'allocated-budget',
      name: 'Allocated budget',
    )
    .geomRadar(
      category: (row) => row.category,
      value: (row) => row.actual,
      id: 'actual-spending',
      name: 'Actual spending',
    )
    .radarConfig(
      const RadarChartConfig(
        radialAxis: RadarNumericAxisConfig(maximum: 100),
      ),
    );
```

Open the live `?page=radar-charts` showcase to compare polygon and circular
webs, inspect linked Data/Split views, copy generated Source, update values,
replay motion, and test reduced-motion behavior.

## Accessibility and comparison limits

- Keep the category count modest; label density is bounded but the source
  table always retains every dimension.
- Keep profile count low enough that fills and intersections remain legible.
- Use an explicit shared maximum for comparisons across charts.
- Preserve meaningful category order across updates.
- Use restrained fill opacity so overlapping outlines remain visible.
- Pair the chart with the Data view when users need exact comparison.
- Do not imply that polygon area is a direct aggregate score; axis order and
  geometry both influence the apparent shape.
