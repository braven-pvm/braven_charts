import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects Radial Bar as native category/value rows and CSV', () {
    final series = RadialBarChartSeries.fromMap(
      id: 'delivery',
      name: 'Delivery',
      unit: '%',
      values: const {'Discover': 72, 'Build': 54, 'Launch': 31},
    );
    final document = ChartDocument(
      documentId: 'radial-bar-table',
      revision: 1,
      series: [_success(ChartSeriesDocumentCodec.encode(series)).value],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: [ChartAxisDocument(id: 'y', position: 'left')],
      theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
      interaction: _success(
        ChartInteractionDocumentCodec.encode(const InteractionConfig()),
      ).value,
    );

    final model = ChartTableModel.fromDocument(document);
    expect(model.projectionKind, ChartTableProjectionKind.polar);
    expect(model.xColumnLabel, 'Category');
    expect(model.polarRows, hasLength(3));
    expect(model.polarRows.first.category, 'Discover');
    expect(model.polarRows.first.valueDisplay, '72.00');
    expect(model.longRows.first.xDisplay, 'Discover');
    expect(ChartTableExporter.headers(model), [
      '#',
      'Category',
      'Series',
      'Value (%)',
    ]);
    expect(
      ChartTableExporter.csvForDisplayedRows(
        model,
        polarRows: model.polarRows,
      ).csv,
      allOf(contains('Discover'), contains('72.0')),
    );
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
