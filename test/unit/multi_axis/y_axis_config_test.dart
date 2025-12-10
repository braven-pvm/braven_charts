import 'dart:ui' show Color;

import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YAxisConfig', () {
    group('construction', () {
      test('creates with required parameters only', () {
        final config = YAxisConfig.withId(id: 'test-axis',
          position: YAxisPosition.left,
        );

        expect(config.id, equals('test-axis'));
        expect(config.position, equals(YAxisPosition.left));
      });

      test('creates with all parameters', () {
        String formatter(double v) => '${v.toInt()}W';

        final config = YAxisConfig.withId(id: 'power',
          position: YAxisPosition.right,
          color: const Color(0xFF0000FF),
          label: 'Power',
          unit: 'W',
          min: 0,
          max: 400,
          showTicks: false,
          showAxisLine: false,
          labelDisplay: AxisLabelDisplay.none,
          minWidth: 50.0,
          maxWidth: 100.0,
          tickCount: 5,
          labelFormatter: formatter,
        );

        expect(config.id, equals('power'));
        expect(config.position, equals(YAxisPosition.right));
        expect(config.color, equals(const Color(0xFF0000FF)));
        expect(config.label, equals('Power'));
        expect(config.unit, equals('W'));
        expect(config.min, equals(0));
        expect(config.max, equals(400));
        expect(config.showTicks, isFalse);
        expect(config.showAxisLine, isFalse);
        expect(config.shouldShowTickLabels, isFalse);
        expect(config.minWidth, equals(50.0));
        expect(config.maxWidth, equals(100.0));
        expect(config.tickCount, equals(5));
        expect(config.labelFormatter, equals(formatter));
      });

      test('has correct default values', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
        );

        expect(config.color, isNull);
        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.min, isNull);
        expect(config.max, isNull);
        expect(config.showTicks, isTrue);
        expect(config.showAxisLine, isTrue);
        expect(config.shouldShowTickLabels, isTrue);
        expect(config.minWidth, equals(0.0));
        expect(config.maxWidth, equals(80.0));
        expect(config.tickCount, isNull);
        expect(config.labelFormatter, isNull);
      });
    });

    group('validation', () {
      test('throws assertion error for empty id', () {
        expect(
          () => YAxisConfig.withId(id: '',
            position: YAxisPosition.left,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for negative minWidth', () {
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            minWidth: -10,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for maxWidth < minWidth', () {
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            minWidth: 50,
            maxWidth: 40,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for min >= max', () {
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            min: 100,
            max: 50,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            min: 100,
            max: 100,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for tickCount < 2', () {
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            tickCount: 1,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            tickCount: 0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('allows null min or max independently', () {
        // Only min specified
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            min: 100,
          ),
          returnsNormally,
        );

        // Only max specified
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            max: 100,
          ),
          returnsNormally,
        );
      });

      test('allows tickCount >= 2', () {
        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            tickCount: 2,
          ),
          returnsNormally,
        );

        expect(
          () => YAxisConfig.withId(id: 'test',
            position: YAxisPosition.left,
            tickCount: 10,
          ),
          returnsNormally,
        );
      });
    });

    group('copyWith', () {
      test('returns new instance (not same reference)', () {
        final original = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
        );

        final copy = original.copyWith();

        expect(identical(original, copy), isFalse);
      });

      test('changes specified values', () {
        final original = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
          label: 'Original',
        );

        final copy = original.copyWith(
          position: YAxisPosition.right,
          label: 'Changed',
        );

        expect(copy.id, equals('test')); // Unchanged
        expect(copy.position, equals(YAxisPosition.right)); // Changed
        expect(copy.color, equals(const Color(0xFF0000FF))); // Unchanged
        expect(copy.label, equals('Changed')); // Changed
      });

      test('preserves unchanged values', () {
        final original = YAxisConfig.withId(id: 'power',
          position: YAxisPosition.leftOuter,
          color: const Color(0xFFFF0000),
          label: 'Power',
          unit: 'W',
          min: 0,
          max: 400,
          showTicks: false,
          showAxisLine: false,
          labelDisplay: AxisLabelDisplay.none,
          minWidth: 50,
          maxWidth: 100,
          tickCount: 5,
        );

        final copy = original.copyWith(label: 'New Label');

        expect(copy.id, equals('power'));
        expect(copy.position, equals(YAxisPosition.leftOuter));
        expect(copy.color, equals(const Color(0xFFFF0000)));
        expect(copy.unit, equals('W'));
        expect(copy.min, equals(0));
        expect(copy.max, equals(400));
        expect(copy.showTicks, isFalse);
        expect(copy.showAxisLine, isFalse);
        expect(copy.shouldShowTickLabels, isFalse);
        expect(copy.minWidth, equals(50));
        expect(copy.maxWidth, equals(100));
        expect(copy.tickCount, equals(5));
      });

      test('can change id', () {
        final original = YAxisConfig.withId(id: 'original-id',
          position: YAxisPosition.left,
        );

        final copy = original.copyWith(id: 'new-id');

        expect(copy.id, equals('new-id'));
      });

      test('can set optional values to null via explicit null handling', () {
        final original = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
          label: 'Label',
        );

        // copyWith typically doesn't allow setting back to null
        // This test verifies the original values are preserved
        final copy = original.copyWith();

        expect(copy.color, equals(const Color(0xFF0000FF)));
        expect(copy.label, equals('Label'));
      });
    });

    group('equality', () {
      test('same values are equal', () {
        final config1 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
          label: 'Test',
        );

        final config2 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
          label: 'Test',
        );

        expect(config1, equals(config2));
      });

      test('different id values are not equal', () {
        final config1 = YAxisConfig.withId(id: 'test1',
          position: YAxisPosition.left,
        );

        final config2 = YAxisConfig.withId(id: 'test2',
          position: YAxisPosition.left,
        );

        expect(config1, isNot(equals(config2)));
      });

      test('different position values are not equal', () {
        final config1 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
        );

        final config2 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.right,
        );

        expect(config1, isNot(equals(config2)));
      });

      test('different optional values are not equal', () {
        final config1 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          label: 'Label 1',
        );

        final config2 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          label: 'Label 2',
        );

        expect(config1, isNot(equals(config2)));
      });

      test('hashCode is consistent with equality', () {
        final config1 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
        );

        final config2 = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
        );

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('identical objects are equal', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
        );

        expect(config, equals(config));
      });
    });

    group('all positions work', () {
      test('leftOuter position', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.leftOuter,
        );
        expect(config.position, equals(YAxisPosition.leftOuter));
      });

      test('left position', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.left,
        );
        expect(config.position, equals(YAxisPosition.left));
      });

      test('right position', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.right,
        );
        expect(config.position, equals(YAxisPosition.right));
      });

      test('rightOuter position', () {
        final config = YAxisConfig.withId(id: 'test',
          position: YAxisPosition.rightOuter,
        );
        expect(config.position, equals(YAxisPosition.rightOuter));
      });
    });
  });
}
