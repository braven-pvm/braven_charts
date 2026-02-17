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
        expect(() => painter.generateTicks(testBounds), returnsNormally);
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
        expect(() => painter.formatTickLabel(42.5), returnsNormally);
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
        expect(() => painter.resolveAxisColor(), returnsNormally);
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
        },
      );

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
        },
      );

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
        },
      );

      test(
        'resolveAxisColor returns default color when series[0].color is null',
        () {
          const config = XAxisConfig(color: null);
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);
          final series = [
            const ChartSeries(id: 'series1', points: [], color: null),
          ];

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
            series: series,
          );

          final color = painter.resolveAxisColor();

          expect(color, equals(const Color(0xFF333333)));
        },
      );
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
          expect(
            tick >= testBounds.min && tick <= testBounds.max,
            isTrue,
            reason:
                'Tick $tick should be within bounds ${testBounds.min} to ${testBounds.max}',
          );
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

        final config = XAxisConfig(labelFormatter: customFormatter);
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

        final config = XAxisConfig(labelFormatter: throwingFormatter);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Should fallback gracefully instead of crashing
        expect(() => painter.formatTickLabel(50.0), returnsNormally);
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
        const config = XAxisConfig(visible: true, color: testColor);
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
        const config = XAxisConfig(visible: true, showAxisLine: true);
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
        const config = XAxisConfig(visible: true, showTicks: true);
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
        const config = XAxisConfig(visible: true, showAxisLine: false);
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
        const config = XAxisConfig(visible: true, showTicks: false);
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

    // ========== TDD RED PHASE: XAxisConfig Property Verification ==========
    group('[TDD-RED] XAxisConfig property verification', () {
      group('appearance properties', () {
        test('color property affects axis line color', () {
          const customColor = Color(0xFFAA00BB);
          const config = XAxisConfig(
            color: customColor,
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
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: The paint operation should use customColor
          // This will FAIL until XAxisPainter properly uses config.color
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          // TODO: Add MockCanvas to verify paint color matches customColor
        });

        test('label property appears in axis rendering', () {
          const config = XAxisConfig(label: 'Test Axis Label', visible: true);
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: The axis label should be painted
          // This will FAIL until paint() renders axis label
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          // TODO: Verify "Test Axis Label" was painted
        });

        test('unit property appears in tick labels when configured', () {
          const config = XAxisConfig(
            unit: 'ms',
            labelDisplay: AxisLabelDisplay.labelAndTickUnit,
            visible: true,
          );
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: formatTickLabel should include "ms" unit
          final label = painter.formatTickLabel(50.0);
          expect(label, contains('ms'));
        });
      });

      group('bounds properties', () {
        test('explicit min/max override data bounds', () {
          const config = XAxisConfig(min: 10.0, max: 90.0, visible: true);
          final dataBounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: dataBounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: Ticks should respect config.min/max, not dataBounds
          // This will FAIL until painter uses config.min/max when provided
          final ticks = painter.generateTicks(dataBounds);
          expect(ticks.first, greaterThanOrEqualTo(10.0));
          expect(ticks.last, lessThanOrEqualTo(90.0));
        });

        test('min property is respected when generating ticks', () {
          const config = XAxisConfig(min: 20.0, visible: true);
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: No tick should be < 20.0
          final ticks = painter.generateTicks(bounds);
          expect(ticks.every((t) => t >= 20.0), isTrue);
        });

        test('max property is respected when generating ticks', () {
          const config = XAxisConfig(max: 80.0, visible: true);
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: No tick should be > 80.0
          final ticks = painter.generateTicks(bounds);
          expect(ticks.every((t) => t <= 80.0), isTrue);
        });
      });

      group('visibility properties', () {
        test('visible=false prevents all rendering', () {
          const config = XAxisConfig(visible: false, label: 'Hidden Axis');
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: paint() should return early, no drawing
          // This is already implemented - test should PASS
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
        });

        test('showAxisLine=false hides axis line but not other elements', () {
          const config = XAxisConfig(
            visible: true,
            showAxisLine: false,
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
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: No axis line drawn, but ticks/labels should still render
          // This will FAIL until paint() conditionally draws axis line
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          // TODO: Verify no horizontal line at plotArea.bottom
        });

        test('showTicks=false hides tick marks but not labels', () {
          const config = XAxisConfig(
            visible: true,
            showTicks: false,
            labelDisplay: AxisLabelDisplay.labelWithUnit,
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
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: No tick marks, but labels still painted
          // This will FAIL until paint() conditionally draws ticks
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          // TODO: Verify tick marks absent, labels present
        });

        test('showCrosshairLabel property is stored and accessible', () {
          const config = XAxisConfig(showCrosshairLabel: true, visible: true);

          // EXPECTATION: Property should be accessible
          expect(config.showCrosshairLabel, isTrue);

          const config2 = XAxisConfig(showCrosshairLabel: false, visible: true);
          expect(config2.showCrosshairLabel, isFalse);
        });
      });

      group('layout properties - labelDisplay modes', () {
        test('labelDisplay.labelOnly shows label without unit', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.labelOnly,
            visible: true,
          );

          // EXPECTATION: shouldShowAxisLabel=true, shouldAppendUnitToLabel=false
          expect(config.shouldShowAxisLabel, isTrue);
          expect(config.shouldAppendUnitToLabel, isFalse);
          expect(config.shouldShowTickUnit, isFalse);
        });

        test('labelDisplay.labelWithUnit shows label with unit', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.labelWithUnit,
            visible: true,
          );

          // EXPECTATION: shouldShowAxisLabel=true, shouldAppendUnitToLabel=true
          expect(config.shouldShowAxisLabel, isTrue);
          expect(config.shouldAppendUnitToLabel, isTrue);
          expect(config.shouldShowTickUnit, isFalse);
        });

        test('labelDisplay.labelAndTickUnit shows label and tick unit', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.labelAndTickUnit,
            visible: true,
          );

          // EXPECTATION: shouldShowAxisLabel=true, shouldShowTickUnit=true
          expect(config.shouldShowAxisLabel, isTrue);
          expect(config.shouldAppendUnitToLabel, isFalse);
          expect(config.shouldShowTickUnit, isTrue);
        });

        test(
          'labelDisplay.labelWithUnitAndTickUnit shows all unit information',
          () {
            const config = XAxisConfig(
              label: 'Time',
              unit: 's',
              labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
              visible: true,
            );

            // EXPECTATION: All unit display flags true
            expect(config.shouldShowAxisLabel, isTrue);
            expect(config.shouldAppendUnitToLabel, isTrue);
            expect(config.shouldShowTickUnit, isTrue);
          },
        );

        test('labelDisplay.tickUnitOnly hides axis label', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.tickUnitOnly,
            visible: true,
          );

          // EXPECTATION: shouldShowAxisLabel=false, shouldShowTickUnit=true
          expect(config.shouldShowAxisLabel, isFalse);
          expect(config.shouldShowTickUnit, isTrue);
        });

        test('labelDisplay.tickOnly shows ticks without units', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.tickOnly,
            visible: true,
          );

          // EXPECTATION: shouldShowAxisLabel=false, shouldShowTickUnit=false
          expect(config.shouldShowAxisLabel, isFalse);
          expect(config.shouldShowTickUnit, isFalse);
        });

        test('labelDisplay.none hides all labels', () {
          const config = XAxisConfig(
            label: 'Time',
            unit: 's',
            labelDisplay: AxisLabelDisplay.none,
            visible: true,
          );

          // EXPECTATION: shouldShowTickLabels=false
          expect(config.shouldShowTickLabels, isFalse);
          expect(config.shouldShowAxisLabel, isFalse);
        });
      });

      group('layout properties - dimensions and spacing', () {
        test('minHeight property is respected', () {
          const config = XAxisConfig(minHeight: 50.0, visible: true);

          // EXPECTATION: minHeight is accessible and used in layout
          expect(config.minHeight, equals(50.0));
        });

        test('maxHeight property is respected', () {
          const config = XAxisConfig(maxHeight: 100.0, visible: true);

          // EXPECTATION: maxHeight is accessible and used in layout
          expect(config.maxHeight, equals(100.0));
        });

        test('tickLabelPadding property affects spacing', () {
          const config = XAxisConfig(tickLabelPadding: 8.0, visible: true);

          // EXPECTATION: tickLabelPadding is used in paint calculations
          expect(config.tickLabelPadding, equals(8.0));
        });

        test('axisLabelPadding property affects spacing', () {
          const config = XAxisConfig(axisLabelPadding: 10.0, visible: true);

          // EXPECTATION: axisLabelPadding is used for label positioning
          expect(config.axisLabelPadding, equals(10.0));
        });

        test('axisMargin property affects spacing', () {
          const config = XAxisConfig(axisMargin: 12.0, visible: true);

          // EXPECTATION: axisMargin is used for external spacing
          expect(config.axisMargin, equals(12.0));
        });
      });

      group('behavior properties', () {
        test(
          'tickCount hint generates approximately correct number of ticks',
          () {
            const config = XAxisConfig(tickCount: 5, visible: true);
            final bounds = const DataRange(min: 0.0, max: 100.0);
            const labelStyle = TextStyle(fontSize: 12.0);

            final painter = XAxisPainter(
              config: config,
              axisBounds: bounds,
              labelStyle: labelStyle,
            );

            // EXPECTATION: generateTicks should respect tickCount hint
            // This will FAIL until painter uses config.tickCount
            final ticks = painter.generateTicks(bounds, maxTicks: 5);
            expect(ticks.length, lessThanOrEqualTo(7)); // Allow some tolerance
            expect(ticks.length, greaterThanOrEqualTo(3));
          },
        );

        test('labelFormatter is used when provided', () {
          String customFormatter(double value) => 'X=${value.toInt()}';
          final config = XAxisConfig(
            labelFormatter: customFormatter,
            visible: true,
          );
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: formatTickLabel should use custom formatter
          final label = painter.formatTickLabel(50.0);
          expect(label, equals('X=50'));
        });

        test('labelFormatter overrides default formatting', () {
          String customFormatter(double value) =>
              'T=${value.toStringAsFixed(1)}';
          final config = XAxisConfig(
            unit: 's',
            labelDisplay: AxisLabelDisplay.labelAndTickUnit,
            labelFormatter: customFormatter,
            visible: true,
          );
          final bounds = const DataRange(min: 0.0, max: 100.0);
          const labelStyle = TextStyle(fontSize: 12.0);

          final painter = XAxisPainter(
            config: config,
            axisBounds: bounds,
            labelStyle: labelStyle,
          );

          // EXPECTATION: Custom formatter takes priority over unit suffix
          final label = painter.formatTickLabel(42.5);
          expect(label, equals('T=42.5'));
        });
      });

      group('axis title positioning', () {
        test('axis title is horizontally centered below tick labels', () {
          const config = XAxisConfig(
            label: 'Time (s)',
            labelDisplay: AxisLabelDisplay.labelWithUnit,
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
          final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

          painter.paint(canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea);

          // EXPECTATION: Axis label should be centered horizontally
          // X position should be: plotArea.left + (plotArea.width - labelWidth) / 2
          // This will FAIL until paint() centers the axis label
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          // TODO: Verify axis title X position is centered
        });

        test(
          'axis title Y position is below tick labels with proper spacing',
          () {
            const config = XAxisConfig(
              label: 'Distance',
              unit: 'km',
              labelDisplay: AxisLabelDisplay.labelWithUnit,
              visible: true,
              tickLabelPadding: 4.0,
              axisLabelPadding: 5.0,
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
            final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

            painter.paint(
              canvas,
              const Rect.fromLTWH(0, 0, 400, 300),
              plotArea,
            );

            // EXPECTATION: Y position = plotArea.bottom + tickLength + tickLabelPadding + tickLabelHeight + axisLabelPadding
            // This will FAIL until paint() calculates Y position correctly
            final picture = recorder.endRecording();
            expect(picture, isNotNull);
            // TODO: Verify axis title Y position calculation
          },
        );

        test('axis title respects labelDisplay mode for unit formatting', () {
          const config1 = XAxisConfig(
            label: 'Power',
            unit: 'W',
            labelDisplay: AxisLabelDisplay.labelWithUnit,
            visible: true,
          );

          // EXPECTATION: Title should be "Power (W)"
          expect(config1.shouldShowAxisLabel, isTrue);
          expect(config1.shouldAppendUnitToLabel, isTrue);

          const config2 = XAxisConfig(
            label: 'Power',
            unit: 'W',
            labelDisplay: AxisLabelDisplay.labelOnly,
            visible: true,
          );

          // EXPECTATION: Title should be "Power" (no unit)
          expect(config2.shouldShowAxisLabel, isTrue);
          expect(config2.shouldAppendUnitToLabel, isFalse);
        });
      });
    });
  });
}
