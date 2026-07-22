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

/// Reads a checked-in generated fluent file under `generated/theming/`.
String _generatedThemingSource(String subdirectory, String fileName) {
  final separator = Platform.pathSeparator;
  final path = [
    Directory.current.path,
    'lib',
    'src',
    'fluent',
    'generated',
    'theming',
    subdirectory,
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

      test('bar WIDTH is construction-only — the OR-shaped assert has no '
          'honest setter', () {
        // The constructor asserts `percent != null || pixels != null`: the
        // two are ALTERNATIVES. copyWith merges each with `??` and exposes no
        // clear flag, so no verb can select percent sizing INSTEAD of pixel
        // sizing — a percent-only series is unreachable through any chain.
        // The withBarWidth(percent, pixels) this class used to generate
        // required both, which made its percent argument dead in every call.
        expect(base.barWidthPercent, 0.6);
        expect(
          base.copyWith(barWidthPixels: 18).barWidthPercent,
          0.6,
          reason: 'copyWith cannot null the sibling width',
        );
        final source = _generatedSource('chart_series_fluent.dart');
        expect(source, isNot(contains('withBarWidth(')));
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

      test('`id` has no verb — a series id is a cross-object join key', () {
        // yAxisId, annotations and artifact documents all bind to it, so a
        // mid-chain rewrite would detach the series from everything that
        // references it. YAxisConfig.id was already excluded on this rule.
        final source = _generatedSource('chart_series_fluent.dart');
        expect(source, isNot(contains('withId(')));
        expect(base.withBaselineValue(2).id, 'bars');
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
                const BarBulletStyle(
                  ranges: [
                    BarBulletRange(endValue: 5, color: Color(0xFFCCCCCC)),
                  ],
                ),
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
        densityGrouping: const CandlestickDensityGrouping(targetGroupWidth: 6),
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

    test('withOhlc equals the copyWith equivalent', () {
      expect(
        point().withOhlc(open: 1, high: 6, low: 0.5, close: 3),
        point().copyWith(open: 1, high: 6, low: 0.5, close: 3),
      );
    });

    test('the OHLC values move as a unit — an individual setter would have '
        'thrown', () {
      // Reviewer-verified: `point().withHigh(1)` threw ArgumentError because
      // low is 0.5 < 1 but close is 3 > 1. The combined verb states the whole
      // candle, so no intermediate value exists for the body validation to
      // reject.
      expect(
        point().withOhlc(open: 0.8, high: 1, low: 0.5, close: 0.9).high,
        1,
      );
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
      final moved = point().withOhlc(open: 1, high: 4, low: 0.5, close: 3.5);
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
        base
            .withEnabled(true)
            .withTargetGroupWidth(8)
            .withMinimumPointsPerGroup(3),
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
    });

    test('sliceRadiusConfig has no generated verb — it is paired with every '
        "point's PointStyle.size", () {
      // Reviewer-adjacent: the executing smoke test caught
      // `withSliceRadiusConfig` throwing on any series whose points carry no
      // sizes, which is every series built without them. The parameter is
      // force-excluded; construction remains the complete path.
      expect(
        () => base().copyWith(sliceRadiusConfig: const PieSliceRadiusConfig()),
        throwsArgumentError,
      );
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
        base
            .withBorderColor(const Color(0xFF223344))
            .clearBorderColor()
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
      expect(
        updated,
        base.copyWith(shadow: base.shadow.copyWith(opacity: 0.4)),
      );
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

  // ===========================================================================
  // lib/src/models/x_axis_config.dart
  // ===========================================================================
  group('x_axis_config.dart', () {
    const base = XAxisConfig();

    test('withLabel equals the copyWith equivalent', () {
      expect(base.withLabel('Time'), base.copyWith(label: 'Time'));
    });

    test('withRange moves the assert-coupled bounds together', () {
      final ranged = base.withRange(0, 100);
      expect(ranged, base.copyWith(min: 0, max: 100));
      expect(ranged.min, 0);
      expect(ranged.max, 100);
    });

    test('withHeightBounds moves the assert-coupled extents together', () {
      final sized = base.withHeightBounds(10, 90);
      expect(sized, base.copyWith(minHeight: 10, maxHeight: 90));
    });

    test('the invalid intermediate the combined setters replace is '
        'unreachable', () {
      // Inverting one bound alone throws on the raw config API...
      expect(
        () => base.withRange(0, 100).copyWith(min: 200),
        throwsA(isA<AssertionError>()),
      );
      // ...and no individual verb is generated for a coupled parameter.
      final source = _generatedSource('x_axis_config_fluent.dart');
      expect(source, isNot(contains('withMin(')));
      expect(source, isNot(contains('withMax(')));
      expect(source, isNot(contains('withMinHeight(')));
      expect(source, isNot(contains('withMaxHeight(')));
    });

    test('clearCategoryAxis unsets the nested category metadata', () {
      final loaded = base.withCategoryAxis(
        const CategoryAxisConfig(categories: ['a', 'b']),
      );
      expect(loaded.categoryAxis, isNotNull);
      expect(
        loaded.clearCategoryAxis(),
        loaded.copyWith(clearCategoryAxis: true),
      );
      expect(loaded.clearCategoryAxis().categoryAxis, isNull);
    });
  });

  // ===========================================================================
  // lib/src/models/y_axis_config.dart
  // ===========================================================================
  group('y_axis_config.dart', () {
    YAxisConfig base() => YAxisConfig(position: YAxisPosition.left);

    test('withUnit equals the copyWith equivalent', () {
      expect(base().withUnit('bpm'), base().copyWith(unit: 'bpm'));
    });

    test('withRange and withWidthBounds move their pairs together', () {
      final tuned = base().withRange(40, 200).withWidthBounds(20, 120);
      expect(tuned.min, 40);
      expect(tuned.max, 200);
      expect(tuned.minWidth, 20);
      expect(tuned.maxWidth, 120);
      expect(
        tuned,
        base().copyWith(min: 40, max: 200, minWidth: 20, maxWidth: 120),
      );
    });

    test('no individual verb exists for a coupled parameter, and `id` stays '
        'internal', () {
      final source = _generatedSource('y_axis_config_fluent.dart');
      expect(source, isNot(contains('withMin(')));
      expect(source, isNot(contains('withMax(')));
      expect(source, isNot(contains('withMinWidth(')));
      expect(source, isNot(contains('withMaxWidth(')));
      // `id` is force-excluded: a public withId would hijack multi-axis
      // binding identity.
      expect(source, isNot(contains('withId(')));
    });

    test('the fluent surface preserves the axis identity', () {
      final axis = YAxisConfig.withId(
        id: 'power',
        position: YAxisPosition.right,
      );
      expect(axis.withLabel('Power').id, 'power');
    });
  });

  // ===========================================================================
  // lib/src/models/category_axis_config.dart
  // ===========================================================================
  group('category_axis_config.dart', () {
    const base = CategoryAxisConfig(categories: ['Mon', 'Tue']);

    test('withLabelOverflow equals the copyWith equivalent', () {
      expect(
        base.withLabelOverflow(CategoryLabelOverflow.ellipsis),
        base.copyWith(labelOverflow: CategoryLabelOverflow.ellipsis),
      );
    });

    test('a chain equals one combined copyWith', () {
      expect(
        base
            .withCategories(const ['Mon', 'Tue', 'Wed'])
            .withMaxLabelLines(3)
            .withAutoViewport(false),
        base.copyWith(
          categories: const ['Mon', 'Tue', 'Wed'],
          maxLabelLines: 3,
          autoViewport: false,
        ),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/multi_axis_config.dart
  // ===========================================================================
  group('multi_axis_config.dart', () {
    const base = MultiAxisConfig();

    test('withMode equals the copyWith equivalent', () {
      expect(
        base.withMode(NormalizationMode.none),
        base.copyWith(mode: NormalizationMode.none),
      );
    });

    test('withAxes carries fluent-built axes', () {
      final axes = [
        YAxisConfig.withId(
          id: 'hr',
          position: YAxisPosition.left,
        ).withRange(40, 200),
      ];
      expect(base.withAxes(axes), base.copyWith(axes: axes));
      expect(base.withAxes(axes).axes.single.max, 200);
    });
  });

  // ===========================================================================
  // lib/src/models/interaction_config.dart
  // ===========================================================================
  group('interaction_config.dart', () {
    test('CrosshairStyle: withX equals the copyWith equivalent', () {
      const base = CrosshairStyle();
      expect(base.withLineWidth(3), base.copyWith(lineWidth: 3));
      expect(
        base.withStrokeCap(StrokeCap.butt),
        base.copyWith(strokeCap: StrokeCap.butt),
      );
    });

    test('TooltipStyle: withX equals the copyWith equivalent', () {
      const base = TooltipStyle();
      expect(base.withBorderRadius(10), base.copyWith(borderRadius: 10));
    });

    test('TooltipConfig: withX and the nested style updater', () {
      const base = TooltipConfig();
      expect(
        base.withTriggerMode(TooltipTriggerMode.tap),
        base.copyWith(triggerMode: TooltipTriggerMode.tap),
      );
      final updated = base.updateStyle((current) => current.withFontSize(16));
      expect(updated.style.fontSize, 16);
      expect(updated, base.copyWith(style: base.style.copyWith(fontSize: 16)));
    });

    test('GestureConfig: withX equals the copyWith equivalent', () {
      const base = GestureConfig();
      expect(base.withPanThreshold(24), base.copyWith(panThreshold: 24));
    });

    test('KeyboardConfig: withX equals the copyWith equivalent', () {
      const base = KeyboardConfig();
      expect(base.withZoomStep(0.25), base.copyWith(zoomStep: 0.25));
    });

    test('ChartSelectionConfig: withX equals the copyWith equivalent', () {
      const base = ChartSelectionConfig();
      expect(
        base.withAcquisitionMode(ChartSelectionAcquisitionMode.lasso),
        base.copyWith(acquisitionMode: ChartSelectionAcquisitionMode.lasso),
      );
    });

    test('InteractionConfig: withX equals the copyWith equivalent', () {
      const base = InteractionConfig();
      expect(
        base.withKeyboardZoomPercent(40),
        base.copyWith(keyboardZoomPercent: 40),
      );
    });

    test('InteractionConfig: all six nested updaters edit a leaf without '
        're-stating the enclosing config', () {
      const base = InteractionConfig();

      final crosshair = base.updateCrosshair(
        (current) => current.withSnapRadius(32),
      );
      expect(crosshair.crosshair.snapRadius, 32);
      expect(crosshair.crosshair.mode, base.crosshair.mode);

      final tooltip = base.updateTooltip(
        (current) => current.updateStyle((style) => style.withPadding(12)),
      );
      expect(tooltip.tooltip.style.padding, 12);

      final gesture = base.updateGesture(
        (current) => current.withPinchThreshold(0.3),
      );
      expect(gesture.gesture.pinchThreshold, 0.3);

      final keyboard = base.updateKeyboard(
        (current) => current.withPanStep(25),
      );
      expect(keyboard.keyboard.panStep, 25);

      final selection = base.updateSelection(
        (current) => current.withUseModifierKeys(false),
      );
      expect(selection.selection.useModifierKeys, isFalse);

      final summary = base.updateValueSummary(
        (current) => current.withEnabled(true),
      );
      expect(summary.valueSummary.enabled, isTrue);
      expect(
        summary,
        base.copyWith(valueSummary: base.valueSummary.copyWith(enabled: true)),
      );
    });

    test('InteractionConfig: a deep chain equals one combined copyWith', () {
      const base = InteractionConfig();
      expect(
        base
            .withEnableZoom(false)
            .withEnablePan(false)
            .updateCrosshair((current) => current.withEnabled(false)),
        base.copyWith(
          enableZoom: false,
          enablePan: false,
          crosshair: base.crosshair.copyWith(enabled: false),
        ),
      );
    });

    test('function-typed callbacks get no fluent verb', () {
      final source = _generatedSource('interaction_config_fluent.dart');
      expect(source, isNot(contains('withOnDataPointTap(')));
      expect(source, isNot(contains('withCustomBuilder(')));
    });
  });

  // ===========================================================================
  // lib/src/models/cartesian_value_summary_config.dart
  // ===========================================================================
  group('cartesian_value_summary_config.dart', () {
    const base = CartesianValueSummaryConfig();

    test('withEnabled equals the copyWith equivalent', () {
      expect(base.withEnabled(true), base.copyWith(enabled: true));
    });

    test('withOverlayPresentation builds the overlay variant', () {
      final config = base.withOverlayPresentation(
        placement: const ChartOverlayPlacement(anchor: Alignment.bottomRight),
      );
      expect(config.presentation, isA<CartesianValueSummaryOverlay>());
      expect(
        config,
        base.copyWith(
          presentation: const CartesianValueSummaryPresentation.overlay(
            placement: ChartOverlayPlacement(anchor: Alignment.bottomRight),
          ),
        ),
      );
    });

    test('withAnnotationPresentation builds the annotation variant with its '
        'factory defaults', () {
      final config = base.withAnnotationPresentation(draggable: true);
      final presentation =
          config.presentation as CartesianValueSummaryAnnotation;
      expect(presentation.draggable, isTrue);
      // Omitted parameters keep the factory defaults.
      expect(presentation.clampToPlot, isTrue);
      expect(presentation.placement, ChartOverlayPlacement.topLeft);
    });

    test('withAutomaticContent builds the automatic variant', () {
      final config = base.withAutomaticContent(includeTrends: true);
      expect(config.content, isA<CartesianValueSummaryAutomaticContent>());
      expect(
        (config.content as CartesianValueSummaryAutomaticContent).includeTrends,
        isTrue,
      );
    });

    test('the function-typed sealed factory gets NO helper — withContent '
        'carries it instead', () {
      // `withBuilderContent` was the fleet's only function-typed verb: the
      // sealed-variant path bypassed the excludedFunction rule, and the
      // config it minted is the one artifacts refuse to serialize without a
      // REGISTERED descriptorId — which no signature can enforce. The plain
      // withX verb still reaches the variant, at the constructor where that
      // requirement is documented.
      final source = _generatedSource(
        'cartesian_value_summary_config_fluent.dart',
      );
      expect(source, isNot(contains('withBuilderContent')));
      expect(source, contains('withAutomaticContent('));

      CartesianValueSummaryContentModel builder(
        CartesianTrackingSnapshot snapshot,
      ) => const CartesianValueSummaryContentModel(title: 'custom');
      final config = base.withContent(
        CartesianValueSummaryContent.builder(builder, descriptorId: 'demo'),
      );
      final content = config.content as CartesianValueSummaryBuilderContent;
      expect(content.descriptorId, 'demo');
      expect(content.builder, same(builder));
    });

    test('updatePresentation rebuilds the sealed value in place', () {
      final config = base
          .withAnnotationPresentation(draggable: true)
          .updatePresentation(
            (current) => switch (current) {
              CartesianValueSummaryOverlay() => current,
              CartesianValueSummaryAnnotation() => current.withClampToPlot(
                false,
              ),
            },
          );
      final presentation =
          config.presentation as CartesianValueSummaryAnnotation;
      expect(presentation.draggable, isTrue);
      expect(presentation.clampToPlot, isFalse);
    });

    test('updateContent and updateStyle edit the nested leaves', () {
      final content = base.withAutomaticContent().updateContent(
        (current) => switch (current) {
          CartesianValueSummaryAutomaticContent() =>
            current.withIncludeHiddenSeries(true),
          CartesianValueSummaryBuilderContent() => current,
        },
      );
      expect(
        (content.content as CartesianValueSummaryAutomaticContent)
            .includeHiddenSeries,
        isTrue,
      );

      final styled = base.updateStyle((current) => current.withBorderWidth(3));
      expect(styled.style.borderWidth.resolve(0), 3);
    });

    test('the sealed variants carry their own fluent extensions', () {
      const overlay = CartesianValueSummaryOverlay();
      expect(
        overlay
            .withPlacement(
              const ChartOverlayPlacement(anchor: Alignment.topRight),
            )
            .placement,
        const ChartOverlayPlacement(anchor: Alignment.topRight),
      );
      expect(
        overlay
            .updatePlacement((current) => current.withAnchor(Alignment.center))
            .placement
            .anchor,
        Alignment.center,
      );

      const annotation = CartesianValueSummaryAnnotation();
      expect(annotation.withDraggable(true).draggable, isTrue);

      const automatic = CartesianValueSummaryAutomaticContent();
      expect(automatic.withIncludeTrends(true).includeTrends, isTrue);
    });

    test('the controller and the placement callback get no fluent verb', () {
      final source = _generatedSource(
        'cartesian_value_summary_config_fluent.dart',
      );
      expect(source, isNot(contains('withController(')));
      expect(source, isNot(contains('withOnPlacementChanged(')));
    });
  });

  // ===========================================================================
  // lib/src/models/chart_overlay_placement.dart
  // ===========================================================================
  group('chart_overlay_placement.dart', () {
    const base = ChartOverlayPlacement.topLeft;

    test('withAnchor and withOffset equal their copyWith equivalents', () {
      expect(
        base.withAnchor(Alignment.bottomRight),
        base.copyWith(anchor: Alignment.bottomRight),
      );
      expect(
        base.withOffset(const Offset(4, 8)),
        base.copyWith(offset: const Offset(4, 8)),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/auto_scroll_config.dart
  // ===========================================================================
  group('auto_scroll_config.dart', () {
    const base = AutoScrollConfig();

    test('withMaxVisiblePoints equals the copyWith equivalent', () {
      expect(
        base.withMaxVisiblePoints(250),
        base.copyWith(maxVisiblePoints: 250),
      );
    });

    test(
      'a nullable parameter with no copyWith clear flag has no clear verb',
      () {
        final source = _generatedSource('auto_scroll_config_fluent.dart');
        expect(source, contains('withResumeAfterInteractionDelay('));
        expect(source, isNot(contains('clearResumeAfterInteractionDelay(')));
        expect(source, contains('No clear verb'));
      },
    );
  });

  // ===========================================================================
  // lib/src/models/streaming_config.dart
  // ===========================================================================
  group('streaming_config.dart', () {
    const base = StreamingConfig();

    test('withMaxBufferSize equals the copyWith equivalent', () {
      expect(base.withMaxBufferSize(500), base.copyWith(maxBufferSize: 500));
    });

    test('a chain equals one combined copyWith', () {
      expect(
        base.withAutoScroll(false).withAutoScrollWindowSize(64),
        base.copyWith(autoScroll: false, autoScrollWindowSize: 64),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/data_point_label_config.dart
  // ===========================================================================
  group('data_point_label_config.dart', () {
    const base = DataPointLabelConfig();

    test('withPosition equals the copyWith equivalent', () {
      expect(
        base.withPosition(DataPointLabelPosition.below),
        base.copyWith(position: DataPointLabelPosition.below),
      );
    });

    test('the function-typed formatter gets no fluent verb', () {
      final source = _generatedSource('data_point_label_config_fluent.dart');
      expect(source, isNot(contains('withFormatter(')));
    });
  });

  // ===========================================================================
  // lib/src/models/series_inline_label_config.dart
  // ===========================================================================
  group('series_inline_label_config.dart', () {
    test('SeriesLabelBackground: withX equals the copyWith equivalent', () {
      const base = SeriesLabelBackground(color: Color(0xFF102030));
      expect(base.withBorderWidth(2), base.copyWith(borderWidth: 2));
      expect(base.withCornerRadius(6).cornerRadius, 6);
    });

    test('SeriesInlineLabelConfig: withX equals the copyWith equivalent', () {
      const base = SeriesInlineLabelConfig(text: 'FTP');
      expect(
        base.withPosition(SeriesLabelPosition.left),
        base.copyWith(position: SeriesLabelPosition.left),
      );
      expect(
        base
            .withBackground(
              const SeriesLabelBackground(color: Color(0xFF102030)),
            )
            .background,
        isNotNull,
      );
    });

    test('a sentinel-based copyWith yields no clear verb', () {
      // SeriesLabelBackground unsets through `Object? = _sentinel`, not
      // through a `bool clearX` flag, so the derived-clear convention finds
      // nothing to lower onto.
      final source = _generatedSource('series_inline_label_config_fluent.dart');
      expect(source, isNot(contains('clearCornerRadius(')));
      expect(source, isNot(contains('clearBorderColor(')));
      expect(source, contains('No clear verb'));
    });
  });

  // ===========================================================================
  // lib/src/models/segment_style.dart
  // ===========================================================================
  group('segment_style.dart', () {
    test('SegmentStyle: withX and every derived clear verb', () {
      const base = SegmentStyle();
      expect(
        base.withColor(const Color(0xFF00FF00)),
        base.copyWith(color: const Color(0xFF00FF00)),
      );
      final loaded = base
          .withColor(const Color(0xFF00FF00))
          .withStrokeWidth(3)
          .withDashPattern(const [2, 6]);
      expect(loaded.clearColor().color, isNull);
      expect(loaded.clearStrokeWidth().strokeWidth, isNull);
      expect(loaded.clearDashPattern().dashPattern, isNull);
    });

    test('PointStyle: withX and every derived clear verb', () {
      const base = PointStyle();
      expect(base.withSize(9), base.copyWith(size: 9));
      final loaded = base
          .withColor(const Color(0xFFFF0000))
          .withSize(9)
          .withScatterMarkerShape(SeriesMarkerShape.square)
          .withScatterMarkerStyle(const ScatterMarkerStyle(opacity: 0.5));
      expect(loaded.clearColor().color, isNull);
      expect(loaded.clearSize().size, isNull);
      expect(loaded.clearScatterMarkerShape().scatterMarkerShape, isNull);
      expect(loaded.clearScatterMarkerStyle().scatterMarkerStyle, isNull);
    });
  });

  // ===========================================================================
  // lib/src/models/path_animation_style.dart
  // ===========================================================================
  group('path_animation_style.dart', () {
    test('PathAnimationTiming: withX and the overridden clear flag', () {
      const base = PathAnimationTiming();
      expect(
        base.withDelay(const Duration(milliseconds: 40)),
        base.copyWith(delay: const Duration(milliseconds: 40)),
      );
      final timed = base.withDuration(const Duration(milliseconds: 400));
      expect(timed.duration, const Duration(milliseconds: 400));
      // `copyWith` spells this flag `inheritDuration`; the clearFlags override
      // is what maps it onto the `clearX` verb.
      expect(timed.clearDuration(), timed.copyWith(inheritDuration: true));
      expect(timed.clearDuration().duration, isNull);
    });

    test('PathAnimationStyle: withX and both nested updaters', () {
      const base = PathAnimationStyle();
      expect(
        base.withEntranceMode(PathEntranceAnimationMode.reveal),
        base.copyWith(entranceMode: PathEntranceAnimationMode.reveal),
      );
      final entrance = base.updateEntranceTiming(
        (current) => current.withDuration(const Duration(milliseconds: 250)),
      );
      expect(
        entrance.entranceTiming.duration,
        const Duration(milliseconds: 250),
      );
      final update = base.updateDataUpdateTiming(
        (current) => current.withDelay(const Duration(milliseconds: 10)),
      );
      expect(update.dataUpdateTiming.delay, const Duration(milliseconds: 10));
    });

    test('the series-level nested updater reaches the animation leaf', () {
      const series = LineChartSeries(
        id: 'power',
        points: [ChartDataPoint(x: 0, y: 1)],
      );
      final animated = series.updatePathAnimation(
        (current) => current.withEntranceMode(PathEntranceAnimationMode.reveal),
      );
      expect(
        animated.pathAnimation.entranceMode,
        PathEntranceAnimationMode.reveal,
      );
    });
  });

  // ===========================================================================
  // lib/src/models/scatter_marker_style.dart
  // ===========================================================================
  group('scatter_marker_style.dart', () {
    test('ScatterMarkerStyle: withX and every derived clear verb', () {
      const base = ScatterMarkerStyle();
      expect(base.withOpacity(0.5), base.copyWith(opacity: 0.5));
      final loaded = base
          .withFillColor(const Color(0xFF102030))
          .withStrokeColor(const Color(0xFF405060))
          .withStrokeWidth(2)
          .withOpacity(0.5)
          .withWidth(10)
          .withHeight(12)
          .withRotationDegrees(45);
      expect(loaded.clearFillColor().fillColor, isNull);
      expect(loaded.clearStrokeColor().strokeColor, isNull);
      expect(loaded.clearStrokeWidth().strokeWidth, isNull);
      expect(loaded.clearOpacity().opacity, isNull);
      expect(loaded.clearWidth().width, isNull);
      expect(loaded.clearHeight().height, isNull);
      // `copyWith` spells this flag `clearRotation`; the clearFlags override
      // supplies the missing derivation.
      expect(
        loaded.clearRotationDegrees(),
        loaded.copyWith(clearRotation: true),
      );
      expect(loaded.clearRotationDegrees().rotationDegrees, isNull);
    });

    test('ScatterInteractionStyle: withX and its three clear verbs', () {
      const base = ScatterInteractionStyle();
      expect(base.withHoverScale(1.6), base.copyWith(hoverScale: 1.6));
      final loaded = base
          .withHoverColor(const Color(0xFF102030))
          .withSelectionColor(const Color(0xFF405060))
          .withFocusColor(const Color(0xFF708090));
      expect(loaded.clearHoverColor().hoverColor, isNull);
      expect(loaded.clearSelectionColor().selectionColor, isNull);
      expect(loaded.clearFocusColor().focusColor, isNull);
    });

    test('the series-level nested updater reaches the interaction leaf', () {
      const series = ScatterChartSeries(
        id: 'scatter',
        points: [ChartDataPoint(x: 0, y: 1)],
      );
      final updated = series.updateInteractionStyle(
        (current) => current.withDimmedOpacity(0.5),
      );
      expect(updated.interactionStyle.dimmedOpacity, 0.5);
    });
  });

  // ===========================================================================
  // lib/src/models/annotation_style.dart
  // ===========================================================================
  group('annotation_style.dart', () {
    const base = AnnotationStyle();

    test('withBorderWidth equals the copyWith equivalent', () {
      expect(base.withBorderWidth(3), base.copyWith(borderWidth: 3));
    });

    test('a 3-step chain equals the single copyWith and does not mutate', () {
      final chained = base
          .withBackgroundColor(const Color(0xFF112233))
          .withBorderColor(const Color(0xFF445566))
          .withPadding(const EdgeInsets.all(6));
      expect(
        chained,
        base.copyWith(
          backgroundColor: const Color(0xFF112233),
          borderColor: const Color(0xFF445566),
          padding: const EdgeInsets.all(6),
        ),
      );
      expect(base.backgroundColor, isNull);
    });

    test('the nullable gap is documented, not silently unclearable', () {
      final source = _generatedSource('annotation_style_fluent.dart');
      expect(source, isNot(contains('clearBackgroundColor(')));
      expect(source, contains("No clear verb: this class's copyWith cannot"));
    });
  });

  // ===========================================================================
  // lib/src/models/chart_annotation.dart
  // ===========================================================================
  group('chart_annotation.dart', () {
    test('PointAnnotation withMarkerSize equals the copyWith equivalent', () {
      final base = PointAnnotation(seriesId: 's', dataPointIndex: 3);
      final widened = base.withMarkerSize(14);
      expect(widened.markerSize, 14);
      expect(widened.markerSize, base.copyWith(markerSize: 14).markerSize);
      // The chain does not mutate the receiver.
      expect(base.markerSize, 8.0);
    });

    test(
      'PointAnnotation updateStyle rebuilds the nested annotation style',
      () {
        final base = PointAnnotation(
          seriesId: 's',
          dataPointIndex: 0,
        ).withStyle(const AnnotationStyle(borderWidth: 1));
        final updated = base.updateStyle(
          (current) => current.withBorderWidth(5),
        );
        expect(updated.style.borderWidth, 5);
        expect(base.style.borderWidth, 1);
      },
    );

    test('RangeAnnotation bounds are construction-only — a band must stay a '
        'band', () {
      // An X-only band and a Y-only band are legal ranges (the constructor
      // asserts `startX != null || startY != null`, an OR). copyWith merges
      // each bound with `??` and has no clear flag, so nothing can put one
      // BACK to null: the withBounds(startX, endX, startY, endY) this class
      // used to generate took all four non-nullable and silently converted a
      // band into a box.
      final band = RangeAnnotation(startX: 0, endX: 1);
      expect(band.startY, isNull);
      expect(
        band.copyWith(startY: 10, endY: 40).startX,
        0,
        reason: 'copyWith cannot null the opposite pair',
      );
      final source = _generatedSource('chart_annotation_fluent.dart');
      expect(source, isNot(contains('withBounds(')));
    });

    test('RangeAnnotation: the invalid intermediate is unreachable', () {
      final base = RangeAnnotation(startX: 0, endX: 1);
      // Inverting a single bound throws on the raw config API...
      expect(() => base.copyWith(startX: 50), throwsA(isA<AssertionError>()));
      // ...and no verb exists for any coupled bound, combined or individual.
      final source = _generatedSource('chart_annotation_fluent.dart');
      expect(source, isNot(contains('RangeAnnotation withStartX(')));
      expect(source, isNot(contains('RangeAnnotation withEndX(')));
      expect(source, isNot(contains('RangeAnnotation withStartY(')));
      expect(source, isNot(contains('RangeAnnotation withEndY(')));
      // `id` is a join key for selection state and artifact documents.
      expect(source, isNot(contains('withId(')));
    });

    test('TextAnnotation withText and withAnchor equal their copyWith', () {
      final base = TextAnnotation(text: 'a', position: const Offset(4, 4));
      expect(base.withText('b').text, 'b');
      expect(
        base.withAnchor(AnnotationAnchor.center).anchor,
        AnnotationAnchor.center,
      );
    });

    test(
      'TextAnnotation withText SAYS it does nothing on a rich annotation',
      () {
        // The reader models the public plain-text constructor while copyWith
        // rebuilds through `_internal`, so `withText` type-checks on a rich
        // annotation, stores the text, and is never drawn: `isRichText` stays
        // true and the Delta keeps winning. The class cannot be fixed from the
        // fluent layer, so the generated verb states the limitation.
        final rich = TextAnnotation.rich(
          richTextDelta: const [
            {'insert': 'bold\n'},
          ],
          position: const Offset(4, 4),
        );
        final retexted = rich.withText('plain');
        expect(retexted.isRichText, isTrue);
        expect(retexted.richTextDelta, isNotNull);

        final source = _generatedSource('chart_annotation_fluent.dart');
        expect(source, contains('No effect on a RICH annotation'));
        // The rich half itself is construction-only.
        expect(source, isNot(contains('withRichTextDelta(')));
      },
    );

    test('ThresholdAnnotation withValue equals the copyWith equivalent', () {
      final base = ThresholdAnnotation(axis: AnnotationAxis.y, value: 100);
      expect(base.withValue(180).value, 180);
      expect(base.withValue(180).value, base.copyWith(value: 180).value);
    });

    test('PinAnnotation withX/withY equal their copyWith equivalents', () {
      final base = PinAnnotation(x: 1, y: 2);
      expect(base.withX(9).x, 9);
      expect(base.withY(7).y, 7);
    });

    test('TrendAnnotation withTrend moves the coupled pair together', () {
      final base = TrendAnnotation(trendType: TrendType.linear);
      final moving = base.withTrend(TrendType.movingAverage, 7);
      expect(moving.trendType, TrendType.movingAverage);
      expect(moving.windowSize, 7);
    });

    test('TrendAnnotation: the invalid intermediate is unreachable', () {
      final base = TrendAnnotation(trendType: TrendType.linear);
      // Switching to a moving average without a window throws...
      expect(
        () => base.copyWith(trendType: TrendType.movingAverage),
        throwsA(isA<AssertionError>()),
      );
      // ...and neither half has an individual verb.
      final source = _generatedSource('chart_annotation_fluent.dart');
      expect(source, isNot(contains('TrendAnnotation withTrendType(')));
      expect(source, isNot(contains('TrendAnnotation withWindowSize(')));
    });

    test('ErrorBarAnnotation withCapSize equals the copyWith equivalent', () {
      final base = ErrorBarAnnotation(
        seriesId: 's',
        values: const [ErrorBarDatum(pointIndex: 0, yPositive: 1)],
      );
      expect(base.withCapSize(9).capSize, 9);
    });

    test('ChordAnnotation withEndpoints moves the coupled indices', () {
      final base = ChordAnnotation(seriesId: 's', startIndex: 0, endIndex: 1);
      final moved = base.withEndpoints(4, 9);
      expect(moved.startIndex, 4);
      expect(moved.endIndex, 9);
    });

    test('ChordAnnotation: the invalid intermediate is unreachable', () {
      final base = ChordAnnotation(seriesId: 's', startIndex: 0, endIndex: 1);
      // Collapsing the chord onto one point throws...
      expect(() => base.copyWith(endIndex: 0), throwsA(isA<AssertionError>()));
      // ...and neither index has an individual verb.
      final source = _generatedSource('chart_annotation_fluent.dart');
      expect(source, isNot(contains('ChordAnnotation withStartIndex(')));
      expect(source, isNot(contains('ChordAnnotation withEndIndex(')));
    });

    test('LegendAnnotation clearCustomPosition unsets the drag override', () {
      final base = LegendAnnotation().withCustomPosition(const Offset(20, 30));
      expect(base.customPosition, const Offset(20, 30));
      expect(base.clearCustomPosition().customPosition, isNull);
    });

    test('LegendAnnotation: the mutually exclusive scales get no verb', () {
      // `assert([sizeScale, colorScale, opacityScale, categoryScale]
      // .whereType<Object>().length <= 1)` — a second scale throws, so the
      // four are force-excluded rather than given chainable setters.
      final source = _generatedSource('chart_annotation_fluent.dart');
      expect(source, isNot(contains('withSizeScale(')));
      expect(source, isNot(contains('withColorScale(')));
      expect(source, isNot(contains('withOpacityScale(')));
      expect(source, isNot(contains('withCategoryScale(')));
    });

    test('LegendAnnotation updateLegendStyle reaches the nested style', () {
      final base = LegendAnnotation();
      final updated = base.updateLegendStyle(
        (current) => current.withBorderWidth(3),
      );
      expect(updated.legendStyle.borderWidth, 3);
    });
  });

  // ===========================================================================
  // lib/src/models/grid_config.dart
  // ===========================================================================
  group('grid_config.dart', () {
    const base = GridConfig();

    test('withHorizontal equals the copyWith equivalent', () {
      expect(base.withHorizontal(false), base.copyWith(horizontal: false));
    });

    test('a 3-step chain equals the single copyWith', () {
      expect(
        base
            .withVertical(false)
            .withHorizontalStrokeWidth(2)
            .withVerticalColor(const Color(0xFF223344)),
        base.copyWith(
          vertical: false,
          horizontalStrokeWidth: 2,
          verticalColor: const Color(0xFF223344),
        ),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/legend_style.dart
  // ===========================================================================
  group('legend_style.dart', () {
    const base = LegendStyle();

    test('withPosition equals the copyWith equivalent', () {
      expect(
        base.withPosition(LegendPosition.bottomCenter),
        base.copyWith(position: LegendPosition.bottomCenter),
      );
    });

    test('a 3-step chain equals the single copyWith', () {
      expect(
        base.withBorderWidth(2).withItemSpacing(9).withAllowDragging(false),
        base.copyWith(borderWidth: 2, itemSpacing: 9, allowDragging: false),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/pie_chart_config.dart
  // ===========================================================================
  group('pie_chart_config.dart', () {
    test('PieGradientStyle: withX plus both derived clear verbs', () {
      const base = PieGradientStyle();
      expect(base.withAngleDegrees(30), base.copyWith(angleDegrees: 30));
      final tinted = base
          .withStartColor(const Color(0xFFAABBCC))
          .withEndColor(const Color(0xFF112233));
      expect(tinted.clearStartColor().startColor, isNull);
      expect(tinted.clearEndColor().endColor, isNull);
    });

    test('PieElevationStyle: withX equals the copyWith equivalent', () {
      const base = PieElevationStyle();
      expect(base.withBlurRadius(6), base.copyWith(blurRadius: 6));
      expect(
        base.withColor(const Color(0xFF000000)).clearColor().color,
        isNull,
      );
    });

    test('PieChartTheme: nested updaters reach both elevation leaves', () {
      const base = PieChartTheme();
      final lifted = base.updateShadow((current) => current.withBlurRadius(9));
      expect(lifted.shadow.blurRadius, 9);
      final selected = base.updateSelectedElevation(
        (current) => current.withSpreadRadius(4),
      );
      expect(selected.selectedElevation.spreadRadius, 4);
      expect(base.shadow.blurRadius, 0);
    });

    test('PieSliceRadiusConfig: withX and clearUnit', () {
      const base = PieSliceRadiusConfig();
      expect(base.withMinimumFactor(0.5), base.copyWith(minimumFactor: 0.5));
      expect(base.withUnit('mm').clearUnit().unit, isNull);
    });

    test('PieChartStyle: a 3-step chain equals the single copyWith', () {
      const base = PieChartStyle();
      expect(
        base.withRadiusFactor(0.7).withSliceGap(4).withClockwise(false),
        base.copyWith(radiusFactor: 0.7, sliceGap: 4, clockwise: false),
      );
      expect(base.radiusFactor, 0.9);
    });

    test('PieChartStyle: every derived clear verb unsets its field', () {
      const base = PieChartStyle();
      final loaded = base
          .withBorderColor(const Color(0xFF010203))
          .withOpacity(0.5)
          .withCornerRadius(3)
          .withGradient(const PieGradientStyle())
          .withShadow(const PieElevationStyle())
          .withSelectedElevation(const PieElevationStyle())
          .withCornerTreatment(PieCornerTreatment.outerOnly)
          .withBorderColorMode(PieBorderColorMode.slice)
          .withAnimationMode(PieAnimationMode.fade);
      expect(loaded.clearBorderColor().borderColor, isNull);
      expect(loaded.clearOpacity().opacity, isNull);
      expect(loaded.clearCornerRadius().cornerRadius, isNull);
      expect(loaded.clearGradient().gradient, isNull);
      expect(loaded.clearShadow().shadow, isNull);
      expect(loaded.clearSelectedElevation().selectedElevation, isNull);
      expect(loaded.clearCornerTreatment().cornerTreatment, isNull);
      expect(loaded.clearBorderColorMode().borderColorMode, isNull);
      expect(loaded.clearAnimationMode().animationMode, isNull);
    });

    test('PieDataLabelConfig: withX and clearSecondaryContent', () {
      const base = PieDataLabelConfig();
      expect(base.withPadding(9), base.copyWith(padding: 9));
      final loaded = base.withSecondaryContent(PieDataLabelContent.value);
      expect(loaded.clearSecondaryContent().secondaryContent, isNull);
    });
  });

  // ===========================================================================
  // lib/src/models/donut_chart_config.dart
  // ===========================================================================
  group('donut_chart_config.dart', () {
    test('DonutCenterContent: withX and its derived clear verbs', () {
      const base = DonutCenterContent();
      expect(base.withLabel('Total'), base.copyWith(label: 'Total'));
      final loaded = base.withLabel('Total').withCustomValue('42');
      expect(loaded.clearLabel().label, isNull);
      expect(loaded.clearCustomValue().customValue, isNull);
    });

    test('DonutChartStyle: withX equals the copyWith equivalent', () {
      const base = DonutChartStyle();
      expect(
        base.withInnerRadiusFactor(0.4),
        base.copyWith(innerRadiusFactor: 0.4),
      );
    });

    test('a base-typed verb keeps the subclass and its fields', () {
      // The cross-library slicing question, pinned as behaviour: `withX` is
      // typed to PieChartStyle, but `copyWith` dispatches VIRTUALLY, so the
      // DonutChartStyle identity and its own fields survive. This is why
      // PieChartStyle is modelled rather than exempted.
      const PieChartStyle style = DonutChartStyle(innerRadiusFactor: 0.4);
      final widened = style.withRadiusFactor(0.5);
      expect(widened, isA<DonutChartStyle>());
      expect((widened as DonutChartStyle).innerRadiusFactor, 0.4);
      expect(widened.radiusFactor, 0.5);
    });

    test('ChartDataPoint verbs keep a CandlestickDataPoint intact', () {
      final ChartDataPoint point = CandlestickDataPoint(
        x: 0,
        open: 1,
        high: 3,
        low: 0.5,
        close: 2,
      );
      final labelled = point.withLabel('bar');
      expect(labelled, isA<CandlestickDataPoint>());
      expect((labelled as CandlestickDataPoint).open, 1);
      expect(labelled.high, 3);
      expect(labelled.label, 'bar');
    });
  });

  // ===========================================================================
  // lib/src/models/polar_chart_config.dart
  // ===========================================================================
  group('polar_chart_config.dart', () {
    test('PolarThreshold: withX and its derived clear verbs', () {
      const base = PolarThreshold(value: 10);
      expect(base.withWidth(3), base.copyWith(width: 3));
      final loaded = base.withLabel('cap').withColor(const Color(0xFF223344));
      expect(loaded.clearLabel().label, isNull);
      expect(loaded.clearColor().color, isNull);
    });

    test('PolarColumnCompositionConfig: withX equals the copyWith', () {
      const base = PolarColumnCompositionConfig();
      expect(
        base.withMode(PolarColumnCompositionMode.grouped),
        base.copyWith(mode: PolarColumnCompositionMode.grouped),
      );
    });

    test('PolarPaneConfig: a 3-step chain equals the single copyWith', () {
      const base = PolarPaneConfig();
      expect(
        base
            .withStartAngleDegrees(0)
            .withSweepAngleDegrees(180)
            .withClipMarks(false),
        base.copyWith(
          startAngleDegrees: 0,
          sweepAngleDegrees: 180,
          clipMarks: false,
        ),
      );
    });

    test('PolarLabelStyle: withX plus all three clear verbs', () {
      const base = PolarLabelStyle();
      final loaded = base
          .withColor(const Color(0xFF556677))
          .withFontSize(14)
          .withFontWeight(FontWeight.w600);
      expect(loaded.clearColor().color, isNull);
      expect(loaded.clearFontSize().fontSize, isNull);
      expect(loaded.clearFontWeight().fontWeight, isNull);
    });

    test('PolarCategoryAxisConfig: withX and the nested label updater', () {
      const base = PolarCategoryAxisConfig();
      expect(base.withLabelOffset(6), base.copyWith(labelOffset: 6));
      final restyled = base.updateLabelStyle(
        (current) => current.withFontSize(11),
      );
      expect(restyled.labelStyle.fontSize, 11);
    });

    test('PolarNumericAxisConfig: withX and every derived clear verb', () {
      const base = PolarNumericAxisConfig();
      final loaded = base
          .withMinimum(0)
          .withMaximum(100)
          .withScaleMode(PolarRadialScaleMode.areaCorrect);
      expect(loaded.clearMinimum().minimum, isNull);
      expect(loaded.clearMaximum().maximum, isNull);
      expect(loaded.clearScaleMode().scaleMode, isNull);
      expect(base.withTickCount(8), base.copyWith(tickCount: 8));
    });

    test('PolarChartConfig: all four nested updaters reach a leaf', () {
      const base = PolarChartConfig();
      expect(
        base
            .updatePane((c) => c.withInnerRadiusFactor(0.2))
            .pane
            .innerRadiusFactor,
        0.2,
      );
      expect(
        base
            .updateAngularAxis((c) => c.withShowLabels(false))
            .angularAxis
            .showLabels,
        isFalse,
      );
      expect(
        base.updateRadialAxis((c) => c.withTickCount(9)).radialAxis.tickCount,
        9,
      );
      expect(
        base
            .updateComposition((c) => c.withGroupInnerPadding(0.3))
            .composition
            .groupInnerPadding,
        0.3,
      );
      expect(
        base.withThresholds(const [PolarThreshold(value: 5)]).thresholds,
        hasLength(1),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/concentric_donut_config.dart
  // ===========================================================================
  group('concentric_donut_config.dart', () {
    const base = ConcentricDonutConfig();

    test('withRingGap equals the copyWith equivalent', () {
      expect(base.withRingGap(8), base.copyWith(ringGap: 8));
    });

    test('updateCenterContent reaches the donut centre leaf', () {
      expect(
        base
            .updateCenterContent((current) => current.withLabel('Sum'))
            .centerContent
            .label,
        'Sum',
      );
    });
  });

  // ===========================================================================
  // lib/src/models/radial_selection_style.dart
  // ===========================================================================
  group('radial_selection_style.dart', () {
    const base = RadialSelectionStyle();

    test('a 3-step chain equals the single copyWith', () {
      expect(
        base
            .withEffect(RadialSelectionEffect.lift)
            .withLiftScale(1.2)
            .withBackdropBlur(2),
        base.copyWith(
          effect: RadialSelectionEffect.lift,
          liftScale: 1.2,
          backdropBlur: 2,
        ),
      );
    });
  });

  // ===========================================================================
  // lib/src/models/chart_theme.dart
  // ===========================================================================
  group('chart_theme.dart', () {
    test('every nested component updater reaches its leaf', () {
      final base = ChartTheme.light;
      expect(
        base.updateGridStyle((c) => c.withMajorWidth(3)).gridStyle.majorWidth,
        3,
      );
      expect(
        base.updateAxisStyle((c) => c.withTickLength(9)).axisStyle.tickLength,
        9,
      );
      expect(
        base
            .updateSeriesTheme((c) => c.withLineWidths(const [4]))
            .seriesTheme
            .lineWidths,
        const [4],
      );
      expect(
        base
            .updateTypographyTheme((c) => c.withBaseFontSize(15))
            .typographyTheme
            .baseFontSize,
        15,
      );
      expect(
        base
            .updateInteractionTheme((c) => c.withCrosshairWidth(2.5))
            .interactionTheme
            .crosshairWidth,
        2.5,
      );
      expect(
        base
            .updateAnnotationTheme(
              (c) => c.updateTrendDefaults((t) => t.withLineWidth(4)),
            )
            .annotationTheme
            .trendDefaults
            .lineWidth,
        4,
      );
      expect(
        base
            .updateScrollbarConfig((c) => c.withThickness(20))
            .scrollbarConfig
            .thickness,
        20,
      );
      expect(
        base
            .updateAnimationTheme(
              (c) => c.withInteractionDuration(const Duration(seconds: 3)),
            )
            .animationTheme
            .interactionDuration,
        const Duration(seconds: 3),
      );
      expect(
        base
            .updateCandlestickTheme(
              (c) => c.withRisingBodyFillColor(const Color(0xFF00FF00)),
            )
            .candlestickTheme
            .risingBodyFillColor,
        const Color(0xFF00FF00),
      );
      expect(
        base
            .updateCartesianValueSummaryTheme((c) => c.withBorderWidth(3))
            .cartesianValueSummaryTheme
            .borderWidth,
        3,
      );
      expect(
        base
            .updateLegendStyle((c) => c.withItemSpacing(11))
            .legendStyle
            .itemSpacing,
        11,
      );
      expect(
        base
            .updatePieChartTheme((c) => c.withOpacity(0.5))
            .pieChartTheme
            .opacity,
        0.5,
      );
      // The chain did not mutate the receiver.
      expect(base.gridStyle.majorWidth, ChartTheme.light.gridStyle.majorWidth);
    });

    test('the deprecated private-field-backed params get no verb (E1)', () {
      // `gridColor`, `axisColor`, `textColor` and `seriesColors` are
      // `@Deprecated` constructor params with no matching `copyWith`
      // parameter; the engine drops them instead of emitting dead verbs.
      final source = _generatedSource('chart_theme_fluent.dart');
      expect(source, isNot(contains('withGridColor(')));
      expect(source, isNot(contains('withAxisColor(')));
      expect(source, isNot(contains('withTextColor(')));
      expect(source, isNot(contains('withSeriesColors(')));
    });
  });

  // ===========================================================================
  // lib/src/theming/components/ + styles/ + table/
  // ===========================================================================
  group('theming components', () {
    test('AnimationTheme: withX equals the copyWith equivalent', () {
      final base = AnimationTheme.defaultLight;
      expect(
        base.withDataUpdateDuration(const Duration(milliseconds: 700)),
        base.copyWith(dataUpdateDuration: const Duration(milliseconds: 700)),
      );
    });

    test('AnnotationTheme: all five nested updaters edit a leaf', () {
      const base = AnnotationTheme.defaultLight;
      expect(
        base
            .updatePointDefaults((c) => c.withMarkerSize(20))
            .pointDefaults
            .markerSize,
        20,
      );
      expect(
        base
            .updateRangeDefaults((c) => c.withBorderWidth(4))
            .rangeDefaults
            .borderWidth,
        4,
      );
      expect(
        base
            .updateTextDefaults((c) => c.withBorderRadius(21))
            .textDefaults
            .borderRadius,
        21,
      );
      expect(
        base
            .updateThresholdDefaults((c) => c.withLineWidth(6))
            .thresholdDefaults
            .lineWidth,
        6,
      );
      expect(
        base
            .updateTrendDefaults((c) => c.withLineWidth(7))
            .trendDefaults
            .lineWidth,
        7,
      );
      expect(
        base
            .updatePointDefaults(
              (c) => c.updateLabelStyle((l) => l.withBorderWidth(5)),
            )
            .pointDefaults
            .labelStyle
            .borderWidth,
        5,
      );
    });

    test('AxisStyle: a 3-step chain equals the single copyWith', () {
      const base = AxisStyle.defaultLight;
      expect(
        base.withLineWidth(2).withShowTicks(false).withTickWidth(3),
        base.copyWith(lineWidth: 2, showTicks: false, tickWidth: 3),
      );
    });

    test('CandlestickTheme: withX equals the copyWith equivalent', () {
      const base = CandlestickTheme.light;
      expect(
        base.withDojiWickColor(const Color(0xFF123456)),
        base.copyWith(dojiWickColor: const Color(0xFF123456)),
      );
    });

    test('CartesianValueSummaryTheme: withX equals the copyWith', () {
      const base = CartesianValueSummaryTheme.light;
      expect(base.withRowGap(6), base.copyWith(rowGap: 6));
    });

    test('GridStyle: withMinorGrid moves the three coupled inputs', () {
      const base = GridStyle.defaultLight;
      final minor = base.withMinorGrid(
        showMinor: true,
        minorColor: const Color(0xFFEEEEEE),
        minorWidth: 0.5,
      );
      expect(minor.showMinor, isTrue);
      expect(minor.minorColor, const Color(0xFFEEEEEE));
      expect(minor.minorWidth, 0.5);
    });

    test('GridStyle: the invalid intermediate is unreachable', () {
      // Turning minor lines on without a colour/width throws...
      expect(
        () => GridStyle.defaultLight.copyWith(showMinor: true),
        throwsA(isA<AssertionError>()),
      );
      // ...and no individual verb exists for any of the three.
      final source = _generatedThemingSource(
        'components',
        'grid_style_fluent.dart',
      );
      expect(source, isNot(contains('withShowMinor(')));
      expect(source, isNot(contains('withMinorColor(')));
      expect(source, isNot(contains('withMinorWidth(')));
    });

    test('InteractionTheme: withX plus the nested label-style updaters', () {
      const base = InteractionTheme.defaultLight;
      expect(base.withCrosshairWidth(3), base.copyWith(crosshairWidth: 3));
      expect(
        base
            .updateCrosshairLabelStyle((c) => c.withBorderRadius(7))
            .crosshairLabelStyle
            .borderRadius,
        7,
      );
    });

    test('ScrollbarConfig: a 3-step chain equals the single copyWith', () {
      const base = ScrollbarConfig();
      expect(
        base.withThickness(14).withAutoHide(false).withPadding(6),
        base.copyWith(thickness: 14, autoHide: false, padding: 6),
      );
    });

    test('SeriesTheme: withX equals the copyWith equivalent', () {
      final base = SeriesTheme.defaultLight;
      expect(
        base.withMarkerSizes(const [3, 4]),
        base.copyWith(markerSizes: const [3, 4]),
      );
    });

    test('TypographyTheme: withX equals the copyWith equivalent', () {
      final base = TypographyTheme.defaultLight;
      expect(
        base.withTitleMultiplier(1.8),
        base.copyWith(titleMultiplier: 1.8),
      );
    });

    test('LabelStyle: withX equals the copyWith equivalent', () {
      final base = InteractionTheme.defaultLight.crosshairLabelStyle;
      expect(base.withBorderWidth(3), base.copyWith(borderWidth: 3));
    });

    test('ChartDataTableTheme: a 3-step chain matches the single copyWith', () {
      // A ThemeExtension carries no `operator ==`, so the chain is compared
      // field by field.
      const base = ChartDataTableTheme();
      final chained = base
          .withRowHeight(40)
          .withHeaderHeight(50)
          .withDividerColor(const Color(0xFF999999));
      final direct = base.copyWith(
        rowHeight: 40,
        headerHeight: 50,
        dividerColor: const Color(0xFF999999),
      );
      expect(chained.rowHeight, direct.rowHeight);
      expect(chained.headerHeight, direct.headerHeight);
      expect(chained.dividerColor, direct.dividerColor);
      expect(base.rowHeight, 36);
    });
  });

  // ===========================================================================
  // Exempt runtime/result types (Task 5 judgement call)
  // ===========================================================================
  group('exempt runtime types', () {
    test('ChartTransform and BarGroupInfo get no fluent extension', () {
      final directory = Directory(
        [
          Directory.current.path,
          'lib',
          'src',
          'fluent',
          'generated',
        ].join(Platform.pathSeparator),
      );
      final sources = StringBuffer();
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          sources.writeln(entity.readAsStringSync());
        }
      }
      expect(sources.toString(), isNot(contains('ChartTransformFluent')));
      expect(sources.toString(), isNot(contains('BarGroupInfoFluent')));
    });
  });
}
