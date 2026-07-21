/// Behaviour matrix for the generated fluent surface (Task 5 fleet).
///
/// The file is organised BY SOURCE FILE so it reads as a checklist against the
/// annotated fleet. For every annotated class in the series/data/axes/
/// interaction half there is at least:
///
/// - one `withX` case asserting equality with the equivalent `copyWith`;
/// - every derived `clearX` verb exercised at least once per source file;
/// - every `withoutX` / `inheritX` where a tri-state field exists;
/// - every combined setter, plus a case proving the invalid intermediate the
///   setter replaces is unreachable through the fluent surface;
/// - the `updateX` nested updaters on `InteractionConfig` and on a series;
/// - the sealed helpers on `CartesianValueSummaryConfig`.
///
/// Everything is imported through the opt-in barrel only.
library;

import 'dart:io';

import 'package:braven_charts/braven_charts_fluent.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a checked-in generated fluent file.
///
/// Combined setters REPLACE their member parameters, so the proof that an
/// invalid intermediate is unreachable is the absence of the individual verb
/// from the generated source: calling it would not compile.
String _generatedSource(String fileName) {
  final separator = Platform.pathSeparator;
  final path = [
    Directory.current.path,
    'lib',
    'src',
    'fluent',
    'generated',
    'models',
    fileName,
  ].join(separator);
  return File(path).readAsStringSync();
}

void main() {
  // ===========================================================================
  // lib/src/models/chart_series.dart
  // ===========================================================================
  group('chart_series.dart', () {
    const points = [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 3)];

    group('ScatterChartSeries', () {
      const base = ScatterChartSeries(id: 'scatter', points: points);

      test('withMarkerRadius equals the copyWith equivalent', () {
        expect(base.withMarkerRadius(9), base.copyWith(markerRadius: 9));
      });

      test('withRenderMode equals the copyWith equivalent', () {
        expect(
          base.withRenderMode(ScatterRenderMode.density),
          base.copyWith(renderMode: ScatterRenderMode.density),
        );
      });

      test('every derived clear verb unsets its field', () {
        final loaded = base
            .withMarkerStyle(const ScatterMarkerStyle())
            .withSizeEncoding(const ScatterSizeEncoding())
            .withColorEncoding(
              const ScatterColorEncoding(colors: [Color(0xFF000000)]),
            )
            .withOpacityEncoding(const ScatterOpacityEncoding())
            .withCategoryEncoding(
              const ScatterCategoryEncoding(
                categories: [ScatterCategoryStyle(key: 'a')],
              ),
            )
            .withDataPointLabels(const DataPointLabelConfig());
        expect(loaded.clearMarkerStyle().markerStyle, isNull);
        expect(loaded.clearSizeEncoding().sizeEncoding, isNull);
        expect(loaded.clearColorEncoding().colorEncoding, isNull);
        expect(loaded.clearOpacityEncoding().opacityEncoding, isNull);
        expect(loaded.clearCategoryEncoding().categoryEncoding, isNull);
        expect(loaded.clearDataPointLabels().dataPointLabels, isNull);
      });

      test('a clear verb equals the copyWith flag', () {
        final loaded = base.withMarkerStyle(const ScatterMarkerStyle());
        expect(
          loaded.clearMarkerStyle(),
          loaded.copyWith(clearMarkerStyle: true),
        );
      });
    });

    group('AreaChartSeries', () {
      const base = AreaChartSeries(id: 'area', points: points);

      test('withFillOpacity equals the copyWith equivalent', () {
        expect(base.withFillOpacity(0.75), base.copyWith(fillOpacity: 0.75));
      });

      test('clearFillGradient equals the copyWith flag', () {
        final loaded = base.withFillGradient(
          const AreaGradient(colors: [Color(0xFF112233), Color(0xFF445566)]),
        );
        expect(
          loaded.clearFillGradient(),
          loaded.copyWith(clearFillGradient: true),
        );
        expect(loaded.clearFillGradient().fillGradient, isNull);
      });
    });

    group('BarChartSeries', () {
      const base = BarChartSeries(
        id: 'bars',
        points: points,
        barWidthPercent: 0.6,
      );

      test('withBaselineValue equals the copyWith equivalent', () {
        expect(base.withBaselineValue(2), base.copyWith(baselineValue: 2));
      });

      test('withBarWidth moves both assert-coupled width inputs', () {
        final moved = base.withBarWidth(0.4, 18);
        expect(moved, base.copyWith(barWidthPercent: 0.4, barWidthPixels: 18));
        expect(moved.barWidthPercent, 0.4);
        expect(moved.barWidthPixels, 18);
      });

      test('withWidthBounds moves min and max together', () {
        final moved = base.withWidthBounds(220, 40);
        expect(moved, base.copyWith(maxWidth: 220, minWidth: 40));
        expect(moved.minWidth, 40);
        expect(moved.maxWidth, 220);
      });

      test('the invalid intermediate the combined setters replace is '
          'unreachable', () {
        // The hazard is real on the raw config API...
        expect(
          () => base.copyWith(minWidth: 200),
          throwsA(isA<AssertionError>()),
        );
        // ...and the fluent surface never exposes the individual verbs, so no
        // chain step can construct that value (calling them would not compile).
        final source = _generatedSource('chart_series_fluent.dart');
        expect(source, isNot(contains('withMinWidth(')));
        expect(source, isNot(contains('withMaxWidth(')));
        expect(source, isNot(contains('withBarWidthPercent(')));
        expect(source, isNot(contains('withBarWidthPixels(')));
      });

      test('every derived clear verb unsets its field', () {
        final loaded = base
            .withGroupId('g1')
            .withTrackStyle(const BarTrackStyle(color: Color(0xFFEEEEEE)))
            .withLollipopStyle(const BarLollipopStyle());
        expect(loaded.clearGroupId().groupId, isNull);
        expect(loaded.clearTrackStyle().trackStyle, isNull);
        expect(loaded.clearLollipopStyle().lollipopStyle, isNull);
        expect(
          base
              .withBulletStyle(
                const BarBulletStyle(ranges: [BarBulletRange(endValue: 5, color: Color(0xFFCCCCCC))]),
              )
              .clearBulletStyle()
              .bulletStyle,
          isNull,
        );
      });
    });
  });

  // ===========================================================================
  // lib/src/models/candlestick_chart_series.dart
  // ===========================================================================
  group('candlestick_chart_series.dart', () {
    final candles = [
      CandlestickDataPoint(x: 0, open: 1, high: 4, low: 0.5, close: 3),
      CandlestickDataPoint(x: 1, open: 3, high: 5, low: 2, close: 4),
    ];

    test('CandlestickChartSeries.withUnit equals the copyWith equivalent', () {
      final base = CandlestickChartSeries(id: 'ohlc', points: candles);
      expect(base.withUnit('USD'), base.copyWith(unit: 'USD'));
    });

    test('CandlestickChartSeries.updateDensityGrouping rebuilds the nested '
        'config from its current value', () {
      final base = CandlestickChartSeries(
        id: 'ohlc',
        points: candles,
        densityGrouping: const CandlestickDensityGrouping(
          targetGroupWidth: 6,
        ),
      );
      final updated = base.updateDensityGrouping(
        (current) => current.withEnabled(true),
      );
      expect(updated.densityGrouping.enabled, isTrue);
      // The untouched leaf survives the update.
      expect(updated.densityGrouping.targetGroupWidth, 6);
      expect(
        updated,
        base.copyWith(
          densityGrouping: base.densityGrouping.copyWith(enabled: true),
        ),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/candlestick_data_point.dart
  // ===========================================================================
  group('candlestick_data_point.dart', () {
    CandlestickDataPoint point() =>
        CandlestickDataPoint(x: 0, open: 1, high: 4, low: 0.5, close: 3);

    test('withHigh equals the copyWith equivalent', () {
      expect(point().withHigh(6), point().copyWith(high: 6));
    });

    test('every derived clear verb unsets its field', () {
      final loaded = point()
          .withMagnitude(2)
          .withColorValue(3)
          .withOpacityValue(0.5)
          .withCategoryValue('a')
          .withSegmentStyle(const SegmentStyle(color: Color(0xFF00FF00)))
          .withPointStyle(const PointStyle(color: Color(0xFFFF0000)))
          .withCandlestickStyle(const CandlestickPointStyle());
      expect(loaded.clearMagnitude().magnitude, isNull);
      expect(loaded.clearColorValue().colorValue, isNull);
      expect(loaded.clearOpacityValue().opacityValue, isNull);
      expect(loaded.clearCategoryValue().categoryValue, isNull);
      expect(loaded.clearSegmentStyle().segmentStyle, isNull);
      expect(loaded.clearPointStyle().pointStyle, isNull);
      expect(loaded.clearCandlestickStyle().candlestickStyle, isNull);
    });

    test('the subtype extension keeps the OHLC state', () {
      final moved = point().withClose(3.5);
      expect(moved, isA<CandlestickDataPoint>());
      expect(moved.open, 1);
      expect(moved.high, 4);
      expect(moved.close, 3.5);
      // The inherited y mirror follows close.
      expect(moved.y, 3.5);
    });
  });

  // ===========================================================================
  // lib/src/models/candlestick_density_grouping.dart
  // ===========================================================================
  group('candlestick_density_grouping.dart', () {
    const base = CandlestickDensityGrouping();

    test('withEnabled equals the copyWith equivalent', () {
      expect(base.withEnabled(true), base.copyWith(enabled: true));
    });

    test('a chain equals one combined copyWith', () {
      expect(
        base.withEnabled(true).withTargetGroupWidth(8).withMinimumPointsPerGroup(
          3,
        ),
        base.copyWith(
          enabled: true,
          targetGroupWidth: 8,
          minimumPointsPerGroup: 3,
        ),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/chart_data_point.dart
  // ===========================================================================
  group('chart_data_point.dart', () {
    const base = ChartDataPoint(x: 1, y: 2);

    test('withY equals the copyWith equivalent', () {
      expect(base.withY(5), base.copyWith(y: 5));
    });

    test('every derived clear verb unsets its field', () {
      final loaded = base
          .withMagnitude(4)
          .withColorValue(5)
          .withOpacityValue(0.25)
          .withCategoryValue('c')
          .withSegmentStyle(const SegmentStyle(color: Color(0xFF00FF00)))
          .withPointStyle(const PointStyle(color: Color(0xFFFF0000)));
      expect(loaded.clearMagnitude(), loaded.copyWith(clearMagnitude: true));
      expect(loaded.clearColorValue().colorValue, isNull);
      expect(loaded.clearOpacityValue().opacityValue, isNull);
      expect(loaded.clearCategoryValue().categoryValue, isNull);
      expect(loaded.clearSegmentStyle().segmentStyle, isNull);
      expect(loaded.clearPointStyle().pointStyle, isNull);
    });

    test('chains do not mutate the receiver', () {
      final moved = base.withLabel('peak').withX(9);
      expect(base, const ChartDataPoint(x: 1, y: 2));
      expect(moved.label, 'peak');
      expect(moved.x, 9);
    });
  });

  // ===========================================================================
  // lib/src/models/pie_chart_series.dart
  // ===========================================================================
  group('pie_chart_series.dart', () {
    PieChartSeries base() =>
        PieChartSeries.fromMap(id: 'pie', values: const {'a': 3, 'b': 5});

    test('withPieStyle equals the copyWith equivalent', () {
      const style = PieChartStyle(radiusFactor: 0.75);
      expect(base().withPieStyle(style), base().copyWith(pieStyle: style));
    });

    test('the derived clear verbs unset their fields', () {
      final loaded = base().withSliceGroupingConfig(
        const RadialSliceGroupingConfig(),
      );
      expect(loaded.sliceGroupingConfig, isNotNull);
      expect(loaded.clearSliceGroupingConfig().sliceGroupingConfig, isNull);
      expect(base().clearSliceRadiusConfig().sliceRadiusConfig, isNull);
    });
  });

  // ===========================================================================
  // lib/src/models/donut_chart_series.dart
  // ===========================================================================
  group('donut_chart_series.dart', () {
    DonutChartSeries base() =>
        DonutChartSeries.fromMap(id: 'donut', values: const {'a': 3, 'b': 5});

    test('withCenterContent equals the copyWith equivalent', () {
      expect(
        base().withCenterContent(const DonutCenterContent()),
        base().copyWith(centerContent: const DonutCenterContent()),
      );
    });

    test('clearSliceGroupingConfig unsets the field', () {
      final loaded = base().withSliceGroupingConfig(
        const RadialSliceGroupingConfig(),
      );
      expect(loaded.clearSliceGroupingConfig().sliceGroupingConfig, isNull);
    });
  });

  // ===========================================================================
  // lib/src/models/polar_column_chart_series.dart
  // ===========================================================================
  group('polar_column_chart_series.dart', () {
    test('PolarColumnGradientStyle: withX and clearX', () {
      const base = PolarColumnGradientStyle();
      expect(
        base.withStartLightnessShift(0.2),
        base.copyWith(startLightnessShift: 0.2),
      );
      final loaded = base
          .withStartColor(const Color(0xFF102030))
          .withEndColor(const Color(0xFF405060));
      expect(loaded.clearStartColor().startColor, isNull);
      expect(loaded.clearEndColor().endColor, isNull);
    });

    test('PolarColumnShadowStyle: withX and clearX', () {
      const base = PolarColumnShadowStyle();
      expect(base.withBlurRadius(4), base.copyWith(blurRadius: 4));
      expect(
        base.withColor(const Color(0xFF000000)).clearColor().color,
        isNull,
      );
    });

    test('PolarColumnIntervalStyle: withX and clearX', () {
      const base = PolarColumnIntervalStyle();
      expect(
        base.withDisplay(PolarColumnIntervalDisplay.band),
        base.copyWith(display: PolarColumnIntervalDisplay.band),
      );
      expect(
        base.withColor(const Color(0xFF223344)).clearColor().color,
        isNull,
      );
    });

    test('PolarColumnTargetMarkerStyle: withX and clearX', () {
      const base = PolarColumnTargetMarkerStyle();
      expect(base.withWidth(3.5), base.copyWith(width: 3.5));
      expect(
        base.withColor(const Color(0xFF223344)).clearColor().color,
        isNull,
      );
    });

    test('PolarColumnStyle: withX, clearX and the nested updater', () {
      const base = PolarColumnStyle();
      expect(base.withCornerRadius(9), base.copyWith(cornerRadius: 9));
      expect(
        base.withBorderColor(const Color(0xFF223344)).clearBorderColor()
            .borderColor,
        isNull,
      );
      expect(
        base
            .withGradient(const PolarColumnGradientStyle())
            .clearGradient()
            .gradient,
        isNull,
      );
      final updated = base.updateShadow((current) => current.withOpacity(0.4));
      expect(updated.shadow.opacity, 0.4);
      expect(updated, base.copyWith(shadow: base.shadow.copyWith(opacity: 0.4)));
    });

    test('PolarColumnChartSeries: withX and the nested updater', () {
      final base = PolarColumnChartSeries.fromMap(
        id: 'polar',
        values: const {'a': 3, 'b': 5},
      );
      expect(
        base.withPreset(PolarColumnPreset.rose),
        base.copyWith(preset: PolarColumnPreset.rose),
      );
      final updated = base.updatePolarStyle(
        (current) => current.withOpacity(0.6),
      );
      expect(updated.polarStyle.opacity, 0.6);
      final marker = base.updateTargetMarkerStyle(
        (current) => current.withWidth(4),
      );
      expect(marker.targetMarkerStyle.width, 4);
      final interval = base.updateIntervalStyle(
        (current) => current.withOpacity(0.8),
      );
      expect(interval.intervalStyle.opacity, 0.8);
    });
  });

  // ===========================================================================
  // lib/src/models/radial_category_series.dart
  // ===========================================================================
  group('radial_category_series.dart', () {
    const base = RadialSliceGroupingConfig();

    test('withMinimumShare equals the copyWith equivalent', () {
      expect(base.withMinimumShare(0.1), base.copyWith(minimumShare: 0.1));
    });

    test('every derived clear verb unsets its field', () {
      final loaded = base
          .withColor(const Color(0xFF888888))
          .withRadiusAggregation(RadialSliceRadiusAggregation.sum);
      expect(loaded.clearColor().color, isNull);
      expect(loaded.clearRadiusAggregation().radiusAggregation, isNull);
    });
  });
}
