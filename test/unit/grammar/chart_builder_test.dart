// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Equivalence of the chained [BravenChart] facade with hand-written specs.
///
/// The facade contains NO lowering logic: its whole job is to build a
/// [PlotSpec], so every test here asserts `toSpec()` against the spec a user
/// would type by hand. That keeps exactly one description of what each verb
/// means, and it means the lowering parity suite covers the facade for free.
///
/// Accessors are top-level tear-offs on both sides on purpose: `PlotSpec`,
/// `Mark` and `Channel` have value equality, but a closure compares by
/// IDENTITY, so `(row) => row.power` written twice is two different marks.
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

const powerRamp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF16A34A), Color(0xFFDC2626)],
);
const zoneStyles = <ScatterCategoryStyle>[
  ScatterCategoryStyle(key: 'easy', color: Color(0xFF16A34A)),
  ScatterCategoryStyle(key: 'hard', color: Color(0xFFDC2626)),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  group('one geom per family equals the hand-written spec', () {
    test('geomLine', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine(
            name: 'Power',
            color: const Color(0xFF2563EB),
            strokeWidth: 3,
            dashPattern: const <double>[4, 2],
            interpolation: LineInterpolation.monotone,
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              color: Color(0xFF2563EB),
              strokeWidth: 3,
              dashPattern: <double>[4, 2],
              interpolation: LineInterpolation.monotone,
            ),
          ],
        ),
      );
    });

    test('geomArea', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomArea(name: 'Power', baseline: 100, fillOpacity: 0.2)
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            AreaMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              baseline: 100,
              fillOpacity: 0.2,
            ),
          ],
        ),
      );
    });

    test('geomBar', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomBar(
            name: 'Power',
            barWidthPercent: 0.6,
            layoutMode: BarLayoutMode.stacked,
            groupId: 'ride',
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            BarMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              barWidthPercent: 0.6,
              layoutMode: BarLayoutMode.stacked,
              groupId: 'ride',
            ),
          ],
        ),
      );
    });

    test('geomLine threads data-point markers and labels into the mark', () {
      const labels = DataPointLabelConfig(
        show: true,
        position: DataPointLabelPosition.below,
      );
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine(
            name: 'Power',
            showDataPointMarkers: true,
            dataPointLabels: labels,
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              showDataPointMarkers: true,
              dataPointLabels: labels,
            ),
          ],
        ),
      );
    });

    test('geomArea threads data-point markers and labels into the mark', () {
      const labels = DataPointLabelConfig(show: true);
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomArea(
            name: 'Power',
            showDataPointMarkers: true,
            dataPointLabels: labels,
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            AreaMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              showDataPointMarkers: true,
              dataPointLabels: labels,
            ),
          ],
        ),
      );
    });

    test('geomBar threads a label style into the mark', () {
      const barLabels = BarLabelStyle(show: true, showUnit: true);
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomBar(name: 'Power', labelStyle: barLabels)
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            BarMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
              labelStyle: barLabels,
            ),
          ],
        ),
      );
    });

    test('geomPoint with every channel and its encoding template', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomPoint(
            name: 'Efforts',
            size: const Channel<Sample>(sampleEffort, label: 'Effort'),
            colorBy: const Channel<Sample>(sampleHeartRate, label: 'HR'),
            colorEncoding: powerRamp,
            opacityBy: const Channel<Sample>(sampleEffort),
            opacityEncoding: const ScatterOpacityEncoding(minimumOpacity: 0.2),
            categoryBy: const CategoryChannel<Sample>(
              sampleZone,
              label: 'Zone',
            ),
            categories: zoneStyles,
            markerRadius: 5,
            markerShape: SeriesMarkerShape.diamond,
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            ScatterMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Efforts',
              size: Channel<Sample>(sampleEffort, label: 'Effort'),
              colorBy: Channel<Sample>(sampleHeartRate, label: 'HR'),
              colorEncoding: powerRamp,
              opacityBy: Channel<Sample>(sampleEffort),
              opacityEncoding: ScatterOpacityEncoding(minimumOpacity: 0.2),
              categoryBy: CategoryChannel<Sample>(sampleZone, label: 'Zone'),
              categories: zoneStyles,
              markerRadius: 5,
              markerShape: SeriesMarkerShape.diamond,
            ),
          ],
        ),
      );
    });

    test('geomCandlestick', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .geomCandlestick(
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
            name: 'Price',
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            CandlestickMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              open: sampleOpen,
              high: sampleHigh,
              low: sampleLow,
              close: sampleClose,
              name: 'Price',
            ),
          ],
        ),
      );
    });

    test('trend defaults its source to the preceding geometry', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine(name: 'Power')
          .trend(method: TrendType.movingAverage, windowSize: 3, name: 'MA3')
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
            ),
            TrendMark<Sample>(
              id: 'mark-1',
              sourceMarkId: 'mark-0',
              trendType: TrendType.movingAverage,
              windowSize: 3,
              name: 'MA3',
            ),
          ],
        ),
      );
    });

    test('trend can name an earlier geometry explicitly', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .geomLine(id: 'power', y: samplePower)
          .geomLine(id: 'hr', y: sampleHeartRate)
          .trend(of: 'power')
          .toSpec();

      expect((spec.marks.last as TrendMark<Sample>).sourceMarkId, 'power');
    });
  });

  group('reference marks', () {
    test('threshold appends a ThresholdMark with an explicit id', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine(name: 'Power')
          .threshold(
            value: 250,
            axis: AnnotationAxis.y,
            label: 'FTP',
            color: const Color(0xFFFF9800),
            strokeWidth: 1.5,
            dashPattern: const <double>[6, 3],
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
            ),
            ThresholdMark<Sample>(
              id: 'mark-1',
              value: 250,
              axis: AnnotationAxis.y,
              label: 'FTP',
              color: Color(0xFFFF9800),
              strokeWidth: 1.5,
              dashPattern: <double>[6, 3],
            ),
          ],
        ),
      );
    });

    test('band appends a BandMark with an explicit id', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .band(
            start: 200,
            end: 260,
            label: 'Zone',
            color: const Color(0x332563EB),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(id: 'mark-0', x: sampleTime, y: samplePower),
            BandMark<Sample>(
              id: 'mark-1',
              start: 200,
              end: 260,
              label: 'Zone',
              color: Color(0x332563EB),
            ),
          ],
        ),
      );
    });

    test('pointAt appends a PointMark bound to a series point', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .geomLine(id: 'power', y: samplePower)
          .pointAt(
            seriesId: 'power',
            dataPointIndex: 2,
            label: 'Peak',
            markerSize: 12,
            markerShape: MarkerShape.star,
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(id: 'power', x: sampleTime, y: samplePower),
            PointMark<Sample>(
              id: 'mark-1',
              seriesId: 'power',
              dataPointIndex: 2,
              label: 'Peak',
              markerSize: 12,
              markerShape: MarkerShape.star,
            ),
          ],
        ),
      );
    });

    test('a threshold is not a valid trend source', () {
      // Reference marks are excluded from the geometry set, so a trend cannot
      // fit over one.
      expect(
        () => BravenChart.of(
          rows,
        ).x(sampleTime).y(samplePower).threshold(value: 250).trend(),
        throwsA(isA<GrammarSpecException>()),
      );
    });
  });

  group('encoding defaults', () {
    test('geoms inherit the chain-level x and y', () {
      final spec = BravenChart.of(
        rows,
      ).x(sampleTime).y(samplePower).geomLine().geomBar().toSpec();

      expect(spec.marks, <Mark<Sample>>[
        const LineMark<Sample>(id: 'mark-0', x: sampleTime, y: samplePower),
        const BarMark<Sample>(id: 'mark-1', x: sampleTime, y: samplePower),
      ]);
    });

    test(
      'a per-geom accessor overrides the chain default for that geom only',
      () {
        final spec = BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine()
            .geomLine(y: sampleHeartRate)
            .geomLine()
            .toSpec();

        expect(
          spec.marks.map((mark) => (mark as LineMark<Sample>).y),
          <FieldAccessor<Sample, num>>[
            samplePower,
            sampleHeartRate,
            samplePower,
          ],
        );
      },
    );

    test('x and y labels name the axes when none are configured', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime, label: 'Elapsed')
          .y(samplePower, label: 'Power')
          .geomLine()
          .toSpec();

      expect(spec.xAxis, const XAxisConfig(label: 'Elapsed'));
      expect(spec.yAxes.single.label, 'Power');
      expect(spec.yAxes.single.position, YAxisPosition.left);
    });

    test('an explicitly configured axis wins over the channel label', () {
      final bpm = YAxisConfig.withId(
        id: 'bpm',
        position: YAxisPosition.right,
        label: 'Heart rate',
      );
      final spec = BravenChart.of(rows)
          .x(sampleTime, label: 'Elapsed')
          .y(samplePower, label: 'Power')
          .xAxis(const XAxisConfig(label: 'Time', unit: 's'))
          .yAxis(bpm)
          .geomLine(yAxisId: 'bpm')
          .toSpec();

      expect(spec.xAxis, const XAxisConfig(label: 'Time', unit: 's'));
      expect(spec.yAxes, <YAxisConfig>[bpm]);
    });

    // The two tests above stop at `toSpec()`. The label only matters if it
    // survives LOWERING as well — a chain label that reaches the spec and is
    // then dropped on the way to `YAxisConfig` would still be a silent no-op,
    // and would make the Chart Grammar page's hand-built comparison a lie.
    test('the .y label survives lowering onto the synthesized axis', () {
      final lowered = BravenChart.of(rows)
          .x(sampleTime, label: 'Elapsed')
          .y(samplePower, label: 'Power')
          .geomLine()
          .toSpec()
          .lower();

      expect(lowered.yAxes.single.id, 'axis-0');
      expect(lowered.yAxes.single.label, 'Power');
      expect(lowered.yAxes.single.position, YAxisPosition.left);
      expect(lowered.series.single.yAxisConfig?.label, 'Power');
      expect(lowered.xAxis, const XAxisConfig(label: 'Elapsed'));
    });

    test('an explicit .yAxis() still wins after lowering', () {
      final bpm = YAxisConfig.withId(
        id: 'bpm',
        position: YAxisPosition.right,
        label: 'Heart rate',
      );
      final lowered = BravenChart.of(rows)
          .y(samplePower, label: 'Power')
          .yAxis(bpm)
          .geomLine(x: sampleTime, yAxisId: 'bpm')
          .toSpec()
          .lower();

      expect(lowered.yAxes, <YAxisConfig>[bpm]);
      expect(lowered.yAxes.single.label, 'Heart rate');
      expect(lowered.series.single.yAxisConfig, bpm);
    });

    test('no .y label leaves the synthesized axis unlabelled', () {
      final lowered = BravenChart.of(
        rows,
      ).x(sampleTime).y(samplePower).geomLine().toSpec().lower();

      expect(lowered.yAxes.single.id, 'axis-0');
      expect(lowered.yAxes.single.label, isNull);
    });
  });

  group('missing encodings fail at the geom call, not at build', () {
    test('geomLine without any x', () {
      expect(
        () => BravenChart.of(rows).y(samplePower).geomLine(),
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
    });

    test('geomLine without any y', () {
      expect(
        () => BravenChart.of(rows).x(sampleTime).geomLine(),
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
    });

    test('geomArea, geomBar and geomPoint fail the same way', () {
      final bare = BravenChart.of(rows);
      expect(
        bare.geomArea,
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
      expect(
        bare.geomBar,
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
      expect(
        bare.geomPoint,
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
    });

    test('geomCandlestick without an x', () {
      expect(
        () => BravenChart.of(rows).geomCandlestick(
          open: sampleOpen,
          high: sampleHigh,
          low: sampleLow,
          close: sampleClose,
        ),
        throwsGrammarCode(GrammarDiagnosticCode.missingEncoding),
      );
    });

    test('the message names the verb and the channel', () {
      expect(
        () => BravenChart.of(rows).y(samplePower).geomLine(),
        throwsA(
          isA<GrammarSpecException>().having(
            (error) => error.message,
            'message',
            allOf(contains('geomLine()'), contains('x')),
          ),
        ),
      );
    });

    test('a trend with nothing to fit fails at the call', () {
      expect(
        () => BravenChart.of(rows).trend(),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });

    test('a trend naming an unknown mark fails at the call', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine(id: 'power')
            .trend(of: 'cadence'),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });

    test('a trend cannot be fitted over another trend', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine(id: 'power')
            .trend(id: 'power-trend')
            .trend(of: 'power-trend'),
        throwsGrammarCode(GrammarDiagnosticCode.unknownTrendSource),
      );
    });
  });

  group('every verb returns a new builder', () {
    test('an intermediate builder is unchanged by later chaining', () {
      final base = BravenChart.of(rows).x(sampleTime).y(samplePower);
      final oneMark = base.geomLine();
      final twoMarks = oneMark.geomBar().transposed().theme(ChartTheme.dark);

      expect(base.toSpec().marks, isEmpty);
      expect(oneMark.toSpec().marks, hasLength(1));
      expect(oneMark.toSpec().transposed, isFalse);
      expect(oneMark.toSpec().theme, isNull);
      expect(twoMarks.toSpec().marks, hasLength(2));
      expect(twoMarks.toSpec().transposed, isTrue);
      expect(twoMarks.toSpec().theme, ChartTheme.dark);
    });

    test('branching a chain twice produces two independent specs', () {
      final base = BravenChart.of(rows).x(sampleTime).y(samplePower);
      final lines = base.geomLine();
      final bars = base.geomBar();

      expect(lines.toSpec().marks.single, isA<LineMark<Sample>>());
      expect(bars.toSpec().marks.single, isA<BarMark<Sample>>());
    });

    test('yAxis is repeatable and keeps declaration order', () {
      final watts = YAxisConfig.withId(
        id: 'watts',
        position: YAxisPosition.left,
      );
      final bpm = YAxisConfig.withId(id: 'bpm', position: YAxisPosition.right);
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .yAxis(watts)
          .yAxis(bpm)
          .geomLine(yAxisId: 'watts')
          .geomLine(y: sampleHeartRate, yAxisId: 'bpm')
          .toSpec();

      expect(spec.yAxes, <YAxisConfig>[watts, bpm]);
    });

    test('transposed, theme, interaction and xAxis reach the spec', () {
      const interaction = InteractionConfig(enableZoom: false);
      const xAxis = XAxisConfig(label: 'Time', unit: 's');
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomBar()
          .transposed()
          .theme(ChartTheme.dark)
          .interaction(interaction)
          .xAxis(xAxis)
          .toSpec();

      expect(spec.transposed, isTrue);
      expect(spec.theme, ChartTheme.dark);
      expect(spec.interaction, interaction);
      expect(spec.xAxis, xAxis);
    });
  });

  group('chart-level options reach the spec', () {
    test('.grid, .title and .legend equal the hand-written spec', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine(name: 'Power')
          .grid(const GridConfig(horizontal: false, verticalStrokeWidth: 1.5))
          .title('Session', subtitle: 'Power over time')
          .legend(false)
          .toSpec();

      expect(
        spec,
        const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[
            LineMark<Sample>(
              id: 'mark-0',
              x: sampleTime,
              y: samplePower,
              name: 'Power',
            ),
          ],
          grid: GridConfig(horizontal: false, verticalStrokeWidth: 1.5),
          title: 'Session',
          subtitle: 'Power over time',
          showLegend: false,
        ),
      );
    });

    test('.title without a subtitle leaves the subtitle unset', () {
      final spec = BravenChart.of(
        rows,
      ).x(sampleTime).y(samplePower).geomLine().title('Only a title').toSpec();

      expect(spec.title, 'Only a title');
      expect(spec.subtitle, isNull);
    });

    test('chart-level options default to unset when no verb is called', () {
      final spec = BravenChart.of(
        rows,
      ).x(sampleTime).y(samplePower).geomLine().toSpec();

      expect(spec.grid, isNull);
      expect(spec.title, isNull);
      expect(spec.subtitle, isNull);
      expect(spec.showLegend, isNull);
    });
  });

  group('build', () {
    testWidgets('build() returns a BravenPlot over the same spec', (
      tester,
    ) async {
      final chart = BravenChart.of(
        rows,
      ).x(sampleTime).y(samplePower).geomLine(name: 'Power');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: chart.build(key: const ValueKey<String>('plot')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final plot = tester.widget<BravenPlot<Sample>>(
        find.byType(BravenPlot<Sample>),
      );
      expect(plot.spec, chart.toSpec());
      expect(plot.key, const ValueKey<String>('plot'));
    });

    testWidgets('a full realistic chain pumps, paints and extracts', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      // SHOWCASE CHAIN — kept in sync with the authoring-code card on the
      // Chart Grammar page. Area + moving-average trend on the power axis, a
      // heart-rate line on its own axis, and a channel-encoded scatter.
      final chart = BravenChart.of(rows)
          .x(sampleTime, label: 'Elapsed (min)')
          .y(samplePower)
          .yAxis(
            YAxisConfig.withId(
              id: 'watts',
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
            ),
          )
          .yAxis(
            YAxisConfig.withId(
              id: 'bpm',
              position: YAxisPosition.right,
              label: 'Heart rate',
              unit: 'bpm',
            ),
          )
          .geomArea(
            id: 'power',
            name: 'Power',
            yAxisId: 'watts',
            color: const Color(0xFF2563EB),
            fillOpacity: 0.18,
          )
          .trend(
            method: TrendType.movingAverage,
            windowSize: 3,
            name: '3-sample average',
            color: const Color(0xFF1D4ED8),
          )
          .geomLine(
            id: 'hr',
            y: sampleHeartRate,
            name: 'Heart rate',
            yAxisId: 'bpm',
            color: const Color(0xFFDC2626),
            strokeWidth: 2,
          )
          .geomPoint(
            id: 'efforts',
            name: 'Efforts',
            yAxisId: 'watts',
            size: const Channel<Sample>(sampleEffort, label: 'Effort'),
            categoryBy: const CategoryChannel<Sample>(
              sampleZone,
              label: 'Zone',
            ),
            categories: zoneStyles,
          )
          .interaction(
            const InteractionConfig(
              crosshair: CrosshairConfig(
                displayMode: CrosshairDisplayMode.tracking,
              ),
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 460,
                child: chart.build(bravenChartController: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final result = controller.extractDocument();
      expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
      final document = (result as ChartArtifactSuccess<ChartDocumentSnapshot>)
          .value
          .document;
      expect(document.series.map((series) => series.id), <String>[
        'power',
        'hr',
        'efforts',
      ]);
      expect(document.axes.map((axis) => axis.id), <String>['watts', 'bpm']);
      expect(document.annotations, hasLength(1));
    });
  });

  group('.facet sets PlotSpec.facet', () {
    test('facet with defaults lands on the spec', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone)
          .toSpec();

      expect(spec.facet, const FacetSpec<Sample>(by: sampleZone));
      expect(spec.facet!.scales, FacetScales.fixed);
    });

    test('facet carries columns, scales and label', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone, columns: 3, scales: FacetScales.freeY, label: 'Zone')
          .toSpec();

      expect(
        spec.facet,
        const FacetSpec<Sample>(
          by: sampleZone,
          columns: 3,
          scales: FacetScales.freeY,
          label: 'Zone',
        ),
      );
    });

    test('a chain without .facet leaves the spec unfaceted', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .toSpec();
      expect(spec.facet, isNull);
    });
  });

  group('faceted terminals', () {
    Matcher throwsCode(GrammarDiagnosticCode code) =>
        throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

    test('.build() on a faceted chain throws, directing to buildFaceted', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine()
            .facet(sampleZone)
            .build(),
        throwsCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('.buildFaceted() on a non-faceted chain throws', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine()
            .buildFaceted(),
        throwsCode(GrammarDiagnosticCode.notFaceted),
      );
    });

    test('.buildFaceted() returns a BravenFacetPlot over the faceted spec', () {
      final widget = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone, columns: 2, label: 'Zone')
          .buildFaceted();
      expect(widget, isA<BravenFacetPlot<Sample>>());
      expect(widget.spec.facet, isNotNull);
      expect(widget.spec.facet!.columns, 2);
    });

    test('.build() on a non-faceted chain still returns a BravenPlot', () {
      final widget = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .build();
      expect(widget, isA<BravenPlot<Sample>>());
    });
  });
}
