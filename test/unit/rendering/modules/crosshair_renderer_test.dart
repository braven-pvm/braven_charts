// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for CrosshairRenderer module

import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/crosshair_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairRenderer', () {
    late CrosshairRenderer renderer;
    late ChartTransform transform;
    late Rect plotArea;
    late MultiAxisInfo multiAxisInfo;

    setUp(() {
      renderer = const CrosshairRenderer();
      transform = const ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
        invertY: true,
      );
      plotArea = const Rect.fromLTWH(50, 50, 400, 300);
      multiAxisInfo = MultiAxisInfo(
        effectiveAxes: [
          YAxisConfig.withId(id: 'default', position: YAxisPosition.left),
        ],
        axisBounds: const {'default': DataRange(min: 0, max: 100)},
        axisWidths: const {'default': 50.0},
        effectiveBindings: const [],
        normalizationMode: null,
        series: const [],
      );
    });

    group('Initialization', () {
      test('creates instance with const constructor', () {
        const renderer = CrosshairRenderer();
        expect(renderer, isNotNull);
      });
    });

    group('MultiAxisInfo', () {
      test('isMultiAxisMode returns false for single axis', () {
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ],
          axisBounds: const {'axis1': DataRange(min: 0, max: 100)},
          axisWidths: const {'axis1': 50.0},
          effectiveBindings: const [],
          normalizationMode: NormalizationMode.perSeries,
          series: const [],
        );

        expect(info.isMultiAxisMode, isFalse);
      });

      test(
        'isMultiAxisMode returns true for multiple axes with perSeries normalization',
        () {
          final info = MultiAxisInfo(
            effectiveAxes: [
              YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
              YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
            ],
            axisBounds: const {
              'axis1': DataRange(min: 0, max: 100),
              'axis2': DataRange(min: 0, max: 1000),
            },
            axisWidths: const {'axis1': 50.0, 'axis2': 50.0},
            effectiveBindings: const [],
            normalizationMode: NormalizationMode.perSeries,
            series: const [],
          );

          expect(info.isMultiAxisMode, isTrue);
        },
      );

      test(
        'isMultiAxisMode returns false for multiple axes without perSeries normalization',
        () {
          final info = MultiAxisInfo(
            effectiveAxes: [
              YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
              YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
            ],
            axisBounds: const {
              'axis1': DataRange(min: 0, max: 100),
              'axis2': DataRange(min: 0, max: 1000),
            },
            axisWidths: const {'axis1': 50.0, 'axis2': 50.0},
            effectiveBindings: const [],
            normalizationMode: null,
            series: const [],
          );

          expect(info.isMultiAxisMode, isFalse);
        },
      );

      test('getPositionWidth returns total width for position', () {
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              visible: true,
            ),
            YAxisConfig.withId(
              id: 'axis2',
              position: YAxisPosition.left,
              visible: true,
            ),
            YAxisConfig.withId(
              id: 'axis3',
              position: YAxisPosition.right,
              visible: true,
            ),
          ],
          axisBounds: const {
            'axis1': DataRange(min: 0, max: 100),
            'axis2': DataRange(min: 0, max: 200),
            'axis3': DataRange(min: 0, max: 300),
          },
          axisWidths: const {'axis1': 50.0, 'axis2': 60.0, 'axis3': 70.0},
          effectiveBindings: const [],
          normalizationMode: null,
          series: const [],
        );

        expect(info.getPositionWidth(YAxisPosition.left), equals(110.0));
        expect(info.getPositionWidth(YAxisPosition.right), equals(70.0));
      });

      test('getPositionWidth excludes invisible axes', () {
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              visible: true,
            ),
            YAxisConfig.withId(
              id: 'axis2',
              position: YAxisPosition.left,
              visible: false,
            ),
          ],
          axisBounds: const {
            'axis1': DataRange(min: 0, max: 100),
            'axis2': DataRange(min: 0, max: 200),
          },
          axisWidths: const {'axis1': 50.0, 'axis2': 60.0},
          effectiveBindings: const [],
          normalizationMode: null,
          series: const [],
        );

        expect(info.getPositionWidth(YAxisPosition.left), equals(50.0));
      });

      test('resolveAxisColor returns axis color if set', () {
        const axisColor = Color(0xFF00FF00);
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              color: axisColor,
            ),
          ],
          axisBounds: const {'axis1': DataRange(min: 0, max: 100)},
          axisWidths: const {'axis1': 50.0},
          effectiveBindings: const [],
          normalizationMode: null,
          series: const [],
        );

        expect(
          info.resolveAxisColor(info.effectiveAxes.first),
          equals(axisColor),
        );
      });

      test('resolveAxisColor returns series color if axis has no color', () {
        const seriesColor = Color(0xFFFF0000);
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ],
          axisBounds: const {'axis1': DataRange(min: 0, max: 100)},
          axisWidths: const {'axis1': 50.0},
          effectiveBindings: const [
            SeriesAxisBinding(seriesId: 'series1', yAxisId: 'axis1'),
          ],
          normalizationMode: null,
          series: [
            const ChartSeries(
              id: 'series1',
              name: 'Series 1',
              points: [],
              color: seriesColor,
            ),
          ],
        );

        expect(
          info.resolveAxisColor(info.effectiveAxes.first),
          equals(seriesColor),
        );
      });

      test('resolveAxisColor returns default gray if no color found', () {
        final info = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ],
          axisBounds: const {'axis1': DataRange(min: 0, max: 100)},
          axisWidths: const {'axis1': 50.0},
          effectiveBindings: const [],
          normalizationMode: null,
          series: const [],
        );

        expect(
          info.resolveAxisColor(info.effectiveAxes.first),
          equals(const Color(0xFF666666)),
        );
      });
    });

    group('Paint Method', () {
      test('paint executes without errors for standard mode', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        // Should not throw
        expect(
          () => renderer.paint(
            canvas: canvas,
            size: const Size(500, 400),
            cursorPosition: const Offset(200, 150),
            plotArea: plotArea,
            transform: transform,
            theme: ChartTheme.light,
            crosshairConfig: const CrosshairConfig(),
            multiAxisInfo: multiAxisInfo,
            seriesElements: const [],
            isRangeCreationMode: false,
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });

      test('paint handles range creation mode', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => renderer.paint(
            canvas: canvas,
            size: const Size(500, 400),
            cursorPosition: const Offset(200, 150),
            plotArea: plotArea,
            transform: transform,
            theme: ChartTheme.light,
            crosshairConfig: const CrosshairConfig(),
            multiAxisInfo: multiAxisInfo,
            seriesElements: const [],
            isRangeCreationMode: true,
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });

      test('paint handles multi-axis mode', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        final multiAxisInfoWithMultiple = MultiAxisInfo(
          effectiveAxes: [
            YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              showCrosshairLabel: true,
            ),
            YAxisConfig.withId(
              id: 'axis2',
              position: YAxisPosition.right,
              showCrosshairLabel: true,
            ),
          ],
          axisBounds: const {
            'axis1': DataRange(min: 0, max: 100),
            'axis2': DataRange(min: 0, max: 1000),
          },
          axisWidths: const {'axis1': 50.0, 'axis2': 50.0},
          effectiveBindings: const [],
          normalizationMode: NormalizationMode.perSeries,
          series: const [],
        );

        expect(
          () => renderer.paint(
            canvas: canvas,
            size: const Size(500, 400),
            cursorPosition: const Offset(200, 150),
            plotArea: plotArea,
            transform: transform,
            theme: ChartTheme.light,
            crosshairConfig: const CrosshairConfig(),
            multiAxisInfo: multiAxisInfoWithMultiple,
            seriesElements: const [],
            isRangeCreationMode: false,
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });

      test('paint handles different crosshair modes', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        for (final mode in CrosshairMode.values) {
          expect(
            () => renderer.paint(
              canvas: canvas,
              size: const Size(500, 400),
              cursorPosition: const Offset(200, 150),
              plotArea: plotArea,
              transform: transform,
              theme: ChartTheme.light,
              crosshairConfig: CrosshairConfig(mode: mode),
              multiAxisInfo: multiAxisInfo,
              seriesElements: const [],
              isRangeCreationMode: false,
            ),
            returnsNormally,
            reason: 'Should handle mode: $mode',
          );
        }

        recorder.endRecording();
      });
    });
  });
}
