import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  group('WebTestUtils', () {
    test('has all required viewport sizes', () {
      expect(WebTestUtils.webViewports.length, 8);
      expect(WebTestUtils.webViewports['mobile'], const Size(375, 667));
      expect(WebTestUtils.webViewports['desktop'], const Size(1366, 768));
      expect(WebTestUtils.webViewports['ultrawide'], const Size(3440, 1440));
    });

    testWidgets('createWebTestApp creates valid widget tree', (tester) async {
      final testWidget = WebTestUtils.createWebTestApp(
        child: const Text('Test Chart'),
      );

      await tester.pumpWidget(testWidget);
      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('createChartContainer creates sized container', (tester) async {
      final container = WebTestUtils.createChartContainer(
        chart: const Placeholder(),
        size: const Size(1920, 1080),
      );

      await tester.pumpWidget(MaterialApp(home: container));
      
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 1920);
      expect(sizedBox.height, 1080);
    });

    testWidgets('waitForLoadingComplete handles no loading state', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('No loading')),
      ));

      // Should complete immediately since no CircularProgressIndicator
      await WebTestUtils.waitForLoadingComplete(tester);
      expect(find.text('No loading'), findsOneWidget);
    });

    test('WebPerformanceMetrics validates thresholds correctly', () {
      final goodMetrics = const WebPerformanceMetrics(
        renderTime: Duration(milliseconds: 30),
        interactionTime: Duration(milliseconds: 10),
        frameCount: 60,
      );

      expect(goodMetrics.meetsRenderThreshold(), isTrue);
      expect(goodMetrics.meetsInteractionThreshold(), isTrue);

      final badMetrics = const WebPerformanceMetrics(
        renderTime: Duration(milliseconds: 100),
        interactionTime: Duration(milliseconds: 50),
        frameCount: 30,
      );

      expect(badMetrics.meetsRenderThreshold(), isFalse);
      expect(badMetrics.meetsInteractionThreshold(), isFalse);
    });
  });
}
