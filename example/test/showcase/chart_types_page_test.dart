import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_types_page.dart';
import 'package:braven_charts_example/showcase/widgets/chart_type_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart types is a concise native-rendered family overview', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chart Types'), findsOneWidget);
    expect(find.text('Start with the data question'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-type-cartesian-grid')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsNWidgets(5));
    for (final family in ['Line', 'Area', 'Bar', 'Scatter', 'Candlestick']) {
      expect(find.text(family), findsOneWidget);
    }
    expect(find.text('Motion'), findsOneWidget);
    expect(find.text('Chart Options'), findsNothing);
    expect(find.text('Regenerate Dataset'), findsNothing);
    final lineWidth = tester
        .getSize(find.byKey(const ValueKey('chart-type-card-line')))
        .width;

    await tester.drag(
      find.byKey(const ValueKey('chart-types-overview')),
      const Offset(0, -800),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chart-type-radial-grid')),
      findsOneWidget,
    );
    expect(showcaseChartTypes, hasLength(9));
    expect(find.byType(BravenChartPlus), findsAtLeastNWidgets(3));
    for (final family in ['Pie', 'Donut', 'Concentric Donut']) {
      expect(find.text(family), findsOneWidget);
    }
    expect(find.text('Grouping'), findsOneWidget);
    expect(find.text('Variable radius'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('chart-type-card-pie'))).width,
      greaterThan(lineWidth),
    );
    await tester.drag(
      find.byKey(const ValueKey('chart-types-overview')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chart-type-polar-grid')), findsOneWidget);
    expect(find.text('Polar Column'), findsOneWidget);
  });

  testWidgets('family cards open the matching deep guides', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    String? selectedSlug;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartTypesPage(onOpenChartType: (slug) => selectedSlug = slug),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('chart-type-card-bar')));
    await tester.pump();
    expect(selectedSlug, 'bar-charts');

    await tester.tap(find.byKey(const ValueKey('chart-type-card-candlestick')));
    await tester.pump();
    expect(selectedSlug, 'candlestick-charts');

    await tester.drag(
      find.byKey(const ValueKey('chart-types-overview')),
      const Offset(0, -800),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('chart-type-card-donut')));
    await tester.pump();
    expect(selectedSlug, 'donut-charts');

    await tester.tap(
      find.byKey(const ValueKey('chart-type-card-concentric-donut')),
    );
    await tester.pump();
    expect(selectedSlug, 'concentric-donut');

    await tester.drag(
      find.byKey(const ValueKey('chart-types-overview')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('chart-type-card-polar-column')),
    );
    await tester.pump();
    expect(selectedSlug, 'polar-column');
  });

  testWidgets('radial catalog previews fill their cards with concise actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: ChartTypeCatalogStrip(onOpenChartType: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final pie = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-pie')),
    );
    final pieSeries = pie.series.single as PieChartSeries;
    expect(pieSeries.pieStyle.radiusFactor, 1.0);

    final donut = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-donut')),
    );
    final donutSeries = donut.series.single as DonutChartSeries;
    expect(donutSeries.donutStyle.radiusFactor, 0.94);

    final concentric = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-concentric-donut')),
    );
    expect(concentric.concentricDonutConfig.outerRadiusFactor, 0.92);
    expect(concentric.series, hasLength(3));
    expect(concentric.concentricDonutConfig.centerContent.customValue, '3');
    final concentricScale = tester.widget<Transform>(
      find.byKey(const ValueKey('chart-type-preview-scale-concentric-donut')),
    );
    expect(concentricScale.transform.getMaxScaleOnAxis(), closeTo(1.12, 0.001));
    expect(
      tester.getSize(find.byKey(const ValueKey('chart-type-card-pie'))).width,
      greaterThan(
        tester
            .getSize(find.byKey(const ValueKey('chart-type-card-line')))
            .width,
      ),
    );
    expect(find.text('View Concentric'), findsOneWidget);
    final polar = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-polar-column')),
    );
    expect(polar.series.single, isA<PolarColumnChartSeries>());
    expect(polar.polarChartConfig.angularAxis.showLabels, isFalse);
    expect(find.text('View Polar Column'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gallery and Chart Types share animated previews', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    void expectConfiguredEntrances() {
      final line = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('chart-type-preview-line')),
      );
      expect(
        line.series.whereType<LineChartSeries>().map(
          (series) => series.pathAnimation.entranceMode,
        ),
        everyElement(PathEntranceAnimationMode.reveal),
      );

      final area = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('chart-type-preview-area')),
      );
      expect(
        area.series.whereType<AreaChartSeries>().map(
          (series) => series.pathAnimation.entranceMode,
        ),
        everyElement(PathEntranceAnimationMode.reveal),
      );

      final scatter = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('chart-type-preview-scatter')),
      );
      expect(scatter.series.whereType<ScatterChartSeries>(), hasLength(3));
    }

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump();
    expectConfiguredEntrances();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: ChartTypeCatalogStrip(onOpenChartType: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
    expectConfiguredEntrances();
  });

  testWidgets(
    'Scatter preview markers enter on mount and respect reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(420, 260);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scatterType = showcaseChartTypeForSlug('scatter-charts');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChartTypePreview(chartType: scatterType)),
        ),
      );

      ScatterChartSeries firstSeries() =>
          tester
                  .widget<BravenChartPlus>(
                    find.byKey(const ValueKey('chart-type-preview-scatter')),
                  )
                  .series
                  .first
              as ScatterChartSeries;

      expect(firstSeries().markerRadius, 0);
      expect(firstSeries().markerStyle?.opacity, 0);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(firstSeries().markerRadius, greaterThan(0));
      expect(firstSeries().markerRadius, lessThan(4.4));

      await tester.pump(const Duration(milliseconds: 500));
      expect(firstSeries().markerRadius, closeTo(4.4, 0.001));
      expect(firstSeries().markerStyle?.opacity, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: ChartTypePreview(chartType: scatterType)),
          ),
        ),
      );
      await tester.pump();
      expect(firstSeries().markerRadius, closeTo(4.4, 0.001));
      expect(firstSeries().markerStyle?.opacity, 1);
    },
  );

  testWidgets('Polar Column preview uses its native sweep entrance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartTypePreview(
            chartType: showcaseChartTypeForSlug('polar-column'),
          ),
        ),
      ),
    );

    final preview = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-polar-column')),
    );
    expect(
      preview.series
          .whereType<PolarColumnChartSeries>()
          .single
          .polarStyle
          .animationMode,
      PolarColumnAnimationMode.sweep,
    );
  });

  testWidgets('Scatter and Candlestick cards use representative compositions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: ChartTypePreview(
                chartType: showcaseChartTypeForSlug('scatter-charts'),
              ),
            ),
            Expanded(
              child: ChartTypePreview(
                chartType: showcaseChartTypeForSlug('candlestick-charts'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final scatter = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-scatter')),
    );
    final scatterSeries = scatter.series
        .whereType<ScatterChartSeries>()
        .toList();
    expect(scatterSeries.map((series) => series.name), [
      'Triathlon',
      'Volleyball',
      'Basketball',
    ]);
    expect(scatterSeries.map((series) => series.markerShape).toSet(), {
      SeriesMarkerShape.triangle,
      SeriesMarkerShape.square,
      SeriesMarkerShape.circle,
    });
    expect(scatterSeries.every((series) => series.points.length >= 9), isTrue);

    final candlestick = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('chart-type-preview-candlestick')),
    );
    final candles = candlestick.series
        .whereType<CandlestickChartSeries>()
        .single;
    expect(candles.candles, hasLength(16));
    expect(candles.candles.any((point) => point.close > point.open), isTrue);
    expect(candles.candles.any((point) => point.close < point.open), isTrue);
    expect(candles.animation.mode, CandlestickAnimationMode.reveal);
    final average = candlestick.series.whereType<LineChartSeries>().single;
    expect(average.points, hasLength(12));
    expect(
      average.pathAnimation.entranceMode,
      PathEntranceAnimationMode.reveal,
    );
  });
}
