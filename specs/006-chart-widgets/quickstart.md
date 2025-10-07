# Quickstart: Create Your First Chart in 5 Minutes

**Feature**: 006-chart-widgets  
**Target Time**: 5 minutes to first working chart  
**Prerequisites**: Flutter SDK 3.37+ installed, Braven Charts package added to pubspec.yaml

---

## Step 1: Basic Line Chart (2 minutes)

Create a simple line chart showing sales data:

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Dashboard')),
      body: Center(
        child: BravenChart(
          chartType: ChartType.line,
          series: [
            ChartSeries(
              id: 'monthly_sales',
              name: 'Monthly Sales',
              points: [
                ChartDataPoint(1, 10000),  // Jan
                ChartDataPoint(2, 15000),  // Feb
                ChartDataPoint(3, 12000),  // Mar
                ChartDataPoint(4, 18000),  // Apr
                ChartDataPoint(5, 22000),  // May
                ChartDataPoint(6, 25000),  // Jun
              ],
            ),
          ],
          title: 'Monthly Sales 2025',
          width: 400,
          height: 300,
        ),
      ),
    );
  }
}
```

**Run it**: `flutter run -d chrome`

**Expected Result**: Professional line chart with auto-calculated axes, grid lines, and legend.

---

## Step 2: Add Annotations (1 minute)

Highlight important events on your chart:

```dart
BravenChart(
  chartType: ChartType.line,
  series: [...], // Same as Step 1
  annotations: [
    // Mark best month
    PointAnnotation(
      seriesId: 'monthly_sales',
      dataPointIndex: 5, // June
      label: 'Record Month!',
      markerShape: MarkerShape.star,
    ),
    
    // Show target line
    ThresholdAnnotation(
      axis: AnnotationAxis.y,
      value: 20000,
      label: 'Sales Target',
      lineColor: Colors.green,
      dashPattern: [5, 5],
    ),
  ],
  title: 'Monthly Sales 2025',
  width: 400,
  height: 300,
)
```

**Expected Result**: Chart now shows star marker on June and horizontal target line at 20K.

---

## Step 3: Simplified Data Input (30 seconds)

Use the `fromValues` factory for quick charts:

```dart
BravenChart.fromValues(
  chartType: ChartType.line,
  seriesId: 'sales',
  yValues: [10000, 15000, 12000, 18000, 22000, 25000],
  // X-values auto-generated as 0, 1, 2, 3, 4, 5
  title: 'Monthly Sales 2025',
)
```

**Expected Result**: Same chart with less code.

---

## Step 4: Customize Axes (1 minute)

Hide axes for a sparkline or customize appearance:

```dart
BravenChart.fromValues(
  chartType: ChartType.line,
  seriesId: 'sales',
  yValues: [10000, 15000, 12000, 18000, 22000, 25000],
  // Sparkline style - no axes
  xAxis: AxisConfig.hidden(),
  yAxis: AxisConfig.hidden(),
  width: 200,
  height: 60,
)
```

Or customize with grid-only style:

```dart
BravenChart.fromValues(
  chartType: ChartType.line,
  seriesId: 'sales',
  yValues: [10000, 15000, 12000, 18000, 22000, 25000],
  // Grid-only style
  xAxis: AxisConfig.gridOnly(),
  yAxis: AxisConfig.gridOnly().copyWith(
    gridColor: Colors.grey.withOpacity(0.3),
  ),
)
```

**Expected Result**: Sparkline (tiny chart for dashboards) or customized grid appearance.

---

## Step 5: Real-Time Data (30 seconds)

Add streaming data with automatic throttling:

```dart
class RealTimeChart extends StatelessWidget {
  final Stream<ChartDataPoint> sensorStream;
  
  @override
  Widget build(BuildContext context) {
    return BravenChart(
      chartType: ChartType.line,
      series: [], // Start empty
      dataStream: sensorStream, // Auto-updates!
      title: 'Sensor Readings',
      width: 400,
      height: 300,
    );
  }
}
```

**Expected Result**: Chart automatically updates as data arrives, throttled to 60 FPS.

---

## Step 6: Programmatic Control (1 minute)

Use `ChartController` for dynamic updates:

```dart
class InteractiveChart extends StatefulWidget {
  @override
  _InteractiveChartState createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  final controller = ChartController();
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  
  void _addDataPoint() {
    final nextX = controller.getAllSeries()['sales']?.length ?? 0;
    controller.addPoint(
      'sales',
      ChartDataPoint(nextX.toDouble(), Random().nextDouble() * 30000),
    );
  }
  
  void _addAnnotation() {
    controller.addAnnotation(
      TextAnnotation(
        position: Offset(200, 100),
        label: 'Important Event',
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BravenChart(
          chartType: ChartType.line,
          series: [ChartSeries(id: 'sales', points: [])],
          controller: controller,
          width: 400,
          height: 300,
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: _addDataPoint,
              child: Text('Add Point'),
            ),
            ElevatedButton(
              onPressed: _addAnnotation,
              child: Text('Add Annotation'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**Expected Result**: Buttons add points and annotations to chart in real-time.

---

## Common Patterns

### Pattern 1: Multi-Series Chart
```dart
BravenChart(
  chartType: ChartType.line,
  series: [
    ChartSeries(id: 'product_a', name: 'Product A', points: [...]),
    ChartSeries(id: 'product_b', name: 'Product B', points: [...]),
    ChartSeries(id: 'product_c', name: 'Product C', points: [...]),
  ],
)
```

### Pattern 2: Different Chart Types
```dart
// Bar chart
BravenChart(chartType: ChartType.bar, series: [...])

// Area chart  
BravenChart(chartType: ChartType.area, series: [...])

// Scatter plot
BravenChart(chartType: ChartType.scatter, series: [...])
```

### Pattern 3: Dark Mode Support
```dart
BravenChart(
  chartType: ChartType.line,
  series: [...],
  theme: ChartTheme.defaultDark, // Or auto from Theme.of(context)
)
```

### Pattern 4: Custom Fixed Range
```dart
BravenChart(
  chartType: ChartType.line,
  series: [...],
  yAxis: AxisConfig(
    range: AxisRange.fixed(0, 100), // Fixed 0-100 range
  ),
)
```

---

## Troubleshooting

### Chart Not Showing
- **Check**: Did you provide `width` and `height` or wrap in sized container?
- **Check**: Does `series` have at least one `ChartSeries` with points?

### Performance Issues
- **Solution**: Use viewport culling (automatic for 10K+ points)
- **Solution**: Limit annotations to <500

### Axes Not Auto-Calculating
- **Check**: All data points have finite coordinates (no NaN/Infinity)
- **Check**: At least 2 points per series for range calculation

### Stream Updates Too Slow
- **Check**: Stream throttling is 60 FPS (16ms) - lower frequency streams update at their rate
- **Check**: Backpressure handling drops frames - check stream rate

---

## Next Steps

1. **Explore Examples**: See `example/lib/main.dart` for comprehensive examples
2. **API Documentation**: Read inline dartdoc for all parameters
3. **Advanced Features**: Interaction callbacks, custom themes, data binding
4. **Performance**: Review performance benchmarks in `test/widgets/integration/`

**Total Time**: ~5 minutes from zero to working, interactive chart! 🎉
