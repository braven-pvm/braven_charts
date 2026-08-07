import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/mobile_apps_showcase_page.dart';
import 'package:braven_charts_example/showcase/pages/mobile_showcase_page.dart';
import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop route presents six live phone-native experiences', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'mobile-apps'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MobileAppsShowcasePage), findsOneWidget);
    expect(find.text('Charts that belong in your hand'), findsOneWidget);
    expect(find.text('Stride'), findsOneWidget);
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.text('Touchline'), findsOneWidget);
    expect(find.text('Summit'), findsOneWidget);
    expect(find.text('Loop'), findsOneWidget);
    expect(find.text('Citypulse'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsNWidgets(6));
    expect(
      find.byKey(const ValueKey('mobile-app-endurance-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-app-recovery-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-app-match-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-app-training-range-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-app-habit-heatmap-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-app-pickup-hexbin-chart')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile route stacks device experiences without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'mobile-apps'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MobileAppsShowcasePage), findsOneWidget);
    expect(find.byType(MobileShowcasePage), findsNothing);
    final gallery = find.byKey(const ValueKey('mobile-app-device-gallery'));
    expect(gallery, findsOneWidget);
    expect(tester.getRect(gallery).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(gallery).right, lessThanOrEqualTo(390));
    final moreGallery = find.byKey(
      const ValueKey('mobile-app-device-gallery-more'),
    );
    expect(moreGallery, findsOneWidget);
    expect(tester.getRect(moreGallery).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(moreGallery).right, lessThanOrEqualTo(390));
    expect(find.byType(BravenChartPlus), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone browser links to the finished mobile app gallery', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(MobileShowcasePage), findsOneWidget);
    final link = find.byKey(const ValueKey('open-mobile-apps-showcase'));
    expect(link, findsOneWidget);
    expect(tester.getSize(link).height, greaterThanOrEqualTo(48));

    await tester.tap(link);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MobileAppsShowcasePage), findsOneWidget);
    expect(find.text('Charts that belong in your hand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
