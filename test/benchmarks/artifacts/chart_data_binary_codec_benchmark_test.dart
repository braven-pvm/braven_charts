import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binary payload benchmark covers small, medium, and large datasets', () {
    for (final pointCount in [100, 10000, 100000]) {
      final payload = InlineColumnarPayload(
        xValues: [
          for (var index = 0; index < pointCount; index++)
            ChartNumberDocument.fromDouble(index.toDouble()),
        ],
        yValues: [
          for (var index = 0; index < pointCount; index++)
            ChartNumberDocument.fromDouble(180 + index * 0.125),
        ],
      );
      final jsonBlob = _success(ChartDataBlobCodec.encode(payload)).value;

      final encodeWatch = Stopwatch()..start();
      final binaryBlob = _success(ChartDataBinaryCodec.encode(payload)).value;
      encodeWatch.stop();
      final decodeWatch = Stopwatch()..start();
      final decoded = _success(
        ChartDataBinaryCodec.decode(
          binaryBlob.reference(resolverKey: 'benchmark/$pointCount'),
          binaryBlob.bytes,
        ),
      ).value;
      decodeWatch.stop();

      expect(decoded.pointCount, pointCount);
      expect(binaryBlob.byteLength, lessThan(jsonBlob.byteLength));
      expect(encodeWatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(decodeWatch.elapsed, lessThan(const Duration(seconds: 5)));
      // ignore: avoid_print
      print(
        'Binary payload ($pointCount points): '
        '${binaryBlob.byteLength}B vs ${jsonBlob.byteLength}B JSON; '
        'encode ${encodeWatch.elapsedMicroseconds / 1000}ms; '
        'decode ${decodeWatch.elapsedMicroseconds / 1000}ms',
      );
    }
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
