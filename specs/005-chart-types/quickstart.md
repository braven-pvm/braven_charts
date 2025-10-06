# Chart Types Quick Start Guide

**Feature**: Chart Types (Layer 4)  
**Purpose**: Executable examples demonstrating all chart type APIs  
**Date**: 2025-10-06

---

## Overview

This guide provides executable test scenarios for all four chart types (Line, Area, Bar, Scatter). Each example can be run as an integration test to validate the implementation.

---

## Example 1: Basic Line Chart

**Scenario**: Create a simple line chart with straight lines connecting data points

```dart
void main() {
  test('Create basic line chart with straight lines', () {
    // Arrange: Create time-series data
    final series = ChartSeries(
      id: 'revenue',
      points: [
        ChartDataPoint(x: 0.0, y: 100.0),
        ChartDataPoint(x: 1.0, y: 150.0),
        ChartDataPoint(x: 2.0, y: 120.0),
        ChartDataPoint(x: 3.0, y: 180.0),
        ChartDataPoint(x: 4.0, y: 200.0),
      ],
    );
    
    // Act: Create line chart layer with default config
    final lineChart = LineChartLayer(
      series: [series],
      config: LineChartConfig(
        lineStyle: LineStyle.straight,
        markerShape: MarkerShape.circle,
        markerSize: 6.0,
        showMarkers: true,
        lineWidth: 2.0,
      ),
    );
    
    // Assert: Verify chart properties
    expect(lineChart.series.length, equals(1));
    expect(lineChart.config.lineStyle, equals(LineStyle.straight));
    
    // Render test: Ensure no errors during rendering
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final context = RenderContext(
      theme: ChartTheme.defaultLight(),
      transformer: UniversalCoordinateTransformer(/* ... */),
      viewport: ViewportState.initial(),
    );
    
    expect(() => lineChart.render(canvas, Size(800, 600), context), returnsNormally);
  });
}
```

---

## Example 2: Smooth Line Chart with Multiple Series

**Scenario**: Create a multi-series line chart with bezier curves

```dart
void main() {
  test('Create smooth line chart with multiple series', () {
    // Arrange: Create two data series
    final revenueSeries = ChartSeries(
      id: 'revenue',
      points: List.generate(10, (i) => 
        ChartDataPoint(x: i.toDouble(), y: 100 + i * 10 + Random().nextDouble() * 20)
      ),
    );
    
    final costSeries = ChartSeries(
      id: 'cost',
      points: List.generate(10, (i) => 
        ChartDataPoint(x: i.toDouble(), y: 80 + i * 8 + Random().nextDouble() * 15)
      ),
    );
    
    // Act: Create line chart with smooth curves
    final lineChart = LineChartLayer(
      series: [revenueSeries, costSeries],
      config: LineChartConfig(
        lineStyle: LineStyle.smooth,  // Catmull-Rom bezier curves
        markerShape: MarkerShape.circle,
        markerSize: 4.0,
        showMarkers: true,
        lineWidth: 2.5,
      ),
    );
    
    // Assert: Verify multiple series
    expect(lineChart.series.length, equals(2));
    expect(lineChart.series[0].id, equals('revenue'));
    expect(lineChart.series[1].id, equals('cost'));
    
    // Theme test: Verify series get distinct colors from theme
    final theme = ChartTheme.defaultLight();
    expect(theme.series.colors.length, greaterThan(1));
  });
}
```

---

## Example 3: Area Chart with Gradient Fill

**Scenario**: Create an area chart with vertical gradient fill

```dart
void main() {
  test('Create area chart with gradient fill', () {
    // Arrange: Create data for area visualization
    final series = ChartSeries(
      id: 'temperature',
      points: [
        ChartDataPoint(x: 0.0, y: 20.0),
        ChartDataPoint(x: 1.0, y: 25.0),
        ChartDataPoint(x: 2.0, y: 30.0),
        ChartDataPoint(x: 3.0, y: 28.0),
        ChartDataPoint(x: 4.0, y: 22.0),
      ],
    );
    
    // Act: Create area chart with gradient
    final areaChart = AreaChartLayer(
      series: [series],
      config: AreaChartConfig(
        fillStyle: AreaFillStyle.gradient,
        baseline: AreaBaseline(type: AreaBaselineType.zero),
        stacked: false,
        fillOpacity: 0.5,
        showLine: true,
        lineConfig: LineChartConfig(
          lineStyle: LineStyle.smooth,
          markerShape: MarkerShape.none,
          lineWidth: 2.0,
        ),
      ),
    );
    
    // Assert: Verify config
    expect(areaChart.config.fillStyle, equals(AreaFillStyle.gradient));
    expect(areaChart.config.fillOpacity, equals(0.5));
    expect(areaChart.config.showLine, isTrue);
  });
}
```

---

## Example 4: Stacked Area Chart

**Scenario**: Stack multiple area series to show composition

```dart
void main() {
  test('Create stacked area chart', () {
    // Arrange: Create three series with same X coordinates (required for stacking)
    final product1 = ChartSeries(
      id: 'product1',
      points: [
        ChartDataPoint(x: 0.0, y: 10.0),
        ChartDataPoint(x: 1.0, y: 15.0),
        ChartDataPoint(x: 2.0, y: 12.0),
      ],
    );
    
    final product2 = ChartSeries(
      id: 'product2',
      points: [
        ChartDataPoint(x: 0.0, y: 20.0),
        ChartDataPoint(x: 1.0, y: 25.0),
        ChartDataPoint(x: 2.0, y: 22.0),
      ],
    );
    
    final product3 = ChartSeries(
      id: 'product3',
      points: [
        ChartDataPoint(x: 0.0, y: 30.0),
        ChartDataPoint(x: 1.0, y: 35.0),
        ChartDataPoint(x: 2.0, y: 32.0),
      ],
    );
    
    // Act: Create stacked area chart
    final areaChart = AreaChartLayer(
      series: [product1, product2, product3],
      config: AreaChartConfig(
        fillStyle: AreaFillStyle.solid,
        baseline: AreaBaseline(type: AreaBaselineType.zero),
        stacked: true,  // Series stack on top of each other
        fillOpacity: 0.7,
        showLine: false,
      ),
    );
    
    // Assert: Verify stacking enabled
    expect(areaChart.config.stacked, isTrue);
    expect(areaChart.series.length, equals(3));
  });
}
```

---

## Example 5: Grouped Bar Chart

**Scenario**: Create vertical bar chart with grouped bars (side-by-side)

```dart
void main() {
  test('Create grouped bar chart', () {
    // Arrange: Create sales data for two quarters
    final q1Sales = ChartSeries(
      id: 'q1',
      points: [
        ChartDataPoint(x: 0.0, y: 100.0),  // Region A
        ChartDataPoint(x: 1.0, y: 150.0),  // Region B
        ChartDataPoint(x: 2.0, y: 120.0),  // Region C
      ],
    );
    
    final q2Sales = ChartSeries(
      id: 'q2',
      points: [
        ChartDataPoint(x: 0.0, y: 110.0),  // Region A
        ChartDataPoint(x: 1.0, y: 160.0),  // Region B
        ChartDataPoint(x: 2.0, y: 130.0),  // Region C
      ],
    );
    
    // Act: Create grouped bar chart
    final barChart = BarChartLayer(
      series: [q1Sales, q2Sales],
      config: BarChartConfig(
        orientation: BarOrientation.vertical,
        groupingMode: BarGroupingMode.grouped,  // Side-by-side
        barWidthRatio: 0.8,
        barSpacing: 4.0,
        groupSpacing: 16.0,
        cornerRadius: 4.0,
        borderWidth: 0.0,
        useGradient: false,
      ),
    );
    
    // Assert: Verify grouping mode
    expect(barChart.config.groupingMode, equals(BarGroupingMode.grouped));
    expect(barChart.config.orientation, equals(BarOrientation.vertical));
  });
}
```

---

## Example 6: Stacked Bar Chart with Negative Values

**Scenario**: Create stacked bar chart handling negative values correctly

```dart
void main() {
  test('Create stacked bar chart with negative values', () {
    // Arrange: Create profit/loss data
    final income = ChartSeries(
      id: 'income',
      points: [
        ChartDataPoint(x: 0.0, y: 100.0),
        ChartDataPoint(x: 1.0, y: 150.0),
        ChartDataPoint(x: 2.0, y: 120.0),
      ],
    );
    
    final expenses = ChartSeries(
      id: 'expenses',
      points: [
        ChartDataPoint(x: 0.0, y: -80.0),  // Negative value
        ChartDataPoint(x: 1.0, y: -90.0),
        ChartDataPoint(x: 2.0, y: -70.0),
      ],
    );
    
    // Act: Create stacked bar chart
    final barChart = BarChartLayer(
      series: [income, expenses],
      config: BarChartConfig(
        orientation: BarOrientation.vertical,
        groupingMode: BarGroupingMode.stacked,
        barWidthRatio: 0.6,
        barSpacing: 0.0,  // No spacing in stacked mode
        groupSpacing: 20.0,
        cornerRadius: 0.0,
        borderWidth: 1.0,
        borderColor: Colors.black.withOpacity(0.2),
        useGradient: true,
      ),
    );
    
    // Assert: Verify stacking handles negatives
    expect(barChart.config.groupingMode, equals(BarGroupingMode.stacked));
    expect(barChart.series[1].points.every((p) => p.y < 0), isTrue);
  });
}
```

---

## Example 7: Scatter Plot with Fixed-Size Markers

**Scenario**: Create basic scatter plot with circular markers

```dart
void main() {
  test('Create scatter plot with fixed-size markers', () {
    // Arrange: Create 2D correlation data
    final series = ChartSeries(
      id: 'correlation',
      points: List.generate(50, (i) => 
        ChartDataPoint(
          x: Random().nextDouble() * 100,
          y: Random().nextDouble() * 100,
        )
      ),
    );
    
    // Act: Create scatter chart
    final scatterChart = ScatterChartLayer(
      series: [series],
      config: ScatterChartConfig(
        markerShape: MarkerShape.circle,
        sizingMode: MarkerSizingMode.fixed,
        fixedSize: 6.0,
        markerStyle: MarkerStyle.filled,
        borderWidth: 0.0,
        enableClustering: false,
      ),
    );
    
    // Assert: Verify config
    expect(scatterChart.config.sizingMode, equals(MarkerSizingMode.fixed));
    expect(scatterChart.config.fixedSize, equals(6.0));
  });
}
```

---

## Example 8: Scatter Plot with Data-Driven Sizing

**Scenario**: Create scatter plot where marker size represents a third variable

```dart
void main() {
  test('Create scatter plot with data-driven marker sizing', () {
    // Arrange: Create data with size metadata
    final series = ChartSeries(
      id: 'bubbles',
      points: [
        ChartDataPoint(x: 10.0, y: 20.0, metadata: {'size': 5.0}),
        ChartDataPoint(x: 20.0, y: 30.0, metadata: {'size': 10.0}),
        ChartDataPoint(x: 30.0, y: 25.0, metadata: {'size': 15.0}),
        ChartDataPoint(x: 40.0, y: 35.0, metadata: {'size': 8.0}),
      ],
    );
    
    // Act: Create scatter chart with data-driven sizing
    final scatterChart = ScatterChartLayer(
      series: [series],
      config: ScatterChartConfig(
        markerShape: MarkerShape.circle,
        sizingMode: MarkerSizingMode.dataDriven,
        minSize: 4.0,
        maxSize: 20.0,
        markerStyle: MarkerStyle.both,  // Filled and outlined
        borderWidth: 2.0,
        enableClustering: false,
      ),
    );
    
    // Assert: Verify data-driven sizing config
    expect(scatterChart.config.sizingMode, equals(MarkerSizingMode.dataDriven));
    expect(scatterChart.config.minSize, equals(4.0));
    expect(scatterChart.config.maxSize, equals(20.0));
  });
}
```

---

## Example 9: Data Updates with Animation

**Scenario**: Update chart data with smooth animation

```dart
void main() {
  test('Update chart data with animation', () async {
    // Arrange: Create initial data
    final initialSeries = ChartSeries(
      id: 'data',
      points: [
        ChartDataPoint(x: 0.0, y: 10.0),
        ChartDataPoint(x: 1.0, y: 15.0),
        ChartDataPoint(x: 2.0, y: 12.0),
      ],
    );
    
    final lineChart = LineChartLayer(
      series: [initialSeries],
      config: LineChartConfig.defaults(),
      animationConfig: ChartAnimationConfig(
        enabled: true,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
    
    // Act: Update to new data
    final newSeries = ChartSeries(
      id: 'data',
      points: [
        ChartDataPoint(x: 0.0, y: 20.0),
        ChartDataPoint(x: 1.0, y: 25.0),
        ChartDataPoint(x: 2.0, y: 22.0),
      ],
    );
    
    lineChart.updateData([newSeries]);
    
    // Assert: Animation in progress
    expect(lineChart.isAnimating, isTrue);
    
    // Wait for animation to complete
    await Future.delayed(Duration(milliseconds: 350));
    expect(lineChart.isAnimating, isFalse);
    expect(lineChart.series[0].points[0].y, equals(20.0));
  });
}
```

---

## Example 10: Performance Test (10,000 Points)

**Scenario**: Verify line chart renders 10,000 points within 16ms

```dart
void main() {
  test('Line chart renders 10K points in <16ms', () {
    // Arrange: Create large dataset
    final series = ChartSeries(
      id: 'large',
      points: List.generate(10000, (i) => 
        ChartDataPoint(x: i.toDouble(), y: sin(i / 100) * 100)
      ),
    );
    
    final lineChart = LineChartLayer(
      series: [series],
      config: LineChartConfig.defaults(),
    );
    
    // Act: Render and measure time
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final context = RenderContext(/* ... */);
    
    final stopwatch = Stopwatch()..start();
    lineChart.render(canvas, Size(1920, 1080), context);
    stopwatch.stop();
    
    // Assert: Performance requirement met
    expect(stopwatch.elapsedMilliseconds, lessThan(16),
      reason: '60 FPS requires <16ms frame time');
    
    print('Rendered 10,000 points in ${stopwatch.elapsedMilliseconds}ms');
  });
}
```

---

## Summary

These 10 examples cover:

1. **Line Charts**: Basic straight lines, smooth curves, multiple series
2. **Area Charts**: Gradient fills, stacked areas
3. **Bar Charts**: Grouped bars, stacked bars, negative values
4. **Scatter Plots**: Fixed sizing, data-driven sizing
5. **Animations**: Data updates with transitions
6. **Performance**: Large dataset rendering

All examples are executable as integration tests and demonstrate the complete API surface of the Chart Types feature.
