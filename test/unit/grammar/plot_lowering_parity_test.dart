// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Config-equality parity for the grammar lowering.
///
/// PARITY MEANS: build the same chart twice — once as a [PlotSpec] put through
/// [lower], once as the hand-written `ChartSeries`/`ChartAnnotation`/axis
/// configs a user would write today — and assert the two are EQUAL by the
/// package's own `==`. The grammar layer therefore cannot drift from the
/// config surface it lowers onto without turning this file red.
///
/// Artifact-document equality is Task 11's job; this file is config-only.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({
    required this.time,
    required this.power,
    required this.heartRate,
    required this.effort,
    required this.zone,
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
    this.stamp,
  });

  final double time;
  final double power;
  final double heartRate;
  final double effort;
  final String zone;
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime? stamp;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
double sampleHeartRate(Sample row) => row.heartRate;
double sampleEffort(Sample row) => row.effort;
Object sampleZone(Sample row) => row.zone;
double sampleOpen(Sample row) => row.open;
double sampleHigh(Sample row) => row.high;
double sampleLow(Sample row) => row.low;
double sampleClose(Sample row) => row.close;
DateTime sampleStamp(Sample row) => row.stamp!;

/// Per-point text accessors. Tear-offs, not closures: marks compare by value
/// and a closure written twice is two different marks.
String? sampleZoneLabel(Sample row) => row.zone;
String? samplePointKey(Sample row) => 'key-${row.time}';
String? sampleBlankText(Sample row) => '';
String? sampleCollidingKey(Sample row) => 'same';

const rows = <Sample>[
  Sample(
    time: 0,
    power: 180,
    heartRate: 120,
    effort: 1,
    zone: 'easy',
    open: 10,
    high: 14,
    low: 9,
    close: 12,
  ),
  Sample(
    time: 1,
    power: 220,
    heartRate: 140,
    effort: 4,
    zone: 'hard',
    open: 12,
    high: 16,
    low: 11,
    close: 15,
  ),
  Sample(
    time: 2,
    power: 260,
    heartRate: 165,
    effort: 9,
    zone: 'easy',
    open: 15,
    high: 18,
    low: 13,
    close: 14,
  ),
];

/// The axis the lowering synthesizes when a spec declares none.
YAxisConfig defaultAxis() =>
    YAxisConfig(position: YAxisPosition.left).copyWith(id: 'axis-0');

List<ChartDataPoint> xyPoints() => <ChartDataPoint>[
  for (final row in rows) ChartDataPoint(x: row.time, y: row.power),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  group('parity: one mark per family', () {
    test('line mark solo lowers to a plain LineChartSeries', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(lowered.series, <ChartSeries>[
        LineChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
      ]);
      expect(lowered.annotations, isEmpty);
      expect(lowered.yAxes, <YAxisConfig>[axis]);
      expect(lowered.xAxis, isNull);
      expect(lowered.theme, isNull);
      expect(lowered.interaction, const InteractionConfig());
    });

    test('line mark styling reaches the series verbatim', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'power',
            name: 'Power',
            color: Color(0xFF2196F3),
            strokeWidth: 3.5,
            dashPattern: <double>[4, 2],
            interpolation: LineInterpolation.monotone,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: xyPoints(),
          color: const Color(0xFF2196F3),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          strokeWidth: 3.5,
          dashPattern: const <double>[4, 2],
          interpolation: LineInterpolation.monotone,
        ),
      );
    });

    test('area mark solo lowers to an AreaChartSeries', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          AreaMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'load',
            baseline: 100,
            fillOpacity: 0.55,
            interpolation: LineInterpolation.bezier,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        AreaChartSeries(
          id: 'load',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          fillOpacity: 0.55,
          baselineValue: 100,
          interpolation: LineInterpolation.bezier,
        ),
      );
    });

    test('bar mark solo lowers with the package default width percent', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          BarMark<Sample>(x: sampleTime, y: samplePower),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        BarChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          barWidthPercent: 0.8,
        ),
      );
    });

    test('bar mark honors an explicit pixel width and layout hints', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          BarMark<Sample>(
            x: sampleTime,
            y: samplePower,
            barWidthPixels: 18,
            barGap: 6,
            layoutMode: BarLayoutMode.stacked,
            groupId: 'load',
            baselineValue: 50,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        BarChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          barWidthPixels: 18,
          barGap: 6,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'load',
          baselineValue: 50,
        ),
      );
    });

    test('line mark data-point markers and labels reach the series', () {
      const labels = DataPointLabelConfig(
        show: true,
        position: DataPointLabelPosition.below,
      );
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'power',
            showDataPointMarkers: true,
            dataPointLabels: labels,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        LineChartSeries(
          id: 'power',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          showDataPointMarkers: true,
          dataPointLabels: labels,
        ),
      );
    });

    test('area mark data-point markers and labels reach the series', () {
      const labels = DataPointLabelConfig(show: true);
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          AreaMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'load',
            showDataPointMarkers: true,
            dataPointLabels: labels,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        AreaChartSeries(
          id: 'load',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          showDataPointMarkers: true,
          dataPointLabels: labels,
        ),
      );
    });

    test('bar mark label style reaches the series', () {
      const barLabels = BarLabelStyle(show: true, showUnit: true);
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          BarMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'load',
            labelStyle: barLabels,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        BarChartSeries(
          id: 'load',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          barWidthPercent: 0.8,
          labelStyle: barLabels,
        ),
      );
    });

    test('scatter mark solo lowers to a plain ScatterChartSeries', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          ScatterMark<Sample>(
            x: sampleTime,
            y: samplePower,
            markerRadius: 7,
            markerShape: SeriesMarkerShape.triangle,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        ScatterChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          markerRadius: 7,
          markerShape: SeriesMarkerShape.triangle,
        ),
      );
    });

    test('candlestick mark lowers to typed CandlestickDataPoints', () {
      final stamped = <Sample>[
        for (var index = 0; index < rows.length; index++)
          Sample(
            time: rows[index].time,
            power: rows[index].power,
            heartRate: rows[index].heartRate,
            effort: rows[index].effort,
            zone: rows[index].zone,
            open: rows[index].open,
            high: rows[index].high,
            low: rows[index].low,
            close: rows[index].close,
            stamp: DateTime.utc(2026, 7, 21, index),
          ),
      ];

      final lowered = (PlotSpec<Sample>(
        data: stamped,
        marks: const <Mark<Sample>>[
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
            timestamp: sampleStamp,
            id: 'ohlc',
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        CandlestickChartSeries(
          id: 'ohlc',
          points: <CandlestickDataPoint>[
            for (var index = 0; index < stamped.length; index++)
              CandlestickDataPoint(
                x: stamped[index].time,
                open: stamped[index].open,
                high: stamped[index].high,
                low: stamped[index].low,
                close: stamped[index].close,
                timestamp: DateTime.utc(2026, 7, 21, index),
              ),
          ],
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
      );
    });
  });

  group('parity: unit', () {
    test('unit lowers onto every Cartesian series family', () {
      for (final (mark, family) in const <(Mark<Sample>, String)>[
        (LineMark<Sample>(x: sampleTime, y: samplePower, unit: 'W'), 'line'),
        (AreaMark<Sample>(x: sampleTime, y: samplePower, unit: 'W'), 'area'),
        (BarMark<Sample>(x: sampleTime, y: samplePower, unit: 'W'), 'bar'),
        (
          ScatterMark<Sample>(x: sampleTime, y: samplePower, unit: 'W'),
          'scatter',
        ),
        (
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
            unit: 'W',
          ),
          'candlestick',
        ),
      ]) {
        final lowered = (PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[mark],
        )).lower();
        expect(lowered.series.single.unit, 'W', reason: family);
      }
    });

    test('a mark that declares no unit lowers to a series with none', () {
      // The control for the test above: without this, a hard-coded literal in
      // the passthrough would satisfy every family assertion.
      for (final (mark, family) in const <(Mark<Sample>, String)>[
        (LineMark<Sample>(x: sampleTime, y: samplePower), 'line'),
        (AreaMark<Sample>(x: sampleTime, y: samplePower), 'area'),
        (BarMark<Sample>(x: sampleTime, y: samplePower), 'bar'),
        (ScatterMark<Sample>(x: sampleTime, y: samplePower), 'scatter'),
        (
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
          ),
          'candlestick',
        ),
      ]) {
        final lowered = (PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[mark],
        )).lower();
        expect(lowered.series.single.unit, isNull, reason: family);
      }
    });

    test('a unit-bearing line mark reaches config parity', () {
      // `unit` participates in `ChartSeries ==` through the base class, so the
      // parity assertion this file is built on is load-bearing for it.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'power',
            unit: 'W',
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        LineChartSeries(
          id: 'power',
          points: xyPoints(),
          unit: 'W',
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
      );
    });
  });

  group('parity: per-point label and pointKey', () {
    test('label and pointKey lower onto the points', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            label: sampleZoneLabel,
            pointKey: samplePointKey,
          ),
        ],
      )).lower();

      // Read as a WHOLE list of pairs rather than a per-point expect, so a
      // dropped field, a wrong row and an off-by-one all fail the same way.
      expect(
        lowered.series.single.points
            .map((point) => <String?>[point.label, point.pointKey])
            .toList(),
        <List<String?>>[
          <String?>['easy', 'key-0.0'],
          <String?>['hard', 'key-1.0'],
          <String?>['easy', 'key-2.0'],
        ],
      );
    });

    test('a mark that declares neither leaves every point bare', () {
      // The control for the test above: without it a hard-coded literal in the
      // point builders would satisfy it.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
      )).lower();

      expect(
        lowered.series.single.points
            .map((point) => <String?>[point.label, point.pointKey])
            .toList(),
        <List<String?>>[
          <String?>[null, null],
          <String?>[null, null],
          <String?>[null, null],
        ],
      );
    });

    test('an empty pointKey lowers to null rather than throwing', () {
      // `ChartDataPoint`'s constructor asserts a non-empty pointKey, so the
      // accessor must normalise '' to null instead of letting the assert fire.
      // This is not a convenience: the source emitter reverses a pointKey
      // through a NON-NULLABLE row slot and writes '' for a point that had
      // none, so an emitted chain feeds '' back through this path for every
      // key-less point in a partially-keyed series.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            pointKey: sampleBlankText,
          ),
        ],
      )).lower();

      expect(
        lowered.series.single.points.map((point) => point.pointKey),
        everyElement(isNull),
      );
    });

    test('an empty label lowers to null too', () {
      // Same equivalence, for the same reason: `label` shares the non-nullable
      // string row slot, so '' is how "this point has no label" travels. An
      // author who genuinely wants an empty label is not silently served a
      // different chart — the emitter's round-trip proof compares points and
      // refuses that chart rather than emitting one that drops it.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            label: sampleBlankText,
          ),
        ],
      )).lower();

      expect(
        lowered.series.single.points.map((point) => point.label),
        everyElement(isNull),
      );
    });

    test('every family that carries them lowers both', () {
      // Whole-map comparison so one missing family cannot hide behind an
      // earlier family's failure short-circuiting the loop.
      final marks = <String, Mark<Sample>>{
        'line': const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          label: sampleZoneLabel,
          pointKey: samplePointKey,
        ),
        'area': const AreaMark<Sample>(
          x: sampleTime,
          y: samplePower,
          label: sampleZoneLabel,
          pointKey: samplePointKey,
        ),
        'bar': const BarMark<Sample>(
          x: sampleTime,
          y: samplePower,
          label: sampleZoneLabel,
          pointKey: samplePointKey,
        ),
        'scatter': const ScatterMark<Sample>(
          x: sampleTime,
          y: samplePower,
          label: sampleZoneLabel,
          pointKey: samplePointKey,
        ),
      };
      final firstPoints = <String, List<String?>>{
        for (final entry in marks.entries)
          entry.key: () {
            final point = (PlotSpec<Sample>(
              data: rows,
              marks: <Mark<Sample>>[entry.value],
            )).lower().series.single.points.first;
            return <String?>[point.label, point.pointKey];
          }(),
      };

      expect(firstPoints, <String, List<String?>>{
        for (final family in marks.keys) family: <String?>['easy', 'key-0.0'],
      });
    });

    test(
      'a channel-styled mark keeps its baked style AND its per-point text',
      () {
        // Line/area with `colorBy`, and bar with `colorBy`/`sizeBy`, build their
        // points through a DIFFERENT builder from the plain path. A field added
        // to one builder and forgotten in the other is exactly the silent drop
        // this suite exists to catch.
        final lowered = (PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'line',
              x: sampleTime,
              y: samplePower,
              label: sampleZoneLabel,
              pointKey: samplePointKey,
              colorBy: Channel<Sample>(sampleEffort),
              colorEncoding: const ScatterColorEncoding(
                colors: <Color>[Colors.blue, Colors.red],
              ),
            ),
            BarMark<Sample>(
              id: 'bar',
              x: sampleTime,
              y: sampleHeartRate,
              label: sampleZoneLabel,
              pointKey: samplePointKey,
              colorBy: Channel<Sample>(sampleEffort),
              colorEncoding: const ScatterColorEncoding(
                colors: <Color>[Colors.blue, Colors.red],
              ),
            ),
          ],
        )).lower();

        final line = lowered.series[0].points.first;
        final bar = lowered.series[1].points.first;
        expect(
          <String?>[line.label, line.pointKey],
          <String?>['easy', 'key-0.0'],
        );
        expect(line.segmentStyle, isNotNull);
        expect(
          <String?>[bar.label, bar.pointKey],
          <String?>['easy', 'key-0.0'],
        );
        expect(bar.pointStyle, isNotNull);
      },
    );

    test('duplicate pointKeys within one series are refused by name', () {
      // A pointKey is the STABLE SELECTION IDENTITY, so two rows yielding the
      // same key make selection ambiguous. The radial side already refuses the
      // equivalent collision (`duplicateRadialCategory`); this is the Cartesian
      // one, and it is named rather than left to fail obscurely downstream.
      expect(
        () => (PlotSpec<Sample>(
          data: rows,
          marks: const <Mark<Sample>>[
            LineMark<Sample>(
              x: sampleTime,
              y: samplePower,
              pointKey: sampleCollidingKey,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicatePointKey),
      );
    });

    test('the same key on two DIFFERENT series is accepted', () {
      // Scoping is per SERIES, exactly as `ChartDataPoint.pointKey` documents
      // ("unique among the keyed points in one series"). Two marks that key
      // their rows the same way are the ordinary shared-x chart.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            id: 'power',
            x: sampleTime,
            y: samplePower,
            pointKey: samplePointKey,
          ),
          LineMark<Sample>(
            id: 'heart-rate',
            x: sampleTime,
            y: sampleHeartRate,
            pointKey: samplePointKey,
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(2));
      expect(lowered.series[1].points.first.pointKey, 'key-0.0');
    });

    test('key-less points do not collide with each other', () {
      // Every row yields '' here, which normalises to null. Null is "no
      // identity", not "the same identity", so this must lower cleanly — the
      // partially-keyed series an emitted chain produces depends on it.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            pointKey: sampleBlankText,
          ),
        ],
      )).lower();

      expect(lowered.series.single.points, hasLength(3));
    });

    test('an empty dataset still reports emptyData, not the key collision', () {
      // The module's ordering contract: `BravenPlot` swallows ONLY emptyData,
      // so emptyData must stay reachable for a spec that is otherwise well
      // formed. A key collision cannot be decided without rows, so on an empty
      // dataset the collision check finds nothing and emptyData wins.
      expect(
        () => (PlotSpec<Sample>(
          data: const <Sample>[],
          marks: const <Mark<Sample>>[
            LineMark<Sample>(
              x: sampleTime,
              y: samplePower,
              pointKey: sampleCollidingKey,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test('a structural error still outranks the key collision', () {
      // The collision check reads rows but sits with the shape-decidable
      // validations, so an authoring error the spec's SHAPE already condemns —
      // here an unknown axis id — is still what gets reported.
      expect(
        () => (PlotSpec<Sample>(
          data: rows,
          yAxes: <YAxisConfig>[
            YAxisConfig.withId(id: 'left', position: YAxisPosition.left),
          ],
          marks: const <Mark<Sample>>[
            LineMark<Sample>(
              x: sampleTime,
              y: samplePower,
              yAxisId: 'nope',
              pointKey: sampleCollidingKey,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownAxisId),
      );
    });
  });

  group('parity: isXOrdered', () {
    test('isXOrdered is carried EXPLICITLY, never derived from the rows', () {
      final ordered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, isXOrdered: true),
        ],
      )).lower();
      expect(ordered.series.single.isXOrdered, isTrue);

      // `rows` is ALREADY sorted ascending by time, so a lowering that derived
      // the flag from the synthesised data would flip this to true. It must
      // not: `isXOrdered` changes nearest-point behaviour (see
      // `chart_selection_expression.dart`), and deriving it would silently
      // change every existing grammar chart whose rows happen to be sorted.
      expect(
        rows.map((row) => row.time).toList(),
        <double>[0, 1, 2],
        reason:
            'the control is only meaningful while these rows ARE sorted; a '
            'derived flag would read true off them',
      );
      final notDeclared = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
      )).lower();
      expect(notDeclared.series.single.isXOrdered, isFalse);
    });

    test('every family that carries it lowers it', () {
      // Whole-map comparison so one family missed in the passthrough cannot
      // hide behind an earlier family's failure short-circuiting the loop.
      final marks = <String, Mark<Sample>>{
        'line': const LineMark<Sample>(
          x: sampleTime,
          y: samplePower,
          isXOrdered: true,
        ),
        'area': const AreaMark<Sample>(
          x: sampleTime,
          y: samplePower,
          isXOrdered: true,
        ),
        'bar': const BarMark<Sample>(
          x: sampleTime,
          y: samplePower,
          isXOrdered: true,
        ),
        'scatter': const ScatterMark<Sample>(
          x: sampleTime,
          y: samplePower,
          isXOrdered: true,
        ),
      };
      Map<String, bool> flagsOf(Map<String, Mark<Sample>> marks) =>
          <String, bool>{
            for (final entry in marks.entries)
              entry.key: (PlotSpec<Sample>(
                data: rows,
                marks: <Mark<Sample>>[entry.value],
              )).lower().series.single.isXOrdered,
          };

      expect(flagsOf(marks), <String, bool>{
        for (final family in marks.keys) family: true,
      });

      // The control, in the same shape: a hard-coded `true` in any of the four
      // passthroughs would satisfy the map above.
      expect(
        flagsOf(const <String, Mark<Sample>>{
          'line': LineMark<Sample>(x: sampleTime, y: samplePower),
          'area': AreaMark<Sample>(x: sampleTime, y: samplePower),
          'bar': BarMark<Sample>(x: sampleTime, y: samplePower),
          'scatter': ScatterMark<Sample>(x: sampleTime, y: samplePower),
        }),
        <String, bool>{for (final family in marks.keys) family: false},
      );
    });

    test('a candlestick series stays ordered by its OWN contract', () {
      // CandlestickMark deliberately has no `isXOrdered`: `CandlestickChartSeries`
      // hard-codes `isXOrdered: true` and ASSERTS against false, so a flag on
      // the mark could only ever be honoured in one position. This pins why the
      // carry stops at four families rather than five.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
          ),
        ],
      )).lower();
      expect(lowered.series.single.isXOrdered, isTrue);
    });

    test('an ordered line mark reaches config parity', () {
      // `isXOrdered` participates in `ChartSeries ==` through the base class,
      // so the whole-series parity this file is built on is load-bearing for
      // it — and it is what the emitter's round-trip proof compares.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'power',
            isXOrdered: true,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        LineChartSeries(
          id: 'power',
          points: xyPoints(),
          isXOrdered: true,
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
      );
    });
  });

  group('parity: composition', () {
    test('multi-mark specs number unlabelled marks mark-<index>', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          BarMark<Sample>(x: sampleTime, y: samplePower),
          LineMark<Sample>(x: sampleTime, y: sampleHeartRate),
          ScatterMark<Sample>(x: sampleTime, y: sampleEffort),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(lowered.series, <ChartSeries>[
        BarChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          barWidthPercent: 0.8,
        ),
        LineChartSeries(
          id: 'mark-1',
          points: <ChartDataPoint>[
            for (final row in rows)
              ChartDataPoint(x: row.time, y: row.heartRate),
          ],
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
        ScatterChartSeries(
          id: 'mark-2',
          points: <ChartDataPoint>[
            for (final row in rows) ChartDataPoint(x: row.time, y: row.effort),
          ],
          yAxisId: 'axis-0',
          yAxisConfig: axis,
        ),
      ]);
      expect(lowered.yAxes, <YAxisConfig>[axis]);
    });

    test('yAxisId hints lower onto the declared YAxisConfig slots', () {
      final powerAxis = YAxisConfig.withId(
        id: 'power',
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
      );
      final hrAxis = YAxisConfig.withId(
        id: 'hr',
        position: YAxisPosition.right,
        label: 'Heart rate',
        unit: 'bpm',
      );

      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'power'),
          LineMark<Sample>(x: sampleTime, y: sampleHeartRate, yAxisId: 'hr'),
        ],
        yAxes: <YAxisConfig>[powerAxis, hrAxis],
      )).lower();

      expect(lowered.series, <ChartSeries>[
        LineChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'power',
          yAxisConfig: powerAxis,
        ),
        LineChartSeries(
          id: 'mark-1',
          points: <ChartDataPoint>[
            for (final row in rows)
              ChartDataPoint(x: row.time, y: row.heartRate),
          ],
          yAxisId: 'hr',
          yAxisConfig: hrAxis,
        ),
      ]);
      expect(lowered.yAxes, <YAxisConfig>[powerAxis, hrAxis]);
    });

    test('an id-less declared axis is numbered axis-<index>', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'axis-0'),
          LineMark<Sample>(
            x: sampleTime,
            y: sampleHeartRate,
            yAxisId: 'axis-1',
          ),
        ],
        yAxes: <YAxisConfig>[
          YAxisConfig(position: YAxisPosition.left),
          YAxisConfig(position: YAxisPosition.right),
        ],
      )).lower();

      expect(lowered.yAxes.map((axis) => axis.id), <String>[
        'axis-0',
        'axis-1',
      ]);
      expect(lowered.series.map((series) => series.yAxisId), <String>[
        'axis-0',
        'axis-1',
      ]);
    });

    test('numbering an id-less axis preserves everything else on it', () {
      // The `.y(label:)` chain synthesizes an id-less, LABELLED left axis and
      // hands it to the lowering as a declared axis. Numbering it must not
      // strip the label — that would turn `.y(acc, label: 'Power')` into a
      // silent no-op the moment the spec was lowered.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
        yAxes: <YAxisConfig>[
          YAxisConfig(position: YAxisPosition.left, label: 'Power', unit: 'W'),
        ],
      )).lower();

      final axis = lowered.yAxes.single;
      expect(axis.id, 'axis-0');
      expect(axis.label, 'Power');
      expect(axis.unit, 'W');
      expect(axis.position, YAxisPosition.left);
      expect(lowered.series.single.yAxisConfig?.label, 'Power');
    });

    test('transposed bars lower to horizontal orientation', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          BarMark<Sample>(x: sampleTime, y: samplePower),
        ],
        transposed: true,
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        BarChartSeries(
          id: 'mark-0',
          points: xyPoints(),
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          barWidthPercent: 0.8,
          orientation: BarOrientation.horizontal,
        ),
      );
    });

    test('theme, interaction and x-axis pass through unchanged', () {
      final theme = ChartTheme.dark;
      const interaction = InteractionConfig(enableZoom: false);
      const xAxis = XAxisConfig(label: 'Time', unit: 's');

      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
        theme: theme,
        interaction: interaction,
        xAxis: xAxis,
      )).lower();

      expect(lowered.theme, same(theme));
      expect(lowered.interaction, interaction);
      expect(lowered.xAxis, xAxis);
    });
  });

  group('parity: scatter channels', () {
    test('every channel lowers to its data column and its encoding', () {
      const colorRamp = ScatterColorEncoding(
        colors: <Color>[Color(0xFF00FF00), Color(0xFFFF0000)],
        label: 'Heart rate',
        unit: 'bpm',
      );
      const categories = <ScatterCategoryStyle>[
        ScatterCategoryStyle(key: 'easy', color: Color(0xFF4CAF50)),
        ScatterCategoryStyle(key: 'hard', color: Color(0xFFF44336)),
      ];

      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          ScatterMark<Sample>(
            x: sampleTime,
            y: samplePower,
            id: 'effort',
            size: Channel<Sample>(sampleEffort, label: 'Effort'),
            colorBy: Channel<Sample>(sampleHeartRate),
            colorEncoding: colorRamp,
            opacityBy: Channel<Sample>(sampleEffort, label: 'Confidence'),
            categoryBy: CategoryChannel<Sample>(sampleZone, label: 'Zone'),
            categories: categories,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      expect(
        lowered.series.single,
        ScatterChartSeries(
          id: 'effort',
          points: <ChartDataPoint>[
            for (final row in rows)
              ChartDataPoint(
                x: row.time,
                y: row.power,
                magnitude: row.effort,
                colorValue: row.heartRate,
                opacityValue: row.effort,
                categoryValue: row.zone,
              ),
          ],
          yAxisId: 'axis-0',
          yAxisConfig: axis,
          sizeEncoding: const ScatterSizeEncoding(label: 'Effort'),
          colorEncoding: colorRamp,
          opacityEncoding: const ScatterOpacityEncoding(label: 'Confidence'),
          categoryEncoding: const ScatterCategoryEncoding(
            categories: categories,
            label: 'Zone',
          ),
        ),
      );
    });

    test('a size channel without a template uses the default encoding', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          ScatterMark<Sample>(
            x: sampleTime,
            y: samplePower,
            size: Channel<Sample>(sampleEffort),
          ),
        ],
      )).lower();

      final series = lowered.series.single as ScatterChartSeries;
      expect(series.sizeEncoding, const ScatterSizeEncoding());
      expect(series.colorEncoding, isNull);
      expect(series.opacityEncoding, isNull);
      expect(series.categoryEncoding, isNull);
      expect(
        series.points.map((point) => point.magnitude),
        rows.map((row) => row.effort),
      );
    });

    test('a channel label overrides the template label', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          ScatterMark<Sample>(
            x: sampleTime,
            y: samplePower,
            size: Channel<Sample>(sampleEffort, label: 'Channel label'),
            sizeEncoding: ScatterSizeEncoding(
              minimumRadius: 2,
              maximumRadius: 30,
              label: 'Template label',
              unit: 'N',
            ),
          ),
        ],
      )).lower();

      final series = lowered.series.single as ScatterChartSeries;
      expect(
        series.sizeEncoding,
        const ScatterSizeEncoding(
          minimumRadius: 2,
          maximumRadius: 30,
          label: 'Channel label',
          unit: 'N',
        ),
      );
    });

    test('native channel scales are accepted and change nothing', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          ScatterMark<Sample>(
            x: sampleTime,
            y: samplePower,
            size: Channel<Sample>(sampleEffort, scale: ChannelScale.sqrt),
            opacityBy: Channel<Sample>(
              sampleEffort,
              scale: ChannelScale.linear,
            ),
          ),
        ],
      )).lower();

      final series = lowered.series.single as ScatterChartSeries;
      expect(series.sizeEncoding, const ScatterSizeEncoding());
      expect(series.opacityEncoding, const ScatterOpacityEncoding());
    });
  });

  group('parity: trend', () {
    test('a trend mark lowers to a TrendAnnotation on its source series', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          TrendMark<Sample>(
            sourceMarkId: 'power',
            id: 'power-trend',
            name: 'Power trend',
            color: Color(0xFFFF9800),
            lineWidth: 1.5,
            dashPattern: <double>[6, 3],
            showConfidenceBand: true,
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(lowered.annotations, hasLength(1));

      final expected = TrendAnnotation(
        id: 'power-trend',
        label: 'Power trend',
        seriesId: 'power',
        trendType: TrendType.linear,
        showConfidenceBand: true,
        lineColor: const Color(0xFFFF9800),
        lineWidth: 1.5,
        dashPattern: const <double>[6, 3],
      );
      // ChartAnnotation has identity equality (its id is mutable and
      // auto-generated), so parity is asserted on the serialized form the
      // artifact codec reads. The lowered id is deterministic, so no field is
      // excluded.
      expect(
        (lowered.annotations.single as TrendAnnotation).toJson(),
        expected.toJson(),
      );
    });

    test('an unlabelled trend mark is numbered like any other mark', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
          TrendMark<Sample>(sourceMarkId: 'mark-0'),
        ],
      )).lower();

      expect(lowered.series.single.id, 'mark-0');
      expect(lowered.annotations.single.id, 'mark-1');
      expect(
        (lowered.annotations.single as TrendAnnotation).seriesId,
        'mark-0',
      );
    });

    test('a moving-average trend carries its window size', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          TrendMark<Sample>(
            sourceMarkId: 'power',
            id: 'ma',
            trendType: TrendType.movingAverage,
            windowSize: 2,
          ),
        ],
      )).lower();

      expect(
        (lowered.annotations.single as TrendAnnotation).toJson(),
        TrendAnnotation(
          id: 'ma',
          seriesId: 'power',
          trendType: TrendType.movingAverage,
          windowSize: 2,
        ).toJson(),
      );
    });
  });

  group('parity: reference marks', () {
    test('a threshold mark lowers to a ThresholdAnnotation', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          ThresholdMark<Sample>(
            value: 250,
            axis: AnnotationAxis.y,
            id: 'ftp',
            label: 'FTP',
            color: Color(0xFFFF9800),
            strokeWidth: 1.5,
            dashPattern: <double>[6, 3],
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(lowered.annotations, hasLength(1));
      // ChartAnnotation has identity equality, so parity is asserted on the
      // serialized form the artifact codec reads — the same approach the trend
      // parity case above uses. The lowered id is deterministic.
      expect(
        (lowered.annotations.single as ThresholdAnnotation).toJson(),
        ThresholdAnnotation(
          id: 'ftp',
          label: 'FTP',
          axis: AnnotationAxis.y,
          value: 250,
          lineColor: const Color(0xFFFF9800),
          lineWidth: 1.5,
          dashPattern: const <double>[6, 3],
        ).toJson(),
      );
    });

    test('a band mark lowers to a RangeAnnotation on the Y axis', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          BandMark<Sample>(
            start: 200,
            end: 260,
            axis: AnnotationAxis.y,
            id: 'zone',
            label: 'Threshold zone',
            color: Color(0x332563EB),
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(
        (lowered.annotations.single as RangeAnnotation).toJson(),
        RangeAnnotation(
          id: 'zone',
          label: 'Threshold zone',
          startY: 200,
          endY: 260,
          fillColor: const Color(0x332563EB),
        ).toJson(),
      );
    });

    test('a band mark on the X axis fills startX/endX only', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          BandMark<Sample>(start: 1, end: 2, axis: AnnotationAxis.x, id: 'win'),
        ],
      )).lower();

      final range = lowered.annotations.single as RangeAnnotation;
      expect(range.startX, 1);
      expect(range.endX, 2);
      expect(range.startY, isNull);
      expect(range.endY, isNull);
    });

    test('a point mark lowers to a PointAnnotation on its series', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          PointMark<Sample>(
            seriesId: 'power',
            dataPointIndex: 2,
            id: 'peak',
            label: 'Peak',
            color: Color(0xFFDC2626),
            markerSize: 12,
            markerShape: MarkerShape.star,
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(
        (lowered.annotations.single as PointAnnotation).toJson(),
        PointAnnotation(
          id: 'peak',
          label: 'Peak',
          seriesId: 'power',
          dataPointIndex: 2,
          markerColor: const Color(0xFFDC2626),
          markerSize: 12,
          markerShape: MarkerShape.star,
        ).toJson(),
      );
    });

    test('an unlabelled reference mark is numbered like any other mark', () {
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
          ThresholdMark<Sample>(value: 250),
        ],
      )).lower();

      expect(lowered.series.single.id, 'mark-0');
      expect(lowered.annotations.single.id, 'mark-1');
    });

    test('reference marks bind no Y axis of their own', () {
      // A threshold + a single geometry must not declare a second axis, and
      // must not leave the geometry's axis unbound.
      final lowered = (PlotSpec<Sample>(
        data: rows,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
          ThresholdMark<Sample>(value: 250),
        ],
      )).lower();

      expect(lowered.yAxes, hasLength(1));
    });
  });

  group('non-finite values', () {
    test('Cartesian point families carry non-finite values through', () {
      const gapped = <Sample>[
        Sample(time: 0, power: 180, heartRate: 1, effort: 1, zone: 'a'),
        Sample(time: 1, power: double.nan, heartRate: 1, effort: 1, zone: 'a'),
        Sample(time: 2, power: 260, heartRate: 1, effort: 1, zone: 'a'),
      ];

      final lowered = (PlotSpec<Sample>(
        data: gapped,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
      )).lower();

      final points = lowered.series.single.points;
      expect(points, hasLength(3));
      expect(points[1].y.isNaN, isTrue);
      expect(points[1].isValid, isFalse);
    });

    test('candlestick rows reject non-finite values with a named code', () {
      const broken = <Sample>[
        Sample(
          time: 0,
          power: 1,
          heartRate: 1,
          effort: 1,
          zone: 'a',
          open: 10,
          high: double.infinity,
          low: 9,
          close: 11,
        ),
      ];

      expect(
        () => (PlotSpec<Sample>(
          data: broken,
          marks: const <Mark<Sample>>[
            CandlestickMark<Sample>(
              x: sampleTime,
              open: sampleOpen,
              high: sampleHigh,
              low: sampleLow,
              close: sampleClose,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidCandlestickRow),
      );
    });

    test('candlestick rows reject a violated OHLC invariant', () {
      const broken = <Sample>[
        Sample(
          time: 0,
          power: 1,
          heartRate: 1,
          effort: 1,
          zone: 'a',
          open: 10,
          high: 5,
          low: 9,
          close: 11,
        ),
      ];

      expect(
        () => (PlotSpec<Sample>(
          data: broken,
          marks: const <Mark<Sample>>[
            CandlestickMark<Sample>(
              x: sampleTime,
              open: sampleOpen,
              high: sampleHigh,
              low: sampleLow,
              close: sampleClose,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidCandlestickRow),
      );
    });
  });

  group('validation', () {
    test('an empty mark list is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyMarks),
      );
    });

    test('an empty data list is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: <Sample>[],
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test('duplicate mark ids are rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'same'),
            LineMark<Sample>(x: sampleTime, y: sampleHeartRate, id: 'same'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateMarkId),
      );
    });

    test('a trend over an unknown mark id is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
            TrendMark<Sample>(sourceMarkId: 'cadence'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });

    test('a trend over another trend is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
            TrendMark<Sample>(sourceMarkId: 'power', id: 'first'),
            TrendMark<Sample>(sourceMarkId: 'first'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });

    test('a moving-average trend without a window size is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
            TrendMark<Sample>(
              sourceMarkId: 'power',
              trendType: TrendType.movingAverage,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidTrendWindow),
      );
    });

    test('a mark bound to an unknown axis id is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'nowhere'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownAxisId),
      );
    });

    test('duplicate axis ids are rejected', () {
      expect(
        () => (PlotSpec<Sample>(
          data: rows,
          marks: const <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'a'),
          ],
          yAxes: <YAxisConfig>[
            YAxisConfig.withId(id: 'a', position: YAxisPosition.left),
            YAxisConfig.withId(id: 'a', position: YAxisPosition.right),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateAxisId),
      );
    });

    test('an axis no mark measures against is rejected', () {
      expect(
        () => (PlotSpec<Sample>(
          data: rows,
          marks: const <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'a'),
          ],
          yAxes: <YAxisConfig>[
            YAxisConfig.withId(id: 'a', position: YAxisPosition.left),
            YAxisConfig.withId(id: 'b', position: YAxisPosition.right),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unboundAxis),
      );
    });

    test('a color channel without a ramp is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              colorBy: Channel<Sample>(sampleHeartRate),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.missingChannelEncoding),
      );
    });

    test('a category channel without category styles is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              categoryBy: CategoryChannel<Sample>(sampleZone),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.missingChannelEncoding),
      );
    });

    test('an orphan color encoding (no colorBy) is rejected', () {
      // The mirror image of the missing-encoding check: an encoding with no
      // channel to drive it would be silently inert, which the module's
      // fail-fast contract forbids.
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              colorEncoding: ScatterColorEncoding(
                colors: <Color>[Color(0xFF16A34A), Color(0xFFDC2626)],
              ),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.orphanChannelEncoding),
      );
    });

    test('an orphan size encoding (no size) is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              sizeEncoding: ScatterSizeEncoding(label: 'Effort'),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.orphanChannelEncoding),
      );
    });

    test('an orphan category style list (no categoryBy) is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              categories: <ScatterCategoryStyle>[
                ScatterCategoryStyle(key: 'easy', color: Color(0xFF16A34A)),
              ],
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.orphanChannelEncoding),
      );
    });

    test('a non-native channel scale is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              size: Channel<Sample>(sampleEffort, scale: ChannelScale.linear),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unsupportedChannelScale),
      );
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              opacityBy: Channel<Sample>(
                sampleEffort,
                scale: ChannelScale.sqrt,
              ),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unsupportedChannelScale),
      );
    });

    test('transposing a non-bar geometry is rejected', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            BarMark<Sample>(x: sampleTime, y: samplePower),
            LineMark<Sample>(x: sampleTime, y: sampleHeartRate),
          ],
          transposed: true,
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unsupportedTransposition),
      );
    });

    test('every diagnostic names its code in toString', () {
      final error = GrammarSpecException.emptyMarks();
      expect(error.code, GrammarDiagnosticCode.emptyMarks);
      expect(error.toString(), contains('emptyMarks'));
      expect(error.message, isNotEmpty);
      // Reserved for the Task 12 facade: a geom that inherits no x/y.
      final missing = GrammarSpecException.missingEncoding('geomLine', 'y');
      expect(missing.code, GrammarDiagnosticCode.missingEncoding);
      expect(missing.message, contains('geomLine'));
      expect(missing.message, contains('y'));
    });
  });

  group('structural errors surface even when the data is empty', () {
    // The emptyData guard runs AFTER every data-INDEPENDENT structural check,
    // so a spec wired against an initially-empty dataset (a cleared filter, a
    // pending fetch) still reports its authoring errors instead of masquerading
    // as a clean chart that only throws once real rows arrive. BravenPlot may
    // therefore swallow ONLY an empty-but-otherwise-well-formed spec.
    const emptyRows = <Sample>[];

    test('duplicate mark ids beat the empty-data guard', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'same'),
            LineMark<Sample>(x: sampleTime, y: sampleHeartRate, id: 'same'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateMarkId),
      );
    });

    test('an unknown trend source beats the empty-data guard', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, id: 'power'),
            TrendMark<Sample>(sourceMarkId: 'nope'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });

    test('a channel without its encoding beats the empty-data guard', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              x: sampleTime,
              y: samplePower,
              colorBy: Channel<Sample>(sampleHeartRate),
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.missingChannelEncoding),
      );
    });

    test('an unbound axis beats the empty-data guard', () {
      expect(
        () => (PlotSpec<Sample>(
          data: emptyRows,
          marks: const <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'a'),
          ],
          yAxes: <YAxisConfig>[
            YAxisConfig.withId(id: 'a', position: YAxisPosition.left),
            YAxisConfig.withId(id: 'b', position: YAxisPosition.right),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unboundAxis),
      );
    });

    test('an unknown axis binding beats the empty-data guard', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower, yAxisId: 'nowhere'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownAxisId),
      );
    });

    test('an unsupported transposition beats the empty-data guard', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            BarMark<Sample>(x: sampleTime, y: samplePower),
            LineMark<Sample>(x: sampleTime, y: sampleHeartRate),
          ],
          transposed: true,
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.unsupportedTransposition),
      );
    });

    test('an empty-but-well-formed spec still reports emptyData', () {
      // The one case BravenPlot is allowed to swallow: nothing structurally
      // wrong, just no rows yet.
      expect(
        () => (const PlotSpec<Sample>(
          data: emptyRows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });
  });

  group('faceting rejects the single-panel lowering', () {
    test('lower() on a faceted spec throws facetedSpecNotLowerable', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(x: sampleTime, y: samplePower),
          ],
          facet: FacetSpec<Sample>(by: sampleZone),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('the facet rejection beats every other diagnostic', () {
      // A faceted spec that is ALSO otherwise broken (no marks) still reports
      // the facet-path error first — the caller reached for the wrong terminal.
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[],
          facet: FacetSpec<Sample>(by: sampleZone),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('the new diagnostics name their codes in toString', () {
      expect(
        GrammarSpecException.notFaceted().code,
        GrammarDiagnosticCode.notFaceted,
      );
      expect(
        GrammarSpecException.emptyFacetValues().code,
        GrammarDiagnosticCode.emptyFacetValues,
      );
      final capped = GrammarSpecException.facetPanelCapExceeded(64, 50);
      expect(capped.code, GrammarDiagnosticCode.facetPanelCapExceeded);
      expect(capped.message, contains('64'));
      expect(capped.message, contains('50'));
    });
  });

  group('range area lowering', () {
    test('lowers to a RangeAreaChartSeries carrying every native field', () {
      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(
            id: 'band',
            low: (row) => row.low,
            high: (row) => row.high,
            name: 'Recovery',
            color: const Color(0xFF2563EB),
            unit: 'score',
            interpolation: LineInterpolation.monotone,
            tension: 0.4,
            fillOpacity: 0.22,
            borderMode: RangeAreaBorderMode.closed,
            upperBoundaryStyle: const RangeAreaBoundaryStyle(strokeWidth: 2),
            lowerBoundaryStyle: const RangeAreaBoundaryStyle(glowRadius: 3),
            connectGaps: true,
            showBoundaryMarkers: true,
            markerRadius: 4,
            labelConfig: const RangeAreaLabelConfig(
              value: RangeAreaLabelValue.both,
            ),
            hitTestMode: RangeAreaHitTestMode.nearestBoundary,
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.id, 'band');
      expect(series.name, 'Recovery');
      expect(series.color, const Color(0xFF2563EB));
      expect(series.unit, 'score');
      expect(series.interpolation, LineInterpolation.monotone);
      expect(series.tension, 0.4);
      expect(series.fillOpacity, 0.22);
      expect(series.borderMode, RangeAreaBorderMode.closed);
      expect(series.upperBoundaryStyle.strokeWidth, 2);
      expect(series.lowerBoundaryStyle.glowRadius, 3);
      expect(series.connectGaps, isTrue);
      expect(series.showBoundaryMarkers, isTrue);
      expect(series.markerRadius, 4);
      expect(series.labelConfig.value, RangeAreaLabelValue.both);
      expect(series.hitTestMode, RangeAreaHitTestMode.nearestBoundary);
      expect(series.intervals.first.low, 1);
      expect(series.intervals.first.high, 3);
    });

    test('an unset field lowers to the series default, not to a copy of it', () {
      // The assertion is against a FRESHLY CONSTRUCTED series, so it tracks the
      // class rather than restating today's literals. A default that changed on
      // RangeAreaChartSeries and not in the lowering fails here.
      final reference = RangeAreaChartSeries(
        id: 'reference',
        points: <RangeAreaDataPoint>[RangeAreaDataPoint(x: 0, low: 1, high: 3)],
      );

      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(low: (row) => row.low, high: (row) => row.high)
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.interpolation, reference.interpolation);
      expect(series.tension, reference.tension);
      expect(series.fillOpacity, reference.fillOpacity);
      expect(series.borderMode, reference.borderMode);
      expect(series.upperBoundaryStyle, reference.upperBoundaryStyle);
      expect(series.lowerBoundaryStyle, reference.lowerBoundaryStyle);
      expect(series.connectGaps, reference.connectGaps);
      expect(series.showBoundaryMarkers, reference.showBoundaryMarkers);
      expect(series.markerRadius, reference.markerRadius);
      expect(series.labelConfig, reference.labelConfig);
      expect(series.hitTestMode, reference.hitTestMode);
    });

    test('both bounds null lowers that row to a gap', () {
      const rows = <_BandRow>[
        _BandRow(0, 1, 3),
        _BandRow(1, null, null),
        _BandRow(2, 2, 4),
      ];

      final lowered = BravenChart.of(rows)
          .x((row) => row.x)
          .geomRangeArea(low: (row) => row.low, high: (row) => row.high)
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.hasGaps, isTrue);
      expect(series.intervals.map((i) => i.isGap), <bool>[false, true, false]);
      expect(series.intervals[1].x, 2 - 1); // the gap keeps its own x
    });

    test('exactly one bound null is refused by NAME with the row index', () {
      const rows = <_BandRow>[_BandRow(0, 1, 3), _BandRow(1, 2, null)];

      expect(
        () => BravenChart.of(rows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>()
              .having(
                (e) => e.code,
                'code',
                GrammarDiagnosticCode.incompleteRangeAreaInterval,
              )
              .having((e) => e.message, 'message', contains('Row 1'))
              .having((e) => e.message, 'message', contains('"band"')),
        ),
      );
    });

    test('unsorted rows are refused by NAME, not as a raw ArgumentError', () {
      // The offending row is index 2, NOT 0: the row number in the message has
      // to come from the constructor's `points[N]` name, so a lowering that
      // fell back to a default index would report the wrong row here.
      const rows = <_BandRow>[
        _BandRow(0, 1, 3),
        _BandRow(5, 2, 4),
        _BandRow(1, 2, 4),
      ];

      expect(
        () => BravenChart.of(rows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>()
              .having(
                (e) => e.code,
                'code',
                GrammarDiagnosticCode.invalidRangeAreaRow,
              )
              .having((e) => e.message, 'message', contains('Row 2'))
              .having((e) => e.message, 'message', isNot(contains('Row 0'))),
        ),
      );
    });

    test(
      'high < low is refused by NAME rather than escaping as ArgumentError',
      () {
        const rows = <_BandRow>[_BandRow(0, 5, 1)];

        expect(
          () => BravenChart.of(rows)
              .x((row) => row.x)
              .geomRangeArea(
                id: 'band',
                low: (row) => row.low,
                high: (row) => row.high,
              )
              .toSpec()
              .lower(),
          throwsA(
            isA<GrammarSpecException>().having(
              (e) => e.code,
              'code',
              GrammarDiagnosticCode.invalidRangeAreaRow,
            ),
          ),
        );
      },
    );

    // A styling argument the series refuses is NOT a bad row. The band's rows
    // below are all valid, so a diagnostic that names a row — or claims the
    // band holds an invalid interval — would be describing something that did
    // not happen.
    void expectStyleRefusal(
      BravenChart<_BandRow> chart, {
      required String parameter,
    }) {
      expect(
        () => chart.toSpec().lower(),
        throwsA(
          isA<GrammarSpecException>()
              .having(
                (e) => e.code,
                'code',
                GrammarDiagnosticCode.invalidRangeAreaStyle,
              )
              .having((e) => e.message, 'message', contains(parameter))
              .having((e) => e.message, 'message', contains('"band"'))
              .having(
                (e) => e.message,
                'message',
                isNot(contains('is not a valid interval')),
              )
              .having((e) => e.message, 'message', isNot(contains('Row '))),
        ),
      );
    }

    test(
      'an out-of-range tension is refused as a STYLE failure, not a row',
      () {
        expectStyleRefusal(
          BravenChart.of(_bandRows)
              .x((row) => row.x)
              .geomRangeArea(
                id: 'band',
                low: (row) => row.low,
                high: (row) => row.high,
                tension: 5,
              ),
          parameter: 'tension',
        );
      },
    );

    test('an out-of-range fillOpacity is refused as a STYLE failure', () {
      expectStyleRefusal(
        BravenChart.of(_bandRows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
              fillOpacity: 1.5,
            ),
        parameter: 'fillOpacity',
      );
    });

    test(
      'an odd-length boundary dashPattern is refused as a STYLE failure',
      () {
        expectStyleRefusal(
          BravenChart.of(_bandRows)
              .x((row) => row.x)
              .geomRangeArea(
                id: 'band',
                low: (row) => row.low,
                high: (row) => row.high,
                upperBoundaryStyle: const RangeAreaBoundaryStyle(
                  dashPattern: <double>[4],
                ),
              ),
          parameter: 'upperBoundaryStyle.dashPattern',
        );
      },
    );

    test('per-point label and key reach the lowered points', () {
      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(
            low: (row) => row.low,
            high: (row) => row.high,
            label: (row) => 'point-${row.x.toInt()}',
            pointKey: (row) => 'key-${row.x.toInt()}',
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.intervals.first.label, 'point-0');
      expect(series.intervals.first.pointKey, 'key-0');
    });

    test(
      'a duplicate point key is refused, as on every other Cartesian mark',
      () {
        expect(
          () => BravenChart.of(_bandRows)
              .x((row) => row.x)
              .geomRangeArea(
                id: 'band',
                low: (row) => row.low,
                high: (row) => row.high,
                pointKey: (row) => 'same',
              )
              .toSpec()
              .lower(),
          throwsA(
            isA<GrammarSpecException>().having(
              (e) => e.code,
              'code',
              GrammarDiagnosticCode.duplicatePointKey,
            ),
          ),
        );
      },
    );
  });

  group('line path fields', () {
    test('every path field lowers onto the series', () {
      final lowered = BravenChart.of(_pathRows)
          .x((row) => row.x)
          .geomLine(
            y: (row) => row.y,
            tension: 0.6,
            dataPointMarkerRadius: 4.5,
            dataPointMarkerStyle: DataPointMarkerStyle.hollow,
            dataPointMarkerBackground: const Color(0xFF0F172A),
            lineGlow: 3,
            inlineLabel: const SeriesInlineLabelConfig(text: 'Load'),
            pathAnimation: const PathAnimationStyle(
              entranceMode: PathEntranceAnimationMode.reveal,
            ),
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as LineChartSeries;
      expect(series.tension, 0.6);
      expect(series.dataPointMarkerRadius, 4.5);
      expect(series.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
      expect(series.dataPointMarkerBackground, const Color(0xFF0F172A));
      expect(series.lineGlow, 3);
      expect(series.inlineLabel?.text, 'Load');
      expect(
        series.pathAnimation.entranceMode,
        PathEntranceAnimationMode.reveal,
      );
    });

    test(
      'an unset path field lowers to the series default, tracked not copied',
      () {
        // Compared against a FRESHLY CONSTRUCTED series so this tracks the class
        // rather than restating today's literals.
        const reference = LineChartSeries(
          id: 'reference',
          points: <ChartDataPoint>[],
        );

        final lowered = BravenChart.of(
          _pathRows,
        ).x((row) => row.x).geomLine(y: (row) => row.y).toSpec().lower();

        final series = lowered.series.single as LineChartSeries;
        expect(series.tension, reference.tension);
        expect(series.dataPointMarkerRadius, reference.dataPointMarkerRadius);
        expect(series.dataPointMarkerStyle, reference.dataPointMarkerStyle);
        expect(
          series.dataPointMarkerBackground,
          reference.dataPointMarkerBackground,
        );
        expect(series.lineGlow, reference.lineGlow);
        expect(series.inlineLabel, reference.inlineLabel);
        expect(series.pathAnimation, reference.pathAnimation);
      },
    );
  });
}

class _PathRow {
  const _PathRow(this.x, this.y);
  final double x;
  final double y;
}

const List<_PathRow> _pathRows = <_PathRow>[_PathRow(0, 1), _PathRow(1, 2)];

class _BandRow {
  const _BandRow(this.x, this.low, this.high);
  final double x;
  final double? low;
  final double? high;
}

const List<_BandRow> _bandRows = <_BandRow>[
  _BandRow(0, 1, 3),
  _BandRow(1, 2, 4),
];
