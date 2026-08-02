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

    test('Y axis categorical configuration round-trips losslessly', () {
      const categoryAxis = CategoryAxisConfig(
        categories: ['Monday', 'Tuesday', 'Wednesday'],
        labelDensity: CategoryLabelDensity.showAll,
        labelOverflow: CategoryLabelOverflow.ellipsis,
        minimumCategoryExtent: 38,
        maximumLabelExtent: 92,
        maxLabelLines: 1,
        labelRotationDegrees: -20,
        autoViewport: false,
      );
      final axis = YAxisConfig(
        position: YAxisPosition.left,
        label: 'Day',
        categoryAxis: categoryAxis,
      ).copyWith(id: 'weekday');

      final document = _success(ChartAxisDocumentCodec.encodeYAxis(axis));
      final back = _success(
        ChartAxisDocumentCodec.decodeYAxis(
          ChartAxisDocument.fromJson(document.toJson()),
        ),
      );

      expect(document.categories, categoryAxis.categories);
      expect(back.categoryAxis, categoryAxis);
    });
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}
