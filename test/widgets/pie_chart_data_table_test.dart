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

  testWidgets('shows and sorts the variable-radius metric', (tester) async {
    final model = _pieModel(variableRadius: true);
    await tester.pumpWidget(_host(ChartDataTable(model: model)));

    expect(find.text('Total area (km²)'), findsOneWidget);
    expect(find.text('120.00'), findsOneWidget);

    await tester.tap(find.text('Total area (km²)'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Hardware')).dy,
      lessThan(tester.getTopLeft(find.text('Subscriptions')).dy),
    );
  });

  testWidgets('shows ring identity and activates exact Concentric rows', (
    tester,
  ) async {
    final model = _concentricModel();
    List<ChartPointRef>? activated;
    ChartTableRowExport? copiedRow;
    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          onRowActivated: (points) => activated = points,
          onCopyRow: (row) => copiedRow = row,
        ),
      ),
    );

    expect(find.text('Ring'), findsOneWidget);
    expect(find.text('Current period'), findsNWidgets(2));
    expect(find.text('Previous period'), findsNWidgets(2));
    expect(find.text('Subscriptions'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('previous:0')));
    await tester.pump();
    expect(activated, [
      const ChartPointRef(seriesId: 'previous', pointIndex: 0),
    ]);

    await tester.tap(find.byTooltip('Copy Subscriptions row').last);
    await tester.pump();
    expect(copiedRow?.displayValues, [
      '3',
      'Previous period',
      'previous',
      'Subscriptions',
      '50.00',
      '25.00%',
    ]);
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 720, height: 360, child: child)),
  ),
);

ChartTableModel _pieModel({bool variableRadius = false}) {
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
                  radiusValues: variableRadius
                      ? const {
                          'Subscriptions': 120,
                          'Services': 100,
                          'Hardware': 80,
                        }
                      : const {},
                  sliceRadiusConfig: variableRadius
                      ? const PieSliceRadiusConfig(
                          label: 'Total area',
                          unit: 'km²',
                        )
                      : null,
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

ChartTableModel _concentricModel() {
  final rings = [
    DonutChartSeries.fromMap(
      id: 'current',
      name: 'Current period',
      unit: 'USD',
      values: const {'Subscriptions': 60, 'Services': 40},
    ),
    DonutChartSeries.fromMap(
      id: 'previous',
      name: 'Previous period',
      unit: 'USD',
      values: const {'Subscriptions': 50, 'Services': 150},
    ),
  ];
  final series = [
    for (final ring in rings)
      (ChartSeriesDocumentCodec.encode(ring)
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value,
  ];
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'concentric-table-widget',
      revision: 1,
      series: series,
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
