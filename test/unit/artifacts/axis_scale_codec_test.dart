import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartAxisDocumentCodec scaleType/logBase', () {
    test('X axis scaleType/logBase round-trip through the codec', () {
      const axis = XAxisConfig(scaleType: AxisScaleType.log, logBase: 2);
      final document = _success(ChartAxisDocumentCodec.encodeXAxis(axis));
      final back = _success(
        ChartAxisDocumentCodec.decodeXAxis(
          ChartAxisDocument.fromJson(document.toJson()),
        ),
      );
      expect(back.scaleType, AxisScaleType.log);
      expect(back.logBase, 2);
    });

    test('X axis defaults omit scaleType/logBase from JSON', () {
      const axis = XAxisConfig(label: 'x');
      final document = _success(ChartAxisDocumentCodec.encodeXAxis(axis));
      final json = document.toJson();
      expect(json.containsKey('scaleType'), isFalse);
      expect(json.containsKey('logBase'), isFalse);
      final back = _success(
        ChartAxisDocumentCodec.decodeXAxis(ChartAxisDocument.fromJson(json)),
      );
      expect(back.scaleType, AxisScaleType.linear);
      expect(back.logBase, 10);
    });

    test('Y axis scaleType/logBase round-trip through the codec', () {
      final axis = YAxisConfig(
        position: YAxisPosition.left,
        scaleType: AxisScaleType.log,
        logBase: 2,
      ).copyWith(id: 'y-axis');
      final document = _success(ChartAxisDocumentCodec.encodeYAxis(axis));
      final back = _success(
        ChartAxisDocumentCodec.decodeYAxis(
          ChartAxisDocument.fromJson(document.toJson()),
        ),
      );
      expect(back.scaleType, AxisScaleType.log);
      expect(back.logBase, 2);
    });

    test('Y axis defaults omit scaleType/logBase from JSON', () {
      final axis = YAxisConfig(
        position: YAxisPosition.left,
      ).copyWith(id: 'y-axis');
      final document = _success(ChartAxisDocumentCodec.encodeYAxis(axis));
      final json = document.toJson();
      expect(json.containsKey('scaleType'), isFalse);
      expect(json.containsKey('logBase'), isFalse);
      final back = _success(
        ChartAxisDocumentCodec.decodeYAxis(ChartAxisDocument.fromJson(json)),
      );
      expect(back.scaleType, AxisScaleType.linear);
      expect(back.logBase, 10);
    });
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
