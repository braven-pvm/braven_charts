/// API Contract: AxisConfig
/// TDD red phase - tests written before implementation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('AxisConfig Contract', () {
    test('MUST have factory constructor defaults()', () {
      final config = AxisConfig.defaults();
      expect(config.showAxis, isTrue);
      expect(config.showGrid, isTrue);
      expect(config.showTicks, isTrue);
      expect(config.showLabels, isTrue);
    });

    test('MUST have factory constructor hidden()', () {
      final config = AxisConfig.hidden();
      expect(config.showAxis, isFalse);
      expect(config.showGrid, isFalse);
      expect(config.showTicks, isFalse);
      expect(config.showLabels, isFalse);
    });

    test('MUST have factory constructor minimal()', () {
      final config = AxisConfig.minimal();
      expect(config.showAxis, isFalse);
      expect(config.showGrid, isTrue);
      expect(config.showTicks, isFalse);
    });

    test('MUST have factory constructor gridOnly()', () {
      final config = AxisConfig.gridOnly();
      expect(config.showAxis, isFalse);
      expect(config.showGrid, isTrue);
      expect(config.showTicks, isFalse);
      expect(config.showLabels, isFalse);
    });

    test('MUST support copyWith for customization', () {
      final config = AxisConfig.defaults();
      final modified = config.copyWith(showAxis: false);
      expect(modified.showAxis, isFalse);
      expect(modified.showGrid, isTrue); // Unchanged
    });

    test('MUST validate positive widths', () {
      expect(
        () => AxisConfig(axisWidth: -1),
        throwsAssertionError,
      );
    });

    test('MUST validate range min < max', () {
      expect(
        () => AxisConfig(range: AxisRange(10, 5)), // Invalid!
        throwsAssertionError,
      );
    });
  });
}
