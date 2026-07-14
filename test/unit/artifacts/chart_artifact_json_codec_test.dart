import 'dart:convert';
import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartArtifactJsonCodec', () {
    test('round-trips schema v1 deterministically without losing values', () {
      final artifact = _buildArtifact();

      final encodedResult = ChartArtifactJsonCodec.encode(artifact);
      expect(encodedResult, isA<ChartArtifactSuccess<String>>());
      final encoded = (encodedResult as ChartArtifactSuccess<String>).value;

      final decodedResult = ChartArtifactJsonCodec.decode(
        encoded,
        supportedCapabilities: const {
          'series.line',
          'annotation.pin',
          'annotation.threshold',
        },
      );
      expect(
        decodedResult,
        isA<ChartArtifactSuccess<ChartArtifactDecodeResult>>(),
      );
      final decoded =
          (decodedResult as ChartArtifactSuccess<ChartArtifactDecodeResult>)
              .value;

      expect(decoded.sourceSchemaVersion, 1);
      expect(decoded.migratedSchemaVersion, 1);
      expect(decoded.migrationsApplied, isEmpty);
      expect(decoded.artifact.createdAt.isUtc, isTrue);
      expect(decoded.artifact.document.pointCount, 3);
      expect(
        decoded.artifact.document.series.single.data,
        isA<InlinePointPayload>(),
      );
      final points =
          (decoded.artifact.document.series.single.data as InlinePointPayload)
              .points;
      expect(points[1].y.asDouble.isNaN, isTrue);
      expect(points[2].y.asDouble, double.infinity);
      expect(points.first.timestamp?.isUtc, isTrue);
      expect(decoded.artifact.extensions['example.roundTrip']?.toJson(), {
        'preserved': true,
      });

      final reencoded = ChartArtifactJsonCodec.encode(decoded.artifact);
      expect(reencoded, isA<ChartArtifactSuccess<String>>());
      expect((reencoded as ChartArtifactSuccess<String>).value, encoded);
    });

    test('decodes and canonically re-encodes the checked-in v1 fixture', () {
      final fixture = File(
        'test/fixtures/artifacts/schema_v1_minimal.json',
      ).readAsStringSync();

      final result = ChartArtifactJsonCodec.decode(fixture);
      expect(result, isA<ChartArtifactSuccess<ChartArtifactDecodeResult>>());
      final artifact =
          (result as ChartArtifactSuccess<ChartArtifactDecodeResult>)
              .value
              .artifact;
      expect(artifact.artifactId, 'artifact-fixture-1');
      expect(artifact.document.series.single.id, 'power');
      expect(
        (artifact.document.series.single.data as InlinePointPayload)
            .points
            .last
            .y
            .asDouble
            .isNaN,
        isTrue,
      );

      final encoded = ChartArtifactJsonCodec.encode(artifact);
      expect(encoded, isA<ChartArtifactSuccess<String>>());
      expect(
        (encoded as ChartArtifactSuccess<String>).value,
        canonicalJsonEncode(jsonDecode(fixture)),
      );
    });

    test('returns structured failures for invalid and future schemas', () {
      final invalid = ChartArtifactJsonCodec.decode('{not-json');
      expect(invalid, isA<ChartArtifactFailure<ChartArtifactDecodeResult>>());
      expect(
        (invalid as ChartArtifactFailure<ChartArtifactDecodeResult>).error.code,
        ChartArtifactDiagnosticCodes.invalidJson,
      );

      final future =
          jsonDecode(
                (ChartArtifactJsonCodec.encode(_buildArtifact())
                        as ChartArtifactSuccess<String>)
                    .value,
              )
              as Map<String, dynamic>;
      future['schemaVersion'] = 2;
      final unsupported = ChartArtifactJsonCodec.decode(jsonEncode(future));
      expect(
        (unsupported as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
      );
    });

    test('rejects missing capabilities before hydration', () {
      final encoded =
          (ChartArtifactJsonCodec.encode(_buildArtifact())
                  as ChartArtifactSuccess<String>)
              .value;

      final result = ChartArtifactJsonCodec.decode(encoded);

      expect(result, isA<ChartArtifactFailure<ChartArtifactDecodeResult>>());
      expect(
        (result as ChartArtifactFailure<ChartArtifactDecodeResult>).error.code,
        ChartArtifactDiagnosticCodes.missingRequiredCapability,
      );
      expect(result.error.message, contains('series.line'));
      expect(result.error.message, contains('annotation.pin'));
      expect(result.error.message, contains('annotation.threshold'));
    });

    test('enforces point and encoded-byte limits', () {
      final artifact = _buildArtifact();
      final pointLimited = ChartArtifactJsonCodec.encode(
        artifact,
        limits: const ChartArtifactValidationLimits(maxPoints: 2),
      );
      expect(pointLimited, isA<ChartArtifactFailure<String>>());
      expect(
        (pointLimited as ChartArtifactFailure<String>).error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );

      final encoded =
          (ChartArtifactJsonCodec.encode(artifact)
                  as ChartArtifactSuccess<String>)
              .value;
      final decodedPointLimited = ChartArtifactJsonCodec.decode(
        encoded,
        limits: const ChartArtifactValidationLimits(maxPoints: 2),
      );
      expect(
        (decodedPointLimited as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );

      final byteLimited = ChartArtifactJsonCodec.decode(
        encoded,
        limits: ChartArtifactValidationLimits(
          maxEncodedBytes: utf8.encode(encoded).length - 1,
        ),
      );
      expect(
        (byteLimited as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
    });

    test('counts series and points nested inside legend annotations', () {
      final legendResult = ChartAnnotationDocumentCodec.encode(
        LegendAnnotation(
          series: const [
            LineChartSeries(id: 'nested', points: [ChartDataPoint(x: 0, y: 1)]),
          ],
        ),
      );
      final legend =
          (legendResult as ChartArtifactSuccess<ChartAnnotationDocument>).value;
      final artifact = _buildArtifact(additionalAnnotations: [legend]);

      final encodedSeriesLimited = ChartArtifactJsonCodec.encode(
        artifact,
        limits: const ChartArtifactValidationLimits(maxSeries: 1),
      );
      expect(encodedSeriesLimited, isA<ChartArtifactFailure<String>>());
      expect(
        (encodedSeriesLimited as ChartArtifactFailure<String>).error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );

      final encoded =
          (ChartArtifactJsonCodec.encode(artifact)
                  as ChartArtifactSuccess<String>)
              .value;
      final decodedPointLimited = ChartArtifactJsonCodec.decode(
        encoded,
        limits: const ChartArtifactValidationLimits(maxPoints: 3),
      );
      expect(
        (decodedPointLimited as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
    });

    test('rejects duplicate series ids and unsupported payload storage', () {
      final root =
          jsonDecode(
                (ChartArtifactJsonCodec.encode(_buildArtifact())
                        as ChartArtifactSuccess<String>)
                    .value,
              )
              as Map<String, dynamic>;
      final document = root['document'] as Map<String, dynamic>;
      final series = document['series'] as List<dynamic>;
      series.add(Map<String, dynamic>.from(series.single as Map));

      final duplicate = ChartArtifactJsonCodec.decode(jsonEncode(root));
      expect(
        (duplicate as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .message,
        contains('Duplicate series id'),
      );

      series.removeLast();
      final firstSeries = series.single as Map<String, dynamic>;
      (firstSeries['data'] as Map<String, dynamic>)['storage'] =
          'referencedPayload';
      final unsupportedStorage = ChartArtifactJsonCodec.decode(
        jsonEncode(root),
      );
      expect(
        (unsupportedStorage as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .message,
        contains('Unsupported chart data storage'),
      );
    });
  });
}

ChartArtifact _buildArtifact({
  List<ChartAnnotationDocument> additionalAnnotations = const [],
}) {
  return ChartArtifact(
    artifactId: 'artifact-round-trip',
    renderer: const ChartRendererInfo(
      package: 'braven_charts',
      version: '0.1.0',
    ),
    createdAt: DateTime.parse('2026-07-14T10:30:00+02:00'),
    document: ChartDocument(
      documentId: 'document-round-trip',
      revision: 9,
      title: 'Power and heart rate',
      series: [
        ChartSeriesDocument(
          type: 'line',
          id: 'power',
          name: 'Power',
          unit: 'W',
          axisId: 'power-axis',
          requiredCapabilities: const {'series.line'},
          metadata:
              JsonValue.fromJson({'source': 'unit-test'}) as JsonObjectValue,
          annotations: [
            ChartAnnotationDocument(
              type: 'pin',
              id: 'series-pin',
              requiredCapabilities: const {'annotation.pin'},
            ),
          ],
          data: InlinePointPayload([
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(0),
              y: ChartNumberDocument.fromDouble(211.4),
              timestamp: DateTime.parse('2026-07-14T08:30:00Z'),
              metadata:
                  JsonValue.fromJson({'quality': 'measured'})
                      as JsonObjectValue,
            ),
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(0.5),
              y: ChartNumberDocument.fromDouble(double.nan),
              label: 'gap',
            ),
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(1),
              y: ChartNumberDocument.fromDouble(double.infinity),
            ),
          ]),
        ),
      ],
      xAxis: ChartAxisDocument(
        id: 'time',
        position: 'bottom',
        label: 'Time',
        unit: 'h',
        formatter:
            JsonValue.fromJson({
                  'id': 'braven.elapsedTime',
                  'arguments': {'unit': 'hours'},
                })
                as JsonObjectValue,
      ),
      axes: [
        ChartAxisDocument(
          id: 'power-axis',
          position: 'left',
          label: 'Power',
          unit: 'W',
        ),
      ],
      theme: ChartThemeDocument(
        reference: 'braven.light',
        resolved:
            JsonValue.fromJson({'backgroundColor': '#FFFFFFFF'})
                as JsonObjectValue,
      ),
      interaction: ChartInteractionDocument(
        configuration:
            JsonValue.fromJson({'zoom': true, 'pan': true}) as JsonObjectValue,
      ),
      annotations: [
        ChartAnnotationDocument(
          type: 'threshold',
          id: 'document-threshold',
          requiredCapabilities: const {'annotation.threshold'},
        ),
        ...additionalAnnotations,
      ],
    ),
    viewState: ChartViewState(
      visibleBounds: const ChartBoundsDocument(
        xMin: 0,
        xMax: 1,
        yMin: 0,
        yMax: 300,
      ),
      selectedSeriesId: 'power',
      selectedPointRefs: const [
        ChartPointRef(seriesId: 'power', pointIndex: 0),
      ],
      visibleAxisIds: const ['power-axis'],
    ),
    provenance: ChartArtifactProvenance(
      values:
          JsonValue.fromJson({'captureReason': 'round-trip-test'})
              as JsonObjectValue,
    ),
    extensions: {
      'example.roundTrip': JsonValue.fromJson({'preserved': true}),
    },
  );
}
