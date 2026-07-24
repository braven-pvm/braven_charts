import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Config source emitter names axis scaleType/logBase', () {
    test('emits a non-default X-axis scaleType + logBase', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'line',
              points: [ChartDataPoint(x: 1, y: 1), ChartDataPoint(x: 10, y: 2)],
            ),
            xAxis: const XAxisConfig(
              label: 'x',
              scaleType: AxisScaleType.log,
              logBase: 2,
            ),
          ),
        ),
      );

      expect(generated.source, contains('scaleType: AxisScaleType.log,'));
      expect(generated.source, contains('logBase: 2.0,'));
    });

    test('emits a non-default Y-axis scaleType + logBase', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'line',
              points: [ChartDataPoint(x: 1, y: 1), ChartDataPoint(x: 10, y: 2)],
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              scaleType: AxisScaleType.log,
              logBase: 2,
            ),
          ),
        ),
      );

      expect(generated.source, contains('scaleType: AxisScaleType.log,'));
      expect(generated.source, contains('logBase: 2.0,'));
    });

    test('omits scaleType/logBase for a default (linear) axis', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'line',
              points: [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)],
            ),
          ),
        ),
      );

      expect(generated.source, isNot(contains('scaleType: AxisScaleType')));
      expect(generated.source, isNot(contains('logBase:')));
    });
  });
}

ChartGeneratedSource _success(
  ChartArtifactResult<ChartGeneratedSource> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

ChartDocumentSnapshot _snapshot(
  ChartSeries series, {
  String? title,
  ChartTheme? theme,
  String? themeReference = 'braven.light',
  XAxisConfig xAxis = const XAxisConfig(label: 'Elapsed interval'),
  YAxisConfig? yAxis,
}) {
  final encodedSeries = [
    (ChartSeriesDocumentCodec.encode(series)
            as ChartArtifactSuccess<ChartSeriesDocument>)
        .value,
  ];
  final encodedTheme = ChartThemeDocumentCodec.encode(
    theme ?? ChartTheme.light,
    reference: themeReference,
  );
  final encodedInteraction = ChartInteractionDocumentCodec.encode(
    const InteractionConfig(),
  );
  final encodedXAxis = ChartAxisDocumentCodec.encodeXAxis(xAxis);
  final encodedYAxis = ChartAxisDocumentCodec.encodeYAxis(
    yAxis ?? YAxisConfig(position: YAxisPosition.left, label: 'Value'),
  );

  return ChartDocumentSnapshot(
    document: ChartDocument(
      documentId: 'source-test',
      revision: 1,
      title: title,
      series: encodedSeries,
      annotations: const [],
      xAxis: (encodedXAxis as ChartArtifactSuccess<ChartAxisDocument>).value,
      axes: [(encodedYAxis as ChartArtifactSuccess<ChartAxisDocument>).value],
      theme: (encodedTheme as ChartArtifactSuccess<ChartThemeDocument>).value,
      interaction:
          (encodedInteraction as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
      configuration: JsonObjectValue(const {}),
      requiredCapabilities: const {},
    ),
  );
}
