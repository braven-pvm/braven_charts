import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartDartSourceGenerator', () {
    test('generates deterministic direct Dart for a line chart', () {
      final snapshot = _snapshot(
        LineChartSeries(
          id: 'power',
          name: 'Power',
          unit: 'W',
          color: const Color(0xFFFF7A26),
          interpolation: LineInterpolation.monotone,
          dashPattern: const [2, 6],
          showDataPointMarkers: true,
          points: const [
            ChartDataPoint(
              x: 0,
              y: 148,
              label: 'Start',
              segmentStyle: SegmentStyle(dashPattern: [8, 4]),
            ),
            ChartDataPoint(x: 1, y: 162),
          ],
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
          ),
        ),
        title: "Rider's power",
      );

      final first = _success(ChartDartSourceGenerator.generate(snapshot));
      final second = _success(ChartDartSourceGenerator.generate(snapshot));

      expect(second.source, first.source);
      expect(first.seriesCount, 1);
      expect(first.pointCount, 2);
      expect(first.omittedPointCount, 0);
      expect(first.source, contains('final chart = BravenChartPlus('));
      expect(first.source, contains("title: 'Rider\\'s power',"));
      expect(first.source, contains('LineChartSeries('));
      expect(first.source, contains("id: 'power',"));
      expect(first.source, contains('Color(0xFFFF7A26)'));
      expect(
        first.source,
        contains('interpolation: LineInterpolation.monotone,'),
      );
      expect(first.source, contains('showDataPointMarkers: true,'));
      expect(first.source, contains('dashPattern: [2.0, 6.0],'));
      expect(first.source, contains('yAxisConfig: YAxisConfig('));
      expect(first.source, contains("label: 'Start',"));
      expect(first.source, contains('segmentStyle: SegmentStyle('));
      expect(first.source, contains('dashPattern: [8.0, 4.0],'));
      expect(first.source, contains('theme: ChartTheme.light,'));
    });

    test('generates the six built-in chart family constructors', () {
      final series = <ChartSeries>[
        const LineChartSeries(id: 'line', points: [ChartDataPoint(x: 0, y: 1)]),
        const AreaChartSeries(id: 'area', points: [ChartDataPoint(x: 0, y: 2)]),
        const ScatterChartSeries(
          id: 'scatter',
          points: [ChartDataPoint(x: 0, y: 3)],
        ),
        const BarChartSeries(
          id: 'bar',
          barWidthPercent: 0.7,
          points: [ChartDataPoint(x: 0, y: 4)],
        ),
        PieChartSeries.fromMap(id: 'pie', values: const {'Core': 5}),
        DonutChartSeries.fromMap(
          id: 'donut',
          values: const {'Ready': 6},
          centerContent: const DonutCenterContent(
            label: 'Status',
            valueMode: DonutCenterValueMode.custom,
            customValue: 'Ready',
          ),
        ),
      ];

      for (final item in series) {
        final generated = _success(
          ChartDartSourceGenerator.generate(_snapshot(item)),
        );
        final constructor = switch (item) {
          LineChartSeries() => 'LineChartSeries(',
          AreaChartSeries() => 'AreaChartSeries(',
          ScatterChartSeries() => 'ScatterChartSeries(',
          BarChartSeries() => 'BarChartSeries(',
          PieChartSeries() => 'PieChartSeries(',
          DonutChartSeries() => 'DonutChartSeries(',
          ChartSeries() => 'ChartSeries(',
        };
        expect(generated.source, contains(constructor));
      }
    });

    test('omits all data explicitly when the inline ceiling is exceeded', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'stream',
              points: [
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
                ChartDataPoint(x: 2, y: 3),
              ],
            ),
          ),
          options: const ChartDartSourceOptions(maxInlinePoints: 2),
        ),
      );

      expect(generated.isComplete, isFalse);
      expect(generated.omittedPointCount, 3);
      expect(generated.source, contains('3 points omitted'));
      expect(generated.source, contains('Supply this series data here'));
      expect(generated.source, isNot(contains('ChartDataPoint(')));
      expect(
        generated.warnings,
        contains(
          isA<ChartSourceWarning>().having(
            (warning) => warning.code,
            'code',
            ChartSourceWarningCodes.dataOmitted,
          ),
        ),
      );
    });

    test('supports import-free output and a custom declaration name', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'cohort',
              points: [ChartDataPoint(x: 1, y: 2)],
            ),
          ),
          options: const ChartDartSourceOptions(
            includeImports: false,
            variableName: 'cohortChart',
          ),
        ),
      );

      expect(generated.source, startsWith('final cohortChart'));
      expect(generated.source, isNot(contains('package:braven_charts')));
    });

    test('emits direct constructors for analytical annotations', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'power',
              points: [
                ChartDataPoint(x: 0, y: 100),
                ChartDataPoint(x: 1, y: 120),
                ChartDataPoint(x: 2, y: 140),
              ],
            ),
            annotations: [
              PointAnnotation(
                id: 'peak',
                seriesId: 'power',
                dataPointIndex: 2,
                markerShape: MarkerShape.star,
              ),
              RangeAnnotation(
                id: 'window',
                label: 'Target window',
                startX: 0.5,
                endX: 1.5,
                fillColor: const Color(0x3322AA66),
                style: const AnnotationStyle(
                  backgroundColor: Color(0xFFF3F4F6),
                ),
              ),
              TextAnnotation(
                id: 'note',
                text: 'Review',
                position: const Offset(24, 16),
              ),
              ThresholdAnnotation(
                id: 'target',
                axis: AnnotationAxis.y,
                value: 125,
                lineColor: const Color(0xFFFF5500),
                dashPattern: const [4, 2],
              ),
              PinAnnotation(id: 'pin', x: 1, y: 120),
              TrendAnnotation(
                id: 'trend',
                seriesId: 'power',
                trendType: TrendType.linear,
              ),
              ChordAnnotation(
                id: 'chord',
                seriesId: 'power',
                startIndex: 0,
                endIndex: 2,
                perpendicularIndex: 1,
              ),
            ],
          ),
        ),
      );

      for (final constructor in const [
        'PointAnnotation(',
        'RangeAnnotation(',
        'TextAnnotation(',
        'ThresholdAnnotation(',
        'PinAnnotation(',
        'TrendAnnotation(',
        'ChordAnnotation(',
      ]) {
        expect(generated.source, contains(constructor));
      }
      expect(generated.source, contains('MarkerShape.star'));
      expect(generated.source, contains("label: 'Target window'"));
      expect(generated.source, contains('dashPattern: [4.0, 2.0]'));
      expect(generated.source, contains('perpendicularIndex: 1'));
      expect(generated.source, contains('style: AnnotationStyle('));
      expect(generated.source, contains('backgroundColor: Color(0xFFF3F4F6)'));
    });

    test('emits complete canvas legend content and styling', () {
      final legendSeries = const LineChartSeries(
        id: 'legend-power',
        name: 'Legend power',
        points: [ChartDataPoint(x: 0, y: 100)],
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            legendSeries,
            annotations: [
              LegendAnnotation(
                id: 'canvas-legend',
                series: [legendSeries],
                trendAnnotations: [
                  TrendAnnotation(
                    id: 'legend-trend',
                    seriesId: 'legend-power',
                    label: 'Power trend',
                    trendType: TrendType.linear,
                  ),
                ],
                hiddenSeriesIds: const {'legend-power'},
                legendStyle: const LegendStyle(
                  position: LegendPosition.bottomLeft,
                  backgroundColor: Color(0xCC0F172A),
                  allowDragging: false,
                ),
                customPosition: const Offset(18, 24),
              ),
            ],
          ),
        ),
      );

      expect(generated.source, contains('LegendAnnotation('));
      expect(generated.source, contains("id: 'legend-power'"));
      expect(generated.source, contains('trendAnnotations: ['));
      expect(generated.source, contains("label: 'Power trend'"));
      expect(generated.source, contains('legendStyle: LegendStyle('));
      expect(generated.source, contains('position: LegendPosition.bottomLeft'));
      expect(generated.source, contains("hiddenSeriesIds: {'legend-power'}"));
      expect(generated.source, contains('customPosition: Offset(18.0, 24.0)'));
      expect(generated.warnings, isEmpty);
    });

    test('emits a resolved custom theme instead of dropping it', () {
      final theme = ChartTheme.dark.copyWith(
        backgroundColor: const Color(0xFF08111F),
        focusBorderColor: const Color(0xFF22D3EE),
        focusBorderWidth: 3,
        pieChartTheme: const PieChartTheme(
          cornerRadius: 6,
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'custom-theme',
              points: [ChartDataPoint(x: 0, y: 1)],
            ),
            theme: theme,
            themeReference: null,
          ),
        ),
      );

      for (final source in const [
        'theme: ChartTheme(',
        'backgroundColor: Color(0xFF08111F)',
        'gridStyle: GridStyle(',
        'axisStyle: AxisStyle(',
        'seriesTheme: SeriesTheme(',
        'interactionTheme: InteractionTheme(',
        'typographyTheme: TypographyTheme(',
        'animationTheme: AnimationTheme(',
        'annotationTheme: AnnotationTheme(',
        'scrollbarConfig: ScrollbarConfig(',
        'pieChartTheme: PieChartTheme(',
        'focusBorderColor: Color(0xFF22D3EE)',
      ]) {
        expect(generated.source, contains(source));
      }
      expect(generated.source, isNot(contains('resolved custom theme is not')));
      expect(generated.warnings, isEmpty);
    });

    test('emits controller-backed durable view-state restoration', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'power',
              points: [ChartDataPoint(x: 0, y: 1)],
            ),
            viewState: ChartViewState(
              visibleBounds: const ChartBoundsDocument(
                xMin: 1,
                xMax: 4,
                yMin: 10,
                yMax: 40,
              ),
              hiddenSeriesIds: const {'recovery'},
              selectedSeriesId: 'power',
              selectedPointRefs: const [
                ChartPointRef(seriesId: 'power', pointIndex: 0),
              ],
              visibleAxisIds: const ['power-axis'],
              overflowAxisIds: const ['recovery-axis'],
              selectedAnnotationId: 'target',
              legendPosition: const ChartPositionDocument(x: 22, y: 14),
            ),
          ),
          options: const ChartDartSourceOptions(includeViewState: true),
        ),
      );

      expect(
        generated.source,
        contains('final chartController = BravenChartController();'),
      );
      expect(
        generated.source,
        contains('bravenChartController: chartController'),
      );
      expect(generated.source, contains('void restoreChartViewState()'));
      expect(generated.source, contains('ChartBoundsDocument('));
      expect(generated.source, contains("hiddenSeriesIds: {'recovery'}"));
      expect(generated.source, contains('ChartPointRef('));
      expect(generated.source, contains("selectedAnnotationId: 'target'"));
      expect(generated.source, contains('ChartPositionDocument('));
      expect(generated.warnings, isEmpty);
    });

    test('emits advanced bar presentation and analytical values', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const BarChartSeries(
              id: 'targets',
              barWidthPercent: 0.7,
              points: [
                ChartDataPoint(x: 0, y: 42),
                ChartDataPoint(x: 1, y: 58),
              ],
              rangeStartValues: [20, null],
              barStyle: BarChartStyle(
                cornerRadius: 6,
                gradient: BarGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                ),
                border: BarBorderStyle(color: Color(0xFF0F172A), width: 2),
              ),
              trackStyle: BarTrackStyle(color: Color(0xFFE2E8F0), value: 80),
              targetValues: [50, 60],
              targetMarkerStyle: BarTargetMarkerStyle(color: Color(0xFFF97316)),
              errorLowerValues: [38, 54],
              errorUpperValues: [46, 63],
              errorBarStyle: BarErrorBarStyle(color: Color(0xFF334155)),
              labelStyle: BarLabelStyle(
                show: true,
                position: BarLabelPosition.outsideEnd,
              ),
            ),
          ),
        ),
      );

      for (final source in const [
        'rangeStartValues: [20.0, null]',
        'barStyle: BarChartStyle(',
        'gradient: BarGradient(',
        'trackStyle: BarTrackStyle(',
        'targetValues: [50.0, 60.0]',
        'errorLowerValues: [38.0, 54.0]',
        'errorBarStyle:',
        'labelStyle: BarLabelStyle(',
        'position: BarLabelPosition.outsideEnd',
      ]) {
        expect(generated.source, contains(source));
      }
      expect(generated.warnings, isNot(contains(isA<ChartSourceWarning>())));
    });

    test(
      'emits radial style, labels, radius, grouping, and center content',
      () {
        final generated = _success(
          ChartDartSourceGenerator.generate(
            _snapshot(
              DonutChartSeries.fromMap(
                id: 'readiness',
                values: const {'Ready': 72, 'Risk': 18, 'Other': 10},
                radiusValues: const {'Ready': 90, 'Risk': 54, 'Other': 38},
                donutStyle: const DonutChartStyle(
                  innerRadiusFactor: 0.62,
                  sweepAngleDegrees: 280,
                  gradient: PieGradientStyle(
                    type: PieGradientType.radial,
                    startLightnessShift: 0.2,
                  ),
                  shadow: PieElevationStyle(
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ),
                dataLabels: const PieDataLabelConfig(
                  position: PieDataLabelPosition.inside,
                  calloutStyle: LabelStyle(
                    textStyle: TextStyle(color: Colors.white, fontSize: 11),
                    backgroundColor: Color(0xCC0F172A),
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    borderRadius: 5,
                    padding: EdgeInsets.all(4),
                  ),
                ),
                sliceRadiusConfig: const PieSliceRadiusConfig(
                  minimumFactor: 0.5,
                  label: 'Confidence',
                ),
                sliceGroupingConfig: const RadialSliceGroupingConfig(
                  minimumShare: 0.12,
                  minimumSourceCount: 2,
                  label: 'Remaining',
                  radiusAggregation: RadialSliceRadiusAggregation.mean,
                ),
                centerContent: const DonutCenterContent(
                  label: 'Status',
                  valueMode: DonutCenterValueMode.custom,
                  customValue: '72% ready',
                ),
              ),
            ),
          ),
        );

        for (final source in const [
          'donutStyle: DonutChartStyle(',
          'gradient: PieGradientStyle(',
          'type: PieGradientType.radial',
          'shadow: PieElevationStyle(',
          'calloutStyle: LabelStyle(',
          'sliceRadiusConfig: PieSliceRadiusConfig(',
          'sliceGroupingConfig: RadialSliceGroupingConfig(',
          'radiusAggregation: RadialSliceRadiusAggregation.mean',
          "customValue: '72% ready'",
        ]) {
          expect(generated.source, contains(source));
        }
      },
    );

    test('returns a structured failure for an invalid variable name', () {
      final result = ChartDartSourceGenerator.generate(
        _snapshot(
          const LineChartSeries(
            id: 'line',
            points: [ChartDataPoint(x: 0, y: 1)],
          ),
        ),
        options: const ChartDartSourceOptions(variableName: 'chart-source'),
      );

      expect(result, isA<ChartArtifactFailure<ChartGeneratedSource>>());
      expect(
        (result as ChartArtifactFailure<ChartGeneratedSource>).error.path,
        r'$.sourceOptions.variableName',
      );
    });
  });
}

ChartGeneratedSource _success(
  ChartArtifactResult<ChartGeneratedSource> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

ChartDocumentSnapshot _snapshot(
  ChartSeries series, {
  String? title,
  List<ChartAnnotation> annotations = const [],
  ChartTheme? theme,
  String? themeReference = 'braven.light',
  ChartViewState? viewState,
}) {
  final encodedSeries = ChartSeriesDocumentCodec.encode(series);
  final encodedTheme = ChartThemeDocumentCodec.encode(
    theme ?? ChartTheme.light,
    reference: themeReference,
  );
  final encodedInteraction = ChartInteractionDocumentCodec.encode(
    const InteractionConfig(),
  );
  final encodedXAxis = ChartAxisDocumentCodec.encodeXAxis(
    const XAxisConfig(label: 'Elapsed interval'),
  );
  final encodedYAxis = ChartAxisDocumentCodec.encodeYAxis(
    YAxisConfig(position: YAxisPosition.left, label: 'Value'),
  );

  return ChartDocumentSnapshot(
    document: ChartDocument(
      documentId: 'source-test',
      revision: 1,
      title: title,
      series: [
        (encodedSeries as ChartArtifactSuccess<ChartSeriesDocument>).value,
      ],
      annotations: [
        for (final annotation in annotations)
          (ChartAnnotationDocumentCodec.encode(annotation)
                  as ChartArtifactSuccess<ChartAnnotationDocument>)
              .value,
      ],
      xAxis: (encodedXAxis as ChartArtifactSuccess<ChartAxisDocument>).value,
      axes: [(encodedYAxis as ChartArtifactSuccess<ChartAxisDocument>).value],
      theme: (encodedTheme as ChartArtifactSuccess<ChartThemeDocument>).value,
      interaction:
          (encodedInteraction as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
    viewState: viewState,
  );
}
