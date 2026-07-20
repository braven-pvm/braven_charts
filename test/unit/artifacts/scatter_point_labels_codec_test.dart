import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scatter point-label layout round-trips through artifacts', () {
    const source = ScatterChartSeries(
      id: 'labelled-accounts',
      points: [ChartDataPoint(x: 4, y: 5, label: 'North')],
      dataPointLabels: DataPointLabelConfig(
        show: true,
        position: DataPointLabelPosition.right,
        content: DataPointLabelContent.pointLabel,
        offsetX: 6,
        offsetY: -2,
        markerGap: 5,
        collisionPolicy: DataPointLabelCollisionPolicy.reposition,
        collisionPadding: 3,
        plotEdgeAware: false,
        labelColor: Color(0xFF334155),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        background: Color(0xFFFFFFFF),
        backgroundOpacity: 0.92,
      ),
    );

    final encoded = ChartSeriesDocumentCodec.encode(source);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    final style = Map<String, Object?>.from(document.style!.toJson()! as Map);
    expect(style['dataPointLabels'], isA<Map<String, Object?>>());

    final decoded = ChartSeriesDocumentCodec.decode(document);
    expect((decoded as ChartArtifactSuccess<ChartSeries>).value, source);
  });

  test('legacy point-label documents receive collision defaults', () {
    final encoded =
        ChartSeriesDocumentCodec.encode(
              const ScatterChartSeries(
                id: 'legacy-labels',
                points: [ChartDataPoint(x: 1, y: 2)],
                dataPointLabels: DataPointLabelConfig(show: true),
              ),
            )
            as ChartArtifactSuccess<ChartSeriesDocument>;
    final json = Map<String, Object?>.from(encoded.value.toJson());
    final style = Map<String, Object?>.from(json['style']! as Map);
    final labels = Map<String, Object?>.from(style['dataPointLabels']! as Map)
      ..remove('content')
      ..remove('markerGap')
      ..remove('collisionPolicy')
      ..remove('collisionPadding')
      ..remove('plotEdgeAware');
    style['dataPointLabels'] = labels;
    json['style'] = style;

    final decoded = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(json),
    );
    final series =
        (decoded as ChartArtifactSuccess<ChartSeries>).value
            as ScatterChartSeries;
    expect(series.dataPointLabels, const DataPointLabelConfig(show: true));
  });
}
