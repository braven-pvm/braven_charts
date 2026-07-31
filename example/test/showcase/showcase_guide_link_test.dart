import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:braven_charts_example/showcase/widgets/showcase_guide_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves every showcase route with an authoritative guide mapping', () {
    const expectedGuideIds = <String, String>{
      'line-charts': 'line-area',
      'area-charts': 'line-area',
      'range-area-charts': 'range-area',
      'bar-charts': 'bar',
      'scatter-charts': 'api-overview',
      'candlestick-charts': 'candlestick',
      'pie-charts': 'pie',
      'donut-charts': 'donut',
      'concentric-donut': 'concentric-donut',
      'polar-column': 'polar-column',
      'radial-bar': 'radial-bar',
      'gauge-charts': 'gauge',
      'value-summary': 'value-summary',
      'mobile-interaction': 'mobile-interaction',
      'interaction': 'cartesian-navigator',
      'chart-grammar': 'chart-grammar',
      'chart-workbench': 'chart-workbench',
      'artifact-showcase': 'chart-artifacts',
    };

    for (final entry in expectedGuideIds.entries) {
      final guide = showcaseGuideForPage(entry.key);
      expect(guide, isNotNull, reason: 'Missing guide for ${entry.key}');
      expect(guide!.id, entry.value);
      expect(
        guide.url,
        startsWith('https://braven-pvm.github.io/braven_charts/guides/'),
      );
    }

    expect(showcaseGuideForPage('technical-indicators'), isNull);
  });

  testWidgets('mapped showcase page opens its hosted guide from the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ShowcaseHome(
          requestedPageOverride: 'chart-workbench',
          onOpenPublicUrl: openedUrls.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guideButton = find.byKey(const ValueKey('chart-page-guide-button'));
    expect(guideButton, findsOneWidget);

    await tester.tap(guideButton);
    await tester.pump();

    expect(openedUrls, [
      'https://braven-pvm.github.io/braven_charts/guides/chart-workbench/',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone chart-family surface opens the selected family guide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ShowcaseHome(
          requestedPageOverride: 'line-charts',
          onOpenPublicUrl: openedUrls.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guideButton = find.byKey(
      const ValueKey('mobile-showcase-guide-button'),
    );
    expect(guideButton, findsOneWidget);

    await tester.tap(guideButton);
    await tester.pump();

    expect(openedUrls, [
      'https://braven-pvm.github.io/braven_charts/guides/chart-families/line-area/',
    ]);
    expect(tester.takeException(), isNull);
  });
}
