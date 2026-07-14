import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema-v1 artifact surface is available from the public barrel', () {
    final artifact = ChartArtifact(
      artifactId: 'public-api',
      renderer: const ChartRendererInfo(
        package: 'braven_charts',
        version: '0.1.0',
      ),
      createdAt: DateTime.utc(2026, 7, 14),
      document: ChartDocument(
        documentId: 'public-document',
        revision: 0,
        series: const [],
        xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
        axes: const [],
        theme: ChartThemeDocument(),
        interaction: ChartInteractionDocument(),
      ),
      viewState: ChartViewState(),
    );

    final result = ChartArtifactJsonCodec.encode(artifact);

    expect(result, isA<ChartArtifactSuccess<String>>());
    expect(
      (result as ChartArtifactSuccess<String>).value,
      contains('braven.chartArtifact'),
    );
  });
}
