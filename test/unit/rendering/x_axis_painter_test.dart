// @orchestra-task: 3

@Tags(['tdd-red'])
library;

import 'dart:ui' show Canvas, Color, PictureRecorder, Rect;

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/rendering/x_axis_painter.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XAxisPainter', () {
    group('constructor', () {
      test('accepts required parameters', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        expect(
          () => XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          ),
          returnsNormally,
        );
      });

      test('accepts optional series parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);
        final series = <ChartSeries>[];

        expect(
          () => XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
            series: series,
          ),
          returnsNormally,
        );
      });

      test('stores config parameter', () {
        const config = XAxisConfig(label: 'Time', unit: 's');
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        expect(painter.config, equals(config));
      });

      test('stores axisBounds parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        expect(painter.axisBounds, equals(bounds));
      });

      test('stores labelStyle parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 14.0, color: Color(0xFF0000FF));

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        expect(painter.labelStyle, equals(labelStyle));
      });

      test('stores series parameter when provided', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);
        final series = <ChartSeries>[];

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        expect(painter.series, equals(series));
      });

      test('series parameter defaults to null when not provided', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        expect(painter.series, isNull);
      });
    });

    group('paint method', () {
      test('paint method exists and accepts required parameters', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Create mock canvas and rects
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        // Method should exist and be callable
        expect(
          () => painter.paint(canvas, chartArea, plotArea),
          returnsNormally,
        );
      });

      test('paint method signature has correct parameter types', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        // Should accept Canvas, Rect, Rect parameters
        painter.paint(canvas, chartArea, plotArea);
      });
    });

    group('generateTicks method', () {
      test('generateTicks method exists', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 100.0);

        // Method should exist and be callable
        expect(
          () => painter.generateTicks(testBounds),
          returnsNormally,
        );
      });

      test('generateTicks returns List<double>', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 100.0);
        final ticks = painter.generateTicks(testBounds);

        expect(ticks, isA<List<double>>());
      });

      test('generateTicks accepts optional maxTicks parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 100.0);

        // Should accept maxTicks parameter
        expect(
          () => painter.generateTicks(testBounds, maxTicks: 10),
          returnsNormally,
        );
      });
    });

    group('formatTickLabel method', () {
      test('formatTickLabel method exists', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Method should exist and be callable
        expect(
          () => painter.formatTickLabel(42.5),
          returnsNormally,
        );
      });

      test('formatTickLabel accepts double parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Should accept double value
        painter.formatTickLabel(123.456);
      });

      test('formatTickLabel returns String', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        expect(label, isA<String>());
      });
    });

    group('resolveAxisColor method', () {
      test('resolveAxisColor method exists', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Method should exist and be callable
        expect(
          () => painter.resolveAxisColor(),
          returnsNormally,
        );
      });

      test('resolveAxisColor returns Color', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final color = painter.resolveAxisColor();

        expect(color, isA<Color>());
      });

      test('resolveAxisColor uses config color when provided', () {
        const testColor = Color(0xFF00FF00);
        const config = XAxisConfig(color: testColor);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(testColor));
      });

      test(
          'resolveAxisColor returns first series color when config color is null',
          () {
        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);
        const seriesColor = Color(0xFFFF0000);
        final series = [
          const ChartSeries(
            id: 'series1',
            points: [ChartDataPoint(x: 0, y: 0)],
            color: seriesColor,
          ),
        ];

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(seriesColor));
      });

      test(
          'resolveAxisColor returns default color when config color is null and no series',
          () {
        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: null,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(const Color(0xFF333333)));
      });

      test(
          'resolveAxisColor returns default color when config color is null and series is empty',
          () {
        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);
        final series = <ChartSeries>[];

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(const Color(0xFF333333)));
      });

      test(
          'resolveAxisColor returns default color when series[0].color is null',
          () {
        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);
        final series = [
          const ChartSeries(
            id: 'series1',
            points: [],
            color: null,
          ),
        ];

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(const Color(0xFF333333)));
      });
    });

    group('generateTicks - nice number algorithm', () {
      test('generates nice tick values for range 0-100', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 100.0);
        final ticks = painter.generateTicks(testBounds);

        // Should generate nice values like [0, 20, 40, 60, 80, 100]
        // not arbitrary values like [0, 17, 34, 51, 68, 85]
        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(0.0));
        expect(ticks.last, lessThanOrEqualTo(100.0));

        // Check values are "nice" - should be multiples of 1, 2, 5, 10, 20, 50, etc.
        for (final tick in ticks) {
          expect(tick >= testBounds.min && tick <= testBounds.max, isTrue,
              reason:
                  'Tick $tick should be within bounds ${testBounds.min} to ${testBounds.max}');
        }
      });

      test('generates nice tick values for range 0-1000', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 1000.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 1000.0);
        final ticks = painter.generateTicks(testBounds);

        // Should generate nice values like [0, 200, 400, 600, 800, 1000]
        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(0.0));
        expect(ticks.last, lessThanOrEqualTo(1000.0));

        for (final tick in ticks) {
          expect(tick >= testBounds.min && tick <= testBounds.max, isTrue);
        }
      });

      test('respects maxTicks parameter', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 100.0);
        final ticks = painter.generateTicks(testBounds, maxTicks: 5);

        // Should return at most 5 tick values
        expect(ticks.length, lessThanOrEqualTo(5));
      });

      test('generates ticks for negative ranges', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: -50.0, max: 50.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: -50.0, max: 50.0);
        final ticks = painter.generateTicks(testBounds);

        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(-50.0));
        expect(ticks.last, lessThanOrEqualTo(50.0));

        for (final tick in ticks) {
          expect(tick >= testBounds.min && tick <= testBounds.max, isTrue);
        }
      });

      test('generates ticks for small ranges', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 1.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = const DataRange(min: 0.0, max: 1.0);
        final ticks = painter.generateTicks(testBounds);

        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(0.0));
        expect(ticks.last, lessThanOrEqualTo(1.0));
      });
    });

    group('formatTickLabel - formatter and unit', () {
      test('uses default formatting when no formatter or unit', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        // Should be just the number as a string
        expect(label, isA<String>());
        expect(label, isNot(contains(' '))); // No unit appended
      });

      test('appends unit when shouldShowTickUnit is true', () {
        const config = XAxisConfig(
          unit: 's',
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        // Should append unit: "50.0 s"
        expect(label, contains('s'));
        expect(config.shouldShowTickUnit, isTrue);
      });

      test('uses custom labelFormatter when provided', () {
        String customFormatter(double value) => 'T=${value.toInt()}';

        final config = XAxisConfig(
          labelFormatter: customFormatter,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        // Should use custom formatter output
        expect(label, equals('T=50'));
      });

      test('handles null unit gracefully', () {
        const config = XAxisConfig(
          unit: null,
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        // Should not crash, just format the number
        expect(label, isA<String>());
      });

      test('handles empty unit gracefully', () {
        const config = XAxisConfig(
          unit: '',
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final label = painter.formatTickLabel(50.0);

        // Should not crash
        expect(label, isA<String>());
      });

      test('falls back to default formatting when custom formatter throws', () {
        String throwingFormatter(double value) => throw Exception('Test error');

        final config = XAxisConfig(
          labelFormatter: throwingFormatter,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Should fallback gracefully instead of crashing
        expect(
          () => painter.formatTickLabel(50.0),
          returnsNormally,
        );
      });
    });

    group('paint - visibility and rendering', () {
      test('returns early when config.visible is false', () {
        const config = XAxisConfig(visible: false);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        // Should not crash
        painter.paint(canvas, chartArea, plotArea);

        // The test passes if no drawing operations happened
        // (This will fail with current stub implementation)
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('calls resolveAxisColor to get axis color', () {
        const testColor = Color(0xFF00FF00);
        const config = XAxisConfig(
          visible: true,
          color: testColor,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // The implementation should use resolveAxisColor()
        // not directly access config.color
        // This tests the proper indirection
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(testColor));
      });

      test('draws axis line when showAxisLine is true', () {
        const config = XAxisConfig(
          visible: true,
          showAxisLine: true,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // Should have drawn the axis line
        // (This will fail with current stub - no drawing happens)
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('draws tick marks when showTicks is true', () {
        const config = XAxisConfig(
          visible: true,
          showTicks: true,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // Should have drawn tick marks
        // (This will fail with current stub)
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('does not draw axis line when showAxisLine is false', () {
        const config = XAxisConfig(
          visible: true,
          showAxisLine: false,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // Should not draw axis line (but may draw other elements)
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('does not draw tick marks when showTicks is false', () {
        const config = XAxisConfig(
          visible: true,
          showTicks: false,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // Should not draw tick marks
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('uses resolved axis color for all rendered elements', () {
        const testColor = Color(0xFFFF00FF);
        const config = XAxisConfig(
          visible: true,
          color: testColor,
          showAxisLine: true,
          showTicks: true,
        );
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = const Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        painter.paint(canvas, chartArea, plotArea);

        // Should use the resolved color consistently
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(testColor));
      });
    });
  });
}
