// @orchestra-task: 3

// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

@Tags(['tdd-red'])
library;

import 'package:braven_charts/src/models/bar_group_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarGroupInfo', () {
    group('Gap Parameter (FR-003)', () {
      test('gap defaults to 2.0 pixels when not specified', () {
        const info = BarGroupInfo(index: 0, count: 3);
        expect(info.gap, equals(2.0),
            reason: 'FR-003 specifies default gap of 2.0 pixels');
      });

      test('custom gap value is respected in construction', () {
        const info = BarGroupInfo(index: 0, count: 3, gap: 4.0);
        expect(info.gap, equals(4.0));
      });

      test('gap can be zero', () {
        const info = BarGroupInfo(index: 0, count: 3, gap: 0.0);
        expect(info.gap, equals(0.0));
      });

      test('gap must be non-negative', () {
        expect(
          () => BarGroupInfo(index: 0, count: 3, gap: -1.0),
          throwsA(isA<AssertionError>()),
          reason: 'Negative gaps are invalid',
        );
      });
    });

    group('Bar Width Calculation', () {
      test('calculateOffset with single bar series (count=1)', () {
        const info = BarGroupInfo(index: 0, count: 1, gap: 2.0);
        final offset = info.calculateOffset(20.0);

        // Single bar: effectiveWidth = 20 + 2 = 22
        // totalWidth = 22 * 1 - 2 = 20
        // startOffset = -20/2 + 20/2 = 0
        // offset = 0 + 0 * 22 = 0
        expect(offset, equals(0.0),
            reason: 'Single bar should be centered at 0');
      });

      test('calculateOffset with two bar series produces symmetric offsets',
          () {
        const info0 = BarGroupInfo(index: 0, count: 2, gap: 2.0);
        const info1 = BarGroupInfo(index: 1, count: 2, gap: 2.0);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);

        // Two bars: effectiveWidth = 20 + 2 = 22
        // totalWidth = 22 * 2 - 2 = 42
        // startOffset = -42/2 + 20/2 = -11
        // offset0 = -11 + 0 * 22 = -11
        // offset1 = -11 + 1 * 22 = 11
        expect(offset0, equals(-11.0));
        expect(offset1, equals(11.0));
        expect(offset0 + offset1, equals(0.0),
            reason: 'Two bars should be symmetric around center');
      });

      test(
          'calculateOffset with three bar series (as documented in BarGroupInfo)',
          () {
        const info0 = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 2, count: 3, gap: 2.0);

        final offset0 = info0.calculateOffset(20.0);
        final offset1 = info1.calculateOffset(20.0);
        final offset2 = info2.calculateOffset(20.0);

        // Three bars: effectiveWidth = 20 + 2 = 22
        // totalWidth = 22 * 3 - 2 = 64
        // startOffset = -64/2 + 20/2 = -22
        // offset0 = -22 + 0 * 22 = -22
        // offset1 = -22 + 1 * 22 = 0
        // offset2 = -22 + 2 * 22 = 22
        expect(offset0, equals(-22.0));
        expect(offset1, equals(0.0));
        expect(offset2, equals(22.0));
      });

      test('calculateOffset with five bar series', () {
        final offsets = <double>[];
        for (int i = 0; i < 5; i++) {
          final info = BarGroupInfo(index: i, count: 5, gap: 2.0);
          offsets.add(info.calculateOffset(20.0));
        }

        // Five bars: effectiveWidth = 20 + 2 = 22
        // totalWidth = 22 * 5 - 2 = 108
        // startOffset = -108/2 + 20/2 = -44
        // offsets: -44, -22, 0, 22, 44
        expect(offsets[0], equals(-44.0));
        expect(offsets[1], equals(-22.0));
        expect(offsets[2], equals(0.0));
        expect(offsets[3], equals(22.0));
        expect(offsets[4], equals(44.0));

        // Middle bar should always be at center
        expect(offsets[2], equals(0.0),
            reason: 'Middle bar of odd count should be centered');
      });

      test('calculateOffset respects custom gap values', () {
        // With gap = 0 (no spacing)
        const info0NoGap = BarGroupInfo(index: 0, count: 3, gap: 0.0);
        const info1NoGap = BarGroupInfo(index: 1, count: 3, gap: 0.0);
        const info2NoGap = BarGroupInfo(index: 2, count: 3, gap: 0.0);

        final offset0NoGap = info0NoGap.calculateOffset(20.0);
        final offset1NoGap = info1NoGap.calculateOffset(20.0);
        final offset2NoGap = info2NoGap.calculateOffset(20.0);

        // effectiveWidth = 20 + 0 = 20
        // totalWidth = 20 * 3 - 0 = 60
        // startOffset = -60/2 + 20/2 = -20
        expect(offset0NoGap, equals(-20.0));
        expect(offset1NoGap, equals(0.0));
        expect(offset2NoGap, equals(20.0));

        // With gap = 4.0 (double default)
        const info0BigGap = BarGroupInfo(index: 0, count: 3, gap: 4.0);
        const info1BigGap = BarGroupInfo(index: 1, count: 3, gap: 4.0);
        const info2BigGap = BarGroupInfo(index: 2, count: 3, gap: 4.0);

        final offset0BigGap = info0BigGap.calculateOffset(20.0);
        final offset1BigGap = info1BigGap.calculateOffset(20.0);
        final offset2BigGap = info2BigGap.calculateOffset(20.0);

        // effectiveWidth = 20 + 4 = 24
        // totalWidth = 24 * 3 - 4 = 68
        // startOffset = -68/2 + 20/2 = -24
        expect(offset0BigGap, equals(-24.0));
        expect(offset1BigGap, equals(0.0));
        expect(offset2BigGap, equals(24.0));

        // Verify larger gap produces larger spacing
        expect(
          (offset2BigGap - offset1BigGap).abs(),
          greaterThan((offset2NoGap - offset1NoGap).abs()),
          reason: 'Larger gap should produce larger spacing between bars',
        );
      });

      test('calculateOffset with different bar widths scales offsets correctly',
          () {
        const info0 = BarGroupInfo(index: 0, count: 2, gap: 2.0);
        const info1 = BarGroupInfo(index: 1, count: 2, gap: 2.0);

        // Test with narrow bars (10px)
        final offset0Narrow = info0.calculateOffset(10.0);
        final offset1Narrow = info1.calculateOffset(10.0);

        // effectiveWidth = 10 + 2 = 12
        // totalWidth = 12 * 2 - 2 = 22
        // startOffset = -22/2 + 10/2 = -6
        expect(offset0Narrow, equals(-6.0));
        expect(offset1Narrow, equals(6.0));

        // Test with wide bars (40px)
        final offset0Wide = info0.calculateOffset(40.0);
        final offset1Wide = info1.calculateOffset(40.0);

        // effectiveWidth = 40 + 2 = 42
        // totalWidth = 42 * 2 - 2 = 82
        // startOffset = -82/2 + 40/2 = -21
        expect(offset0Wide, equals(-21.0));
        expect(offset1Wide, equals(21.0));

        // Wider bars should produce larger offsets
        expect(offset1Wide.abs(), greaterThan(offset1Narrow.abs()));
      });
    });

    group('Equality and Hashing', () {
      test('equal BarGroupInfo instances are equal', () {
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 1, count: 3, gap: 2.0);

        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('different index produces inequality', () {
        const info1 = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 1, count: 3, gap: 2.0);

        expect(info1, isNot(equals(info2)));
      });

      test('different count produces inequality', () {
        const info1 = BarGroupInfo(index: 1, count: 2, gap: 2.0);
        const info2 = BarGroupInfo(index: 1, count: 3, gap: 2.0);

        expect(info1, isNot(equals(info2)));
      });

      test('different gap produces inequality', () {
        const info1 = BarGroupInfo(index: 1, count: 3, gap: 2.0);
        const info2 = BarGroupInfo(index: 1, count: 3, gap: 4.0);

        expect(info1, isNot(equals(info2)));
      });
    });

    group('CopyWith', () {
      test('copyWith creates new instance with updated fields', () {
        const original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
        final copied = original.copyWith(index: 1);

        expect(copied.index, equals(1));
        expect(copied.count, equals(3));
        expect(copied.gap, equals(2.0));
        expect(copied, isNot(same(original)));
      });

      test('copyWith with no parameters creates equal instance', () {
        const original = BarGroupInfo(index: 1, count: 3, gap: 4.0);
        final copied = original.copyWith();

        expect(copied, equals(original));
        expect(copied, isNot(same(original)));
      });
    });
  });
}
