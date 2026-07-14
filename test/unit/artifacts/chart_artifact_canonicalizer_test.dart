import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document hash is SHA-256 and independent of map insertion order', () {
    final first = _document(
      metadata: JsonObjectValue({
        'b': JsonNumberValue(2),
        'a': JsonNumberValue(1),
      }),
    );
    final second = _document(
      metadata: JsonObjectValue({
        'a': JsonNumberValue(1),
        'b': JsonNumberValue(2),
      }),
    );

    final firstHash = ChartArtifactCanonicalizer.documentHash(first);
    final secondHash = ChartArtifactCanonicalizer.documentHash(second);

    expect(firstHash, startsWith('sha256:'));
    expect(firstHash, hasLength(71));
    expect(secondHash, firstHash);
  });

  test('document hash changes with rendering-relevant data', () {
    final first = ChartArtifactCanonicalizer.documentHash(_document(y: 10));
    final second = ChartArtifactCanonicalizer.documentHash(_document(y: 11));

    expect(second, isNot(first));
  });
}

ChartDocument _document({double y = 10, JsonObjectValue? metadata}) =>
    ChartDocument(
      documentId: 'hash-test',
      revision: 1,
      series: [
        ChartSeriesDocument(
          type: 'line',
          id: 'series',
          metadata: metadata,
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
