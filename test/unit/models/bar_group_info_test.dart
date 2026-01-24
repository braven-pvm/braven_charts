// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/models/bar_group_info.dart';

void main() {
  group('BarGroupInfo', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        const info = BarGroupInfo(index: 0, count: 3);

        expect(info.index, equals(0));
        expect(info.count, equals(3));
        expect(info.gap, equals(2.0));
      });

      test('creates instance with custom gap', () {
        const info = BarGroupInfo(index: 1, count: 3, gap: 4.0);

        expect(info.index, equals(1));
        expect(info.count, equals(3));
        expect(info.gap, equals(4.0));
      });

      test('throws assertion error when index is negative', () {
        expect(
          () => BarGroupInfo(index: -1, count: 3),
          throwsAssertionError,
        );
      });

      test('throws assertion error when count is less than 1', () {
        expect(
          () => BarGroupInfo(index: 0, count: 0),
          throwsAssertionError,
        );
      });

      test('throws assertion error when index >= count', () {
        expect(
          () => BarGroupInfo(index: 3, count: 3),
          throwsAssertionError,
        );
      });

      test('throws assertion error when gap is negative', () {
        expect(
          () => BarGroupInfo(index: 0, count: 3, gap: -1.0),
          throwsAssertionError,
        );
      });

      test('allows gap of 0', () {
        const info = BarGroupInfo(index: 0, count: 3, gap: 0.0);
        expect(info.gap, equals(0.0));
      });

      test('is const constructible', () {
        const info1 = BarGroupInfo(index: 0, count: 3);
        const info2 = BarGroupInfo(index: 0, count: 3);

        expect(identical(info1, info2), isTrue);
      });
    });

    group('calculateOffset', () {
      test('calculates correct offset for single bar series', () {
        const info = BarGroupInfo(index: 0, count: 1);
        final offset = info.calculateOffset(20.0);

        // Single bar should be centered at 0
        expect(offset, equals(0.0));
      });

      test('calculates correct offsets for three bar series with default gap', () {
        const info0 = BarGroupInfo(index: 0, count: 3);
        const info1 = BarGroupInfo(index: 1, count: 3);
        const info2 = BarGroupInfo(index: 2, count: 3);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);
        final offset2 = info2.calculateOffset(20.0);

        // With 20px bars and 2px gap:
        // effectiveWidth = 22px
        // totalWidth = 22*3 - 2 = 64px
        // startOffset = -64/2 + 20/2 = -22px
        // offsets: -22, 0, 22
        expect(offset0, equals(-22.0));
        expect(offset1, equals(0.0));
        expect(offset2, equals(22.0));
      });

      test('calculates correct offsets for two bar series', () {
        const info0 = BarGroupInfo(index: 0, count: 2);
        const info1 = BarGroupInfo(index: 1, count: 2);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);

        // With 20px bars and 2px gap:
        // effectiveWidth = 22px
        // totalWidth = 22*2 - 2 = 42px
        // startOffset = -42/2 + 20/2 = -11px
        // offsets: -11, 11
        expect(offset0, equals(-11.0));
        expect(offset1, equals(11.0));
      });

      test('calculates correct offsets with custom gap', () {
        const info0 = BarGroupInfo(index: 0, count: 3, gap: 4.0);
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 4.0);
        const info2 = BarGroupInfo(index: 2, count: 3, gap: 4.0);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);
        final offset2 = info2.calculateOffset(20.0);

        // With 20px bars and 4px gap:
        // effectiveWidth = 24px
        // totalWidth = 24*3 - 4 = 68px
        // startOffset = -68/2 + 20/2 = -24px
        // offsets: -24, 0, 24
        expect(offset0, equals(-24.0));
        expect(offset1, equals(0.0));
        expect(offset2, equals(24.0));
      });

      test('calculates correct offsets with zero gap', () {
        const info0 = BarGroupInfo(index: 0, count: 3, gap: 0.0);
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 0.0);
        const info2 = BarGroupInfo(index: 2, count: 3, gap: 0.0);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);
        final offset2 = info2.calculateOffset(20.0);

        // With 20px bars and 0px gap:
        // effectiveWidth = 20px
        // totalWidth = 20*3 - 0 = 60px
        // startOffset = -60/2 + 20/2 = -20px
        // offsets: -20, 0, 20
        expect(offset0, equals(-20.0));
        expect(offset1, equals(0.0));
        expect(offset2, equals(20.0));
      });

      test('works with different bar widths', () {
        const info = BarGroupInfo(index: 1, count: 3);

        final offset10 = info.calculateOffset(10.0);
        final offset20 = info.calculateOffset(20.0);
        final offset30 = info.calculateOffset(30.0);

        // Middle bar should always be at 0
        expect(offset10, equals(0.0));
        expect(offset20, equals(0.0));
        expect(offset30, equals(0.0));
      });

      test('maintains symmetry for odd count', () {
        const info0 = BarGroupInfo(index: 0, count: 5);
        const info4 = BarGroupInfo(index: 4, count: 5);

        final offset0 = info0.calculateOffset(20.0);
        final offset4 = info4.calculateOffset(20.0);

        // First and last should be symmetric
        expect(offset0, equals(-offset4));
      });

      test('maintains symmetry for even count', () {
        const info0 = BarGroupInfo(index: 0, count: 4);
        const info3 = BarGroupInfo(index: 3, count: 4);

        final offset0 = info0.calculateOffset(20.0);
        final offset3 = info3.calculateOffset(20.0);

        // First and last should be symmetric
        expect(offset0, equals(-offset3));
      });
    });

    group('equality and hashCode', () {
      test('equal instances have same hash code', () {
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 1, count: 3, gap: 2.0);

        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('different index produces different instance', () {
        const info1 = BarGroupInfo(index: 0, count: 3);
        const info2 = BarGroupInfo(index: 1, count: 3);

        expect(info1, isNot(equals(info2)));
      });

      test('different count produces different instance', () {
        const info1 = BarGroupInfo(index: 0, count: 2);
        const info2 = BarGroupInfo(index: 0, count: 3);

        expect(info1, isNot(equals(info2)));
      });

      test('different gap produces different instance', () {
        const info1 = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 0, count: 3, gap: 4.0);

        expect(info1, isNot(equals(info2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const info = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        final str = info.toString();

        expect(str, contains('BarGroupInfo'));
        expect(str, contains('index: 1'));
        expect(str, contains('count: 3'));
        expect(str, contains('gap: 2.0'));
      });
    });

    group('copyWith', () {
      test('creates copy with overridden index', () {
        const original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        final copy = original.copyWith(index: 1);

        expect(copy.index, equals(1));
        expect(copy.count, equals(3));
        expect(copy.gap, equals(2.0));
      });

      test('creates copy with overridden count', () {
        const original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        final copy = original.copyWith(count: 4);

        expect(copy.index, equals(0));
        expect(copy.count, equals(4));
        expect(copy.gap, equals(2.0));
      });

      test('creates copy with overridden gap', () {
        const original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        final copy = original.copyWith(gap: 4.0);

        expect(copy.index, equals(0));
        expect(copy.count, equals(3));
        expect(copy.gap, equals(4.0));
      });

      test('creates copy with multiple overrides', () {
        const original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        final copy = original.copyWith(index: 2, gap: 5.0);

        expect(copy.index, equals(2));
        expect(copy.count, equals(3));
        expect(copy.gap, equals(5.0));
      });

      test('creates identical copy when no parameters provided', () {
        const original = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('immutability', () {
      test('fields are final and cannot be modified', () {
        const info = BarGroupInfo(index: 0, count: 3);

        // This test verifies the class is properly immutable at compile time
        // If this compiles, immutability is enforced
        expect(info.index, equals(0));
        expect(info.count, equals(3));
        expect(info.gap, equals(2.0));
      });
    });

    group('edge cases', () {
      test('handles very large bar widths', () {
        const info = BarGroupInfo(index: 1, count: 3);
        final offset = info.calculateOffset(1000.0);

        expect(offset, equals(0.0)); // Middle bar always at 0
      });

      test('handles very small bar widths', () {
        const info = BarGroupInfo(index: 1, count: 3);
        final offset = info.calculateOffset(1.0);

        expect(offset, equals(0.0)); // Middle bar always at 0
      });

      test('handles large number of bars', () {
        const info0 = BarGroupInfo(index: 0, count: 10);
        const info9 = BarGroupInfo(index: 9, count: 10);

        final offset0 = info0.calculateOffset(20.0);
        final offset9 = info9.calculateOffset(20.0);

        // Should maintain symmetry
        expect(offset0, equals(-offset9));
      });

      test('handles fractional bar widths', () {
        const info = BarGroupInfo(index: 0, count: 3);
        final offset = info.calculateOffset(15.5);

        // Should calculate correctly with fractional values
        expect(offset, isA<double>());
        expect(offset.isFinite, isTrue);
      });
    });

    group('documentation examples', () {
      test('example from class documentation works correctly', () {
        // Example from BarGroupInfo class doc
        const groupInfo = BarGroupInfo(
          index: 1,
          count: 3,
          gap: 2.0,
        );

        final offset = groupInfo.calculateOffset(20.0);
        expect(offset, equals(0.0)); // Middle of three bars
      });

      test('example from calculateOffset documentation works correctly', () {
        // Example from calculateOffset method doc
        const info0 = BarGroupInfo(index: 0, count: 3);
        const info1 = BarGroupInfo(index: 1, count: 3);
        const info2 = BarGroupInfo(index: 2, count: 3);

        expect(info0.calculateOffset(20.0), equals(-22.0));
        expect(info1.calculateOffset(20.0), equals(0.0));
        expect(info2.calculateOffset(20.0), equals(22.0));
      });
    });
  });
}
