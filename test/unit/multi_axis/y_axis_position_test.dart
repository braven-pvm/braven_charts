import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YAxisPosition', () {
    test('has exactly 4 values', () {
      expect(YAxisPosition.values.length, equals(4));
    });

    test('contains leftOuter value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.leftOuter),
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

    test('contains rightOuter value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.rightOuter),
        isTrue,
      );
    });

    group('layout order (left to right)', () {
      test('leftOuter is first (index 0)', () {
        expect(YAxisPosition.leftOuter.index, equals(0));
      });

      test('left is second (index 1)', () {
        expect(YAxisPosition.left.index, equals(1));
      });

      test('right is third (index 2)', () {
        expect(YAxisPosition.right.index, equals(2));
      });

      test('rightOuter is fourth (index 3)', () {
        expect(YAxisPosition.rightOuter.index, equals(3));
      });

      test('values are in correct layout order', () {
        expect(
            YAxisPosition.values,
            equals([
              YAxisPosition.leftOuter,
              YAxisPosition.left,
              YAxisPosition.right,
              YAxisPosition.rightOuter,
            ]));
      });
    });

    group('enum names', () {
      test('leftOuter has correct name', () {
        expect(YAxisPosition.leftOuter.name, equals('leftOuter'));
      });

      test('left has correct name', () {
        expect(YAxisPosition.left.name, equals('left'));
      });

      test('right has correct name', () {
        expect(YAxisPosition.right.name, equals('right'));
      });

      test('rightOuter has correct name', () {
        expect(YAxisPosition.rightOuter.name, equals('rightOuter'));
      });
    });
  });
}
