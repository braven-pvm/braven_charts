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
      // Built at RUNTIME (no `const`) so the two are DISTINCT instances.
      // Dart canonicalizes identical const expressions to the same object, so
      // a const-vs-const `expect(a, b)` passes on identity even with no custom
      // operator== — it would stay green if operator==/hashCode were deleted.
      // Distinct runtime instances force identity and value equality to
      // diverge, so a passing assertion genuinely exercises value equality.
      final a = FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone');
      final b = FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone');
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different accessor, columns, scales or label is not equal', () {
      // Runtime-built (no `const`) so each `isNot` genuinely invokes
      // operator==: a value-equality bug that dropped one of these fields would
      // make the pair compare equal and fail the assertion. Const canonical
      // instances would instead pass trivially on identity, guarding nothing.
      expect(
        FacetSpec<Sample>(by: sampleZone),
        isNot(FacetSpec<Sample>(by: sampleOther)),
      );
      expect(
        FacetSpec<Sample>(by: sampleZone, columns: 2),
        isNot(FacetSpec<Sample>(by: sampleZone, columns: 3)),
      );
      expect(
        FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
        isNot(FacetSpec<Sample>(by: sampleZone)),
      );
      expect(
        FacetSpec<Sample>(by: sampleZone, label: 'Zone'),
        isNot(FacetSpec<Sample>(by: sampleZone, label: 'Athlete')),
      );
    });
  });
}
