import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/services/data_optimizer.dart';

void main() {
  group('DataOptimizer', () {
    late DataOptimizer optimizer;

    setUp(() {
      optimizer = DataOptimizer();
    });

    test('downsample returns original data when below threshold', () {
      final data = List.generate(
        10,
        (index) => DataPoint(index.toDouble(), index.toDouble()),
      );

      final result = optimizer.downsample(data, 100000);

      expect(result.length, equals(data.length));
      expect(result.first, equals(data.first));
      expect(result.last, equals(data.last));
    });

    test('downsample reduces large data and preserves endpoints', () {
      final data = List.generate(
        100005,
        (index) => DataPoint(index.toDouble(), (index % 5).toDouble()),
      );

      final result = optimizer.downsample(data, 100000);

      expect(result.length, equals(100000));
      expect(result.first, equals(data.first));
      expect(result.last, equals(data.last));
    });

    test('downsampleIndices returns full range when target >= length', () {
      final indices = optimizer.downsampleIndices(5, 10);

      expect(indices, equals([0, 1, 2, 3, 4]));
    });

    test('downsampleIndices preserves endpoints', () {
      final indices = optimizer.downsampleIndices(100005, 100000);

      expect(indices.first, equals(0));
      expect(indices.last, equals(100004));
      expect(indices.length, equals(100000));
    });
  });
}
