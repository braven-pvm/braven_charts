import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_data_table_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactDataTableLabPage());

  testWidgets('captures one document into a transposed exact-X table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('160 table rows'), findsOneWidget);
    expect(find.text('Sample'), findsOneWidget);
    expect(find.text('Power (W)'), findsOneWidget);
    expect(find.text('Heart rate (bpm)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-table-header-index')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-table-row-index-0')),
      findsOneWidget,
    );
    expect(find.byTooltip('Copy row 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy row 1'));
    await tester.pumpAndSettle();
    expect(find.text('Copied row 1 to the clipboard.'), findsOneWidget);

    await tester.tap(find.text('Export CSV'));
    await tester.pumpAndSettle();
    expect(
      find.text('Copied 160 raw-value CSV rows to the clipboard.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hide heart rate'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Visible only'));
    await tester.pump();
    expect(find.text('160 table rows'), findsOneWidget);
    expect(find.text('Heart rate (bpm)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves table sort state across display-mode changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Sample'));
    await tester.pump();
    expect(find.bySemanticsLabel('Sample, ascending'), findsOneWidget);

    await tester.tap(find.text('Chart'));
    await tester.pump();
    await tester.tap(find.text('Data'));
    await tester.pump();

    expect(find.bySemanticsLabel('Sample, ascending'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('offers separate chart and data modes on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump();

    expect(find.text('Split'), findsNothing);
    expect(find.byTooltip('Recapture chart document'), findsOneWidget);
    await tester.tap(find.text('Data'));
    await tester.pump();

    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.textContaining('All series · 160 rows'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
