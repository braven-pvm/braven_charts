import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

void main() {
  test(
    '2D histogram bins retain source identity through artifact table and Dart',
    () async {
      final histogram = HeatmapHistogramData(
        xAxis: HeatmapHistogramAxis(
          boundaries: const [0, 5, 10],
          labels: const ['Low X', 'High X'],
        ),
        yAxis: HeatmapHistogramAxis(
          boundaries: const [0, 50, 100],
          labels: const ['Low Y', 'High Y'],
        ),
        observations: [
          HeatmapHistogramObservation(x: 2, y: 20, pointKey: 'review-a'),
          HeatmapHistogramObservation(x: 3, y: 25, pointKey: 'review-b'),
          HeatmapHistogramObservation(x: 8, y: 82, pointKey: 'review-c'),
        ],
      );
      final series = HeatmapChartSeries(
        id: 'review-density',
        name: 'Review density',
        points: histogram.cellsFor(
          emptyBinMode: HeatmapHistogramEmptyBinMode.missing,
        ),
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
          label: 'Observations',
        ),
      );

      final encoded = _success(ChartSeriesDocumentCodec.encode(series));
      final decoded = _success(ChartSeriesDocumentCodec.decode(encoded));
      final decodedSeries = decoded as HeatmapChartSeries;
      expect(decodedSeries.points, hasLength(4));
      expect(decodedSeries.points.first.metadata?['histogramSourcePointKeys'], [
        'review-a',
        'review-b',
      ]);
      expect(decodedSeries.points.first.metadata?['histogramCount'], 2);

      final document = ChartDocument(
        documentId: 'histogram-integration',
        revision: 1,
        series: [encoded],
        xAxis: ChartAxisDocument(
          id: 'x',
          position: 'bottom',
          label: 'X bin',
          categories: ['Low X', 'High X'],
        ),
        axes: [
          ChartAxisDocument(
            id: 'y',
            position: 'left',
            label: 'Y bin',
            categories: ['Low Y', 'High Y'],
          ),
        ],
        theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)),
        interaction: _success(
          ChartInteractionDocumentCodec.encode(const InteractionConfig()),
        ),
      );
      final table = ChartTableModel.fromDocument(
        document,
        options: const ChartTableOptions(
          rowLayout: ChartTableRowLayout.long,
          includeMetadata: true,
        ),
      );
      expect(table.longRows, hasLength(4));
      expect(
        table.longRows.first.metadata?.values['histogramCount']?.toJson(),
        2,
      );
      expect(
        table.longRows.first.metadata?.values['histogramSourcePointKeys']
            ?.toJson(),
        ['review-a', 'review-b'],
      );

      final generated = _success(
        ChartDartSourceGenerator.generate(
          ChartDocumentSnapshot(document: document),
          options: const ChartDartSourceOptions(
            variableName: 'reviewDensityChart',
          ),
        ),
      );
      expect(generated.source, contains('HeatmapChartSeries('));
      expect(generated.source, contains("'histogramCount': 2"));
      expect(
        generated.source,
        contains("'histogramSourcePointKeys': ['review-a', 'review-b']"),
      );
      await expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'heatmap_histogram_generated_source',
      );
    },
  );
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
