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
}
