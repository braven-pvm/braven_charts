library;

import 'package:braven_charts/src/models/data_point_label_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataPointLabelPosition', () {
    test('has four values', () {
      expect(DataPointLabelPosition.values, containsAll([
        DataPointLabelPosition.above,
        DataPointLabelPosition.below,
        DataPointLabelPosition.left,
        DataPointLabelPosition.right,
      ]));
    });
  });

  group('DataPointLabelConfig', () {
    group('defaults', () {
      test('show is false', () {
        const config = DataPointLabelConfig();
        expect(config.show, isFalse);
      });
      test('position is above', () {
        const config = DataPointLabelConfig();
        expect(config.position, DataPointLabelPosition.above);
      });
      test('offsets are zero', () {
        const config = DataPointLabelConfig();
        expect(config.offsetX, 0.0);
        expect(config.offsetY, 0.0);
      });
      test('labelColor is null (inherits series color)', () {
        const config = DataPointLabelConfig();
        expect(config.labelColor, isNull);
      });
      test('fontSize is 10.0', () {
        const config = DataPointLabelConfig();
        expect(config.fontSize, 10.0);
      });
      test('fontWeight is w600', () {
        const config = DataPointLabelConfig();
        expect(config.fontWeight, FontWeight.w600);
      });
      test('showUnit is false', () {
        const config = DataPointLabelConfig();
        expect(config.showUnit, isFalse);
      });
      test('formatter is null', () {
        const config = DataPointLabelConfig();
        expect(config.formatter, isNull);
      });
      test('background is null', () {
        const config = DataPointLabelConfig();
        expect(config.background, isNull);
      });
      test('backgroundOpacity is 0.85', () {
        const config = DataPointLabelConfig();
        expect(config.backgroundOpacity, 0.85);
      });
    });

    group('copyWith', () {
      test('copies all fields when nothing overridden', () {
        const original = DataPointLabelConfig(
          show: true,
          position: DataPointLabelPosition.right,
          offsetX: 2.0,
          offsetY: -1.0,
          labelColor: Colors.red,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          showUnit: true,
          background: Colors.white,
          backgroundOpacity: 0.9,
        );
        final copy = original.copyWith();
        expect(copy.show, isTrue);
        expect(copy.position, DataPointLabelPosition.right);
        expect(copy.offsetX, 2.0);
        expect(copy.offsetY, -1.0);
        expect(copy.labelColor, Colors.red);
        expect(copy.fontSize, 12.0);
        expect(copy.fontWeight, FontWeight.bold);
        expect(copy.showUnit, isTrue);
        expect(copy.background, Colors.white);
        expect(copy.backgroundOpacity, 0.9);
      });

      test('overrides specific fields', () {
        const original = DataPointLabelConfig(show: false);
        final copy = original.copyWith(show: true, fontSize: 14.0);
        expect(copy.show, isTrue);
        expect(copy.fontSize, 14.0);
        expect(copy.position, DataPointLabelPosition.above); // unchanged
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = DataPointLabelConfig(show: true, fontSize: 12.0);
        const b = DataPointLabelConfig(show: true, fontSize: 12.0);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different show values are not equal', () {
        const a = DataPointLabelConfig(show: true);
        const b = DataPointLabelConfig(show: false);
        expect(a, isNot(equals(b)));
      });
    });

    group('autoFormatLabelValue', () {
      test('formats whole number as integer', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, null), '5');
        expect(DataPointLabelConfig.autoFormatLabelValue(100.0, null), '100');
        expect(DataPointLabelConfig.autoFormatLabelValue(-5.0, null), '-5');
      });
      test('formats |y| < 1 with 2 decimal places', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(0.123, null), '0.12');
        expect(DataPointLabelConfig.autoFormatLabelValue(-0.75, null), '-0.75');
      });
      test('formats 1 <= |y| < 100 with 1 decimal place', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(12.56, null), '12.6');
        expect(DataPointLabelConfig.autoFormatLabelValue(99.94, null), '99.9');
      });
      test('formats |y| >= 100 non-integer as integer', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(150.7, null), '151');
      });
      test('appends unit when provided', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, 'W'), '5 W');
        expect(DataPointLabelConfig.autoFormatLabelValue(12.3, 'bpm'), '12.3 bpm');
      });
      test('no unit when unit is empty string', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, ''), '5');
      });
    });
  });
}
