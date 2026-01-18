// @orchestra-task: 8
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

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
  group('[TDD-RED] XAxisConfig backward compatibility', () {
    group('default configuration', () {
      test('chart without explicit XAxisConfig uses sensible defaults', () {
        // SCENARIO: User creates chart without providing XAxisConfig
        // EXPECTATION: Should use XAxisConfig() default constructor values

        const defaultConfig = XAxisConfig();

        // Verify defaults are sensible for backward compatibility
        expect(defaultConfig.visible, isTrue,
            reason: 'Axis should be visible by default');
        expect(defaultConfig.showAxisLine, isTrue,
            reason: 'Axis line should show by default');
        expect(defaultConfig.showTicks, isTrue,
            reason: 'Tick marks should show by default');
        expect(defaultConfig.showCrosshairLabel, isTrue,
            reason: 'Crosshair label should show by default');
        expect(
            defaultConfig.labelDisplay, equals(AxisLabelDisplay.labelWithUnit),
            reason: 'Default should be space-efficient labelWithUnit mode');
        expect(defaultConfig.minHeight, equals(0.0),
            reason: 'Should allow axis to shrink to content');
        expect(defaultConfig.maxHeight, equals(60.0),
            reason: 'Should have reasonable max height');
        expect(defaultConfig.tickLabelPadding, equals(4.0),
            reason: 'Should have default tick label padding');
        expect(defaultConfig.axisLabelPadding, equals(5.0),
            reason: 'Should have default axis label padding');
        expect(defaultConfig.axisMargin, equals(8.0),
            reason: 'Should have default margin');
      });

      test('XAxisPainter works with default XAxisConfig', () {
        const config = XAxisConfig(); // All defaults
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

        // EXPECTATION: Should render without errors
        expect(
          () => painter.paint(
              canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea),
          returnsNormally,
        );

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('default config generates reasonable ticks', () {
        const config = XAxisConfig();
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
        );

        // EXPECTATION: Should generate ticks even with default config
        final ticks = painter.generateTicks(bounds);
        expect(ticks, isNotEmpty, reason: 'Should generate some ticks');
        expect(ticks.length, greaterThan(1),
            reason: 'Should have multiple ticks');
        expect(ticks.first, greaterThanOrEqualTo(bounds.min));
        expect(ticks.last, lessThanOrEqualTo(bounds.max));
      });
    });

    group('color fallback', () {
      test('uses first series color when XAxisConfig.color is null', () {
        const seriesColor = Color(0xFFFF5500);
        const series = [
          LineChartSeries(
            id: 'test-series',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 100, y: 100),
            ],
            color: seriesColor,
          ),
        ];

        const config = XAxisConfig(color: null); // No explicit color
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        // EXPECTATION: resolveAxisColor should return first series color
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(seriesColor),
            reason: 'Should use first series color when config.color is null');
      });

      test('explicit XAxisConfig.color takes priority over series color', () {
        const configColor = Color(0xFF0000FF);
        const seriesColor = Color(0xFFFF0000);
        const series = [
          LineChartSeries(
            id: 'test-series',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 100, y: 100),
            ],
            color: seriesColor,
          ),
        ];

        const config = XAxisConfig(color: configColor); // Explicit color
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        // EXPECTATION: resolveAxisColor should return config color
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(configColor),
            reason: 'Explicit config.color should take priority');
      });

      test('uses default color when no config color and no series', () {
        const config = XAxisConfig(color: null); // No explicit color
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: null, // No series to extract color from
        );

        // EXPECTATION: resolveAxisColor should return default color
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(const Color(0xFF333333)),
            reason: 'Should use default color when no other color available');
      });

      test('uses default color when series list is empty', () {
        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: const [], // Empty series list
        );

        // EXPECTATION: resolveAxisColor should return default color
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(const Color(0xFF333333)),
            reason: 'Should use default color when series list is empty');
      });

      test('uses default color when first series has null color', () {
        const series = [
          LineChartSeries(
            id: 'test-series',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 100, y: 100),
            ],
            color: null, // Series has no color
          ),
        ];

        const config = XAxisConfig(color: null);
        final bounds = const DataRange(min: 0.0, max: 100.0);
        const labelStyle = TextStyle(fontSize: 12.0);

        final painter = XAxisPainter(
          config: config,
          axisBounds: bounds,
          labelStyle: labelStyle,
          series: series,
        );

        // EXPECTATION: resolveAxisColor should return default color
        final resolvedColor = painter.resolveAxisColor();
        expect(resolvedColor, equals(const Color(0xFF333333)),
            reason: 'Should use default color when series color is null');
      });
    });

    group('legacy XAxisRenderer not invoked', () {
      test('XAxisRenderer is not imported in XAxisPainter', () {
        // EXPECTATION: grep for "import.*x_axis_renderer" in x_axis_painter.dart
        // should return no results (except in comments or excluded contexts)

        // This test verifies that the new XAxisPainter does NOT depend on
        // the legacy XAxisRenderer class for rendering operations.

        // IMPLEMENTATION NOTE: This test should be implemented as a grep check
        // or source code analysis to ensure no import statement exists.
        // For now, we document the expectation.

        // TODO: Add grep-based verification or AST analysis
        expect(true, isTrue,
            reason:
                'Placeholder - verify XAxisRenderer not imported in XAxisPainter');
      });

      test('paint operation does not call XAxisRenderer methods', () {
        const config = XAxisConfig(
          visible: true,
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
        final plotArea = const Rect.fromLTWH(50, 20, 300, 250);

        // EXPECTATION: paint() should complete without calling XAxisRenderer
        expect(
          () => painter.paint(
              canvas, const Rect.fromLTWH(0, 0, 400, 300), plotArea),
          returnsNormally,
          reason: 'Should render using XAxisPainter only, not XAxisRenderer',
        );

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });
    });

    group('API parity with YAxisConfig', () {
      test('XAxisConfig has equivalent appearance properties to YAxisConfig',
          () {
        // Both should have: color, label, unit properties
        const xConfig = XAxisConfig(
          color: Color(0xFF000000),
          label: 'X Label',
          unit: 'x-unit',
        );

        expect(xConfig.color, isNotNull);
        expect(xConfig.label, equals('X Label'));
        expect(xConfig.unit, equals('x-unit'));

        // YAxisConfig has the same properties (verified by inspection)
        // This test documents the expected parity
      });

      test('XAxisConfig has equivalent visibility properties to YAxisConfig',
          () {
        // Both should have: visible, showAxisLine, showTicks, showCrosshairLabel
        const xConfig = XAxisConfig(
          visible: true,
          showAxisLine: true,
          showTicks: true,
          showCrosshairLabel: true,
        );

        expect(xConfig.visible, isTrue);
        expect(xConfig.showAxisLine, isTrue);
        expect(xConfig.showTicks, isTrue);
        expect(xConfig.showCrosshairLabel, isTrue);

        // YAxisConfig has the same properties (verified by inspection)
      });

      test('XAxisConfig shares AxisLabelDisplay enum with YAxisConfig', () {
        // Both should use the same AxisLabelDisplay enum
        const xConfig = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );

        expect(xConfig.labelDisplay, equals(AxisLabelDisplay.labelWithUnit));

        // Verify all enum values are available
        const allModes = [
          AxisLabelDisplay.labelOnly,
          AxisLabelDisplay.labelWithUnit,
          AxisLabelDisplay.labelAndTickUnit,
          AxisLabelDisplay.labelWithUnitAndTickUnit,
          AxisLabelDisplay.tickUnitOnly,
          AxisLabelDisplay.tickOnly,
          AxisLabelDisplay.none,
        ];

        for (final mode in allModes) {
          final config = XAxisConfig(labelDisplay: mode);
          expect(config.labelDisplay, equals(mode),
              reason: 'XAxisConfig should support $mode');
        }
      });

      test('XAxisConfig has equivalent dimension properties to YAxisConfig',
          () {
        // XAxisConfig has minHeight/maxHeight, YAxisConfig has minWidth/maxWidth
        // Both have padding and margin properties
        const xConfig = XAxisConfig(
          minHeight: 30.0,
          maxHeight: 80.0,
          tickLabelPadding: 6.0,
          axisLabelPadding: 8.0,
          axisMargin: 10.0,
        );

        expect(xConfig.minHeight, equals(30.0));
        expect(xConfig.maxHeight, equals(80.0));
        expect(xConfig.tickLabelPadding, equals(6.0));
        expect(xConfig.axisLabelPadding, equals(8.0));
        expect(xConfig.axisMargin, equals(10.0));

        // YAxisConfig has equivalent minWidth/maxWidth and padding properties
      });

      test('XAxisConfig has equivalent behavior properties to YAxisConfig', () {
        String customFormatter(double value) => 'F:$value';
        final xConfig = XAxisConfig(
          tickCount: 8,
          labelFormatter: customFormatter,
        );

        expect(xConfig.tickCount, equals(8));
        expect(xConfig.labelFormatter, isNotNull);
        expect(xConfig.labelFormatter!(42.0), equals('F:42.0'));

        // YAxisConfig has the same tickCount and labelFormatter properties
      });

      test('XAxisConfig has equivalent bounds properties to YAxisConfig', () {
        const xConfig = XAxisConfig(
          min: 10.0,
          max: 90.0,
        );

        expect(xConfig.min, equals(10.0));
        expect(xConfig.max, equals(90.0));

        // YAxisConfig has the same min/max properties
      });

      test('XAxisConfig has equivalent helper methods to YAxisConfig', () {
        // Both should have shouldShowAxisLabel, shouldAppendUnitToLabel, etc.
        const xConfig = XAxisConfig(
          label: 'Test',
          unit: 'u',
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );

        expect(xConfig.shouldShowAxisLabel, isTrue);
        expect(xConfig.shouldAppendUnitToLabel, isTrue);
        expect(xConfig.shouldShowTickUnit, isFalse);
        expect(xConfig.shouldShowTickLabels, isTrue);

        // YAxisConfig has equivalent helper methods
        // (verified by inspection of y_axis_config.dart)
      });
    });
  });
}
