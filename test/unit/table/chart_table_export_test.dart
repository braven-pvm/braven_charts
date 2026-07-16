import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV uses raw values and RFC-style escaping', () {
    final row = ChartTableRowExport(
      rowId: 'row-1',
      headers: const ['#', 'Sample', 'Power, average', 'Note'],
      rawValues: const [1, 7, 241.44, 'Hard "finish"\ninterval'],
      displayValues: const ['1', '00:07', '241 W', 'Hard finish'],
      references: const [
        ChartTablePointReference(seriesId: 'power', pointIndex: 0),
      ],
    );

    final export = ChartTableCsvExport(headers: row.headers, rows: [row]);

    expect(row.tabSeparatedText, '1\t00:07\t241 W\tHard finish');
    expect(
      export.tabSeparatedText,
      '#\tSample\tPower, average\tNote\r\n'
      '1\t00:07\t241 W\tHard finish',
    );
    expect(
      export.csv,
      '#,Sample,"Power, average",Note\r\n'
      '1,7,241.44,"Hard ""finish""\ninterval"',
    );
  });

  test('TSV flattens tabs and line breaks inside displayed cells', () {
    final row = ChartTableRowExport(
      rowId: 'row-1',
      headers: const ['Series\tname', 'Note'],
      rawValues: const ['Power', 'First\nSecond'],
      displayValues: const ['Power\toutput', 'First\nSecond'],
      references: const [],
    );
    final export = ChartTableCsvExport(headers: row.headers, rows: [row]);

    expect(
      export.tabSeparatedText,
      'Series name\tNote\r\nPower output\tFirst Second',
    );
  });

  test('rejects row values that do not align with headers', () {
    expect(
      () => ChartTableRowExport(
        rowId: 'broken',
        headers: const ['X', 'Y'],
        rawValues: const [1],
        displayValues: const ['1', '2'],
        references: const [],
      ),
      throwsArgumentError,
    );
  });

  test('pie CSV and clipboard exports use category, value, and share', () {
    final model = _pieModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      pieRows: model.pieRows,
    );

    expect(export.headers, ['#', 'Category', 'Value (USD)', 'Share']);
    expect(
      export.tabSeparatedText,
      '#\tCategory\tValue (USD)\tShare\r\n'
      '1\tSubscriptions\t42.00\t42.00%\r\n'
      '2\tServices\t58.00\t58.00%',
    );
    expect(
      export.csv,
      '#,Category,Value (USD),Share\r\n'
      '1,Subscriptions,42.0,0.42\r\n'
      '2,Services,58.0,0.58',
    );
    expect(export.rows.first.references.single.pointIndex, 0);
  });
}

ChartTableModel _pieModel() {
  final series =
      (ChartSeriesDocumentCodec.encode(
                PieChartSeries.fromMap(
                  id: 'revenue',
                  unit: 'USD',
                  values: const {'Subscriptions': 42, 'Services': 58},
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'pie-export',
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
