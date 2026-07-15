import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChartPreview detaches byte input and output', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final preview = ChartPreview(
      mimeType: 'image/png',
      widthPixels: 10,
      heightPixels: 10,
      pixelRatio: 1,
      documentHash: 'sha256:test',
      bytes: source,
    );

    source[0] = 9;
    expect(preview.bytes, [1, 2, 3]);

    final returned = preview.bytes!;
    returned[1] = 9;
    expect(preview.bytes, [1, 2, 3]);
  });

  test('ChartPreview rejects simultaneous inline and referenced payloads', () {
    expect(
      () => ChartPreview(
        mimeType: 'image/png',
        widthPixels: 10,
        heightPixels: 10,
        pixelRatio: 1,
        documentHash: 'sha256:test',
        bytes: Uint8List(1),
        uri: Uri.parse('content://preview'),
      ),
      throwsArgumentError,
    );
  });

  test('artifact collection inputs cannot mutate the document', () {
    final sourceSeries = <ChartSeriesDocument>[];
    final document = ChartDocument(
      documentId: 'document',
      revision: 0,
      series: sourceSeries,
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme: ChartThemeDocument(),
      interaction: ChartInteractionDocument(),
    );

    sourceSeries.add(
      ChartSeriesDocument(
        type: 'line',
        id: 'late',
        data: InlinePointPayload(const []),
      ),
    );

    expect(document.series, isEmpty);
    expect(
      () => document.series.add(sourceSeries.single),
      throwsUnsupportedError,
    );
  });
}
