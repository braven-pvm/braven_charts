import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scatter jitter round-trips with its portable capability', () {
    const source = ScatterChartSeries(
      id: 'survey-responses',
      points: [ChartDataPoint(x: 4, y: 5), ChartDataPoint(x: 4, y: 5)],
      jitter: ScatterJitterConfig(xAmplitude: 12, yAmplitude: 8, seed: 17),
    );

    final encoded = ChartSeriesDocumentCodec.encode(source);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(document.requiredCapabilities, contains('series.scatter.jitter.v1'));
    final style = Map<String, Object?>.from(document.style!.toJson()! as Map);
    expect(style['jitter'], {
      'xAmplitude': 12.0,
      'yAmplitude': 8.0,
      'seed': 17,
    });

    final decoded = ChartSeriesDocumentCodec.decode(document);
    expect((decoded as ChartArtifactSuccess<ChartSeries>).value, source);
  });

  test('Scatter jitter decoding rejects invalid amplitudes', () {
    final encoded =
        ChartSeriesDocumentCodec.encode(
              const ScatterChartSeries(
                id: 'invalid-jitter',
                points: [ChartDataPoint(x: 1, y: 2)],
                jitter: ScatterJitterConfig(xAmplitude: 4),
              ),
            )
            as ChartArtifactSuccess<ChartSeriesDocument>;
    final json = Map<String, Object?>.from(encoded.value.toJson());
    final style = Map<String, Object?>.from(json['style']! as Map);
    final jitter = Map<String, Object?>.from(style['jitter']! as Map)
      ..['xAmplitude'] = -1;
    style['jitter'] = jitter;
    json['style'] = style;

    final decoded = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(json),
    );
    expect(decoded, isA<ChartArtifactFailure<ChartSeries>>());
  });
}
