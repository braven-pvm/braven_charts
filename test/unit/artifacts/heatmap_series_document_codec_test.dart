import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips Heatmap cells, missing state, scale, and appearance', () {
    final source = HeatmapChartSeries(
      id: 'temperature',
      name: 'Temperature',
      unit: '°C',
      points: [
        HeatmapDataPoint(
          x: 0,
          y: 0,
          value: 0,
          pointKey: 'mon-00',
          label: 'Monday midnight',
          metadata: const {'source': 'sensor-a'},
        ),
        HeatmapDataPoint.missing(
          x: 1,
          y: 0,
          pointKey: 'mon-01',
          label: 'Missing sample',
        ),
        HeatmapDataPoint(x: 2, y: 0, value: 18.5, pointKey: 'mon-02'),
      ],
      colorScale: HeatmapColorScale.diverging(
        lowColor: const Color(0xFF2563EB),
        midpointColor: const Color(0xFFF8FAFC),
        highColor: const Color(0xFFDC2626),
        midpoint: 10,
        minimumValue: 0,
        maximumValue: 20,
        reverse: true,
        clamp: false,
        missingColor: const Color(0xFFE2E8F0),
        label: 'Temperature',
        unit: '°C',
      ),
      cellWidth: .8,
      cellHeight: .9,
      gapFraction: .12,
      borderColor: const Color(0xFF334155),
      borderWidth: 1.5,
      cornerRadius: 3,
      showInLegend: false,
      showTrackingAxisLabel: false,
      showCellLabels: true,
      cellLabelColor: const Color(0xFF0F172A),
      cellLabelFontSize: 12,
      animation: const HeatmapAnimationStyle(
        entranceMode: HeatmapEntranceMode.scale,
        entranceOrder: HeatmapEntranceOrder.radial,
        entranceScale: 0.7,
        staggerFraction: 0.8,
        animateDataUpdates: false,
        entranceTiming: PathAnimationTiming(
          delay: Duration(milliseconds: 20),
          duration: Duration(milliseconds: 480),
        ),
        dataUpdateTiming: PathAnimationTiming(
          duration: Duration(milliseconds: 260),
        ),
      ),
    );

    for (final storage in ChartDataStorage.values) {
      final encoded =
          ChartSeriesDocumentCodec.encode(source, dataStorage: storage)
              as ChartArtifactSuccess<ChartSeriesDocument>;
      final portable = ChartSeriesDocument.fromJson(encoded.value.toJson());
      final decoded =
          ChartSeriesDocumentCodec.decode(portable)
              as ChartArtifactSuccess<ChartSeries>;

      expect(portable.type, 'heatmap');
      expect(
        portable.requiredCapabilities,
        containsAll({
          'series.heatmap',
          'series.heatmap.cell.v1',
          'series.heatmap.color-scale.v1',
        }),
      );
      expect(decoded.value, source);
      expect(decoded.value.showInLegend, isFalse);
      expect(decoded.value.showTrackingAxisLabel, isFalse);
      expect(
        (decoded.value as HeatmapChartSeries).animation.entranceOrder,
        HeatmapEntranceOrder.radial,
      );
    }
  });

  test('rejects Heatmap documents without measured-value extension', () {
    final encoded =
        ChartSeriesDocumentCodec.encode(
              HeatmapChartSeries(
                id: 'matrix',
                points: [HeatmapDataPoint(x: 0, y: 0, value: 4)],
                colorScale: HeatmapColorScale.sequential(
                  colors: const [Colors.white, Colors.blue],
                ),
              ),
            )
            as ChartArtifactSuccess<ChartSeriesDocument>;
    final json = encoded.value.toJson();
    final data = json['data']! as Map<String, Object?>;
    final points = data['points']! as List<Object?>;
    final point = points.single! as Map<String, Object?>;
    point.remove('extensions');

    final decoded = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(json),
    );

    expect(decoded, isA<ChartArtifactFailure<ChartSeries>>());
    expect(
      (decoded as ChartArtifactFailure<ChartSeries>).error.message,
      contains('heatmap.cell.v1'),
    );
  });

  test('preserves zero separately from explicit missing cells', () {
    final source = HeatmapChartSeries(
      id: 'matrix',
      points: [
        HeatmapDataPoint(x: 0, y: 0, value: 0),
        HeatmapDataPoint.missing(x: 1, y: 0),
      ],
      colorScale: HeatmapColorScale.threshold(
        thresholds: const [1],
        colors: const [Colors.blue, Colors.red],
        bandLabels: const ['Low', 'High'],
      ),
    );
    final document =
        (ChartSeriesDocumentCodec.encode(source)
                as ChartArtifactSuccess<ChartSeriesDocument>)
            .value;
    final decoded =
        (ChartSeriesDocumentCodec.decode(document)
                    as ChartArtifactSuccess<ChartSeries>)
                .value
            as HeatmapChartSeries;

    expect(decoded.cells.first.value, 0);
    expect(decoded.cells.first.isMissing, isFalse);
    expect(decoded.cells.last.value, isNull);
    expect(decoded.cells.last.isMissing, isTrue);
  });
}
