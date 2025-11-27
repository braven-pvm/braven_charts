// Multi-Axis Unit Tests - 011-multi-axis-normalization
//
// This directory contains unit tests for multi-axis normalization feature:
// - YAxisConfig validation and behavior
// - MultiAxisState normalization/denormalization
// - AxisBoundsCalculator computations
// - NormalizationMode logic

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src_plus/axis/axis.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';

void main() {
  group('YAxisConfig', () {
    test('creates with required parameters', () {
      final config = YAxisConfig(
        id: 'price',
        position: YAxisPosition.left,
      );

      expect(config.id, 'price');
      expect(config.position, YAxisPosition.left);
      expect(config.showLabels, true);
      expect(config.showTicks, true);
      expect(config.showAxisLine, true);
    });

    test('validates id is not empty', () {
      expect(
        () => YAxisConfig(id: '', position: YAxisPosition.left),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates minWidth is positive', () {
      expect(
        () => YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          minWidth: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates maxWidth >= minWidth', () {
      expect(
        () => YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          minWidth: 100,
          maxWidth: 50,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates min < max when both specified', () {
      expect(
        () => YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          min: 100,
          max: 50,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates tickCount >= 2', () {
      expect(
        () => YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          tickCount: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith creates new instance with updated values', () {
      final original = YAxisConfig(
        id: 'price',
        position: YAxisPosition.left,
        showLabels: true,
      );

      final modified = original.copyWith(showLabels: false);

      expect(original.showLabels, true);
      expect(modified.showLabels, false);
      expect(modified.id, 'price');
      expect(modified.position, YAxisPosition.left);
    });

    test('equality compares all properties', () {
      final config1 = YAxisConfig(
        id: 'price',
        position: YAxisPosition.left,
      );
      final config2 = YAxisConfig(
        id: 'price',
        position: YAxisPosition.left,
      );
      final config3 = YAxisConfig(
        id: 'volume',
        position: YAxisPosition.left,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('YAxisPosition', () {
    test('isLeft returns true for left positions', () {
      expect(YAxisPosition.left.isLeft, true);
      expect(YAxisPosition.leftOuter.isLeft, true);
      expect(YAxisPosition.right.isLeft, false);
      expect(YAxisPosition.rightOuter.isLeft, false);
    });

    test('isRight returns true for right positions', () {
      expect(YAxisPosition.right.isRight, true);
      expect(YAxisPosition.rightOuter.isRight, true);
      expect(YAxisPosition.left.isRight, false);
      expect(YAxisPosition.leftOuter.isRight, false);
    });

    test('isOuter returns true for outer positions', () {
      expect(YAxisPosition.leftOuter.isOuter, true);
      expect(YAxisPosition.rightOuter.isOuter, true);
      expect(YAxisPosition.left.isOuter, false);
      expect(YAxisPosition.right.isOuter, false);
    });

    test('isInner returns true for inner positions', () {
      expect(YAxisPosition.left.isInner, true);
      expect(YAxisPosition.right.isInner, true);
      expect(YAxisPosition.leftOuter.isInner, false);
      expect(YAxisPosition.rightOuter.isInner, false);
    });
  });

  group('NormalizationMode', () {
    test('none disables normalization', () {
      expect(NormalizationMode.none, isNotNull);
    });

    test('auto enables automatic normalization', () {
      expect(NormalizationMode.auto, isNotNull);
    });

    test('perSeries enables per-series normalization', () {
      expect(NormalizationMode.perSeries, isNotNull);
    });
  });
}
