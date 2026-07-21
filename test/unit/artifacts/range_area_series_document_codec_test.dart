import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips Range Area intervals, gaps, style, and motion', () {
    final source = RangeAreaChartSeries(
      id: 'confidence',
      name: 'Confidence interval',
      points: [
        RangeAreaDataPoint.atTime(
          timestamp: DateTime.utc(2026, 7, 21),
          low: 8.25,
          high: 12.75,
          label: 'Observed',
          metadata: const {'quality': 'verified'},
        ),
        RangeAreaDataPoint.gap(
          x: DateTime.utc(2026, 7, 22).millisecondsSinceEpoch.toDouble(),
          label: 'Missing',
        ),
        RangeAreaDataPoint(
          x: DateTime.utc(2026, 7, 23).millisecondsSinceEpoch.toDouble(),
          low: 9.5,
          high: 14,
        ),
      ],
      color: const Color(0xFF2563EB),
      unit: '°C',
      interpolation: LineInterpolation.monotone,
      tension: .4,
      fillOpacity: .36,
      fillGradient: const AreaGradient(
        colors: [Color(0x332563EB), Color(0xAA2563EB)],
        stops: [0, 1],
      ),
      borderMode: RangeAreaBorderMode.closed,
      upperBoundaryStyle: const RangeAreaBoundaryStyle(
        color: Color(0xFF1D4ED8),
        strokeWidth: 2,
        dashPattern: [4, 2],
        glowRadius: 3,
      ),
      lowerBoundaryStyle: const RangeAreaBoundaryStyle(
        visible: false,
        strokeWidth: 1,
      ),
      connectGaps: true,
      showBoundaryMarkers: true,
      markerRadius: 4,
      labelConfig: const RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        labels: DataPointLabelConfig(show: true),
        boundaryGap: 6,
      ),
      hitTestMode: RangeAreaHitTestMode.nearestBoundary,
      pathAnimation: const PathAnimationStyle(
        entranceMode: PathEntranceAnimationMode.reveal,
        dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
        entranceTiming: PathAnimationTiming(
          duration: Duration(milliseconds: 450),
        ),
      ),
    );

    for (final storage in ChartDataStorage.values) {
      final encoded =
          ChartSeriesDocumentCodec.encode(source, dataStorage: storage)
              as ChartArtifactSuccess<ChartSeriesDocument>;
      final portable = ChartSeriesDocument.fromJson(encoded.value.toJson());
      final decoded =
          ChartSeriesDocumentCodec.decode(portable)
              as ChartArtifactSuccess<ChartSeries>;

      expect(portable.type, 'rangeArea');
      expect(
        portable.requiredCapabilities,
        containsAll({
          'series.rangeArea',
          'series.rangeArea.interval.v1',
          'series.rangeArea.gradient.v1',
          'series.path-dash.v1',
          'series.path-motion.v1',
          'series.path-motion-timing.v1',
        }),
      );
      expect(decoded.value, source);
    }
  });

  test('rejects a Range Area document whose midpoint is not canonical y', () {
    final source = RangeAreaChartSeries(
      id: 'range',
      points: [RangeAreaDataPoint(x: 1, low: 4, high: 8)],
    );
    final encoded =
        ChartSeriesDocumentCodec.encode(source)
            as ChartArtifactSuccess<ChartSeriesDocument>;
    final json = encoded.value.toJson();
    final data = json['data']! as Map<String, Object?>;
    final points = data['points']! as List<Object?>;
    final point = points.single! as Map<String, Object?>;
    point['y'] = 99;

    final decoded = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(json),
    );

    expect(decoded, isA<ChartArtifactFailure<ChartSeries>>());
    expect(
      (decoded as ChartArtifactFailure<ChartSeries>).error.message,
      contains('canonical y'),
    );
  });

  test('rejects malformed gaps carrying bounds or a non-canonical y', () {
    final source = RangeAreaChartSeries(
      id: 'range',
      points: [RangeAreaDataPoint.gap(x: 1)],
    );
    final encoded =
        ChartSeriesDocumentCodec.encode(source)
            as ChartArtifactSuccess<ChartSeriesDocument>;

    Map<String, Object?> mutatedPoint() {
      final json = encoded.value.toJson();
      final data = json['data']! as Map<String, Object?>;
      final points = data['points']! as List<Object?>;
      return points.single! as Map<String, Object?>;
    }

    final boundedPoint = mutatedPoint();
    final boundedExtensions =
        boundedPoint['extensions']! as Map<String, Object?>;
    final boundedRange =
        boundedExtensions['rangeArea.interval.v1']! as Map<String, Object?>;
    boundedRange['low'] = 4;
    final boundedDocument = encoded.value.toJson();
    final boundedData = boundedDocument['data']! as Map<String, Object?>;
    (boundedData['points']! as List<Object?>)[0] = boundedPoint;
    final bounded = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(boundedDocument),
    );
    expect(bounded, isA<ChartArtifactFailure<ChartSeries>>());
    final boundedFailure = bounded as ChartArtifactFailure<ChartSeries>;
    expect(
      boundedFailure.error.message,
      contains('cannot include low or high'),
    );

    final nonCanonicalPoint = mutatedPoint()..['y'] = 3;
    final nonCanonicalDocument = encoded.value.toJson();
    final nonCanonicalData =
        nonCanonicalDocument['data']! as Map<String, Object?>;
    (nonCanonicalData['points']! as List<Object?>)[0] = nonCanonicalPoint;
    final nonCanonical = ChartSeriesDocumentCodec.decode(
      ChartSeriesDocument.fromJson(nonCanonicalDocument),
    );
    expect(nonCanonical, isA<ChartArtifactFailure<ChartSeries>>());
    final nonCanonicalFailure =
        nonCanonical as ChartArtifactFailure<ChartSeries>;
    expect(nonCanonicalFailure.error.message, contains('zero placeholder'));
  });

  test('an older runtime cannot accept midpoint-only Range Area fallback', () {
    final series = RangeAreaChartSeries(
      id: 'range',
      points: [RangeAreaDataPoint(x: 1, low: 4, high: 8)],
    );
    final seriesDocument =
        (ChartSeriesDocumentCodec.encode(series)
                as ChartArtifactSuccess<ChartSeriesDocument>)
            .value;
    final artifact = ChartArtifact(
      artifactId: 'range-area-capability-test',
      renderer: const ChartRendererInfo(
        package: 'braven_charts',
        version: '0.1.0',
      ),
      createdAt: DateTime.utc(2026, 7, 21),
      document: ChartDocument(
        documentId: 'range-area-document',
        revision: 1,
        series: [seriesDocument],
        xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
        axes: const [],
        theme: ChartThemeDocument(reference: 'braven.light'),
        interaction: ChartInteractionDocument(),
      ),
    );
    final encoded =
        (ChartArtifactJsonCodec.encode(artifact)
                as ChartArtifactSuccess<String>)
            .value;

    final decoded = ChartArtifactJsonCodec.decode(
      encoded,
      supportedCapabilities: const {'series.line', 'series.area'},
    );

    expect(decoded, isA<ChartArtifactFailure<ChartArtifactDecodeResult>>());
    final failure = decoded as ChartArtifactFailure<ChartArtifactDecodeResult>;
    expect(
      failure.error.code,
      ChartArtifactDiagnosticCodes.missingRequiredCapability,
    );
    expect(failure.error.message, contains('series.rangeArea'));
    expect(failure.error.message, contains('series.rangeArea.interval.v1'));
  });
}
