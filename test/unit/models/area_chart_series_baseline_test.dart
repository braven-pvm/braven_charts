import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AreaChartSeries baseline fields', () {
    test('baselineValue defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.baselineValue, isNull);
    });

    test('aboveBaselineFillColor defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.aboveBaselineFillColor, isNull);
    });

    test('belowBaselineFillColor defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.belowBaselineFillColor, isNull);
    });

    test('copyWith preserves baselineValue when not overridden', () {
      const s = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(s.copyWith(id: 'b').baselineValue, 133.0);
    });

    test('copyWith updates baselineValue', () {
      const s = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(s.copyWith(baselineValue: 200.0).baselineValue, 200.0);
    });

    test('copyWith preserves aboveBaselineFillColor when not overridden', () {
      const color = Color(0xFF00FF00);
      const s = AreaChartSeries(id: 'a', points: [], aboveBaselineFillColor: color);
      expect(s.copyWith(id: 'b').aboveBaselineFillColor, color);
    });

    test('copyWith preserves belowBaselineFillColor when not overridden', () {
      const color = Color(0xFFFF0000);
      const s = AreaChartSeries(id: 'a', points: [], belowBaselineFillColor: color);
      expect(s.copyWith(id: 'b').belowBaselineFillColor, color);
    });

    test('== treats same baselineValue as equal', () {
      const a = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(a, equals(b));
    });

    test('== treats different baselineValues as not equal', () {
      const a = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 200.0);
      expect(a, isNot(equals(b)));
    });

    test('null baselineValue differs from non-null in ==', () {
      const a = AreaChartSeries(id: 'a', points: []);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with ==', () {
      const a = AreaChartSeries(
        id: 'a',
        points: [],
        baselineValue: 133.0,
        aboveBaselineFillColor: Color(0xFF00FF00),
      );
      const b = AreaChartSeries(
        id: 'a',
        points: [],
        baselineValue: 133.0,
        aboveBaselineFillColor: Color(0xFF00FF00),
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== distinguishes aboveBaselineFillColor values', () {
      const a = AreaChartSeries(
        id: 'a', points: [], aboveBaselineFillColor: Color(0xFF00FF00),
      );
      const b = AreaChartSeries(
        id: 'a', points: [], aboveBaselineFillColor: Color(0xFF0000FF),
      );
      expect(a, isNot(equals(b)));
    });

    test('== distinguishes belowBaselineFillColor values', () {
      const a = AreaChartSeries(
        id: 'a', points: [], belowBaselineFillColor: Color(0xFFFF0000),
      );
      const b = AreaChartSeries(
        id: 'a', points: [], belowBaselineFillColor: Color(0xFF0000FF),
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith(baselineValue: null) preserves existing value', () {
      const s = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(s.copyWith(baselineValue: null).baselineValue, 133.0);
    });
  });
}
