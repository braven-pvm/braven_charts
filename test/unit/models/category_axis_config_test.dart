import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryAxisConfig', () {
    test('maps integer data coordinates onto a padded category domain', () {
      const config = CategoryAxisConfig(categories: ['Alpha', 'Beta', 'Gamma']);

      expect(config.domainMin, -0.5);
      expect(config.domainMax, 2.5);
      expect(config.labelFor(0), 'Alpha');
      expect(config.labelFor(2), 'Gamma');
      expect(config.labelFor(1.2), isNull);
      expect(config.labelFor(3), isNull);
    });

    test('copyWith preserves and replaces category behavior', () {
      const source = CategoryAxisConfig(
        categories: ['One', 'Two'],
        labelOverflow: CategoryLabelOverflow.ellipsis,
        autoViewport: false,
      );

      final copy = source.copyWith(
        labelDensity: CategoryLabelDensity.showAll,
        maxLabelLines: 3,
      );

      expect(copy.categories, source.categories);
      expect(copy.labelOverflow, CategoryLabelOverflow.ellipsis);
      expect(copy.labelDensity, CategoryLabelDensity.showAll);
      expect(copy.maxLabelLines, 3);
      expect(copy.autoViewport, isFalse);
    });

    test('validates durable non-empty category identity', () {
      const valid = CategoryAxisConfig(categories: ['North', 'South']);
      expect(valid.validate, returnsNormally);

      const empty = CategoryAxisConfig(categories: ['North', '  ']);
      expect(empty.validate, throwsArgumentError);

      const duplicate = CategoryAxisConfig(
        categories: ['North', 'South', 'North'],
      );
      expect(duplicate.validate, throwsArgumentError);
    });
  });
}
