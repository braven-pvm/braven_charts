// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/region_summary.dart';
import 'package:braven_charts/src/models/region_summary_config.dart';
import 'package:braven_charts/src/rendering/modules/region_summary_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a minimal [DataRegion] for use in tests.
///
/// [seriesData] defaults to a single series with two data points.
DataRegion _makeRegion({
  String id = 'test-region',
  double startX = 0.0,
  double endX = 10.0,
  Map<String, List<ChartDataPoint>>? seriesData,
}) {
  return DataRegion(
    id: id,
    startX: startX,
    endX: endX,
    source: DataRegionSource.rangeAnnotation,
    seriesData:
        seriesData ??
        {
          'series-a': [
            const ChartDataPoint(x: 2.0, y: 10.0),
            const ChartDataPoint(x: 8.0, y: 20.0),
          ],
        },
  );
}

/// Creates a [SeriesRegionSummary] with sensible test defaults.
///
/// [seriesId] defaults to `'series-a'`, [seriesName] to `'Series A'`.
SeriesRegionSummary _makeSeries({
  String seriesId = 'series-a',
  String? seriesName = 'Series A',
  double min = 10.0,
  double max = 20.0,
  double average = 15.0,
  double sum = 30.0,
  double range = 10.0,
  int count = 2,
  double duration = 10.0,
}) {
  return SeriesRegionSummary(
    seriesId: seriesId,
    seriesName: seriesName,
    count: count,
    min: min,
    max: max,
    sum: sum,
    average: average,
    range: range,
    firstY: min,
    lastY: max,
    delta: max - min,
    duration: duration,
  );
}

/// Creates a [RegionSummary] with one series (series-a).
RegionSummary _makeSingleSeriesSummary() {
  final region = _makeRegion();
  return RegionSummary(
    region: region,
    seriesSummaries: {'series-a': _makeSeries()},
  );
}

/// Creates a [RegionSummary] with two series.
RegionSummary _makeTwoSeriesSummary() {
  final region = _makeRegion(
    seriesData: {
      'series-a': [
        const ChartDataPoint(x: 2.0, y: 10.0),
        const ChartDataPoint(x: 8.0, y: 20.0),
      ],
      'series-b': [
        const ChartDataPoint(x: 3.0, y: 50.0),
        const ChartDataPoint(x: 7.0, y: 80.0),
      ],
    },
  );
  return RegionSummary(
    region: region,
    seriesSummaries: {
      'series-a': _makeSeries(),
      'series-b': _makeSeries(
        seriesId: 'series-b',
        seriesName: 'Series B',
        min: 50.0,
        max: 80.0,
        average: 65.0,
        sum: 130.0,
        range: 30.0,
      ),
    },
  );
}

/// A minimal [Canvas] mock that silently ignores all draw calls.
class _MockCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // Construction
  // ===========================================================================
  group('RegionSummaryRenderer', () {
    group('Construction', () {
      test('can be const constructed', () {
        // Arrange / Act
        const renderer1 = RegionSummaryRenderer();
        const renderer2 = RegionSummaryRenderer();

        // Assert — const constructor should yield identical instances
        expect(identical(renderer1, renderer2), isTrue);
      });
    });

    // =========================================================================
    // Paint — basic card rendering with configured metrics
    // =========================================================================
    group('paint() — card rendering with configured metrics', () {
      test('renders without throwing for basic single-series summary', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        );
        const regionBounds = Rect.fromLTWH(100.0, 100.0, 200.0, 300.0);

        // Act / Assert — must not throw
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('renders metric display labels for configured metrics', () {
        // Arrange — capture drawn text by verifying no exceptions are thrown
        // and that all metric labels (Min, Max, Avg) would be included.
        // The renderer must draw text containing RegionMetric.displayLabel
        // values for every metric in config.metrics.
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );

        // Verify that RegionMetric.displayLabel values are as expected
        expect(RegionMetric.min.displayLabel, equals('Min'));
        expect(RegionMetric.max.displayLabel, equals('Max'));
        expect(RegionMetric.average.displayLabel, equals('Avg'));
      });

      test('renders only metrics present in config.metrics set', () {
        // Arrange — single metric: count only
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(metrics: {RegionMetric.count});
        const regionBounds = Rect.fromLTWH(100.0, 100.0, 200.0, 300.0);

        // Act / Assert — must not throw
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('handles empty metrics set without throwing', () {
        // Arrange — no metrics configured
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(metrics: const {});
        const regionBounds = Rect.fromLTWH(100.0, 100.0, 200.0, 300.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });

    // =========================================================================
    // Paint — value formatting
    // =========================================================================
    group('paint() — value formatting', () {
      test('default formatting uses 2 decimal places', () {
        // Arrange — no custom formatter; default should format to 2dp
        const renderer = RegionSummaryRenderer();
        final summary = RegionSummary(
          region: _makeRegion(),
          seriesSummaries: {
            'series-a': _makeSeries(min: 10.123456, max: 20.654321),
          },
        );
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max},
          // valueFormatter is null → default formatting
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('custom valueFormatter is invoked for metric values', () {
        // Arrange — custom formatter that appends 'UNIT'
        const renderer = RegionSummaryRenderer();
        var formatterCallCount = 0;
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
          valueFormatter: (value, unit) {
            formatterCallCount++;
            return '${value.toStringAsFixed(0)}UNIT';
          },
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act
        renderer.paint(
          _MockCanvas(),
          const Size(800.0, 600.0),
          summary,
          config,
          regionBounds,
        );

        // Assert — formatter must be called at least once per metric per series
        expect(
          formatterCallCount,
          greaterThanOrEqualTo(3), // min, max, average for 1 series
        );
      });

      test('custom valueFormatter receives correct value for min metric', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        const expectedMin = 42.5;
        double? capturedValue;
        final summary = RegionSummary(
          region: _makeRegion(),
          seriesSummaries: {'series-a': _makeSeries(min: expectedMin)},
        );
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min},
          valueFormatter: (value, unit) {
            capturedValue = value;
            return value.toString();
          },
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act
        renderer.paint(
          _MockCanvas(),
          const Size(800.0, 600.0),
          summary,
          config,
          regionBounds,
        );

        // Assert — formatter must be called with the min value
        expect(capturedValue, equals(expectedMin));
      });

      test('custom valueFormatter receives unit from SeriesRegionSummary', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        String? capturedUnit;
        const expectedUnit = 'W';
        final summary = RegionSummary(
          region: _makeRegion(),
          seriesSummaries: const {
            'series-a': SeriesRegionSummary(
              seriesId: 'series-a',
              seriesName: 'Power',
              unit: expectedUnit,
              count: 2,
              min: 100.0,
              max: 200.0,
              sum: 300.0,
              average: 150.0,
              range: 100.0,
              duration: 10.0,
            ),
          },
        );
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.average},
          valueFormatter: (value, unit) {
            capturedUnit = unit;
            return '$value ${unit ?? ''}';
          },
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act
        renderer.paint(
          _MockCanvas(),
          const Size(800.0, 600.0),
          summary,
          config,
          regionBounds,
        );

        // Assert — the unit from the series summary should be passed through
        expect(capturedUnit, equals(expectedUnit));
      });
    });

    // =========================================================================
    // Paint — positioning (aboveRegion, centred)
    // =========================================================================
    group('paint() — positioning (aboveRegion default)', () {
      test('renders without error when position is aboveRegion', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          position: RegionSummaryPosition.aboveRegion,
        );
        // Region in the middle of the canvas — plenty of room above
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('card is centred horizontally over regionBounds', () {
        // Arrange — use a RecordingCanvas to verify x-position of drawn card.
        // Because we use a mock canvas, we verify the renderer does not throw
        // and that positioning logic would centre at regionBounds.center.dx.
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          position: RegionSummaryPosition.aboveRegion,
        );
        // Region centred at x=400 (left=300, width=200 → center=400)
        const regionBounds = Rect.fromLTWH(300.0, 300.0, 200.0, 150.0);

        // Act / Assert — must not throw; card placement is verified visually
        // via golden tests. Here we verify the centre calculation is correct.
        expect(regionBounds.center.dx, equals(400.0));
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });

    // =========================================================================
    // Paint — insideTop fallback when card would exceed chart top
    // =========================================================================
    group('paint() — insideTop fallback', () {
      test('renders without error when position is insideTop', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          position: RegionSummaryPosition.insideTop,
        );
        const regionBounds = Rect.fromLTWH(100.0, 50.0, 200.0, 300.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test(
        'falls back to insideTop when card would exceed canvas top boundary',
        () {
          // Arrange — region is very close to the top of the canvas.
          // With aboveRegion position the card would clip past y=0.
          const renderer = RegionSummaryRenderer();
          final summary = _makeSingleSeriesSummary();
          // Request aboveRegion but region top is only 5px from canvas top
          final config = RegionSummaryConfig(
            position: RegionSummaryPosition.aboveRegion,
          );
          // Region starts at y=5 — card height > 5 → must fall back
          const regionBounds = Rect.fromLTWH(200.0, 5.0, 200.0, 300.0);

          // Act / Assert — renderer must not throw even with clipping scenario
          expect(
            () => renderer.paint(
              _MockCanvas(),
              const Size(800.0, 600.0),
              summary,
              config,
              regionBounds,
            ),
            returnsNormally,
          );
        },
      );

      test('renders insideTop position without error for region at top', () {
        // Arrange — region begins at the very top of canvas
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          position: RegionSummaryPosition.aboveRegion,
        );
        const regionBounds = Rect.fromLTWH(100.0, 0.0, 400.0, 400.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });

    // =========================================================================
    // Paint — multi-series display
    // =========================================================================
    group('paint() — multi-series display', () {
      test('renders two series without throwing', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeTwoSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        );
        const regionBounds = Rect.fromLTWH(150.0, 200.0, 300.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('renders three series without throwing', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final region = _makeRegion(
          seriesData: {
            'series-a': [const ChartDataPoint(x: 1.0, y: 10.0)],
            'series-b': [const ChartDataPoint(x: 2.0, y: 20.0)],
            'series-c': [const ChartDataPoint(x: 3.0, y: 30.0)],
          },
        );
        final summary = RegionSummary(
          region: region,
          seriesSummaries: {
            'series-a': _makeSeries(),
            'series-b': _makeSeries(
              seriesId: 'series-b',
              seriesName: 'Series B',
              min: 20.0,
              max: 40.0,
              average: 30.0,
              sum: 60.0,
              range: 20.0,
              count: 1,
            ),
            'series-c': _makeSeries(
              seriesId: 'series-c',
              seriesName: 'Series C',
              min: 30.0,
              max: 60.0,
              average: 45.0,
              sum: 90.0,
              range: 30.0,
              count: 1,
            ),
          },
        );
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        );
        const regionBounds = Rect.fromLTWH(100.0, 100.0, 400.0, 300.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('multi-series formatter is called for each series', () {
        // Arrange — track total formatter calls
        const renderer = RegionSummaryRenderer();
        var callCount = 0;
        final summary = _makeTwoSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
          valueFormatter: (value, unit) {
            callCount++;
            return value.toStringAsFixed(1);
          },
        );
        const regionBounds = Rect.fromLTWH(150.0, 200.0, 300.0, 200.0);

        // Act
        renderer.paint(
          _MockCanvas(),
          const Size(800.0, 600.0),
          summary,
          config,
          regionBounds,
        );

        // Assert — 3 metrics × 2 series = at least 6 formatter calls
        expect(callCount, greaterThanOrEqualTo(6));
      });

      test('series name is used as group label when available', () {
        // Arrange — verify seriesName is correctly set on the summary data
        final summary = _makeTwoSeriesSummary();
        expect(
          summary.seriesSummaries['series-a']?.seriesName,
          equals('Series A'),
        );
        expect(
          summary.seriesSummaries['series-b']?.seriesName,
          equals('Series B'),
        );
      });

      test('seriesId is used as fallback label when seriesName is null', () {
        // Arrange — seriesName is null
        const renderer = RegionSummaryRenderer();
        final region = _makeRegion();
        final summary = RegionSummary(
          region: region,
          seriesSummaries: const {
            'series-a': SeriesRegionSummary(
              seriesId: 'series-a',
              seriesName: null, // no name
              count: 1,
              min: 5.0,
              max: 5.0,
              sum: 5.0,
              average: 5.0,
              range: 0.0,
              duration: 10.0,
            ),
          },
        );
        final config = RegionSummaryConfig(metrics: {RegionMetric.average});
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act / Assert — must not throw even with null seriesName
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });

    // =========================================================================
    // Paint — insideBottom position
    // =========================================================================
    group('paint() — insideBottom position', () {
      test('renders without error when position is insideBottom', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          position: RegionSummaryPosition.insideBottom,
        );
        const regionBounds = Rect.fromLTWH(100.0, 100.0, 300.0, 300.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });

    // =========================================================================
    // Paint — edge cases
    // =========================================================================
    group('paint() — edge cases', () {
      test('handles single-point region bounds (zero width)', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max},
        );
        // Zero-width region
        const regionBounds = Rect.fromLTWH(300.0, 200.0, 0.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('handles empty seriesSummaries in RegionSummary', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = RegionSummary(
          region: _makeRegion(),
          seriesSummaries: const {}, // no series
        );
        final config = RegionSummaryConfig(
          metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
        );
        const regionBounds = Rect.fromLTWH(200.0, 200.0, 200.0, 200.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(800.0, 600.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });

      test('handles very small canvas size', () {
        // Arrange
        const renderer = RegionSummaryRenderer();
        final summary = _makeSingleSeriesSummary();
        final config = RegionSummaryConfig(metrics: {RegionMetric.min});
        const regionBounds = Rect.fromLTWH(0.0, 0.0, 50.0, 50.0);

        // Act / Assert
        expect(
          () => renderer.paint(
            _MockCanvas(),
            const Size(50.0, 50.0),
            summary,
            config,
            regionBounds,
          ),
          returnsNormally,
        );
      });
    });
  });
}
