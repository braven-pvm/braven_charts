import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSeriesDocumentCodec', () {
    test('round-trips every base and line-series field', () {
      final source = LineChartSeries(
        id: 'power',
        name: 'Power',
        points: [
          ChartDataPoint(
            x: double.nan,
            y: double.infinity,
            timestamp: DateTime.utc(2026, 7, 14, 9, 15),
            label: 'surge',
            metadata: const {'quality': 'verified', 'lap': 3},
            segmentStyle: const SegmentStyle(
              color: Color(0xFFAA1122),
              strokeWidth: 3.5,
            ),
            pointStyle: const PointStyle(color: Color(0xFF1144AA), size: 7.25),
          ),
        ],
        color: const Color(0xFF123456),
        style: SeriesStyle.line,
        isXOrdered: true,
        metadata: const {'source': 'erg', 'channel': 2},
        yAxisId: 'shared-power',
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          color: const Color(0xFF654321),
          label: 'Power',
          unit: 'W',
          min: 100,
          max: 500,
          renderMin: 120,
          renderMax: 480,
          visible: false,
          showAxisLine: false,
          showTicks: false,
          showTickLabels: false,
          showCrosshairLabel: false,
          crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
          minWidth: 12,
          maxWidth: 92,
          tickLabelPadding: 6,
          axisLabelPadding: 7,
          axisMargin: 9,
          tickCount: 7,
          showMinorTicks: true,
          minorTickCount: 3,
          minorTickLength: 2.5,
        ).copyWith(id: 'inline-power'),
        unit: 'W',
        interpolation: LineInterpolation.monotone,
        strokeWidth: 4.5,
        tension: 0.6,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 5.5,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        dataPointMarkerBackground: const Color(0xFFFAFAFA),
        lineGlow: 2.25,
        dataPointLabels: const DataPointLabelConfig(
          show: true,
          position: DataPointLabelPosition.left,
          offsetX: 1.5,
          offsetY: -2.5,
          labelColor: Color(0xFF101010),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          showUnit: true,
          background: Color(0xFFECECEC),
          backgroundOpacity: 0.7,
        ),
        inlineLabel: const SeriesInlineLabelConfig(
          text: 'FTP',
          position: SeriesLabelPosition.center,
          offsetY: -4,
          color: Color(0xFF202020),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          background: SeriesLabelBackground(
            color: Color(0xFFF0F0F0),
            cornerRadius: 6,
            padding: EdgeInsets.fromLTRB(3, 4, 5, 6),
            borderColor: Color(0xFF303030),
            borderWidth: 2,
          ),
        ),
      );

      final decoded = _roundTrip(source) as LineChartSeries;

      expect(decoded.id, source.id);
      expect(decoded.name, source.name);
      expect(decoded.color, source.color);
      expect(decoded.style, source.style);
      expect(decoded.isXOrdered, isTrue);
      expect(decoded.metadata, source.metadata);
      expect(decoded.yAxisId, source.yAxisId);
      expect(decoded.yAxisConfig, source.yAxisConfig);
      expect(decoded.unit, source.unit);
      expect(decoded.interpolation, source.interpolation);
      expect(decoded.strokeWidth, source.strokeWidth);
      expect(decoded.tension, source.tension);
      expect(decoded.showDataPointMarkers, isTrue);
      expect(decoded.dataPointMarkerRadius, source.dataPointMarkerRadius);
      expect(decoded.dataPointMarkerStyle, source.dataPointMarkerStyle);
      expect(
        decoded.dataPointMarkerBackground,
        source.dataPointMarkerBackground,
      );
      expect(decoded.lineGlow, source.lineGlow);
      expect(decoded.dataPointLabels, source.dataPointLabels);
      expect(decoded.inlineLabel, source.inlineLabel);
      expect(decoded.points.single.x.isNaN, isTrue);
      expect(decoded.points.single.y, double.infinity);
      expect(decoded.points.single.timestamp, source.points.single.timestamp);
      expect(decoded.points.single.label, 'surge');
      expect(decoded.points.single.metadata, source.points.single.metadata);
      expect(
        decoded.points.single.segmentStyle,
        source.points.single.segmentStyle,
      );
      expect(decoded.points.single.pointStyle, source.points.single.pointStyle);
    });

    test('round-trips every area-series field', () {
      const source = AreaChartSeries(
        id: 'load',
        points: [ChartDataPoint(x: 1, y: 2)],
        color: Color(0xFF335577),
        style: SeriesStyle.area,
        interpolation: LineInterpolation.bezier,
        strokeWidth: 3,
        tension: 0.45,
        fillOpacity: 0.55,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 6,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        dataPointMarkerBackground: Color(0xFFF8F8F8),
        lineGlow: 1.5,
        dataPointLabels: DataPointLabelConfig(show: true),
        inlineLabel: SeriesInlineLabelConfig(text: 'Load'),
        baselineValue: 0,
        aboveBaselineFillColor: Color(0xFF00AA00),
        belowBaselineFillColor: Color(0xFFAA0000),
      );

      final decoded = _roundTrip(source) as AreaChartSeries;

      expect(decoded.style, SeriesStyle.area);
      expect(decoded.interpolation, LineInterpolation.bezier);
      expect(decoded.strokeWidth, 3);
      expect(decoded.tension, 0.45);
      expect(decoded.fillOpacity, 0.55);
      expect(decoded.showDataPointMarkers, isTrue);
      expect(decoded.dataPointMarkerRadius, 6);
      expect(decoded.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
      expect(decoded.dataPointMarkerBackground, const Color(0xFFF8F8F8));
      expect(decoded.lineGlow, 1.5);
      expect(decoded.dataPointLabels, source.dataPointLabels);
      expect(decoded.inlineLabel, source.inlineLabel);
      expect(decoded.baselineValue, 0);
      expect(decoded.aboveBaselineFillColor, const Color(0xFF00AA00));
      expect(decoded.belowBaselineFillColor, const Color(0xFFAA0000));
    });

    test('round-trips scatter, bar, and concrete base series', () {
      final scatter =
          _roundTrip(
                const ScatterChartSeries(
                  id: 'scatter',
                  points: [ChartDataPoint(x: 1, y: 3)],
                  style: SeriesStyle.scatter,
                  markerRadius: 8.5,
                ),
              )
              as ScatterChartSeries;
      expect(scatter.style, SeriesStyle.scatter);
      expect(scatter.markerRadius, 8.5);

      final bar =
          _roundTrip(
                const BarChartSeries(
                  id: 'bar',
                  points: [ChartDataPoint(x: 1, y: 3)],
                  style: SeriesStyle.bar,
                  barWidthPixels: 14,
                  minWidth: 5,
                  maxWidth: 42,
                ),
              )
              as BarChartSeries;
      expect(bar.style, SeriesStyle.bar);
      expect(bar.barWidthPercent, isNull);
      expect(bar.barWidthPixels, 14);
      expect(bar.minWidth, 5);
      expect(bar.maxWidth, 42);

      final base = _roundTrip(
        const ChartSeries(
          id: 'base',
          points: [ChartDataPoint(x: 1, y: 4)],
          style: SeriesStyle.line,
        ),
      );
      expect(base.runtimeType, ChartSeries);
      expect(base.style, SeriesStyle.line);
    });

    test('uses stable built-in type and capability identifiers', () {
      final cases = <(ChartSeries, (String, String))>[
        (
          const LineChartSeries(id: 'line', points: []),
          ('line', 'series.line'),
        ),
        (
          const ScatterChartSeries(id: 'scatter', points: []),
          ('scatter', 'series.scatter'),
        ),
        (
          const AreaChartSeries(id: 'area', points: []),
          ('area', 'series.area'),
        ),
        (
          const BarChartSeries(id: 'bar', points: [], barWidthPercent: 0.5),
          ('bar', 'series.bar'),
        ),
        (const ChartSeries(id: 'base', points: []), ('base', 'series.base')),
      ];

      for (final (series, expected) in cases) {
        final encoded = ChartSeriesDocumentCodec.encode(series);
        expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
        final document =
            (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
        expect(document.type, expected.$1);
        expect(document.requiredCapabilities, {expected.$2});
      }
    });

    test('fails closed for runtime callbacks', () {
      final labelFormatter =
          ChartSeriesDocumentCodec.encode(
                LineChartSeries(
                  id: 'callback',
                  points: const [],
                  dataPointLabels: DataPointLabelConfig(
                    formatter: (point) => point.y.toString(),
                  ),
                ),
              )
              as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        labelFormatter.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(labelFormatter.error.path, contains('formatter'));

      final axisFormatter =
          ChartSeriesDocumentCodec.encode(
                LineChartSeries(
                  id: 'axis-callback',
                  points: const [],
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.left,
                    labelFormatter: (value) => '$value W',
                  ),
                ),
              )
              as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        axisFormatter.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
    });

    test('round-trips series-level annotations', () {
      final source = LineChartSeries(
        id: 'annotated',
        points: const [],
        annotations: [PinAnnotation(id: 'pin', x: 1, y: 2)],
      );

      final decoded = _roundTrip(source) as LineChartSeries;

      expect(decoded.annotations, hasLength(1));
      expect(decoded.annotations.single, isA<PinAnnotation>());
      expect(decoded.annotations.single.id, 'pin');
    });

    test('rejects metadata that is not recursively JSON-safe', () {
      final result = ChartSeriesDocumentCodec.encode(
        LineChartSeries(
          id: 'unsafe',
          points: const [],
          metadata: {'createdAt': DateTime.utc(2026)},
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartSeriesDocument>>());
      expect(
        (result as ChartArtifactFailure<ChartSeriesDocument>).error.code,
        ChartArtifactDiagnosticCodes.metadataValueNotJsonSafe,
      );
    });

    test('subtype copyWith preserves base style and annotations', () {
      final annotation = PinAnnotation(id: 'pin', x: 1, y: 2);
      final source = LineChartSeries(
        id: 'line',
        points: const [],
        style: SeriesStyle.line,
        annotations: [annotation],
      );

      final copy = source.copyWith(name: 'copy');

      expect(copy.style, SeriesStyle.line);
      expect(copy.annotations, [annotation]);
    });

    test('rejects cyclic series and annotation model graphs', () {
      final annotations = <ChartAnnotation>[];
      final series = LineChartSeries(
        id: 'cycle',
        points: const [],
        annotations: annotations,
      );
      annotations.add(LegendAnnotation(id: 'legend', series: [series]));

      final result = ChartSeriesDocumentCodec.encode(series);

      expect(result, isA<ChartArtifactFailure<ChartSeriesDocument>>());
      final failure = result as ChartArtifactFailure<ChartSeriesDocument>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
      expect(failure.error.message, contains('Cyclic'));
    });

    test('returns a structured failure for unknown series types', () {
      final result = ChartSeriesDocumentCodec.decode(
        ChartSeriesDocument(
          type: 'com.example.heatmap',
          id: 'custom',
          data: InlinePointPayload(const []),
          style: JsonValue.fromJson({'isXOrdered': false}) as JsonObjectValue,
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartSeries>>());
      final failure = result as ChartArtifactFailure<ChartSeries>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.unsupportedModelType,
      );
      expect(failure.error.path, r'$.type');
    });
  });
}

ChartSeries _roundTrip(ChartSeries source) {
  final encoded = ChartSeriesDocumentCodec.encode(source);
  expect(encoded, isA<ChartArtifactSuccess<ChartSeriesDocument>>());
  final document = (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
  final jsonRoundTrip = ChartSeriesDocument.fromJson(document.toJson());
  final decoded = ChartSeriesDocumentCodec.decode(jsonRoundTrip);
  expect(decoded, isA<ChartArtifactSuccess<ChartSeries>>());
  return (decoded as ChartArtifactSuccess<ChartSeries>).value;
}
