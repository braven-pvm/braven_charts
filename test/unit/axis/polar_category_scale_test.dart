import 'dart:math' as math;

import 'package:braven_charts/src/axis/polar_category_scale.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarCategoryScale', () {
    test('allocates equal bands across a complete pane', () {
      final scale = PolarCategoryScale(
        pane: RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        ),
        categories: const ['North', 'East', 'South', 'West'],
      );

      expect(scale.stepAngle, closeTo(math.pi / 2, 1e-12));
      expect(scale.bandSweepAngle, closeTo(math.pi / 2, 1e-12));
      expect(scale.bands, hasLength(4));
      expect(scale.bandAt(0).startAngle, closeTo(-math.pi / 2, 1e-12));
      expect(scale.bandAt(0).centerAngle, closeTo(-math.pi / 4, 1e-12));
      expect(scale.bandAt(3).startAngle, closeTo(math.pi, 1e-12));
      expect(scale.bandAt(3).endAngle, closeTo(math.pi * 1.5, 1e-12));
      expect(scale.bandForCategory('South'), same(scale.bandAt(2)));
    });

    test('resolves inner and outer padding as fractions of one step', () {
      final scale = PolarCategoryScale(
        pane: RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          startAngle: 0,
          sweepAngle: math.pi,
        ),
        categories: const ['A', 'B', 'C'],
        innerPadding: 0.2,
        outerPadding: 0.1,
      );

      expect(scale.stepAngle, closeTo(math.pi / 3, 1e-12));
      expect(scale.bandSweepAngle, closeTo(math.pi / 3 * 0.8, 1e-12));
      expect(scale.bandAt(0).startAngle, closeTo(math.pi / 30, 1e-12));
      expect(
        scale.bandAt(1).startAngle - scale.bandAt(0).endAngle,
        closeTo(math.pi / 15, 1e-12),
      );
      expect(math.pi - scale.bandAt(2).endAngle, closeTo(math.pi / 30, 1e-12));
    });

    test('uses signed counter-clockwise bands and inverse lookup', () {
      final scale = PolarCategoryScale(
        pane: RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          startAngle: 0,
          sweepAngle: math.pi,
          clockwise: false,
        ),
        categories: const ['A', 'B'],
      );

      expect(scale.bandAt(0).sweepAngle, closeTo(-math.pi / 2, 1e-12));
      expect(scale.bandAt(0).centerAngle, closeTo(-math.pi / 4, 1e-12));
      expect(scale.indexForAngle(-math.pi / 4), 0);
      expect(scale.categoryForAngle(-math.pi * 3 / 4), 'B');
      expect(scale.indexForAngle(math.pi / 4), isNull);
    });

    test(
      'inverse lookup rejects padding and preserves the full-sweep seam',
      () {
        final pane = RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          startAngle: 0,
          sweepAngle: math.pi * 2,
        );
        final scale = PolarCategoryScale(
          pane: pane,
          categories: const ['A', 'B'],
          innerPadding: 0.2,
        );
        final first = scale.bandAt(0);
        final gapAngle = first.endAngle + scale.stepAngle * 0.1;

        expect(scale.indexForAngle(first.centerAngle), 0);
        expect(scale.indexForAngle(gapAngle), isNull);
        expect(scale.indexForAngle(pane.startAngle), 0);
        expect(scale.indexForAngle(pane.endAngle), 0);
      },
    );

    test('one category ignores meaningless inner padding', () {
      final scale = PolarCategoryScale(
        pane: RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          startAngle: 0,
          sweepAngle: math.pi,
        ),
        categories: const ['Only'],
        innerPadding: 0.8,
        outerPadding: 0.25,
      );

      expect(scale.stepAngle, closeTo(math.pi / 1.5, 1e-12));
      expect(scale.bandSweepAngle, closeTo(scale.stepAngle, 1e-12));
      expect(scale.bandAt(0).centerAngle, closeTo(math.pi / 2, 1e-12));
    });

    test('rejects empty, ambiguous, or invalid category configuration', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
      );

      expect(
        () => PolarCategoryScale(pane: pane, categories: const []),
        throwsArgumentError,
      );
      expect(
        () => PolarCategoryScale(pane: pane, categories: const ['A', 'A']),
        throwsArgumentError,
      );
      expect(
        () => PolarCategoryScale(pane: pane, categories: const ['A', '  ']),
        throwsArgumentError,
      );
      expect(
        () => PolarCategoryScale(
          pane: pane,
          categories: const ['A'],
          innerPadding: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarCategoryScale(
          pane: pane,
          categories: const ['A'],
          outerPadding: double.nan,
        ),
        throwsArgumentError,
      );
      expect(() => scaleWithInvalidIndex(pane), throwsRangeError);
    });
  });
}

void scaleWithInvalidIndex(RadialPaneGeometry pane) {
  PolarCategoryScale(pane: pane, categories: const ['A']).bandAt(1);
}
