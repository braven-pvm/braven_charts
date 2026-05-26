import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YAxisPosition', () {
    test('has exactly 5 values', () {
      expect(YAxisPosition.values.length, equals(5));
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

    test('contains hidden value', () {
      expect(
        YAxisPosition.values.contains(YAxisPosition.hidden),
        isTrue,
      );
    });

    group('layout order (left to right)', () {
      // leftOuter/rightOuter are deprecated and moved to the end of the enum.
      // Indices reflect the new declaration order: left, right, hidden, leftOuter, rightOuter.
      test('left is first (index 0)', () {
        expect(YAxisPosition.left.index, equals(0));
      });

      test('right is second (index 1)', () {
        expect(YAxisPosition.right.index, equals(1));
      });

      test('hidden is third (index 2)', () {
        expect(YAxisPosition.hidden.index, equals(2));
      });

      // ignore: deprecated_member_use
      test('leftOuter is fourth (index 3)', () {
        // ignore: deprecated_member_use
        expect(YAxisPosition.leftOuter.index, equals(3));
      });

      // ignore: deprecated_member_use
      test('rightOuter is fifth (index 4)', () {
        // ignore: deprecated_member_use
        expect(YAxisPosition.rightOuter.index, equals(4));
      });

      test('values are in correct declaration order', () {
        expect(
            YAxisPosition.values,
            equals([
              YAxisPosition.left,
              YAxisPosition.right,
              YAxisPosition.hidden,
              // ignore: deprecated_member_use
              YAxisPosition.leftOuter,
              // ignore: deprecated_member_use
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

      test('hidden has correct name', () {
        expect(YAxisPosition.hidden.name, equals('hidden'));
      });
    });
  });
}
