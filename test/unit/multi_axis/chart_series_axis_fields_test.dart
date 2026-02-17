// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for Task 15: yAxisId and unit fields on ChartSeries hierarchy.
///
/// These tests verify:
/// - Base ChartSeries accepts yAxisId and unit parameters
/// - All subclasses (Line, Area, Bar, Scatter) support the new fields
/// - copyWith preserves the new fields
/// - Equality includes the new fields
void main() {
  group('ChartSeries yAxisId and unit fields', () {
    // Sample data points for all tests
    final testPoints = [
      const ChartDataPoint(x: 0, y: 100),
      const ChartDataPoint(x: 1, y: 200),
    ];

    group('ChartSeries base class', () {
      test('accepts yAxisId parameter', () {
        const series = ChartSeries(
          id: 'test',
          points: [],
          yAxisId: 'power-axis',
        );

        expect(series.yAxisId, equals('power-axis'));
      });

      test('accepts unit parameter', () {
        const series = ChartSeries(id: 'test', points: [], unit: 'W');

        expect(series.unit, equals('W'));
      });

      test('yAxisId defaults to null', () {
        const series = ChartSeries(id: 'test', points: []);

        expect(series.yAxisId, isNull);
      });

      test('unit defaults to null', () {
        const series = ChartSeries(id: 'test', points: []);

        expect(series.unit, isNull);
      });

      test('accepts both yAxisId and unit together', () {
        const series = ChartSeries(
          id: 'power',
          points: [],
          yAxisId: 'power-axis',
          unit: 'W',
        );

        expect(series.yAxisId, equals('power-axis'));
        expect(series.unit, equals('W'));
      });

      group('copyWith', () {
        test('preserves yAxisId when not overridden', () {
          final series = ChartSeries(
            id: 'test',
            points: testPoints,
            yAxisId: 'original-axis',
          );

          final copy = series.copyWith(name: 'Updated Name');

          expect(copy.yAxisId, equals('original-axis'));
        });

        test('preserves unit when not overridden', () {
          final series = ChartSeries(
            id: 'test',
            points: testPoints,
            unit: 'bpm',
          );

          final copy = series.copyWith(name: 'Updated Name');

          expect(copy.unit, equals('bpm'));
        });

        test('allows overriding yAxisId', () {
          final series = ChartSeries(
            id: 'test',
            points: testPoints,
            yAxisId: 'original-axis',
          );

          final copy = series.copyWith(yAxisId: 'new-axis');

          expect(copy.yAxisId, equals('new-axis'));
        });

        test('allows overriding unit', () {
          final series = ChartSeries(id: 'test', points: testPoints, unit: 'W');

          final copy = series.copyWith(unit: 'kW');

          expect(copy.unit, equals('kW'));
        });
      });

      group('equality', () {
        test('includes yAxisId in equality comparison', () {
          final series1 = ChartSeries(
            id: 'test',
            points: testPoints,
            yAxisId: 'axis-1',
          );

          final series2 = ChartSeries(
            id: 'test',
            points: testPoints,
            yAxisId: 'axis-1',
          );

          final series3 = ChartSeries(
            id: 'test',
            points: testPoints,
            yAxisId: 'axis-2',
          );

          expect(series1, equals(series2));
          expect(series1, isNot(equals(series3)));
        });

        test('includes unit in equality comparison', () {
          final series1 = ChartSeries(
            id: 'test',
            points: testPoints,
            unit: 'W',
          );

          final series2 = ChartSeries(
            id: 'test',
            points: testPoints,
            unit: 'W',
          );

          final series3 = ChartSeries(
            id: 'test',
            points: testPoints,
            unit: 'bpm',
          );

          expect(series1, equals(series2));
          expect(series1, isNot(equals(series3)));
        });
      });
    });

    group('LineChartSeries', () {
      test('supports yAxisId parameter', () {
        final series = LineChartSeries(
          id: 'power',
          name: 'Power',
          points: testPoints,
          color: Colors.blue,
          yAxisId: 'power-axis',
        );

        expect(series.yAxisId, equals('power-axis'));
      });

      test('supports unit parameter', () {
        final series = LineChartSeries(
          id: 'power',
          name: 'Power',
          points: testPoints,
          color: Colors.blue,
          unit: 'W',
        );

        expect(series.unit, equals('W'));
      });

      test('supports both yAxisId and unit together', () {
        final series = LineChartSeries(
          id: 'heartrate',
          name: 'Heart Rate',
          points: testPoints,
          color: Colors.red,
          yAxisId: 'hr-axis',
          unit: 'bpm',
        );

        expect(series.yAxisId, equals('hr-axis'));
        expect(series.unit, equals('bpm'));
      });
    });

    group('AreaChartSeries', () {
      test('supports yAxisId and unit parameters', () {
        final series = AreaChartSeries(
          id: 'volume',
          name: 'Tidal Volume',
          points: testPoints,
          color: Colors.green,
          yAxisId: 'volume-axis',
          unit: 'L',
        );

        expect(series.yAxisId, equals('volume-axis'));
        expect(series.unit, equals('L'));
      });
    });

    group('BarChartSeries', () {
      test('supports yAxisId and unit parameters', () {
        final series = BarChartSeries(
          id: 'sales',
          name: 'Monthly Sales',
          points: testPoints,
          color: Colors.orange,
          barWidthPercent: 0.8,
          yAxisId: 'sales-axis',
          unit: '\$',
        );

        expect(series.yAxisId, equals('sales-axis'));
        expect(series.unit, equals('\$'));
      });
    });

    group('ScatterChartSeries', () {
      test('supports yAxisId and unit parameters', () {
        final series = ScatterChartSeries(
          id: 'temperature',
          name: 'Temperature',
          points: testPoints,
          color: Colors.purple,
          yAxisId: 'temp-axis',
          unit: '°C',
        );

        expect(series.yAxisId, equals('temp-axis'));
        expect(series.unit, equals('°C'));
      });
    });
  });
}
