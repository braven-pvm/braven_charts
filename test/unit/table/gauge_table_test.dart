import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects Gauge as one operational measurement row and raw CSV', () {
    final series = GaugeChartSeries.solid(
      id: 'cpu',
      metric: 'CPU utilization',
      value: 72,
      minimum: 20,
      maximum: 100,
      unit: '%',
      target: const GaugeTarget(value: 70, label: 'SLO'),
      zones: const [
        GaugeZone(from: 20, to: 60, status: 'Healthy'),
        GaugeZone(from: 60, to: 85, status: 'Elevated'),
        GaugeZone(from: 85, to: 100, status: 'Critical'),
      ],
    );
    final document = ChartDocument(
      documentId: 'gauge-table',
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
    expect(model.projectionKind, ChartTableProjectionKind.gauge);
    expect(model.gaugeRows, hasLength(1));
    final row = model.gaugeRows.single;
    expect(row.metric, 'CPU utilization');
    expect(row.valueRaw, 72);
    expect(row.minimumRaw, 20);
    expect(row.maximumRaw, 100);
    expect(row.progressRaw, 0.65);
    expect(row.progressDisplay, '65.00%');
    expect(row.targetRaw, 70);
    expect(row.status, 'Elevated');
    expect(ChartTableExporter.headers(model), [
      '#',
      'Metric',
      'Value (%)',
      'Minimum',
      'Maximum',
      'Progress',
      'Target',
      'Status',
    ]);

    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      gaugeRows: model.gaugeRows,
    );
    expect(
      export.csv,
      contains('CPU utilization,72.0,20.0,100.0,0.65,70.0,Elevated'),
    );
    expect(export.tabSeparatedText, contains('65.00%'));
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
