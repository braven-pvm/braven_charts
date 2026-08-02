import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

void main() {
  test('shared fixed domains survive artifacts and generated Dart', () async {
    HeatmapChartSeries createSeries(String id, List<double> values) =>
        HeatmapChartSeries(
          id: id,
          name: id,
          points: [
            for (var index = 0; index < values.length; index++)
              HeatmapDataPoint(
                x: index.toDouble(),
                y: 0,
                value: values[index],
                pointKey: '$id-$index',
              ),
          ],
          colorScale: HeatmapColorScale.sequential(
            colors: const [Colors.white, Colors.indigo],
            label: 'Latency',
            unit: 'ms',
          ),
        );

    final sourceSeries = [
      createSeries('checkout', const [12, 18, 31]),
      createSeries('reporting', const [52, 74, 96]),
    ];
    final domain = HeatmapSharedColorDomain.fromSeries(
      sourceSeries,
      paddingFraction: 0.05,
    );
    final sharedSeries = [
      for (final series in sourceSeries)
        series.copyWith(colorScale: domain.scaleFor(series.colorScale)),
    ];

    final documents = [
      for (final series in sharedSeries)
        _success(ChartSeriesDocumentCodec.encode(series)),
    ];
    final decoded = [
      for (final document in documents)
        _success(ChartSeriesDocumentCodec.decode(document))
            as HeatmapChartSeries,
    ];
    expect(decoded.map((series) => series.colorScale.minimumValue).toSet(), {
      domain.minimumValue,
    });
    expect(decoded.map((series) => series.colorScale.maximumValue).toSet(), {
      domain.maximumValue,
    });

    final document = ChartDocument(
      documentId: 'shared-domain-small-multiples',
      revision: 1,
      series: documents,
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: [ChartAxisDocument(id: 'y', position: 'left')],
      theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)),
      interaction: _success(
        ChartInteractionDocumentCodec.encode(const InteractionConfig()),
      ),
    );
    final generated = _success(
      ChartDartSourceGenerator.generate(
        ChartDocumentSnapshot(document: document),
        options: const ChartDartSourceOptions(
          variableName: 'sharedDomainCharts',
        ),
      ),
    );
    expect(
      RegExp(
        'minimumValue: ${RegExp.escape(domain.minimumValue.toString())}',
      ).allMatches(generated.source),
      hasLength(2),
    );
    expect(
      RegExp(
        'maximumValue: ${RegExp.escape(domain.maximumValue.toString())}',
      ).allMatches(generated.source),
      hasLength(2),
    );
    await expectGeneratedSourceCompiles(
      generated.source,
      fixtureName: 'heatmap_shared_domain_generated_source',
    );
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
