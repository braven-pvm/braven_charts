// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/data_range.dart' as dr;
import 'package:braven_charts/legacy/src/foundation/data_models/time_series_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartDataPoint Contract Tests', () {
    test('ChartDataPoint constructor exists with required parameters', () {
      final point = const ChartDataPoint(x: 1.0, y: 2.0);
      expect(point.x, equals(1.0));
      expect(point.y, equals(2.0));
    });

    test('ChartDataPoint supports optional timestamp', () {
      final now = DateTime.now();
      final point = ChartDataPoint(x: 1.0, y: 2.0, timestamp: now);
      expect(point.timestamp, equals(now));
      expect(point.hasTimestamp, isTrue);
    });

    test('ChartDataPoint supports optional label', () {
      final point = const ChartDataPoint(x: 1.0, y: 2.0, label: 'Test Point');
      expect(point.label, equals('Test Point'));
      expect(point.hasLabel, isTrue);
    });

    test('ChartDataPoint supports copyWith for immutability', () {
      final original = const ChartDataPoint(x: 1.0, y: 2.0);
      final modified = original.copyWith(y: 3.0);
      expect(original.y, equals(2.0)); // Original unchanged
      expect(modified.y, equals(3.0)); // New instance modified
    });

    test('ChartDataPoint equality excludes metadata', () {
      final p1 = const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'a': 1});
      final p2 = const ChartDataPoint(x: 1.0, y: 2.0, metadata: {'b': 2});
      expect(p1, equals(p2)); // Equal despite different metadata
    });

    test('ChartDataPoint validates finite numbers', () {
      final valid = const ChartDataPoint(x: 1.0, y: 2.0);
      expect(valid.isValid, isTrue);

      final invalidNaN = const ChartDataPoint(x: double.nan, y: 2.0);
      expect(invalidNaN.isValid, isFalse);

      final invalidInf = const ChartDataPoint(x: 1.0, y: double.infinity);
      expect(invalidInf.isValid, isFalse);
    });
  });

  group('ChartSeries Contract Tests', () {
    test('ChartSeries constructor exists with required parameters', () {
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );
      expect(series.id, equals('test-series'));
      expect(series.points, isEmpty);
    });

    test('ChartSeries supports optional name and metadata', () {
      final series = ChartSeries(
        id: 'test',
        points: [],
        name: 'Test Series',
        color: Colors.blue,
      );
      expect(series.name, equals('Test Series'));
      expect(series.color, equals(Colors.blue));
    });

    test('ChartSeries provides computed xRange and yRange', () {
      final points = [
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 3.0, y: 4.0),
        const ChartDataPoint(x: 5.0, y: 1.0),
      ];
      final series = ChartSeries(id: 'test', points: points);

      expect(series.xRange.min, equals(1.0));
      expect(series.xRange.max, equals(5.0));
      expect(series.yRange.min, equals(1.0));
      expect(series.yRange.max, equals(4.0));
    });

    test('ChartSeries validates ordering when isXOrdered=true', () {
      final orderedPoints = [
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: 2.0, y: 3.0),
        const ChartDataPoint(x: 3.0, y: 1.0),
      ];
      final series =
          ChartSeries(id: 'test', points: orderedPoints, isXOrdered: true);
      expect(series.validateOrdering(), isTrue);

      final unorderedPoints = [
        const ChartDataPoint(x: 3.0, y: 1.0),
        const ChartDataPoint(x: 1.0, y: 2.0),
      ];
      final badSeries =
          ChartSeries(id: 'test', points: unorderedPoints, isXOrdered: true);
      expect(badSeries.validateOrdering(), isFalse);
    });

    test('ChartSeries.validate() returns ChartResult', () {
      final validSeries = ChartSeries(id: 'test', points: []);
      final result = validSeries.validate();
      expect(result.isSuccess, isTrue);
    });

    test('ChartSeries.validate() detects invalid points', () {
      final invalidPoints = [
        const ChartDataPoint(x: 1.0, y: 2.0),
        const ChartDataPoint(x: double.nan, y: 3.0), // Invalid
      ];
      final series = ChartSeries(id: 'test', points: invalidPoints);
      final result = series.validate();
      expect(result.isSuccess, isFalse);
    });
  });

  group('DataRange Contract Tests', () {
    test('DataRange constructor enforces min <= max', () {
      final range = const dr.DataRange(min: 0.0, max: 10.0);
      expect(range.min, equals(0.0));
      expect(range.max, equals(10.0));
    });

    test('DataRange.fromValues factory works', () {
      final range = dr.DataRange.fromValues([1.0, 5.0, 3.0, 2.0, 4.0]);
      expect(range.min, equals(1.0));
      expect(range.max, equals(5.0));
    });

    test('DataRange.fromPoints factory works', () {
      final points = [
        const ChartDataPoint(x: 1.0, y: 10.0),
        const ChartDataPoint(x: 5.0, y: 20.0),
      ];
      final xRange = dr.DataRange.fromPoints(points, dr.Axis.x);
      expect(xRange.min, equals(1.0));
      expect(xRange.max, equals(5.0));

      final yRange = dr.DataRange.fromPoints(points, dr.Axis.y);
      expect(yRange.min, equals(10.0));
      expect(yRange.max, equals(20.0));
    });

    test('DataRange computed properties work', () {
      final range = const dr.DataRange(min: 0.0, max: 10.0);
      expect(range.span, equals(10.0));
      expect(range.center, equals(5.0));
    });

    test('DataRange supports padding', () {
      final range = const dr.DataRange(min: 0.0, max: 10.0, padding: 0.1);
      expect(range.paddedMin, equals(-1.0)); // 0 - (10 * 0.1)
      expect(range.paddedMax, equals(11.0)); // 10 + (10 * 0.1)
    });

    test('DataRange contains() method works', () {
      final range = const dr.DataRange(min: 0.0, max: 10.0);
      expect(range.contains(5.0), isTrue);
      expect(range.contains(-1.0), isFalse);
      expect(range.contains(11.0), isFalse);
    });

    test('DataRange overlaps() method works', () {
      final r1 = const dr.DataRange(min: 0.0, max: 10.0);
      final r2 = const dr.DataRange(min: 5.0, max: 15.0);
      final r3 = const dr.DataRange(min: 11.0, max: 20.0);

      expect(r1.overlaps(r2), isTrue);
      expect(r1.overlaps(r3), isFalse);
    });

    test('DataRange merge() method works', () {
      final r1 = const dr.DataRange(min: 0.0, max: 10.0);
      final r2 = const dr.DataRange(min: 5.0, max: 15.0);
      final merged = r1.merge(r2);

      expect(merged.min, equals(0.0));
      expect(merged.max, equals(15.0));
    });

    test('DataRange.validate() returns ChartResult', () {
      final validRange = const dr.DataRange(min: 0.0, max: 10.0);
      final result = validRange.validate();
      expect(result.isSuccess, isTrue);

      // Factory methods ensure valid construction, so validate() should pass
      final rangeFromValues = dr.DataRange.fromValues([1.0, 2.0, 3.0]);
      expect(rangeFromValues.validate().isSuccess, isTrue);
    });

    test('DataRange handles empty list in fromValues', () {
      final range = dr.DataRange.fromValues([]);
      expect(range.min, equals(0.0));
      expect(range.max, equals(0.0));
    });
  });

  group('TimeSeriesData Contract Tests', () {
    test('TimeSeriesData constructor exists', () {
      final data = TimeSeriesData(
        id: 'test',
        name: 'Test Time Series',
        data: [],
      );
      expect(data.id, equals('test'));
      expect(data.name, equals('Test Time Series'));
    });

    test('TimeSeriesData provides startTime and endTime', () {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 1, 2);
      final t3 = DateTime(2024, 1, 3);

      final data = TimeSeriesData(
        id: 'test',
        data: [
          ChartDataPoint(x: 1.0, y: 2.0, timestamp: t2),
          ChartDataPoint(x: 2.0, y: 3.0, timestamp: t1),
          ChartDataPoint(x: 3.0, y: 4.0, timestamp: t3),
        ],
      );

      expect(data.startTime, equals(t1));
      expect(data.endTime, equals(t3));
      expect(data.timeSpan, equals(t3.difference(t1)));
    });

    test('TimeSeriesData toChartSeries() conversion works', () {
      final t1 = DateTime(2024, 1, 1);
      final data = TimeSeriesData(
        id: 'test',
        data: [
          ChartDataPoint(x: 1.0, y: 2.0, timestamp: t1),
        ],
      );

      final series = data.toChartSeries();
      expect(series.id, equals('test'));
      expect(series.points.length, equals(1));
      expect(series.isXOrdered, isTrue);
    });

    test('TimeSeriesData.validate() checks for timestamps', () {
      final withTimestamp = TimeSeriesData(
        id: 'test',
        data: [
          ChartDataPoint(x: 1.0, y: 2.0, timestamp: DateTime.now()),
        ],
      );
      expect(withTimestamp.validate().isSuccess, isTrue);

      final withoutTimestamp = TimeSeriesData(
        id: 'test',
        data: [
          const ChartDataPoint(x: 1.0, y: 2.0), // Missing timestamp
        ],
      );
      expect(withoutTimestamp.validate().isSuccess, isFalse);
    });
  });
}
