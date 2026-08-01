import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

void main() {
  test(
    'density raster retains provenance through artifact table and Dart source',
    () async {
      final density = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(
          minimum: 0,
          maximum: 2,
          cellCount: 2,
          labels: const ['Left', 'Right'],
        ),
        yAxis: HeatmapDensityAxis(
          minimum: 0,
          maximum: 2,
          cellCount: 2,
          labels: const ['Bottom', 'Top'],
        ),
        bandwidthX: 0.8,
        bandwidthY: 0.8,
        observations: [
          HeatmapDensityObservation(x: 0.5, y: 0.5, pointKey: 'sample-a'),
          HeatmapDensityObservation(x: 0.8, y: 0.6, pointKey: 'sample-b'),
        ],
      );
      final series = HeatmapChartSeries(
        id: 'density-raster',
        name: 'Density raster',
        points: density.cellsFor(),
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.purple],
          label: 'Relative density',
        ),
      );

      final encoded = _success(ChartSeriesDocumentCodec.encode(series));
      final decoded =
          _success(ChartSeriesDocumentCodec.decode(encoded))
              as HeatmapChartSeries;
      expect(decoded.points, hasLength(4));
      expect(decoded.points.first.metadata?['densityKernel'], 'gaussian');
      expect(decoded.points.first.metadata?['densitySourcePointKeys'], [
        'sample-a',
        'sample-b',
      ]);

      final document = ChartDocument(
        documentId: 'density-integration',
        revision: 1,
        series: [encoded],
        xAxis: ChartAxisDocument(
          id: 'x',
          position: 'bottom',
          label: 'X sample',
          categories: const ['Left', 'Right'],
        ),
        axes: [
          ChartAxisDocument(
            id: 'y',
            position: 'left',
            label: 'Y sample',
            categories: const ['Bottom', 'Top'],
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
      expect(
        table.longRows.first.metadata?.values['densityKernel']?.toJson(),
        'gaussian',
      );
      expect(
        table.longRows.first.metadata?.values['densitySourcePointKeys']
            ?.toJson(),
        ['sample-a', 'sample-b'],
      );

      final generated = _success(
        ChartDartSourceGenerator.generate(
          ChartDocumentSnapshot(document: document),
          options: const ChartDartSourceOptions(variableName: 'densityChart'),
        ),
      );
      expect(generated.source, contains("'densityKernel': 'gaussian'"));
      expect(
        generated.source,
        contains("'densitySourcePointKeys': ['sample-a', 'sample-b']"),
      );
      await expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'heatmap_density_generated_source',
      );
    },
  );
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
