import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('artifact extraction options are available from the public barrel', () {
    const options = ChartArtifactExtractOptions(
      artifactId: 'public-extraction',
      includePreview: true,
      documentOptions: ChartDocumentExtractOptions(documentId: 'public-doc'),
      previewOptions: ChartPreviewOptions(pixelRatio: 2),
    );

    expect(options.artifactId, 'public-extraction');
    expect(options.documentOptions.documentId, 'public-doc');
    expect(options.previewOptions.pixelRatio, 2);
  });

  test('columnar storage is selectable from the public extraction API', () {
    const options = ChartDocumentExtractOptions(
      dataStorage: ChartDataStorage.inlineColumns,
    );

    expect(options.dataStorage, ChartDataStorage.inlineColumns);
    expect(ChartDataStorage.inlinePoints.wireName, 'inlinePoints');
    expect(ChartDataStorage.inlineColumns.wireName, 'inlineColumns');
  });

  test(
    'selection projection policies are available from the public barrel',
    () {
      const options = ChartDocumentExtractOptions(
        dataScope: ChartDataScope.selection,
        selectionProjection: ChartSelectionProjectionOptions(
          seriesProjection:
              ChartSelectionSeriesProjection.completeParticipatingSeries,
          annotationProjection:
              ChartSelectionAnnotationProjection.retainContained,
        ),
      );

      expect(options.dataScope, ChartDataScope.selection);
      expect(
        options.selectionProjection.annotationProjection,
        ChartSelectionAnnotationProjection.retainContained,
      );
    },
  );

  test('referenced payload resolution is available from the public API', () {
    final resolver = _PublicResolver();
    final reference = ReferencedPayload(
      contentType: ChartDataBlobCodec.contentType,
      byteLength: 1,
      checksum:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      pointCount: 0,
      resolverKey: 'public-contract',
    );

    expect(resolver, isA<ChartDataResolver>());
    expect(reference.storage, 'referenced');
    expect(const ChartArtifactValidationLimits().maxDataPayloadBytes, 1 << 26);
    expect(ChartDataBinaryCodec.contentType, contains('columnar-binary-v1'));
    expect(ChartDataBinaryCodec.formatVersion, 1);
    expect(ChartDataBinaryCodec.compression, 'xor-significant-bytes-v1');
  });

  test('schema-v1 artifact surface is available from the public barrel', () {
    expect(
      ChartArtifactMigrationRegistry(const []),
      isA<ChartArtifactMigrationRegistry>(),
    );
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
    expect(ChartArtifactDeduplicator.group([artifact]).uniqueArtifacts, [
      artifact,
    ]);
    expect(
      ChartArtifactCanonicalizer.viewHash(
        artifact.document,
        artifact.viewState,
      ),
      startsWith('sha256:'),
    );
  });
}

class _PublicResolver implements ChartDataResolver {
  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async => ChartArtifactSuccess(value: const [0]);
}
