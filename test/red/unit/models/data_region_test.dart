// @orchestra-task: 1
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';

void main() {
  group('DataRegionSource', () {
    test('has rangeAnnotation value', () {
      expect(DataRegionSource.rangeAnnotation, isNotNull);
    });

    test('has segment value', () {
      expect(DataRegionSource.segment, isNotNull);
    });

    test('has boxSelect value', () {
      expect(DataRegionSource.boxSelect, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(DataRegionSource.values, hasLength(3));
    });

    test('values contain all expected sources', () {
      expect(
        DataRegionSource.values,
        containsAll([
          DataRegionSource.rangeAnnotation,
          DataRegionSource.segment,
          DataRegionSource.boxSelect,
        ]),
      );
    });
  });

  group('DataRegion constructor', () {
    test('creates instance with required parameters', () {
      final region = DataRegion(
        id: 'test-region-1',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region.id, equals('test-region-1'));
      expect(region.startX, equals(10.0));
      expect(region.endX, equals(20.0));
      expect(region.source, equals(DataRegionSource.rangeAnnotation));
      expect(region.seriesData, isEmpty);
    });

    test('creates instance with optional label', () {
      final region = DataRegion(
        id: 'test-region-2',
        label: 'My Region',
        startX: 5.0,
        endX: 15.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      expect(region.label, equals('My Region'));
    });

    test('label defaults to null when not provided', () {
      final region = DataRegion(
        id: 'test-region-3',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region.label, isNull);
    });

    test('creates instance with seriesData containing data points', () {
      final points = [
        const ChartDataPoint(x: 5.0, y: 10.0),
        const ChartDataPoint(x: 7.0, y: 15.0),
      ];
      final region = DataRegion(
        id: 'data-region',
        startX: 4.0,
        endX: 8.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: {'series-1': points},
      );

      expect(region.seriesData, hasLength(1));
      expect(region.seriesData['series-1'], equals(points));
    });

    test('creates instance with multiple series in seriesData', () {
      final region = DataRegion(
        id: 'multi-series-region',
        startX: 0.0,
        endX: 100.0,
        source: DataRegionSource.segment,
        seriesData: {
          'series-a': [const ChartDataPoint(x: 10.0, y: 20.0)],
          'series-b': [const ChartDataPoint(x: 30.0, y: 40.0)],
          'series-c': [const ChartDataPoint(x: 50.0, y: 60.0)],
        },
      );

      expect(region.seriesData, hasLength(3));
    });
  });

  group('DataRegion validation', () {
    test('allows startX equal to endX (zero-width region)', () {
      final region = DataRegion(
        id: 'zero-width',
        startX: 10.0,
        endX: 10.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region.startX, equals(region.endX));
    });

    test('throws when startX is greater than endX', () {
      expect(
        () => DataRegion(
          id: 'invalid-range',
          startX: 20.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: const {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when id is empty string', () {
      expect(
        () => DataRegion(
          id: '',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.segment,
          seriesData: const {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows valid id with non-empty string', () {
      final region = DataRegion(
        id: 'a',
        startX: 0.0,
        endX: 1.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region.id, equals('a'));
    });

    test('allows negative X values as long as startX <= endX', () {
      final region = DataRegion(
        id: 'negative-range',
        startX: -20.0,
        endX: -5.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region.startX, equals(-20.0));
      expect(region.endX, equals(-5.0));
    });
  });

  group('DataRegion equality', () {
    test('two regions with same id, startX, endX, source are equal', () {
      final region1 = DataRegion(
        id: 'region-eq',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-eq',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region1, equals(region2));
    });

    test('equal regions have same hashCode', () {
      final region1 = DataRegion(
        id: 'region-hash',
        startX: 5.0,
        endX: 15.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-hash',
        startX: 5.0,
        endX: 15.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      expect(region1.hashCode, equals(region2.hashCode));
    });

    test('equality excludes seriesData (derived data)', () {
      final region1 = DataRegion(
        id: 'region-data',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.boxSelect,
        seriesData: {
          'series-1': [const ChartDataPoint(x: 5.0, y: 10.0)],
        },
      );
      final region2 = DataRegion(
        id: 'region-data',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region1, equals(region2));
    });

    test('equality excludes label', () {
      final region1 = DataRegion(
        id: 'region-label',
        label: 'Label A',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-label',
        label: 'Label B',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region1, equals(region2));
    });

    test('different id produces inequality', () {
      final region1 = DataRegion(
        id: 'region-1',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-2',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region1, isNot(equals(region2)));
    });

    test('different startX produces inequality', () {
      final region1 = DataRegion(
        id: 'region-sx',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-sx',
        startX: 11.0,
        endX: 20.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      expect(region1, isNot(equals(region2)));
    });

    test('different endX produces inequality', () {
      final region1 = DataRegion(
        id: 'region-ex',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-ex',
        startX: 10.0,
        endX: 25.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region1, isNot(equals(region2)));
    });

    test('different source produces inequality', () {
      final region1 = DataRegion(
        id: 'region-src',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );
      final region2 = DataRegion(
        id: 'region-src',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      expect(region1, isNot(equals(region2)));
    });
  });

  group('DataRegion copyWith', () {
    late DataRegion original;

    setUp(() {
      original = DataRegion(
        id: 'original',
        label: 'Original Label',
        startX: 10.0,
        endX: 20.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: {
          'series-1': [const ChartDataPoint(x: 12.0, y: 30.0)],
        },
      );
    });

    test('creates identical copy when no parameters provided', () {
      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.label, equals(original.label));
      expect(copy.startX, equals(original.startX));
      expect(copy.endX, equals(original.endX));
      expect(copy.source, equals(original.source));
      expect(copy.seriesData, equals(original.seriesData));
    });

    test('creates copy with overridden id', () {
      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, equals('new-id'));
      expect(copy.startX, equals(original.startX));
      expect(copy.endX, equals(original.endX));
    });

    test('creates copy with overridden label', () {
      final copy = original.copyWith(label: 'New Label');

      expect(copy.label, equals('New Label'));
      expect(copy.id, equals(original.id));
    });

    test('creates copy with overridden startX', () {
      final copy = original.copyWith(startX: 5.0);

      expect(copy.startX, equals(5.0));
      expect(copy.endX, equals(original.endX));
    });

    test('creates copy with overridden endX', () {
      final copy = original.copyWith(endX: 30.0);

      expect(copy.endX, equals(30.0));
      expect(copy.startX, equals(original.startX));
    });

    test('creates copy with overridden source', () {
      final copy = original.copyWith(source: DataRegionSource.boxSelect);

      expect(copy.source, equals(DataRegionSource.boxSelect));
      expect(copy.id, equals(original.id));
    });

    test('creates copy with overridden seriesData', () {
      final newData = {
        'series-2': [const ChartDataPoint(x: 15.0, y: 50.0)],
      };
      final copy = original.copyWith(seriesData: newData);

      expect(copy.seriesData, equals(newData));
      expect(copy.id, equals(original.id));
    });

    test('creates copy with multiple overrides', () {
      final copy = original.copyWith(
        id: 'modified',
        startX: 0.0,
        endX: 50.0,
        source: DataRegionSource.segment,
      );

      expect(copy.id, equals('modified'));
      expect(copy.startX, equals(0.0));
      expect(copy.endX, equals(50.0));
      expect(copy.source, equals(DataRegionSource.segment));
      expect(copy.label, equals(original.label));
    });

    test('copy is not identical to original', () {
      final copy = original.copyWith();

      expect(identical(copy, original), isFalse);
    });
  });

  group('DataRegion edge cases', () {
    test('handles very large X values', () {
      final region = DataRegion(
        id: 'large-values',
        startX: 1e15,
        endX: 1e16,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      expect(region.startX, equals(1e15));
      expect(region.endX, equals(1e16));
    });

    test('handles very small X values', () {
      final region = DataRegion(
        id: 'small-values',
        startX: 1e-15,
        endX: 1e-14,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      expect(region.startX, equals(1e-15));
      expect(region.endX, equals(1e-14));
    });

    test('works with all DataRegionSource values', () {
      for (final source in DataRegionSource.values) {
        final region = DataRegion(
          id: 'source-${source.name}',
          startX: 0.0,
          endX: 10.0,
          source: source,
          seriesData: const {},
        );
        expect(region.source, equals(source));
      }
    });

    test('empty seriesData map is valid', () {
      final region = DataRegion(
        id: 'empty-data',
        startX: 0.0,
        endX: 10.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      expect(region.seriesData, isEmpty);
    });
  });
}
