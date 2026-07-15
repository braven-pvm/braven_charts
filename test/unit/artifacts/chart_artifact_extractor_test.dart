import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/artifacts/chart_artifact_extractor.dart'
    show ChartArtifactExtractor;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'composes document-only artifacts with caller envelope metadata',
    () async {
      var previewCalled = false;
      final createdAt = DateTime.parse('2026-07-15T08:30:00+02:00');
      final result = await ChartArtifactExtractor.extract(
        options: ChartArtifactExtractOptions(
          artifactId: 'artifact-1',
          createdAt: createdAt,
          documentOptions: const ChartDocumentExtractOptions(
            documentId: 'document-1',
          ),
          provenance: ChartArtifactProvenance(
            values: JsonObjectValue(const {
              'source': JsonStringValue('unit-test'),
            }),
          ),
        ),
        extractDocument: (_) => _documentSuccess(1),
        capturePreview: (_) async {
          previewCalled = true;
          return ChartArtifactFailure(
            error: const ChartArtifactError(code: 'unused', message: 'unused'),
          );
        },
      );

      final success = result as ChartArtifactSuccess<ChartArtifact>;
      expect(success.value.artifactId, 'artifact-1');
      expect(success.value.createdAt, DateTime.utc(2026, 7, 15, 6, 30));
      expect(success.value.document.revision, 1);
      expect(success.value.preview, isNull);
      expect(success.value.provenance.toJson(), {'source': 'unit-test'});
      expect(previewCalled, isFalse);
    },
  );

  test('retries until preview hash matches the returned document', () async {
    final first = _document(1);
    final second = _document(2);
    final documents = [first, second, second, second];
    final previewHashes = [
      ChartArtifactCanonicalizer.documentHash(first),
      ChartArtifactCanonicalizer.documentHash(second),
    ];
    var documentCall = 0;
    var previewCall = 0;

    final result = await ChartArtifactExtractor.extract(
      options: const ChartArtifactExtractOptions(
        artifactId: 'atomic',
        includePreview: true,
      ),
      extractDocument: (_) => ChartArtifactSuccess(
        value: ChartDocumentSnapshot(document: documents[documentCall++]),
      ),
      capturePreview: (_) async =>
          ChartArtifactSuccess(value: _preview(previewHashes[previewCall++])),
    );

    final artifact = (result as ChartArtifactSuccess<ChartArtifact>).value;
    expect(artifact.document.revision, 2);
    expect(
      artifact.preview?.documentHash,
      ChartArtifactCanonicalizer.documentHash(artifact.document),
    );
    expect(documentCall, 4);
    expect(previewCall, 2);
  });

  test('uses one document projection for artifact and preview', () async {
    ChartPreviewOptions? receivedPreviewOptions;
    final document = _document(1);
    final result = await ChartArtifactExtractor.extract(
      options: const ChartArtifactExtractOptions(
        artifactId: 'one-projection',
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'artifact-document',
        ),
        previewOptions: ChartPreviewOptions(
          documentOptions: ChartDocumentExtractOptions(
            documentId: 'conflicting-preview-document',
          ),
        ),
      ),
      extractDocument: (_) => ChartArtifactSuccess(
        value: ChartDocumentSnapshot(document: document),
      ),
      capturePreview: (options) async {
        receivedPreviewOptions = options;
        return ChartArtifactSuccess(
          value: _preview(ChartArtifactCanonicalizer.documentHash(document)),
        );
      },
    );

    expect(result, isA<ChartArtifactSuccess<ChartArtifact>>());
    expect(
      receivedPreviewOptions?.documentOptions.documentId,
      'artifact-document',
    );
  });

  test(
    'preview failure preserves a document-only artifact and warning',
    () async {
      final result = await ChartArtifactExtractor.extract(
        options: const ChartArtifactExtractOptions(
          artifactId: 'document-survives',
          includePreview: true,
        ),
        extractDocument: (_) => _documentSuccess(7),
        capturePreview: (_) async => ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.previewTooLarge,
            message: 'Preview exceeded the configured pixel limit.',
          ),
        ),
      );

      final success = result as ChartArtifactSuccess<ChartArtifact>;
      expect(success.value.document.revision, 7);
      expect(success.value.preview, isNull);
      expect(
        success.warnings.map((warning) => warning.code),
        contains(ChartArtifactDiagnosticCodes.previewTooLarge),
      );
    },
  );

  test('revision exhaustion preserves the latest native document', () async {
    var revision = 0;
    final result = await ChartArtifactExtractor.extract(
      options: const ChartArtifactExtractOptions(
        artifactId: 'unstable',
        includePreview: true,
        maxRevisionAttempts: 2,
      ),
      extractDocument: (_) => _documentSuccess(revision++),
      capturePreview: (_) async =>
          ChartArtifactSuccess(value: _preview('sha256:never-matches')),
    );

    final success = result as ChartArtifactSuccess<ChartArtifact>;
    expect(success.value.document.revision, 3);
    expect(success.value.preview, isNull);
    expect(
      success.warnings.map((warning) => warning.code),
      contains(ChartArtifactDiagnosticCodes.unstableStreamRevision),
    );
  });
}

ChartArtifactSuccess<ChartDocumentSnapshot> _documentSuccess(int revision) =>
    ChartArtifactSuccess(
      value: ChartDocumentSnapshot(document: _document(revision)),
    );

ChartDocument _document(int revision) => ChartDocument(
  documentId: 'document',
  revision: revision,
  series: const [],
  xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
  axes: const [],
  theme: ChartThemeDocument(),
  interaction: ChartInteractionDocument(),
);

ChartPreview _preview(String documentHash) => ChartPreview(
  mimeType: 'image/png',
  widthPixels: 10,
  heightPixels: 10,
  pixelRatio: 1,
  documentHash: documentHash,
  bytes: Uint8List.fromList(const [1, 2, 3]),
  byteLength: 3,
);
