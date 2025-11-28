import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YAxisPosition', () {
    test('has exactly 4 values', () {
      expect(YAxisPosition.values.length, equals(4));
    });

    test('contains outerLeft value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.outerLeft),
        isTrue,
      );
    });

    test('contains left value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.left),
        isTrue,
      );
    });

    test('contains right value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.right),
        isTrue,
      );
    });

    test('contains outerRight value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.outerRight),
        isTrue,
      );
    });

    group('layout order (left to right)', () {
      test('outerLeft is first (index 0)', () {
        expect(YAxisPosition.outerLeft.index, equals(0));
      });

      test('left is second (index 1)', () {
        expect(YAxisPosition.left.index, equals(1));
      });

      test('right is third (index 2)', () {
        expect(YAxisPosition.right.index, equals(2));
      });

      test('outerRight is fourth (index 3)', () {
        expect(YAxisPosition.outerRight.index, equals(3));
      });

      test('values are in correct layout order', () {
        expect(
            YAxisPosition.values,
            equals([
              YAxisPosition.outerLeft,
              YAxisPosition.left,
              YAxisPosition.right,
              YAxisPosition.outerRight,
            ]));
      });
    });

    group('enum names', () {
      test('outerLeft has correct name', () {
        expect(YAxisPosition.outerLeft.name, equals('outerLeft'));
      });

      test('left has correct name', () {
        expect(YAxisPosition.left.name, equals('left'));
      });

      test('right has correct name', () {
        expect(YAxisPosition.right.name, equals('right'));
      });

      test('outerRight has correct name', () {
        expect(YAxisPosition.outerRight.name, equals('outerRight'));
      });
    });
  });
}
