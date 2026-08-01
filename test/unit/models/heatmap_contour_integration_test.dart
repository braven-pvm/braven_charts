import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

void main() {
  test(
    'contour overlay retains provenance through artifact table and Dart source',
    () async {
      final density = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        yAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        bandwidthX: 1,
        bandwidthY: 1,
        observations: [
          HeatmapDensityObservation(x: 0, y: 0, pointKey: 'source-centre'),
        ],
      );
      final contours = HeatmapContourData.fromDensity(
        density,
        levels: const [0.5],
      );
      final path = contours.paths.single;
      final heatmap = HeatmapChartSeries(
        id: 'density-raster',
        points: density.cellsFor(),
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
        ),
      );
      final contour = LineChartSeries(
        id: 'density-contour',
        points: contours.chartPointsFor(path),
        color: Colors.deepOrange,
        metadata: {
          'densityContourLevel': path.level,
          'densityContourSourcePointKeys': path.sourcePointKeys,
        },
      );
      final encoded = [
        _success(ChartSeriesDocumentCodec.encode(heatmap)),
        _success(ChartSeriesDocumentCodec.encode(contour)),
      ];
      final document = ChartDocument(
        documentId: 'density-contour-integration',
        revision: 1,
        series: encoded,
        xAxis: ChartAxisDocument(
          id: 'x',
          position: 'bottom',
          categories: ['-2', '-1', '0', '1', '2'],
        ),
        axes: [
          ChartAxisDocument(
            id: 'y',
            position: 'left',
            categories: ['-2', '-1', '0', '1', '2'],
          ),
        ],
        theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)),
        interaction: _success(
          ChartInteractionDocumentCodec.encode(const InteractionConfig()),
        ),
      );

      final decodedContour =
          _success(ChartSeriesDocumentCodec.decode(encoded.last))
              as LineChartSeries;
      expect(
        decodedContour.points.first.metadata?['densityContourPathId'],
        path.id,
      );
      expect(
        decodedContour.points.first.metadata?['densityContourSourcePointKeys'],
        contains('source-centre'),
      );

      final table = ChartTableModel.fromDocument(
        document,
        options: const ChartTableOptions(
          rowLayout: ChartTableRowLayout.long,
          includeMetadata: true,
        ),
      );
      expect(
        table.longRows.any(
          (row) =>
              row.metadata?.values['densityContourPathId']?.toJson() == path.id,
        ),
        isTrue,
      );

      final generated = _success(
        ChartDartSourceGenerator.generate(
          ChartDocumentSnapshot(document: document),
          options: const ChartDartSourceOptions(
            variableName: 'densityContourChart',
          ),
        ),
      );
      expect(generated.source, contains('HeatmapChartSeries('));
      expect(generated.source, contains('LineChartSeries('));
      expect(
        generated.source,
        contains("'densityContourPathId': '${path.id}'"),
      );
      await expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'heatmap_contour_generated_source',
      );
    },
  );
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
