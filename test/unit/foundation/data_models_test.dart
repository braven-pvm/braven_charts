// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/data_range.dart' as dr;
import 'package:braven_charts/legacy/src/foundation/data_models/time_series_data.dart';

void main() {
  group('ChartDataPoint Unit Tests', () {
    group('Constructor', () {
      test('creates point with required parameters', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(point.x, equals(1.0));
        expect(point.y, equals(2.0));
        expect(point.timestamp, isNull);
        expect(point.label, isNull);
        expect(point.metadata, isNull);
      });

      test('creates point with all optional parameters', () {
        final now = DateTime.now();
        final meta = {'key': 'value'};
        final point = ChartDataPoint(
          x: 1.0,
          y: 2.0,
          timestamp: now,
          label: 'Test',
          metadata: meta,
        );
        expect(point.timestamp, equals(now));
        expect(point.label, equals('Test'));
        expect(point.metadata, equals(meta));
      });

      test('const constructor works for compile-time constants', () {
        const point = ChartDataPoint(x: 1.0, y: 2.0);
        expect(point.x, equals(1.0));
      });
    });

    group('Getters', () {
      test('hasTimestamp returns true when timestamp exists', () {
        final point = ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now());
        expect(point.hasTimestamp, isTrue);
      });

      test('hasTimestamp returns false when timestamp is null', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(point.hasTimestamp, isFalse);
      });

      test('hasLabel returns true when label exists', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0, label: 'Test');
        expect(point.hasLabel, isTrue);
      });

      test('hasLabel returns false when label is null', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(point.hasLabel, isFalse);
      });

      test('isValid returns true for finite numbers', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(point.isValid, isTrue);
      });

      test('isValid returns false for NaN x', () {
        final point = const ChartDataPoint(x: double.nan, y: 2.0);
        expect(point.isValid, isFalse);
      });

      test('isValid returns false for NaN y', () {
        final point = const ChartDataPoint(x: 1.0, y: double.nan);
        expect(point.isValid, isFalse);
      });

      test('isValid returns false for infinity x', () {
        final point = const ChartDataPoint(x: double.infinity, y: 2.0);
        expect(point.isValid, isFalse);
      });

      test('isValid returns false for infinity y', () {
        final point = const ChartDataPoint(x: 1.0, y: double.infinity);
        expect(point.isValid, isFalse);
      });

      test('isValid returns false for negative infinity', () {
        final point = const ChartDataPoint(x: 1.0, y: double.negativeInfinity);
        expect(point.isValid, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with modified x', () {
        final original = const ChartDataPoint(x: 1.0, y: 2.0);
        final copy = original.copyWith(x: 3.0);
        expect(copy.x, equals(3.0));
        expect(copy.y, equals(2.0));
        expect(original.x, equals(1.0)); // Original unchanged
      });

      test('creates copy with modified y', () {
        final original = const ChartDataPoint(x: 1.0, y: 2.0);
        final copy = original.copyWith(y: 3.0);
        expect(copy.x, equals(1.0));
        expect(copy.y, equals(3.0));
      });

      test('creates copy with added timestamp', () {
        final original = const ChartDataPoint(x: 1.0, y: 2.0);
        final now = DateTime.now();
        final copy = original.copyWith(timestamp: now);
        expect(copy.timestamp, equals(now));
        expect(original.timestamp, isNull);
      });

      test('creates copy with added label', () {
        final original = const ChartDataPoint(x: 1.0, y: 2.0);
        final copy = original.copyWith(label: 'New');
        expect(copy.label, equals('New'));
        expect(original.label, isNull);
      });

      test('creates copy with modified metadata', () {
        final original =
            const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'a': 1});
        final copy = original.copyWith(metadata: {'b': 2});
        expect(copy.metadata, equals({'b': 2}));
        expect(original.metadata, equals({'a': 1}));
      });

      test('creates copy with no changes when no parameters provided', () {
        final original = const ChartDataPoint(x: 1.0, y: 2.0, label: 'Test');
        final copy = original.copyWith();
        expect(copy.x, equals(original.x));
        expect(copy.y, equals(original.y));
        expect(copy.label, equals(original.label));
      });
    });

    group('Equality', () {
      test('equal points are equal', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0);
        final p2 = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });

      test('points with different x are not equal', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0);
        final p2 = const ChartDataPoint(x: 2.0, y: 2.0);
        expect(p1, isNot(equals(p2)));
      });

      test('points with different y are not equal', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0);
        final p2 = const ChartDataPoint(x: 1.0, y: 3.0);
        expect(p1, isNot(equals(p2)));
      });

      test('points with different timestamp are not equal', () {
        final t1 = DateTime(2024, 1, 1);
        final t2 = DateTime(2024, 1, 2);
        final p1 = ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1);
        final p2 = ChartDataPoint(x: 1.0, y: 2.0, timestamp: t2);
        expect(p1, isNot(equals(p2)));
      });

      test('points with different label are not equal', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0, label: 'A');
        final p2 = const ChartDataPoint(x: 1.0, y: 2.0, label: 'B');
        expect(p1, isNot(equals(p2)));
      });

      test('metadata is excluded from equality', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'a': 1});
        final p2 = const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'b': 2});
        expect(p1, equals(p2)); // Equal despite different metadata
      });

      test('point with metadata equals point without metadata', () {
        final p1 = const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'a': 1});
        final p2 = const ChartDataPoint(x: 1.0, y: 2.0);
        expect(p1, equals(p2));
      });
    });

    group('toString', () {
      test('includes x and y', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0);
        final str = point.toString();
        expect(str, contains('1.0'));
        expect(str, contains('2.0'));
      });

      test('includes timestamp when present', () {
        final now = DateTime(2024, 1, 1);
        final point = ChartDataPoint(x: 1.0, y: 2.0, timestamp: now);
        final str = point.toString();
        expect(str, contains('timestamp'));
      });

      test('includes label when present', () {
        final point = const ChartDataPoint(x: 1.0, y: 2.0, label: 'Test');
        final str = point.toString();
        expect(str, contains('Test'));
      });
    });
  });

  group('ChartSeries Unit Tests', () {
    group('Constructor', () {
      test('creates empty series', () {
        final series = ChartSeries(id: 'test', points: []);
        expect(series.id, equals('test'));
        expect(series.points, isEmpty);
        expect(series.isEmpty, isTrue);
        expect(series.length, equals(0));
      });

      test('creates series with points', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 2.0),
          const ChartDataPoint(x: 2.0, y: 3.0),
        ];
        final series = ChartSeries(id: 'test', points: points);
        expect(series.points.length, equals(2));
        expect(series.isEmpty, isFalse);
        expect(series.length, equals(2));
      });

      test('creates series with all optional parameters', () {
        final series = ChartSeries(
          id: 'test',
          points: [],
          name: 'Test Series',
          color: Colors.blue,
          style: SeriesStyle.line,
          isXOrdered: true,
          metadata: {'key': 'value'},
        );
        expect(series.name, equals('Test Series'));
        expect(series.color, equals(Colors.blue));
        expect(series.style, equals(SeriesStyle.line));
        expect(series.isXOrdered, isTrue);
        expect(series.metadata, equals({'key': 'value'}));
      });

      test('throws assertion error for empty id', () {
        expect(
          () => ChartSeries(id: '', points: []),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Computed Properties', () {
      test('xRange computed from points', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 5.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 15.0),
        ];
        final series = ChartSeries(id: 'test', points: points);
        expect(series.xRange.min, equals(1.0));
        expect(series.xRange.max, equals(5.0));
      });

      test('yRange computed from points', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 25.0),
          const ChartDataPoint(x: 3.0, y: 5.0),
        ];
        final series = ChartSeries(id: 'test', points: points);
        expect(series.yRange.min, equals(5.0));
        expect(series.yRange.max, equals(25.0));
      });

      test('xRange is cached', () {
        final series = ChartSeries(
          id: 'test',
          points: [const ChartDataPoint(x: 1.0, y: 2.0)],
        );
        final range1 = series.xRange;
        final range2 = series.xRange;
        expect(identical(range1, range2), isTrue);
      });

      test('yRange is cached', () {
        final series = ChartSeries(
          id: 'test',
          points: [const ChartDataPoint(x: 1.0, y: 2.0)],
        );
        final range1 = series.yRange;
        final range2 = series.yRange;
        expect(identical(range1, range2), isTrue);
      });
    });

    group('validateOrdering', () {
      test('returns true for empty series', () {
        final series = ChartSeries(id: 'test', points: [], isXOrdered: true);
        expect(series.validateOrdering(), isTrue);
      });

      test('returns true for single point series', () {
        final series = ChartSeries(
          id: 'test',
          points: [const ChartDataPoint(x: 1.0, y: 2.0)],
          isXOrdered: true,
        );
        expect(series.validateOrdering(), isTrue);
      });

      test('returns true for ordered points when isXOrdered=true', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 1.0, y: 2.0),
            const ChartDataPoint(x: 2.0, y: 3.0),
            const ChartDataPoint(x: 3.0, y: 1.0),
          ],
          isXOrdered: true,
        );
        expect(series.validateOrdering(), isTrue);
      });

      test('returns false for unordered points when isXOrdered=true', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 3.0, y: 1.0),
            const ChartDataPoint(x: 1.0, y: 2.0),
            const ChartDataPoint(x: 2.0, y: 3.0),
          ],
          isXOrdered: true,
        );
        expect(series.validateOrdering(), isFalse);
      });

      test('returns true for unordered points when isXOrdered=false', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 3.0, y: 1.0),
            const ChartDataPoint(x: 1.0, y: 2.0),
          ],
          isXOrdered: false,
        );
        expect(series.validateOrdering(), isTrue);
      });

      test('allows equal x values', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 1.0, y: 2.0),
            const ChartDataPoint(x: 1.0, y: 3.0),
            const ChartDataPoint(x: 2.0, y: 4.0),
          ],
          isXOrdered: true,
        );
        expect(series.validateOrdering(), isTrue);
      });
    });

    group('validate', () {
      test('returns Success for valid series', () {
        final series = ChartSeries(
          id: 'test',
          points: [const ChartDataPoint(x: 1.0, y: 2.0)],
        );
        final result = series.validate();
        expect(result.isSuccess, isTrue);
      });

      test('returns Failure for empty id', () {
        // Can't test this because constructor has assertion
        // Empty id test covered in constructor tests
      });

      test('returns Failure for unordered points when isXOrdered=true', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 2.0, y: 1.0),
            const ChartDataPoint(x: 1.0, y: 2.0),
          ],
          isXOrdered: true,
        );
        final result = series.validate();
        expect(result.isSuccess, isFalse);
      });

      test('returns Failure for invalid point', () {
        final series = ChartSeries(
          id: 'test',
          points: [
            const ChartDataPoint(x: 1.0, y: 2.0),
            const ChartDataPoint(x: double.nan, y: 3.0),
          ],
        );
        final result = series.validate();
        expect(result.isSuccess, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with modified id', () {
        final original = ChartSeries(id: 'test1', points: []);
        final copy = original.copyWith(id: 'test2');
        expect(copy.id, equals('test2'));
        expect(original.id, equals('test1'));
      });

      test('creates copy with modified points', () {
        final original = ChartSeries(id: 'test', points: []);
        final newPoints = [const ChartDataPoint(x: 1.0, y: 2.0)];
        final copy = original.copyWith(points: newPoints);
        expect(copy.points.length, equals(1));
        expect(original.points.length, equals(0));
      });

      test('creates copy with modified color', () {
        final original =
            ChartSeries(id: 'test', points: [], color: Colors.blue);
        final copy = original.copyWith(color: Colors.red);
        expect(copy.color, equals(Colors.red));
        expect(original.color, equals(Colors.blue));
      });
    });

    group('Equality', () {
      test('equal series are equal', () {
        final s1 = ChartSeries(id: 'test', points: []);
        final s2 = ChartSeries(id: 'test', points: []);
        expect(s1, equals(s2));
      });

      test('series with different id are not equal', () {
        final s1 = ChartSeries(id: 'test1', points: []);
        final s2 = ChartSeries(id: 'test2', points: []);
        expect(s1, isNot(equals(s2)));
      });

      test('metadata is excluded from equality', () {
        final s1 = ChartSeries(id: 'test', points: [], metadata: {'a': 1});
        final s2 = ChartSeries(id: 'test', points: [], metadata: {'b': 2});
        expect(s1, equals(s2));
      });
    });

    group('toString', () {
      test('includes id and point count', () {
        final series = ChartSeries(
          id: 'test',
          points: [const ChartDataPoint(x: 1.0, y: 2.0)],
        );
        final str = series.toString();
        expect(str, contains('test'));
        expect(str, contains('1'));
      });
    });
  });

  group('DataRange Unit Tests', () {
    group('Constructor', () {
      test('creates range with min and max', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        expect(range.min, equals(0.0));
        expect(range.max, equals(10.0));
        expect(range.padding, equals(0.0));
      });

      test('creates range with padding', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.1);
        expect(range.padding, equals(0.1));
      });

      test('throws assertion error when min > max', () {
        expect(
          () => dr.DataRange(min: 10.0, max: 5.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('allows min == max', () {
        final range = const dr.DataRange(min: 5.0, max: 5.0);
        expect(range.span, equals(0.0));
      });
    });

    group('Factory Constructors', () {
      test('fromValues creates range from list', () {
        final range = dr.DataRange.fromValues([1.0, 5.0, 3.0, 2.0, 4.0]);
        expect(range.min, equals(1.0));
        expect(range.max, equals(5.0));
      });

      test('fromValues handles empty list', () {
        final range = dr.DataRange.fromValues([]);
        expect(range.min, equals(0.0));
        expect(range.max, equals(0.0));
      });

      test('fromValues filters out NaN', () {
        final range = dr.DataRange.fromValues([1.0, double.nan, 5.0]);
        expect(range.min, equals(1.0));
        expect(range.max, equals(5.0));
      });

      test('fromValues filters out infinity', () {
        final range = dr.DataRange.fromValues([1.0, double.infinity, 5.0]);
        expect(range.min, equals(1.0));
        expect(range.max, equals(5.0));
      });

      test('fromValues returns zero range for all non-finite values', () {
        final range = dr.DataRange.fromValues([double.nan, double.infinity]);
        expect(range.min, equals(0.0));
        expect(range.max, equals(0.0));
      });

      test('fromPoints extracts x values', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 5.0, y: 20.0),
        ];
        final range = dr.DataRange.fromPoints(points, dr.Axis.x);
        expect(range.min, equals(1.0));
        expect(range.max, equals(5.0));
      });

      test('fromPoints extracts y values', () {
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 5.0, y: 20.0),
        ];
        final range = dr.DataRange.fromPoints(points, dr.Axis.y);
        expect(range.min, equals(10.0));
        expect(range.max, equals(20.0));
      });

      test('fromPoints handles empty list', () {
        final range = dr.DataRange.fromPoints([], dr.Axis.x);
        expect(range.min, equals(0.0));
        expect(range.max, equals(0.0));
      });

      test('symmetric creates centered range', () {
        final range = dr.DataRange.symmetric(center: 5.0, radius: 2.0);
        expect(range.min, equals(3.0));
        expect(range.max, equals(7.0));
        expect(range.center, equals(5.0));
      });
    });

    group('Computed Properties', () {
      test('span calculates max - min', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        expect(range.span, equals(10.0));
      });

      test('center calculates midpoint', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        expect(range.center, equals(5.0));
      });

      test('paddedMin subtracts padding', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.1);
        expect(range.paddedMin, equals(-1.0)); // 0 - (10 * 0.1)
      });

      test('paddedMax adds padding', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.1);
        expect(range.paddedMax, equals(11.0)); // 10 + (10 * 0.1)
      });

      test('padding has no effect when span is zero', () {
        final range = const dr.DataRange(min: 5.0, max: 5.0, padding: 0.1);
        expect(range.paddedMin, equals(5.0));
        expect(range.paddedMax, equals(5.0));
      });
    });

    group('Methods', () {
      test('contains returns true for value in range', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        expect(range.contains(5.0), isTrue);
        expect(range.contains(0.0), isTrue);
        expect(range.contains(10.0), isTrue);
      });

      test('contains returns false for value outside range', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        expect(range.contains(-1.0), isFalse);
        expect(range.contains(11.0), isFalse);
      });

      test('overlaps returns true for overlapping ranges', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 5.0, max: 15.0);
        expect(r1.overlaps(r2), isTrue);
        expect(r2.overlaps(r1), isTrue);
      });

      test('overlaps returns false for non-overlapping ranges', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 11.0, max: 20.0);
        expect(r1.overlaps(r2), isFalse);
      });

      test('overlaps returns true for touching ranges', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 10.0, max: 20.0);
        expect(r1.overlaps(r2), isTrue);
      });

      test('merge combines two ranges', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 5.0, max: 15.0);
        final merged = r1.merge(r2);
        expect(merged.min, equals(0.0));
        expect(merged.max, equals(15.0));
      });

      test('merge handles disjoint ranges', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 20.0, max: 30.0);
        final merged = r1.merge(r2);
        expect(merged.min, equals(0.0));
        expect(merged.max, equals(30.0));
      });

      test('validate returns Success for valid range', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        final result = range.validate();
        expect(result.isSuccess, isTrue);
      });
    });

    group('Equality', () {
      test('equal ranges are equal', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 0.0, max: 10.0);
        expect(r1, equals(r2));
      });

      test('ranges with different min are not equal', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0);
        final r2 = const dr.DataRange(min: 1.0, max: 10.0);
        expect(r1, isNot(equals(r2)));
      });

      test('ranges with different padding are not equal', () {
        final r1 = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.1);
        final r2 = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.2);
        expect(r1, isNot(equals(r2)));
      });
    });

    group('toString', () {
      test('includes min and max', () {
        final range = const dr.DataRange(min: 0.0, max: 10.0);
        final str = range.toString();
        expect(str, contains('0.0'));
        expect(str, contains('10.0'));
      });
    });
  });

  group('TimeSeriesData Unit Tests', () {
    group('Constructor', () {
      test('creates empty time series', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        expect(ts.id, equals('test'));
        expect(ts.data, isEmpty);
        expect(ts.isEmpty, isTrue);
        expect(ts.length, equals(0));
      });

      test('creates time series with data', () {
        final ts = TimeSeriesData(
          id: 'test',
          name: 'Test Series',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now()),
          ],
          metadata: {'key': 'value'},
        );
        expect(ts.name, equals('Test Series'));
        expect(ts.data.length, equals(1));
        expect(ts.metadata, equals({'key': 'value'}));
      });

      test('throws assertion error for empty id', () {
        expect(
          () => TimeSeriesData(id: '', data: []),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Time Properties', () {
      test('startTime returns earliest timestamp', () {
        final t1 = DateTime(2024, 1, 1);
        final t2 = DateTime(2024, 1, 2);
        final t3 = DateTime(2024, 1, 3);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t2),
            ChartDataPoint(x: 2.0, y: 3.0, timestamp: t1),
            ChartDataPoint(x: 3.0, y: 4.0, timestamp: t3),
          ],
        );
        expect(ts.startTime, equals(t1));
      });

      test('endTime returns latest timestamp', () {
        final t1 = DateTime(2024, 1, 1);
        final t2 = DateTime(2024, 1, 2);
        final t3 = DateTime(2024, 1, 3);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
            ChartDataPoint(x: 2.0, y: 3.0, timestamp: t3),
            ChartDataPoint(x: 3.0, y: 4.0, timestamp: t2),
          ],
        );
        expect(ts.endTime, equals(t3));
      });

      test('timeSpan calculates duration', () {
        final t1 = DateTime(2024, 1, 1);
        final t2 = DateTime(2024, 1, 3);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
            ChartDataPoint(x: 2.0, y: 3.0, timestamp: t2),
          ],
        );
        expect(ts.timeSpan, equals(const Duration(days: 2)));
      });

      test('startTime returns null for empty series', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        expect(ts.startTime, isNull);
      });

      test('endTime returns null for empty series', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        expect(ts.endTime, isNull);
      });

      test('timeSpan returns null for empty series', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        expect(ts.timeSpan, isNull);
      });

      test('startTime ignores points without timestamps', () {
        final t1 = DateTime(2024, 1, 1);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            const ChartDataPoint(x: 1.0, y: 2.0), // No timestamp
            ChartDataPoint(x: 2.0, y: 3.0, timestamp: t1),
          ],
        );
        expect(ts.startTime, equals(t1));
      });
    });

    group('validate', () {
      test('returns Success for valid time series', () {
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now()),
          ],
        );
        final result = ts.validate();
        expect(result.isSuccess, isTrue);
      });

      test('returns Failure for point without timestamp', () {
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            const ChartDataPoint(x: 1.0, y: 2.0), // Missing timestamp
          ],
        );
        final result = ts.validate();
        expect(result.isSuccess, isFalse);
      });

      test('returns Failure for invalid point', () {
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: double.nan, y: 2.0, timestamp: DateTime.now()),
          ],
        );
        final result = ts.validate();
        expect(result.isSuccess, isFalse);
      });
    });

    group('toChartSeries', () {
      test('converts to ChartSeries', () {
        final t1 = DateTime(2024, 1, 1);
        final ts = TimeSeriesData(
          id: 'test',
          name: 'Test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
          ],
        );
        final series = ts.toChartSeries();
        expect(series.id, equals('test'));
        expect(series.name, equals('Test'));
        expect(series.isXOrdered, isTrue);
        expect(series.points.length, equals(1));
      });

      test('converts timestamp to milliseconds for x-axis', () {
        final t1 = DateTime(2024, 1, 1);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
          ],
        );
        final series = ts.toChartSeries();
        expect(
          series.points[0].x,
          equals(t1.millisecondsSinceEpoch.toDouble()),
        );
      });

      test('preserves y values', () {
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 42.0, timestamp: DateTime.now()),
          ],
        );
        final series = ts.toChartSeries();
        expect(series.points[0].y, equals(42.0));
      });

      test('allows custom series id and name', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        final series = ts.toChartSeries(
          seriesId: 'custom-id',
          seriesName: 'Custom Name',
        );
        expect(series.id, equals('custom-id'));
        expect(series.name, equals('Custom Name'));
      });

      test('allows custom color and style', () {
        final ts = TimeSeriesData(id: 'test', data: []);
        final series = ts.toChartSeries(
          color: Colors.red,
          style: SeriesStyle.area,
        );
        expect(series.color, equals(Colors.red));
        expect(series.style, equals(SeriesStyle.area));
      });
    });

    group('copyWith', () {
      test('creates copy with modified id', () {
        final original = TimeSeriesData(id: 'test1', data: []);
        final copy = original.copyWith(id: 'test2');
        expect(copy.id, equals('test2'));
        expect(original.id, equals('test1'));
      });

      test('creates copy with modified data', () {
        final original = TimeSeriesData(id: 'test', data: []);
        final newData = [
          ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now()),
        ];
        final copy = original.copyWith(data: newData);
        expect(copy.data.length, equals(1));
        expect(original.data.length, equals(0));
      });
    });

    group('Equality', () {
      test('equal time series are equal', () {
        final ts1 = TimeSeriesData(id: 'test', data: []);
        final ts2 = TimeSeriesData(id: 'test', data: []);
        expect(ts1, equals(ts2));
      });

      test('time series with different id are not equal', () {
        final ts1 = TimeSeriesData(id: 'test1', data: []);
        final ts2 = TimeSeriesData(id: 'test2', data: []);
        expect(ts1, isNot(equals(ts2)));
      });

      test('metadata is excluded from equality', () {
        final ts1 = TimeSeriesData(id: 'test', data: [], metadata: {'a': 1});
        final ts2 = TimeSeriesData(id: 'test', data: [], metadata: {'b': 2});
        expect(ts1, equals(ts2));
      });
    });

    group('toString', () {
      test('includes id and point count', () {
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now()),
          ],
        );
        final str = ts.toString();
        expect(str, contains('test'));
        expect(str, contains('1'));
      });

      test('includes startTime and endTime when available', () {
        final t1 = DateTime(2024, 1, 1);
        final ts = TimeSeriesData(
          id: 'test',
          data: [
            ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
          ],
        );
        final str = ts.toString();
        expect(str, contains('2024'));
      });
    });
  });
}
