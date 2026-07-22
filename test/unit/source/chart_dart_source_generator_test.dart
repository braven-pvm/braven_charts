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
              pointKey: 'power-start',
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
      expect(first.source, contains("pointKey: 'power-start',"));
      expect(first.source, contains('segmentStyle: SegmentStyle('));
      expect(first.source, contains('dashPattern: [8.0, 4.0],'));
      expect(first.source, contains('theme: ChartTheme.light,'));
    });

    test('generates every built-in chart family constructor', () {
      final series = <ChartSeries>[
        CandlestickChartSeries(
          id: 'candlestick',
          points: [
            CandlestickDataPoint(x: 0, open: 2, high: 4, low: 1, close: 3),
          ],
        ),
        const LineChartSeries(id: 'line', points: [ChartDataPoint(x: 0, y: 1)]),
        const AreaChartSeries(id: 'area', points: [ChartDataPoint(x: 0, y: 2)]),
        RangeAreaChartSeries(
          id: 'range-area',
          points: [RangeAreaDataPoint(x: 0, low: 1, high: 3)],
        ),
        const ScatterChartSeries(
          id: 'scatter',
          points: [ChartDataPoint(x: 0, y: 3)],
          jitter: ScatterJitterConfig(xAmplitude: 10, yAmplitude: 6, seed: 23),
          dataPointLabels: DataPointLabelConfig(
            show: true,
            content: DataPointLabelContent.pointLabel,
            collisionPolicy: DataPointLabelCollisionPolicy.reposition,
            offsetX: 4,
          ),
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
        PolarColumnChartSeries.fromMap(id: 'polar', values: const {'North': 7}),
      ];

      for (final item in series) {
        final generated = _success(
          ChartDartSourceGenerator.generate(
            _snapshot(
              item,
              polarChartConfig: item is PolarColumnChartSeries
                  ? const PolarChartConfig()
                  : null,
            ),
          ),
        );
        final constructor = switch (item) {
          CandlestickChartSeries() => 'CandlestickChartSeries(',
          LineChartSeries() => 'LineChartSeries(',
          AreaChartSeries() => 'AreaChartSeries(',
          RangeAreaChartSeries() => 'RangeAreaChartSeries(',
          ScatterChartSeries() => 'ScatterChartSeries(',
          BarChartSeries() => 'BarChartSeries(',
          PieChartSeries() => 'PieChartSeries(',
          DonutChartSeries() => 'DonutChartSeries(',
          PolarColumnChartSeries() => 'PolarColumnChartSeries(',
          ChartSeries() => 'ChartSeries(',
        };
        expect(generated.source, contains(constructor));
        if (item is ScatterChartSeries) {
          expect(generated.source, contains('jitter: ScatterJitterConfig('));
          expect(generated.source, contains('xAmplitude: 10.0,'));
          expect(generated.source, contains('yAmplitude: 6.0,'));
          expect(generated.source, contains('seed: 23,'));
          expect(
            generated.source,
            contains('content: DataPointLabelContent.pointLabel,'),
          );
          expect(
            generated.source,
            contains(
              'collisionPolicy: DataPointLabelCollisionPolicy.reposition,',
            ),
          );
          expect(generated.source, contains('offsetX: 4.0,'));
        }
      }
    });

    test('emits the settable style discriminator for a base ChartSeries', () {
      // A directly-instantiated base ChartSeries exposes a settable `style`
      // param that round-trips through the codec's `'base'` case, but the
      // _emitSeriesStyle allowlist omitted the base type (Fix B). RED before,
      // GREEN after.
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ChartSeries(
              id: 's',
              points: [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)],
              style: SeriesStyle.line,
            ),
          ),
        ),
      );
      expect(generated.source, contains('ChartSeries('));
      expect(generated.source, contains('style: SeriesStyle.line,'));
    });

    test('generates deterministic Candlestick OHLC, style, and motion', () {
      final snapshot = _snapshot(
        CandlestickChartSeries(
          id: 'price',
          unit: 'USD',
          points: [
            CandlestickDataPoint(
              x: 1,
              pointKey: 'price-session-1',
              open: 100,
              high: 112,
              low: 98,
              close: 110,
              candlestickStyle: const CandlestickPointStyle(
                wickColor: Color(0xFF334455),
              ),
            ),
          ],
          candlestickStyle: const CandlestickChartStyle(
            bodyFillMode: CandlestickBodyFillMode.filled,
            bodyWidthFactor: .6,
          ),
          animation: const CandlestickAnimationStyle(staggerFraction: .35),
          densityGrouping: const CandlestickDensityGrouping(
            enabled: true,
            targetGroupWidth: 6,
            minimumPointsPerGroup: 3,
          ),
        ),
      );

      final first = _success(ChartDartSourceGenerator.generate(snapshot));
      final second = _success(ChartDartSourceGenerator.generate(snapshot));

      expect(second.source, first.source);
      expect(first.source, contains('CandlestickChartSeries('));
      expect(first.source, contains('CandlestickDataPoint('));
      expect(first.source, contains("pointKey: 'price-session-1',"));
      expect(first.source, contains('open: 100.0,'));
      expect(first.source, contains('high: 112.0,'));
      expect(first.source, contains('low: 98.0,'));
      expect(first.source, contains('close: 110.0,'));
      expect(first.source, isNot(contains('isXOrdered:')));
      expect(
        first.source,
        contains('bodyFillMode: CandlestickBodyFillMode.filled,'),
      );
      expect(first.source, contains('staggerFraction: 0.35,'));
      expect(
        first.source,
        contains('densityGrouping: CandlestickDensityGrouping('),
      );
      expect(first.source, contains('targetGroupWidth: 6.0,'));
      expect(first.source, contains('minimumPointsPerGroup: 3,'));
      expect(first.source, contains('wickColor: Color(0xFF334455),'));
    });

    test('generates deterministic Range Area intervals, gaps, and styling', () {
      final snapshot = _snapshot(
        RangeAreaChartSeries(
          id: 'confidence',
          unit: '%',
          points: [
            RangeAreaDataPoint(
              x: 1,
              pointKey: 'confidence-1',
              low: 42,
              high: 58,
            ),
            RangeAreaDataPoint.gap(
              x: 2,
              pointKey: 'confidence-2',
              label: 'Missing',
            ),
          ],
          color: const Color(0xFF2563EB),
          interpolation: LineInterpolation.monotone,
          fillOpacity: .4,
          fillGradient: const AreaGradient(
            colors: [Color(0x332563EB), Color(0x992563EB)],
          ),
          borderMode: RangeAreaBorderMode.closed,
          upperBoundaryStyle: const RangeAreaBoundaryStyle(
            strokeWidth: 2,
            dashPattern: [4, 2],
          ),
          showBoundaryMarkers: true,
          labelConfig: const RangeAreaLabelConfig(
            value: RangeAreaLabelValue.both,
            labels: DataPointLabelConfig(show: true),
          ),
          pathAnimation: const PathAnimationStyle(
            entranceMode: PathEntranceAnimationMode.reveal,
            dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
          ),
        ),
      );

      final first = _success(ChartDartSourceGenerator.generate(snapshot));
      final second = _success(ChartDartSourceGenerator.generate(snapshot));

      expect(second.source, first.source);
      expect(first.source, contains('RangeAreaChartSeries('));
      expect(first.source, contains('RangeAreaDataPoint('));
      expect(first.source, contains("pointKey: 'confidence-1',"));
      expect(first.source, contains('low: 42.0,'));
      expect(first.source, contains('high: 58.0,'));
      expect(first.source, contains('RangeAreaDataPoint.gap('));
      expect(first.source, contains("pointKey: 'confidence-2',"));
      expect(first.source, contains("label: 'Missing',"));
      expect(first.source, contains('fillGradient: AreaGradient('));
      expect(first.source, contains('borderMode: RangeAreaBorderMode.closed,'));
      expect(first.source, contains('dashPattern: [4.0, 2.0],'));
      expect(first.source, contains('showBoundaryMarkers: true,'));
      expect(first.source, contains('labelConfig: RangeAreaLabelConfig('));
      expect(first.source, contains('value: RangeAreaLabelValue.both,'));
      expect(first.source, contains('pathAnimation: PathAnimationStyle('));
      expect(
        first.source,
        contains('entranceMode: PathEntranceAnimationMode.reveal,'),
      );
      expect(first.source, isNot(contains('isXOrdered:')));
      expect(first.completeness, ChartGeneratedSourceCompleteness.complete);
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

    test('emits non-default Scatter marker geometry', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'shaped-cohort',
              points: [
                ChartDataPoint(
                  x: 1,
                  y: 2,
                  pointStyle: PointStyle(
                    scatterMarkerShape: SeriesMarkerShape.invertedTriangle,
                    scatterMarkerStyle: ScatterMarkerStyle(width: 24),
                  ),
                ),
              ],
              markerRadius: 9,
              markerShape: SeriesMarkerShape.star,
              markerStyle: ScatterMarkerStyle(
                fillColor: Color(0xFF2563EB),
                strokeColor: Color(0xFF0F172A),
                strokeWidth: 2,
                opacity: 0.75,
                width: 18,
                height: 10,
                rotationDegrees: 30,
              ),
              interactionStyle: ScatterInteractionStyle(
                hoverColor: Color(0xFF22C55E),
                hoverScale: 1.5,
                selectionColor: Color(0xFF7C3AED),
                selectionScale: 1.4,
                focusGap: 6,
                dimmedOpacity: 0.2,
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('markerRadius: 9.0,'));
      expect(
        generated.source,
        contains('markerShape: SeriesMarkerShape.star,'),
      );
      for (final source in const [
        'markerStyle: ScatterMarkerStyle(',
        'fillColor: Color(0xFF2563EB),',
        'strokeColor: Color(0xFF0F172A),',
        'strokeWidth: 2.0,',
        'opacity: 0.75,',
        'width: 18.0,',
        'height: 10.0,',
        'rotationDegrees: 30.0,',
        'scatterMarkerStyle: ScatterMarkerStyle(',
        'scatterMarkerShape: SeriesMarkerShape.invertedTriangle,',
        'width: 24.0,',
        'interactionStyle: ScatterInteractionStyle(',
        'hoverColor: Color(0xFF22C55E),',
        'hoverScale: 1.5,',
        'selectionColor: Color(0xFF7C3AED),',
        'selectionScale: 1.4,',
        'focusGap: 6.0,',
        'dimmedOpacity: 0.2,',
      ]) {
        expect(generated.source, contains(source));
      }
    });

    test('emits Scatter magnitude and size encoding', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'bubble',
              points: [ChartDataPoint(x: 1, y: 2, magnitude: 80)],
              sizeEncoding: ScatterSizeEncoding(
                minimumRadius: 3,
                maximumRadius: 20,
                maximumValue: 100,
                label: 'Accounts',
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('magnitude: 80.0,'));
      expect(generated.source, contains('sizeEncoding: ScatterSizeEncoding('));
      expect(generated.source, contains('minimumRadius: 3.0,'));
      expect(generated.source, contains('maximumRadius: 20.0,'));
      expect(generated.source, contains("label: 'Accounts',"));
    });

    test('emits independent Scatter color values and encoding', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'readiness',
              points: [ChartDataPoint(x: 1, y: 2, colorValue: 84)],
              colorEncoding: ScatterColorEncoding(
                colors: [Color(0xFFDC2626), Color(0xFF16A34A)],
                minimumValue: 40,
                maximumValue: 100,
                label: 'Readiness',
                unit: '%',
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('colorValue: 84.0,'));
      expect(
        generated.source,
        contains('colorEncoding: ScatterColorEncoding('),
      );
      expect(generated.source, contains('Color(0xFFDC2626),'));
      expect(generated.source, contains('Color(0xFF16A34A),'));
      expect(generated.source, contains("label: 'Readiness',"));
    });

    test('emits piecewise Scatter color scale configuration', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'risk',
              points: [ChartDataPoint(x: 1, y: 2, colorValue: 80)],
              colorEncoding: ScatterColorEncoding(
                colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
                scaleType: ScatterColorScaleType.piecewise,
                thresholds: [60],
                bandLabels: ['Normal', 'Critical'],
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('scaleType: ScatterColorScaleType.piecewise'),
      );
      expect(generated.source, contains('thresholds: [60.0]'));
      expect(generated.source, contains("bandLabels: ['Normal', 'Critical']"));
    });

    test('emits independent Scatter opacity values and encoding', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'confidence',
              points: [ChartDataPoint(x: 1, y: 2, opacityValue: 84)],
              opacityEncoding: ScatterOpacityEncoding(
                minimumOpacity: 0.15,
                maximumOpacity: 0.95,
                minimumValue: 40,
                maximumValue: 100,
                label: 'Confidence',
                unit: '%',
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('opacityValue: 84.0,'));
      expect(
        generated.source,
        contains('opacityEncoding: ScatterOpacityEncoding('),
      );
      expect(generated.source, contains('minimumOpacity: 0.15,'));
      expect(generated.source, contains('maximumOpacity: 0.95,'));
      expect(generated.source, contains("label: 'Confidence',"));
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
                trendType: TrendType.loess,
                loessSpan: 0.4,
                loessRobustnessIterations: 3,
                loessSampleCount: 160,
                showEquation: true,
                showRSquared: true,
                showSampleCount: true,
                showPearsonCorrelation: true,
                showSpearmanCorrelation: true,
                showConfidenceBand: true,
                showPredictionBand: true,
                confidenceLevel: 0.99,
                confidenceBandOpacity: 0.24,
                predictionBandOpacity: 0.12,
              ),
              ErrorBarAnnotation(
                id: 'errors',
                seriesId: 'power',
                values: const [
                  ErrorBarDatum.symmetric(pointIndex: 0, y: 4),
                  ErrorBarDatum(
                    pointIndex: 1,
                    xNegative: 0.1,
                    xPositive: 0.2,
                    yNegative: 3,
                    yPositive: 5,
                  ),
                ],
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
        'ErrorBarAnnotation(',
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
      expect(generated.source, contains('TrendType.loess'));
      expect(generated.source, contains('loessSpan: 0.4'));
      expect(generated.source, contains('loessRobustnessIterations: 3'));
      expect(generated.source, contains('loessSampleCount: 160'));
      expect(generated.source, contains('showEquation: true'));
      expect(generated.source, contains('showRSquared: true'));
      expect(generated.source, contains('showSampleCount: true'));
      expect(generated.source, contains('showPearsonCorrelation: true'));
      expect(generated.source, contains('showSpearmanCorrelation: true'));
      expect(generated.source, contains('showConfidenceBand: true'));
      expect(generated.source, contains('showPredictionBand: true'));
      expect(generated.source, contains('confidenceLevel: 0.99'));
      expect(generated.source, contains('confidenceBandOpacity: 0.24'));
      expect(generated.source, contains('predictionBandOpacity: 0.12'));
      expect(generated.source, contains('ErrorBarDatum('));
      expect(generated.source, contains('xNegative: 0.1'));
      expect(generated.source, contains('yPositive: 5.0'));
    });

    test('emits the full TextStyle field set for annotation label styles', () {
      // Every field here is round-tripped by ChartStyleDocumentCodec but the
      // emitter previously dropped the richer ones (shadows, fontFamilyFallback,
      // textBaseline, leadingDistribution, locale, fontFeatures, fontVariations,
      // debugLabel, overflow, inherit, and combined decorations). RED before
      // Fix A, GREEN after.
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'power',
              points: [ChartDataPoint(x: 0, y: 100), ChartDataPoint(x: 1, y: 120)],
            ),
            annotations: [
              RangeAnnotation(
                id: 'window',
                label: 'Target window',
                startX: 0.5,
                endX: 1.5,
                style: AnnotationStyle(
                  textStyle: TextStyle(
                    inherit: false,
                    color: Color(0xFF102030),
                    fontFamily: 'Inter',
                    fontFamilyFallback: ['Roboto', 'Arial'],
                    letterSpacing: 1.5,
                    wordSpacing: 1.2,
                    textBaseline: TextBaseline.alphabetic,
                    leadingDistribution: TextLeadingDistribution.even,
                    locale: Locale.fromSubtags(
                      languageCode: 'en',
                      countryCode: 'ZA',
                    ),
                    shadows: [
                      Shadow(
                        color: Color(0x55000000),
                        offset: Offset(1, 2),
                        blurRadius: 3,
                      ),
                    ],
                    fontFeatures: [FontFeature('smcp')],
                    fontVariations: [FontVariation('wght', 650)],
                    decoration: TextDecoration.combine([
                      TextDecoration.underline,
                      TextDecoration.overline,
                    ]),
                    decorationStyle: TextDecorationStyle.dashed,
                    debugLabel: 'label-test',
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Previously-dropped fields now emitted.
      expect(generated.source, contains('inherit: false,'));
      expect(
        generated.source,
        contains("fontFamilyFallback: ['Roboto', 'Arial'],"),
      );
      expect(
        generated.source,
        contains('textBaseline: TextBaseline.alphabetic,'),
      );
      expect(
        generated.source,
        contains('leadingDistribution: TextLeadingDistribution.even,'),
      );
      expect(
        generated.source,
        contains(
          "locale: Locale.fromSubtags(languageCode: 'en', countryCode: 'ZA'),",
        ),
      );
      expect(
        generated.source,
        contains(
          'shadows: [Shadow(color: Color(0x55000000), offset: Offset(1.0, 2.0), '
          'blurRadius: 3.0)],',
        ),
      );
      expect(
        generated.source,
        contains("fontFeatures: [FontFeature('smcp', 1)],"),
      );
      expect(
        generated.source,
        contains("fontVariations: [FontVariation('wght', 650.0)],"),
      );
      expect(
        generated.source,
        contains(
          'decoration: TextDecoration.combine([TextDecoration.underline, '
          'TextDecoration.overline]),',
        ),
      );
      expect(generated.source, contains("debugLabel: 'label-test',"));
      expect(generated.source, contains('overflow: TextOverflow.fade,'));
      // A field already emitted before Fix A stays intact.
      expect(generated.source, contains('letterSpacing: 1.5,'));
      // No warning is produced for the combined decoration any more.
      expect(generated.warnings, isEmpty);
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
                errorBarAnnotations: [
                  ErrorBarAnnotation(
                    id: 'legend-error',
                    label: 'X/Y measurement error',
                    seriesId: 'legend-power',
                    values: const [
                      ErrorBarDatum.symmetric(pointIndex: 0, x: 1, y: 2),
                    ],
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
      expect(generated.source, contains('errorBarAnnotations: ['));
      expect(generated.source, contains("label: 'Power trend'"));
      expect(generated.source, contains("label: 'X/Y measurement error'"));
      expect(generated.source, contains('legendStyle: LegendStyle('));
      expect(generated.source, contains('position: LegendPosition.bottomLeft'));
      expect(generated.source, contains("hiddenSeriesIds: {'legend-power'}"));
      expect(generated.source, contains('customPosition: Offset(18.0, 24.0)'));
      expect(generated.warnings, isEmpty);
    });

    test('emits a native quantitative size legend', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'bubble',
              points: [ChartDataPoint(x: 1, y: 2, magnitude: 95)],
            ),
            annotations: [
              LegendAnnotation(
                id: 'bubble-size-key',
                sizeScale: const LegendSizeScale(
                  label: 'Active accounts',
                  color: Color(0xFF0F9F8F),
                  samples: [
                    LegendSizeSample(radius: 4, label: '95'),
                    LegendSizeSample(radius: 24, label: '600'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(generated.source, contains('sizeScale: LegendSizeScale('));
      expect(generated.source, contains("label: 'Active accounts'"));
      expect(generated.source, contains('LegendSizeSample('));
      expect(generated.source, contains("label: '600'"));
      expect(generated.warnings, isEmpty);
    });

    test('emits a native quantitative color legend', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'readiness',
              points: [ChartDataPoint(x: 1, y: 2, colorValue: 84)],
            ),
            annotations: [
              LegendAnnotation(
                id: 'readiness-key',
                colorScale: const LegendColorScale(
                  label: 'Recovery readiness',
                  colors: [Color(0xFFDC2626), Color(0xFF16A34A)],
                  minimumLabel: '45 %',
                  midpointLabel: '70 %',
                  maximumLabel: '95 %',
                ),
              ),
            ],
          ),
        ),
      );

      expect(generated.source, contains('colorScale: LegendColorScale('));
      expect(generated.source, contains("label: 'Recovery readiness'"));
      expect(generated.source, contains("minimumLabel: '45 %'"));
      expect(generated.source, contains("maximumLabel: '95 %'"));
      expect(generated.warnings, isEmpty);
    });

    test('emits explicit Scatter cluster rendering', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'clusters',
              points: [
                ChartDataPoint(x: 1, y: 2),
                ChartDataPoint(x: 1.1, y: 2.1),
              ],
              renderMode: ScatterRenderMode.clusters,
              clusterConfig: ScatterClusterConfig(
                cellSize: 52,
                minimumPointCount: 3,
                minimumRadius: 9,
                maximumRadius: 30,
                showCountLabels: false,
                labelMinimumPointCount: 5,
                showZones: true,
                zoneOpacity: 0.14,
                drillOnTap: false,
                drillPadding: 0.24,
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('renderMode: ScatterRenderMode.clusters'),
      );
      expect(
        generated.source,
        contains('clusterConfig: ScatterClusterConfig('),
      );
      expect(generated.source, contains('cellSize: 52.0'));
      expect(generated.source, contains('minimumPointCount: 3'));
      expect(generated.source, contains('showCountLabels: false'));
      expect(generated.source, contains('showZones: true'));
      expect(generated.source, contains('zoneOpacity: 0.14'));
      expect(generated.source, contains('drillOnTap: false'));
      expect(generated.source, contains('drillPadding: 0.24'));
      expect(generated.warnings, isEmpty);
    });

    test('emits explicit Scatter hexagonal bin rendering', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'hexbin',
              points: [
                ChartDataPoint(x: 1, y: 2),
                ChartDataPoint(x: 1.1, y: 2.1),
              ],
              renderMode: ScatterRenderMode.hexbin,
              binConfig: ScatterBinConfig(
                cellSize: 48,
                gap: 2,
                minimumPointCount: 3,
                minimumOpacity: 0.15,
                maximumOpacity: 0.9,
                aggregate: ScatterBinAggregate.sum,
                valueSource: ScatterBinValueSource.x,
                showLabels: true,
                labelMinimumPointCount: 8,
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('renderMode: ScatterRenderMode.hexbin'),
      );
      expect(generated.source, contains('binConfig: ScatterBinConfig('));
      expect(generated.source, contains('cellSize: 48.0'));
      expect(generated.source, contains('minimumPointCount: 3'));
      expect(generated.source, contains('aggregate: ScatterBinAggregate.sum'));
      expect(
        generated.source,
        contains('valueSource: ScatterBinValueSource.x'),
      );
      expect(generated.source, contains('showLabels: true'));
      expect(generated.warnings, isEmpty);
    });

    test('emits explicit Scatter density contour rendering', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'density',
              points: [
                ChartDataPoint(x: 1, y: 2),
                ChartDataPoint(x: 1.1, y: 2.1),
              ],
              renderMode: ScatterRenderMode.density,
              densityConfig: ScatterDensityConfig(
                gridCellSize: 6,
                bandwidth: 28,
                contourCount: 7,
                minimumDensity: 0.12,
                minimumOpacity: 0.22,
                maximumOpacity: 0.84,
                lineWidth: 2.5,
                showPoints: true,
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('renderMode: ScatterRenderMode.density'),
      );
      expect(
        generated.source,
        contains('densityConfig: ScatterDensityConfig('),
      );
      expect(generated.source, contains('gridCellSize: 6.0'));
      expect(generated.source, contains('bandwidth: 28.0'));
      expect(generated.source, contains('contourCount: 7'));
      expect(generated.source, contains('showPoints: true'));
      expect(generated.warnings, isEmpty);
    });

    test('emits a native segmented color legend', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'risk',
              points: [ChartDataPoint(x: 1, y: 2, colorValue: 80)],
            ),
            annotations: [
              LegendAnnotation(
                id: 'risk-key',
                colorScale: const LegendColorScale(
                  label: 'Risk score',
                  colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
                  minimumLabel: '0',
                  maximumLabel: '100',
                  type: LegendColorScaleType.piecewise,
                  segmentLabels: ['Normal', 'Critical'],
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        generated.source,
        contains('type: LegendColorScaleType.piecewise'),
      );
      expect(
        generated.source,
        contains("segmentLabels: ['Normal', 'Critical']"),
      );
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
              selectedSeriesIds: const {'power', 'heart-rate'},
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
      expect(
        generated.source,
        contains("selectedSeriesIds: {'heart-rate', 'power'}"),
      );
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
                selectionStyle: const RadialSelectionStyle(
                  effect: RadialSelectionEffect.lift,
                  liftScale: 1.1,
                  liftOffset: 7,
                  backdropBlur: 1.4,
                ),
                dataLabels: const PieDataLabelConfig(
                  position: PieDataLabelPosition.inside,
                  insideOffset: -12,
                  secondaryContent: PieDataLabelContent.category,
                  secondaryPosition: PieDataLabelPosition.outside,
                  calloutStyle: LabelStyle(
                    textStyle: TextStyle(color: Colors.white, fontSize: 11),
                    backgroundColor: Color(0xCC0F172A),
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    borderRadius: 5,
                    padding: EdgeInsets.all(4),
                  ),
                  secondaryCalloutStyle: LabelStyle(
                    textStyle: TextStyle(color: Colors.black, fontSize: 10),
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    borderRadius: 0,
                    padding: EdgeInsets.zero,
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
          'selectionStyle: RadialSelectionStyle(',
          'effect: RadialSelectionEffect.lift',
          'liftOffset: 7.0',
          'insideOffset: -12.0',
          'calloutStyle: LabelStyle(',
          'secondaryContent: PieDataLabelContent.category',
          'secondaryPosition: PieDataLabelPosition.outside',
          'secondaryCalloutStyle: LabelStyle(',
          'sliceRadiusConfig: PieSliceRadiusConfig(',
          'sliceGroupingConfig: RadialSliceGroupingConfig(',
          'radiusAggregation: RadialSliceRadiusAggregation.mean',
          "customValue: '72% ready'",
        ]) {
          expect(generated.source, contains(source));
        }
      },
    );

    test('emits lifted radial selection presentation', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            PieChartSeries.fromMap(
              id: 'lifted-pie',
              values: const {'Core': 60, 'Edge': 40},
              selectionStyle: const RadialSelectionStyle(
                effect: RadialSelectionEffect.lift,
                liftScale: 1.12,
                liftOffset: 8,
                backdropBlur: 1.5,
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('selectionStyle: RadialSelectionStyle('),
      );
      expect(generated.source, contains('effect: RadialSelectionEffect.lift'));
      expect(generated.source, contains('liftScale: 1.12'));
      expect(generated.source, contains('liftOffset: 8'));
      expect(generated.source, contains('backdropBlur: 1.5'));
    });

    test('emits the complete Concentric Donut composition', () {
      const config = ConcentricDonutConfig(
        innerRadiusFactor: 0.24,
        outerRadiusFactor: 0.92,
        ringGap: 7,
        order: ConcentricRingOrder.innerToOuter,
        ringWeights: {'previous': 0.8, 'current': 1.4},
        legendMode: ConcentricDonutLegendMode.flat,
        centerContent: DonutCenterContent(
          label: 'Periods',
          valueMode: DonutCenterValueMode.custom,
          customValue: '2 compared',
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            DonutChartSeries.fromMap(
              id: 'current',
              values: const {'Subscriptions': 60, 'Services': 40},
            ),
            additionalSeries: [
              DonutChartSeries.fromMap(
                id: 'previous',
                values: const {'Subscriptions': 50, 'Services': 50},
              ),
            ],
            concentricDonutConfig: config,
          ),
        ),
      );

      expect(generated.seriesCount, 2);
      expect(
        generated.source,
        contains('concentricDonutConfig: ConcentricDonutConfig('),
      );
      expect(generated.source, contains('innerRadiusFactor: 0.24'));
      expect(generated.source, contains('outerRadiusFactor: 0.92'));
      expect(generated.source, contains('ringGap: 7.0'));
      expect(
        generated.source,
        contains('order: ConcentricRingOrder.innerToOuter'),
      );
      expect(generated.source, contains("'current': 1.4"));
      expect(generated.source, contains("'previous': 0.8"));
      expect(
        generated.source,
        contains('legendMode: ConcentricDonutLegendMode.flat'),
      );
      expect(generated.source, contains("label: 'Periods'"));
      expect(generated.source, contains("customValue: '2 compared'"));
    });

    test('emits Polar Column series style and complete pane axes', () {
      const config = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: 20,
          sweepAngleDegrees: 240,
          clockwise: false,
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.9,
          clipMarks: false,
        ),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.18,
          outerPadding: 0.08,
          showLabels: false,
          showGridLines: false,
          maximumVisibleLabels: 9,
          maximumVisibleGridLines: 18,
          labelOffset: 14,
          labelStyle: PolarLabelStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: 10,
          maximum: 90,
          scaleMode: PolarRadialScaleMode.areaCorrect,
          tickCount: 7,
          showLabels: false,
          showGridLines: true,
          labelPosition: PolarRadialLabelPosition.middle,
          labelAngleOffsetDegrees: 15,
          labelOffset: 8,
          labelStyle: PolarLabelStyle(color: Color(0xFF0D9488), fontSize: 11),
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            PolarColumnChartSeries.rose(
              id: 'demand',
              unit: 'orders',
              values: const {'North': 42, 'South': 68},
              polarStyle: const PolarColumnStyle(
                cornerRadius: 10,
                cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds,
                opacity: 0.75,
                borderColor: Color(0xFF102030),
                borderWidth: 2,
                showDataLabels: false,
                maximumVisibleDataLabels: 6,
                dataLabelRadialPosition: 0.7,
                dataLabelStyle: PolarLabelStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                gradient: PolarColumnGradientStyle(
                  startColor: Color(0xFF22D3EE),
                  endColor: Color(0xFF4338CA),
                ),
                shadow: PolarColumnShadowStyle(
                  blurRadius: 9,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                  opacity: 0.3,
                ),
                animationMode: PolarColumnAnimationMode.sweep,
              ),
              selectionStyle: const RadialSelectionStyle(
                effect: RadialSelectionEffect.lift,
                liftScale: 1.1,
                liftOffset: 9,
                backdropBlur: 2,
              ),
            ),
            polarChartConfig: config,
          ),
        ),
      );

      expect(generated.source, contains('PolarColumnChartSeries('));
      expect(generated.source, contains('preset: PolarColumnPreset.rose'));
      expect(generated.source, contains('polarStyle: PolarColumnStyle('));
      expect(generated.source, contains('cornerRadius: 10.0'));
      expect(
        generated.source,
        contains('cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds'),
      );
      expect(generated.source, contains('Color(0xFF102030)'));
      expect(generated.source, contains('maximumVisibleDataLabels: 6'));
      expect(generated.source, contains('dataLabelRadialPosition: 0.7'));
      expect(generated.source, contains('PolarColumnGradientStyle('));
      expect(generated.source, contains('PolarColumnShadowStyle('));
      expect(
        generated.source,
        contains('animationMode: PolarColumnAnimationMode.sweep'),
      );
      expect(generated.source, contains('polarChartConfig: PolarChartConfig('));
      expect(generated.source, contains('startAngleDegrees: 20.0'));
      expect(generated.source, contains('sweepAngleDegrees: 240.0'));
      expect(generated.source, contains('clockwise: false'));
      expect(
        generated.source,
        contains('scaleMode: PolarRadialScaleMode.areaCorrect'),
      );
      expect(generated.source, contains('tickCount: 7'));
      expect(generated.source, contains('maximumVisibleLabels: 9'));
      expect(generated.source, contains('maximumVisibleGridLines: 18'));
      expect(generated.source, contains('labelOffset: 14.0'));
      expect(
        generated.source,
        contains('labelPosition: PolarRadialLabelPosition.middle'),
      );
      expect(generated.source, contains('labelAngleOffsetDegrees: 15.0'));
      expect(generated.source, contains('fontWeight: FontWeight.w700'));
    });

    test('emits portable chart selection policy', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const ScatterChartSeries(
              id: 'selectable',
              points: [ChartDataPoint(x: 1, y: 2)],
            ),
            interaction: const InteractionConfig(
              selection: ChartSelectionConfig(
                acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
                scope: ChartSelectionScope.markOrWholeSeries,
                operation: ChartSelectionOperation.add,
                dragActivation: ChartSelectionDragActivation.shiftPrimaryButton,
                clearOnBackgroundTap: false,
                useModifierKeys: false,
                dataPointHitRadius: 14,
                completeSeriesHitRadius: 30,
                dataPointHoverScale: 1.8,
                dataPointSelectionScale: 3.2,
                completeSeriesHoverStrokeScale: 2.1,
                completeSeriesSelectionStrokeScale: 1.9,
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('selection: ChartSelectionConfig('));
      expect(
        generated.source,
        contains('acquisitionMode: ChartSelectionAcquisitionMode.xInterval'),
      );
      expect(
        generated.source,
        contains('scope: ChartSelectionScope.markOrWholeSeries'),
      );
      expect(
        generated.source,
        contains('operation: ChartSelectionOperation.add'),
      );
      expect(
        generated.source,
        contains(
          'dragActivation: ChartSelectionDragActivation.shiftPrimaryButton',
        ),
      );
      expect(generated.source, contains('clearOnBackgroundTap: false'));
      expect(generated.source, contains('useModifierKeys: false'));
      expect(generated.source, contains('dataPointHitRadius: 14.0'));
      expect(generated.source, contains('completeSeriesHitRadius: 30.0'));
      expect(generated.source, contains('dataPointHoverScale: 1.8'));
      expect(generated.source, contains('dataPointSelectionScale: 3.2'));
      expect(generated.source, contains('completeSeriesHoverStrokeScale: 2.1'));
      expect(
        generated.source,
        contains('completeSeriesSelectionStrokeScale: 1.9'),
      );
    });

    test('emits grouped Polar Column composition settings', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            PolarColumnChartSeries.fromMap(
              id: 'north',
              unit: 'orders',
              values: const {'Search': 42, 'Social': 28},
            ),
            additionalSeries: [
              PolarColumnChartSeries.fromMap(
                id: 'south',
                unit: 'orders',
                values: const {'Search': 36, 'Social': 31},
              ),
            ],
            polarChartConfig: const PolarChartConfig(
              composition: PolarColumnCompositionConfig(
                mode: PolarColumnCompositionMode.grouped,
                groupInnerPadding: 0.2,
              ),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('composition: PolarColumnCompositionConfig('),
      );
      expect(
        generated.source,
        contains('mode: PolarColumnCompositionMode.grouped'),
      );
      expect(generated.source, contains('groupInnerPadding: 0.2'));
    });

    test('reports runtime callbacks once as a source limitation', () {
      final snapshot = _snapshot(
        const ScatterChartSeries(
          id: 'viewport-linked',
          points: [ChartDataPoint(x: 1, y: 2)],
        ),
        interaction: InteractionConfig(onViewportChanged: (_) {}),
        interactionBindingDescriptors: {
          ChartInteractionDocumentCodec.viewportChangedBinding: JsonObjectValue(
            const {'id': JsonStringValue('showcase.viewportChanged')},
          ),
        },
      );

      final result = ChartDartSourceGenerator.generate(snapshot);
      expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      final success = result as ChartArtifactSuccess<ChartGeneratedSource>;
      expect(
        success.warnings.where(
          (warning) =>
              warning.code ==
                  ChartArtifactDiagnosticCodes.runtimeBindingRequired &&
              warning.path?.contains('onViewportChanged') == true,
        ),
        isEmpty,
      );
      expect(
        success.value.warnings,
        contains(
          isA<ChartSourceWarning>().having(
            (warning) => warning.code,
            'code',
            ChartSourceWarningCodes.runtimeValueOmitted,
          ),
        ),
      );
      expect(
        success.value.source,
        contains('Runtime interaction bindings omitted:'),
      );
    });

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

    test('uses registered formatters while hydrating generated source', () {
      final descriptor = ChartFormatterDescriptor(
        id: 'showcase.session',
        fallbackPattern: 'Session {value}',
      );
      final snapshot = _snapshot(
        const LineChartSeries(id: 'line', points: [ChartDataPoint(x: 0, y: 1)]),
        xAxisFormatter: descriptor.toDocument(),
      );

      final unbound = ChartDartSourceGenerator.generate(snapshot);
      expect(unbound, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      expect(
        (unbound as ChartArtifactSuccess<ChartGeneratedSource>).warnings.map(
          (warning) => warning.code,
        ),
        contains(ChartArtifactDiagnosticCodes.unregisteredFormatter),
      );

      final bound = ChartDartSourceGenerator.generate(
        snapshot,
        options: ChartDartSourceOptions(
          formatters: ChartFormatterRegistry(
            customFormatters: {
              'showcase.session': (value, _) => 'Session ${value.round()}',
            },
          ),
        ),
      );
      expect(bound, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      expect(
        (bound as ChartArtifactSuccess<ChartGeneratedSource>).warnings.map(
          (warning) => warning.code,
        ),
        isNot(contains(ChartArtifactDiagnosticCodes.unregisteredFormatter)),
      );
    });

    // ------------------------------------------------------------------
    // Source-emitter drift-gap fixes (Convergence slice 2).
    //
    // Each of these asserts that a modelled config property which round-trips
    // through the document codecs is now present in the generated source for a
    // NON-DEFAULT value. Before the fix the emitter silently dropped them: the
    // property was modelled, captured and persisted, but had no `_emit*` line.
    // ------------------------------------------------------------------

    test('emits dataPointMarkerBackground for a line series', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const LineChartSeries(
              id: 'line',
              points: [ChartDataPoint(x: 0, y: 1)],
              showDataPointMarkers: true,
              dataPointMarkerBackground: Color(0xFF102030),
            ),
          ),
        ),
      );
      expect(
        generated.source,
        contains('dataPointMarkerBackground: Color(0xFF102030),'),
      );
    });

    test('emits dataPointMarkerBackground for an area series', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const AreaChartSeries(
              id: 'area',
              points: [ChartDataPoint(x: 0, y: 2)],
              showDataPointMarkers: true,
              dataPointMarkerBackground: Color(0xFF405060),
            ),
          ),
        ),
      );
      expect(
        generated.source,
        contains('dataPointMarkerBackground: Color(0xFF405060),'),
      );
    });

    test('emits the categorical x-axis configuration', () {
      final generated = _success(
        ChartDartSourceGenerator.generate(
          _snapshot(
            const BarChartSeries(
              id: 'bar',
              barWidthPercent: 0.7,
              points: [ChartDataPoint(x: 0, y: 1)],
            ),
            xAxis: const XAxisConfig(
              label: 'Quarter',
              categoryAxis: CategoryAxisConfig(
                categories: ['Q1', 'Q2', 'Q3'],
                labelDensity: CategoryLabelDensity.showAll,
                maxLabelLines: 3,
                labelRotationDegrees: 45,
                autoViewport: false,
              ),
            ),
          ),
        ),
      );
      expect(generated.source, contains('categoryAxis: CategoryAxisConfig('));
      expect(generated.source, contains("categories: ['Q1', 'Q2', 'Q3'],"));
      expect(
        generated.source,
        contains('labelDensity: CategoryLabelDensity.showAll,'),
      );
      expect(generated.source, contains('maxLabelLines: 3,'));
      expect(generated.source, contains('labelRotationDegrees: 45.0,'));
      expect(generated.source, contains('autoViewport: false,'));
    });
  });

  group('Source-emitter drift-gap fixes (Convergence slice 3b)', () {
    test('emits barStyle.pattern (BarPatternStyle)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          barStyle: BarChartStyle(
            pattern: BarPatternStyle(pattern: BarFillPattern.crosshatch, spacing: 10),
          ),
        ),
      )));
      expect(generated.source, contains('pattern: BarPatternStyle('));
      expect(generated.source, contains('pattern: BarFillPattern.crosshatch,'));
      expect(generated.source, contains('spacing: 10'));
    });

    test('emits barStyle.motion (BarMotionStyle)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          barStyle: BarChartStyle(
            motion: BarMotionStyle(order: BarAnimationOrder.centerOut, staggerFraction: 0.2),
          ),
        ),
      )));
      expect(generated.source, contains('motion: BarMotionStyle('));
      expect(generated.source, contains('order: BarAnimationOrder.centerOut,'));
      expect(generated.source, contains('staggerFraction: 0.2'));
    });

    test('emits the 10 previously-dropped labelStyle fields', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          labelStyle: BarLabelStyle(
            show: true,
            collisionPolicy: BarLabelCollisionPolicy.hide,
            plotEdgeAware: false,
            collisionPadding: 5,
            backgroundColor: Color(0xFF102030),
            borderColor: Color(0xFF405060),
            borderWidth: 2,
            borderRadius: 8,
            backgroundPadding: 6,
            callout: BarLabelCalloutStyle(show: true, minimumLength: 9),
            showStackTotal: true,
          ),
        ),
      )));
      final src = generated.source;
      expect(src, contains('collisionPolicy: BarLabelCollisionPolicy.hide,'));
      expect(src, contains('plotEdgeAware: false,'));
      expect(src, contains('collisionPadding: 5'));
      expect(src, contains('backgroundColor: Color(0xFF102030),'));
      expect(src, contains('borderColor: Color(0xFF405060),'));
      expect(src, contains('borderWidth: 2'));
      expect(src, contains('borderRadius: 8'));
      expect(src, contains('backgroundPadding: 6'));
      expect(src, contains('callout: BarLabelCalloutStyle('));
      expect(src, contains('showStackTotal: true,'));
    });

    test('emits series divergingRole + divergingStyle', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          layoutMode: BarLayoutMode.divergingStacked,
          divergingRole: BarDivergingRole.negative,
          divergingStyle: BarDivergingStyle(showCenterLine: false, centerLineWidth: 2),
        ),
      )));
      expect(generated.source, contains('divergingRole: BarDivergingRole.negative,'));
      expect(generated.source, contains('divergingStyle: BarDivergingStyle('));
      expect(generated.source, contains('showCenterLine: false,'));
    });

    test('emits series lollipopStyle (with nested headBorder)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          lollipopStyle: BarLollipopStyle(
            stemWidth: 4, headRadius: 9,
            headBorder: BarBorderStyle(color: Color(0xFF010203), width: 2),
          ),
        ),
      )));
      expect(generated.source, contains('lollipopStyle: BarLollipopStyle('));
      expect(generated.source, contains('stemWidth: 4'));
      expect(generated.source, contains('headBorder: BarBorderStyle('));
    });

    test('emits series bulletStyle (with BarBulletRange list)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', barWidthPercent: 0.7, points: [ChartDataPoint(x: 0, y: 1)],
          bulletStyle: BarBulletStyle(
            ranges: [
              BarBulletRange(endValue: 5, color: Color(0xFFAA0000), label: 'low'),
              BarBulletRange(endValue: 10, color: Color(0xFF00AA00)),
            ],
            cornerRadius: 4,
          ),
        ),
      )));
      final src = generated.source;
      expect(src, contains('bulletStyle: BarBulletStyle('));
      expect(src, contains('ranges: ['));
      expect(src, contains('BarBulletRange('));
      expect(src, contains('endValue: 5'));
      expect(src, contains('color: Color(0xFFAA0000),'));
      expect(src, contains("label: 'low',"));
    });

    test('emits CandlestickDataPoint.categoryValue', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        CandlestickChartSeries(
          id: 'c',
          points: [
            CandlestickDataPoint(
              x: 0, open: 2, high: 4, low: 1, close: 3, categoryValue: 'Q1',
            ),
          ],
        ),
      )));
      expect(generated.source, contains("categoryValue: 'Q1',"));
    });
  });

  group('Series-emitter drift-gap fixes (Convergence slice 3e)', () {
    // The line/area SERIES emitters dropped fields that only
    // _emitRangeAreaOptions emitted. Each was round-tripped by the codec, so
    // the source generator silently lost it. Non-default values force emission.
    test('emits LineChartSeries.pathAnimation', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const LineChartSeries(
          id: 'l',
          points: [ChartDataPoint(x: 0, y: 1)],
          pathAnimation: PathAnimationStyle(
            entranceMode: PathEntranceAnimationMode.reveal,
          ),
        ),
      )));
      expect(generated.source, contains('pathAnimation: PathAnimationStyle('));
      expect(
        generated.source,
        contains('entranceMode: PathEntranceAnimationMode.reveal,'),
      );
    });

    test('emits AreaChartSeries.pathAnimation + fillGradient', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const AreaChartSeries(
          id: 'a',
          points: [ChartDataPoint(x: 0, y: 1)],
          pathAnimation: PathAnimationStyle(
            entranceMode: PathEntranceAnimationMode.reveal,
          ),
          fillGradient: AreaGradient(
            colors: [Color(0xFFAA0000), Color(0xFF0000AA)],
          ),
        ),
      )));
      final src = generated.source;
      expect(src, contains('pathAnimation: PathAnimationStyle('));
      expect(src, contains('entranceMode: PathEntranceAnimationMode.reveal,'));
      expect(src, contains('fillGradient: AreaGradient('));
      expect(src, contains('Color(0xFFAA0000),'));
      expect(src, contains('Color(0xFF0000AA),'));
    });

    test('emits the shared ChartSeries.style discriminator', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const LineChartSeries(
          id: 'l',
          points: [ChartDataPoint(x: 0, y: 1)],
          style: SeriesStyle.area,
        ),
      )));
      expect(generated.source, contains('style: SeriesStyle.area,'));
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
  List<ChartSeries> additionalSeries = const [],
  ConcentricDonutConfig? concentricDonutConfig,
  PolarChartConfig? polarChartConfig,
  String? title,
  List<ChartAnnotation> annotations = const [],
  ChartTheme? theme,
  String? themeReference = 'braven.light',
  ChartViewState? viewState,
  InteractionConfig interaction = const InteractionConfig(),
  Map<String, JsonObjectValue> interactionBindingDescriptors = const {},
  JsonObjectValue? xAxisFormatter,
  XAxisConfig xAxis = const XAxisConfig(label: 'Elapsed interval'),
}) {
  final encodedSeries = [
    for (final item in [series, ...additionalSeries])
      (ChartSeriesDocumentCodec.encode(item)
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value,
  ];
  final encodedTheme = ChartThemeDocumentCodec.encode(
    theme ?? ChartTheme.light,
    reference: themeReference,
  );
  final encodedInteraction = ChartInteractionDocumentCodec.encode(
    interaction,
    runtimeBindingDescriptors: interactionBindingDescriptors,
  );
  final encodedXAxis = ChartAxisDocumentCodec.encodeXAxis(
    xAxis,
    formatter: xAxisFormatter,
  );
  final encodedYAxis = ChartAxisDocumentCodec.encodeYAxis(
    YAxisConfig(position: YAxisPosition.left, label: 'Value'),
  );

  return ChartDocumentSnapshot(
    document: ChartDocument(
      documentId: 'source-test',
      revision: 1,
      title: title,
      series: encodedSeries,
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
      configuration: JsonObjectValue({
        if (concentricDonutConfig != null)
          ...(ChartConfigurationDocumentCodec.encodeConcentricDonut(
                    concentricDonutConfig,
                  )
                  as ChartArtifactSuccess<JsonObjectValue>)
              .value
              .values,
        if (polarChartConfig != null)
          ...(ChartConfigurationDocumentCodec.encodePolarChart(polarChartConfig)
                  as ChartArtifactSuccess<JsonObjectValue>)
              .value
              .values,
      }),
      requiredCapabilities: {
        for (final item in [series, ...additionalSeries])
          if (item is PolarColumnChartSeries &&
              item.polarStyle.cornerRadiusMode !=
                  PolarColumnCornerRadiusMode.outerEnd)
            PolarColumnChartSeries.cornerRadiusModeCapability,
        for (final item in [series, ...additionalSeries])
          if (item is PolarColumnChartSeries &&
              item.polarStyle.hasAdvancedAppearance)
            PolarColumnChartSeries.appearanceCapability,
        if (concentricDonutConfig != null) 'series.donut.concentric.v1',
        if (polarChartConfig != null) 'chart.polar.config.v1',
        if (polarChartConfig?.hasCustomLabelAppearance == true)
          PolarChartConfig.labelAppearanceCapability,
        if (polarChartConfig != null && additionalSeries.isNotEmpty)
          'chart.polar.multiple-series.v1',
        if (polarChartConfig?.composition.mode ==
            PolarColumnCompositionMode.grouped)
          'chart.polar.grouped-series.v1',
        if (polarChartConfig?.composition.mode ==
            PolarColumnCompositionMode.stacked)
          'chart.polar.stacked-series.v1',
      },
    ),
    viewState: viewState,
  );
}
