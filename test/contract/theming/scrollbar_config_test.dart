import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ScrollbarConfig immutability and copyWith()
///
/// Tests that ScrollbarConfig is properly immutable and supports selective
/// field modification via copyWith() pattern (required for theme customization).
///
/// See data-model.md Entity 3 "ScrollbarConfig" for specification.
void main() {
  group('ScrollbarConfig - CONTRACT', () {
    test('MUST be immutable (instances with identical values are equal)', () {
      const config1 = ScrollbarConfig();
      const config2 = ScrollbarConfig();

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('MUST support copyWith() for selective field modification', () {
      const original = ScrollbarConfig.defaultLight;

      final modified = original.copyWith(thickness: 16.0);

      expect(modified.thickness, equals(16.0));
      expect(modified.minHandleSize, equals(original.minHandleSize));
      expect(modified.trackColor, equals(original.trackColor));
      expect(modified.handleColor, equals(original.handleColor));
    });

    test('MUST support copyWith() for multiple field modifications', () {
      const original = ScrollbarConfig.defaultLight;

      final modified = original.copyWith(
        thickness: 16.0,
        handleColor: const Color(0xFF000000),
        autoHide: false,
        minZoomRatio: 0.05,
      );

      expect(modified.thickness, equals(16.0));
      expect(modified.handleColor, equals(const Color(0xFF000000)));
      expect(modified.autoHide, equals(false));
      expect(modified.minZoomRatio, equals(0.05));
      expect(modified.minHandleSize, equals(original.minHandleSize));
    });

    test('MUST maintain equality transitivity', () {
      const config1 = ScrollbarConfig.defaultLight;
      const config2 = ScrollbarConfig.defaultLight;
      final config3 = config1.copyWith();

      expect(config1, equals(config2));
      expect(config2, equals(config3));
      expect(config1, equals(config3));
    });

    test('MUST maintain equality reflexivity', () {
      const config = ScrollbarConfig.defaultLight;
      expect(config, equals(config));
    });

    test('MUST maintain equality symmetry', () {
      const config1 = ScrollbarConfig.defaultLight;
      const config2 = ScrollbarConfig.defaultLight;

      expect(config1, equals(config2));
      expect(config2, equals(config1));
    });

    test('MUST have different hashCodes for different configurations', () {
      const config1 = ScrollbarConfig.defaultLight;
      final config2 = config1.copyWith(thickness: 16.0);
      final config3 = config1.copyWith(handleColor: const Color(0xFF000000));

      expect(config1.hashCode, isNot(equals(config2.hashCode)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
      expect(config2.hashCode, isNot(equals(config3.hashCode)));
    });
  });
}
