import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/gallery_page.dart';
import 'package:braven_charts_example/showcase/widgets/bar_gallery_cards.dart';
import 'package:braven_charts_example/showcase/widgets/donut_gallery_cards.dart';
import 'package:braven_charts_example/showcase/widgets/gallery_flagships.dart';
import 'package:braven_charts_example/showcase/widgets/pie_gallery_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flagship panels render independently for package media', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(552 * pixelRatio, 444 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PerformanceIntelligenceGalleryHero(
            panel: PerformanceIntelligenceHeroPanel.sessionProfile,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Training load and response'), findsOneWidget);
    expect(find.text('Adaptive power-duration model'), findsNothing);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PerformanceIntelligenceGalleryHero(
            panel: PerformanceIntelligenceHeroPanel.powerDuration,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Training load and response'), findsNothing);
    expect(find.text('Adaptive power-duration model'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery Bar card carries targets and uncertainty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 620, child: BarTargetsGalleryCard()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final actual = chart.series.whereType<BarChartSeries>().last;
    expect(actual.targetValues, hasLength(actual.points.length));
    expect(actual.errorLowerValues, hasLength(actual.points.length));
    expect(actual.errorUpperValues, hasLength(actual.points.length));
    expect(actual.errorBarStyle.width, 1.75);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gallery leads with chart families and mounts flagship analysis',
    (tester) async {
      final pixelRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: GalleryPage()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Seven chart guides, one native renderer'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chart-type-card-line')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chart-type-card-pie')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chart-type-card-donut')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chart-type-card-concentric-donut')),
        findsOneWidget,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('A workhorse profile and a deeper analytical model'),
        findsOneWidget,
      );
      expect(find.text('Training load and response'), findsOneWidget);
      expect(find.text('Adaptive power-duration model'), findsOneWidget);
      expect(find.text('Line + area'), findsOneWidget);
      expect(find.text('Baseline fill'), findsOneWidget);
      expect(
        find.text('Hover to compare both signals · drag to pan'),
        findsOneWidget,
      );
      final hero = find.byType(PerformanceIntelligenceGalleryHero);
      final flagshipCharts = tester
          .widgetList<BravenChartPlus>(
            find.descendant(of: hero, matching: find.byType(BravenChartPlus)),
          )
          .toList();
      expect(flagshipCharts, hasLength(2));
      expect(flagshipCharts.first.series, hasLength(2));
      expect(flagshipCharts.first.annotations, hasLength(5));
      expect(flagshipCharts.first.showXScrollbar, isFalse);
      expect(flagshipCharts.last.series, hasLength(6));
      expect(flagshipCharts.last.annotations, hasLength(5));
      expect(flagshipCharts.last.showXScrollbar, isTrue);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1900));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Live sensor stream'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.byType(BravenChartPlus), findsAtLeastNWidgets(1));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -4300));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('The building blocks'), findsOneWidget);
      expect(_gridCount(tester, 'gallery-building-blocks-curated'), 7);
    },
  );

  testWidgets('gallery separates curated highlights from the full catalog', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1600 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GalleryPage()));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('gallery-mode-control')), findsOneWidget);
    expect(
      find.text('Focused tour of the representative compositions'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gallery-advanced-curated')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gallery-building-blocks-curated')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-advanced-curated'), 8);
    expect(_gridCount(tester, 'gallery-building-blocks-curated'), 7);
    final galleryScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('Thirteen comparison strategies, one Bar API'),
      800,
      scrollable: galleryScrollable,
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('gallery-bar-compositions')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-bar-compositions'), 13);
    const barGrid = 'gallery-bar-compositions';
    expect(_gridContains<BarTargetsGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarCapacityGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarWaterfallGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarRangeGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarHorizontalGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarNormalizedGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarOverlayGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarRodsGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarGradientGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarSignedGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarOffsetGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarAxesGalleryCard>(tester, barGrid), isTrue);
    expect(_gridContains<BarStackedGalleryCard>(tester, barGrid), isTrue);

    await tester.scrollUntilVisible(
      find.text('One whole, five presentation strategies'),
      800,
      scrollable: galleryScrollable,
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('gallery-pie-compositions')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-pie-compositions'), 5);
    expect(find.byType(SimpleRevenueGalleryCard), findsOneWidget);
    expect(find.byType(RevenueContributionGalleryCard), findsOneWidget);
    expect(find.byType(ReleaseEffortGalleryCard), findsOneWidget);
    expect(find.byType(SupportMixGalleryCard), findsOneWidget);
    expect(find.byType(PortfolioAllocationGalleryCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Three measures, three radial encodings'),
      500,
      scrollable: galleryScrollable,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('gallery-donut-compositions')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-donut-compositions'), 3);
    expect(find.byType(RevenueRingGalleryCard), findsOneWidget);
    expect(find.byType(DeliveryProgressGalleryCard), findsOneWidget);
    expect(find.byType(CampaignReachGalleryCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Independent totals, one shared radial pane'),
      500,
      scrollable: galleryScrollable,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('gallery-concentric-donut-compositions')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-concentric-donut-compositions'), 3);
    expect(find.byType(ConcentricMixGalleryCard), findsOneWidget);
    expect(find.byType(ConcentricHealthGalleryCard), findsOneWidget);
    expect(find.byType(ConcentricPortfolioGalleryCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('gallery-mode-control')),
      -800,
      scrollable: galleryScrollable,
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Full catalog'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('Every maintained example in the showcase catalog'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('gallery-advanced-full')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gallery-building-blocks-full')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-advanced-full'), 11);
    expect(_gridCount(tester, 'gallery-building-blocks-full'), 17);
  });
  testWidgets('donut media panel reuses three product-shaped compositions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonutGalleryMediaPanel())),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BravenChartPlus), findsNWidgets(3));
    expect(find.text('Subscription MRR'), findsOneWidget);
    expect(find.text('Release readiness'), findsOneWidget);
    expect(find.text('Channel efficiency'), findsOneWidget);
    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList(growable: false);
    expect(
      charts.every(
        (chart) => chart.series.every((series) => series is DonutChartSeries),
      ),
      isTrue,
    );
    expect(charts.map((chart) => chart.series.length), [1, 1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('concentric media panel presents three distinct compositions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConcentricDonutGalleryMediaPanel()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BravenChartPlus), findsNWidgets(3));
    expect(find.text('Revenue mix over time'), findsOneWidget);
    expect(find.text('Service-level health'), findsOneWidget);
    expect(find.text('Portfolio allocation'), findsOneWidget);
    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList(growable: false);
    expect(charts.map((chart) => chart.series.length), [3, 3, 3]);
    expect(
      charts.first.concentricDonutConfig.ringWeights,
      containsPair('gallery-concentric-current', 1.2),
    );
    final health = charts[1].series.first as DonutChartSeries;
    expect(health.donutStyle.sweepAngleDegrees, 270);
    final portfolioCard = tester.widget<Card>(
      find.ancestor(
        of: find.text('Portfolio allocation'),
        matching: find.byType(Card),
      ),
    );
    expect(portfolioCard.color, const Color(0xFF101827));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark radial charts use dark card chrome and compact labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 440, child: DeliveryProgressGalleryCard()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, const Color(0xFF111827));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.single as DonutChartSeries;
    expect(series.dataLabels.calloutStyle?.textStyle.fontSize, 10);
    expect(series.dataLabels.minimumShare, 0.09);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark Pie themes also carry through the card chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 440, child: ReleaseEffortGalleryCard()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, const Color(0xFF111827));
    expect(tester.takeException(), isNull);
  });
}

int? _gridCount(WidgetTester tester, String key) {
  return tester
      .widget<SliverGrid>(find.byKey(ValueKey(key)))
      .delegate
      .estimatedChildCount;
}

bool _gridContains<T extends Widget>(WidgetTester tester, String key) {
  final delegate =
      tester.widget<SliverGrid>(find.byKey(ValueKey(key))).delegate
          as SliverChildListDelegate;
  return delegate.children.whereType<T>().isNotEmpty;
}
