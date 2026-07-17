import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/gallery_page.dart';
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
            panel: PerformanceIntelligenceHeroPanel.thresholdExposure,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Threshold exposure by interval'), findsOneWidget);
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

    expect(find.text('Threshold exposure by interval'), findsNothing);
    expect(find.text('Adaptive power-duration model'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery leads with flagship analysis and mounts live data', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GalleryPage()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Two analytical viewpoints, one rendering engine'),
      findsOneWidget,
    );
    expect(find.text('Threshold exposure by interval'), findsOneWidget);
    expect(find.text('Adaptive power-duration model'), findsOneWidget);
    expect(find.text('Mixed series'), findsOneWidget);
    expect(find.text('Baseline fill'), findsOneWidget);
    expect(
      find.text('Hover for exact interval values · wheel to zoom'),
      findsOneWidget,
    );
    final flagshipCharts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .take(2)
        .toList();
    expect(flagshipCharts, hasLength(2));
    expect(flagshipCharts.first.series, hasLength(2));
    expect(flagshipCharts.first.annotations, hasLength(7));
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
  });

  testWidgets('gallery separates curated highlights from the full catalog', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1600 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GalleryPage()));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('gallery-mode-control')), findsOneWidget);
    expect(find.text('22 representative compositions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gallery-advanced-curated')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gallery-building-blocks-curated')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-advanced-curated'), 8);
    expect(_gridCount(tester, 'gallery-building-blocks-curated'), 8);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -8000));
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

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 8000));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Full catalog'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('35 examples across the complete catalog'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('gallery-advanced-full')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gallery-building-blocks-full')),
      findsOneWidget,
    );
    expect(_gridCount(tester, 'gallery-advanced-full'), 11);
    expect(_gridCount(tester, 'gallery-building-blocks-full'), 18);
  });
}

int? _gridCount(WidgetTester tester, String key) {
  return tester
      .widget<SliverGrid>(find.byKey(ValueKey(key)))
      .delegate
      .estimatedChildCount;
}
