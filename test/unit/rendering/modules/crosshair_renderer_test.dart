// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for CrosshairRenderer module

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/x_axis_position.dart';
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

    group('X-axis crosshair label placement', () {
      test('over-axis labels follow the configured edge', () {
        final bottom = renderer.calculateXAxisCrosshairLabelY(
          plotArea: plotArea,
          textHeight: 12,
          labelPadding: 4,
          axis: const XAxisConfig(position: XAxisPosition.bottom),
        );
        final top = renderer.calculateXAxisCrosshairLabelY(
          plotArea: plotArea,
          textHeight: 12,
          labelPadding: 4,
          axis: const XAxisConfig(position: XAxisPosition.top),
        );

        expect(bottom, greaterThan(plotArea.bottom));
        expect(top + 12, lessThan(plotArea.top));
      });

      test('inside labels remain inside the matching plot edge', () {
        final bottom = renderer.calculateXAxisCrosshairLabelY(
          plotArea: plotArea,
          textHeight: 12,
          labelPadding: 4,
          axis: const XAxisConfig(
            position: XAxisPosition.bottom,
            crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
          ),
        );
        final top = renderer.calculateXAxisCrosshairLabelY(
          plotArea: plotArea,
          textHeight: 12,
          labelPadding: 4,
          axis: const XAxisConfig(
            position: XAxisPosition.top,
            crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
          ),
        );

        expect(bottom + 12, lessThanOrEqualTo(plotArea.bottom));
        expect(top, greaterThanOrEqualTo(plotArea.top));
      });

      test('mirrored axes return labels for both plot edges', () {
        final positions = renderer.calculateXAxisCrosshairLabelYs(
          plotArea: plotArea,
          textHeight: 12,
          labelPadding: 4,
          axis: const XAxisConfig(position: XAxisPosition.both),
        );

        expect(positions, hasLength(2));
        expect(positions.first + 12, lessThan(plotArea.top));
        expect(positions.last, greaterThan(plotArea.bottom));
        expect(
          renderer.calculateXAxisCrosshairLabelY(
            plotArea: plotArea,
            textHeight: 12,
            labelPadding: 4,
            axis: const XAxisConfig(position: XAxisPosition.both),
          ),
          positions.last,
        );
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

    group('Y-axis crosshair label placement', () {
      const chartSize = Size(500, 400);
      const labelWidth = 30.0;
      const labelPadding = 4.0;

      test('uses each repeated left axis strip', () {
        final axes = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
          YAxisConfig.withId(id: 'cadence', position: YAxisPosition.left),
        ];
        final info = MultiAxisInfo(
          effectiveAxes: axes,
          axisBounds: const {
            'power': DataRange(min: 100, max: 200),
            'cadence': DataRange(min: 60, max: 100),
          },
          axisWidths: const {'power': 55.0, 'cadence': 65.0},
          effectiveBindings: const [],
          normalizationMode: NormalizationMode.perSeries,
          series: const [],
        );

        final powerX = renderer.calculateYAxisCrosshairLabelX(
          chartSize: chartSize,
          plotArea: const Rect.fromLTWH(120, 10, 380, 340),
          axis: axes[0],
          textWidth: labelWidth,
          labelPadding: labelPadding,
          multiAxisInfo: info,
        );
        final cadenceX = renderer.calculateYAxisCrosshairLabelX(
          chartSize: chartSize,
          plotArea: const Rect.fromLTWH(120, 10, 380, 340),
          axis: axes[1],
          textWidth: labelWidth,
          labelPadding: labelPadding,
          multiAxisInfo: info,
        );

        expect(powerX, 17.0);
        expect(cadenceX, 82.0);
      });

      test('uses each repeated right axis strip', () {
        final axes = [
          YAxisConfig.withId(id: 'heart-rate', position: YAxisPosition.right),
          YAxisConfig.withId(id: 'cadence', position: YAxisPosition.right),
        ];
        final info = MultiAxisInfo(
          effectiveAxes: axes,
          axisBounds: const {
            'heart-rate': DataRange(min: 100, max: 180),
            'cadence': DataRange(min: 60, max: 100),
          },
          axisWidths: const {'heart-rate': 60.0, 'cadence': 70.0},
          effectiveBindings: const [],
          normalizationMode: NormalizationMode.perSeries,
          series: const [],
        );

        final heartRateX = renderer.calculateYAxisCrosshairLabelX(
          chartSize: chartSize,
          plotArea: const Rect.fromLTWH(0, 10, 370, 340),
          axis: axes[0],
          textWidth: labelWidth,
          labelPadding: labelPadding,
          multiAxisInfo: info,
        );
        final cadenceX = renderer.calculateYAxisCrosshairLabelX(
          chartSize: chartSize,
          plotArea: const Rect.fromLTWH(0, 10, 370, 340),
          axis: axes[1],
          textWidth: labelWidth,
          labelPadding: labelPadding,
          multiAxisInfo: info,
        );

        expect(heartRateX, 448.0);
        expect(cadenceX, 378.0);
      });
    });

    group('Paint Method', () {
      test('paints an opt-in guide band behind the center line', () async {
        const cursor = Offset(200, 150);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        renderer.paint(
          canvas: canvas,
          size: const Size(500, 400),
          cursorPosition: cursor,
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(
            mode: CrosshairMode.vertical,
            displayMode: CrosshairDisplayMode.standard,
            showCoordinateLabels: false,
            style: CrosshairStyle(
              lineColor: Color(0x00000000),
              dashPattern: [],
              bandColor: Color(0x80FF0000),
              bandWidth: 20,
            ),
          ),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
        );

        final image = await recorder.endRecording().toImage(500, 400);
        final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
        addTearDown(image.dispose);

        int alphaAt(int x, int y) => pixels!.getUint8((y * 500 + x) * 4 + 3);

        expect(alphaAt(205, 150), greaterThan(0));
        expect(alphaAt(215, 150), 0);
        expect(
          alphaAt(205, plotArea.top.round() - 2),
          0,
          reason: 'the guide band must remain clipped to the plot',
        );
      });

      test('honors the configured center-line dash pattern', () async {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        renderer.paint(
          canvas: canvas,
          size: const Size(500, 400),
          cursorPosition: const Offset(200, 150),
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(
            mode: CrosshairMode.vertical,
            displayMode: CrosshairDisplayMode.standard,
            showCoordinateLabels: false,
            style: CrosshairStyle(
              lineColor: Color(0xFF0066FF),
              lineWidth: 2,
              dashPattern: [4, 4],
              strokeCap: StrokeCap.butt,
            ),
          ),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
        );

        final image = await recorder.endRecording().toImage(500, 400);
        final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
        addTearDown(image.dispose);

        int alphaAt(int x, int y) => pixels!.getUint8((y * 500 + x) * 4 + 3);

        expect(alphaAt(200, plotArea.top.round() + 2), greaterThan(0));
        expect(alphaAt(200, plotArea.top.round() + 6), 0);
        expect(alphaAt(200, plotArea.top.round() + 10), greaterThan(0));
      });

      test('tracking both paints both cursor lines when transposed', () async {
        const cursor = Offset(250, 180);
        const transposedPlotArea = Rect.fromLTWH(80, 90, 400, 220);
        const transposed = ChartTransform(
          dataXMin: -1,
          dataXMax: 6,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 220,
          invertY: true,
          transposed: true,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        renderer.paint(
          canvas: canvas,
          size: const Size(520, 400),
          cursorPosition: cursor,
          plotArea: transposedPlotArea,
          transform: transposed,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(
            mode: CrosshairMode.both,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
        );

        final image = await recorder.endRecording().toImage(520, 400);
        final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
        addTearDown(image.dispose);
        expect(pixels, isNotNull);

        int strongestAlphaNear(int x, int y) {
          var strongest = 0;
          for (var sampleY = y - 1; sampleY <= y + 1; sampleY++) {
            for (var sampleX = x - 1; sampleX <= x + 1; sampleX++) {
              final offset = (sampleY * 520 + sampleX) * 4 + 3;
              strongest = math.max(strongest, pixels!.getUint8(offset));
            }
          }
          return strongest;
        }

        expect(strongestAlphaNear(cursor.dx.round(), 120), greaterThan(0));
        expect(strongestAlphaNear(120, cursor.dy.round()), greaterThan(0));
      });

      test('paints transposed labels for independent value axes', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final axes = [
          YAxisConfig.withId(
            id: 'revenue',
            position: YAxisPosition.left,
            label: 'Revenue',
            unit: r'$k',
            showCrosshairLabel: true,
          ),
          YAxisConfig.withId(
            id: 'orders',
            position: YAxisPosition.right,
            label: 'Orders',
            unit: 'orders',
            showCrosshairLabel: true,
          ),
          YAxisConfig.withId(
            id: 'conversion',
            position: YAxisPosition.right,
            label: 'Conversion',
            unit: '%',
            showCrosshairLabel: true,
          ),
        ];
        final info = MultiAxisInfo(
          effectiveAxes: axes,
          axisBounds: const {
            'revenue': DataRange(min: 0, max: 100),
            'orders': DataRange(min: 0, max: 500),
            'conversion': DataRange(min: 0, max: 100),
          },
          axisWidths: const {'revenue': 50, 'orders': 50, 'conversion': 50},
          effectiveBindings: const [],
          normalizationMode: NormalizationMode.perSeries,
          series: const [],
        );
        const transposed = ChartTransform(
          dataXMin: -1,
          dataXMax: 6,
          dataYMin: -0.05,
          dataYMax: 1.05,
          plotWidth: 400,
          plotHeight: 220,
          invertY: true,
          transposed: true,
        );

        expect(
          () => renderer.paint(
            canvas: canvas,
            size: const Size(520, 400),
            cursorPosition: const Offset(250, 180),
            plotArea: const Rect.fromLTWH(80, 90, 400, 220),
            transform: transposed,
            theme: ChartTheme.light,
            crosshairConfig: const CrosshairConfig(mode: CrosshairMode.both),
            multiAxisInfo: info,
            seriesElements: const [],
            isRangeCreationMode: false,
          ),
          returnsNormally,
        );

        recorder.endRecording();
      });

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
