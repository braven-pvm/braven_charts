import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sorts, activates, copies, and exports native pie rows', (
    tester,
  ) async {
    final model = _pieModel();
    ChartTableRowExport? copiedRow;
    ChartTableCsvExport? copiedDataset;
    ChartTableCsvExport? exportedDataset;
    List<ChartPointRef>? activated;

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          onCopyRow: (row) => copiedRow = row,
          onCopyDataset: (export) => copiedDataset = export,
          onExportCsv: (export) => exportedDataset = export,
          onRowActivated: (points) => activated = points,
        ),
      ),
    );

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Value (USD)'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-table-pie-color-0')),
      findsOneWidget,
    );

    await tester.tap(find.text('Value (USD)'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Hardware')).dy,
      lessThan(tester.getTopLeft(find.text('Subscriptions')).dy),
    );

    await tester.tap(find.byTooltip('Copy Hardware row'));
    await tester.pump();
    expect(copiedRow?.displayValues, ['1', 'Hardware', '27.00', '27.00%']);

    await tester.tap(find.text('Copy data'));
    await tester.pump();
    expect(copiedDataset?.rows.first.displayValues[1], 'Hardware');

    await tester.tap(find.text('Export CSV'));
    await tester.pump();
    expect(exportedDataset?.csv, contains('Hardware,27.0,0.27'));

    await tester.tap(find.text('Hardware'));
    await tester.pump();
    expect(activated, [
      const ChartPointRef(seriesId: 'revenue', pointIndex: 2),
    ]);
  });

  testWidgets('directs oversized pie-table copies to CSV export', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(ChartDataTable(model: _pieModel(), clipboardRowLimit: 2)),
    );

    await tester.tap(find.text('Copy data'));
    await tester.pump();

    expect(
      find.text(
        'This table has 3 rows and is too large to copy. Use Export CSV instead.',
      ),
      findsOneWidget,
    );
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 720, height: 360, child: child)),
  ),
);

ChartTableModel _pieModel() {
  final series =
      (ChartSeriesDocumentCodec.encode(
                PieChartSeries.fromMap(
                  id: 'revenue',
                  unit: 'USD',
                  values: const {
                    'Subscriptions': 42,
                    'Services': 31,
                    'Hardware': 27,
                  },
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'pie-table-widget',
      revision: 1,
      series: [series],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}
