import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartArtifactDeduplicator', () {
    test('groups equal documents in stable input order', () {
      final shared = _document('shared', y: 10);
      final distinct = _document('distinct', y: 11);
      final artifacts = [
        _artifact('first', shared),
        _artifact('other', distinct),
        _artifact('duplicate', shared),
      ];

      final result = ChartArtifactDeduplicator.group(artifacts);

      expect(result.scope, ChartArtifactDeduplicationScope.document);
      expect(result.inputCount, 3);
      expect(result.duplicateCount, 1);
      expect(result.uniqueArtifacts.map((artifact) => artifact.artifactId), [
        'first',
        'other',
      ]);
      expect(result.groups.first.primary.artifactId, 'first');
      expect(result.groups.first.duplicates.single.artifactId, 'duplicate');
      expect(
        result.groups.first.hash,
        ChartArtifactCanonicalizer.documentHash(shared),
      );
    });

    test('view scope separates durable view states', () {
      final shared = _document('shared');
      final artifacts = [
        _artifact(
          'visible-a',
          shared,
          viewState: ChartViewState(hiddenSeriesIds: const {'b'}),
        ),
        _artifact(
          'visible-b',
          shared,
          viewState: ChartViewState(hiddenSeriesIds: const {'a'}),
        ),
        _artifact(
          'visible-a-copy',
          shared,
          viewState: ChartViewState(hiddenSeriesIds: const {'b'}),
        ),
      ];

      final documentResult = ChartArtifactDeduplicator.group(artifacts);
      final viewResult = ChartArtifactDeduplicator.group(
        artifacts,
        scope: ChartArtifactDeduplicationScope.view,
      );

      expect(documentResult.groups, hasLength(1));
      expect(documentResult.duplicateCount, 2);
      expect(viewResult.groups, hasLength(2));
      expect(viewResult.duplicateCount, 1);
      expect(viewResult.groups.first.primary.artifactId, 'visible-a');
      expect(
        viewResult.groups.first.duplicates.single.artifactId,
        'visible-a-copy',
      );
    });

    test('publishes immutable result collections', () {
      final artifact = _artifact('only', _document('only'));
      final result = ChartArtifactDeduplicator.group([artifact, artifact]);

      expect(
        () => result.groups.add(result.groups.single),
        throwsUnsupportedError,
      );
      expect(
        () => result.uniqueArtifacts.add(artifact),
        throwsUnsupportedError,
      );
      expect(
        () => result.groups.single.duplicates.add(artifact),
        throwsUnsupportedError,
      );
    });
  });
}

ChartArtifact _artifact(
  String artifactId,
  ChartDocument document, {
  ChartViewState? viewState,
}) => ChartArtifact(
  artifactId: artifactId,
  renderer: const ChartRendererInfo(package: 'braven_charts', version: 'test'),
  createdAt: DateTime.utc(2026, 7, 15),
  document: document,
  viewState: viewState,
);

ChartDocument _document(String documentId, {double y = 10}) => ChartDocument(
  documentId: documentId,
  revision: 1,
  series: [
    ChartSeriesDocument(
      type: 'line',
      id: 'series',
      data: InlinePointPayload([
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(1),
          y: ChartNumberDocument.fromDouble(y),
        ),
      ]),
    ),
  ],
  xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
  axes: [ChartAxisDocument(id: 'y', position: 'left')],
  theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
  interaction: _success(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value,
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
