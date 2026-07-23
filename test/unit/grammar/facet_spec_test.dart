// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Value semantics and scale-sharing rules for [FacetSpec] / [FacetScales].
///
/// Like [Mark], a [FacetSpec] holds an accessor function, so it has value
/// equality (the accessor compared by IDENTITY) and NO copyWith — it never
/// enters the config surface. Accessors are top-level tear-offs so equality is
/// stable.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.zone});
  final String zone;
}

Object? sampleZone(Sample row) => row.zone;
Object? sampleOther(Sample row) => row.zone.length;

void main() {
  group('scale sharing', () {
    test('sharesX is true only for fixed and freeY', () {
      expect(FacetScales.fixed.sharesX, isTrue);
      expect(FacetScales.freeY.sharesX, isTrue);
      expect(FacetScales.freeX.sharesX, isFalse);
      expect(FacetScales.free.sharesX, isFalse);
    });

    test('sharesY is true only for fixed and freeX', () {
      expect(FacetScales.fixed.sharesY, isTrue);
      expect(FacetScales.freeX.sharesY, isTrue);
      expect(FacetScales.freeY.sharesY, isFalse);
      expect(FacetScales.free.sharesY, isFalse);
    });

    test('syncsInteraction mirrors sharesX', () {
      for (final scales in FacetScales.values) {
        expect(scales.syncsInteraction, scales.sharesX);
      }
    });
  });

  group('value semantics', () {
    test('defaults to fixed scales and null columns/label', () {
      const spec = FacetSpec<Sample>(by: sampleZone);
      expect(spec.scales, FacetScales.fixed);
      expect(spec.columns, isNull);
      expect(spec.label, isNull);
    });

    test('two facet specs over the same tear-off are equal', () {
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone'),
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone'),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone')
            .hashCode,
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone')
            .hashCode,
      );
    });

    test('a different accessor, columns, scales or label is not equal', () {
      expect(
        const FacetSpec<Sample>(by: sampleZone),
        isNot(const FacetSpec<Sample>(by: sampleOther)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2),
        isNot(const FacetSpec<Sample>(by: sampleZone, columns: 3)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
        isNot(const FacetSpec<Sample>(by: sampleZone)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, label: 'Zone'),
        isNot(const FacetSpec<Sample>(by: sampleZone, label: 'Athlete')),
      );
    });
  });
}
