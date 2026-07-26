import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/bar_geometry.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:braven_charts/src/utils/bar_series_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lays out 1,000 styled bars within one 60fps frame on average', () {
    final series = BarChartSeries(
      id: 'benchmark',
      points: [
        for (var index = 0; index < 1000; index++)
          ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
      ],
      barWidthPercent: 0.72,
      minBarLength: 2,
      barStyle: const BarChartStyle(
        cornerRadius: 4,
        gradient: BarGradient(colors: [Color(0xFF34D399), Color(0xFF168AAD)]),
      ),
      trackStyle: const BarTrackStyle(color: Color(0xFFE0F2F1), value: 100),
    );
    const transform = ChartTransform(
      dataXMin: -1,
      dataXMax: 1000,
      dataYMin: 0,
      dataYMax: 110,
      plotWidth: 1600,
      plotHeight: 900,
    );

    for (var warmup = 0; warmup < 5; warmup++) {
      BarGeometryEngine.layout(series: series, transform: transform);
    }

    const iterations = 20;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final geometry = BarGeometryEngine.layout(
        series: series,
        transform: transform,
      );
      expect(geometry, hasLength(1000));
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Bar geometry (1,000 styled bars): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(averageMilliseconds, lessThan(16.67));
  });

  test('virtualizes 100,000 bars within one 60fps frame while panning', () {
    final series = BarChartSeries(
      id: 'virtualized-benchmark',
      points: [
        for (var index = 0; index < 100000; index++)
          ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
      ],
      isXOrdered: true,
      barWidthPercent: 0.72,
      maxWidth: 24,
      labelStyle: const BarLabelStyle(
        show: true,
        collisionPolicy: BarLabelCollisionPolicy.hide,
      ),
    );
    final element = SeriesElement(series: series, transform: _viewport(0));

    // Build the immutable category index outside the measured pan loop.
    expect(element.visibleBarGeometryCount, lessThan(130));

    const iterations = 50;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      element.updateTransform(_viewport(iteration * 1000.0));
      expect(element.visibleBarGeometryCount, lessThan(130));
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Virtualized bar pan (100,000 points): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(averageMilliseconds, lessThan(16.67));
  });

  test('cold-indexes 100,000 ordered bars promptly', () {
    final series = BarChartSeries(
      id: 'cold-index-benchmark',
      points: [
        for (var index = 0; index < 100000; index++)
          ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
      ],
      isXOrdered: true,
      barWidthPercent: 0.72,
      maxWidth: 24,
    );

    SeriesElement buildElement() =>
        SeriesElement(series: series, transform: _viewport(50000));

    for (var warmup = 0; warmup < 3; warmup++) {
      expect(buildElement().visibleBarGeometryCount, lessThan(130));
    }

    const iterations = 10;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      expect(buildElement().visibleBarGeometryCount, lessThan(130));
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Cold virtualized bar index (100,000 ordered points): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    // This is one-time setup work. Per-frame panning remains held to the
    // 16.67ms budget by the viewport benchmark above, while cold indexing
    // follows the 100ms contract used by the other dense chart families.
    expect(averageMilliseconds, lessThan(100));
  });

  test('resolves bounds for 120,000 normalized-stack points promptly', () {
    final series = [
      for (var seriesIndex = 0; seriesIndex < 12; seriesIndex++)
        BarChartSeries(
          id: 'stack-$seriesIndex',
          groupId: 'stress',
          layoutMode: BarLayoutMode.normalizedStacked,
          points: [
            for (var pointIndex = 0; pointIndex < 10000; pointIndex++)
              ChartDataPoint(
                x: pointIndex.toDouble(),
                y: (12 + (pointIndex * 11 + seriesIndex * 7) % 32).toDouble(),
              ),
          ],
          isXOrdered: true,
          barWidthPercent: 0.9,
        ),
    ];

    DataConverter.computeDataBounds(series);
    const iterations = 5;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final bounds = DataConverter.computeDataBounds(series);
      expect(bounds.xMin.isFinite, isTrue);
      expect(bounds.yMax.isFinite, isTrue);
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Dense normalized bounds (120,000 points): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(averageMilliseconds, lessThan(500));
  });

  testWidgets('mounts a viewport over 120,000 bar points promptly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final categories = [
      for (var index = 0; index < 10000; index++) 'Category $index',
    ];
    final series = [
      for (var seriesIndex = 0; seriesIndex < 12; seriesIndex++)
        BarChartSeries(
          id: 'mount-$seriesIndex',
          groupId: 'stress',
          layoutMode: BarLayoutMode.normalizedStacked,
          points: [
            for (var pointIndex = 0; pointIndex < 10000; pointIndex++)
              ChartDataPoint(
                x: pointIndex.toDouble(),
                y: (12 + (pointIndex * 11 + seriesIndex * 7) % 32).toDouble(),
              ),
          ],
          isXOrdered: true,
          barWidthPercent: 0.9,
          labelStyle: const BarLabelStyle(
            show: true,
            collisionPolicy: BarLabelCollisionPolicy.hide,
          ),
        ),
    ];

    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        home: BravenChartPlus(
          showLegend: false,
          series: series,
          xAxisConfig: XAxisConfig(
            categoryAxis: CategoryAxisConfig(
              categories: categories,
              minimumCategoryExtent: 48,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    stopwatch.stop();
    // ignore: avoid_print
    print(
      'Dense chart first frame (120,000 points): '
      '${stopwatch.elapsedMilliseconds}ms',
    );

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final elements = renderBox.debugElements.whereType<SeriesElement>();
    expect(elements, hasLength(12));
    expect(
      elements.fold<int>(
        0,
        (sum, element) => sum + element.visibleBarGeometryCount,
      ),
      lessThan(500),
    );
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    expect(tester.takeException(), isNull);
  });

  test('interpolates the 10,000-mark motion budget within one frame', () {
    final previous = BarChartSeries(
      id: 'motion-budget',
      points: [
        for (var index = 0; index < 10000; index++)
          ChartDataPoint(
            x: index.toDouble(),
            y: (index % 100).toDouble(),
            label: 'Category $index',
          ),
      ],
      isXOrdered: true,
      barWidthPercent: 0.7,
    );
    final next = previous.copyWith(
      points: [
        for (var index = 0; index < 10000; index++)
          ChartDataPoint(
            x: index.toDouble(),
            y: ((index + 20) % 100).toDouble(),
            label: 'Category $index',
          ),
      ],
    );

    for (var warmup = 0; warmup < 3; warmup++) {
      BarSeriesTransition.interpolate(from: previous, to: next, progress: 0.5);
    }
    const iterations = 10;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final frame = BarSeriesTransition.interpolate(
        from: previous,
        to: next,
        progress: 0.5,
      );
      expect(frame.points, hasLength(10000));
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Bar transition interpolation (10,000 points): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(averageMilliseconds, lessThan(16.67));
  });
}

ChartTransform _viewport(double start) => ChartTransform(
  dataXMin: start,
  dataXMax: start + 100,
  dataYMin: 0,
  dataYMax: 110,
  plotWidth: 1600,
  plotHeight: 900,
);
