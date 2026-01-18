// @orchestra-task: 1

@Tags(['tdd-red'])
library;

import 'dart:ui' show Canvas, Color, Rect;

import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/rendering/x_axis_painter.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XAxisPainter', () {
    group('constructor', () {
      test('accepts required parameters', () {
        const config = XAxisConfig();
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // Create mock canvas and rects
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = Rect.fromLTWH(50, 20, 300, 250);

        // Method should exist and be callable
        expect(
          () => painter.paint(canvas, chartArea, plotArea),
          returnsNormally,
        );
      });

      test('paint method signature has correct parameter types', () {
        const config = XAxisConfig();
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final chartArea = Rect.fromLTWH(0, 0, 400, 300);
        final plotArea = Rect.fromLTWH(50, 20, 300, 250);

        // Should accept Canvas, Rect, Rect parameters
        painter.paint(canvas, chartArea, plotArea);
      });
    });

    group('generateTicks method', () {
      test('generateTicks method exists', () {
        const config = XAxisConfig();
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = DataRange(min: 0.0, max: 100.0);

        // Method should exist and be callable
        expect(
          () => painter.generateTicks(testBounds),
          returnsNormally,
        );
      });

      test('generateTicks returns List<double>', () {
        const config = XAxisConfig();
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = DataRange(min: 0.0, max: 100.0);
        final ticks = painter.generateTicks(testBounds);

        expect(ticks, isA<List<double>>());
      });

      test('generateTicks accepts optional maxTicks parameter', () {
        const config = XAxisConfig();
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final testBounds = DataRange(min: 0.0, max: 100.0);

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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
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
        final bounds = DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        final color = painter.resolveAxisColor();

        expect(color, equals(testColor));
      });
    });
  });
}
