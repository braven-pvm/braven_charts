// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

void main() {
  test(
    'clustered matrix retains order and source identity through portable surfaces',
    () async {
      final clustered = HeatmapMatrixClusterData(
        rowLabels: const ['Acquisition', 'Errors', 'Activation'],
        columnLabels: const ['Revenue', 'Latency', 'Conversion'],
        cells: _cells(const [
          [0.82, -0.31, 0.91],
          [-0.58, 0.94, -0.52],
          [0.76, -0.27, 0.88],
        ]),
      );
      final rowDendrogram = HeatmapDendrogramData(
        root: clustered.rowRoot!,
        sourceLabels: clustered.sourceRowLabels,
        axis: HeatmapDendrogramAxis.rows,
      );
      final columnDendrogram = HeatmapDendrogramData(
        root: clustered.columnRoot!,
        sourceLabels: clustered.sourceColumnLabels,
        axis: HeatmapDendrogramAxis.columns,
      );
      const dendrogramStyle = HeatmapDendrogramStyle(
        branchColor: Color(0xFF5B5AA6),
        branchWidth: 2.25,
        branchCap: StrokeCap.square,
        branchJoin: StrokeJoin.bevel,
        baselineColor: Color(0xFFB8B7D9),
        baselineWidth: 1.25,
        showLeafBaseline: false,
        tickColor: Color(0xFF7473A8),
        tickWidth: 1.5,
        tickLength: 7,
        showLeafTicks: true,
        elbowRadius: 8,
        showLeafMarkers: true,
        leafMarkerColor: Color(0xFF0284C7),
        leafMarkerRadius: 4,
        leafMarkerShape: HeatmapDendrogramMarkerShape.square,
        leafMarkerFill: HeatmapDendrogramMarkerFill.hollow,
        leafMarkerBorderColor: Color(0xFF0C4A6E),
        leafMarkerBorderWidth: 1.5,
        showMergeMarkers: true,
        mergeMarkerColor: Color(0xFFF97316),
        mergeMarkerRadius: 5,
        mergeMarkerShape: HeatmapDendrogramMarkerShape.diamond,
        mergeMarkerFill: HeatmapDendrogramMarkerFill.solid,
        mergeMarkerBorderColor: Color(0xFF7C2D12),
        mergeMarkerBorderWidth: 2,
        showLeafLabels: true,
        showMergeDistanceLabels: true,
        labelColor: Color(0xFF111827),
        labelBackgroundColor: Color(0xFFF8FAFC),
        labelDensity: HeatmapDendrogramLabelDensity.sparse,
        labelPlacement: HeatmapDendrogramLabelPlacement.after,
        maxLabelCharacters: 9,
        mergeDistanceFractionDigits: 3,
      );
      final series = HeatmapChartSeries(
        id: 'clustered-matrix',
        name: 'Clustered matrix',
        points: clustered.cells,
        colorScale: HeatmapColorScale.diverging(
          lowColor: Colors.indigo,
          midpointColor: Colors.white,
          highColor: Colors.orange,
          midpoint: 0,
          minimumValue: -1,
          maximumValue: 1,
        ),
        metadata: {
          ...clustered.metadata,
          ...rowDendrogram.metadata,
          ...columnDendrogram.metadata,
          ...dendrogramStyle.metadataFor(HeatmapDendrogramAxis.rows),
          ...dendrogramStyle.metadataFor(HeatmapDendrogramAxis.columns),
        },
      );

      final encoded = _success(ChartSeriesDocumentCodec.encode(series));
      final decoded =
          _success(ChartSeriesDocumentCodec.decode(encoded))
              as HeatmapChartSeries;
      expect(decoded.metadata?['heatmapClusterRowOrder'], clustered.rowOrder);
      expect(
        decoded.metadata?['heatmapClusterColumnHierarchy'],
        clustered.columnRoot!.toJson(),
      );
      expect(decoded.metadata?['heatmapDendrogramRow'], rowDendrogram.toJson());
      expect(
        decoded.metadata?['heatmapDendrogramColumn'],
        columnDendrogram.toJson(),
      );
      expect(
        HeatmapDendrogramStyle.fromJson(
          decoded.metadata?['heatmapDendrogramRowStyle']
              as Map<String, dynamic>,
        ),
        dendrogramStyle,
      );
      expect(
        decoded.metadata?['heatmapDendrogramColumnStyle'],
        dendrogramStyle.toJson(),
      );
      final activation = decoded.points.singleWhere(
        (cell) => cell.pointKey == 'cluster-cell-2-0',
      );
      expect(
        activation.metadata?['heatmapClusterSourceRowLabel'],
        'Activation',
      );
      expect(
        activation.metadata?['heatmapClusterSourceColumnLabel'],
        'Revenue',
      );

      final document = ChartDocument(
        documentId: 'cluster-integration',
        revision: 1,
        series: [encoded],
        xAxis: ChartAxisDocument(
          id: 'x',
          position: 'bottom',
          label: 'Metric',
          categories: clustered.columnLabels,
        ),
        axes: [
          ChartAxisDocument(
            id: 'y',
            position: 'left',
            label: 'Signal',
            categories: clustered.rowLabels,
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
      expect(table.longRows, hasLength(9));
      expect(
        table.longRows.first.metadata?.values['heatmapClusterSourceRowLabel']
            ?.toJson(),
        isNotNull,
      );

      final generated = _success(
        ChartDartSourceGenerator.generate(
          ChartDocumentSnapshot(document: document),
          options: const ChartDartSourceOptions(
            variableName: 'clusteredMatrixChart',
          ),
        ),
      );
      expect(generated.source, contains("'heatmapClusterRowOrder':"));
      expect(generated.source, contains("'heatmapDendrogramColumn':"));
      expect(generated.source, contains("'heatmapDendrogramRowStyle':"));
      expect(generated.source, contains("'branchCap': 'square'"));
      expect(generated.source, contains("'elbowRadius': 8.0"));
      expect(generated.source, contains("'segments':"));
      expect(generated.source, contains("'nodes':"));
      expect(generated.source, contains("'showMergeDistanceLabels': true"));
      expect(generated.source, contains("'labelDensity': 'sparse'"));
      expect(generated.source, contains("'leafMarkerShape': 'square'"));
      expect(generated.source, contains("'leafMarkerFill': 'hollow'"));
      expect(generated.source, contains("'leafMarkerBorderWidth': 1.5"));
      expect(generated.source, contains("'mergeMarkerShape': 'diamond'"));
      expect(generated.source, contains("'mergeMarkerBorderWidth': 2.0"));
      expect(generated.source, contains("'heatmapClusterSourceRowLabel':"));
      await expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'heatmap_cluster_generated_source',
      );
    },
  );
}

List<HeatmapDataPoint> _cells(List<List<double>> values) => [
  for (var row = 0; row < values.length; row++)
    for (var column = 0; column < values[row].length; column++)
      HeatmapDataPoint(
        x: column.toDouble(),
        y: row.toDouble(),
        value: values[row][column],
        pointKey: 'cluster-cell-$row-$column',
        label: 'Cell $row, $column',
      ),
];

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
