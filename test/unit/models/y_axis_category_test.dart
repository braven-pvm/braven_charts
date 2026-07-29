import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YAxisConfig category axis', () {
    test('exposes category identity at exact integer centres', () {
      final axis = YAxisConfig(
        position: YAxisPosition.left,
        categoryAxis: const CategoryAxisConfig(
          categories: ['API', 'Web', 'Jobs'],
        ),
      );

      expect(axis.isCategorical, isTrue);
      expect(axis.categoryLabelFor(0), 'API');
      expect(axis.categoryLabelFor(2), 'Jobs');
      expect(axis.categoryLabelFor(1.2), isNull);
    });

    test('copyWith preserves, replaces, and clears category metadata', () {
      final source = YAxisConfig(
        position: YAxisPosition.left,
        categoryAxis: const CategoryAxisConfig(categories: ['A', 'B']),
      );

      expect(source.copyWith().categoryAxis, source.categoryAxis);
      expect(
        source
            .copyWith(
              categoryAxis: const CategoryAxisConfig(categories: ['C', 'D']),
            )
            .categoryLabelFor(1),
        'D',
      );
      expect(source.copyWith(clearCategoryAxis: true).categoryAxis, isNull);
    });
  });
}
