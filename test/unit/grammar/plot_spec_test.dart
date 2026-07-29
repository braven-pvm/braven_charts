// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row type for the typed accessors under test.
class Sample {
  const Sample({
    required this.time,
    required this.power,
    required this.heartRate,
    required this.zone,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.stamp,
  });

  final double time;
  final double power;
  final double heartRate;
  final String zone;
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime? stamp;
}

// Top-level tear-offs: constant expressions, so marks built from them are
// const-constructible.
double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
double sampleHeartRate(Sample row) => row.heartRate;
Object sampleZone(Sample row) => row.zone;
double sampleOpen(Sample row) => row.open;
double sampleHigh(Sample row) => row.high;
double sampleLow(Sample row) => row.low;
double sampleClose(Sample row) => row.close;
DateTime sampleStamp(Sample row) => row.stamp ?? DateTime.utc(2026);

/// Exhaustive switch over the sealed [Mark] hierarchy.
///
/// This function is the compile-time guard the spec model promises: adding a
/// `Mark` variant without updating every dispatch site is a COMPILE error, not
/// a runtime surprise. There is deliberately no `_` fallback.
String geomOf(Mark<Sample> mark) => switch (mark) {
  LineMark<Sample>() => 'line',
  AreaMark<Sample>() => 'area',
  BarMark<Sample>() => 'bar',
  ScatterMark<Sample>() => 'scatter',
  HeatmapMark<Sample>() => 'heatmap',
  CandlestickMark<Sample>() => 'candlestick',
  TrendMark<Sample>() => 'trend',
  ThresholdMark<Sample>() => 'threshold',
  BandMark<Sample>() => 'band',
  PointMark<Sample>() => 'point',
  RadialMark<Sample>() => 'radial',
};

const _line = LineMark<Sample>(x: sampleTime, y: samplePower);
const _area = AreaMark<Sample>(x: sampleTime, y: samplePower);
const _bar = BarMark<Sample>(x: sampleTime, y: samplePower);
const _scatter = ScatterMark<Sample>(x: sampleTime, y: samplePower);
final _heatmap = HeatmapMark<Sample>(
  x: sampleTime,
  y: sampleHeartRate,
  value: samplePower,
  colorScale: HeatmapColorScale.sequential(
    colors: const [Color(0xFFDBEAFE), Color(0xFF1D4ED8)],
  ),
);
const _candle = CandlestickMark<Sample>(
  x: sampleTime,
  open: sampleOpen,
  high: sampleHigh,
  low: sampleLow,
  close: sampleClose,
);
const _trend = TrendMark<Sample>(sourceMarkId: 'mark-0');
const _threshold = ThresholdMark<Sample>(value: 250);
const _band = BandMark<Sample>(start: 200, end: 260);
const _point = PointMark<Sample>(seriesId: 'mark-0', dataPointIndex: 0);
const _polar = PolarMark<Sample>(category: sampleZone, value: samplePower);

void main() {
  group('const-ness', () {
    test('every mark variant is const-constructible', () {
      // The declarations above are already `const`; identical() proves the
      // compiler canonicalized them rather than allocating.
      expect(
        identical(_line, const LineMark<Sample>(x: sampleTime, y: samplePower)),
        isTrue,
      );
      expect(
        identical(_area, const AreaMark<Sample>(x: sampleTime, y: samplePower)),
        isTrue,
      );
      expect(
        identical(_bar, const BarMark<Sample>(x: sampleTime, y: samplePower)),
        isTrue,
      );
      expect(
        identical(
          _scatter,
          const ScatterMark<Sample>(x: sampleTime, y: samplePower),
        ),
        isTrue,
      );
      expect(
        identical(
          _candle,
          const CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
          ),
        ),
        isTrue,
      );
      expect(
        identical(_trend, const TrendMark<Sample>(sourceMarkId: 'mark-0')),
        isTrue,
      );
      expect(
        identical(_threshold, const ThresholdMark<Sample>(value: 250)),
        isTrue,
      );
      expect(
        identical(_band, const BandMark<Sample>(start: 200, end: 260)),
        isTrue,
      );
      expect(
        identical(
          _point,
          const PointMark<Sample>(seriesId: 'mark-0', dataPointIndex: 0),
        ),
        isTrue,
      );
    });

    test('channels are const-constructible', () {
      expect(
        identical(
          const Channel<Sample>(samplePower),
          const Channel<Sample>(samplePower),
        ),
        isTrue,
      );
      expect(
        identical(
          const CategoryChannel<Sample>(sampleZone),
          const CategoryChannel<Sample>(sampleZone),
        ),
        isTrue,
      );
    });

    test('a whole plot spec is const-constructible', () {
      const spec = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
      );
      expect(spec.transposed, isFalse);
      expect(spec.yAxes, isEmpty);
      expect(spec.theme, isNull);
      expect(spec.interaction, isNull);
      expect(spec.xAxis, isNull);
    });
  });

  group('sealed exhaustiveness', () {
    test('the switch over Mark covers every V1 variant', () {
      expect(geomOf(_line), 'line');
      expect(geomOf(_area), 'area');
      expect(geomOf(_bar), 'bar');
      expect(geomOf(_scatter), 'scatter');
      expect(geomOf(_heatmap), 'heatmap');
      expect(geomOf(_candle), 'candlestick');
      expect(geomOf(_trend), 'trend');
      expect(geomOf(_threshold), 'threshold');
      expect(geomOf(_band), 'band');
      expect(geomOf(_point), 'point');
    });
  });

  group('accessor typing', () {
    const row = Sample(
      time: 1,
      power: 200,
      heartRate: 140,
      zone: 'threshold',
      open: 10,
      high: 12,
      low: 9,
      close: 11,
    );

    test('mark accessors are typed FieldAccessor functions', () {
      final FieldAccessor<Sample, num> x = _line.x;
      final FieldAccessor<Sample, num> y = _line.y;
      expect(x(row), 1);
      expect(y(row), 200);
    });

    test('Channel exposes a num accessor, CategoryChannel an Object one', () {
      const size = Channel<Sample>(sampleHeartRate, label: 'HR');
      const category = CategoryChannel<Sample>(sampleZone, label: 'Zone');
      expect(size.accessor(row), 140);
      expect(category.accessor(row), 'threshold');
      expect(size.label, 'HR');
      expect(category.label, 'Zone');
      expect(size.scale, isNull);
    });

    test('candlestick marks expose five numeric accessors', () {
      expect(_candle.x(row), 1);
      expect(_candle.open(row), 10);
      expect(_candle.high(row), 12);
      expect(_candle.low(row), 9);
      expect(_candle.close(row), 11);
      expect(_candle.timestamp, isNull);
      const stamped = CandlestickMark<Sample>(
        x: sampleTime,
        open: sampleOpen,
        high: sampleHigh,
        low: sampleLow,
        close: sampleClose,
        timestamp: sampleStamp,
      );
      expect(stamped.timestamp, isNotNull);
    });
  });

  group('value equality', () {
    test('channels compare by accessor identity, label and scale', () {
      expect(
        const Channel<Sample>(samplePower, label: 'Power'),
        const Channel<Sample>(samplePower, label: 'Power'),
      );
      expect(
        const Channel<Sample>(samplePower, label: 'Power').hashCode,
        const Channel<Sample>(samplePower, label: 'Power').hashCode,
      );
      expect(
        const Channel<Sample>(samplePower, label: 'Power'),
        isNot(const Channel<Sample>(samplePower, label: 'Watts')),
      );
      expect(
        const Channel<Sample>(samplePower),
        isNot(const Channel<Sample>(sampleHeartRate)),
      );
      expect(
        const Channel<Sample>(samplePower, scale: ChannelScale.sqrt),
        isNot(const Channel<Sample>(samplePower, scale: ChannelScale.linear)),
      );
      expect(
        const CategoryChannel<Sample>(sampleZone, label: 'Zone'),
        const CategoryChannel<Sample>(sampleZone, label: 'Zone'),
      );
    });

    test('marks compare by value, including list-valued fields', () {
      expect(
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          id: 'power',
          strokeWidth: 3,
          dashPattern: <double>[4, 2],
        ),
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          id: 'power',
          strokeWidth: 3,
          dashPattern: <double>[4, 2],
        ),
      );
      expect(
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          dashPattern: <double>[4, 2],
        ),
        isNot(
          const LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            dashPattern: <double>[2, 4],
          ),
        ),
      );
      expect(_line, isNot(_area));
      expect(
        const ScatterMark<Sample>(
          x: sampleTime,
          y: samplePower,
          size: Channel<Sample>(sampleHeartRate),
        ),
        const ScatterMark<Sample>(
          x: sampleTime,
          y: samplePower,
          size: Channel<Sample>(sampleHeartRate),
        ),
      );
      expect(
        const TrendMark<Sample>(
          sourceMarkId: 'power',
          trendType: TrendType.loess,
        ),
        isNot(const TrendMark<Sample>(sourceMarkId: 'power')),
      );
    });

    test('a mark carrying a Color compares on it', () {
      expect(
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          color: Color(0xFF112233),
        ),
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          color: Color(0xFF112233),
        ),
      );
      expect(
        const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          color: Color(0xFF112233),
        ),
        isNot(
          const LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            color: Color(0xFF445566),
          ),
        ),
      );
    });

    test('plot specs compare by value across every field', () {
      final rows = <Sample>[];
      final left = PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[_line, _trend],
        transposed: false,
        xAxis: const XAxisConfig(label: 'Time'),
        yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)],
        interaction: const InteractionConfig(),
      );
      final right = PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[_line, _trend],
        transposed: false,
        xAxis: const XAxisConfig(label: 'Time'),
        yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)],
        interaction: const InteractionConfig(),
      );
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(
        left,
        isNot(
          PlotSpec<Sample>(
            data: rows,
            marks: const <Mark<Sample>>[_line, _trend],
            transposed: true,
            xAxis: const XAxisConfig(label: 'Time'),
            yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)],
            interaction: const InteractionConfig(),
          ),
        ),
      );
      expect(
        left,
        isNot(
          PlotSpec<Sample>(
            data: rows,
            marks: const <Mark<Sample>>[_line],
            xAxis: const XAxisConfig(label: 'Time'),
            yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)],
            interaction: const InteractionConfig(),
          ),
        ),
      );
    });
  });

  group('marks expose no copyWith', () {
    test('the grammar layer is not config-shaped', () {
      // Enforcement (test/meta/surface_enforcement_test.dart) demands
      // @chartSurface on every barrel-reachable class with a copyWith. Marks
      // deliberately have none: they are small enough to reconstruct, and a
      // generated fluent surface over them would be a second vocabulary for
      // the same objects.
      expect(_line, isNot(isA<ChartSeries>()));
      // ignore: unnecessary_type_check
      expect(_line is Mark<Sample>, isTrue);
    });
  });

  group('facet field', () {
    test('facet defaults to null and a non-faceted spec is unchanged', () {
      const spec = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
      );
      expect(spec.facet, isNull);
    });

    test('facet is carried on the spec and compared by value', () {
      const facet = FacetSpec<Sample>(by: sampleZone, columns: 2);
      const left = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        facet: facet,
      );
      const right = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        facet: facet,
      );
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(
        left,
        isNot(
          const PlotSpec<Sample>(
            data: <Sample>[],
            marks: <Mark<Sample>>[_line],
          ),
        ),
      );
    });

    test('facetCleared drops the facet and keeps everything else', () {
      const facet = FacetSpec<Sample>(by: sampleZone);
      const faceted = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        transposed: false,
        xAxis: XAxisConfig(label: 'Time'),
        facet: facet,
      );
      final cleared = faceted.facetCleared();
      expect(cleared.facet, isNull);
      expect(cleared.marks, faceted.marks);
      expect(cleared.xAxis, faceted.xAxis);
      expect(
        cleared,
        const PlotSpec<Sample>(
          data: <Sample>[],
          marks: <Mark<Sample>>[_line],
          xAxis: XAxisConfig(label: 'Time'),
        ),
      );
    });
  });

  group('polar field', () {
    test('polar defaults to null on a spec that never sets it', () {
      const spec = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_polar],
      );
      expect(spec.polar, isNull);
    });

    test('polar config participates in equality and survives facetCleared', () {
      const polar = PolarChartConfig(
        composition: PolarColumnCompositionConfig(
          mode: PolarColumnCompositionMode.grouped,
        ),
      );
      const a = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_polar],
        polar: polar,
      );
      const b = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_polar],
      );
      // Identical marks and data: only `polar` differs, so inequality here can
      // only come from the new field participating in `==`.
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
      const twin = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_polar],
        polar: polar,
      );
      expect(a, twin);
      expect(a.hashCode, twin.hashCode);
      expect(a.facetCleared().polar, same(polar));
    });
  });
}
