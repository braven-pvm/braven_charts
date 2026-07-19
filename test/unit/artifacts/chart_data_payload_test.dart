import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InlineColumnarPayload', () {
    test('round-trips every point field without a repeated point object', () {
      final points = [
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(double.nan),
          y: ChartNumberDocument.fromDouble(double.infinity),
          magnitude: ChartNumberDocument.fromDouble(42),
          opacityValue: ChartNumberDocument.fromDouble(0.72),
          timestamp: DateTime.parse('2026-07-15T08:30:00+02:00'),
          label: 'surge',
          metadata: JsonObjectValue({'lap': JsonNumberValue(3)}),
          segmentStyle: JsonObjectValue({'strokeWidth': JsonNumberValue(2.5)}),
          pointStyle: JsonObjectValue({'size': JsonNumberValue(7)}),
          extensions: const {'quality': JsonStringValue('verified')},
        ),
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(2),
          y: ChartNumberDocument.fromDouble(20),
        ),
      ];

      final payload = InlineColumnarPayload.fromPoints(points);
      final json = payload.toJson();
      final decoded = ChartDataPayload.fromJson(json);

      expect(json['storage'], 'inlineColumns');
      expect(json, isNot(contains('points')));
      expect(json['x'], hasLength(2));
      expect(json['metadata'], isA<List<Object?>>());
      expect(json['magnitudes'], isA<List<Object?>>());
      expect(json['opacityValues'], isA<List<Object?>>());
      expect(decoded, isA<InlineColumnarPayload>());
      expect(
        (decoded as InlineColumnarPayload).points.map(
          (point) => point.toJson(),
        ),
        points.map((point) => point.toJson()),
      );
      expect(decoded.points.first.timestamp, DateTime.utc(2026, 7, 15, 6, 30));
      expect(() => decoded.xValues.add(points.first.x), throwsUnsupportedError);
      expect(() => decoded.points.add(points.first), throwsUnsupportedError);
    });

    test('omits optional columns when every value is absent', () {
      final payload = InlineColumnarPayload.fromPoints([
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(1),
          y: ChartNumberDocument.fromDouble(2),
        ),
      ]);

      expect(payload.toJson().keys, ['storage', 'x', 'y']);
    });

    test('rejects mismatched required and optional column lengths', () {
      expect(
        () => InlineColumnarPayload(
          xValues: [ChartNumberDocument.fromDouble(1)],
          yValues: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => InlineColumnarPayload(
          xValues: [ChartNumberDocument.fromDouble(1)],
          yValues: [ChartNumberDocument.fromDouble(2)],
          labels: const [],
        ),
        throwsArgumentError,
      );
    });

    test('codec counts columnar points before model construction', () {
      final artifact = _artifact(
        InlineColumnarPayload.fromPoints([
          _point(1, 10),
          _point(2, 20),
          _point(3, 30),
        ]),
      );

      final encodedLimit = ChartArtifactJsonCodec.encode(
        artifact,
        limits: const ChartArtifactValidationLimits(maxPoints: 2),
      );
      final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;
      final decodedLimit = ChartArtifactJsonCodec.decode(
        encoded,
        limits: const ChartArtifactValidationLimits(maxPoints: 2),
      );

      expect(encodedLimit, isA<ChartArtifactFailure<String>>());
      expect(
        (encodedLimit as ChartArtifactFailure<String>).error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
      expect(
        decodedLimit,
        isA<ChartArtifactFailure<ChartArtifactDecodeResult>>(),
      );

      final malformed = artifact.toJson();
      final document = malformed['document']! as Map<String, Object?>;
      final series = document['series']! as List<Object?>;
      final seriesJson = series.single as Map<String, Object?>;
      final data = seriesJson['data']! as Map<String, Object?>;
      data['y'] = <Object?>[];
      final malformedResult = ChartArtifactJsonCodec.decode(
        jsonEncode(malformed),
      );
      expect(
        (malformedResult as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });

    test('reduces repeated JSON keys for numeric series', () {
      final points = [
        for (var index = 0; index < 200; index++)
          _point(index.toDouble(), index * 2.0),
      ];
      final pointBytes = utf8
          .encode(jsonEncode(InlinePointPayload(points).toJson()))
          .length;
      final columnBytes = utf8
          .encode(jsonEncode(InlineColumnarPayload.fromPoints(points).toJson()))
          .length;

      expect(columnBytes, lessThan(pointBytes * 0.7));
    });
  });
}

ChartPointDocument _point(double x, double y) => ChartPointDocument(
  x: ChartNumberDocument.fromDouble(x),
  y: ChartNumberDocument.fromDouble(y),
);

ChartArtifact _artifact(ChartDataPayload payload) => ChartArtifact(
  artifactId: 'columnar-test',
  renderer: const ChartRendererInfo(package: 'braven_charts', version: 'test'),
  createdAt: DateTime.utc(2026, 7, 15),
  document: ChartDocument(
    documentId: 'columnar-document',
    revision: 0,
    series: [ChartSeriesDocument(type: 'line', id: 'series', data: payload)],
    xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
    axes: const [],
    theme: ChartThemeDocument(),
    interaction: ChartInteractionDocument(),
  ),
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
