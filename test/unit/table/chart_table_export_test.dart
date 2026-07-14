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
      export.csv,
      '#,Sample,"Power, average",Note\r\n'
      '1,7,241.44,"Hard ""finish""\ninterval"',
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
}
