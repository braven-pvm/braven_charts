import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactShowcasePage());

  testWidgets('presents the complete artifact workflow on one page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    expect(find.text('Chart Artifacts'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('Generate random chart'), findsOneWidget);
    expect(find.text('Capture current chart'), findsOneWidget);
    expect(find.text('Captured charts'), findsOneWidget);
    expect(find.text('No captured charts yet'), findsOneWidget);
    expect(find.text('3. Restore or inspect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures, inspects, and restores a portable chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);

    expect(find.byKey(const ValueKey('artifact-thumbnail-1')), findsOneWidget);
    expect(find.text('1 saved in this demo session'), findsOneWidget);

    await tester.tap(find.text('View data'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('captured-data-showcase-capture-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Restore chart'));
    await tester.pump();

    expect(find.text('RESTORED FROM CAPTURE 1'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);

    await tester.tap(find.text('Raw JSON'));
    await tester.pump();
    expect(
      find.textContaining('"artifactType": "braven.chartArtifact"'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('regenerates a different live chart', (tester) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    expect(find.byKey(const ValueKey('generated-chart-1')), findsOneWidget);

    await tester.tap(find.text('Generate random chart'));
    await tester.pump();
    expect(find.byKey(const ValueKey('generated-chart-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the single page usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Generate random chart'), findsOneWidget);
    expect(find.byTooltip('Capture current chart'), findsOneWidget);
    expect(find.text('Chart Artifacts'), findsOneWidget);
    expect(find.text('1. Generate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
